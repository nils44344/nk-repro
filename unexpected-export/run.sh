#!/bin/bash
# SyntaxError: Unexpected token 'export': Node's module detection by package.json "type", what npm init writes,
# Jest + an ESM-only dependency (nanoid 5) with each fix. Run once per Node version.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v) npm $(npm -v)"
f() { grep -aE "SyntaxError|Warning|Error|ok|PASS|FAIL|Tests:|Must use|ESM syntax|MODULE_TYPELESS" | grep -v "^\s*at " | head -${1:-3} | cut -c1-200; }

echo "######## node esm.js, by package.json type"
for T in commonjs none module; do
  rm -rf n$T; mkdir n$T && cd n$T
  if [ $T = none ]; then echo '{}' > package.json; else echo "{\"type\":\"$T\"}" > package.json; fi
  echo "export const a = 1; console.log('ok', a);" > esm.js
  echo "-- type=$T"; node esm.js 2>&1 | f 3
  cd ..
done
echo "-- export in a .cjs file"; echo "export const a = 1;" > n.cjs; node n.cjs 2>&1 | f 2
echo "-- export in a .mjs file under type=commonjs"; cp nnone/esm.js ncommonjs/esm.mjs; (cd ncommonjs && node esm.mjs 2>&1 | f 2)

echo "######## npm init -y writes"
for N in npm "npx -y npm@12"; do rm -rf i && mkdir i && cd i; $N init -y >/dev/null 2>&1; echo "-- npm $($N -v 2>/dev/null | tail -1): type=$(node -p 'require("./package.json").type')"; cd ..; done

echo "######## Jest 30 + nanoid 5 in a CommonJS project"
rm -rf j && mkdir j && cd j && echo '{"type":"commonjs","scripts":{"test":"jest"}}' > package.json
npm install -D jest@30 nanoid@5 babel-jest @babel/core @babel/preset-env $Q 2>&1 | tail -1
echo "versions: jest $(npx jest --version) nanoid $(node -p 'require("./node_modules/nanoid/package.json").version')"
echo "const { nanoid } = require('nanoid'); test('id', () => { expect(nanoid().length).toBe(21); });" > r.test.js
echo "-- require, plain jest"; npx jest r.test.js 2>&1 | f 4
echo "import { nanoid } from 'nanoid'; test('id', () => { expect(nanoid().length).toBe(21); });" > i.test.mjs
echo "-- import in .mjs test, plain jest"; npx jest --testMatch '**/*.test.mjs' 2>&1 | f 4
echo "-- import in .mjs test, NODE_OPTIONS=--experimental-vm-modules"; NODE_OPTIONS=--experimental-vm-modules npx jest --testMatch '**/*.test.mjs' 2>&1 | f 3
echo '{ "presets": [["@babel/preset-env", { "targets": { "node": "current" } }]] }' > babel.config.json
echo "module.exports = { transformIgnorePatterns: ['/node_modules/(?!nanoid)'] };" > jest.config.js
echo "-- require + babel-jest + transformIgnorePatterns '/node_modules/(?!nanoid)'"; npx jest r.test.js 2>&1 | f 4
rm jest.config.js; echo "-- same babel config, default transformIgnorePatterns"; npx jest r.test.js 2>&1 | f 3
cd ..
echo "== done"
