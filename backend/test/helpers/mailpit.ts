const BASE = process.env.MAILPIT_URL ?? 'http://localhost:8025';

export interface MailpitMessage {
  ID: string;
  Subject: string;
  Text: string;
  HTML: string;
  To: { Address: string }[];
}

/** Polls Mailpit (docker compose) until a message to `to` arrives. Use unique recipient addresses per test. */
export async function waitForEmail(
  to: string,
  subjectContains?: string,
  timeoutMs = 10_000,
): Promise<MailpitMessage> {
  const deadline = Date.now() + timeoutMs;
  for (;;) {
    const res = await fetch(
      `${BASE}/api/v1/search?query=${encodeURIComponent(`to:${to}`)}`,
    );
    const list = (await res.json()) as {
      messages?: { ID: string; Subject: string }[];
    };
    const hit = list.messages?.find(
      (m) => !subjectContains || m.Subject.includes(subjectContains),
    );
    if (hit) {
      const full = await fetch(`${BASE}/api/v1/message/${hit.ID}`);
      return (await full.json()) as MailpitMessage;
    }
    if (Date.now() > deadline) {
      throw new Error(`No email to ${to} (${subjectContains ?? '*'}) arrived`);
    }
    await new Promise((r) => setTimeout(r, 200));
  }
}

export async function countEmails(to: string): Promise<number> {
  const res = await fetch(
    `${BASE}/api/v1/search?query=${encodeURIComponent(`to:${to}`)}`,
  );
  return ((await res.json()) as { messages_count: number }).messages_count;
}
