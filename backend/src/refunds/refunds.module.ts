import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Env } from '../config/env.schema';
import { LedgerModule } from '../ledger/ledger.module';
import { AdminPurchasesController } from './admin-purchases.controller';
import { REFUND_PROVIDER, RefundProvider } from './refund.provider';
import { RefundsService } from './refunds.service';
import { RazorpayRefundProvider } from './razorpay-refund.provider';
import { StubRefundProvider } from './stub-refund.provider';

/** Admin purchase search + refunds (Part 3). Registered once in AppModule. */
@Module({
  imports: [LedgerModule],
  controllers: [AdminPurchasesController],
  providers: [
    RefundsService,
    {
      provide: REFUND_PROVIDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>): RefundProvider => {
        const keyId = config.get('RAZORPAY_KEY_ID', { infer: true });
        const keySecret = config.get('RAZORPAY_KEY_SECRET', { infer: true });
        if (keyId && keySecret) {
          return new RazorpayRefundProvider({ keyId, keySecret });
        }
        return new StubRefundProvider(
          config.get('NODE_ENV', { infer: true }) !== 'production',
        );
      },
    },
  ],
})
export class RefundsModule {}
