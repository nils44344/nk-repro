#!/bin/bash
# "The uploaded script has no registered event handlers": each way of writing the handler, under wrangler dev
# (local workerd) and, with DEPLOY=1, deployed to one test Worker on workers.dev.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
echo "== $(date) node $(node -v)"
[ -f package.json ] || { npm init -y >/dev/null; npm pkg set type=module; npm install -D wrangler@4 hono --no-audit --no-fund --loglevel=error 2>&1 | tail -1; }
npx wrangler --version 2>&1 | tail -1
NAME=${NAME:-nk-repro-cpu}
case_() { # $1 label, $2 file body
  printf '%s\n' "$2" > src.js
  printf '{ "name": "%s", "main": "src.js", "compatibility_date": "2026-09-01", "workers_dev": true }\n' "$NAME" > wrangler.jsonc
  echo; echo "######## $1"
  (npx wrangler dev --port 8799 > dev.log 2>&1 &); sleep 20
  echo "dev: HTTP $(curl -s -m 20 -o body.txt -w '%{http_code}' http://localhost:8799/) body: $(head -c 60 body.txt | tr '\n' ' ')"
  sed 's/\x1b\[[0-9;]*m//g' dev.log | grep -aiE "error|handler|warn|10021|10068" | grep -v "update available" | head -4 | cut -c1-200
  if command -v powershell >/dev/null; then powershell -NoProfile -c 'Get-NetTCPConnection -LocalPort 8799 -State Listen -EA 0 | % { Stop-Process -Id $_.OwningProcess -Force }'; else pkill -f "wrangler dev" ; pkill -f workerd; fi; sleep 3
  if [ "$DEPLOY" = 1 ]; then
    npx wrangler deploy 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -aE "Uploaded|Deployed|ERROR|code:|registered|does nothing" | head -4 | cut -c1-200
  fi
}
case_ "default export object (the fix)" 'export default { async fetch() { return new Response("hello"); } };'
case_ "named export fetch" 'export async function fetch() { return new Response("hello"); }'
case_ "default export is a plain function" 'export default async function (request) { return new Response("hello"); }'
case_ "CommonJS module.exports" 'module.exports = { async fetch() { return new Response("hello"); } };'
case_ "Hono: export default app" 'import { Hono } from "hono"; const app = new Hono(); app.get("/", (c) => c.text("hello")); export default app;'
case_ "Hono: export default { fetch: app.fetch }" 'import { Hono } from "hono"; const app = new Hono(); app.get("/", (c) => c.text("hello")); export default { fetch: app.fetch };'
case_ "addEventListener misspelled" 'addEventListener("fecth", (e) => e.respondWith(new Response("hello")));'
echo "== done $(date)"
