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
  ListVerificationsQueryDto,
  RejectVerificationDto,
} from './dto/verification.dto';
import { VerificationService } from './verification.service';

@ApiTags('admin')
@ApiBearerAuth()
@Roles('ADMIN')
@Controller('admin/verifications')
export class AdminVerificationController {
  constructor(private readonly verification: VerificationService) {}

  @Get()
  list(@Query() q: ListVerificationsQueryDto) {
    return this.verification.list(q.status, q.cursor, q.limit);
  }

  @Get(':id')
  detail(@Param('id', ParseUUIDPipe) id: string) {
    return this.verification.detail(id);
  }

  @Post(':id/approve')
  approve(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('id') adminId: string,
  ) {
    return this.verification.approve(id, adminId);
  }

  @Post(':id/reject')
  reject(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('id') adminId: string,
    @Body() dto: RejectVerificationDto,
  ) {
    return this.verification.reject(id, adminId, dto.note);
  }
}
