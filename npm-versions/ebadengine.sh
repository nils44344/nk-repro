#!/bin/bash
# npm EBADENGINE: when it warns, when npm quietly picks an older major, engine-strict, and the edgesOut crash.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund"; echo "== $(date -u) node $(node -v) npm $(npm -v)"
e() { grep -aE "EBADENGINE|code E[A-Z]+|Cannot read properties[^\n]*|notsup Required[^\n]*" | head -2 | tr '\n' ' ' | cut -c1-160; }
t() { rm -rf p && mkdir p && cd p && npm init -y >/dev/null; [ -n "$3" ] && echo "engine-strict=true" > .npmrc
  out=$(npm install $2 $Q 2>&1); got=$(node -p "try{require('./node_modules/$1/package.json').version}catch{'not installed'}")
  echo "-- npm install $2${3:+ (engine-strict)}: $(echo "$out" | e)${out:+ } -> $1 $got"; cd $W; }
t react-router react-router@8; t react-router react-router; t vite vite; t vite vite@8; t react-router react-router@8 strict
echo "   engines: react-router@8 $(npm view react-router@8 engines.node 2>/dev/null | tail -1), vite@8 $(npm view vite@8 engines.node 2>/dev/null | tail -1)"
echo "== done"
