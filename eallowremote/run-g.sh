#!/usr/bin/env bash
# Transitive case done properly: "mid" is packed to a .tgz (so npm resolves its dependencies), and mid depends on a
# tarball URL. Then root vs all vs overrides on npm 12.0.2, 12.1.0, 12.2.1.
NODE=D:/nk-eallow/node-v26.13.0-win-x64/node.exe
TGZ=https://registry.npmjs.org/is-odd/-/is-odd-3.0.1.tgz
trim() { grep -E "npm error (code|Refusing|Fetching)|^added|^up to date|ERESOLVE|EOVERRIDE|npm error [A-Z]" | grep -v "does not support Node" | head -5; }
B=D:/nk-eallow/w/gbase; rm -rf $B; mkdir -p $B/mid; cd $B/mid
printf '%s\n' '{"name":"mid","version":"1.0.0","dependencies":{"is-odd":"'$TGZ'"}}' > package.json
"$NODE" D:/nk-eallow/node-v26.13.0-win-x64/node_modules/npm/bin/npm-cli.js pack --loglevel=error >/dev/null 2>&1; ls $B/mid/*.tgz
for V in 12.0.2 12.1.0 12.2.1; do
  CLI=D:/nk-eallow/npm$V/node_modules/npm/bin/npm-cli.js
  npm() { "$NODE" "$CLI" --no-audit --no-fund --loglevel=warn "$@" 2>&1; }
  echo "################ npm $V"
  for mode in default root all; do
    W=$B/$V-$mode; rm -rf $W; mkdir -p $W; cd $W
    printf '%s\n' '{"name":"app","version":"1.0.0","dependencies":{"mid":"file:../mid/mid-1.0.0.tgz"}}' > package.json
    echo "== $mode"; if [ $mode = default ]; then npm install | trim; else npm install --allow-remote=$mode | trim; fi
    [ -d node_modules/is-odd ] && echo "   is-odd installed: $(node -p "require('./node_modules/is-odd/package.json').version" 2>/dev/null)"
  done
  W=$B/$V-override; rm -rf $W; mkdir -p $W; cd $W
  printf '%s\n' '{"name":"app","version":"1.0.0","dependencies":{"mid":"file:../mid/mid-1.0.0.tgz"},"overrides":{"is-odd":"3.0.1"}}' > package.json
  echo "== overrides is-odd 3.0.1, default settings"; npm install | trim
  [ -d node_modules/is-odd ] && echo "   is-odd installed: $(node -p "require('./node_modules/is-odd/package.json').version" 2>/dev/null)"
done
echo "################ fixes on 12.2.1"
CLI=D:/nk-eallow/npm12.2.1/node_modules/npm/bin/npm-cli.js
npm() { "$NODE" "$CLI" --no-audit --no-fund --loglevel=warn "$@" 2>&1; }
X=D:/nk-eallow/w/fx; rm -rf $X; mkdir -p $X/a $X/c $X/n; cd $X/a; echo '{"name":"a","version":"1.0.0"}' > package.json
echo "== A + --allow-remote=root (URL given on the command line)"; npm install $TGZ --allow-remote=root | trim; grep is-odd package.json
cd $X/c; echo '{"name":"c","version":"1.0.0","dependencies":{"is-odd":"github:jonschlinkert/is-odd"}}' > package.json
echo "== C + --allow-git=root"; npm install --allow-git=root | trim
cd $X/n; echo "== N npx + --allow-remote=root"; "$NODE" "$(dirname $CLI)/npx-cli.js" --yes --allow-remote=root https://registry.npmjs.org/cowsay/-/cowsay-1.6.0.tgz hi 2>&1 | grep -E "npm error (code|Refusing)|< hi >" | head -3
echo "== N npx + --allow-remote=all"; "$NODE" "$(dirname $CLI)/npx-cli.js" --yes --allow-remote=all https://registry.npmjs.org/cowsay/-/cowsay-1.6.0.tgz hi 2>&1 | grep -E "npm error (code|Refusing)|< hi >" | head -3
cd D:/nk-eallow/w/h; rm -rf node_modules; echo "== H npm ci + allow-remote=root in .npmrc"; printf 'allow-remote=root\n' > .npmrc; npm ci | trim; rm .npmrc
