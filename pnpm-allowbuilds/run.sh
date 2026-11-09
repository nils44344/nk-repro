#!/bin/bash
# pnpm 12 ERR_PNPM_IGNORED_BUILDS (9 Nov 2026): which approval settings let a clean install exit 0?
# esbuild (has a postinstall) + lefthook pinned to an older version than the approval names.
set +e
W=${W:-$(pwd)/work}; rm -rf "$W"; mkdir -p "$W"; cd "$W" || exit 1
PN="npx -y pnpm@${PNPM_V:-12.18.0}"
echo "== $(date -u +%F) node $(node -v) pnpm $($PN -v)"
t() { # $1 label, $2 pnpm-workspace.yaml body (empty = no file), $3 extra package.json pnpm field
  rm -rf p && mkdir p && cd p
  printf '{"name":"p","version":"1.0.0","private":true,"dependencies":{"esbuild":"0.28.2","lefthook":"2.2.1"}%s}\n' "$3" > package.json
  [ -n "$2" ] && printf '%s\n' "$2" > pnpm-workspace.yaml
  out=$($PN install --reporter=append-only 2>&1); e=$?
  printf '%-58s | exit %s | %s\n' "$1" "$e" "$(echo "$out" | grep -m1 -oE 'ERR_PNPM_[A-Z_]+|Ignored build scripts: [^ ].*' | head -1)"
  cd ..
}
t "no config" ""
t "package.json pnpm.onlyBuiltDependencies [esbuild, lefthook]" "" ',"pnpm":{"onlyBuiltDependencies":["esbuild","lefthook"]}'
t "workspace onlyBuiltDependencies [esbuild, lefthook]" $'onlyBuiltDependencies:\n  - esbuild\n  - lefthook'
t "allowBuilds esbuild: true only" $'allowBuilds:\n  esbuild: true'
t "allowBuilds esbuild: true, lefthook: false" $'allowBuilds:\n  esbuild: true\n  lefthook: false'
t "allowBuilds name-keyed (esbuild, lefthook: true)" $'allowBuilds:\n  esbuild: true\n  lefthook: true'
t "allowBuilds version-keyed lefthook@2.2.2 (lock has 2.2.1)" $'allowBuilds:\n  esbuild: true\n  lefthook@2.2.2: true'
t "allowBuilds version-keyed lefthook@2.2.1 (matches)" $'allowBuilds:\n  esbuild: true\n  lefthook@2.2.1: true'
echo "== done"
