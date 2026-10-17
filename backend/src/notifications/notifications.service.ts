import { InjectQueue } from '@nestjs/bullmq';
import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Queue } from 'bullmq';
import { ApiException } from '../common/errors/api-exception';
import { decodeCursor, Page, PageQueryDto, toPage } from '../common/pagination';
import { PrismaService } from '../prisma/prisma.service';
import { renderNotification } from './notification.templates';
import {
  NotificationPayloads,
  NotificationType,
  PUSH_QUEUE,
  PushJob,
} from './notification.types';

export interface NotificationView {
  id: string;
  type: string;
  title: string;
  body: string;
  data: Record<string, string>;
  readAt: Date | null;
  createdAt: Date;
}

export interface NotificationPage extends Page<NotificationView> {
  unreadCount: number;
}

interface NotificationCursor extends Record<string, unknown> {
  at: string;
  id: string;
}

// A notification written inside a still-open transaction is not visible to the worker yet; delay and let retries cover the rest.
const TX_PUSH_DELAY_MS = 1_000;

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    @InjectQueue(PUSH_QUEUE) private readonly queue: Queue<PushJob>,
  ) {}

  /**
   * Records an in-app notification for `userId` and queues the push. Safe to call from any flow:
   * it never throws, and the same event notifies a user at most once (idempotent per event key).
   * Pass the caller's transaction client to make the notification commit/roll back with the state change.
   */
  async notify<T extends NotificationType>(
    userId: string,
    type: T,
    payload: NotificationPayloads[T],
    tx?: Prisma.TransactionClient,
  ): Promise<void> {
    try {
      const { title, body, data, dedupeKey } = renderNotification(
        type,
        payload,
      );
      const db = tx ?? this.prisma;
      const rows = await db.$queryRaw<{ id: string }[]>`
        INSERT INTO "Notification" ("userId", "type", "title", "body", "data", "dedupeKey")
        VALUES (${userId}::uuid, ${type}, ${title}, ${body}, ${JSON.stringify(data)}::jsonb, ${dedupeKey})
        ON CONFLICT ("userId", "dedupeKey") DO NOTHING
        RETURNING "id"::text AS "id"`;
      if (rows.length === 0) return;
      await this.queue.add(
        'push',
        { notificationId: rows[0].id },
        {
          attempts: 5,
          backoff: { type: 'exponential', delay: 2_000 },
          delay: tx ? TX_PUSH_DELAY_MS : 0,
        },
      );
    } catch (err) {
      this.logger.warn(
        `Could not notify ${userId} of ${type}: ${err instanceof Error ? err.message : String(err)}`,
      );
    }
  }

  async list(userId: string, query: PageQueryDto): Promise<NotificationPage> {
    const c = decodeCursor<NotificationCursor>(query.cursor);
    const at = c ? new Date(c.at) : null;
    if (c && (typeof c.id !== 'string' || !at || Number.isNaN(at.getTime()))) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Invalid cursor',
      );
    }
    const [rows, unreadCount] = await Promise.all([
      this.prisma.notification.findMany({
        where: {
          userId,
          ...(c && at
            ? {
                OR: [
                  { createdAt: { lt: at } },
                  { createdAt: at, id: { lt: c.id } },
                ],
              }
            : {}),
        },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: query.limit + 1,
      }),
      this.prisma.notification.count({ where: { userId, readAt: null } }),
    ]);
    const page = toPage(rows, query.limit, (r) => ({
      at: r.createdAt.toISOString(),
      id: r.id,
    }));
    return {
      items: page.items.map((r) => ({
        id: r.id,
        type: r.type,
        title: r.title,
        body: r.body,
        data: r.data as Record<string, string>,
        readAt: r.readAt,
        createdAt: r.createdAt,
      })),
      nextCursor: page.nextCursor,
      unreadCount,
    };
  }

  /** Marks the given notifications (or all) of this user as read; other users' ids are ignored. */
  async markRead(userId: string, ids?: string[]): Promise<void> {
    await this.prisma.notification.updateMany({
      where: { userId, readAt: null, ...(ids ? { id: { in: ids } } : {}) },
      data: { readAt: new Date() },
    });
  }
}
