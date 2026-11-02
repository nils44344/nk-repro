#!/bin/bash
# npm ETARGET causes: a tag that doesn't exist, min-release-age vs a fresh nightly (and the exclude fix),
# a companion package not published at the same version (Prisma 8 rc).
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund"
npm install -g npm@12 $Q >/dev/null 2>&1
echo "== $(date -u) node $(node -v) npm $(npm -v)"
e() { grep -aE "code E|notarget|added|up to date" | head -2 | cut -c1-200; }
p() { rm -rf $1; mkdir $1 && cd $1 && npm init -y >/dev/null; }
echo "######## 1. tag that doesn't exist"; p a; npm install react@beta-nope $Q 2>&1 | e; cd ..
NIGHTLY=$(npm view typescript dist-tags.next); PUB=$(npm view typescript time --json | node -e "const t=JSON.parse(require('fs').readFileSync(0));console.log(t['$NIGHTLY'])")
echo "######## 2. min-release-age=7 vs typescript@$NIGHTLY (published $PUB)"; p b; echo "min-release-age=7" > .npmrc
npm install typescript@$NIGHTLY $Q 2>&1 | e
echo "-- typescript@next (a tag) under the same setting:"; npm install typescript@next $Q 2>&1 | e; echo "   installed: $(node -p 'require("./node_modules/typescript/package.json").version' 2>/dev/null)"
printf 'min-release-age=7\nmin-release-age-exclude=typescript\n' > .npmrc; rm -rf node_modules package-lock.json
echo "-- with min-release-age-exclude=typescript"; npm install typescript@$NIGHTLY $Q 2>&1 | e; cd ..
RC=$(npm view prisma dist-tags.latest); echo "######## 5. prisma@$RC + @prisma/client@$RC"; p c
npm install prisma@$RC @prisma/client@$RC $Q 2>&1 | e
echo "   @prisma/client versions matching 8.x: $(npm view @prisma/client versions --json | node -e 'console.log(JSON.parse(require("fs").readFileSync(0)).filter(v=>v.startsWith("8.")).length)')"
cd ..; echo "== done"
