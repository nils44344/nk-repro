const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
prisma.$queryRaw`select 1`.then(() => console.log('OK')).catch((e) => console.log(e.constructor.name, '| code:', e.errorCode, '|', e.message.trim().split('\n').slice(-2).join(' / '))).finally(() => prisma.$disconnect());
