import { Body, Controller, Get, HttpCode, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { IsNotEmpty, IsString } from 'class-validator';
import {
  type AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';
import { CheckoutResult, CheckoutService } from './checkout.service';
import { StubCompleteDto, VerifyPaymentDto } from './dto/checkout.dto';

class OrderStatusQueryDto {
  @IsString()
  @IsNotEmpty()
  orderId!: string;
}

@ApiTags('checkout')
@ApiBearerAuth()
@Controller('checkout')
export class CheckoutController {
  constructor(private readonly checkout: CheckoutService) {}

  @Post()
  @HttpCode(200)
  @Throttle({ write: { limit: 20, ttl: 60_000 } })
  create(@CurrentUser() user: AuthUser): Promise<CheckoutResult> {
    return this.checkout.checkout(user.id);
  }

  @Post('verify')
  @HttpCode(200)
  verify(@CurrentUser() user: AuthUser, @Body() dto: VerifyPaymentDto) {
    return this.checkout.verify(user.id, dto);
  }

  @Post('stub-complete')
  @HttpCode(200)
  stubComplete(@CurrentUser() user: AuthUser, @Body() dto: StubCompleteDto) {
    return this.checkout.stubComplete(user.id, dto.orderId);
  }

  @Get('status')
  status(@CurrentUser() user: AuthUser, @Query() q: OrderStatusQueryDto) {
    return this.checkout.getStatus(user.id, q.orderId);
  }
}
