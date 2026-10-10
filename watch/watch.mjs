// Release watcher: notices the hour a tool this blog covers ships a new version, and opens an issue in this repo
// (which emails the owner) listing the posts it touches. The tested write-up should go up before forum threads do.
// State lives in watch/state.json; the workflow commits it back. Every version is recorded; only changes at or above a
// package's `alert` level open an issue, so daily patch releases don't bury the ones that matter.
import { readFileSync, writeFileSync, existsSync, appendFileSync } from 'node:fs';
import { join } from 'node:path';

const STATE = join(import.meta.dirname, 'state.json');
const BLOG = 'https://nilaykabariya.blog';

// alert: 'all' = any new version (posts depend on exact versions), 'minor' = x.Y.0 and majors, 'major' = X.0.0 only.
const NPM = {
  next: { tags: ['latest'], alert: 'all', posts: ['/tested/nextjs-16-3-vulnerabilities-which-version-is-patched'] },
  prisma: { tags: ['latest'], alert: 'all', posts: ['/database/prisma-generate-no-command-registered-prisma-8', '/database/prisma-client-did-not-initialize-yet', '/database/prisma-p1001-cant-reach-database-server'] },
  '@prisma/client': { tags: ['latest'], alert: 'all', posts: ['/database/prisma-generate-no-command-registered-prisma-8', '/database/prisma-client-did-not-initialize-yet'] },
  bun: { tags: ['latest'], alert: 'all', posts: ['/fixes/bun-error-cannot-find-module', '/tested/bun-vs-node-24-startup-typescript-tests'] },
  typescript: { tags: ['latest'], alert: 'minor', posts: ['/topics/typescript'] },
  vite: { tags: ['latest', 'beta'], alert: 'minor', posts: ['/fixes'] },
  tailwindcss: { tags: ['latest'], alert: 'minor', posts: ['/topics/tailwind'] },
  npm: { tags: ['latest'], alert: 'minor', posts: ['/topics/npm'] },
  '@supabase/supabase-js': { tags: ['latest'], alert: 'minor', posts: ['/database/supabase-error-42501-row-level-security'] },
  supabase: { tags: ['latest'], alert: 'major', posts: ['/database/supabase-error-42501-row-level-security'] },
  openai: { tags: ['latest'], alert: 'major', posts: ['/ai'] },
  '@anthropic-ai/sdk': { tags: ['latest'], alert: 'minor', posts: ['/ai'] },
  '@google/genai': { tags: ['latest'], alert: 'major', posts: ['/ai/gemini-api-429-resource-exhausted', '/ai/gemini-2-5-flash-no-longer-available-to-new-users'] },
  wrangler: { tags: ['latest'], alert: 'major', posts: ['/deploy'] },
  '@anthropic-ai/claude-code': { tags: ['latest'], alert: 'minor', posts: ['/agents'] },
  'drizzle-orm': { tags: ['latest'], alert: 'minor', posts: ['/database/drizzle-failed-query-error'] },
  // Starters with an open Windows problem in the starters report: any release may be the fix.
  nuxt: { tags: ['latest'], alert: 'all', posts: ['/tested/framework-starters-on-windows-tested'] },
  '@docusaurus/core': { tags: ['latest'], alert: 'all', posts: ['/tested/framework-starters-on-windows-tested'] },
  '@swc/core': { tags: ['latest'], alert: 'all', posts: ['/tested/framework-starters-on-windows-tested'] },
  'create-react-router': { tags: ['latest'], alert: 'all', posts: ['/tested/framework-starters-on-windows-tested'] },
  '@angular/cli': { tags: ['latest'], alert: 'minor', posts: ['/tested/framework-starters-on-windows-tested'] },
  'create-cloudflare': { tags: ['latest'], alert: 'minor', posts: ['/tested/framework-starters-on-windows-tested'] },
};
// Node.js: the newest Current release (alert on a new major) and the active LTS line (alert on a new codename: LTS day).
const NODE_POSTS = ['/topics/node', '/tested/bun-vs-node-24-startup-typescript-tests'];

async function json(url) {
  const r = await fetch(url, { headers: { accept: 'application/json' }, signal: AbortSignal.timeout(20_000) });
  if (!r.ok) throw new Error(`${url}: HTTP ${r.status}`);
  return r.json();
}

const now = {};
// Small endpoint: only the dist-tags, not the multi-megabyte package document.
await Promise.all(Object.entries(NPM).map(async ([pkg, { tags }]) => {
  try {
    const dt = await json(`https://registry.npmjs.org/-/package/${pkg.replace('/', '%2F')}/dist-tags`);
    for (const t of tags) if (dt[t]) now[`npm:${pkg}@${t}`] = dt[t];
  } catch (e) { console.log(`skip ${pkg}: ${e.message}`); }
}));
try {
  const idx = await json('https://nodejs.org/dist/index.json');
  now['node:current'] = idx[0].version;
  const lts = idx.find((r) => r.lts);
  now['node:lts'] = `${lts.version} (${lts.lts})`;
} catch (e) { console.log(`skip node: ${e.message}`); }

const before = existsSync(STATE) ? JSON.parse(readFileSync(STATE, 'utf8')) : {};
const first = Object.keys(before).length === 0;
writeFileSync(STATE, JSON.stringify({ ...before, ...now }, null, 2) + '\n');

const parts = (v) => String(v).replace(/^v/, '').split(/[.\s-]/);
/** How big the step is: 'major', 'minor' or 'patch' (prerelease bumps count as patch). */
const step = (a, b) => (parts(a)[0] !== parts(b)[0] ? 'major' : parts(a)[1] !== parts(b)[1] ? 'minor' : 'patch');
const rank = { patch: 0, minor: 1, major: 2 };

const changes = [];
for (const [key, to] of Object.entries(now)) {
  const from = before[key];
  if (!from || from === to) continue;
  const [kind, rest] = key.split(':');
  if (kind === 'npm') {
    const pkg = rest.replace(/@[^@]+$/, '');
    const s = step(from, to);
    const level = NPM[pkg].alert === 'all' ? 'patch' : NPM[pkg].alert;
    if (rank[s] < rank[level]) continue;
    changes.push({ name: rest.replace(/@latest$/, ''), from, to, big: s === 'major', posts: NPM[pkg].posts, link: `https://www.npmjs.com/package/${pkg}/v/${to}` });
  } else {
    // node:lts → a new codename is a new LTS line; node:current → only a new major.
    const big = rest === 'lts' ? from.split(' ')[1] !== to.split(' ')[1] : step(from, to) === 'major';
    if (!big) continue;
    changes.push({ name: `node ${rest}`, from, to, big, posts: NODE_POSTS, link: 'https://nodejs.org/en/blog/release' });
  }
}

const lines = changes.map((c) => `- ${c.big ? '**MAJOR** ' : ''}\`${c.name}\`: ${c.from} → **${c.to}** ([release](${c.link}))\n  Posts: ${c.posts.map((p) => `${BLOG}${p}`).join(', ')}`);
const alert = !first && changes.length > 0;
console.log(first ? `First run: recorded ${Object.keys(now).length} versions, no alerts.` : alert ? lines.join('\n') : 'Nothing at alert level.');

writeFileSync(join(import.meta.dirname, 'last-changes.md'), lines.join('\n') + '\n');
if (process.env.GITHUB_OUTPUT) {
  appendFileSync(process.env.GITHUB_OUTPUT, `changed=${alert}\n`);
  appendFileSync(process.env.GITHUB_OUTPUT, `title=${changes.map((c) => `${c.name} ${c.to}`).join(', ').slice(0, 200)}\n`);
}
