// P2002 "Unique constraint failed": each way to hit it, on Postgres and SQLite, and what the error object holds.
import { PrismaClient, Prisma } from './src/generated/prisma/client.js';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaBetterSqlite3 } from '@prisma/adapter-better-sqlite3';
const pg = process.env.DB === 'pg';
const adapter = pg ? new PrismaPg({ connectionString: process.env.DATABASE_URL! }) : new PrismaBetterSqlite3({ url: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });
const show = (label: string, e: any) => {
  if (e instanceof Prisma.PrismaClientKnownRequestError)
    console.log(`${label}: code ${e.code} | last line: ${e.message.split('\n').filter(Boolean).slice(-1)[0]} | meta: ${JSON.stringify(e.meta)}`);
  else console.log(`${label}: OTHER ${e?.constructor?.name} ${String(e?.message).slice(0, 300)}`);
};
await prisma.user.deleteMany();
await prisma.user.create({ data: { email: 'a@x.com' } });
try { await prisma.user.create({ data: { email: 'a@x.com' } }); } catch (e) { show('duplicate create', e); }
const f = await prisma.user.create({ data: { email: 'f@x.com' } });
try { await prisma.user.update({ where: { id: f.id }, data: { email: 'a@x.com' } }); } catch (e) { show('update to taken value', e); }
try { await prisma.user.create({ data: { email: 'A@x.com' } }); console.log('different case A@x.com: created, no error'); } catch (e) { show('case', e); }

await prisma.user.deleteMany();
if (pg) await prisma.$executeRawUnsafe('TRUNCATE "User" RESTART IDENTITY');
await prisma.user.createMany({ data: [{ id: 1, email: 'b1@x.com' }, { id: 2, email: 'b2@x.com' }] });
try { const u = await prisma.user.create({ data: { email: 'b3@x.com' } }); console.log('create after explicit ids: OK id', u.id); } catch (e) { show('create after explicit ids', e); }
if (pg) {
  await prisma.$executeRawUnsafe(`SELECT setval(pg_get_serial_sequence('"User"', 'id'), (SELECT MAX(id) FROM "User"))`);
  const u = await prisma.user.create({ data: { email: 'b4@x.com' } }); console.log('after setval: OK id', u.id);
}

await prisma.user.deleteMany();
let rej = 0, first: any;
for (let i = 0; i < 20; i++) {
  const em = `c${i}@x.com`;
  const r = await Promise.allSettled([1, 2, 3].map(() => prisma.user.upsert({ where: { email: em }, update: {}, create: { email: em } })));
  for (const x of r) if (x.status === 'rejected') { rej++; first ??= x.reason; }
}
console.log(`concurrent upsert: ${rej} of 60 rejected`); if (first) show('  first upsert rejection', first);
rej = 0; first = undefined;
for (let i = 0; i < 20; i++) {
  const em = `d${i}@x.com`;
  const r = await Promise.allSettled([1, 2, 3].map(async () => (await prisma.user.findUnique({ where: { email: em } })) ?? prisma.user.create({ data: { email: em } })));
  for (const x of r) if (x.status === 'rejected') { rej++; first ??= x.reason; }
}
console.log(`concurrent findUnique-then-create: ${rej} of 60 rejected`); if (first) show('  first rejection', first);
try { const r = await prisma.user.createMany({ data: [{ email: 'a@x.com' }, { email: 'e@x.com' }, { email: 'e@x.com' }], skipDuplicates: true }); console.log('createMany skipDuplicates: count', r.count); } catch (e) { show('createMany skipDuplicates', e); }
try { await prisma.user.createMany({ data: [{ email: 'g@x.com' }, { email: 'g@x.com' }] }); } catch (e) { show('createMany with a duplicate', e); }
console.log('rows with g@x.com:', await prisma.user.count({ where: { email: 'g@x.com' } }));
await prisma.$disconnect();
