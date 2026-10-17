import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';
import { RequestStatus } from '@prisma/client';
import { PageQueryDto } from '../../common/pagination';

const trim = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() : value;

export class SubmitVerificationDto {
  @Transform(trim)
  @Matches(/^[A-Za-z0-9][A-Za-z0-9/-]{3,29}$/, {
    message:
      'coaRegistrationNumber must be 4-30 characters: letters, digits, "/" or "-"',
  })
  coaRegistrationNumber!: string;
}

export class ListVerificationsQueryDto extends PageQueryDto {
  @ApiPropertyOptional({ enum: RequestStatus, default: RequestStatus.PENDING })
  @IsOptional()
  @IsEnum(RequestStatus)
  status: RequestStatus = RequestStatus.PENDING;
}

export class RejectVerificationDto {
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  note!: string;
}
