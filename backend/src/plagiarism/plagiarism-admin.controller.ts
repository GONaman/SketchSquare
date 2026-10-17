import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Roles } from '../common/decorators/access.decorators';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import {
  ListPlagiarismFlagsQueryDto,
  RejectPlagiarismFlagDto,
} from './dto/plagiarism-flag.dto';
import { PlagiarismAdminService } from './plagiarism-admin.service';

@ApiTags('admin')
@ApiBearerAuth()
@Roles('ADMIN')
@Controller('admin/plagiarism-flags')
export class PlagiarismAdminController {
  constructor(private readonly admin: PlagiarismAdminService) {}

  @Get()
  list(@Query() q: ListPlagiarismFlagsQueryDto) {
    return this.admin.list(q.status, q.cursor, q.limit);
  }

  @Post(':id/approve')
  approve(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('id') adminId: string,
  ) {
    return this.admin.approve(id, adminId);
  }

  @Post(':id/reject')
  reject(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('id') adminId: string,
    @Body() dto: RejectPlagiarismFlagDto,
  ) {
    return this.admin.reject(id, adminId, dto.reason);
  }
}
