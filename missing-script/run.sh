#!/bin/bash
# npm "Missing script: dev": wrong folder, scaffold script names, typo, workspaces, duplicate/singular "scripts", start fallback.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
[ -n "$NPM" ] && npm install -g npm@$NPM --no-audit --no-fund >/dev/null 2>&1
export CI=1 NG_CLI_ANALYTICS=false NEXT_TELEMETRY_DISABLED=1
echo "== $(date) node $(node -v) npm $(npm -v)"
e() { grep -aE "Missing script|Did you mean|Scripts available|^  [a-z]|DEV|WEB|SERVER|workspace" | head -${1:-3} | cut -c1-160; }
echo "######## 1. wrong folder"; mkdir -p one/my-app/src && cd one && npm init -y >/dev/null
(cd my-app && npm init -y >/dev/null && npm pkg set scripts.dev="echo DEV")
echo "-- from the parent"; npm run dev 2>&1 | e 2; echo "-- from my-app"; (cd my-app && npm run dev 2>&1 | e 1); echo "-- from my-app/src"; (cd my-app/src && npm run dev 2>&1 | e 1); cd ..
echo "######## 3. typo"; mkdir t && cd t && npm init -y >/dev/null && npm pkg set scripts.start="echo START"; npm run strat 2>&1 | e 3; cd ..
echo "######## 4. workspaces"; mkdir -p ws/apps/web ws/apps/api && cd ws
echo '{"name":"root","private":true,"workspaces":["apps/*"]}' > package.json
echo '{"name":"web","version":"1.0.0","scripts":{"dev":"echo WEB"}}' > apps/web/package.json; echo '{"name":"api","version":"1.0.0"}' > apps/api/package.json
npm install --no-audit --no-fund >/dev/null 2>&1
echo "-- root: npm run dev"; npm run dev 2>&1 | e 1; echo "-- npm run dev -w web"; npm run dev -w web 2>&1 | e 1
echo "-- npm run dev --workspaces"; npm run dev --workspaces 2>&1 | e 3; echo "-- npm run dev --workspaces --if-present"; npm run dev --workspaces --if-present 2>&1 | e 2; cd ..
echo "######## 5a. two scripts blocks"; mkdir dup && cd dup && printf '{ "name": "dup", "version": "1.0.0", "scripts": { "dev": "echo DEV" }, "dependencies": {}, "scripts": { "build": "echo BUILD" } }\n' > package.json; npm run dev 2>&1 | e 4; cd ..
echo "######## 5b. \"script\" singular"; mkdir sing && cd sing && printf '{ "name": "sing", "version": "1.0.0", "script": { "dev": "echo DEV" } }\n' > package.json; npm run dev 2>&1 | e 2; cd ..
echo "######## 6. npm start with no start script"; mkdir st && cd st && npm init -y >/dev/null && npm pkg delete scripts.test
echo "-- no server.js"; npm start 2>&1 | e 2; echo 'console.log("SERVER")' > server.js; echo "-- with server.js"; npm start 2>&1 | e 1; cd ..
if [ "$SCAFFOLD" = 1 ]; then
  echo "######## 2. scaffold script names"
  npm create -y vite@latest v -- --template react-ts --no-interactive >/dev/null 2>&1; echo "create-vite: $(node -p 'JSON.stringify(require("./v/package.json").scripts)' 2>&1)"
  npx -y create-next-app@latest n --ts --app --no-eslint --no-tailwind --no-src-dir --import-alias "@/*" --use-npm --yes --skip-install >/dev/null 2>&1; echo "create-next-app $(npm view create-next-app version): $(node -p 'JSON.stringify(require("./n/package.json").scripts)' 2>&1)"
  npx -y @angular/cli@latest new a --defaults --skip-git --skip-install --ssr=false >/dev/null 2>&1; echo "Angular CLI $(npm view @angular/cli version): $(node -p 'JSON.stringify(require("./a/package.json").scripts)' 2>&1)"
fi
echo "== done"
