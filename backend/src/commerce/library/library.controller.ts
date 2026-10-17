import { Controller, Get, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import {
  type AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';
import { Page, PageQueryDto } from '../../common/pagination';
import { LibraryItem, LibraryService } from './library.service';

@ApiTags('library')
@ApiBearerAuth()
@Controller('me')
export class LibraryController {
  constructor(private readonly library: LibraryService) {}

  @Get('purchases')
  purchases(
    @CurrentUser() user: AuthUser,
    @Query() query: PageQueryDto,
  ): Promise<Page<LibraryItem>> {
    return this.library.list(user.id, query.cursor, query.limit);
  }
}
