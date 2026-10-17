import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface AuditEntry {
  actorId: string;
  /** `<domain>.<verb>`, e.g. `verification.approve`, `category-request.reject`. */
  action: string;
  entityType: string;
  entityId?: string;
  metadata?: Prisma.InputJsonValue;
}

/**
 * Append-only record of privileged (ADMIN) actions. Pass the transaction client so the audit row commits or
 * rolls back together with the action it describes. Every admin mutation must call this (docs/CONVENTIONS.md).
 */
@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  async record(
    entry: AuditEntry,
    db: Pick<Prisma.TransactionClient, 'auditLog'> = this.prisma,
  ): Promise<void> {
    await db.auditLog.create({
      data: {
        actorId: entry.actorId,
        action: entry.action,
        entityType: entry.entityType,
        entityId: entry.entityId,
        metadata: entry.metadata,
      },
    });
  }
}
