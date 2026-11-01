#!/bin/bash
# DEP0040 "The punycode module is deprecated": own code vs node_modules vs bundled, per Node version,
# and which popular packages print it once bundled with esbuild.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v)"
npm init -y >/dev/null; npm pkg delete type
npm install node-fetch@2 tough-cookie@4 psl ajv@6 whatwg-url@5 esbuild $Q 2>&1 | tail -1
w() { grep -aoE "DEP0[0-9]+[^.]*" | head -1; }
echo "-- own code: require('punycode')"; node -e "require('punycode')" 2>&1 | w || true; echo "   (end)"
for P in node-fetch tough-cookie psl ajv whatwg-url; do
  V=$(node -p "require('./node_modules/$P/package.json').version")
  echo "require('$P'); setTimeout(()=>{}, 50);" > t-$P.js
  U=$(node t-$P.js 2>&1 | w); npx esbuild t-$P.js --bundle --platform=node --log-level=error --outfile=dist/$P.js
  B=$(node dist/$P.js 2>&1 | w)
  echo "-- $P $V | unbundled: ${U:-none} | bundled: ${B:-none} | punycode refs in bundle: $(grep -c "require(\"punycode\")" dist/$P.js)"
done
echo "-- npm ls punycode"; npm ls punycode 2>&1 | head -8
echo "== done"
