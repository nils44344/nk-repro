#!/bin/bash
# TypeScript 7 vs frameworks: generate a fresh project, build/check it as generated, on plain typescript@7,
# and on the side-by-side setup (typescript 7 as @typescript/native, the 6.x compat package as "typescript").
# Usage: FW=next|angular|vue|nest|nuxt|svelte|astro bash run.sh
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
export CI=1 NG_CLI_ANALYTICS=false NEXT_TELEMETRY_DISABLED=1 ASTRO_TELEMETRY_DISABLED=1 NUXT_TELEMETRY_DISABLED=1
echo "== $(date) node $(node -v) npm $(npm -v) FW=$FW"
case $FW in
  next)    npx -y create-next-app@latest app --ts --app --no-eslint --no-tailwind --no-src-dir --import-alias "@/*" --use-npm --yes >gen.log 2>&1; CMD="npm run build" ;;
  angular) npx -y @angular/cli@latest new app --defaults --skip-git --ssr=false >gen.log 2>&1; CMD="npx ng build" ;;
  vue)     npx -y create-vue@latest app --ts --force >gen.log 2>&1; CMD="npm run build" ;;
  nest)    npx -y @nestjs/cli@latest new app --package-manager npm --skip-git >gen.log 2>&1; CMD="npm run build" ;;
  nuxt)    npx -y nuxi@latest init app --packageManager npm --gitInit false --template minimal >gen.log 2>&1; CMD="npx nuxi typecheck" ;;
  svelte)  npx -y sv@latest create app --template minimal --types ts --no-add-ons --install npm >gen.log 2>&1; CMD="npx svelte-check" ;;
  astro)   npx -y create-astro@latest app --template minimal --install --no-git --yes >gen.log 2>&1; CMD="npx astro check" ;;
esac
[ -d app ] || { echo "generator failed:"; tail -15 gen.log; exit 0; }
cd app; [ -d node_modules ] || npm install $Q 2>&1 | tail -1
[ $FW = nuxt ] && npm install -D vue-tsc typescript $Q 2>&1 | tail -1
[ $FW = astro ] && npm install -D @astrojs/check typescript $Q 2>&1 | tail -1
v() { node -p "try{require('./node_modules/$1/package.json').version}catch{'-'}"; }
echo "versions: typescript $(v typescript) | next $(v next) @angular/core $(v @angular/core) vue $(v vue) vue-tsc $(v vue-tsc) @nestjs/core $(v @nestjs/core) nuxt $(v nuxt) @sveltejs/kit $(v @sveltejs/kit) svelte-check $(v svelte-check) astro $(v astro) @astrojs/check $(v @astrojs/check)"
run() { $CMD > out.log 2>&1; local c=$?; sed 's/\x1b\[[0-9;]*m//g' out.log | grep -aiE "error|not supported|does not|not defined|reading|requires|expose|cannot|✓|compiled|built|found 0|0 errors" | grep -v "^\s*at " | head -4 | cut -c1-220; echo "   exit $c"; }
echo "-- as generated: $CMD"; run
if [ $FW = angular ]; then
  echo "-- strict npm install -D typescript@7.0.2 (no flags)"; npm install -D typescript@7.0.2 $Q 2>&1 | grep -E "ERESOLVE|added|changed|code E" | head -2
  echo "   typescript now $(v typescript); @angular/compiler-cli wants $(node -p 'require("./node_modules/@angular/compiler-cli/package.json").peerDependencies.typescript')"
  echo "-- ng serve on plain typescript 7"; timeout 40 npx ng serve --port 4300 > serve.log 2>&1; sed 's/\[[0-9;]*m//g' serve.log | grep -aE "ERROR|reading|failed|Local:" | head -2 | cut -c1-200
else npm install -D typescript@7 --legacy-peer-deps $Q 2>&1 | tail -1; fi
echo "-- plain typescript $(v typescript)"; run
# the fix as the post gives it: no --legacy-peer-deps (with it, npm skips peers and @astrojs/check fails to load)
rm -rf node_modules package-lock.json; npm pkg delete devDependencies.typescript
npm install -D "@typescript/native@npm:typescript@7" "typescript@npm:@typescript/typescript6@^6.0.2" $Q 2>&1 | grep -E "ERESOLVE|added" | head -1
[ $FW = svelte ] && { npx svelte-kit sync >/dev/null 2>&1; CMD="npx svelte-check --tsgo"; }
echo "-- side-by-side: typescript (compat) $(v typescript), tsc $(npx tsc --version), cmd: $CMD"; run
echo "== done"
