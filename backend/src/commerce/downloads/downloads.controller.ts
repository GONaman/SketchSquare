import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import {
  type AuthUser,
  CurrentUser,
} from '../../common/decorators/current-user.decorator';
import { DownloadQueryDto } from './dto/download-query.dto';
import { DownloadLink, DownloadService } from './download.service';

@ApiTags('downloads')
@ApiBearerAuth()
@Controller('drawings')
export class DownloadsController {
  constructor(private readonly downloads: DownloadService) {}

  @Get(':id/download')
  download(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Query() query: DownloadQueryDto,
  ): Promise<DownloadLink> {
    return this.downloads.createLink(user, id, query.sheetId);
  }
}
