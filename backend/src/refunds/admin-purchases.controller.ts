import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Roles } from '../common/decorators/access.decorators';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import {
  ListAdminPurchasesQueryDto,
  RefundPurchaseDto,
} from './dto/admin-purchases.dto';
import { RefundsService } from './refunds.service';

@ApiTags('admin')
@ApiBearerAuth()
@Roles('ADMIN')
@Controller('admin/purchases')
export class AdminPurchasesController {
  constructor(private readonly refunds: RefundsService) {}

  @Get()
  list(@Query() q: ListAdminPurchasesQueryDto) {
    return this.refunds.list(q);
  }

  @Get(':id')
  detail(@Param('id', ParseUUIDPipe) id: string) {
    return this.refunds.detail(id);
  }

  @Post(':id/refund')
  @HttpCode(200)
  refund(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('id') adminId: string,
    @Body() dto: RefundPurchaseDto,
  ) {
    return this.refunds.refund(id, adminId, dto.reason);
  }
}
