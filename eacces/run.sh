#!/bin/bash
# npm EACCES: global installs, a root-owned cache after sudo, and Docker as a non-root user.
set +e
NODEDIR=$(dirname "$(command -v node)"); echo "node $(node -v) npm $(npm -v) at $NODEDIR"
sudo useradd -m dev
D(){ sudo -u dev env HOME=/home/dev PATH="$NODEDIR:/usr/bin:/bin" "$@"; }
echo "== 1. global install as a normal user"; D npm config get prefix; D npm install -g cowsay 2>&1 | grep -E "code|syscall|path|errno|Error:" | head -5
echo "== fix 1: user prefix"; D npm config set prefix /home/dev/.npm-global; D npm install -g cowsay --no-audit --no-fund 2>&1 | tail -1; D /home/dev/.npm-global/bin/cowsay hi 2>&1 | head -2 | tail -1
echo "== 2. sudo npm leaves root-owned cache"
D npm config delete prefix
sudo env HOME=/home/dev PATH="$NODEDIR:/usr/bin:/bin" npm install -g --prefix /tmp/rootglobal is-number --no-audit --no-fund 2>&1 | tail -1
ls -ld /home/dev/.npm /home/dev/.npm/_cacache 2>&1 | awk '{print $3,$4,$9}'
mkdir -p /tmp/p && sudo chown dev /tmp/p; D bash -c 'cd /tmp/p && npm init -y >/dev/null && npm install is-odd --no-audit --no-fund 2>&1 | grep -E "code|syscall|path|errno|Your cache|sudo chown" | head -6'
echo "== fix 2: chown the cache"; sudo chown -R dev:dev /home/dev/.npm; D bash -c 'cd /tmp/p && npm install is-odd --no-audit --no-fund 2>&1 | tail -1'
echo "== 3. Docker: USER node with a root-owned WORKDIR"
mkdir -p d1 && cd d1 && printf '{"name":"a","version":"1.0.0","dependencies":{"is-number":"^7.0.0"}}\n' > package.json
printf 'FROM node:24-slim\nWORKDIR /app\nCOPY package.json .\nUSER node\nRUN npm install --no-audit --no-fund\n' > Dockerfile
docker build -q . 2>&1 | grep -E "code|syscall|path|errno|ERROR" | head -5
echo "== fix 3: chown before switching user"
printf 'FROM node:24-slim\nWORKDIR /app\nRUN chown node:node /app\nUSER node\nCOPY --chown=node:node package.json .\nRUN npm install --no-audit --no-fund\n' > Dockerfile
docker build . 2>&1 | grep -E "added|ERROR|code" | head -3
