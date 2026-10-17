import { ApiPropertyOptional } from '@nestjs/swagger';
import { DrawingStatus } from '@prisma/client';
import { IsEnum, IsOptional } from 'class-validator';
import { PageQueryDto } from '../../common/pagination';

export class MyDrawingsQueryDto extends PageQueryDto {
  @ApiPropertyOptional({
    enum: DrawingStatus,
    description: 'Defaults to every status except REMOVED',
  })
  @IsOptional()
  @IsEnum(DrawingStatus)
  status?: DrawingStatus;
}
