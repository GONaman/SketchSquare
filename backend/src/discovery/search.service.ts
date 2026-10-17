import { HttpStatus, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ApiException } from '../common/errors/api-exception';
import { Page, decodeCursor, encodeCursor } from '../common/pagination';
import { StorageService } from '../storage/storage.service';
import {
  DRAWING_SUMMARY_SELECT,
  DrawingSummary,
  toDrawingSummary,
} from './drawing-summary';
import { SearchQueryDto } from './dto/search-query.dto';
import { SearchParams, buildSearchQuery } from './search-query.builder';
import { DEFAULT_TOLERANCE_PCT, toFeet } from './size-match';

interface SearchRow {
  id: string;
  size_score?: number;
  [key: `k${number}`]: string;
}

@Injectable()
export class SearchService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}

  toParams(dto: SearchQueryDto): SearchParams {
    if ((dto.length === undefined) !== (dto.breadth === undefined)) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'length and breadth must be provided together',
      );
    }
    if (
      dto.minPricePaise !== undefined &&
      dto.maxPricePaise !== undefined &&
      dto.minPricePaise > dto.maxPricePaise
    ) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'minPricePaise cannot exceed maxPricePaise',
      );
    }
    const unit = dto.unit ?? 'ft';
    const q = dto.q?.trim();
    return {
      q: q || undefined,
      categoryId: dto.categoryId,
      size:
        dto.length !== undefined && dto.breadth !== undefined
          ? {
              lengthFt: toFeet(dto.length, unit),
              breadthFt: toFeet(dto.breadth, unit),
              tolerancePct: dto.tolerancePct ?? DEFAULT_TOLERANCE_PCT,
            }
          : undefined,
      cities: dto.city?.map((c) => c.trim()).filter(Boolean),
      minDrawingRating: dto.minDrawingRating,
      minArchitectRating: dto.minArchitectRating,
      priceType: dto.priceType,
      minPricePaise: dto.minPricePaise,
      maxPricePaise: dto.maxPricePaise,
      floors: dto.floors,
      facing: dto.facing,
      architectId: dto.architectId,
      sort: dto.sort ?? 'relevance',
      limit: dto.limit,
      cursor: decodeCursor<{ s: string; v: string[] }>(dto.cursor),
    };
  }

  async search(dto: SearchQueryDto): Promise<Page<DrawingSummary>> {
    return this.run(this.toParams(dto));
  }

  async run(params: SearchParams): Promise<Page<DrawingSummary>> {
    const built = buildSearchQuery(params);
    const rows = await this.prisma.$queryRaw<SearchRow[]>(built.sql);
    const hasMore = rows.length > params.limit;
    const pageRows = hasMore ? rows.slice(0, params.limit) : rows;

    const drawings = await this.prisma.drawing.findMany({
      where: { id: { in: pageRows.map((r) => r.id) } },
      select: DRAWING_SUMMARY_SELECT,
    });
    const byId = new Map(drawings.map((d) => [d.id, d]));

    const items = pageRows.flatMap((r) => {
      const d = byId.get(r.id);
      return d
        ? [
            toDrawingSummary(
              d,
              (key) => this.storage.previewUrl(key),
              built.hasSize ? r.size_score : undefined,
            ),
          ]
        : [];
    });

    const last = pageRows[pageRows.length - 1];
    const nextCursor =
      hasMore && last
        ? encodeCursor({
            s: params.sort,
            v: Array.from({ length: built.keyCount }, (_, i) => last[`k${i}`]),
          })
        : null;
    return { items, nextCursor };
  }
}
