import { IsOptional, IsUUID } from 'class-validator';

export class DownloadQueryDto {
  @IsOptional()
  @IsUUID()
  sheetId?: string;
}
