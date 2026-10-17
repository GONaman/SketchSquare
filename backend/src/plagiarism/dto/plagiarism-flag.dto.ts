import { ApiPropertyOptional } from '@nestjs/swagger';
import { PlagiarismFlagStatus } from '@prisma/client';
import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { PageQueryDto } from '../../common/pagination';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

export class ListPlagiarismFlagsQueryDto extends PageQueryDto {
  @ApiPropertyOptional({
    enum: PlagiarismFlagStatus,
    default: PlagiarismFlagStatus.PENDING,
  })
  @IsOptional()
  @IsEnum(PlagiarismFlagStatus)
  status: PlagiarismFlagStatus = PlagiarismFlagStatus.PENDING;
}

export class RejectPlagiarismFlagDto {
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  reason!: string;
}
