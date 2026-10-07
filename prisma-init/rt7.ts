import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from './src/generated/prisma/client.ts';
const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL! }) });
try { await prisma.user.count(); console.log('OK'); }
catch (e: any) {
  console.log('P7 name:', e.name, '| code:', e.code, '| meta:', JSON.stringify(e.meta));
  console.log(String(e.message).trim().split('\n').filter(Boolean).slice(-2).join('\n'));
}
await prisma.$disconnect();
