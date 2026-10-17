import { HttpStatus, Injectable } from '@nestjs/common';
import { DrawingStatus, Prisma } from '@prisma/client';
import { ApiException } from '../common/errors/api-exception';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { CreateDrawingDto, PlotUnit } from './dto/create-drawing.dto';
import { UpdateDrawingDto } from './dto/update-drawing.dto';
import { DrawingWithRelations, toOwnerDrawingDetail } from './drawing.mapper';

const M_TO_FT = 3.28084;
/** After publication only these fields may change. */
const LOCKED_FIELDS_AFTER_PUBLISH = [
  'categoryId',
  'city',
  'plotLength',
  'plotBreadth',
  'unit',
  'floors',
  'facing',
  'bedrooms',
  'tags',
  'isFree',
] as const;

export const DRAWING_INCLUDE = {
  category: true,
  architect: true,
  sheets: true,
} satisfies Prisma.DrawingInclude;

export function toFeet(value: number, unit: PlotUnit): number {
  return Math.round((unit === 'm' ? value * M_TO_FT : value) * 100) / 100;
}

function validation(message: string): ApiException {
  return new ApiException(HttpStatus.BAD_REQUEST, 'VALIDATION_ERROR', message);
}

@Injectable()
export class DrawingsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}

  private readonly previewUrl = (key: string | null | undefined) =>
    this.storage.previewUrl(key);

  /** Loads a drawing the caller owns. Missing/removed → 404, someone else's → 403. */
  async loadOwned(
    drawingId: string,
    userId: string,
  ): Promise<DrawingWithRelations> {
    const drawing = await this.prisma.drawing.findUnique({
      where: { id: drawingId },
      include: DRAWING_INCLUDE,
    });
    if (!drawing || drawing.status === DrawingStatus.REMOVED) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Drawing not found',
      );
    }
    if (drawing.architectId !== userId) {
      throw new ApiException(
        HttpStatus.FORBIDDEN,
        'FORBIDDEN',
        'You do not own this drawing',
      );
    }
    return drawing;
  }

  private async assertCategoryActive(categoryId: string): Promise<void> {
    const category = await this.prisma.category.findUnique({
      where: { id: categoryId },
    });
    if (!category?.isActive) throw validation('categoryId: unknown category');
  }

  async create(userId: string, dto: CreateDrawingDto) {
    await this.assertCategoryActive(dto.categoryId);
    const pricePaise = dto.isFree ? 0 : dto.pricePaise;
    if (pricePaise === undefined) {
      throw validation('pricePaise: required unless isFree is true');
    }
    const created = await this.prisma.drawing.create({
      data: {
        architectId: userId,
        title: dto.title.trim(),
        description: dto.description.trim(),
        categoryId: dto.categoryId,
        city: dto.city.trim(),
        plotLengthFt: toFeet(dto.plotLength, dto.unit),
        plotBreadthFt: toFeet(dto.plotBreadth, dto.unit),
        floors: dto.floors,
        facing: dto.facing,
        bedrooms: dto.bedrooms,
        tags: this.cleanTags(dto.tags),
        pricePaise,
      },
      include: DRAWING_INCLUDE,
    });
    return toOwnerDrawingDetail(created, this.previewUrl);
  }

  async update(userId: string, drawingId: string, dto: UpdateDrawingDto) {
    const drawing = await this.loadOwned(drawingId, userId);
    if (drawing.status === DrawingStatus.PROCESSING) {
      throw new ApiException(
        HttpStatus.CONFLICT,
        'CONFLICT',
        'Drawing is being processed; try again shortly',
      );
    }
    const editable =
      drawing.status === DrawingStatus.DRAFT ||
      drawing.status === DrawingStatus.FAILED;
    if (!editable) {
      const locked = LOCKED_FIELDS_AFTER_PUBLISH.filter(
        (f) => dto[f] !== undefined,
      );
      if (locked.length > 0) {
        throw validation(
          `${locked[0]}: cannot be changed after publishing (only title, description and pricePaise)`,
        );
      }
    }
    if (
      dto.unit !== undefined &&
      dto.plotLength === undefined &&
      dto.plotBreadth === undefined
    ) {
      throw validation('unit: only valid together with plotLength/plotBreadth');
    }
    if (dto.categoryId) await this.assertCategoryActive(dto.categoryId);

    const unit = dto.unit ?? 'ft';
    const data: Prisma.DrawingUncheckedUpdateInput = {
      title: dto.title?.trim(),
      description: dto.description?.trim(),
      categoryId: dto.categoryId,
      city: dto.city?.trim(),
      plotLengthFt:
        dto.plotLength === undefined ? undefined : toFeet(dto.plotLength, unit),
      plotBreadthFt:
        dto.plotBreadth === undefined
          ? undefined
          : toFeet(dto.plotBreadth, unit),
      floors: dto.floors,
      facing: dto.facing,
      bedrooms: dto.bedrooms,
      tags: dto.tags === undefined ? undefined : this.cleanTags(dto.tags),
      pricePaise: dto.isFree ? 0 : dto.pricePaise,
    };

    const updated = await this.prisma.drawing.update({
      where: { id: drawingId },
      data,
      include: DRAWING_INCLUDE,
    });
    return toOwnerDrawingDetail(updated, this.previewUrl);
  }

  /** Soft delete; idempotent. Past buyers keep access because purchases are untouched. */
  async remove(userId: string, drawingId: string): Promise<void> {
    const drawing = await this.prisma.drawing.findUnique({
      where: { id: drawingId },
      select: { architectId: true, status: true },
    });
    if (!drawing) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Drawing not found',
      );
    }
    if (drawing.architectId !== userId) {
      throw new ApiException(
        HttpStatus.FORBIDDEN,
        'FORBIDDEN',
        'You do not own this drawing',
      );
    }
    if (drawing.status === DrawingStatus.REMOVED) return;
    await this.prisma.drawing.update({
      where: { id: drawingId },
      data: { status: DrawingStatus.REMOVED },
    });
  }

  private cleanTags(tags: string[] | undefined): string[] {
    const cleaned = (tags ?? [])
      .map((t) => t.trim().toLowerCase())
      .filter(Boolean);
    return [...new Set(cleaned)];
  }
}
