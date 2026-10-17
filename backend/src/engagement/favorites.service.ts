import { HttpStatus, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { ApiException } from '../common/errors/api-exception';
import { decodeCursor, Page, PageQueryDto, toPage } from '../common/pagination';
import {
  DRAWING_SUMMARY_SELECT,
  DrawingSummary,
  toDrawingSummary,
} from '../discovery/drawing-summary';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';

interface FavoriteCursor extends Record<string, unknown> {
  at: string;
  id: string;
}

/** Same visibility as search: only published drawings of approved architects can be favourited or listed. */
const LISTABLE = {
  status: 'PUBLISHED',
  architect: { verificationStatus: 'APPROVED' },
} satisfies Prisma.DrawingWhereInput;

@Injectable()
export class FavoritesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}

  /** Idempotent: favouriting twice keeps the original `createdAt`. */
  async add(userId: string, drawingId: string): Promise<void> {
    const drawing = await this.prisma.drawing.findFirst({
      where: { id: drawingId, ...LISTABLE },
      select: { id: true },
    });
    if (!drawing) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Drawing not found',
      );
    }
    await this.prisma.favorite.createMany({
      data: [{ userId, drawingId }],
      skipDuplicates: true,
    });
  }

  /** Idempotent; also works for drawings that were removed since being favourited. */
  async remove(userId: string, drawingId: string): Promise<void> {
    await this.prisma.favorite.deleteMany({ where: { userId, drawingId } });
  }

  async list(
    userId: string,
    query: PageQueryDto,
  ): Promise<Page<DrawingSummary>> {
    const c = decodeCursor<FavoriteCursor>(query.cursor);
    const at = c ? new Date(c.at) : null;
    if (c && (typeof c.id !== 'string' || !at || Number.isNaN(at.getTime()))) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Invalid cursor',
      );
    }
    const rows = await this.prisma.favorite.findMany({
      where: {
        userId,
        drawing: LISTABLE,
        ...(c && at
          ? {
              OR: [
                { createdAt: { lt: at } },
                { createdAt: at, drawingId: { lt: c.id } },
              ],
            }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { drawingId: 'desc' }],
      take: query.limit + 1,
      select: {
        createdAt: true,
        drawingId: true,
        drawing: { select: DRAWING_SUMMARY_SELECT },
      },
    });
    const page = toPage(rows, query.limit, (r) => ({
      at: r.createdAt.toISOString(),
      id: r.drawingId,
    }));
    return {
      items: page.items.map((r) =>
        toDrawingSummary(r.drawing, (key) => this.storage.previewUrl(key)),
      ),
      nextCursor: page.nextCursor,
    };
  }
}
