/**
 * Sets env vars for the current test file and restores them afterwards. e2e suites run in one process (`--runInBand`),
 * so an unrestored override would leak into whichever file Jest happens to schedule next.
 */
export function overrideEnv(vars: Record<string, string>): void {
  const previous = Object.fromEntries(
    Object.keys(vars).map((key) => [key, process.env[key]]),
  );
  Object.assign(process.env, vars);
  afterAll(() => {
    for (const [key, value] of Object.entries(previous)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  });
}
