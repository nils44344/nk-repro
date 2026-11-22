#!/usr/bin/env bash
# sh: vite: command not found / sh: 1: vite: not found, on Linux, macOS, CI and Docker.
# Each case runs in a fresh copy of a minimal Vite project. Prints the command, the key output lines and the exit code.
set +e
W=${W:-$PWD/work}; VITE=${VITE:-8.3.8}
echo "== $(uname -s) $(uname -m) | node $(node -v) | npm $(npm -v) | /bin/sh -> $(readlink -f /bin/sh 2>/dev/null || echo /bin/sh) | vite $VITE"
mkdir -p "$W/tpl" && cd "$W/tpl"
cat > package.json <<J
{ "name": "vite-cnf", "private": true, "type": "module", "scripts": { "dev": "vite", "build": "vite build" }, "devDependencies": { "vite": "$VITE" } }
J
echo '<!doctype html><title>t</title><script type="module" src="/main.js"></script>' > index.html
echo 'document.title = "ok";' > main.js
npm install --no-audit --no-fund >/dev/null 2>&1 && rm -rf node_modules   # lockfile only
fresh() { rm -rf "$W/c" && cp -r "$W/tpl" "$W/c" && cd "$W/c"; }
run() { echo; echo "\$ $*"; ( eval "$@" ) 2>&1 | grep -E "vite|not found|command not found|Permission denied|built in|ERR|error|added|up to date|omit" | grep -v "^npm warn" | head -6; echo "exit ${PIPESTATUS[0]}"; }

echo; echo "### 1. no install"; fresh; run npm run build
echo; echo "### 2. control: npm ci"; fresh; run npm ci --no-audit --no-fund; run npm run build
echo; echo "### 3. NODE_ENV=production npm ci"; fresh; run NODE_ENV=production npm ci --no-audit --no-fund; run "ls node_modules/.bin 2>&1 | head -3"; run npm run build
echo; echo "### 4. npm ci --omit=dev"; fresh; run npm ci --omit=dev --no-audit --no-fund; run npm run build
echo; echo "### 5. NODE_ENV=production npm ci --include=dev"; fresh; run NODE_ENV=production npm ci --include=dev --no-audit --no-fund; run npm run build
echo; echo "### 6. omit=dev in .npmrc"; fresh; echo "omit=dev" > .npmrc; run npm ci --no-audit --no-fund; run npm run build; run npm ci --include=dev --no-audit --no-fund; run npm run build
echo; echo "### 7. vite typed in the shell, not via npm"; fresh; npm ci --no-audit --no-fund >/dev/null 2>&1; run vite build; run sh -c "'vite build'"; run npx vite build; run ./node_modules/.bin/vite build
echo; echo "### 8. exec bit lost on the bin target"; fresh; npm ci --no-audit --no-fund >/dev/null 2>&1; chmod -x node_modules/vite/bin/vite.js; run npm run build; run npm rebuild vite; run npm run build
echo; echo "### 9. node_modules/.bin missing"; fresh; npm ci --no-audit --no-fund >/dev/null 2>&1; rm -rf node_modules/.bin; run npm run build; run npm rebuild; run npm run build

if [ "$(uname -s)" = Linux ] && command -v docker >/dev/null; then
  echo; echo "### 10. Docker: bind mount hides the image's node_modules"
  fresh
  cat > Dockerfile <<D
FROM node:24-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --no-audit --no-fund
COPY . .
CMD ["npm", "run", "build"]
D
  docker build -q -t vite-cnf . >/dev/null 2>&1 && echo "image built"
  run docker run --rm vite-cnf
  run docker run --rm -v "\$PWD:/app" vite-cnf
  run docker run --rm -v "\$PWD:/app" -v /app/node_modules vite-cnf
fi
