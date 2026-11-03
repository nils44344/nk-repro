#!/bin/bash
# npm "Invalid Version": a bad version in package-lock.json (npm ci / npm install) vs a bad "version" in your own
# package.json (npm version patch). Run with NPM=11 or 12.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
[ -n "$NPM" ] && npm install -g npm@$NPM --no-audit --no-fund >/dev/null 2>&1
Q="--no-audit --no-fund"; echo "== $(date -u) node $(node -v) npm $(npm -v)"
e() { grep -aE "Invalid [Vv]ersion[^\n]*|code EUSAGE|added|up to date|^v[0-9]" | head -1 | cut -c1-100; }
mkdir -p lock && cd lock && npm init -y >/dev/null && npm install is-number@7.0.0 $Q >/dev/null 2>&1; cp package-lock.json good.json
for V in 7.0.0 7.0 7.0.0a2 ""; do
  node -e 'const f="package-lock.json",l=JSON.parse(require("fs").readFileSync("good.json"));l.packages["node_modules/is-number"].version=process.argv[1];require("fs").writeFileSync(f,JSON.stringify(l,null,2))' "$V"
  rm -rf node_modules; c=$(npm ci $Q 2>&1 | e)
  node -e 'const f="package-lock.json",l=JSON.parse(require("fs").readFileSync("good.json"));l.packages["node_modules/is-number"].version=process.argv[1];require("fs").writeFileSync(f,JSON.stringify(l,null,2))' "$V"
  rm -rf node_modules; i=$(npm install $Q 2>&1 | e); fixed=$(node -p 'require("./package-lock.json").packages["node_modules/is-number"].version')
  echo "-- lock version \"$V\": npm ci -> $c | npm install -> $i (lock now \"$fixed\")"; done
cd $W; mkdir -p pkg && cd pkg && git init -q . && git config user.email t@t && git config user.name t
for V in 1.0.0 1.0.0-beta v1.0.0 " 1.0.0 " "" 1.0 0.1.0a2 "4.2 11" 01.0.0; do
  echo "{\"name\":\"x\",\"version\":\"$V\"}" > package.json; echo "-- version \"$V\": npm version patch -> $(npm version patch --no-git-tag-version 2>&1 | e)"; done
echo "== done"
