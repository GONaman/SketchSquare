import { Module } from '@nestjs/common';
import { FavoritesController } from './favorites.controller';
import { FavoritesService } from './favorites.service';

/** Phase 8 user engagement: favourites (8.1) and expressing interest (8.2). */
@Module({
  controllers: [FavoritesController],
  providers: [FavoritesService],
})
export class EngagementModule {}
