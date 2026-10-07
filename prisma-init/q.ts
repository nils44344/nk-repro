import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from './src/generated/prisma/client.ts';
const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL! }) });
const u = await prisma.user.upsert({ where: { email: 'a@example.com' }, update: {}, create: { email: 'a@example.com', name: 'A' } });
console.log('query ok:', u, 'count', await prisma.user.count());
await prisma.$disconnect();
