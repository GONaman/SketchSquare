import { Controller, Get, Res } from '@nestjs/common';
import { ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { Public } from '../common/decorators/access.decorators';
import { ShutdownState } from '../observability/graceful-shutdown';
import { HealthReport, HealthService } from './health.service';

@ApiTags('ops')
@Controller('health')
export class HealthController {
  constructor(
    private readonly health: HealthService,
    private readonly shutdown: ShutdownState,
  ) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'Liveness + dependency check (DB, Redis, S3)' })
  @ApiOkResponse({
    schema: {
      example: { status: 'ok', checks: { db: 'up', redis: 'up', s3: 'up' } },
    },
  })
  async get(@Res({ passthrough: true }) res: Response): Promise<HealthReport> {
    if (this.shutdown.active) {
      res.status(503);
      return { status: 'error', shuttingDown: true };
    }
    const report = await this.health.check();
    if (report.status !== 'ok') res.status(503);
    return report;
  }
}
