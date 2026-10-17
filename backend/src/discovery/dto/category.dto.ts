import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { RequestStatus } from '@prisma/client';
import { Transform } from 'class-transformer';
import { IsEnum, IsOptional, IsString, Length } from 'class-validator';
import { PageQueryDto } from '../../common/pagination';

export class CreateCategoryRequestDto {
  @ApiProperty({ minLength: 2, maxLength: 60 })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : value,
  )
  @IsString()
  @Length(2, 60)
  name!: string;
}

export class CategoryRequestsQueryDto extends PageQueryDto {
  @ApiPropertyOptional({ enum: RequestStatus, default: RequestStatus.PENDING })
  @IsOptional()
  @IsEnum(RequestStatus)
  status?: RequestStatus;
}
