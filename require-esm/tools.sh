#!/bin/bash
# ERR_REQUIRE_ESM (8 Nov 2026): (1) the exact Node 20 release where require(esm) starts working,
# (2) whether test runners and loaders still throw it on the current Node: Jest 30 (CommonJS test), tsx.
set +e
W=${W:-$(pwd)/work-tools}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
npm init -y >/dev/null; npm i chalk@5.6.2 jest@30 tsx $Q >/dev/null 2>&1
echo 'const chalk = require("chalk"); console.log("loaded, default.green is", typeof (chalk.default ?? chalk).green);' > a.cjs
echo "== $(date -u +%F) host node $(node -v)"
echo "### 1. Node 20 boundary"
for v in 20.17.0 20.18.3 20.19.0 20.19.5 20.20.2; do
  npx -y node@$v a.cjs > o.txt 2>&1; e=$?
  printf '%-8s | exit %s | %s\n' "$v" "$e" "$(grep -m1 -oE 'ERR_REQUIRE_ESM|loaded, default.green is [a-z]+|ExperimentalWarning[^.]*' o.txt)"
done
echo "### 2. tools on host node $(node -v)"
mkdir -p t && echo 'const chalk = require("chalk"); test("x", () => { expect(typeof (chalk.default ?? chalk).green).toBe("function"); });' > t/a.test.cjs
npx jest --testMatch '**/t/*.test.cjs' > j.txt 2>&1; echo "jest $(npx jest --version) (CommonJS test requiring chalk 5): exit $? | $(grep -m1 -oE 'ERR_REQUIRE_ESM|Must use import[^:]*|Tests: +[0-9]+ (passed|failed)[^,]*|SyntaxError[^\n]{0,60}' j.txt)"
echo 'const chalk = require("chalk"); console.log("tsx loaded", typeof (chalk.default ?? chalk).green);' > b.cts
npx tsx b.cts > x.txt 2>&1; echo "tsx $(npx tsx --version | head -1 | awk '{print $NF}') (.cts requiring chalk 5): exit $? | $(grep -m1 -oE 'ERR_REQUIRE_ESM|tsx loaded [a-z]+' x.txt)"
echo "== done"
