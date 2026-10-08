// Re-checks https://nilaykabariya.blog/database/prisma-generate-no-command-registered-prisma-8.
// The post's whole premise is a split npm tag: `prisma@latest` is the Prisma 8 release candidate while
// `@prisma/client@latest` is still 7.x. When Prisma 8 goes final these checks flip, and the post needs an update.
import { sh, tmp, files, check, record } from './lib.mjs';

const POST = 'prisma-generate-no-command-registered-prisma-8';
const latest = sh('npm view prisma dist-tags.latest').trim();
const client = sh('npm view @prisma/client dist-tags.latest').trim();

const schema = `generator client {
  provider = "prisma-client"
  output   = "../src/generated/prisma"
}

datasource db {
  provider = "postgresql"
}

model User {
  id    Int     @id @default(autoincrement())
  email String  @unique
}
`;
const dir = () => {
  const d = tmp('prisma');
  files(d, { 'prisma/schema.prisma': schema, '.env': 'DATABASE_URL="postgresql://postgres:repro@localhost:55432/postgres"\n' });
  return d;
};

const checks = [
  check('npm "latest" for prisma is still a Prisma 8 release candidate', () => latest, (v) => /^8\.\d+\.\d+-rc/.test(v)),
  check('npm "latest" for @prisma/client is still 7.x', () => client, (v) => /^7\./.test(v)),
  check('Unpinned `npx -y prisma generate` fails: No command registered for `generate`', () => sh('npx -y prisma generate', dir()), (o) => /No command registered for `generate`/.test(o)),
  check('Fix: `npx -y prisma@7 generate` generates the client', () => sh('npx -y prisma@7 generate', dir()), (o) => /Generated Prisma Client \(7\./.test(o)),
];

const ok = record(POST, { 'prisma (latest tag)': latest, '@prisma/client (latest tag)': client }, checks);
process.exitCode = ok ? 0 : 1;
