import { generateKeyPairSync, createVerify } from 'node:crypto';
import { FcmPushService } from './fcm-push.service';

const { privateKey, publicKey } = generateKeyPairSync('rsa', {
  modulusLength: 2048,
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
  publicKeyEncoding: { type: 'spki', format: 'pem' },
});

const creds = {
  projectId: 'proj',
  clientEmail: 'svc@proj.iam.gserviceaccount.com',
  // As it would arrive from an env var: literal "\n" sequences.
  privateKey: privateKey.replace(/\n/g, '\\n'),
};
const message = { title: 't', body: 'b', data: { a: '1' } };

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status });

function build(sendResponses: Response[]) {
  const calls: { url: string; init: RequestInit }[] = [];
  const queue = [...sendResponses];
  const fetchFn = jest.fn((url: string | URL | Request, init?: RequestInit) => {
    const u = typeof url === 'string' ? url : (url as URL).toString();
    calls.push({ url: u, init: init ?? {} });
    if (u.includes('oauth2.googleapis.com')) {
      return Promise.resolve(
        json(200, { access_token: 'at', expires_in: 3600 }),
      );
    }
    return Promise.resolve(queue.shift() ?? json(200, {}));
  }) as unknown as typeof fetch;
  return { svc: new FcmPushService(creds, fetchFn), calls };
}

describe('FcmPushService', () => {
  it('does nothing without targets', async () => {
    const { svc, calls } = build([]);
    expect(await svc.send([], message)).toEqual({ sent: 0, invalidTokens: [] });
    expect(calls).toHaveLength(0);
  });

  it('exchanges a verifiable RS256 JWT and sends each token', async () => {
    const { svc, calls } = build([]);
    const res = await svc.send(
      [
        { token: 't1', platform: 'android' },
        { token: 't2', platform: 'ios' },
      ],
      message,
    );
    expect(res).toEqual({ sent: 2, invalidTokens: [] });

    const auth = calls[0];
    const assertion = new URLSearchParams(
      auth.init.body as URLSearchParams,
    ).get('assertion')!;
    const [h, c, s] = assertion.split('.');
    expect(JSON.parse(Buffer.from(h, 'base64url').toString())).toMatchObject({
      alg: 'RS256',
    });
    expect(JSON.parse(Buffer.from(c, 'base64url').toString())).toMatchObject({
      iss: creds.clientEmail,
    });
    expect(
      createVerify('RSA-SHA256')
        .update(`${h}.${c}`)
        .verify(publicKey, Buffer.from(s, 'base64url')),
    ).toBe(true);

    const send = calls[1];
    expect(send.url).toBe(
      'https://fcm.googleapis.com/v1/projects/proj/messages:send',
    );
    expect((send.init.headers as Record<string, string>).Authorization).toBe(
      'Bearer at',
    );
    expect(
      (JSON.parse(send.init.body as string) as { message: unknown }).message,
    ).toMatchObject({
      token: 't1',
      notification: { title: 't', body: 'b' },
      data: { a: '1' },
    });
    // The access token is cached across sends.
    await svc.send([{ token: 't3', platform: 'web' }], message);
    expect(
      calls.filter((x) => x.url.includes('oauth2.googleapis.com')),
    ).toHaveLength(1);
  });

  it('reports dead tokens instead of throwing', async () => {
    const { svc } = build([
      json(404, {
        error: {
          status: 'NOT_FOUND',
          details: [{ errorCode: 'UNREGISTERED' }],
        },
      }),
      json(200, {}),
    ]);
    const res = await svc.send(
      [
        { token: 'dead', platform: 'android' },
        { token: 'ok', platform: 'android' },
      ],
      message,
    );
    expect(res).toEqual({ sent: 1, invalidTokens: ['dead'] });
  });

  it('throws on transient errors so the queue retries', async () => {
    const { svc } = build([json(500, { error: { status: 'INTERNAL' } })]);
    await expect(
      svc.send([{ token: 't', platform: 'android' }], message),
    ).rejects.toThrow(/FCM send failed \(500\)/);
  });
});
