import { Module } from '@nestjs/common';
import { WatermarkService } from './watermark.service';

/** Import this module wherever previews or buyer-specific copies are produced (StorageModule is global). */
@Module({
  providers: [WatermarkService],
  exports: [WatermarkService],
})
export class WatermarkModule {}
