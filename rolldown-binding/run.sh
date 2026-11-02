#!/bin/bash
# "Cannot find module @rolldown/binding-...": Vite 8 with the native binding skipped or removed, and which fixes work.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) $(uname -s) node $(node -v) npm $(npm -v)"
b() { npx vite build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -aE "Cannot find module|binding|built in|npm has a bug|Error:" | head -2 | cut -c1-220; }
app() { rm -rf $1; mkdir $1 && cd $1 && npm init -y >/dev/null && npm pkg set type=module && echo '<!doctype html><script type="module">console.log(1)</script>' > index.html; }
app a; npm install -D vite@8 $Q 2>&1 | tail -1
echo "vite $(node -p 'require("./node_modules/vite/package.json").version') rolldown $(node -p 'require("./node_modules/rolldown/package.json").version') binding: $(ls node_modules/@rolldown | grep binding)"
echo "-- clean build"; b
BIND=node_modules/@rolldown/$(ls node_modules/@rolldown | grep binding | head -1)
echo "######## binding folder removed"; rm -rf $BIND; b
echo "-- npm rebuild"; npm rebuild $Q >/dev/null 2>&1; b
echo "-- npm i (lockfile kept)"; npm i $Q 2>&1 | tail -1; b
cd ..
echo "######## omit=optional in .npmrc"; app o; echo "omit=optional" > .npmrc; npm install -D vite@8 $Q 2>&1 | tail -1; b
sed -i '/omit=optional/d' .npmrc; echo "-- line removed, npm i"; npm i $Q 2>&1 | tail -1; b
cd ..
echo "######## npm 12: binding removed, then npm i"; app t; npx -y npm@12 install -D vite@8 $Q 2>&1 | tail -2; echo "npm 12: $(npx -y npm@12 -v)"; b
rm -rf node_modules/@rolldown/binding-*; b; npx -y npm@12 i $Q 2>&1 | tail -1; b
echo "== done"
