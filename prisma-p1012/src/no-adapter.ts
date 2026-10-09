import 'dotenv/config';
import { PrismaClient } from './generated/prisma/client';
const prisma = new PrismaClient();
console.log(await prisma.user.count());
