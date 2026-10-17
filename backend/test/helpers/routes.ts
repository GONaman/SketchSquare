import { INestApplication, RequestMethod } from '@nestjs/common';
import { METHOD_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { DiscoveryService, MetadataScanner, Reflector } from '@nestjs/core';
import {
  ALLOW_UNVERIFIED_KEY,
  IS_PUBLIC_KEY,
  ROLES_KEY,
} from '../../src/common/decorators/access.decorators';

export type AccessLevel = 'public' | 'authed' | 'approved' | 'admin';

export interface RouteInfo {
  /** `METHOD /path/:param` exactly as declared (controller path + handler path). */
  key: string;
  method: string;
  path: string;
  /** Access derived from the decorator metadata the global guards act on. */
  access: AccessLevel;
  /** Handler is wrapped in `@SkipThrottle` for the `write` throttler. */
  skipsWriteThrottle: boolean;
}

const join = (...parts: string[]) =>
  '/' +
  parts
    .flatMap((p) => p.split('/'))
    .filter(Boolean)
    .join('/');

/** Walks every controller registered in the Nest container (no hand-maintained list). */
export function enumerateRoutes(app: INestApplication): RouteInfo[] {
  const discovery = app.get(DiscoveryService);
  const scanner = app.get(MetadataScanner);
  const reflector = app.get(Reflector);
  const routes: RouteInfo[] = [];

  for (const wrapper of discovery.getControllers()) {
    const instance = wrapper.instance as object | undefined;
    const metatype = wrapper.metatype as (new () => unknown) | null;
    if (!instance || !metatype) continue;
    const prefix = Reflect.getMetadata(PATH_METADATA, metatype) as
      string | string[] | undefined;
    const proto = Object.getPrototypeOf(instance) as object;
    for (const name of scanner.getAllMethodNames(proto)) {
      const handler = (proto as Record<string, () => unknown>)[name];
      const methodId = Reflect.getMetadata(METHOD_METADATA, handler) as
        RequestMethod | undefined;
      if (methodId === undefined) continue;
      const sub = Reflect.getMetadata(PATH_METADATA, handler) as
        string | string[] | undefined;
      const method = RequestMethod[methodId];
      const meta = <T>(key: string) =>
        reflector.getAllAndOverride<T | undefined>(key, [handler, metatype]);
      const roles = meta<string[]>(ROLES_KEY);
      let access: AccessLevel = 'approved';
      if (meta<boolean>(IS_PUBLIC_KEY)) access = 'public';
      else if (roles?.includes('ADMIN')) access = 'admin';
      else if (meta<boolean>(ALLOW_UNVERIFIED_KEY)) access = 'authed';
      const prefixes = [prefix ?? ''].flat();
      const subs = [sub ?? ''].flat();
      // Array paths (aliases) become one route each; shadowed duplicates collapse to one entry.
      for (const p of prefixes) {
        for (const s of subs) {
          const path = join(p, s);
          const key = `${method} ${path}`;
          if (routes.some((r) => r.key === key)) continue;
          routes.push({
            key,
            method,
            path,
            access,
            skipsWriteThrottle: Boolean(meta<boolean>('THROTTLER:SKIPwrite')),
          });
        }
      }
    }
  }
  return routes.sort((a, b) => a.key.localeCompare(b.key));
}
