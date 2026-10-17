import { BullModule } from '@nestjs/bullmq';
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
import { PAYOUT_PROVIDER, PayoutProvider } from './payouts/payout.provider';
import { PayoutProcessor } from './payouts/payout.processor';
import {
  BullPayoutQueue,
  PAYOUT_QUEUE,
  PAYOUT_QUEUE_NAME,
} from './payouts/payout.queue';
import { PayoutRecoveryService } from './payouts/payout-recovery.service';
import { PayoutService } from './payouts/payout.service';
import { RazorpayXPayoutProvider } from './payouts/razorpayx.provider';
import { RazorpayXWebhookController } from './payouts/razorpayx-webhook.controller';
import { RazorpayXWebhookService } from './payouts/razorpayx-webhook.service';
import { StubPayoutProvider } from './payouts/stub-payout.provider';
import { ProfileController } from './profile/profile.controller';
import { ProfileService } from './profile/profile.service';
import { ReviewsController } from './reviews/reviews.controller';
import { ReviewsService } from './reviews/reviews.service';
import { WalletController } from './wallet/wallet.controller';
import { WalletService } from './wallet/wallet.service';

/** Purchasing, wallet and profile endpoints (Phases 5–6). Registered once in AppModule. */
@Module({
  imports: [
    LedgerModule,
    WatermarkModule,
    BullModule.registerQueue({ name: PAYOUT_QUEUE_NAME }),
  ],
  controllers: [
    CartController,
    CheckoutController,
    RazorpayWebhookController,
    DownloadsController,
    LibraryController,
    ReviewsController,
    WalletController,
    ProfileController,
    RazorpayXWebhookController,
  ],
  providers: [
    CartService,
    CheckoutService,
    PaymentSettlementService,
    RazorpayWebhookService,
    DownloadService,
    LibraryService,
    ReviewsService,
    WalletService,
    ProfileService,
    PayoutService,
    PayoutProcessor,
    PayoutRecoveryService,
    RazorpayXWebhookService,
    { provide: PAYOUT_QUEUE, useClass: BullPayoutQueue },
    {
      provide: PAYOUT_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>): PayoutProvider => {
        const keyId = config.get('RAZORPAYX_KEY_ID', { infer: true });
        const keySecret = config.get('RAZORPAYX_KEY_SECRET', { infer: true });
        const account = config.get('RAZORPAYX_ACCOUNT_NUMBER', { infer: true });
        if (
          config.get('PAYOUT_PROVIDER', { infer: true }) === 'razorpayx' &&
          keyId &&
          keySecret &&
          account
        ) {
          return new RazorpayXPayoutProvider({
            keyId,
            keySecret,
            accountNumber: account,
            webhookSecret: config.get('RAZORPAYX_WEBHOOK_SECRET', {
              infer: true,
            }),
          });
        }
        return new StubPayoutProvider(
          config.get('NODE_ENV', { infer: true }) !== 'production',
        );
      },
    },
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
