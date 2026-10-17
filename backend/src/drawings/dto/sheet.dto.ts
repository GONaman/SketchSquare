import { SheetType } from '@prisma/client';
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Min,
} from 'class-validator';

export class UploadUrlDto {
  @IsString()
  @Length(1, 200)
  fileName!: string;

  @IsString()
  @Length(1, 100)
  contentType!: string;

  @IsInt()
  @Min(1)
  sizeBytes!: number;
}

export class RegisterSheetDto {
  @IsEnum(SheetType)
  type!: SheetType;

  @IsString()
  @Length(1, 400)
  objectKey!: string;

  @IsBoolean()
  isPreview!: boolean;

  @IsString()
  @Length(1, 200)
  fileName!: string;

  @IsInt()
  @Min(1)
  sizeBytes!: number;
}

export class UpdateSheetDto {
  @IsOptional()
  @IsEnum(SheetType)
  type?: SheetType;

  @IsOptional()
  @IsBoolean()
  isPreview?: boolean;
}
