// Fixes for the races, the SQLite skipDuplicates message, and a helper that reads the field on both databases.
import { PrismaClient, Prisma } from './src/generated/prisma/client.js';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaBetterSqlite3 } from '@prisma/adapter-better-sqlite3';
const pg = process.env.DB === 'pg';
const adapter = pg ? new PrismaPg({ connectionString: process.env.DATABASE_URL! }) : new PrismaBetterSqlite3({ url: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });
const isUnique = (e: unknown) => e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002';
const what = (e: any) => { const c = e?.meta?.driverAdapterError?.cause?.constraint; return c?.fields?.join(',') ?? c?.index ?? e?.meta?.target; };
async function upsertRetry(email: string) {
  try { return await prisma.user.upsert({ where: { email }, update: {}, create: { email } }); }
  catch (e) { if (isUnique(e)) return prisma.user.findUniqueOrThrow({ where: { email } }); throw e; }
}
await prisma.user.deleteMany();
let rej = 0;
for (let i = 0; i < 20; i++) { const r = await Promise.allSettled([1, 2, 3].map(() => upsertRetry(`r${i}@x.com`))); rej += r.filter((x) => x.status === 'rejected').length; }
console.log(`upsert + catch P2002 then read: ${rej} of 60 rejected, rows ${await prisma.user.count()}`);
rej = 0;
for (let i = 0; i < 20; i++) { const r = await Promise.allSettled([1, 2, 3].map(() => prisma.user.createMany({ data: [{ email: `s${i}@x.com` }], skipDuplicates: true }))); rej += r.filter((x) => x.status === 'rejected').length; }
console.log(`concurrent createMany skipDuplicates: ${rej} of 60 rejected`);
try { await prisma.user.create({ data: { email: 'r0@x.com' } }); } catch (e) { console.log('isUnique:', isUnique(e), '| meta.target:', JSON.stringify((e as any).meta?.target), '| helper says:', what(e)); }
if (!pg) { try { await prisma.user.createMany({ data: [{ email: 'z@x.com' }], skipDuplicates: true }); } catch (e: any) { console.log('sqlite skipDuplicates:', e.message.split('\n').filter((l: string) => /Unknown|argument|Available/i.test(l)).join(' / ')); } }
await prisma.$disconnect();
