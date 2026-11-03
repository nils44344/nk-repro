#!/bin/bash
# Moving a typical Deno Deploy app (Deno.serve, Deno.env, Deno KV, a jsr: import) to Node 26 and to Cloudflare Workers
# (wrangler dev only, nothing deployed). Each step's first error, and the migrated versions answering requests.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date -u) node $(node -v) $(deno --version | head -1)"
cat > deno.ts <<'T'
import { Hono } from "jsr:@hono/hono@4";
const kv = await Deno.openKv();
const app = new Hono();
app.get("/", (c) => c.text(`hello from ${Deno.env.get("APP_NAME") ?? "deno"}`));
app.get("/count", async (c) => { const cur = (await kv.get<number>(["visits"])).value ?? 0; await kv.set(["visits"], cur + 1); return c.json({ visits: cur + 1 }); });
Deno.serve({ port: 8787 }, app.fetch);
T
hit() { sleep ${1:-4}; echo "   / -> $(curl -s -m 10 localhost:8787/) | /count -> $(curl -s -m 10 localhost:8787/count) then $(curl -s -m 10 localhost:8787/count)"; }
echo "-- Deno, no flag"; timeout 15 deno run -A deno.ts 2>&1 | grep -aoE "Deno.openKv is not a function|error: [^\n]{0,80}" | head -1
echo "-- Deno --unstable-kv"; (APP_NAME=deno-baseline deno run -A --unstable-kv deno.ts > d.log 2>&1 &); hit 8; pkill -f "deno run"; sleep 1
mkdir -p node && cd node && npm init -y >/dev/null && npm pkg set type=module && cp ../deno.ts main.ts
echo "-- Node 26, unchanged"; timeout 15 node main.ts 2>&1 | grep -aoE "ERR_UNSUPPORTED_ESM_URL_SCHEME[^\n]{0,30}|Received protocol '[a-z]+:'" | head -2 | tr '\n' ' '; echo
echo "-- npx jsr add @hono/hono (no version)"; (mkdir -p ../nover && cd ../nover && npm init -y >/dev/null && npx -y jsr add @hono/hono >/dev/null 2>&1; echo "   installed: $(node -p 'require("./package.json").dependencies["@hono/hono"]') -> $(node -p 'require("./node_modules/@hono/hono/package.json").version' 2>/dev/null)")
npx -y jsr add @hono/hono@4 >/dev/null 2>&1; echo "-- npx jsr add @hono/hono@4: $(node -p 'require("./package.json").dependencies["@hono/hono"]') | .npmrc: $(cat .npmrc | tr '\n' ' ')"
sed -i 's|jsr:@hono/hono@4|@hono/hono|' main.ts; echo "-- Node 26, jsr import fixed"; timeout 15 node main.ts 2>&1 | grep -aoE "ReferenceError: [^\n]{0,40}" | head -1
npm i @hono/node-server @deno/kv $Q 2>&1 | tail -1
cat > main.ts <<'T'
import { Hono } from "@hono/hono";
import { serve } from "@hono/node-server";
import { openKv } from "@deno/kv";
const kv = await openKv("kv.sqlite");
const app = new Hono();
app.get("/", (c) => c.text(`hello from ${process.env.APP_NAME ?? "node"}`));
app.get("/count", async (c) => { const cur = (await kv.get<number>(["visits"])).value ?? 0; await kv.set(["visits"], cur + 1); return c.json({ visits: cur + 1 }); });
serve({ fetch: app.fetch, port: 8787 });
T
echo "-- Node 26, migrated"; (APP_NAME=node26 node main.ts > n.log 2>&1 &); hit 5; pkill -f "node main.ts"; sleep 1; grep -aiE "error" n.log | head -1
cd .. && mkdir -p wk && cd wk && npm init -y >/dev/null && npm pkg set type=module && npm i wrangler@4 $Q 2>&1 | tail -1 && cp ../deno.ts main.ts
printf '{ "name": "deno-app", "main": "main.ts", "compatibility_date": "2026-10-01", "vars": { "APP_NAME": "workers" }, "kv_namespaces": [{ "binding": "KV", "id": "local-dev-only" }] }\n' > wrangler.jsonc
echo "-- wrangler dev, unchanged"; timeout 40 npx wrangler dev --port 8787 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -aoE 'Could not resolve "jsr:[^"]+"|Top-level await is currently not supported[^\n]{0,40}' | sort -u | head -2
npx -y jsr add @hono/hono@4 >/dev/null 2>&1
cat > main.ts <<'T'
import { Hono } from "@hono/hono";
type Env = { APP_NAME?: string; KV: KVNamespace };
const app = new Hono<{ Bindings: Env }>();
app.get("/", (c) => c.text(`hello from ${c.env.APP_NAME ?? "workers"}`));
app.get("/count", async (c) => { const cur = Number((await c.env.KV.get("visits")) ?? 0); await c.env.KV.put("visits", String(cur + 1)); return c.json({ visits: cur + 1 }); });
export default app;
T
echo "-- wrangler dev, migrated $(npx wrangler --version 2>&1 | tail -1)"; (npx wrangler dev --port 8787 > w.log 2>&1 &); hit 20; pkill -f "wrangler dev"; pkill -f workerd
echo "== done"
