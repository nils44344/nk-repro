#!/bin/bash
# npm 12 breaking changes, re-checked: install scripts blocked, git deps refused, unknown flags vs unknown .npmrc keys.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund"
npm install -g npm@${NPM:-12} $Q >/dev/null 2>&1
echo "== $(date) node $(node -v) npm $(npm -v)"
p() { mkdir -p $1 && cd $1 && npm init -y >/dev/null; }
echo "######## 1. install scripts"; p s
npm install esbuild $Q 2>&1 | grep -E "added|install-scripts" | head -3
echo "   esbuild binary runs: $(npx esbuild --version 2>&1 | head -1)"
npm install esbuild --allow-scripts=esbuild $Q 2>&1 | grep -E "EALLOW|error" | head -2
cd ..
echo "######## 2. git dependency"; p g
npm install github:sindresorhus/is-plain-obj $Q 2>&1 | grep -E "code|error" | head -3
cd ..
echo "######## 3. unknown flag"; p f
npm install is-number --foo-bar $Q 2>&1 | grep -E "code|error|added|warn" | head -3; echo "   exit ${PIPESTATUS[0]}"
echo "######## 3b. unknown .npmrc key"; echo "shamefully-hoist=true" > .npmrc
npm install is-odd $Q 2>&1 | grep -E "code|error|added|warn" | head -3; echo "   exit ${PIPESTATUS[0]}"
cd ..
echo "== done"
