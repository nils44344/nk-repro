#!/bin/bash
# Follow-up: which Vite version started resolving tsconfig paths in builds, and what dev + Vitest do.
# Run inside the work folder made by run.sh (W=<same dir> bash versions.sh).
set +e
W=${W:-$(pwd)/work}; cd "$W" || exit 1
I="--no-audit --no-fund --loglevel=error"
dev() { # $1 = label; prints the HTTP status for /src/main.js and any resolve error in the log
  (npx vite --port 5288 --strictPort > dev.log 2>&1 &); sleep 9
  code=$(curl -s -o dev-main.js -w "%{http_code}" http://localhost:5288/src/main.js); sleep 2
  echo "dev ($1): HTTP $code | serves @/ import as: $(grep -o 'from "[^"]*hello[^"]*"' dev-main.js | head -1)"
  sed 's/\x1b\[[0-9;]*m//g' dev.log | grep -E "Failed to resolve import|could not be resolved" | head -1 | cut -c1-160
  if command -v powershell >/dev/null; then powershell -NoProfile -c 'Get-NetTCPConnection -LocalPort 5288 -State Listen -EA 0 | % { Stop-Process -Id $_.OwningProcess -Force }'; else pkill -f "vite --port 5288"; fi; sleep 2
}
for V in 8.3.0 8.3.5; do
  echo; echo "######## vite $V, no alias, tsconfig paths only"
  npm install -D vite@$V $I 2>&1 | tail -1
  printf '%s\n' 'export default {}' > vite.config.js
  rm -rf dist; npx vite build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "built in|failed to resolve" | head -1
  dev "no alias"
  npx vitest run 2>&1 | grep -E "Cannot find package|Tests " | head -2
done
echo; echo "######## vite 8.3.5, resolve.tsconfigPaths: true"
printf '%s\n' 'export default { resolve: { tsconfigPaths: true } }' > vite.config.js
rm -rf dist; npx vite build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "built in|failed to resolve" | head -1
dev "tsconfigPaths: true"
npx vitest run 2>&1 | grep -E "Cannot find package|Tests " | head -2
echo "== done $(date)"
