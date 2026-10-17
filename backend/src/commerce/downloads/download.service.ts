import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash } from 'node:crypto';
import { ApiException } from '../../common/errors/api-exception';
import { Env } from '../../config/env.schema';
import { PrismaService } from '../../prisma/prisma.service';
import {
  DOWNLOAD_URL_TTL_SECONDS,
  StorageService,
} from '../../storage/storage.service';
import { WatermarkService } from '../../watermark/watermark.service';

export interface DownloadLink {
  url: string;
  expiresInSeconds: number;
  fileName: string;
}

/** Entitled users get a 5-minute presigned link to their buyer-specific copy; the original key never leaves the server. */
@Injectable()
export class DownloadService {
  private readonly logger = new Logger(DownloadService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly watermark: WatermarkService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  async createLink(
    user: { id: string; fullName: string },
    drawingId: string,
    sheetId: string | undefined,
  ): Promise<DownloadLink> {
    const drawing = await this.prisma.drawing.findUnique({
      where: { id: drawingId },
      select: {
        id: true,
        architectId: true,
        pricePaise: true,
        status: true,
        sheets: { orderBy: [{ createdAt: 'asc' }, { id: 'asc' }] },
      },
    });
    if (!drawing) throw this.notFound();

    let sheet = drawing.sheets.find((s) => s.id === sheetId);
    if (!sheetId && drawing.sheets.length === 1) sheet = drawing.sheets[0];
    if (!sheet) {
      if (!sheetId && drawing.sheets.length > 1) {
        throw new ApiException(
          HttpStatus.BAD_REQUEST,
          'VALIDATION_ERROR',
          'sheetId is required',
        );
      }
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Sheet not found',
      );
    }

    if (drawing.architectId === user.id) {
      return this.link(sheet.originalKey, sheet.fileName);
    }

    const purchase = await this.prisma.purchase.findFirst({
      where: { buyerId: user.id, drawingId, status: 'PAID' },
      select: { id: true },
    });
    let licenseRef: string;
    if (purchase) {
      licenseRef = purchase.id;
    } else if (drawing.pricePaise === 0) {
      await this.claimFreeDownload(user.id, drawing.id, drawing.status);
      licenseRef =
        'free-' +
        createHash('sha256')
          .update(`${user.id}:${drawing.id}`)
          .digest('hex')
          .slice(0, 24);
    } else {
      throw new ApiException(
        HttpStatus.FORBIDDEN,
        'FORBIDDEN',
        'Purchase this drawing to download it',
      );
    }

    try {
      const copy = await this.watermark.ensureBuyerCopy({
        licenseRef,
        buyerName: user.fullName,
        sheetId: sheet.id,
        originalKey: sheet.originalKey,
        originalMime: sheet.originalMime,
        fileName: sheet.fileName,
      });
      return this.link(copy.key, copy.fileName);
    } catch (err) {
      // The buyer is entitled; a failed licence stamp must not lock them out of what they own.
      this.logger.error(
        `Licence watermark failed for sheet ${sheet.id} (${licenseRef}); serving the original`,
        err instanceof Error ? err.stack : String(err),
      );
      return this.link(sheet.originalKey, sheet.fileName);
    }
  }

  /**
   * Records a free claim and counts it against the quota in one transaction. Re-downloading a drawing already
   * claimed is free; only a first claim of a PUBLISHED drawing consumes quota. The conditional UPDATE re-checks the
   * limit under the user's row lock, so parallel claims can never exceed it.
   */
  private async claimFreeDownload(
    userId: string,
    drawingId: string,
    status: string,
  ): Promise<void> {
    const existing = await this.prisma.freeDownload.findUnique({
      where: { userId_drawingId: { userId, drawingId } },
      select: { userId: true },
    });
    if (existing) return;
    if (status !== 'PUBLISHED') throw this.notFound();

    const limit = this.config.get('FREE_DOWNLOAD_LIMIT', { infer: true });
    await this.prisma.$transaction(async (tx) => {
      const created = await tx.freeDownload.createMany({
        data: [{ userId, drawingId }],
        skipDuplicates: true,
      });
      if (created.count === 0) return;
      const updated = await tx.$executeRaw`
        UPDATE "User" SET "freeDownloadsUsed" = "freeDownloadsUsed" + 1
        WHERE "id" = ${userId}::uuid AND "freeDownloadsUsed" < ${limit}`;
      if (updated === 0) {
        throw new ApiException(
          HttpStatus.FORBIDDEN,
          'FREE_LIMIT_REACHED',
          `You have used all ${limit} free downloads`,
          { freeDownloadLimit: limit },
        );
      }
    });
  }

  private async link(key: string, fileName: string): Promise<DownloadLink> {
    return {
      url: await this.storage.presignOriginalDownload(key, fileName),
      expiresInSeconds: DOWNLOAD_URL_TTL_SECONDS,
      fileName,
    };
  }

  private notFound(): ApiException {
    return new ApiException(
      HttpStatus.NOT_FOUND,
      'NOT_FOUND',
      'Drawing not found',
    );
  }
}
