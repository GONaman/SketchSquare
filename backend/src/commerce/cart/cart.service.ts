import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiException } from '../../common/errors/api-exception';
import { Env } from '../../config/env.schema';
import { PrismaService } from '../../prisma/prisma.service';
import {
  DrawingSummaryView,
  drawingSummaryInclude,
  toDrawingSummary,
} from '../shared/drawing.mapper';

export interface CartView {
  items: DrawingSummaryView[];
  totalPaise: number;
}

@Injectable()
export class CartService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  async getCart(userId: string): Promise<CartView> {
    const rows = await this.prisma.cartItem.findMany({
      where: { userId, drawing: { status: 'PUBLISHED' } },
      orderBy: [{ createdAt: 'desc' }, { drawingId: 'asc' }],
      include: { drawing: { include: drawingSummaryInclude } },
    });
    const base = this.config.get('S3_PREVIEWS_PUBLIC_URL', { infer: true });
    const items = rows.map((r) => toDrawingSummary(r.drawing, base));
    return {
      items,
      totalPaise: items.reduce((sum, d) => sum + d.pricePaise, 0),
    };
  }

  async add(userId: string, drawingId: string): Promise<CartView> {
    const drawing = await this.prisma.drawing.findUnique({
      where: { id: drawingId },
      select: { id: true, status: true, architectId: true, pricePaise: true },
    });
    if (!drawing || drawing.status !== 'PUBLISHED') {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Drawing not found',
      );
    }
    if (drawing.architectId === userId) {
      throw this.rejected('You cannot add your own drawing to the basket');
    }
    if (drawing.pricePaise === 0) {
      throw this.rejected(
        'Free drawings are downloaded directly, not added to the basket',
      );
    }
    const owned = await this.prisma.purchase.findFirst({
      where: { buyerId: userId, drawingId, status: 'PAID' },
      select: { id: true },
    });
    if (owned) throw this.rejected('You already own this drawing');

    await this.prisma.cartItem.createMany({
      data: [{ userId, drawingId }],
      skipDuplicates: true,
    });
    return this.getCart(userId);
  }

  async remove(userId: string, drawingId: string): Promise<CartView> {
    await this.prisma.cartItem.deleteMany({ where: { userId, drawingId } });
    return this.getCart(userId);
  }

  private rejected(message: string): ApiException {
    return new ApiException(
      HttpStatus.BAD_REQUEST,
      'VALIDATION_ERROR',
      message,
    );
  }
}
