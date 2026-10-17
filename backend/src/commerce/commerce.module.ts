import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Env } from '../config/env.schema';
import { LedgerModule } from '../ledger/ledger.module';
import { WatermarkModule } from '../watermark/watermark.module';
import { CartController } from './cart/cart.controller';
import { CartService } from './cart/cart.service';
import { CheckoutController } from './checkout/checkout.controller';
import { CheckoutService } from './checkout/checkout.service';
import { DownloadService } from './downloads/download.service';
import { DownloadsController } from './downloads/downloads.controller';
import { LibraryController } from './library/library.controller';
import { LibraryService } from './library/library.service';
import { PAYMENT_PROVIDER, PaymentProvider } from './payments/payment.provider';
import { PaymentSettlementService } from './payments/payment-settlement.service';
import { RazorpayPaymentProvider } from './payments/razorpay.provider';
import { RazorpayWebhookController } from './payments/razorpay-webhook.controller';
import { RazorpayWebhookService } from './payments/razorpay-webhook.service';
import { StubPaymentProvider } from './payments/stub-payment.provider';
import { ReviewsController } from './reviews/reviews.controller';
import { ReviewsService } from './reviews/reviews.service';

/** Purchasing, wallet and profile endpoints (Phases 5–6). Registered once in AppModule. */
@Module({
  imports: [LedgerModule, WatermarkModule],
  controllers: [
    CartController,
    CheckoutController,
    RazorpayWebhookController,
    DownloadsController,
    LibraryController,
    ReviewsController,
  ],
  providers: [
    CartService,
    CheckoutService,
    PaymentSettlementService,
    RazorpayWebhookService,
    DownloadService,
    LibraryService,
    ReviewsService,
    {
      provide: PAYMENT_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>): PaymentProvider => {
        const keyId = config.get('RAZORPAY_KEY_ID', { infer: true });
        const keySecret = config.get('RAZORPAY_KEY_SECRET', { infer: true });
        if (keyId && keySecret) {
          return new RazorpayPaymentProvider({
            keyId,
            keySecret,
            webhookSecret: config.get('RAZORPAY_WEBHOOK_SECRET', {
              infer: true,
            }),
          });
        }
        return new StubPaymentProvider(
          config.get('NODE_ENV', { infer: true }) !== 'production',
        );
      },
    },
  ],
})
export class CommerceModule {}
