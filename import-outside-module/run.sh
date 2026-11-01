#!/bin/bash
# "Cannot use import statement outside a module": Node by "type" and extension, node -e, Jest 30, and TypeScript output.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v) npm $(npm -v)"
f() { grep -aE "SyntaxError|Cannot use import|Warning|Error|^ok|PASS|FAIL|Tests:|MODULE_TYPELESS|ERR_" | grep -v "^\s*at " | head -${1:-2} | cut -c1-200; }
echo "######## node, by package.json type and extension"
for T in none commonjs module; do
  rm -rf n$T; mkdir n$T && cd n$T
  if [ $T = none ]; then echo '{}' > package.json; else echo "{\"type\":\"$T\"}" > package.json; fi
  for E in js cjs mjs; do echo "import { sep } from 'node:path'; console.log('ok', sep);" > app.$E; echo "-- type=$T app.$E"; node app.$E 2>&1 | f 2; done
  cd ..
done
echo "-- node -e with import"; node -e "import { sep } from 'node:path'; console.log('ok', sep)" 2>&1 | f 2
echo "-- node --input-type=module -e"; node --input-type=module -e "import { sep } from 'node:path'; console.log('ok', sep)" 2>&1 | f 2

echo "######## Jest 30, test file uses import"
rm -rf j && mkdir j && cd j && echo '{"type":"commonjs"}' > package.json
npm install -D jest@30 babel-jest @babel/core @babel/preset-env $Q 2>&1 | tail -1
echo "export const add = (a, b) => a + b;" > sum.js
echo "import { add } from './sum.js'; test('add', () => { expect(add(1, 2)).toBe(3); });" > sum.test.js
echo "-- no config"; npx jest 2>&1 | f 3
echo '{ "presets": [["@babel/preset-env", { "targets": { "node": "current" } }]] }' > babel.config.json
echo "-- with babel.config.json preset-env"; npx jest 2>&1 | f 3
rm babel.config.json; npm pkg set type=module
echo "-- type=module, no babel, plain"; npx jest 2>&1 | f 3
echo "-- type=module, NODE_OPTIONS=--experimental-vm-modules"; NODE_OPTIONS=--experimental-vm-modules npx jest 2>&1 | f 3
cd ..

echo "######## TypeScript emits import into a CommonJS package"
rm -rf t && mkdir t && cd t && echo '{"type":"commonjs"}' > package.json
npm install -D typescript@6 @types/node $Q 2>&1 | tail -1; echo "tsc $(npx tsc -v)"
mkdir -p src && echo "import { sep } from 'node:path'; console.log('ok', sep);" > src/index.ts
for M in esnext nodenext commonjs; do
  printf '{ "compilerOptions": { "module": "%s", "moduleResolution": "%s", "target": "es2022", "outDir": "dist", "types": ["node"] } }\n' $M $([ $M = nodenext ] && echo nodenext || echo bundler) > tsconfig.json
  [ $M = commonjs ] && sed -i 's/"bundler"/"node10"/' tsconfig.json
  rm -rf dist; npx tsc 2>&1 | head -2 | cut -c1-160
  echo "-- module=$M emits: $(head -c 50 dist/index.js | tr '\n' ' ')"; node dist/index.js 2>&1 | f 2
done
cd ..
echo "== done"
