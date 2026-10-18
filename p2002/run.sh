#!/bin/bash
# Prisma P2002 on Postgres 18 and SQLite.
set +e
cd "$(dirname "$0")"
docker run -d --name pg -e POSTGRES_PASSWORD=pw -p 5432:5432 postgres:18 >/dev/null
npm init -y >/dev/null; npm pkg set type=module >/dev/null
npm i prisma@7 @prisma/client@7 @prisma/adapter-pg@7 @prisma/adapter-better-sqlite3@7 tsx --silent >/dev/null 2>&1
echo "prisma $(node -p "require('prisma/package.json').version") node $(node -v)"
for DB in pg sqlite; do
  P=$([ $DB = pg ] && echo postgresql || echo sqlite)
  mkdir -p prisma; printf 'generator client {\n  provider = "prisma-client"\n  output   = "../src/generated/prisma"\n}\ndatasource db {\n  provider = "%s"\n}\nmodel User {\n  id    Int    @id @default(autoincrement())\n  email String @unique\n}\n' $P > prisma/schema.prisma
  printf "import { defineConfig, env } from 'prisma/config';\nexport default defineConfig({ schema: 'prisma/schema.prisma', datasource: { url: env('DATABASE_URL') } });\n" > prisma.config.ts
  export DB DATABASE_URL=$([ $DB = pg ] && echo 'postgresql://postgres:pw@localhost:5432/postgres' || echo 'file:./dev.db')
  [ $DB = pg ] && for i in $(seq 1 40); do pg_isready -q -h localhost && break; sleep 1; done
  echo "======== $DB"
  npx prisma db push --accept-data-loss 2>&1 | grep -iE "error|in sync|sync" | head -2
  npx prisma generate >/dev/null 2>&1
  npx tsx t.ts 2>&1 | cut -c1-600
done
