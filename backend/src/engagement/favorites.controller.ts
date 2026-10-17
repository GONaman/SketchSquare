import {
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Put,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import {
  type AuthUser,
  CurrentUser,
} from '../common/decorators/current-user.decorator';
import { Page, PageQueryDto } from '../common/pagination';
import { DrawingSummary } from '../discovery/drawing-summary';
import { FavoritesService } from './favorites.service';

@ApiTags('favorites')
@ApiBearerAuth()
@Controller()
export class FavoritesController {
  constructor(private readonly favorites: FavoritesService) {}

  @Put('drawings/:id/favorite')
  @HttpCode(204)
  @ApiOperation({ summary: 'Favourite a drawing (idempotent)' })
  add(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    return this.favorites.add(user.id, id);
  }

  @Delete('drawings/:id/favorite')
  @HttpCode(204)
  @ApiOperation({ summary: 'Remove a favourite (idempotent)' })
  remove(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    return this.favorites.remove(user.id, id);
  }

  @Get('me/favorites')
  @ApiOperation({ summary: 'My favourite drawings, most recently added first' })
  list(
    @CurrentUser() user: AuthUser,
    @Query() query: PageQueryDto,
  ): Promise<Page<DrawingSummary>> {
    return this.favorites.list(user.id, query);
  }
}
