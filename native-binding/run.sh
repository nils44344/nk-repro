#!/bin/bash
# Which packages throw "Cannot find native binding" when their platform package is missing? (Windows x64, 29 Oct 2026)
export NODE_EXTRA_CA_CERTS=D:/tools/ca-bundle-win.pem
cd D:/nk-natb; rm -rf p; mkdir p; cd p; npm init -y >/dev/null
PKGS="rolldown @tailwindcss/oxide lightningcss @rspack/core oxc-parser @swc/core @parcel/watcher esbuild @biomejs/biome"
npm install $PKGS --no-audit --no-fund --loglevel=error 2>&1 | tail -1
node -v; npm -v
for p in $PKGS; do echo "== $p $(node -p "require('$p/package.json').version")"; done
echo "== platform packages present:"; ls -d node_modules/@*/*win32* node_modules/*win32* 2>/dev/null
for d in node_modules/@*/*win32* node_modules/*win32*; do mv "$d" "$d.off"; done
probe() { echo "-- $1"; node -e "try{require('$1')}catch(e){console.log(String(e.message).split('\n').slice(0,2).join(' / ')); if(e.cause) console.log('cause:', String(e.cause.message||e.cause).split('\n')[0])}" 2>&1 | head -3; }
for p in rolldown @tailwindcss/oxide lightningcss @rspack/core oxc-parser @swc/core @parcel/watcher esbuild; do probe $p; done
echo "-- biome"; npx biome --version 2>&1 | head -2
echo "== fix: npm install again"
for d in node_modules/@*/*win32*.off node_modules/*win32*.off; do rm -rf "${d%.off}" 2>/dev/null; done
rm -rf node_modules/@*/*win32*.off node_modules/*win32*.off
npm install --no-audit --no-fund --loglevel=error 2>&1 | tail -1
for p in rolldown @tailwindcss/oxide lightningcss @rspack/core oxc-parser @swc/core; do probe $p; done
echo "(blank '--' lines above = loaded fine)"
