#!/usr/bin/env bash
# Runs the local-server scripts on the Python SDK 1.17.0 and 2.1.0 and the TypeScript SDK 0.137.0 and 1.1.0.
# No real API calls and no key. (version-bridge-nov8.sh is separate: it calls the real API.)
# Usage: W=<work dir> bash anthropic-sdk2/run.sh
set +e
HERE=$(cd "$(dirname "$0")" && pwd); W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
PY=${PY:-python}
echo "== $(date -u) $(uname -s) $($PY --version 2>&1) node $(node -v)"
for v in 1.17.0 2.1.0; do
  echo "######## python anthropic==$v"
  $PY -m venv "py$v"; B=py$v/bin; [ -d "py$v/Scripts" ] && B=py$v/Scripts
  $B/python -m pip install -q --disable-pip-version-check "anthropic==$v" 2>&1 | grep -iE "error|conflict" | head -3
  for s in calls headers betas; do echo "== $s.py"; $B/python "$HERE/$s.py" 2>&1; done
done
for v in 0.137.0 1.1.0; do
  echo "######## @anthropic-ai/sdk@$v"
  mkdir -p "ts$v"; cd "ts$v" || exit 1
  cp "$HERE/calls.ts" t.ts; cp "$HERE/tsconfig.json" .
  npm init -y >/dev/null; npm pkg set type=module >/dev/null
  npm i "@anthropic-ai/sdk@$v" typescript@5 tsx --no-audit --no-fund --loglevel=error 2>&1 | tail -1
  echo "== tsc -p ."; npx tsc -p . 2>&1 | head -20
  echo "== tsx t.ts"; npx tsx t.ts 2>&1 | head -40
  cd ..
done
echo "== done"
