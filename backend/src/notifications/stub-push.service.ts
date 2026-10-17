import { Injectable, Logger } from '@nestjs/common';
import type {
  PushMessage,
  PushResult,
  PushService,
  PushTarget,
} from './push.service';

export interface StubPush {
  at: Date;
  target: PushTarget;
  message: PushMessage;
}

const KEEP = 200;

/** Used when no FCM credentials are configured: logs the push and remembers the latest ones (inspectable in tests). */
@Injectable()
export class StubPushService implements PushService {
  private readonly logger = new Logger(StubPushService.name);
  readonly sent: StubPush[] = [];

  send(targets: PushTarget[], message: PushMessage): Promise<PushResult> {
    for (const target of targets) {
      this.logger.log(
        `[stub push → ${target.platform}] ${message.title}: ${message.body}`,
      );
      this.sent.push({ at: new Date(), target, message });
    }
    if (this.sent.length > KEEP) this.sent.splice(0, this.sent.length - KEEP);
    return Promise.resolve({ sent: targets.length, invalidTokens: [] });
  }
}
