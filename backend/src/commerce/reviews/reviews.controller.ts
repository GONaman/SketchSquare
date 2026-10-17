import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Put,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import {
  type AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';
import { PutReviewDto } from './dto/put-review.dto';
import { ReviewsService, ReviewView } from './reviews.service';

@ApiTags('reviews')
@ApiBearerAuth()
@Controller('drawings')
export class ReviewsController {
  constructor(private readonly reviews: ReviewsService) {}

  @Put(':id/review')
  @HttpCode(HttpStatus.OK)
  put(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: PutReviewDto,
  ): Promise<ReviewView> {
    return this.reviews.upsert(user, id, dto.rating, dto.comment);
  }
}
