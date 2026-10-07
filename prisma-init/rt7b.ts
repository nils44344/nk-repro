import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from './src/generated/prisma/client.ts';
const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL! }) });
try { await prisma.user.count(); console.log('OK'); }
catch (e: any) { console.log(`[${e.name} code=${e.code} kind=${e.meta?.driverAdapterError?.cause?.kind ?? '-'}]`); console.log(String(e.message).split('\n').filter((l) => l.trim() && !/^\s*(→|\d+ )/.test(l)).join('\n')); }
await prisma.$disconnect();
