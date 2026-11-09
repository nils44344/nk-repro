#!/bin/bash
# pnpm 10 vs 11 vs 12: which build-approval key does each read, and what does a clean install do? (9 Nov 2026)
set +e
W=${W:-$(pwd)/work-v}; rm -rf "$W"; mkdir -p "$W"; cd "$W" || exit 1
echo "== $(date -u +%F) node $(node -v)"
for V in 10 11 12; do
  PN="npx -y pnpm@$V"
  echo "### pnpm $($PN -v)"
  t() {
    rm -rf p && mkdir p && cd p
    printf '{"name":"p","version":"1.0.0","private":true,"dependencies":{"esbuild":"0.28.2"}%s}\n' "$3" > package.json
    [ -n "$2" ] && printf '%s\n' "$2" > pnpm-workspace.yaml
    out=$($PN install --reporter=append-only 2>&1); e=$?
    ran=$( [ -f node_modules/esbuild/bin/esbuild ] && node -e "require('child_process').execFileSync(require.resolve('esbuild/bin/esbuild'),['--version'],{stdio:'pipe'})" 2>/dev/null && echo "esbuild runs" || echo "esbuild binary check failed")
    printf '  %-48s | exit %s | %-26s | %s\n' "$1" "$e" "$(echo "$out" | grep -m1 -oE 'ERR_PNPM_[A-Z_]+|Ignored build scripts[^.]*|WARN[^:]*ignored[^.]*' | head -1 | cut -c1-40)" "$ran"
    cd ..
  }
  t "no setting" ""
  t "package.json pnpm.onlyBuiltDependencies" "" ',"pnpm":{"onlyBuiltDependencies":["esbuild"]}'
  t "workspace onlyBuiltDependencies" $'onlyBuiltDependencies:\n  - esbuild'
  t "workspace allowBuilds esbuild: true" $'allowBuilds:\n  esbuild: true'
done
echo "== done"
