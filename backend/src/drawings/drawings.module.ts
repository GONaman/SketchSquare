import { BullModule } from '@nestjs/bullmq';
import { Module } from '@nestjs/common';
import { WatermarkModule } from '../watermark/watermark.module';
import { DrawingProcessingService } from './drawing-processing.service';
import { DrawingProcessor } from './drawing.processor';
import { DrawingsController } from './drawings.controller';
import { DRAWING_PROCESSING_QUEUE } from './drawings.constants';
import { DrawingsService } from './drawings.service';
import { PublishService } from './publish.service';
import { MyDrawingsController, SellerController } from './seller.controller';
import { SellerService } from './seller.service';
import { SheetsController } from './sheets.controller';
import { SheetsService } from './sheets.service';

@Module({
  imports: [
    WatermarkModule,
    BullModule.registerQueue({ name: DRAWING_PROCESSING_QUEUE }),
  ],
  controllers: [
    DrawingsController,
    SheetsController,
    MyDrawingsController,
    SellerController,
  ],
  providers: [
    DrawingsService,
    SheetsService,
    SellerService,
    PublishService,
    DrawingProcessingService,
    DrawingProcessor,
  ],
  exports: [DrawingsService],
})
export class DrawingsModule {}
