import { ApiPropertyOptional } from '@nestjs/swagger';
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

export const MAX_PRICE_PAISE = 100_000_000; // ₹10,00,000
export const PLOT_UNITS = ['ft', 'm'] as const;
export type PlotUnit = (typeof PLOT_UNITS)[number];

export class CreateDrawingDto {
  @IsString()
  @Length(3, 120)
  title!: string;

  @IsString()
  @Length(1, 5000)
  description!: string;

  @IsUUID()
  categoryId!: string;

  @IsString()
  @Length(1, 80)
  city!: string;

  @ApiPropertyOptional({ description: 'Plot length in `unit`', example: 40 })
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 4 })
  @IsPositive()
  @Max(100000)
  plotLength!: number;

  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 4 })
  @IsPositive()
  @Max(100000)
  plotBreadth!: number;

  @IsIn(PLOT_UNITS)
  unit!: PlotUnit;

  @IsInt()
  @Min(1)
  @Max(100)
  floors!: number;

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

  @ApiPropertyOptional({
    description: 'Integer paise. Required unless `isFree` is true.',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(MAX_PRICE_PAISE)
  pricePaise?: number;

  @ApiPropertyOptional({ description: 'Forces pricePaise = 0' })
  @IsOptional()
  @IsBoolean()
  isFree?: boolean;
}
