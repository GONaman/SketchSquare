import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { DrawingSheet, DrawingStatus, Prisma } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { ApiException } from '../common/errors/api-exception';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import {
  RegisterSheetDto,
  UpdateSheetDto,
  UploadUrlDto,
} from './dto/sheet.dto';
import { toSheetResponse } from './drawing.mapper';
import { DrawingsService } from './drawings.service';
import {
  declaredTypeMatches,
  detectKind,
  kindFromFileName,
  MAX_SHEET_BYTES,
  MAX_SHEETS_PER_DRAWING,
  sanitizeFileName,
  SHEET_KINDS,
  SNIFF_BYTES,
} from './sheet-files';

const upload = (message: string) =>
  new ApiException(HttpStatus.BAD_REQUEST, 'UPLOAD_INVALID', message);
const validation = (message: string) =>
  new ApiException(HttpStatus.BAD_REQUEST, 'VALIDATION_ERROR', message);

@Injectable()
export class SheetsService {
  private readonly logger = new Logger(SheetsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly drawings: DrawingsService,
  ) {}

  private readonly previewUrl = (key: string | null | undefined) =>
    this.storage.previewUrl(key);

  /** Sheets may only change while the drawing is a draft (or after a failed publish). */
  private async loadEditable(drawingId: string, userId: string) {
    const drawing = await this.drawings.loadOwned(drawingId, userId);
    if (
      drawing.status !== DrawingStatus.DRAFT &&
      drawing.status !== DrawingStatus.FAILED
    ) {
      throw new ApiException(
        HttpStatus.CONFLICT,
        'CONFLICT',
        'Sheets can only be changed while the drawing is a draft',
      );
    }
    return drawing;
  }

  async createUploadUrl(userId: string, drawingId: string, dto: UploadUrlDto) {
    const drawing = await this.loadEditable(drawingId, userId);
    if (drawing.sheets.length >= MAX_SHEETS_PER_DRAWING) {
      throw upload(
        `A drawing can have at most ${MAX_SHEETS_PER_DRAWING} sheets`,
      );
    }
    const kind = kindFromFileName(dto.fileName);
    if (!kind) throw upload('Unsupported file type (PDF, PNG, JPG, DWG, DXF)');
    if (!declaredTypeMatches(kind, dto.contentType)) {
      throw upload(`contentType does not match a .${kind} file`);
    }
    if (dto.sizeBytes > MAX_SHEET_BYTES) {
      throw upload('File exceeds the 50 MB limit');
    }
    const objectKey = `drawings/${drawingId}/${randomUUID()}/${sanitizeFileName(dto.fileName)}`;
    const { uploadUrl, headers } = await this.storage.presignOriginalUpload({
      key: objectKey,
      contentType: dto.contentType,
      sizeBytes: dto.sizeBytes,
    });
    return { uploadUrl, objectKey, headers };
  }

  async register(userId: string, drawingId: string, dto: RegisterSheetDto) {
    const drawing = await this.loadEditable(drawingId, userId);
    const prefix = `drawings/${drawingId}/`;
    if (
      !dto.objectKey.startsWith(prefix) ||
      dto.objectKey.includes('..') ||
      dto.objectKey.includes('//')
    ) {
      throw upload('objectKey was not issued for this drawing');
    }

    const existing = drawing.sheets.find(
      (s) => s.originalKey === dto.objectKey,
    );
    if (existing) return toSheetResponse(existing, this.previewUrl);

    if (drawing.sheets.length >= MAX_SHEETS_PER_DRAWING) {
      throw upload(
        `A drawing can have at most ${MAX_SHEETS_PER_DRAWING} sheets`,
      );
    }

    const declaredKind = kindFromFileName(dto.fileName);
    const keyKind = kindFromFileName(dto.objectKey);
    if (!declaredKind || declaredKind !== keyKind) {
      throw upload('fileName does not match the uploaded file type');
    }
    if (dto.isPreview && !SHEET_KINDS[declaredKind].previewable) {
      throw validation(
        'isPreview: only PDF, PNG and JPG sheets can be previews',
      );
    }

    const head = await this.storage.headOriginal(dto.objectKey);
    if (!head) throw upload('No uploaded file found for objectKey');
    if (head.sizeBytes > MAX_SHEET_BYTES || head.sizeBytes === 0) {
      await this.discard(dto.objectKey);
      throw upload('File is empty or exceeds the 50 MB limit');
    }

    const detected = detectKind(
      await this.storage.readOriginalHead(dto.objectKey, SNIFF_BYTES),
    );
    if (detected !== declaredKind) {
      await this.discard(dto.objectKey);
      throw upload('File content does not match its declared type');
    }

    const sha256 = await this.storage.sha256Original(dto.objectKey);
    try {
      const sheet = await this.prisma.drawingSheet.create({
        data: {
          drawingId,
          type: dto.type,
          originalKey: dto.objectKey,
          originalMime: SHEET_KINDS[detected].mime,
          fileName: sanitizeFileName(dto.fileName),
          sizeBytes: head.sizeBytes,
          isPreview: dto.isPreview,
          sha256,
        },
      });
      return toSheetResponse(sheet, this.previewUrl);
    } catch (err) {
      // Concurrent duplicate registration: the unique (drawingId, originalKey) makes it idempotent.
      if (
        err instanceof Prisma.PrismaClientKnownRequestError &&
        err.code === 'P2002'
      ) {
        const sheet = await this.prisma.drawingSheet.findFirstOrThrow({
          where: { drawingId, originalKey: dto.objectKey },
        });
        return toSheetResponse(sheet, this.previewUrl);
      }
      throw err;
    }
  }

  async update(
    userId: string,
    drawingId: string,
    sheetId: string,
    dto: UpdateSheetDto,
  ) {
    const drawing = await this.loadEditable(drawingId, userId);
    const sheet = this.find(drawing.sheets, sheetId);
    if (dto.isPreview === true && !this.isPreviewable(sheet)) {
      throw validation(
        'isPreview: only PDF, PNG and JPG sheets can be previews',
      );
    }
    const updated = await this.prisma.drawingSheet.update({
      where: { id: sheetId },
      data: {
        type: dto.type,
        isPreview: dto.isPreview,
        ...(dto.isPreview === false && { previewKey: null, pHash: null }),
      },
    });
    return toSheetResponse(updated, this.previewUrl);
  }

  async remove(userId: string, drawingId: string, sheetId: string) {
    const drawing = await this.loadEditable(drawingId, userId);
    const sheet = drawing.sheets.find((s) => s.id === sheetId);
    if (!sheet) return; // already gone: DELETE is idempotent
    await this.prisma.drawingSheet.delete({ where: { id: sheetId } });
    await this.discard(sheet.originalKey);
  }

  private find(sheets: DrawingSheet[], sheetId: string): DrawingSheet {
    const sheet = sheets.find((s) => s.id === sheetId);
    if (!sheet) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Sheet not found',
      );
    }
    return sheet;
  }

  private isPreviewable(sheet: DrawingSheet): boolean {
    return (
      Object.values(SHEET_KINDS) as { mime: string; previewable: boolean }[]
    ).some((k) => k.mime === sheet.originalMime && k.previewable);
  }

  private async discard(key: string): Promise<void> {
    try {
      await this.storage.deleteOriginal(key);
    } catch (err) {
      this.logger.warn(`Failed to delete ${key}: ${String(err)}`);
    }
  }
}
