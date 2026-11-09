#!/usr/bin/env bash
# Runs px.py in one venv per package combination (the table in README.md). No real API calls.
# Usage: W=<work dir> bash proxies/run.sh
set +e
HERE=$(cd "$(dirname "$0")" && pwd); W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
PY=${PY:-python}
echo "== $(date -u) $(uname -s) $($PY --version 2>&1)"
combo() {
  n=$1; shift; echo "######## $n: $*"
  $PY -m venv "$n"; B=$n/bin; [ -d "$n/Scripts" ] && B=$n/Scripts
  $B/python -m pip install -q --disable-pip-version-check "$@" 2>&1 | grep -iE "error|conflict" | head -3
  $B/python -I "$HERE/px.py" 2>&1
}
combo px1.40.0 openai==1.40.0 httpx==0.28.1
combo px1.55.2 openai==1.55.2 httpx==0.28.1
combo phx27 openai==1.55.2 httpx==0.27.2
combo px1.55.3 openai==1.55.3 httpx==0.28.1
combo pa0.39.0 anthropic==0.39.0 httpx==0.28.1
combo pa0.40.0 anthropic==0.40.0 httpx==0.28.1
combo voai openai==3.37.0
combo pxnew openai==3.37.0 httpx==0.28.1
echo "== done"
