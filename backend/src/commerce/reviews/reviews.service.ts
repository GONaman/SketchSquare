import { HttpStatus, Injectable } from '@nestjs/common';
import { ApiException } from '../../common/errors/api-exception';
import { PrismaService } from '../../prisma/prisma.service';
import { lockUser } from '../shared/locks';

export interface ReviewView {
  id: string;
  rating: number;
  comment: string | null;
  reviewer: { id: string; fullName: string };
  createdAt: Date;
  updatedAt: Date;
}

const round2 = (n: number | null): number =>
  n === null ? 0 : Math.round(n * 100) / 100;

@Injectable()
export class ReviewsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * One review per (buyer, drawing), editable. Only people who own the drawing (PAID purchase or free claim) and are
   * not its author may review. The review write and both aggregates (drawing, architect) commit together, serialised
   * per architect by a row lock so concurrent reviews can never leave a stale average.
   */
  async upsert(
    reviewer: { id: string; fullName: string },
    drawingId: string,
    rating: number,
    comment: string | null | undefined,
  ): Promise<ReviewView> {
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
    const forbidden = new ApiException(
      HttpStatus.FORBIDDEN,
      'FORBIDDEN',
      'Only buyers of this drawing can review it',
    );
    if (drawing.architectId === reviewer.id) throw forbidden;

    const [purchase, free] = await Promise.all([
      this.prisma.purchase.findFirst({
        where: { buyerId: reviewer.id, drawingId, status: 'PAID' },
        select: { id: true },
      }),
      this.prisma.freeDownload.findUnique({
        where: { userId_drawingId: { userId: reviewer.id, drawingId } },
        select: { userId: true },
      }),
    ]);
    if (!purchase && !free) throw forbidden;

    const text = comment?.trim() ? comment.trim() : null;
    return this.prisma.$transaction(async (tx) => {
      await lockUser(tx, drawing.architectId);
      const review = await tx.review.upsert({
        where: { buyerId_drawingId: { buyerId: reviewer.id, drawingId } },
        create: { buyerId: reviewer.id, drawingId, rating, comment: text },
        update: { rating, comment: text },
      });

      const perDrawing = await tx.review.aggregate({
        where: { drawingId },
        _avg: { rating: true },
        _count: { _all: true },
      });
      await tx.drawing.update({
        where: { id: drawingId },
        data: {
          avgRating: round2(perDrawing._avg.rating),
          ratingCount: perDrawing._count._all,
        },
      });

      const perArchitect = await tx.review.aggregate({
        where: { drawing: { architectId: drawing.architectId } },
        _avg: { rating: true },
        _count: { _all: true },
      });
      await tx.user.update({
        where: { id: drawing.architectId },
        data: {
          architectRating: round2(perArchitect._avg.rating),
          architectRatingCount: perArchitect._count._all,
        },
      });

      return {
        id: review.id,
        rating: review.rating,
        comment: review.comment,
        reviewer: { id: reviewer.id, fullName: reviewer.fullName },
        createdAt: review.createdAt,
        updatedAt: review.updatedAt,
      };
    });
  }
}
