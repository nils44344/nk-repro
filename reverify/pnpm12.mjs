// Re-checks https://nilaykabariya.blog/tested/pnpm-12-breaking-changes-tested on the newest pnpm (npm's latest tag).
import { sh, tmp, files, check, record } from './lib.mjs';

const POST = 'pnpm-12-breaking-changes-tested';
const latest = sh('npm view pnpm dist-tags.latest').trim();
const pnpm = `npx -y pnpm@${latest}`;
const fresh = (name) => {
  const d = tmp(name);
  files(d, { 'package.json': { name: 'p', version: '1.0.0', private: true, dependencies: { 'is-number': '7.0.0' } } });
  return d;
};

const checks = [
  check(`npm's latest pnpm (${latest}) is still major 12`, () => latest, (o) => /^12\./.test(o)),
  check('--frozen-lockfile false: "unexpected argument \'--frozen-lockfile\' found"', () => sh(`${pnpm} install --frozen-lockfile false`, fresh('fl')), (o) => /unexpected argument '--frozen-lockfile' found/.test(o)),
  check('--no-frozen-lockfile installs', () => { const d = fresh('nfl'); return sh(`${pnpm} install --no-frozen-lockfile`, d) + sh('node -e "require(\'is-number\');console.log(\'REQUIRE_OK\')"', d); }, (o) => /REQUIRE_OK/.test(o) && !/unexpected argument/.test(o)),
  check('--resolution-only: "unexpected argument \'--resolution-only\' found"', () => sh(`${pnpm} install --resolution-only`, fresh('ro')), (o) => /unexpected argument '--resolution-only' found/.test(o)),
];
const ok = record(POST, { pnpm: latest }, checks);
process.exitCode = ok ? 0 : 1;
