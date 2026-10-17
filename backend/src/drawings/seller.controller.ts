import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/decorators/current-user.decorator';
import { PageQueryDto } from '../common/pagination';
import { MyDrawingsQueryDto } from './dto/my-drawings-query.dto';
import { SellerService } from './seller.service';

@ApiTags('drawings')
@ApiBearerAuth()
@Controller('me/drawings')
export class MyDrawingsController {
  constructor(private readonly seller: SellerService) {}

  @Get()
  list(@CurrentUser() user: AuthUser, @Query() query: MyDrawingsQueryDto) {
    return this.seller.listMine(user.id, query);
  }
}

@ApiTags('drawings')
@ApiBearerAuth()
@Controller('drawings/:id')
export class SellerController {
  constructor(private readonly seller: SellerService) {}

  @Get('buyers')
  buyers(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Query() query: PageQueryDto,
  ) {
    return this.seller.buyers(user.id, id, query);
  }

  @Get('viewers')
  viewers(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Query() query: PageQueryDto,
  ) {
    return this.seller.viewers(user.id, id, query);
  }

  @Get('reviews')
  reviews(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Query() query: PageQueryDto,
  ) {
    return this.seller.reviews(user, id, query);
  }
}
