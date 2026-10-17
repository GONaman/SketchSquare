import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import {
  type AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';
import { AddCartItemDto } from './dto/add-cart-item.dto';
import { CartService, CartView } from './cart.service';

@ApiTags('cart')
@ApiBearerAuth()
@Controller('cart')
export class CartController {
  constructor(private readonly cart: CartService) {}

  @Get()
  get(@CurrentUser() user: AuthUser): Promise<CartView> {
    return this.cart.getCart(user.id);
  }

  @Post()
  add(
    @CurrentUser() user: AuthUser,
    @Body() dto: AddCartItemDto,
  ): Promise<CartView> {
    return this.cart.add(user.id, dto.drawingId);
  }

  @Delete(':drawingId')
  remove(
    @CurrentUser() user: AuthUser,
    @Param('drawingId', ParseUUIDPipe) drawingId: string,
  ): Promise<CartView> {
    return this.cart.remove(user.id, drawingId);
  }
}
