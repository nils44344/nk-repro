#!/usr/bin/env bash
# Repro for https://nilaykabariya.blog/fixes/npm-error-code-eallowgit : every git dependency case on each npm in NPMS,
# installed into $W/npm<V> and run on the runner's Node. Usage: W=<work dir> NPMS="11.21.2 12.2.2" bash eallowgit/ci.sh
# The first version in NPMS writes the lockfile for the npm ci case; the last one runs npm ci, the values and fixes.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; W=$(cd "$W" && pwd)
NPMS=${NPMS:-"11.21.2 12.2.2"}
OLD=${NPMS%% *}; NEW=${NPMS##* }
GH=jonschlinkert/is-odd
echo "== $(date -u) $(uname -s) node $(node -v), bundled npm $(npm -v), git $(git --version | cut -d' ' -f3), npm dist-tag latest: $(npm view npm dist-tags.latest 2>/dev/null)"
for V in $NPMS; do
  mkdir -p $W/npm$V && (cd $W/npm$V && echo '{"name":"holder","version":"1.0.0"}' > package.json && npm install npm@$V --no-audit --no-fund --loglevel=error >/dev/null 2>&1)
  echo "installed npm $V -> $(node $W/npm$V/node_modules/npm/bin/npm-cli.js -v)"
done
cli() { echo $W/npm$1/node_modules/npm/bin/npm-cli.js; }
trim() { grep -E "npm error (code|Refusing|Fetching|could not)|^npm warn (invalid|config)|^added|^up to date|^changed|EALLOW|< hi" | grep -v "does not support Node" | sed -E 's/ in [0-9]+(ms|s|m)$//' | head -5; }
pkg() { mkdir -p "$1" && cd "$1" && printf '%s\n' "$2" > package.json; }
dep() { echo '{"name":"t","version":"1.0.0","dependencies":{"is-odd":"'$1'"}}'; }

for V in $NPMS; do
  CLI=$(cli $V)
  npm() { node "$CLI" --no-audit --no-fund --loglevel=warn "$@" 2>&1; }
  X=$W/w/$V; rm -rf "$X"; mkdir -p "$X"
  echo "################ npm $V"
  echo "== default allow-git=$(npm config get allow-git)"
  (pkg $X/a "$(dep github:$GH)"; echo "== A: github: shorthand"; npm install | trim)
  (pkg $X/b "$(dep git+https://github.com/$GH.git)"; echo "== B: git+https URL"; npm install | trim)
  (pkg $X/c "$(dep github:$GH#3.0.1)"; echo "== C: pinned to tag #3.0.1"; npm install | trim)
  (pkg $X/d "$(dep 'github:'$GH'#semver:^3')"; echo "== D: pinned to #semver:^3"; npm install | trim)
  (pkg $X/e '{"name":"e","version":"1.0.0"}'; echo "== E: npm install github:... on the command line"; npm install github:$GH | trim)
  (mkdir -p $X/f && cd $X/f; echo "== F: npx github:piuccio/cowsay"; node "$(dirname $CLI)/npx-cli.js" --yes github:piuccio/cowsay hi 2>&1 | trim)
done

CLI=$(cli $NEW)
npm() { node "$CLI" --no-audit --no-fund --loglevel=warn "$@" 2>&1; }
echo "################ values on $NEW (direct github: dependency)"
for v in none root all; do (pkg $W/w/v-$v "$(dep github:$GH)"; echo "== --allow-git=$v"; npm install --allow-git=$v | trim); done
echo "################ where it is set, on $NEW"
(pkg $W/w/s1 "$(dep github:$GH)"; printf 'allow-git=root\n' > .npmrc; echo "== project .npmrc allow-git=root"; npm install | trim)
(pkg $W/w/s2 "$(dep github:$GH)"; echo "== env npm_config_allow_git=root"; npm_config_allow_git=root npm install | trim)
(pkg $W/w/s3 "$(dep github:$GH)"; printf 'allow-git=root\n' > .npmrc; echo "== .npmrc root + flag --allow-git=none (flag wins?)"; npm install --allow-git=none | trim)
echo "################ invalid values on $NEW"
(pkg $W/w/i1 "$(dep github:$GH)"; echo "== flag --allow-git=yes"; npm install --allow-git=yes | trim)
(pkg $W/w/i2 "$(dep github:$GH)"; printf 'allow-git=yes\n' > .npmrc; echo "== .npmrc allow-git=yes"; npm install | trim)
(pkg $W/w/i3 "$(dep github:$GH)"; echo "== env npm_config_allow_git=yes"; npm_config_allow_git=yes npm install | trim)
echo "################ optional git dependency on $NEW"
(pkg $W/w/o '{"name":"o","version":"1.0.0","optionalDependencies":{"is-odd":"github:'$GH'"}}'; echo "== optionalDependencies github:"; npm install | trim; [ -d node_modules/is-odd ] && echo "   is-odd installed" || echo "   is-odd NOT installed")
echo "################ npm ci: lockfile written by $OLD, run on $NEW"
(pkg $W/w/ci "$(dep github:$GH)"; node "$(cli $OLD)" install --no-audit --no-fund --loglevel=warn 2>&1 | trim; grep -m1 '"resolved"' package-lock.json; rm -rf node_modules
 echo "== npm ci"; npm ci | trim; printf 'allow-git=root\n' > .npmrc; echo "== npm ci + allow-git=root"; npm ci | trim)
