import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { Prisma, RequestStatus, VerificationRequest } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { ApiException } from '../common/errors/api-exception';
import { Page, decodeCursor, toPage } from '../common/pagination';
import { MailService } from '../mail/mail.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { detectDocument, MAX_DOCUMENT_BYTES } from './document-type';
import { KycStorageService } from './kyc-storage.service';

export const toVerificationResponse = (v: VerificationRequest) => ({
  id: v.id,
  coaRegistrationNumber: v.coaRegistrationNumber,
  status: v.status,
  reviewNote: v.reviewNote,
  submittedAt: v.submittedAt,
  reviewedAt: v.reviewedAt,
});

const userSelect = {
  id: true,
  fullName: true,
  email: true,
  phone: true,
  city: true,
  address: true,
} satisfies Prisma.UserSelect;

type VerificationWithUser = Prisma.VerificationRequestGetPayload<{
  include: { user: { select: typeof userSelect } };
}>;

const toAdminItem = (v: VerificationWithUser) => ({
  id: v.id,
  status: v.status,
  coaRegistrationNumber: v.coaRegistrationNumber,
  submittedAt: v.submittedAt,
  user: v.user,
});

@Injectable()
export class VerificationService {
  private readonly logger = new Logger(VerificationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly kyc: KycStorageService,
    private readonly mail: MailService,
    private readonly notifications: NotificationsService,
  ) {}

  async submit(
    userId: string,
    coaRegistrationNumber: string,
    file: Express.Multer.File | undefined,
  ) {
    if (!file || file.size === 0) {
      throw this.uploadInvalid('A "document" file is required');
    }
    if (file.size > MAX_DOCUMENT_BYTES) {
      throw this.uploadInvalid('Document must be at most 10MB');
    }
    const doc = detectDocument(file.buffer);
    if (!doc) throw this.uploadInvalid('Document must be a PDF, JPG or PNG');

    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: { role: true, verificationStatus: true },
    });
    if (user.role !== 'ARCHITECT') {
      throw new ApiException(
        HttpStatus.FORBIDDEN,
        'FORBIDDEN',
        'Only architects submit verification',
      );
    }
    if (user.verificationStatus === 'APPROVED') {
      throw new ApiException(
        HttpStatus.CONFLICT,
        'CONFLICT',
        'Your account is already verified',
      );
    }

    const documentKey = `verification/${userId}/${randomUUID()}.${doc.ext}`;
    await this.kyc.put(documentKey, file.buffer, doc.mime);

    let replacedKey: string | undefined;
    try {
      const saved = await this.prisma.$transaction(async (tx) => {
        const latest = await tx.verificationRequest.findFirst({
          where: { userId },
          orderBy: { submittedAt: 'desc' },
        });
        let row: VerificationRequest;
        if (latest?.status === 'PENDING') {
          // Resubmitting while pending replaces the previous submission.
          replacedKey = latest.documentKey;
          row = await tx.verificationRequest.update({
            where: { id: latest.id },
            data: {
              coaRegistrationNumber,
              documentKey,
              submittedAt: new Date(),
            },
          });
        } else {
          row = await tx.verificationRequest.create({
            data: { userId, coaRegistrationNumber, documentKey },
          });
        }
        await tx.user.update({
          where: { id: userId },
          data: { verificationStatus: 'PENDING' },
        });
        return row;
      });
      if (replacedKey) this.deleteQuietly(replacedKey);
      return toVerificationResponse(saved);
    } catch (err) {
      this.deleteQuietly(documentKey);
      throw err;
    }
  }

  async mine(userId: string) {
    const latest = await this.prisma.verificationRequest.findFirst({
      where: { userId },
      orderBy: { submittedAt: 'desc' },
    });
    return { verification: latest ? toVerificationResponse(latest) : null };
  }

  async list(
    status: RequestStatus,
    cursor: string | undefined,
    limit: number,
  ): Promise<Page<ReturnType<typeof toAdminItem>>> {
    const after = decodeCursor<{ at: string; id: string }>(cursor);
    const rows = await this.prisma.verificationRequest.findMany({
      where: {
        status,
        ...(after && {
          OR: [
            { submittedAt: { gt: new Date(after.at) } },
            { submittedAt: new Date(after.at), id: { gt: after.id } },
          ],
        }),
      },
      include: { user: { select: userSelect } },
      orderBy: [{ submittedAt: 'asc' }, { id: 'asc' }],
      take: limit + 1,
    });
    const page = toPage(rows, limit, (last) => ({
      at: last.submittedAt.toISOString(),
      id: last.id,
    }));
    return { ...page, items: page.items.map(toAdminItem) };
  }

  async detail(id: string) {
    const v = await this.prisma.verificationRequest.findUnique({
      where: { id },
      include: { user: { select: userSelect } },
    });
    if (!v) throw this.notFound();
    return {
      ...toAdminItem(v),
      reviewNote: v.reviewNote,
      reviewedAt: v.reviewedAt,
      documentUrl: await this.kyc.presignGet(v.documentKey),
    };
  }

  async approve(id: string, adminId: string) {
    const v = await this.review(id, adminId, 'APPROVED', null);
    await this.mail.sendWelcome(v.user.email, v.user.fullName);
    await this.notifications.notify(v.user.id, 'VERIFICATION_RESULT', {
      requestId: v.id,
      status: 'APPROVED',
    });
    return { ok: true };
  }

  async reject(id: string, adminId: string, note: string) {
    const v = await this.review(id, adminId, 'REJECTED', note);
    await this.mail.sendVerificationRejected(
      v.user.email,
      v.user.fullName,
      note,
    );
    await this.notifications.notify(v.user.id, 'VERIFICATION_RESULT', {
      requestId: v.id,
      status: 'REJECTED',
      note,
    });
    return { ok: true };
  }

  private async review(
    id: string,
    adminId: string,
    status: 'APPROVED' | 'REJECTED',
    note: string | null,
  ) {
    const existing = await this.prisma.verificationRequest.findUnique({
      where: { id },
      include: { user: { select: { id: true, email: true, fullName: true } } },
    });
    if (!existing) throw this.notFound();

    await this.prisma.$transaction(async (tx) => {
      // Conditional on PENDING so two admins (or a double click) cannot both decide.
      const claimed = await tx.verificationRequest.updateMany({
        where: { id, status: 'PENDING' },
        data: {
          status,
          reviewNote: note,
          reviewerId: adminId,
          reviewedAt: new Date(),
        },
      });
      if (claimed.count !== 1) {
        throw new ApiException(
          HttpStatus.CONFLICT,
          'CONFLICT',
          'This verification has already been reviewed',
        );
      }
      await tx.user.update({
        where: { id: existing.userId },
        data: { verificationStatus: status },
      });
      await tx.auditLog.create({
        data: {
          actorId: adminId,
          action: `verification.${status === 'APPROVED' ? 'approve' : 'reject'}`,
          entityType: 'VerificationRequest',
          entityId: id,
          metadata: { userId: existing.userId, ...(note && { note }) },
        },
      });
    });
    return existing;
  }

  private deleteQuietly(key: string): void {
    this.kyc
      .delete(key)
      .catch((e: Error) =>
        this.logger.warn(`Could not delete KYC object ${key}: ${e.message}`),
      );
  }

  private notFound(): ApiException {
    return new ApiException(
      HttpStatus.NOT_FOUND,
      'NOT_FOUND',
      'Verification request not found',
    );
  }

  private uploadInvalid(message: string): ApiException {
    return new ApiException(HttpStatus.BAD_REQUEST, 'UPLOAD_INVALID', message);
  }
}
