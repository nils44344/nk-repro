#!/bin/bash
# import.meta.dirname is the fix for "__dirname is not defined in ES module scope". Where does that fix break?
# The same two-line file through the tools people run it with (8 Nov 2026).
set +e
W=${W:-$(pwd)/work-tools}; rm -rf "$W"; mkdir -p "$W/src"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
npm init -y >/dev/null; npm pkg set type=module
npm i -D esbuild tsx typescript jest vitest @types/node $Q >/dev/null 2>&1
curl -fsSL https://bun.sh/install | bash >/dev/null 2>&1; export PATH=$HOME/.bun/bin:$PATH
curl -fsSL https://deno.land/install.sh | sh -s -- -y >/dev/null 2>&1; export PATH=$HOME/.deno/bin:$PATH
echo "== $(date -u +%F) node $(node -v) esbuild $(npx esbuild --version) tsx $(npx tsx --version | head -1 | awk '{print $NF}') typescript $(npx tsc -v | awk '{print $2}') jest $(npx jest --version) vitest $(npx vitest --version | awk '{print $NF}') bun $(bun --version 2>/dev/null) deno $(deno --version 2>/dev/null | head -1 | awk '{print $2}')"
echo 'export const where = () => import.meta.dirname;' > src/where.js
cp src/where.js src/where.ts
echo 'import { where } from "./where.js"; console.log("dirname =", where());' > src/main.js
echo 'import { where } from "./where.ts"; console.log("dirname =", where());' > src/main.ts
r(){ printf '%-44s | ' "$1"; shift; out=$("$@" 2>&1); echo "$out" | grep -E "dirname =|Error|error|warning|▲" | head -2 | cut -c1-120 | tr '\n' ' '; echo; }
r "node src/main.js" node src/main.js
r "node src/main.ts (type stripping)" node src/main.ts
r "tsx src/main.ts" npx tsx src/main.ts
r "bun src/main.ts" bun src/main.ts
r "deno run src/main.ts" deno run --allow-read src/main.ts
npx esbuild src/main.js --bundle --platform=node --format=esm --outfile=dist/esm.mjs --log-level=warning > esb1.log 2>&1
r "esbuild --format=esm, then node" node dist/esm.mjs
npx esbuild src/main.js --bundle --platform=node --format=cjs --outfile=dist/cjs.cjs --log-level=warning > esb2.log 2>&1
echo "   esbuild cjs build said: $(grep -m1 -E 'import.meta|▲|warning' esb2.log | cut -c1-110)"
r "esbuild --format=cjs, then node" node dist/cjs.cjs
printf '{"compilerOptions":{"module":"commonjs","target":"es2022","outDir":"tsc-cjs","types":["node"],"allowImportingTsExtensions":false},"files":["src/where.ts"]}' > tsconfig.cjs.json
r "tsc with module commonjs" npx tsc -p tsconfig.cjs.json
echo 'import { where } from "../src/where.js"; test("d", () => { console.log("dirname =", where()); });' > jest.test.js
mkdir -p t && mv jest.test.js t/
r "jest (default config)" npx jest t/jest.test.js
r "jest with --experimental-vm-modules" env NODE_OPTIONS=--experimental-vm-modules npx jest t/jest.test.js
echo 'import { test } from "vitest"; import { where } from "../src/where.js"; test("d", () => { console.log("dirname =", where()); });' > t/v.test.js
r "vitest run" npx vitest run t/v.test.js
echo "== done"
