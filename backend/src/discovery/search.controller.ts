import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Page } from '../common/pagination';
import { DrawingSummary } from './drawing-summary';
import { SearchQueryDto } from './dto/search-query.dto';
import { SearchService } from './search.service';

@ApiTags('discovery')
@ApiBearerAuth()
@Controller('drawings')
export class SearchController {
  constructor(private readonly search: SearchService) {}

  @Get('search')
  @ApiOperation({
    summary:
      'Search published drawings by text, plot size (with tolerance and rotation) and filters',
  })
  searchDrawings(
    @Query() query: SearchQueryDto,
  ): Promise<Page<DrawingSummary>> {
    return this.search.search(query);
  }
}
