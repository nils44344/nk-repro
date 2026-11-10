#!/usr/bin/env bash
# Prisma 6: when does `new PrismaClient()` fail after an install, and what a closed database port returns.
# Usage: W=<work dir> NPM12=12.2.2 bash prisma6-noinit/run.sh      (no database and no account needed)
set +e
SRC=$(cd "$(dirname "$0")" && pwd)
W=${W:-$SRC/../.work-prisma6}; rm -rf "$W"; mkdir -p "$W/p"; W=$(cd "$W" && pwd)
NPM12=${NPM12:-12.2.2}
cp -r "$SRC/app.cjs" "$SRC/rt.cjs" "$SRC/package.json" "$SRC/package-lock.json" "$SRC/prisma" "$W/p/"; cd "$W/p"
export DATABASE_URL=postgresql://u:p@localhost:5433/db
strip() { sed 's/\x1b\[[0-9;]*m//g'; }
app() { node app.cjs 2>&1 | strip | grep -E "^constructed|did not initialize yet|Cannot find module" | head -1 | cut -c1-160; }
gen() { echo "files in node_modules/.prisma/client: $(ls node_modules/.prisma/client 2>/dev/null | wc -l | tr -d ' ')"; }
echo "== $(date -u) $(uname -s) node $(node -v) npm $(npm -v)"

echo "######## 1: npm ci, install scripts on"
npm ci --no-audit --no-fund 2>&1 | strip | grep -E "^added|npm error|npm warn install-scripts" | sed -E 's/ in [0-9]+(ms|s|m)$//' | cut -c1-160
npm ls prisma @prisma/client 2>/dev/null | grep -E "prisma@|client@" | sed 's/^[^a-z@]*//'
gen; echo "node app.cjs -> $(app)"
echo "-- npx prisma generate"; npx prisma generate 2>&1 | strip | grep -E "Generated Prisma Client|Error" | sed -E 's/ in [0-9]+(ms|s)$//; s/ to .*//' | head -2
gen; echo "node app.cjs -> $(app)"

echo "######## 2: npm ci --ignore-scripts"
rm -rf node_modules; npm ci --ignore-scripts --no-audit --no-fund 2>&1 | strip | grep -E "^added|npm error" | sed -E 's/ in [0-9]+(ms|s|m)$//'
gen; echo "node app.cjs -> $(app)"
echo "-- npx prisma generate"; npx prisma generate 2>&1 | strip | grep -E "Generated Prisma Client|Error" | sed -E 's/ in [0-9]+(ms|s)$//; s/ to .*//' | head -2
echo "node app.cjs -> $(app)"

echo "######## 3: a closed port (nothing listens on localhost:5433), client generated"
node rt.cjs 2>&1 | strip | cut -c1-240

echo "######## 4: npm $NPM12 ci, default settings"
mkdir -p "$W/npm12" && (cd "$W/npm12" && echo '{"name":"holder","version":"1.0.0"}' > package.json && npm install npm@$NPM12 --no-audit --no-fund --loglevel=error >/dev/null 2>&1)
CLI="$W/npm12/node_modules/npm/bin/npm-cli.js"; echo "npm $(node "$CLI" -v)"
rm -rf node_modules; node "$CLI" ci --no-audit --no-fund 2>&1 | strip | grep -E "^added|npm error|npm warn install-scripts" | sed -E 's/ in [0-9]+(ms|s|m)$//' | cut -c1-200
gen; echo "node app.cjs -> $(app)"
echo "-- with allowScripts for @prisma/client, @prisma/engines and prisma in package.json"
node -e 'const fs=require("fs");const p=JSON.parse(fs.readFileSync("package.json","utf8"));p.allowScripts={"@prisma/client":true,"@prisma/engines":true,"prisma":true};fs.writeFileSync("package.json",JSON.stringify(p,null,2))'
rm -rf node_modules; node "$CLI" ci --no-audit --no-fund 2>&1 | strip | grep -E "^added|npm error|npm warn install-scripts" | sed -E 's/ in [0-9]+(ms|s|m)$//' | cut -c1-200
gen; echo "node app.cjs -> $(app)"
echo "== done"
