import { Module } from '@nestjs/common';
import { ArchitectsController } from './architects.controller';
import { ArchitectsService } from './architects.service';
import { CategoriesController } from './categories.controller';
import { CategoriesService } from './categories.service';
import { CitiesController } from './cities.controller';
import { CitiesService } from './cities.service';
import { SearchController } from './search.controller';
import { SearchService } from './search.service';

@Module({
  controllers: [
    SearchController,
    CategoriesController,
    CitiesController,
    ArchitectsController,
  ],
  providers: [
    SearchService,
    CategoriesService,
    CitiesService,
    ArchitectsService,
  ],
  exports: [SearchService],
})
export class DiscoveryModule {}
