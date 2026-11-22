#!/bin/bash
# Job 1 (each OS): a minimal Rollup 4 project, npm install, one build; pack lockfile + node_modules for job 2.
set +e
R=${ROLLUP:-4.68.8}; OUT=${OUT:-$PWD/pack}; OS=${OS_NAME:-$(uname -s)}
mkdir -p "$OUT" p && cd p || exit 1
cat > package.json <<J
{ "name": "rollup-nb", "private": true, "type": "module", "scripts": { "build": "rollup main.js --file out.js" }, "devDependencies": { "rollup": "$R" } }
J
echo 'export const x = 1;' > main.js
echo "== $OS $(uname -m) | node $(node -v) | npm $(npm -v) | rollup $R"
npm install --no-audit --no-fund 2>&1 | tail -1
echo "native packages installed: $(ls node_modules/@rollup | tr '\n' ' ')"
echo "rollup-* entries in package-lock.json: $(grep -c '"node_modules/@rollup/rollup-' package-lock.json)"
npm run build 2>&1 | grep -E "created|Error|Cannot" | head -2; echo "exit ${PIPESTATUS[0]}"
cp package.json package-lock.json main.js "$OUT/"
tar czf "$OUT/node_modules.tgz" node_modules
