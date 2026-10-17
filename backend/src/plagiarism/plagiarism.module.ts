import { Module } from '@nestjs/common';
import { PlagiarismAdminController } from './plagiarism-admin.controller';
import { PlagiarismAdminService } from './plagiarism-admin.service';
import { PlagiarismCheckService } from './plagiarism-check.service';

@Module({
  controllers: [PlagiarismAdminController],
  providers: [PlagiarismCheckService, PlagiarismAdminService],
  exports: [PlagiarismCheckService],
})
export class PlagiarismModule {}
