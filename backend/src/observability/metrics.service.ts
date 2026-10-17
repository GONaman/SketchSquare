import { Injectable } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';
import {
  collectDefaultMetrics,
  Counter,
  Histogram,
  Registry,
} from 'prom-client';

/** Prometheus registry (own instance, so tests can boot many apps) plus the HTTP RED metrics. */
@Injectable()
export class MetricsService {
  readonly registry = new Registry();
  private readonly requests = new Counter({
    name: 'sketchsquare_http_requests_total',
    help: 'HTTP requests by method, route template and status',
    labelNames: ['method', 'route', 'status'],
    registers: [this.registry],
  });
  private readonly duration = new Histogram({
    name: 'sketchsquare_http_request_duration_seconds',
    help: 'HTTP request latency',
    labelNames: ['method', 'route', 'status'],
    buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
    registers: [this.registry],
  });

  constructor() {
    collectDefaultMetrics({
      register: this.registry,
      prefix: 'sketchsquare_',
    });
  }

  /** Express middleware; labels use the route template (`/drawings/:id`) to keep cardinality bounded. */
  readonly middleware = (
    req: Request,
    res: Response,
    next: NextFunction,
  ): void => {
    const stop = this.duration.startTimer();
    res.on('finish', () => {
      const route = req.route as { path?: string } | undefined;
      const labels = {
        method: req.method,
        route: route?.path ? `${req.baseUrl}${route.path}` : 'unmatched',
        status: String(res.statusCode),
      };
      this.requests.inc(labels);
      stop(labels);
    });
    next();
  };

  render(): Promise<string> {
    return this.registry.metrics();
  }

  get contentType(): string {
    return this.registry.contentType;
  }
}
