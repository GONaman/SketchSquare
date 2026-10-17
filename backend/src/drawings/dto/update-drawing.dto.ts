import { Facing } from '@prisma/client';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
  Length,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { MAX_PRICE_PAISE, PLOT_UNITS } from './create-drawing.dto';
import type { PlotUnit } from './create-drawing.dto';

/** Drafts accept every field; published drawings only title, description and price (checked in the service). */
export class UpdateDrawingDto {
  @IsOptional()
  @IsString()
  @Length(3, 120)
  title?: string;

  @IsOptional()
  @IsString()
  @Length(1, 5000)
  description?: string;

  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @IsOptional()
  @IsString()
  @Length(1, 80)
  city?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 4 })
  @IsPositive()
  @Max(100000)
  plotLength?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 4 })
  @IsPositive()
  @Max(100000)
  plotBreadth?: number;

  @IsOptional()
  @IsIn(PLOT_UNITS)
  unit?: PlotUnit;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  floors?: number;

  @IsOptional()
  @IsEnum(Facing)
  facing?: Facing;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(20)
  bedrooms?: number;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(8)
  @IsString({ each: true })
  @MaxLength(24, { each: true })
  tags?: string[];

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(MAX_PRICE_PAISE)
  pricePaise?: number;

  @IsOptional()
  @IsBoolean()
  isFree?: boolean;
}
