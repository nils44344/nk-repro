// Re-checks https://nilaykabariya.blog/database/drizzle-failed-query-error on the newest drizzle-orm (PGlite, no server).
import { sh, tmp, files, check, record } from './lib.mjs';

const POST = 'drizzle-failed-query-error';
const d = tmp('drizzle');
files(d, {
  'package.json': { name: 'dz', private: true, type: 'module' },
  'probe.mjs': `import { PGlite } from '@electric-sql/pglite';
import { drizzle } from 'drizzle-orm/pglite';
import * as root from 'drizzle-orm';
import { DrizzleQueryError } from 'drizzle-orm/errors';
import { pgTable, serial, text } from 'drizzle-orm/pg-core';
const users = pgTable('users', { id: serial('id').primaryKey(), email: text('email').notNull().unique() });
const db = drizzle(new PGlite());
await db.execute('create table users (id serial primary key, email text not null unique)');
await db.insert(users).values({ email: 'a@b.c' });
try { await db.insert(users).values({ email: 'a@b.c' }); }
catch (e) {
  console.log(JSON.stringify({
    wrapped: e instanceof DrizzleQueryError,
    failedQuery: String(e.message).startsWith('Failed query:'),
    code: e.code ?? null,
    causeCode: e.cause?.code ?? null,
    rootExport: 'DrizzleQueryError' in root,
  }));
}
`,
});
sh('npm i drizzle-orm@latest @electric-sql/pglite@latest --no-fund --no-audit', d);
const version = sh('npm ls drizzle-orm --depth=0', d).match(/drizzle-orm@(\S+)/)?.[1] ?? 'unknown';
let r = {};
const out = sh('node probe.mjs', d);
try { r = JSON.parse(out.trim().split('\n').pop()); } catch {}
const ev = () => out.trim().split('\n').pop();

const checks = [
  check('Errors are wrapped: DrizzleQueryError with "Failed query:" message', ev, () => r.wrapped && r.failedQuery),
  check('e.code is undefined on the wrapper (the 0.44 breaking change)', ev, () => r.code === null),
  check('The Postgres code is on e.cause.code (23505)', ev, () => r.causeCode === '23505'),
  check('DrizzleQueryError is exported from drizzle-orm root (0.45+)', ev, () => r.rootExport === true),
];
const ok = record(POST, { 'drizzle-orm': version }, checks);
process.exitCode = ok ? 0 : 1;
