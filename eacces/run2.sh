#!/bin/bash
set +e
NODEDIR=$(dirname "$(command -v node)"); ls -ld "$(dirname "$NODEDIR")/lib/node_modules"
sudo useradd -m dev
D(){ sudo -u dev env HOME=/home/dev PATH="$NODEDIR:/usr/bin:/bin" "$@"; }
echo "== 1. global install as a normal user"; D npm install -g cowsay --no-audit --no-fund 2>&1 | tail -8
echo "== 1b. distro node (apt)"; sudo apt-get install -y -qq nodejs npm >/dev/null 2>&1; /usr/bin/node -v; sudo -u dev env HOME=/home/dev /usr/bin/npm config get prefix; sudo -u dev env HOME=/home/dev /usr/bin/npm install -g cowsay 2>&1 | grep -E "code|syscall|path|errno|Error" | head -5
echo "== 3. Docker"
mkdir -p d1 && cd d1 && printf '{"name":"a","version":"1.0.0","dependencies":{"is-number":"^7.0.0"}}\n' > package.json
printf 'FROM node:24-slim\nWORKDIR /app\nCOPY package.json .\nUSER node\nRUN npm install --no-audit --no-fund\n' > Dockerfile
docker build --progress=plain . 2>&1 | grep -E "npm error|ERROR" | head -8
