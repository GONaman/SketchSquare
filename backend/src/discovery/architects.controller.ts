import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Page, PageQueryDto } from '../common/pagination';
import { ArchitectsService, TopArchitect } from './architects.service';
import { ArchitectSummary, DrawingSummary } from './drawing-summary';
import { TopArchitectsQueryDto } from './dto/architects.dto';

@ApiTags('discovery')
@ApiBearerAuth()
@Controller('architects')
export class ArchitectsController {
  constructor(private readonly architects: ArchitectsService) {}

  // Declared before ':id' so "top" is never parsed as an id.
  @Get('top')
  top(@Query() query: TopArchitectsQueryDto): Promise<TopArchitect[]> {
    return this.architects.top(query.city);
  }

  @Get(':id')
  profile(
    @Param('id', ParseUUIDPipe) id: string,
    @Query() page: PageQueryDto,
  ): Promise<{ architect: ArchitectSummary; drawings: Page<DrawingSummary> }> {
    return this.architects.profile(id, page);
  }

  @Get(':id/drawings')
  drawings(
    @Param('id', ParseUUIDPipe) id: string,
    @Query() page: PageQueryDto,
  ): Promise<Page<DrawingSummary>> {
    return this.architects.drawings(id, page);
  }
}
