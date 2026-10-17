import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import {
  type AuthUser,
  CurrentUser,
} from '../common/decorators/current-user.decorator';
import { Page, PageQueryDto } from '../common/pagination';
import {
  DrawingDetail,
  DrawingDetailService,
  ReviewView,
} from './drawing-detail.service';

@ApiTags('discovery')
@ApiBearerAuth()
@Controller('drawings')
export class DrawingDetailController {
  constructor(private readonly detail: DrawingDetailService) {}

  // Registered after SearchController so the literal `search` route wins over `:id`.
  @Get(':id')
  @ApiOperation({
    summary:
      'Drawing detail with watermarked previews and viewer flags; non-published drawings are owner/admin only',
  })
  get(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<DrawingDetail> {
    return this.detail.get(user, id);
  }

  @Get(':id/reviews')
  @ApiOperation({ summary: 'Reviews of a drawing, newest first' })
  reviews(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Query() page: PageQueryDto,
  ): Promise<Page<ReviewView>> {
    return this.detail.listReviews(user, id, page);
  }
}
