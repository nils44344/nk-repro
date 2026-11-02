#!/bin/bash
# npm ci EUSAGE "package.json and package-lock.json are not in sync": six causes and their fixes. Run with NPM=11 or 12.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
[ -n "$NPM" ] && npm install -g npm@$NPM --no-audit --no-fund >/dev/null 2>&1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v) npm $(npm -v)"
ci() { npm ci $Q "$@" 2>&1 | grep -aE "EUSAGE|Missing:|Invalid:|can only install with an existing|added [0-9]+" | grep -v "can only install packages when" | head -2 | cut -c1-150; }
p() { rm -rf $1; mkdir $1 && cd $1 && npm init -y >/dev/null; }
echo "######## 1. Missing: dependency added to package.json only"; p a; npm install ms@2.1.3 $Q >/dev/null 2>&1; npm pkg set dependencies.is-number=7.0.0; ci
echo "-- npm ci --force"; ci --force; echo "-- npm ci --legacy-peer-deps"; ci --legacy-peer-deps; rm -rf node_modules; echo "-- after deleting node_modules"; ci
npm install --package-lock-only $Q >/dev/null 2>&1; echo "-- after npm install --package-lock-only"; ci; cd ..
echo "######## 2. Invalid: range edited"; p b; npm install ms@2.1.2 --save-exact $Q >/dev/null 2>&1; npm pkg set dependencies.ms=2.1.3; ci
npm install $Q >/dev/null 2>&1; echo "-- after npm install: ms $(node -p 'require("./package-lock.json").packages["node_modules/ms"].version')"; ci; cd ..
echo "######## 3. Missing: peer skipped with --legacy-peer-deps"; p c; npm install react-dom@18.3.1 --legacy-peer-deps $Q >/dev/null 2>&1; ci
echo "legacy-peer-deps=true" > .npmrc; echo "-- with .npmrc legacy-peer-deps=true"; ci; cd ..
echo "######## 4. Invalid: overrides added"; p d; npm install debug@4.3.4 $Q >/dev/null 2>&1; echo "   ms in lock: $(node -p 'require("./package-lock.json").packages["node_modules/ms"].version')"
node -e 'const p=require("./package.json"); p.overrides={ms:"2.1.3"}; require("fs").writeFileSync("package.json", JSON.stringify(p,null,2))'; ci
npm install $Q >/dev/null 2>&1; echo "-- after npm install"; ci; echo "   ms installed: $(node -p 'require("./node_modules/ms/package.json").version')"; cd ..
echo "######## 5. workspace dependency added by hand"; p e; npm pkg set workspaces[0]=packages/app; mkdir -p packages/app && echo '{"name":"app","version":"1.0.0"}' > packages/app/package.json
npm install $Q >/dev/null 2>&1; (cd packages/app && npm pkg set dependencies.ms=2.1.3); ci; npm install $Q >/dev/null 2>&1; echo "-- after npm install at the root"; ci; cd ..
echo "######## 6. no lockfile"; p f; npm pkg set dependencies.ms=2.1.3; ci; npm install $Q >/dev/null 2>&1; echo "-- after npm install"; ci; cd ..
echo "== done"
