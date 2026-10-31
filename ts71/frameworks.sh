#!/bin/bash
# TS 7.1: the framework checks that refused TypeScript 7.0 (Angular build, vue-tsc, svelte-check, astro check).
# Usage: TSV=7.1.0-beta bash frameworks.sh   (NestJS: see the frameworks post; it uses nest build)
export NODE_EXTRA_CA_CERTS=D:/tools/ca-bundle-win.pem
set +e
TSV=${TSV:-beta}; W=D:/nk-ts71/fw; rm -rf $W; mkdir -p $W; cd $W
I="--no-audit --no-fund --loglevel=error --legacy-peer-deps"
echo "== $(date) node $(node -v) typescript@$TSV"

echo; echo "######## vue-tsc"
mkdir vue && cd vue && npm init -y >/dev/null
npm install -D vue vue-tsc typescript@$TSV $I 2>&1 | tail -2; npx tsc --version; npm ls vue-tsc vue 2>&1 | grep -E "vue"
mkdir src && printf '<script setup lang="ts">\nconst n: number = 1\n</script>\n<template><p>{{ n }}</p></template>\n' > src/App.vue
echo '{"compilerOptions":{"strict":true,"module":"esnext","moduleResolution":"bundler","jsx":"preserve","noEmit":true},"include":["src/**/*.vue"]}' > tsconfig.json
npx vue-tsc --noEmit 2>&1 | head -4; echo "vue-tsc exit ${PIPESTATUS[0]}"; cd ..

echo; echo "######## svelte-check"
mkdir svelte && cd svelte && npm init -y >/dev/null; npm pkg set type=module
npm install -D svelte svelte-check typescript@$TSV $I 2>&1 | tail -2; npm ls svelte-check svelte 2>&1 | grep -E "svelte"
mkdir src && printf '<script lang="ts">\n  let n: number = 1;\n</script>\n<p>{n}</p>\n' > src/App.svelte
echo '{"compilerOptions":{"strict":true,"module":"esnext","moduleResolution":"bundler","noEmit":true,"verbatimModuleSyntax":true},"include":["src"]}' > tsconfig.json
npx svelte-check 2>&1 | grep -vE "^\s*$" | head -5; cd ..

echo; echo "######## astro check"
mkdir astro && cd astro && npm init -y >/dev/null; npm pkg set type=module
npm install astro @astrojs/check typescript@$TSV $I 2>&1 | tail -2; npm ls astro @astrojs/check 2>&1 | grep -E "astro"
mkdir -p src/pages && printf -- '---\nconst n: number = 1;\n---\n<p>{n}</p>\n' > src/pages/index.astro
echo '{"extends":"astro/tsconfigs/strict"}' > tsconfig.json
npx astro check 2>&1 | grep -vE "^\s*$" | tail -5; cd ..

echo; echo "######## Angular"
npx -y @angular/cli@latest new ang --defaults --skip-git --skip-tests --ssr=false --zoneless 2>&1 | tail -2; cd ang
npx ng version 2>&1 | grep -E "Angular CLI|^@angular/core|typescript" | head -3
npm install -D typescript@$TSV $I 2>&1 | tail -2; npx tsc --version
npx ng build 2>&1 | grep -vE "^\s*$" | tail -6
echo "== done $(date)"
