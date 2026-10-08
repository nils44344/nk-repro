// Re-checks https://nilaykabariya.blog/tested/nextjs-16-3-vulnerabilities-which-version-is-patched.
// npm audit only (lockfile, no build): a new advisory or a new 16.3.x patch flips a check, which is exactly when
// the post's "which version is patched" table goes stale.
import { sh, tmp, files, check, record } from './lib.mjs';

const POST = 'nextjs-16-3-vulnerabilities-which-version-is-patched';

/** Advisories npm audit lists against `next` at an exact version. */
function advisories(version) {
  const d = tmp('next');
  files(d, { 'package.json': { name: 'n', private: true, dependencies: { next: version, react: '19.2.0', 'react-dom': '19.2.0' } } });
  sh('npm i --package-lock-only --no-fund --no-audit --legacy-peer-deps', d);
  try {
    const a = JSON.parse(sh('npm audit --json', d).replace(/^[^{]*/, ''));
    const n = a.vulnerabilities?.next;
    return n ? n.via.filter((x) => typeof x === 'object').length : 0;
  } catch { return -1; }
}

const line16_3 = sh('npm view next@16.3 version --json').trim();
const newest16_3 = (() => { try { const v = JSON.parse(line16_3); return Array.isArray(v) ? v.at(-1) : v; } catch { return 'unknown'; } })();
const a1637 = advisories('16.3.7');
const a1638 = advisories('16.3.8');
const latest = sh('npm view next dist-tags.latest').trim();
const aLatest = advisories(latest);

const checks = [
  check('16.3.7 is still flagged by npm audit (the post counted 6 advisories)', () => `16.3.7: ${a1637} advisories`, () => a1637 === 6),
  check('16.3.8 is not flagged by npm audit', () => `16.3.8: ${a1638} advisories`, () => a1638 === 0),
  check('`npm i next@16.3` still resolves to 16.3.8 (no newer 16.3 patch)', () => `newest 16.3.x: ${newest16_3}`, () => newest16_3 === '16.3.8'),
  check(`next@latest (${latest}) is not flagged by npm audit`, () => `${latest}: ${aLatest} advisories`, () => aLatest === 0),
];

const ok = record(POST, { 'next (latest tag)': latest, 'newest 16.3.x': newest16_3 }, checks);
process.exitCode = ok ? 0 : 1;
