import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DrawingStatus, Prisma } from '@prisma/client';
import { ApiException } from '../common/errors/api-exception';
import { Env } from '../config/env.schema';
import { PrismaService } from '../prisma/prisma.service';

export interface ContributionStatus {
  freePublished: number;
  /** Paid drawings that are published. */
  paidPublished: number;
  /** Paid drawings still going through processing/review; they count towards the next paid drawing's requirement. */
  paidPending: number;
  /** Configured ratio: free drawings needed per paid drawing already published/pending (0 = rule disabled). */
  freePerPaid: number;
  /** Additional free drawings needed before another paid drawing can be published. */
  freeNeeded: number;
  canPublishPaid: boolean;
  guidance: string;
}

/** Pure rule: the first paid drawing is always allowed; every further one needs `freePerPaid` free drawings per paid one. */
export function evaluateContribution(
  freePublished: number,
  paidPublished: number,
  paidPending: number,
  freePerPaid: number,
): Pick<ContributionStatus, 'canPublishPaid' | 'freeNeeded' | 'guidance'> {
  const required = freePerPaid * (paidPublished + paidPending);
  const freeNeeded = Math.max(0, required - freePublished);
  const canPublishPaid = freePerPaid === 0 || freeNeeded === 0;
  const plural = freeNeeded === 1 ? 'drawing' : 'drawings';
  let guidance: string;
  if (freePerPaid === 0) {
    guidance = 'You can publish paid drawings.';
  } else if (!canPublishPaid) {
    guidance = `Publish ${freeNeeded} more free ${plural} to unlock publishing another paid drawing. SketchSquare asks architects to contribute free drawings to the community in return for selling paid ones.`;
  } else if (paidPublished + paidPending === 0) {
    guidance = `Your first paid drawing can be published right away. After that, you need ${freePerPaid} published free ${freePerPaid === 1 ? 'drawing' : 'drawings'} per paid drawing.`;
  } else {
    guidance = 'You can publish another paid drawing.';
  }
  return { canPublishPaid, freeNeeded, guidance };
}

type Db = PrismaService | Prisma.TransactionClient;

@Injectable()
export class ContributionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  private get freePerPaid(): number {
    return this.config.get('CONTRIBUTION_FREE_PER_PAID', { infer: true });
  }

  async status(
    userId: string,
    db: Db = this.prisma,
  ): Promise<ContributionStatus> {
    const [freePublished, paidPublished, paidPending] = await Promise.all([
      db.drawing.count({
        where: {
          architectId: userId,
          pricePaise: 0,
          status: DrawingStatus.PUBLISHED,
        },
      }),
      db.drawing.count({
        where: {
          architectId: userId,
          pricePaise: { gt: 0 },
          status: DrawingStatus.PUBLISHED,
        },
      }),
      db.drawing.count({
        where: {
          architectId: userId,
          pricePaise: { gt: 0 },
          status: {
            in: [DrawingStatus.PROCESSING, DrawingStatus.UNDER_REVIEW],
          },
        },
      }),
    ]);
    const freePerPaid = this.freePerPaid;
    return {
      freePublished,
      paidPublished,
      paidPending,
      freePerPaid,
      ...evaluateContribution(
        freePublished,
        paidPublished,
        paidPending,
        freePerPaid,
      ),
    };
  }

  /** Throws CONTRIBUTION_REQUIRED if the architect may not publish another paid drawing yet. */
  async assertCanPublishPaid(
    userId: string,
    db: Db = this.prisma,
  ): Promise<void> {
    const status = await this.status(userId, db);
    if (status.canPublishPaid) return;
    throw new ApiException(
      HttpStatus.FORBIDDEN,
      'CONTRIBUTION_REQUIRED',
      status.guidance,
      {
        freePublished: status.freePublished,
        paidPublished: status.paidPublished,
        paidPending: status.paidPending,
        freePerPaid: status.freePerPaid,
        freeNeeded: status.freeNeeded,
      },
    );
  }
}
