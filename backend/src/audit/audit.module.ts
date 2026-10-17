import { Global, Module } from '@nestjs/common';
import { AuditService } from './audit.service';

/** Global: inject `AuditService` in any admin-facing service. */
@Global()
@Module({
  providers: [AuditService],
  exports: [AuditService],
})
export class AuditModule {}
