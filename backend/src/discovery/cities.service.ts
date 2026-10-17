import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export interface CityCount {
  city: string;
  count: number;
}

@Injectable()
export class CitiesService {
  constructor(private readonly prisma: PrismaService) {}

  /** Cities with searchable drawings; spellings differing only by case are merged (search is case-insensitive). */
  list(): Promise<CityCount[]> {
    return this.prisma.$queryRaw<CityCount[]>`
      SELECT min(d."city") AS "city", count(*)::int AS "count"
      FROM "Drawing" d
      JOIN "User" u ON u."id" = d."architectId"
      WHERE d."status" = 'PUBLISHED' AND u."verificationStatus" = 'APPROVED'
      GROUP BY lower(d."city")
      ORDER BY count(*) DESC, lower(d."city") ASC`;
  }
}
