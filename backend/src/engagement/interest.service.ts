import { HttpStatus, Injectable } from '@nestjs/common';
import { ApiException } from '../common/errors/api-exception';
import { decodeCursor, Page, PageQueryDto, toPage } from '../common/pagination';
import { PrismaService } from '../prisma/prisma.service';

interface InterestCursor extends Record<string, unknown> {
  at: string;
  id: string;
}

export interface InterestedUser {
  user: { id: string; fullName: string; city: string };
  createdAt: Date;
}

@Injectable()
export class InterestService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Idempotent. Only for published, paid drawings of approved architects that the caller does not own.
   * Returns whether a new interest was recorded (false on a repeat), so callers can notify only once.
   */
  async add(userId: string, drawingId: string): Promise<boolean> {
    const drawing = await this.prisma.drawing.findFirst({
      where: {
        id: drawingId,
        status: 'PUBLISHED',
        architect: { verificationStatus: 'APPROVED' },
      },
      select: { architectId: true, pricePaise: true },
    });
    if (!drawing) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Drawing not found',
      );
    }
    if (drawing.architectId === userId) {
      throw new ApiException(
        HttpStatus.FORBIDDEN,
        'FORBIDDEN',
        'You cannot express interest in your own drawing',
      );
    }
    if (drawing.pricePaise === 0) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Interest can only be expressed for paid drawings; free drawings can be downloaded directly',
      );
    }
    const { count } = await this.prisma.interest.createMany({
      data: [{ userId, drawingId }],
      skipDuplicates: true,
    });
    return count > 0;
  }

  /** Idempotent; also works after the drawing was removed or turned free. */
  async remove(userId: string, drawingId: string): Promise<void> {
    await this.prisma.interest.deleteMany({ where: { userId, drawingId } });
  }

  /** Owner only (also for removed drawings). Missing → 404, someone else's → 403. */
  async listInterested(
    ownerId: string,
    drawingId: string,
    query: PageQueryDto,
  ): Promise<Page<InterestedUser>> {
    const drawing = await this.prisma.drawing.findUnique({
      where: { id: drawingId },
      select: { architectId: true },
    });
    if (!drawing) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Drawing not found',
      );
    }
    if (drawing.architectId !== ownerId) {
      throw new ApiException(
        HttpStatus.FORBIDDEN,
        'FORBIDDEN',
        'You do not own this drawing',
      );
    }
    const c = decodeCursor<InterestCursor>(query.cursor);
    const at = c ? new Date(c.at) : null;
    if (c && (typeof c.id !== 'string' || !at || Number.isNaN(at.getTime()))) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Invalid cursor',
      );
    }
    const rows = await this.prisma.interest.findMany({
      where: {
        drawingId,
        ...(c && at
          ? {
              OR: [
                { createdAt: { lt: at } },
                { createdAt: at, userId: { lt: c.id } },
              ],
            }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { userId: 'desc' }],
      take: query.limit + 1,
      select: {
        createdAt: true,
        userId: true,
        user: { select: { id: true, fullName: true, city: true } },
      },
    });
    const page = toPage(rows, query.limit, (r) => ({
      at: r.createdAt.toISOString(),
      id: r.userId,
    }));
    return {
      items: page.items.map((r) => ({ user: r.user, createdAt: r.createdAt })),
      nextCursor: page.nextCursor,
    };
  }
}
