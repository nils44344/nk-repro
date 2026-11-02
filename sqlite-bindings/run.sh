#!/bin/bash
# "Could not locate the bindings file" (sqlite3, better-sqlite3): install scripts skipped (--ignore-scripts, npm 12),
# a bundler packing the native module, and switching Node versions. Node 26 runs via the "node" npm package.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
N26="npx -y node@26"
echo "== $(date) node $(node -v) npm $(npm -v), node26: $($N26 -v 2>/dev/null | tail -1)"
q() { $1 "$2" 2>&1 | grep -aE "^ok|Could not locate|Cannot find module|NODE_MODULE_VERSION [0-9]+|Error:" | head -2 | sed 's/compiled against.*using/... using/' | cut -c1-180; }
echo 'const s=require("sqlite3"); const d=new s.Database(":memory:"); d.get("select 1 as x",(e,r)=>console.log(e?e.message:"ok "+r.x));' > s.cjs
echo 'const D=require("better-sqlite3"); console.log("ok "+new D(":memory:").prepare("select 1 as x").get().x);' > b.cjs
p() { rm -rf $1; mkdir $1 && cd $1 && npm init -y >/dev/null; cp ../s.cjs ../b.cjs .; }
echo "######## 1. scripts skipped"
p a; npm install sqlite3 --ignore-scripts $Q 2>&1 | tail -1; echo "sqlite3 $(node -p 'require("./node_modules/sqlite3/package.json").version')"
echo "-- sqlite3 --ignore-scripts"; q node s.cjs
npm rebuild sqlite3 $Q >/dev/null 2>&1; echo "-- after npm rebuild sqlite3 (node 24)"; q node s.cjs; echo "-- same build on node 26"; q "$N26" s.cjs; cd ..
p n12; npx -y npm@12 install sqlite3 $Q 2>&1 | grep -E "install-scripts   sqlite3" | head -1 | cut -c1-150; echo "-- npm 12 default"; q node s.cjs
npx -y npm@12 install-scripts approve sqlite3 >/dev/null 2>&1; npx -y npm@12 rebuild $Q >/dev/null 2>&1; echo "-- after install-scripts approve + rebuild"; q node s.cjs; cd ..
for V in 12 13; do p b$V; npm install better-sqlite3@$V --ignore-scripts $Q 2>&1 | tail -1; echo "-- better-sqlite3 $(node -p 'require("./node_modules/better-sqlite3/package.json").version') --ignore-scripts: node24"; q node b.cjs; echo "   node26"; q "$N26" b.cjs; cd ..; done
echo "######## 2. bundled with esbuild"
for V in 12 13; do p e$V; npm install better-sqlite3@$V esbuild $Q 2>&1 | tail -1
  npx esbuild b.cjs --bundle --platform=node --outfile=dist/out.cjs --log-level=error; echo "-- better-sqlite3 $V bundled"; q node dist/out.cjs
  npx esbuild b.cjs --bundle --platform=node --outfile=dist/ext.cjs --external:better-sqlite3 --log-level=error; echo "-- with --external:better-sqlite3"; q node dist/ext.cjs; cd ..; done
echo "######## 3. switching Node"
p sw; npm install better-sqlite3@12 $Q 2>&1 | tail -1; echo "-- built on node 24, run on 26"; q "$N26" b.cjs
$N26 $(dirname $(which npm))/../lib/node_modules/npm/bin/npm-cli.js rebuild better-sqlite3 $Q >/dev/null 2>&1; echo "-- rebuilt under node 26: node26"; q "$N26" b.cjs; echo "   node24"; q node b.cjs
cd ..; p bs13; npm install better-sqlite3@13 $Q 2>&1 | tail -1; echo "-- better-sqlite3 13 installed on 24: node24"; q node b.cjs; echo "   node26"; q "$N26" b.cjs
echo "== done"
