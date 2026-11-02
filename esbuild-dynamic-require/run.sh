#!/bin/bash
# esbuild "Dynamic require of X is not supported": ESM bundles of CommonJS code, the three fixes, --external,
# and the Workers case under wrangler dev (local workerd; nothing is deployed).
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
npm init -y >/dev/null; npm pkg set type=module; npm install esbuild fs-extra react wrangler@4 $Q 2>&1 | tail -1
v() { node -p "require('./node_modules/$1/package.json').version"; }
echo "== $(date) node $(node -v) esbuild $(v esbuild) fs-extra $(v fs-extra) react $(v react) wrangler $(v wrangler)"
mkdir -p src; echo 'const fs = require("fs"); module.exports = () => typeof fs.readFileSync;' > src/local.cjs
echo 'import f from "./local.cjs"; import fse from "fs-extra"; console.log("local:", f(), "fs-extra:", typeof fse.pathExists);' > src/index.mjs
r() { node "$1" 2>&1 | grep -aE "Dynamic require|local:|react " | head -1 | cut -c1-140; }
B='--bundle --platform=node'
echo "-- ESM output, no fix"; npx esbuild src/index.mjs $B --format=esm --outfile=dist/a.mjs --log-level=error; r dist/a.mjs
echo "-- fix 1: --format=cjs"; npx esbuild src/index.mjs $B --format=cjs --outfile=dist/b.cjs --log-level=error; r dist/b.cjs
echo "-- fix 2: createRequire banner"; npx esbuild src/index.mjs $B --format=esm --outfile=dist/c.mjs --log-level=error --banner:js="import { createRequire } from 'module'; const require = createRequire(import.meta.url);"; r dist/c.mjs
echo "-- fix 3: --packages=external"; npx esbuild src/index.mjs $B --format=esm --packages=external --outfile=dist/d.mjs --log-level=error; r dist/d.mjs
echo 'import fse from "fs-extra"; console.log("fs-extra:", typeof fse.pathExists);' > src/pkg.mjs
echo "-- fs-extra only, --packages=external"; npx esbuild src/pkg.mjs $B --format=esm --packages=external --outfile=dist/e.mjs --log-level=error; node dist/e.mjs 2>&1 | head -1
echo 'const React = require("react"); console.log("react " + React.version);' > src/r.cjs; echo 'import "./r.cjs";' > src/r.mjs
echo "-- --external:react"; npx esbuild src/r.mjs $B --format=esm --external:react --outfile=dist/f.mjs --log-level=error; r dist/f.mjs
echo "-- without the external"; npx esbuild src/r.mjs $B --format=esm --outfile=dist/g.mjs --log-level=error; r dist/g.mjs
echo "-- external + banner"; npx esbuild src/r.mjs $B --format=esm --external:react --outfile=dist/h.mjs --log-level=error --banner:js="import { createRequire } from 'module'; const require = createRequire(import.meta.url);"; r dist/h.mjs
echo "-- no --platform"; npx esbuild src/index.mjs --bundle --format=esm --outfile=dist/i.mjs 2>&1 | grep -aE 'Could not resolve|bundle for node' | head -2 | cut -c1-140
echo "######## Workers, under wrangler dev"
wk() { # $1 label, $2 require expression, $3 compat flags json
  rm -rf wk && mkdir -p wk/node_modules/dep && cd wk
  echo '{"name":"dep","version":"1.0.0","main":"index.js"}' > node_modules/dep/package.json
  echo "module.exports = () => { const m = $2; return typeof m; };" > node_modules/dep/index.js
  echo 'import dep from "dep"; export default { fetch() { return new Response("ok " + dep()); } };' > index.js
  printf '{ "name": "nk-dynreq", "main": "index.js", "compatibility_date": "2026-09-01", "compatibility_flags": %s }\n' "$3" > wrangler.jsonc
  (../node_modules/.bin/wrangler dev --port 8790 > dev.log 2>&1 &); sleep 15
  echo "-- $1: HTTP $(curl -s -m 15 -o body.txt -w '%{http_code}' http://localhost:8790/) $(head -c 80 body.txt | tr '\n' ' ') $(grep -aoE 'Dynamic require of "[^"]+" is not supported' dev.log | head -1)"
  pkill -f "wrangler dev --port 8790"; pkill -f workerd; sleep 2; cd ..
}
wk "require('fs') nodejs_compat" "require('fs')" '["nodejs_compat"]'
wk "require('fs') no compat" "require('fs')" '[]'
wk "require('node:crypto') nodejs_compat" "require('node:crypto')" '["nodejs_compat"]'
wk "require('buffer') nodejs_compat" "require('buffer')" '["nodejs_compat"]'
wk "require(name) nodejs_compat" "(n => require(n))('pa' + 'th')" '["nodejs_compat"]'
wk "require('path') literal, nodejs_compat" "require('path')" '["nodejs_compat"]'
echo "== done"
