import { Module } from '@nestjs/common';
import { DrawingsController } from './drawings.controller';
import { DrawingsService } from './drawings.service';
import { SheetsController } from './sheets.controller';
import { SheetsService } from './sheets.service';

@Module({
  controllers: [DrawingsController, SheetsController],
  providers: [DrawingsService, SheetsService],
  exports: [DrawingsService],
})
export class DrawingsModule {}
