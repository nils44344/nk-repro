#!/usr/bin/env bash
# "JavaScript heap out of memory": default limits, what --max-old-space-size reaches, and NODE_OPTIONS in npm scripts.
cd "$(dirname "$0")"
echo "== node $(node -v), $(uname -s), RAM $(node -p 'Math.round(require("os").totalmem()/2**30)') GB"
echo "== 1. default limits"; node limit.js
echo "== 2. grow to 600 MB with --max-old-space-size=256 (expect the crash)"
node --max-old-space-size=256 grow.js 2>&1 | grep -E "FATAL ERROR|reached" ; echo "exit: ${PIPESTATUS[0]}"
echo "== 3. same with --max-old-space-size=1024"; node --max-old-space-size=1024 grow.js 2>&1 | grep -E "FATAL ERROR|reached"
echo "== 4. flag on the command line: parent vs child"; node --max-old-space-size=1024 limit.js
echo "== 5. NODE_OPTIONS: parent vs child"; NODE_OPTIONS=--max-old-space-size=1024 node limit.js
echo "== 6. asked vs got"; for n in 256 1024 4096 100000; do echo "asked $n -> $(node --max-old-space-size=$n -p 'Math.round(require("v8").getHeapStatistics().heap_size_limit/2**20)') MB"; done
echo "== 7. npm script with Linux-style NODE_OPTIONS=..."; npm install --silent --no-audit --no-fund >/dev/null 2>&1; npm run -s limit-linux-syntax 2>&1 | tail -3
echo "== 8. npm script with cross-env"; npm run -s limit-cross-env 2>&1 | tail -3
