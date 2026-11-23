#!/bin/bash
# pnpm 11 vs pnpm 12: what each item on pnpm's "What's different in pnpm 12" list prints when you upgrade.
# Every case runs in a fresh folder, first with pnpm 11, then with pnpm 12, and prints the exit code and the output.
# No accounts, no tokens: public npm packages and one public GitHub repo only.
set +e
V11=${V11:-11.28.13}; V12=${V12:-12.21.0}
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
export npm_config_update_notifier=false COREPACK_ENABLE_STRICT=0
export PNPM_HOME="$W/pnpm-home"; export PATH="$PNPM_HOME:$PATH"; mkdir -p "$PNPM_HOME"
for V in $V11 $V12; do npx -y pnpm@$V --version >/dev/null 2>&1; done   # warm the npx cache once
echo "== $(uname -s) | node $(node -v) | pnpm $(npx -y pnpm@$V11 --version) and $(npx -y pnpm@$V12 --version) | npm dist-tags: $(npm view pnpm dist-tags --json | tr -d '\n ' | grep -oE '"latest":"[^"]+"|"latest-11":"[^"]+"|"latest-12":"[^"]+"' | tr '\n' ' ')"

new() { rm -rf "$W/p"; mkdir -p "$W/p"; cd "$W/p" || exit 1; printf '{ "name": "p", "version": "1.0.0", "private": true%s }\n' "$1" > package.json; }
show() { sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g' | grep -avE '^\s*$|^Progress:|Downloading|Packages: \+|^\++$|Done in|^Lockfile is up to date' | head -${2:-12} | cut -c1-240; }
run() { local v=$1; shift; echo "-- pnpm $v: pnpm $*"; ( npx -y pnpm@$v "$@" > out.log 2>&1 ); local e=$?; show < out.log; echo "   exit $e"; }

echo; echo "### 1. a misspelled setting in pnpm-workspace.yaml (minimumReleaseAgee), no packageManager pin"
for v in $V11 $V12; do new; printf 'minimumReleaseAgee: 1440\n' > pnpm-workspace.yaml; run $v add is-number@7.0.0; done

echo; echo "### 2. the same, with packageManager pinned to the pnpm that runs"
for v in $V11 $V12; do new ", \"packageManager\": \"pnpm@$v\""; printf 'minimumReleaseAgee: 1440\n' > pnpm-workspace.yaml; run $v add is-number@7.0.0; done

echo; echo "### 2b. pin satisfied, setting spelled right (minimumReleaseAge)"
new ", \"packageManager\": \"pnpm@$V12\""; printf 'minimumReleaseAge: 1440\n' > pnpm-workspace.yaml; run $V12 add is-number@7.0.0

echo; echo "### 3. pnpm install --frozen-lockfile false (and the other spellings)"
for v in $V11 $V12; do
  new; npx -y pnpm@$v add is-number@7.0.0 >/dev/null 2>&1; cp package.json pkg.before
  run $v install --frozen-lockfile false
  echo "   package.json changed: $(cmp -s package.json pkg.before && echo no || { echo yes:; diff pkg.before package.json | grep '^>' | tr -s ' '; })"
  run $v install --frozen-lockfile=false
  run $v install --no-frozen-lockfile
done

echo; echo "### 4. pnpm install --resolution-only"
for v in $V11 $V12; do new; npx -y pnpm@$v add is-number@7.0.0 >/dev/null 2>&1; run $v install --resolution-only; run $v peers check; done

echo; echo "### 5. pnpm add yarn"
for v in $V11 $V12; do new; run $v add yarn; echo "   package.json now: $(tr -d '\n' < package.json | tr -s ' ')"; done

echo; echo "### 6. engineStrict: an optional dependency whose regular dependency needs node >=99"
mkdir -p "$W/pk/child" "$W/pk/parent"
printf '{ "name": "child-needs-node99", "version": "1.0.0", "engines": { "node": ">=99" } }\n' > "$W/pk/child/package.json"
( cd "$W/pk/child" && npm pack --silent >/dev/null )
printf '{ "name": "opt-parent", "version": "1.0.0", "dependencies": { "child-needs-node99": "file:%s" } }\n' "$W/pk/child/child-needs-node99-1.0.0.tgz" > "$W/pk/parent/package.json"
( cd "$W/pk/parent" && npm pack --silent >/dev/null )
for v in $V11 $V12; do
  new ", \"optionalDependencies\": { \"opt-parent\": \"file:$W/pk/parent/opt-parent-1.0.0.tgz\" }"
  printf 'engineStrict: true\n' > pnpm-workspace.yaml; run $v install
done

echo; echo "### 7. a git+ssh dependency on a runner with no SSH key"
for v in $V11 $V12; do
  new; run $v add git+ssh://git@github.com/sindresorhus/slash.git
  echo "   lockfile resolution: $(grep -m2 -E 'tarball:|repo:|codeload|git@github|resolution:' pnpm-lock.yaml 2>/dev/null | tr -s ' ' | tr '\n' ' ')"
done

echo; echo "### 8. pnpm add --global through sudo"
for v in $V11 $V12; do
  cd "$W"; echo "-- pnpm $v: sudo pnpm add -g is-number@7.0.0"
  ( sudo env "PATH=$PATH" "PNPM_HOME=$PNPM_HOME" npx -y pnpm@$v add -g is-number@7.0.0 > "$W/sudo.log" 2>&1 ); e=$?; show < "$W/sudo.log" 8; echo "   exit $e"
done
echo; echo "== done"
