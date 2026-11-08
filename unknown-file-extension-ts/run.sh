#!/bin/bash
# Unknown file extension ".ts" (8 Nov 2026): node file.ts across releases, and .ts inside node_modules,
# both a copied package and an npm-workspaces link (the monorepo case). Node versions run via npx node@X.
set +e
W=${W:-$(pwd)/work}; rm -rf "$W"; mkdir -p "$W"; cd "$W" || exit 1
mkdir -p app/src lib-ts
cat > app/package.json <<'EOF'
{ "name": "app", "version": "1.0.0", "type": "module", "private": true, "workspaces": ["../lib-ts"] }
EOF
echo 'const msg: string = "hello world"; console.log(msg);' > app/src/index.ts
cat > lib-ts/package.json <<'EOF'
{ "name": "lib-ts", "version": "1.0.0", "type": "module", "main": "index.ts" }
EOF
echo 'export const hi = (): string => "hi from lib-ts";' > lib-ts/index.ts
echo 'import { hi } from "lib-ts"; console.log(hi());' > app/src/uses-lib.ts
# copied package (as if installed from a registry)
mkdir -p copied/node_modules/lib-ts && cp lib-ts/* copied/node_modules/lib-ts/ && cp app/package.json copied/ && sed -i 's/"workspaces": \["..\/lib-ts"\]/"workspaces": []/' copied/package.json && mkdir -p copied/src && cp app/src/uses-lib.ts copied/src/
# workspace link
(cd app && npm install --no-audit --no-fund --loglevel=error >/dev/null 2>&1); echo "workspace link: $(ls -la app/node_modules/lib-ts 2>/dev/null | awk '{print $NF}' | tail -1)"
echo "== $(date -u +%F)"
printf '%-9s | %-28s | %-28s | %s\n' node "node src/index.ts" ".ts package, copied" ".ts package, workspace link"
for v in 20.20.2 22.17.1 22.18.0 24.22.2 26.13.0; do
  a=$(cd app && npx -y node@$v src/index.ts 2>&1 | grep -m1 -oE 'ERR_[A-Z_]+|hello world')
  b=$(cd copied && npx -y node@$v src/uses-lib.ts 2>&1 | grep -m1 -oE 'ERR_[A-Z_]+|hi from lib-ts')
  c=$(cd app && npx -y node@$v src/uses-lib.ts 2>&1 | grep -m1 -oE 'ERR_[A-Z_]+|hi from lib-ts')
  printf '%-9s | %-28s | %-28s | %s\n' "$v" "$a" "$b" "$c"
done
echo "-- full message, copied package, Node 24.22.2:"
(cd copied && npx -y node@24.22.2 src/uses-lib.ts 2>&1 | grep -m1 -E 'Error|ERR_' | cut -c1-200)
echo "== done"
