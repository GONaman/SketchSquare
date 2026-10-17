import { Injectable, Logger } from '@nestjs/common';
import { createSign } from 'node:crypto';
import type {
  PushMessage,
  PushResult,
  PushService,
  PushTarget,
} from './push.service';

export interface FcmCredentials {
  projectId: string;
  clientEmail: string;
  privateKey: string;
}

type FetchFn = typeof fetch;

const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';
// FCM v1 error codes that mean the registration token will never work again.
const DEAD_TOKEN_CODES = new Set(['UNREGISTERED', 'INVALID_ARGUMENT']);

const b64url = (v: string | Buffer) => Buffer.from(v).toString('base64url');

/**
 * FCM HTTP v1 sender authenticated with a service-account key (no firebase-admin dependency).
 * Only constructed when FCM_PROJECT_ID, FCM_CLIENT_EMAIL and FCM_PRIVATE_KEY are all set.
 */
@Injectable()
export class FcmPushService implements PushService {
  private readonly logger = new Logger(FcmPushService.name);
  private cached: { token: string; expiresAt: number } | null = null;

  constructor(
    private readonly creds: FcmCredentials,
    private readonly fetchFn: FetchFn = fetch,
  ) {}

  async send(targets: PushTarget[], message: PushMessage): Promise<PushResult> {
    const result: PushResult = { sent: 0, invalidTokens: [] };
    if (targets.length === 0) return result;
    const accessToken = await this.accessToken();
    for (const target of targets) {
      const res = await this.fetchFn(
        `https://fcm.googleapis.com/v1/projects/${this.creds.projectId}/messages:send`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token: target.token,
              notification: { title: message.title, body: message.body },
              data: message.data,
              android: { priority: 'HIGH' },
            },
          }),
        },
      );
      if (res.ok) {
        result.sent += 1;
        continue;
      }
      const text = await res.text();
      if (res.status === 401) this.cached = null;
      if (this.isDeadToken(res.status, text)) {
        result.invalidTokens.push(target.token);
        continue;
      }
      // Transient/auth errors: surface so the queue retries the whole job.
      throw new Error(`FCM send failed (${res.status}): ${text.slice(0, 200)}`);
    }
    return result;
  }

  private isDeadToken(status: number, body: string): boolean {
    if (status !== 400 && status !== 404) return false;
    try {
      const err = JSON.parse(body) as {
        error?: { details?: { errorCode?: string }[]; status?: string };
      };
      const codes = [
        err.error?.status,
        ...(err.error?.details?.map((d) => d.errorCode) ?? []),
      ];
      return codes.some((c) => c !== undefined && DEAD_TOKEN_CODES.has(c));
    } catch {
      return status === 404;
    }
  }

  private async accessToken(): Promise<string> {
    const now = Math.floor(Date.now() / 1000);
    if (this.cached && this.cached.expiresAt - 60 > now)
      return this.cached.token;

    const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
    const claims = b64url(
      JSON.stringify({
        iss: this.creds.clientEmail,
        scope: SCOPE,
        aud: TOKEN_URL,
        iat: now,
        exp: now + 3600,
      }),
    );
    const signature = createSign('RSA-SHA256')
      .update(`${header}.${claims}`)
      .sign(this.creds.privateKey.replace(/\\n/g, '\n'));
    const assertion = `${header}.${claims}.${b64url(signature)}`;

    const res = await this.fetchFn(TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }),
    });
    if (!res.ok) {
      throw new Error(`FCM auth failed (${res.status})`);
    }
    const json = (await res.json()) as {
      access_token: string;
      expires_in?: number;
    };
    this.cached = {
      token: json.access_token,
      expiresAt: now + (json.expires_in ?? 3600),
    };
    this.logger.debug('Obtained FCM access token');
    return json.access_token;
  }
}
