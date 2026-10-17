import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleDestroy {
  // No eager $connect: Prisma connects lazily, which keeps `npm run openapi` and unit tests infra-free.
  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
