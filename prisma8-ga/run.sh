#!/bin/bash
# Prisma 8 release day: re-run what the Prisma posts claim on the GA version, from a clean folder.
# Usage: PV=8.0.0 bash run.sh   (default: the latest tag). Output goes to out-$PV.txt beside this script.
export NODE_EXTRA_CA_CERTS=D:/tools/ca-bundle-win.pem
set +e
PV=${PV:-latest}; HERE=$(cd "$(dirname "$0")" && pwd); W=D:/nk-prisma8/p; rm -rf $W; mkdir -p $W; cd $W
exec > >(tee "$HERE/out-$PV.txt") 2>&1
npm init -y >/dev/null; npm pkg set type=module
echo "== install prisma@$PV @prisma/client@$PV"
npm install -D prisma@$PV tsx typescript @types/node --no-audit --no-fund --loglevel=error 2>&1 | tail -3
npm install @prisma/client@$PV --no-audit --no-fund --loglevel=error 2>&1 | tail -3
npx prisma --version
echo "== prisma init (sqlite)"; npx prisma init --datasource-provider sqlite 2>&1 | tail -8
ls; cat prisma/schema.prisma; cat prisma.config.ts 2>/dev/null
cat >> prisma/schema.prisma <<'S'

model User {
  id    Int    @id @default(autoincrement())
  email String @unique
}
S
echo "== prisma generate"; npx prisma generate 2>&1 | tail -8
echo "== prisma migrate dev"; npx prisma migrate dev --name init 2>&1 | tail -8
echo "== client import from @prisma/client (old path)"
echo "import { PrismaClient } from '@prisma/client'; const p = new PrismaClient(); console.log('ok', typeof p.user);" > old.mjs
node old.mjs 2>&1 | head -4
echo "== client import from the generated output (new path)"
OUT=$(grep -oE 'output\s*=\s*"[^"]+"' prisma/schema.prisma | sed -E 's/.*"(.+)"/\1/'); echo "output: $OUT"
echo "== duplicate email (P2002)"
cat > dup.ts <<D
import { PrismaClient } from './prisma/${OUT:-../node_modules/.prisma/client}/client';
const p = new PrismaClient();
await p.user.create({ data: { email: 'a@b.c' } });
try { await p.user.create({ data: { email: 'a@b.c' } }); } catch (e: any) { console.log(e.code, e.message.split('\n').slice(-2).join(' ')); }
D
npx tsx dup.ts 2>&1 | tail -4
echo "== done $(date)"
