import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from './generated/prisma/client';
const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL }) });
await prisma.user.upsert({ where: { email: 'a@b.c' }, update: {}, create: { email: 'a@b.c' } });
console.log('users:', await prisma.user.count());
await prisma.$disconnect();
