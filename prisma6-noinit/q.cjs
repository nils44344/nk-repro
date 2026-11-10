// One query through the generated client; prints the error class and the lines that name the server.
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
prisma.$queryRaw`select 1`
  .then(() => console.log('OK'))
  .catch((e) => console.log(e.constructor.name, '| errorCode:', e.errorCode, '|', e.message.split('\n').filter((l) => /reach|running/.test(l)).map((l) => l.trim()).join(' / ')))
  .finally(() => prisma.$disconnect());
