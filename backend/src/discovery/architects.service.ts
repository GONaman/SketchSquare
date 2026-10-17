import { HttpStatus, Injectable } from '@nestjs/common';
import { ApiException } from '../common/errors/api-exception';
import { Page, PageQueryDto, decodeCursor } from '../common/pagination';
import { PrismaService } from '../prisma/prisma.service';
import { ArchitectSummary, DrawingSummary } from './drawing-summary';
import { SearchService } from './search.service';

const ARCHITECT_SELECT = {
  id: true,
  fullName: true,
  city: true,
  architectRating: true,
  architectRatingCount: true,
  avatarUrl: true,
} as const;

function toSummary(r: {
  id: string;
  fullName: string;
  city: string;
  architectRating: number;
  architectRatingCount: number;
  avatarUrl: string | null;
}): ArchitectSummary {
  return {
    id: r.id,
    fullName: r.fullName,
    city: r.city,
    architectRating: r.architectRating,
    ratingCount: r.architectRatingCount,
    avatarUrl: r.avatarUrl,
  };
}

export const MIN_RATINGS_FOR_TOP = 3;
export const TOP_ARCHITECTS_LIMIT = 20;

export type TopArchitect = ArchitectSummary & { drawingCount: number };

const PUBLISHED = { status: 'PUBLISHED' } as const;

@Injectable()
export class ArchitectsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly search: SearchService,
  ) {}

  async top(city?: string): Promise<TopArchitect[]> {
    const rows = await this.prisma.user.findMany({
      where: {
        role: 'ARCHITECT',
        verificationStatus: 'APPROVED',
        architectRatingCount: { gte: MIN_RATINGS_FOR_TOP },
        ...(city ? { city: { equals: city, mode: 'insensitive' } } : {}),
      },
      orderBy: [
        { architectRating: 'desc' },
        { architectRatingCount: 'desc' },
        { id: 'asc' },
      ],
      take: TOP_ARCHITECTS_LIMIT,
      select: {
        ...ARCHITECT_SELECT,
        _count: { select: { drawings: { where: PUBLISHED } } },
      },
    });
    return rows.map((r) => ({
      ...toSummary(r),
      drawingCount: r._count.drawings,
    }));
  }

  async profile(
    id: string,
    page: PageQueryDto,
  ): Promise<{ architect: ArchitectSummary; drawings: Page<DrawingSummary> }> {
    const architect = await this.findArchitect(id);
    return { architect, drawings: await this.drawings(id, page) };
  }

  async drawings(
    architectId: string,
    page: PageQueryDto,
  ): Promise<Page<DrawingSummary>> {
    await this.findArchitect(architectId);
    return this.search.run({
      architectId,
      sort: 'newest',
      limit: page.limit,
      cursor: decodeCursor<{ s: string; v: string[] }>(page.cursor),
    });
  }

  private async findArchitect(id: string): Promise<ArchitectSummary> {
    const row = await this.prisma.user.findFirst({
      where: { id, role: 'ARCHITECT', verificationStatus: 'APPROVED' },
      select: ARCHITECT_SELECT,
    });
    if (!row) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Architect not found',
      );
    }
    return toSummary(row);
  }
}
