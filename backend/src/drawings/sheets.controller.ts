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
import {
  RegisterSheetDto,
  UpdateSheetDto,
  UploadUrlDto,
} from './dto/sheet.dto';
import { SheetsService } from './sheets.service';

@ApiTags('drawings')
@ApiBearerAuth()
@Controller('drawings/:drawingId/sheets')
export class SheetsController {
  constructor(private readonly sheets: SheetsService) {}

  @Post('upload-url')
  @HttpCode(HttpStatus.OK)
  uploadUrl(
    @CurrentUser() user: AuthUser,
    @Param('drawingId', ParseUUIDPipe) drawingId: string,
    @Body() dto: UploadUrlDto,
  ) {
    return this.sheets.createUploadUrl(user.id, drawingId, dto);
  }

  @Post()
  register(
    @CurrentUser() user: AuthUser,
    @Param('drawingId', ParseUUIDPipe) drawingId: string,
    @Body() dto: RegisterSheetDto,
  ) {
    return this.sheets.register(user.id, drawingId, dto);
  }

  @Patch(':sheetId')
  update(
    @CurrentUser() user: AuthUser,
    @Param('drawingId', ParseUUIDPipe) drawingId: string,
    @Param('sheetId', ParseUUIDPipe) sheetId: string,
    @Body() dto: UpdateSheetDto,
  ) {
    return this.sheets.update(user.id, drawingId, sheetId, dto);
  }

  @Delete(':sheetId')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @CurrentUser() user: AuthUser,
    @Param('drawingId', ParseUUIDPipe) drawingId: string,
    @Param('sheetId', ParseUUIDPipe) sheetId: string,
  ) {
    return this.sheets.remove(user.id, drawingId, sheetId);
  }
}
