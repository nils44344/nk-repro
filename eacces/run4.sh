#!/bin/bash
# npm EACCES on npm 11 vs npm 12 (8 Nov 2026): the same three causes, plus `sudo npx` leaving a root-owned
# npx cache, plus Docker on node:24-slim and node:26-slim. NPM_V selects the npm version for the host cases.
set +e
NPM_V=${NPM_V:-11}
NODEDIR=$(dirname "$(command -v node)")
sudo env PATH="$NODEDIR:/usr/bin:/bin" npm install -g "npm@$NPM_V" --no-audit --no-fund >/dev/null 2>&1
echo "== $(date -u +%F) node $(node -v) npm $(npm -v) at $NODEDIR"
sudo useradd -m dev
mkdir -p /tmp/p && sudo chown dev /tmp/p && cd /tmp/p
D(){ sudo -u dev env HOME=/home/dev PATH="$NODEDIR:/usr/bin:/bin" "$@"; }
E='code|syscall|path|errno|Error:|Your cache|sudo chown|root-owned|permission'
echo "== 1. global install as a normal user"; D npm config get prefix; D npm install -g cowsay 2>&1 | grep -E "$E|added" | head -6
echo "== 2. after sudo npm, a normal project install"
sudo env HOME=/home/dev PATH="$NODEDIR:/usr/bin:/bin" npm install -g --prefix /tmp/rootglobal is-number --no-audit --no-fund 2>&1 | tail -1
D bash -c 'cd /tmp/p && npm init -y >/dev/null && npm install is-odd --no-audit --no-fund 2>&1' | grep -E "$E|added" | head -8
sudo chown -R dev:dev /home/dev/.npm
echo "== 4. sudo npx, then npx as the user"
sudo env HOME=/home/dev PATH="$NODEDIR:/usr/bin:/bin" npx -y cowsay@1.6.0 hi 2>&1 | tail -1
echo "owner of _npx: $(stat -c %U /home/dev/.npm/_npx 2>/dev/null)"
D npx -y cowsay@1.6.0 hi 2>&1 | grep -E "$E|< hi >" | head -6
D npx -y figlet-cli@0.2.0 hi 2>&1 | grep -E "$E" | head -6; echo "(a different package)"
echo "== fix 4"; sudo chown -R dev:dev /home/dev/.npm; D npx -y cowsay@1.6.0 hi 2>&1 | grep -E "$E|< hi >" | head -3
echo "== 3. Docker: USER node with a root-owned WORKDIR"
mkdir -p /tmp/d1 && cd /tmp/d1 && printf '{"name":"a","version":"1.0.0","dependencies":{"is-number":"^7.0.0"}}\n' > package.json
for img in node:24-slim node:26-slim; do
  printf 'FROM %s\nWORKDIR /app\nCOPY package.json .\nUSER node\nRUN npm -v && npm install --no-audit --no-fund\n' "$img" > Dockerfile
  echo "-- $img"; docker build --no-cache --progress=plain . 2>&1 | grep -E "^#[0-9]+ [0-9.]+ ([0-9]+\.[0-9]+\.[0-9]+$|npm error (code|syscall|path))|added" | sed -E 's/^#[0-9]+ [0-9.]+ //' | head -5
done
echo "== done"
