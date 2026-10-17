import { Module } from '@nestjs/common';
import { AdminVerificationController } from './admin-verification.controller';
import { KycStorageService } from './kyc-storage.service';
import { VerificationController } from './verification.controller';
import { VerificationService } from './verification.service';

@Module({
  controllers: [VerificationController, AdminVerificationController],
  providers: [VerificationService, KycStorageService],
})
export class VerificationModule {}
