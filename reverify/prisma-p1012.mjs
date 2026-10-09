// Re-checks https://nilaykabariya.blog/database/prisma-datasource-url-no-longer-supported-p1012 on the newest Prisma 7.
// No database needed: every error the post quotes happens before Prisma connects.
import { sh, tmp, files, check, record } from './lib.mjs';

const POST = 'prisma-datasource-url-no-longer-supported-p1012';
const d = tmp('p1012');
const schema = (extra) => `generator client {
  provider = "prisma-client"
  output   = "../src/generated/prisma"
}

datasource db {
  provider = "postgresql"
${extra}}

model User {
  id    Int    @id @default(autoincrement())
  email String @unique
}
`;
const config = (dotenv) => `${dotenv ? "import 'dotenv/config';\n" : ''}import { defineConfig, env } from 'prisma/config';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: { path: 'prisma/migrations' },
  datasource: { url: env('DATABASE_URL') },
});
`;
files(d, { 'package.json': { name: 'p', private: true, type: 'module' }, '.env': 'DATABASE_URL="postgresql://postgres:repro@localhost:55432/postgres"\n' });
sh('npm i -D prisma@7 --no-fund --no-audit && npm i @prisma/client@7 dotenv --no-fund --no-audit', d);
const version = sh('npx prisma -v', d).match(/prisma\s*:\s*(\S+)/)?.[1] ?? 'unknown';
const prisma = (args) => sh(`npx prisma ${args}`, d);

const checks = [];
files(d, { 'prisma/schema.prisma': schema('  url      = env("DATABASE_URL")\n') });
checks.push(check('`url` in the schema: P1012 "no longer supported in schema files"', () => prisma('generate'), (o) => /P1012/.test(o) && /`url` is no longer supported in schema files/.test(o)));
files(d, { 'prisma.config.ts': config(true) });
checks.push(check('`url` kept alongside prisma.config.ts: still P1012', () => prisma('generate'), (o) => /P1012/.test(o)));
sh(process.platform === 'win32' ? 'del prisma.config.ts' : 'rm prisma.config.ts', d);
files(d, { 'prisma/schema.prisma': schema('  directUrl = env("DIRECT_URL")\n') });
checks.push(check('`directUrl` in the schema: P1012 "The datasource property directUrl is no longer supported"', () => prisma('generate'), (o) => /P1012/.test(o) && /property `directUrl` is no longer supported in schema files/.test(o)));
files(d, { 'prisma/schema.prisma': schema('') });
checks.push(check('No URL and no config: migrate dev says datasource.url is required', () => prisma('migrate dev --name init'), (o) => /datasource\.url property is required in your Prisma config file/.test(o)));
files(d, { 'prisma.config.ts': config(false) });
checks.push(check('Config without dotenv: "Cannot resolve environment variable: DATABASE_URL"', () => prisma('validate'), (o) => /Cannot resolve environment variable: DATABASE_URL/.test(o)));
files(d, { 'prisma.config.ts': config(true) });
checks.push(check('Fix: config with dotenv validates', () => prisma('validate'), (o) => /is valid/.test(o)));

const ok = record(POST, { 'prisma (7.x)': version }, checks);
process.exitCode = ok ? 0 : 1;
