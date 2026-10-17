import { Module } from '@nestjs/common';
import { FavoritesController } from './favorites.controller';
import { FavoritesService } from './favorites.service';
import { InterestController } from './interest.controller';
import { InterestService } from './interest.service';

/** Phase 8 user engagement: favourites (8.1) and expressing interest (8.2). */
@Module({
  controllers: [FavoritesController, InterestController],
  providers: [FavoritesService, InterestService],
})
export class EngagementModule {}
