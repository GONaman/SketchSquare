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
import { InterestedUser, InterestService } from './interest.service';

@ApiTags('interest')
@ApiBearerAuth()
@Controller('drawings/:id')
export class InterestController {
  constructor(private readonly interest: InterestService) {}

  @Put('interest')
  @HttpCode(204)
  @ApiOperation({
    summary: 'Express interest in a paid drawing (idempotent; not your own)',
  })
  async add(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    await this.interest.add(user, id);
  }

  @Delete('interest')
  @HttpCode(204)
  @ApiOperation({ summary: 'Withdraw interest (idempotent)' })
  remove(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    return this.interest.remove(user.id, id);
  }

  // `interested` is an alias of the contract path `interests`.
  @Get(['interests', 'interested'])
  @ApiOperation({
    summary: 'Users interested in my drawing, newest first (owner only)',
  })
  list(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Query() query: PageQueryDto,
  ): Promise<Page<InterestedUser>> {
    return this.interest.listInterested(user.id, id, query);
  }
}
