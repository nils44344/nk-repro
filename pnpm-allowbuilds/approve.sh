#!/bin/bash
# pnpm 12: non-interactive ways out of ERR_PNPM_IGNORED_BUILDS (9 Nov 2026).
set +e
W=${W:-$(pwd)/work-a}; rm -rf "$W"; mkdir -p "$W"; cd "$W" || exit 1
PN="npx -y pnpm@12.18.0"
echo "== $(date -u +%F) node $(node -v) pnpm $($PN -v)"
mk() { rm -rf p && mkdir p && cd p && printf '{"name":"p","version":"1.0.0","private":true,"dependencies":{"esbuild":"0.28.2","lefthook":"2.2.1"}}\n' > package.json; }
echo "### 1. install fails, then pnpm approve-builds --all"
mk; $PN install --reporter=append-only >/dev/null 2>&1; echo "first install exit $?"
$PN approve-builds --all 2>&1 | tail -3; echo "approve-builds exit $?"
echo "pnpm-workspace.yaml after:"; cat pnpm-workspace.yaml 2>/dev/null | sed 's/^/   /'
rm -rf node_modules; $PN install --reporter=append-only >/dev/null 2>&1; echo "clean install after approve: exit $?"
cd ..
echo "### 2. strictDepBuilds: false"
mk; printf 'strictDepBuilds: false\n' > pnpm-workspace.yaml
out=$($PN install --reporter=append-only 2>&1); echo "install exit $? | $(echo "$out" | grep -m1 -iE 'ignored build|WARN' | cut -c1-160)"
cd ..
echo "### 3. CI env var"
mk; out=$(CI=true $PN install --reporter=append-only 2>&1); echo "CI=true install exit $? | $(echo "$out" | grep -m1 -oE 'ERR_PNPM_[A-Z_]+')"
echo "== done"
