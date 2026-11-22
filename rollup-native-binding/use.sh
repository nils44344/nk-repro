#!/bin/bash
# Job 2 (ubuntu-latest): "Cannot find module @rollup/rollup-<platform>": which setups give it, and which fixes work.
# Expects the packs of job 1 in $IN/<os>/ (package.json, package-lock.json, main.js, node_modules.tgz).
set +e
IN=${IN:-$PWD/packs}; W=${W:-$PWD/work}; mkdir -p "$W"
Q="--no-audit --no-fund"
echo "== $(uname -s) $(uname -m) | node $(node -v) | npm $(npm -v) | $(ldd --version 2>&1 | head -1)"
b() { npm run build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -aE "created|Cannot find module|npm has a bug|Error" | grep -v "^npm error" | head -3 | cut -c1-260; echo "exit ${PIPESTATUS[0]}"; }
fresh() { cd "$W" && sudo rm -rf "$W/c" && mkdir -p "$W/c" && cp "$IN/$1"/package.json "$IN/$1"/package-lock.json "$IN/$1"/main.js "$W/c/" && cd "$W/c"; }
run() { echo; echo "\$ $*"; ( eval "$@" ) 2>&1 | grep -E "added|up to date|ERR|error" | grep -v "^npm warn" | head -3; echo "exit ${PIPESTATUS[0]}"; }

for os in windows macos ubuntu; do
  echo; echo "### A-$os. npm ci on Linux with the lockfile made on $os"
  fresh $os; echo "lockfile rollup-* entries: $(grep -c '"node_modules/@rollup/rollup-' package-lock.json); linux-x64-gnu entry: $(grep -c '"node_modules/@rollup/rollup-linux-x64-gnu"' package-lock.json)"
  run npm ci $Q; echo "installed: $(ls node_modules/@rollup | tr '\n' ' ')"; b
done

for os in windows macos; do
  echo; echo "### B-$os. node_modules copied from $os, run on Linux"
  fresh $os; tar xzf "$IN/$os/node_modules.tgz"; echo "installed: $(ls node_modules/@rollup | tr '\n' ' ')"; b
  echo "-- fix: npm ci (lockfile kept)"; run npm ci $Q; b
done

echo; echo "### C. --omit=optional"
fresh ubuntu; run npm ci --omit=optional $Q; echo "installed: $(ls node_modules/@rollup | tr '\n' ' ')"; b
echo "-- fix: npm ci"; run npm ci $Q; b

echo; echo "### D. omit=optional in .npmrc"
fresh ubuntu; echo "omit=optional" > .npmrc; run npm ci $Q; b
echo "-- fix: --include=optional"; run npm ci --include=optional $Q; b

echo; echo "### E. platform folder deleted, then fixes"
fresh ubuntu; npm ci $Q >/dev/null 2>&1; rm -rf node_modules/@rollup/rollup-linux-x64-gnu; b
echo "-- npm i (lockfile and node_modules kept)"; run npm i $Q; b
echo "-- npm rebuild"; rm -rf node_modules/@rollup/rollup-linux-x64-gnu; run npm rebuild $Q; b
echo "-- rm -rf node_modules package-lock.json && npm i"; run "rm -rf node_modules package-lock.json && npm i $Q"; b

echo; echo "### F. Alpine (musl) container"
fresh ubuntu; DK="docker run --rm -v $W/c:/app -w /app node:24-alpine"
echo "-- F1 npm ci inside Alpine with the Linux (glibc) lockfile"; $DK sh -c "npm ci $Q >/dev/null 2>&1; ls node_modules/@rollup; npm run build 2>&1 | grep -aE 'created|Cannot find module|npm has a bug' | head -3 | cut -c1-260"
echo "-- F2 node_modules installed on the glibc host, run inside Alpine (bind mount)"; sudo rm -rf node_modules; npm ci $Q >/dev/null 2>&1; echo "host installed: $(ls node_modules/@rollup | tr '\n' ' ')"
$DK sh -c "npm run build 2>&1 | grep -aE 'created|Cannot find module|npm has a bug' | head -3 | cut -c1-260"
echo "-- F3 same, with an anonymous volume for node_modules and npm ci inside"
docker run --rm -v $W/c:/app -v /app/node_modules -w /app node:24-alpine sh -c "npm ci $Q >/dev/null 2>&1; ls node_modules/@rollup; npm run build 2>&1 | grep -aE 'created|Cannot find module' | head -2 | cut -c1-200"
echo; echo "== done"
