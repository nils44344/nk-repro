#!/bin/bash
set +e
sudo useradd -m dev
curl -sO https://nodejs.org/dist/v24.15.0/node-v24.15.0-linux-x64.tar.xz && sudo mkdir -p /opt/rootnode && sudo tar -xJf node-v24.15.0-linux-x64.tar.xz -C /opt/rootnode --strip-components=1
ls -ld /opt/rootnode/lib/node_modules | awk '{print $1,$3,$4,$9}'
R(){ sudo -u dev env HOME=/home/dev PATH="/opt/rootnode/bin:/usr/bin:/bin" "$@"; }
R node -v; R npm config get prefix
echo "== 1. npm install -g as a normal user (root-owned Node)"; R npm install -g cowsay --no-audit --no-fund 2>&1 | grep -E "npm error (code|syscall|path|errno|Error)" | head -5
echo "== fix 1: user prefix"; R npm config set prefix /home/dev/.npm-global; R npm install -g cowsay --no-audit --no-fund 2>&1 | tail -1; R /home/dev/.npm-global/bin/cowsay ok 2>&1 | sed -n 2p
echo "-- not on PATH yet:"; R bash -c 'cowsay hi 2>&1 | head -1'
echo "-- with PATH:"; R bash -c 'export PATH=/home/dev/.npm-global/bin:$PATH; cowsay hi | sed -n 2p'
echo "== sudo npm install -g works but writes as root:"; sudo env HOME=/home/dev PATH="/opt/rootnode/bin:/usr/bin:/bin" npm install -g is-number --prefix /opt/rootnode --no-audit --no-fund 2>&1 | tail -1; ls -ld /home/dev/.npm 2>&1 | awk '{print $3,$4,$9}'; sudo find /home/dev/.npm -user root | head -2
