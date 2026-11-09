#!/usr/bin/env bash
# CI port of run.sh and run-g.sh: the same cases, with each npm version installed into $W/npm<V> and run on the
# runner's Node. Usage: W=<work dir> NPMS="11.20.0 12.2.2" bash eallowremote/ci.sh
# The first version in NPMS writes the lockfile for case H; the last one runs `npm ci` and the fixes.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; W=$(cd "$W" && pwd)
NPMS=${NPMS:-"11.20.0 11.21.2 12.0.2 12.1.0 12.2.1 12.2.2"}
OLD=${NPMS%% *}; NEW=${NPMS##* }
TGZ=https://registry.npmjs.org/is-odd/-/is-odd-3.0.1.tgz
echo "== $(date -u) $(uname -s) node $(node -v), bundled npm $(npm -v), npm dist-tag latest: $(npm view npm dist-tags.latest 2>/dev/null)"
for V in $NPMS; do
  mkdir -p $W/npm$V && (cd $W/npm$V && echo '{"name":"holder","version":"1.0.0"}' > package.json && npm install npm@$V --no-audit --no-fund --loglevel=error >/dev/null 2>&1)
  echo "installed npm $V -> $(node $W/npm$V/node_modules/npm/bin/npm-cli.js -v)"
done
cli() { echo $W/npm$1/node_modules/npm/bin/npm-cli.js; }
trim() { grep -E "npm error (code|Refusing|Fetching|Unknown|[a-z-]+ is not)|^npm warn (config|invalid|Unknown)|^added|^up to date|^changed|EALLOW|Unknown|unknown|cowsay|< hi|< moo|^ *\(oo\)" | grep -v "does not support Node" | sed -E 's/ in [0-9]+(ms|s|m)$//' | head -6; }
pkg() { mkdir -p "$1" && cd "$1" && printf '%s\n' "$2" > package.json; }

for V in $NPMS; do
  CLI=$(cli $V)
  npm() { node "$CLI" --no-audit --no-fund --loglevel=warn "$@" 2>&1; }
  X=$W/w/$V; rm -rf "$X"; mkdir -p "$X"
  echo "################ npm $V"
  echo "== defaults: allow-remote=$(npm config get allow-remote) allow-git=$(npm config get allow-git) allow-file=$(npm config get allow-file)"
  (pkg $X/a '{"name":"a","version":"1.0.0"}'; echo "== A: npm install <tarball URL> on the CLI"; npm install $TGZ | trim)
  (pkg $X/b '{"name":"b","version":"1.0.0","dependencies":{"is-odd":"'$TGZ'"}}'; echo "== B: tarball URL in package.json"; npm install | trim)
  (pkg $X/c '{"name":"c","version":"1.0.0","dependencies":{"is-odd":"github:jonschlinkert/is-odd"}}'; echo "== C: github: shorthand"; npm install | trim)
  (pkg $X/d '{"name":"d","version":"1.0.0","dependencies":{"is-odd":"git+https://github.com/jonschlinkert/is-odd.git"}}'; echo "== D: git+https URL"; npm install | trim)
  (pkg $X/e '{"name":"e","version":"1.0.0","dependencies":{"is-odd":"https://github.com/jonschlinkert/is-odd/archive/refs/tags/3.0.1.tar.gz"}}'; echo "== E: GitHub archive .tar.gz URL"; npm install | trim)
  (pkg $X/f/lib '{"name":"lib","version":"1.0.0"}'; pkg $X/f/app '{"name":"app","version":"1.0.0","dependencies":{"lib":"file:../lib"}}'; echo "== F: file: dependency"; npm install | trim)
  (pkg $X/j '{"name":"j","version":"1.0.0","dependencies":{"is-odd":"'$TGZ'"}}'; echo "== J: env NPM_CONFIG_ALLOW_REMOTE=root"; NPM_CONFIG_ALLOW_REMOTE=root npm install | trim)
  (pkg $X/k '{"name":"k","version":"1.0.0","dependencies":{"is-odd":"'$TGZ'"}}'; printf 'allow-remotes=root\n' > .npmrc; echo "== K: misspelled allow-remotes=root in .npmrc"; npm install | trim)
  (pkg $X/l '{"name":"l","version":"1.0.0","dependencies":{"is-odd":"'$TGZ'"}}'; echo "== L: misspelled --allow-remotes=root flag"; npm install --allow-remotes=root | trim)
  (pkg $X/m '{"name":"m","version":"1.0.0","dependencies":{"is-odd":"'$TGZ'"}}'; printf 'allow-remote=root\n' > .npmrc; echo "== M: allow-remote=root in project .npmrc"; npm install | trim)
  (mkdir -p $X/n && cd $X/n; echo "== N: npx <tarball URL> (cowsay 1.6.0)"; node "$(dirname $CLI)/npx-cli.js" --yes https://registry.npmjs.org/cowsay/-/cowsay-1.6.0.tgz hi 2>&1 | trim)
done

echo "################ transitive: a packed dependency (mid) that depends on a tarball URL"
B=$W/w/gbase; rm -rf $B; mkdir -p $B/mid; cd $B/mid
printf '%s\n' '{"name":"mid","version":"1.0.0","dependencies":{"is-odd":"'$TGZ'"}}' > package.json
node "$(cli $OLD)" pack --loglevel=error >/dev/null 2>&1; ls $B/mid | grep tgz
for V in $NPMS; do
  case $V in 11.*) continue;; esac
  CLI=$(cli $V)
  npm() { node "$CLI" --no-audit --no-fund --loglevel=warn "$@" 2>&1; }
  echo "######## npm $V"
  for mode in default root all; do
    X=$B/$V-$mode; rm -rf $X; mkdir -p $X; cd $X
    printf '%s\n' '{"name":"app","version":"1.0.0","dependencies":{"mid":"file:../mid/mid-1.0.0.tgz"}}' > package.json
    echo "== $mode"; if [ $mode = default ]; then npm install | trim; else npm install --allow-remote=$mode | trim; fi
    [ -d node_modules/is-odd ] && echo "   is-odd installed: $(node -p "require('./node_modules/is-odd/package.json').version" 2>/dev/null)"
  done
  X=$B/$V-override; rm -rf $X; mkdir -p $X; cd $X
  printf '%s\n' '{"name":"app","version":"1.0.0","dependencies":{"mid":"file:../mid/mid-1.0.0.tgz"},"overrides":{"is-odd":"3.0.1"}}' > package.json
  echo "== overrides is-odd 3.0.1, default settings"; npm install | trim
  [ -d node_modules/is-odd ] && echo "   is-odd installed: $(node -p "require('./node_modules/is-odd/package.json').version" 2>/dev/null)"
done

echo "################ H: lockfile written by npm $OLD for a tarball dependency, then npm ci on $NEW"
H=$W/w/h; rm -rf $H; mkdir -p $H; cd $H
printf '%s\n' '{"name":"h","version":"1.0.0","dependencies":{"is-odd":"'$TGZ'","is-number":"^7.0.0"}}' > package.json
node "$(cli $OLD)" install --no-audit --no-fund --loglevel=warn 2>&1 | trim
grep -E '"resolved"' package-lock.json | head -4
rm -rf node_modules
CLI=$(cli $NEW)
npm() { node "$CLI" --no-audit --no-fund --loglevel=warn "$@" 2>&1; }
echo "== npm ci on $NEW"; npm ci | trim
echo "== H npm ci + allow-remote=root in .npmrc"; printf 'allow-remote=root\n' > .npmrc; npm ci | trim; rm .npmrc
echo "== H2: lockfile with registry deps only (is-number ^7), npm ci on $NEW"
mkdir -p ../h2 && cd ../h2 && printf '%s\n' '{"name":"h2","version":"1.0.0","dependencies":{"is-number":"^7.0.0"}}' > package.json
node "$(cli $OLD)" install --no-audit --no-fund --loglevel=warn >/dev/null 2>&1; rm -rf node_modules
npm ci | trim

echo "################ fixes on $NEW"
X=$W/w/fx; rm -rf $X; mkdir -p $X/a $X/c $X/n; cd $X/a; echo '{"name":"a","version":"1.0.0"}' > package.json
echo "== A + --allow-remote=root (URL given on the command line)"; npm install $TGZ --allow-remote=root | trim; grep is-odd package.json
cd $X/c; echo '{"name":"c","version":"1.0.0","dependencies":{"is-odd":"github:jonschlinkert/is-odd"}}' > package.json
echo "== C + --allow-git=root"; npm install --allow-git=root | trim
cd $X/n; echo "== N npx + --allow-remote=root"; node "$(dirname $CLI)/npx-cli.js" --yes --allow-remote=root https://registry.npmjs.org/cowsay/-/cowsay-1.6.0.tgz hi 2>&1 | grep -E "npm error (code|Refusing)|< hi >" | head -3
echo "== N npx + --allow-remote=all"; node "$(dirname $CLI)/npx-cli.js" --yes --allow-remote=all https://registry.npmjs.org/cowsay/-/cowsay-1.6.0.tgz hi 2>&1 | grep -E "npm error (code|Refusing)|< hi >" | head -3
echo "== done $(date -u)"
