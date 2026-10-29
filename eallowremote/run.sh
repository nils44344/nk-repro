#!/usr/bin/env bash
# EALLOWREMOTE / EALLOWGIT cases on npm 11.20.0 (bundled with Node 26.13.0) and npm 12.0.2, 12.1.0, 12.2.1.
# Each case runs in a fresh folder; output is trimmed to the lines that matter.
NODE=D:/nk-eallow/node-v26.13.0-win-x64/node.exe
TGZ=https://registry.npmjs.org/is-odd/-/is-odd-3.0.1.tgz
trim() { grep -E "npm error (code|Refusing|Fetching|Unknown|[a-z-]+ is not)|^npm warn (config|invalid|Unknown)|^added|^up to date|^changed|EALLOW|Unknown|unknown|cowsay|< moo|^ *\(oo\)" | grep -v "does not support Node" | head -6; }
pkg() { mkdir -p "$1" && cd "$1" && printf '%s\n' "$2" > package.json; }
for V in 11.20.0 12.0.2 12.1.0 12.2.1; do
  if [ $V = 11.20.0 ]; then CLI=D:/nk-eallow/node-v26.13.0-win-x64/node_modules/npm/bin/npm-cli.js; else CLI=D:/nk-eallow/npm$V/node_modules/npm/bin/npm-cli.js; fi
  npm() { "$NODE" "$CLI" --no-audit --no-fund --loglevel=warn "$@" 2>&1; }
  W=D:/nk-eallow/w/$V; rm -rf "$W"; mkdir -p "$W"
  echo "################ npm $V"
  echo "== defaults: allow-remote=$(npm config get allow-remote) allow-git=$(npm config get allow-git) allow-file=$(npm config get allow-file)"
  (pkg $W/a '{"name":"a","version":"1.0.0"}'; echo "== A: npm install <tarball URL> on the CLI"; npm install $TGZ | trim)
  (pkg $W/b '{"name":"b","version":"1.0.0","dependencies":{"is-odd":"'$TGZ'"}}'; echo "== B: tarball URL in package.json"; npm install | trim)
  (pkg $W/c '{"name":"c","version":"1.0.0","dependencies":{"is-odd":"github:jonschlinkert/is-odd"}}'; echo "== C: github: shorthand"; npm install | trim)
  (pkg $W/d '{"name":"d","version":"1.0.0","dependencies":{"is-odd":"git+https://github.com/jonschlinkert/is-odd.git"}}'; echo "== D: git+https URL"; npm install | trim)
  (pkg $W/e '{"name":"e","version":"1.0.0","dependencies":{"is-odd":"https://github.com/jonschlinkert/is-odd/archive/refs/tags/3.0.1.tar.gz"}}'; echo "== E: GitHub archive .tar.gz URL"; npm install | trim)
  (pkg $W/f/lib '{"name":"lib","version":"1.0.0"}'; pkg $W/f/app '{"name":"app","version":"1.0.0","dependencies":{"lib":"file:../lib"}}'; echo "== F: file: dependency"; npm install | trim)
  (pkg $W/g/mid '{"name":"mid","version":"1.0.0","dependencies":{"is-odd":"'$TGZ'"}}'; pkg $W/g/app '{"name":"app","version":"1.0.0","dependencies":{"mid":"file:../mid"}}';
   echo "== G1: tarball URL one level down, allow-remote=root"; npm install --allow-remote=root | trim; rm -rf node_modules package-lock.json
   echo "== G2: same, allow-remote=all"; npm install --allow-remote=all | trim; rm -rf node_modules package-lock.json
   echo "== G3: same, overrides is-odd to registry 3.0.1, default settings"; printf '%s\n' '{"name":"app","version":"1.0.0","dependencies":{"mid":"file:../mid"},"overrides":{"is-odd":"3.0.1"}}' > package.json; npm install | trim)
  (pkg $W/j '{"name":"j","version":"1.0.0","dependencies":{"is-odd":"'$TGZ'"}}'; echo "== J: env NPM_CONFIG_ALLOW_REMOTE=root"; NPM_CONFIG_ALLOW_REMOTE=root npm install | trim)
  (pkg $W/k '{"name":"k","version":"1.0.0","dependencies":{"is-odd":"'$TGZ'"}}'; printf 'allow-remotes=root\n' > .npmrc; echo "== K: misspelled allow-remotes=root in .npmrc"; npm install | trim)
  (pkg $W/l '{"name":"l","version":"1.0.0","dependencies":{"is-odd":"'$TGZ'"}}'; echo "== L: misspelled --allow-remotes=root flag"; npm install --allow-remotes=root | trim)
  (pkg $W/m '{"name":"m","version":"1.0.0","dependencies":{"is-odd":"'$TGZ'"}}'; printf 'allow-remote=root\n' > .npmrc; echo "== M: allow-remote=root in project .npmrc"; npm install | trim)
  (mkdir -p $W/n && cd $W/n; echo "== N: npx <tarball URL> (cowsay 1.6.0)"; "$NODE" "$(dirname $CLI)/npx-cli.js" --yes https://registry.npmjs.org/cowsay/-/cowsay-1.6.0.tgz hi 2>&1 | trim)
done
echo "################ H: lockfile written by npm 11.20.0 for a tarball dependency, then npm ci"
H=D:/nk-eallow/w/h; rm -rf $H; mkdir -p $H; cd $H
printf '%s\n' '{"name":"h","version":"1.0.0","dependencies":{"is-odd":"'$TGZ'","is-number":"^7.0.0"}}' > package.json
"$NODE" D:/nk-eallow/node-v26.13.0-win-x64/node_modules/npm/bin/npm-cli.js install --no-audit --no-fund --loglevel=warn 2>&1 | trim
grep -E '"resolved"' package-lock.json | head -4
rm -rf node_modules
echo "== npm ci on 12.2.1"; "$NODE" D:/nk-eallow/npm12.2.1/node_modules/npm/bin/npm-cli.js ci --no-audit --no-fund --loglevel=warn 2>&1 | trim
echo "== H2: lockfile with registry deps only (is-number ^7), npm ci on 12.2.1"
mkdir -p ../h2 && cd ../h2 && printf '%s\n' '{"name":"h2","version":"1.0.0","dependencies":{"is-number":"^7.0.0"}}' > package.json
"$NODE" D:/nk-eallow/node-v26.13.0-win-x64/node_modules/npm/bin/npm-cli.js install --no-audit --no-fund --loglevel=warn >/dev/null 2>&1; rm -rf node_modules
"$NODE" D:/nk-eallow/npm12.2.1/node_modules/npm/bin/npm-cli.js ci --no-audit --no-fund --loglevel=warn 2>&1 | trim
