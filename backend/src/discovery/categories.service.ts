import { HttpStatus, Injectable } from '@nestjs/common';
import { Prisma, RequestStatus } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { ApiException } from '../common/errors/api-exception';
import { Page, decodeCursor, toPage } from '../common/pagination';
import { PrismaService } from '../prisma/prisma.service';
import type { CategoryRequestsQueryDto } from './dto/category.dto';

export interface CategoryView {
  id: string;
  name: string;
  slug: string;
}

export interface CategoryRequestView {
  id: string;
  requestedName: string;
  status: RequestStatus;
}

export interface AdminCategoryRequestView extends CategoryRequestView {
  user: { id: string; fullName: string };
  createdAt: Date;
}

export const slugify = (name: string): string =>
  name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '') || 'category';

@Injectable()
export class CategoriesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  list(): Promise<CategoryView[]> {
    return this.prisma.category.findMany({
      where: { isActive: true },
      orderBy: [{ name: 'asc' }, { id: 'asc' }],
      select: { id: true, name: true, slug: true },
    });
  }

  /** Idempotent per (user, name): repeating a still-pending request returns the existing one. */
  async request(userId: string, name: string): Promise<CategoryRequestView> {
    const existing = await this.prisma.category.findFirst({
      where: { name: { equals: name, mode: 'insensitive' } },
      select: { isActive: true },
    });
    if (existing?.isActive) {
      throw new ApiException(
        HttpStatus.CONFLICT,
        'CONFLICT',
        'This category already exists',
      );
    }
    const pending = await this.prisma.categoryRequest.findFirst({
      where: {
        userId,
        status: 'PENDING',
        requestedName: { equals: name, mode: 'insensitive' },
      },
      select: { id: true, requestedName: true, status: true },
    });
    if (pending) return pending;
    return this.prisma.categoryRequest.create({
      data: { userId, requestedName: name },
      select: { id: true, requestedName: true, status: true },
    });
  }

  async listRequests(
    query: CategoryRequestsQueryDto,
  ): Promise<Page<AdminCategoryRequestView>> {
    const cursor = decodeCursor<{ t: string; id: string }>(query.cursor);
    const after =
      cursor && !Number.isNaN(Date.parse(cursor.t)) && cursor.id
        ? new Date(cursor.t)
        : null;
    if (cursor && !after) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Invalid cursor',
      );
    }
    const where: Prisma.CategoryRequestWhereInput = {
      status: query.status ?? 'PENDING',
      ...(after && cursor
        ? {
            OR: [
              { createdAt: { gt: after } },
              { createdAt: after, id: { gt: cursor.id } },
            ],
          }
        : {}),
    };
    const rows = await this.prisma.categoryRequest.findMany({
      where,
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
      take: query.limit + 1,
      select: {
        id: true,
        requestedName: true,
        status: true,
        createdAt: true,
        user: { select: { id: true, fullName: true } },
      },
    });
    return toPage(rows, query.limit, (r) => ({
      t: r.createdAt.toISOString(),
      id: r.id,
    }));
  }

  /** Approving creates (or re-activates) the Category; the PENDING→APPROVED claim makes it race-safe. */
  async approve(
    adminId: string,
    id: string,
  ): Promise<{ ok: true; category: CategoryView }> {
    return this.prisma.$transaction(async (tx) => {
      const claimed = await tx.categoryRequest.updateMany({
        where: { id, status: 'PENDING' },
        data: { status: 'APPROVED', reviewedAt: new Date() },
      });
      if (claimed.count === 0) await this.failUnclaimed(tx, id);
      const req = await tx.categoryRequest.findUniqueOrThrow({
        where: { id },
        select: { requestedName: true },
      });
      const select = { id: true, name: true, slug: true } as const;
      const approved = (categoryId: string) =>
        this.audit.record(
          {
            actorId: adminId,
            action: 'category-request.approve',
            entityType: 'CategoryRequest',
            entityId: id,
            metadata: { categoryId, name: req.requestedName },
          },
          tx,
        );
      const existing = await tx.category.findFirst({
        where: { name: { equals: req.requestedName, mode: 'insensitive' } },
        select: { ...select, isActive: true },
      });
      if (existing) {
        if (!existing.isActive) {
          await tx.category.update({
            where: { id: existing.id },
            data: { isActive: true },
          });
        }
        await approved(existing.id);
        return {
          ok: true as const,
          category: {
            id: existing.id,
            name: existing.name,
            slug: existing.slug,
          },
        };
      }
      const base = slugify(req.requestedName);
      let slug = base;
      for (let n = 2; await tx.category.findUnique({ where: { slug } }); n++) {
        slug = `${base}-${n}`;
      }
      const category = await tx.category.create({
        data: { name: req.requestedName, slug },
        select,
      });
      await approved(category.id);
      return { ok: true as const, category };
    });
  }

  async reject(adminId: string, id: string): Promise<{ ok: true }> {
    await this.prisma.$transaction(async (tx) => {
      const claimed = await tx.categoryRequest.updateMany({
        where: { id, status: 'PENDING' },
        data: { status: 'REJECTED', reviewedAt: new Date() },
      });
      if (claimed.count === 0) await this.failUnclaimed(tx, id);
      await this.audit.record(
        {
          actorId: adminId,
          action: 'category-request.reject',
          entityType: 'CategoryRequest',
          entityId: id,
        },
        tx,
      );
    });
    return { ok: true };
  }

  private async failUnclaimed(
    db: Pick<PrismaService, 'categoryRequest'>,
    id: string,
  ): Promise<never> {
    const found = await db.categoryRequest.findUnique({
      where: { id },
      select: { status: true },
    });
    if (!found) {
      throw new ApiException(
        HttpStatus.NOT_FOUND,
        'NOT_FOUND',
        'Category request not found',
      );
    }
    throw new ApiException(
      HttpStatus.CONFLICT,
      'CONFLICT',
      `Request is already ${found.status}`,
    );
  }
}
