import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { PageQueryDto } from '../../common/pagination';
import {
  DEFAULT_TOLERANCE_PCT,
  MAX_TOLERANCE_PCT,
  type LengthUnit,
} from '../size-match';
import {
  PRICE_TYPES,
  type PriceType,
  SEARCH_SORTS,
  type SearchSort,
} from '../search-query.builder';

const FACINGS = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];

/** `?city=a&city=b` arrives as an array, `?city=a` as a string: normalise to an array. */
const toArray = ({ value }: { value: unknown }): unknown =>
  value === undefined ? undefined : Array.isArray(value) ? value : [value];

const toNumberArray = ({ value }: { value: unknown }): unknown => {
  const arr = toArray({ value });
  return Array.isArray(arr) ? arr.map((v) => Number(v)) : arr;
};

export class SearchQueryDto extends PageQueryDto {
  @ApiPropertyOptional({
    description: 'Full-text query over title and description',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  q?: string;

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @ApiPropertyOptional({
    description: 'Plot length in `unit`; must be sent together with `breadth`',
    example: 30,
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @IsPositive()
  @Max(100000)
  length?: number;

  @ApiPropertyOptional({
    description: 'Plot breadth in `unit`; must be sent together with `length`',
    example: 40,
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @IsPositive()
  @Max(100000)
  breadth?: number;

  @ApiPropertyOptional({ enum: ['ft', 'm'], default: 'ft' })
  @IsOptional()
  @IsIn(['ft', 'm'])
  unit?: LengthUnit;

  @ApiPropertyOptional({
    minimum: 0,
    maximum: MAX_TOLERANCE_PCT,
    default: DEFAULT_TOLERANCE_PCT,
    description:
      'Each dimension may differ by this percent; the rotated plot also matches',
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(MAX_TOLERANCE_PCT)
  tolerancePct?: number;

  @ApiPropertyOptional({
    type: [String],
    description: 'Repeatable, case-insensitive',
  })
  @IsOptional()
  @Transform(toArray)
  @IsArray()
  @ArrayMaxSize(20)
  @IsString({ each: true })
  @MaxLength(80, { each: true })
  city?: string[];

  @ApiPropertyOptional({ minimum: 0, maximum: 5 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(5)
  minDrawingRating?: number;

  @ApiPropertyOptional({ minimum: 0, maximum: 5 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(5)
  minArchitectRating?: number;

  @ApiPropertyOptional({ enum: PRICE_TYPES, default: 'all' })
  @IsOptional()
  @IsIn(PRICE_TYPES)
  priceType?: PriceType;

  @ApiPropertyOptional({ minimum: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  minPricePaise?: number;

  @ApiPropertyOptional({ minimum: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  maxPricePaise?: number;

  @ApiPropertyOptional({
    type: [Number],
    description: 'Repeatable; number of floors',
  })
  @IsOptional()
  @Transform(toNumberArray)
  @IsArray()
  @ArrayMaxSize(10)
  @IsInt({ each: true })
  @Min(1, { each: true })
  @Max(100, { each: true })
  floors?: number[];

  @ApiPropertyOptional({
    type: [String],
    enum: FACINGS,
    description: 'Repeatable',
  })
  @IsOptional()
  @Transform(toArray)
  @IsArray()
  @ArrayMaxSize(8)
  @IsIn(FACINGS, { each: true })
  facing?: string[];

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID()
  architectId?: string;

  @ApiPropertyOptional({
    enum: SEARCH_SORTS,
    default: 'relevance',
    description:
      'relevance ranks by text match and size match (newest when neither is given); size_match requires length+breadth',
  })
  @IsOptional()
  @IsIn(SEARCH_SORTS)
  sort?: SearchSort;
}
