import {
  Body,
  Controller,
  Delete,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/decorators/current-user.decorator';
import { CreateDrawingDto } from './dto/create-drawing.dto';
import { UpdateDrawingDto } from './dto/update-drawing.dto';
import { DrawingsService } from './drawings.service';

@ApiTags('drawings')
@ApiBearerAuth()
@Controller('drawings')
export class DrawingsController {
  constructor(private readonly drawings: DrawingsService) {}

  @Post()
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateDrawingDto) {
    return this.drawings.create(user.id, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateDrawingDto,
  ) {
    return this.drawings.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.drawings.remove(user.id, id);
  }
}
