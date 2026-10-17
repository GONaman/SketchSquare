import {
  Controller,
  Headers,
  HttpCode,
  Post,
  type RawBodyRequest,
  Req,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import type { Request } from 'express';
import { Public } from '../../common/decorators/access.decorators';
import {
  PayoutWebhookResult,
  RazorpayXWebhookService,
} from './razorpayx-webhook.service';

@ApiTags('payments')
@Controller('payments/razorpayx')
export class RazorpayXWebhookController {
  constructor(private readonly webhooks: RazorpayXWebhookService) {}

  /** Payout status callbacks: signature-verified (HMAC over the raw body) and idempotent by `x-razorpay-event-id`. */
  @Public()
  @Post('webhook')
  // Provider traffic is bursty; the HMAC signature is the real gate, this only caps unsigned floods.
  @Throttle({ write: { limit: 600, ttl: 60_000 } })
  @HttpCode(200)
  webhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('x-razorpay-signature') signature?: string,
    @Headers('x-razorpay-event-id') eventId?: string,
  ): Promise<PayoutWebhookResult> {
    return this.webhooks.handle(req.rawBody, signature, eventId);
  }
}
