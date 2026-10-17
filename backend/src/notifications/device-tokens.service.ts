import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DeviceTokensService {
  constructor(private readonly prisma: PrismaService) {}

  /** Idempotent. A token identifies one physical device, so it moves to whoever registered it last (shared phone, re-login). */
  async register(
    userId: string,
    token: string,
    platform: string,
  ): Promise<void> {
    await this.prisma.deviceToken.upsert({
      where: { token },
      create: { userId, token, platform },
      update: { userId, platform },
    });
  }

  /** Idempotent; only removes the caller's own registration. */
  async remove(userId: string, token: string): Promise<void> {
    await this.prisma.deviceToken.deleteMany({ where: { userId, token } });
  }
}
