import { Controller, Get, HttpStatus, Req, Res } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiExcludeController } from '@nestjs/swagger';
import { SkipThrottle } from '@nestjs/throttler';
import type { Request, Response } from 'express';
import { Public } from '../common/decorators/access.decorators';
import { ApiException } from '../common/errors/api-exception';
import { Env } from '../config/env.schema';
import { bearerToken, isInternalRequest, tokenMatches } from './metrics-access';
import { MetricsService } from './metrics.service';

/** Operational endpoint, not part of the product API contract (hence excluded from OpenAPI). */
@ApiExcludeController()
@SkipThrottle()
@Controller('metrics')
export class MetricsController {
  constructor(
    private readonly metrics: MetricsService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  // Public = no user JWT; access is controlled here by METRICS_TOKEN (scrapers) or by network position.
  @Public()
  @Get()
  async scrape(
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ): Promise<string> {
    const token = this.config.get('METRICS_TOKEN', { infer: true });
    if (token) {
      if (!tokenMatches(bearerToken(req.headers.authorization), token)) {
        throw new ApiException(
          HttpStatus.UNAUTHORIZED,
          'UNAUTHORIZED',
          'Invalid metrics token',
        );
      }
    } else if (
      !isInternalRequest(
        req.socket.remoteAddress,
        req.headers['x-forwarded-for'],
      )
    ) {
      throw new ApiException(
        HttpStatus.FORBIDDEN,
        'FORBIDDEN',
        'Metrics are only available from the internal network (or with METRICS_TOKEN)',
      );
    }
    res.type(this.metrics.contentType);
    return this.metrics.render();
  }
}
