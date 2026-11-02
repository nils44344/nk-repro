#!/bin/bash
# Astro + TS 7 side-by-side: current versions vs the ones in the post (astro 7.3.5, @astrojs/check 0.9.10).
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"; export CI=1 ASTRO_TELEMETRY_DISABLED=1
for SET in "astro@latest @astrojs/check@latest" "astro@7.3.5 @astrojs/check@0.9.10"; do
  D=$(echo $SET | tr ' @/' '___'); rm -rf $D; mkdir $D && cd $D && npm init -y >/dev/null && npm pkg set type=module
  mkdir -p src/pages && echo '---
const n: number = 1;
---
<p>{n}</p>' > src/pages/index.astro; echo '{ "extends": "astro/tsconfigs/strict" }' > tsconfig.json
  npm install $SET "@typescript/native@npm:typescript@7" "typescript@npm:@typescript/typescript6@^6.0.2" --legacy-peer-deps $Q 2>&1 | tail -1
  echo "######## $SET -> astro $(node -p 'require("./node_modules/astro/package.json").version') check $(node -p 'require("./node_modules/@astrojs/check/package.json").version')"
  node -e 'try{console.log("   require.resolve typescript:", require.resolve("typescript"))}catch(e){console.log("   resolve error:", e.message.slice(0,120))}'
  node --input-type=module -e 'import("typescript").then(m=>console.log("   import typescript version:", m.version ?? m.default?.version)).catch(e=>console.log("   import error:", e.message.slice(0,140)))'
  node --input-type=module -e 'import("@astrojs/check").then(()=>console.log("   import @astrojs/check ok")).catch(e=>console.log("   import @astrojs/check error:", e.message.slice(0,200)))'
  npx astro check 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -aE "error|required|0 errors|Result" | head -3 | cut -c1-200
  cd ..
done
