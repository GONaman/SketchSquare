import { Module } from '@nestjs/common';
import { PlagiarismCheckService } from './plagiarism-check.service';

@Module({
  providers: [PlagiarismCheckService],
  exports: [PlagiarismCheckService],
})
export class PlagiarismModule {}
