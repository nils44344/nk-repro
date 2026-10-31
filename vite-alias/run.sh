#!/bin/bash
# Vite "Failed to resolve import" for @/ aliases: every common config, built, plus dev server and Vitest.
# Usage: W=<work dir> bash run.sh   (Windows Git Bash or Linux)
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
I="--no-audit --no-fund --loglevel=error"
echo "== $(date) $(uname -s) node $(node -v)"
npm init -y >/dev/null; npm pkg set type=module
npm install -D vite@8 vitest@5 vite-tsconfig-paths typescript $I 2>&1 | tail -1
npx vite --version; npm ls vite-tsconfig-paths vitest 2>&1 | grep -E "tsconfig-paths|vitest@"
mkdir -p src/utils
echo 'export const hello = () => "hi";' > src/utils/hello.js
echo 'import { hello } from "@/utils/hello"; document.body.textContent = hello();' > src/main.js
echo '<!doctype html><script type="module" src="/src/main.js"></script>' > index.html
echo '{"compilerOptions":{"baseUrl":".","paths":{"@/*":["src/*"]},"module":"esnext","moduleResolution":"bundler","allowJs":true}}' > tsconfig.json
echo "== does Vite 8 have a tsconfig paths option?"; grep -o "tsconfigPaths[^,;]*" node_modules/vite/dist/node/index.d.ts | head -3

build() { rm -rf dist; echo "== $1"; printf '%s\n' "$2" > vite.config.js; npx vite build 2>&1 | grep -E "built in|failed to resolve|Failed to resolve|UNRESOLVED|error" | head -3; }
build "no alias, tsconfig paths only" 'export default {}'
build "alias with fileURLToPath (the fix)" 'import { fileURLToPath } from "node:url"; export default { resolve: { alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) } } }'
build "alias as a relative string ./src" 'export default { resolve: { alias: { "@": "./src" } } }'
build "alias as /src" 'export default { resolve: { alias: { "@": "/src" } } }'
build "alias array form" 'import path from "node:path"; export default { resolve: { alias: [{ find: "@", replacement: path.resolve(import.meta.dirname, "src") }] } }'
build "vite-tsconfig-paths plugin" 'import tsconfigPaths from "vite-tsconfig-paths"; export default { plugins: [tsconfigPaths()] }'
build "resolve.tsconfigPaths: true" 'export default { resolve: { tsconfigPaths: true } }'

echo "== dev server without alias: request /src/main.js"
printf '%s\n' 'export default {}' > vite.config.js
(npx vite --port 5288 --strictPort > dev.log 2>&1 &); sleep 8; curl -s -o /dev/null http://localhost:5288/src/main.js; sleep 3
grep -E "Failed to resolve|Does the file" dev.log | head -2
if command -v powershell >/dev/null; then powershell -NoProfile -c 'Get-NetTCPConnection -LocalPort 5288 -State Listen -EA 0 | % { Stop-Process -Id $_.OwningProcess -Force }'; else pkill -f "vite --port 5288"; fi

echo "== vitest: test importing @/ with and without the alias"
mkdir -p test; echo 'import { test, expect } from "vitest"; import { hello } from "@/utils/hello"; test("alias", () => expect(hello()).toBe("hi"));' > test/a.test.js
npx vitest run 2>&1 | grep -E "Failed to (resolve|load)|Tests |Error" | head -2
printf '%s\n' 'import { fileURLToPath } from "node:url"; export default { resolve: { alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) } } }' > vite.config.js
npx vitest run 2>&1 | grep -E "Tests " | head -1

echo "== letter case: file Hello.js imported as @/utils/hello"
mv src/utils/hello.js src/utils/Hello.js
npx vite build 2>&1 | sed 's/\[[0-9;]*m//g' | grep -E "built in|resolve|Rolldown|UNRESOLVED|Could not" | head -4
mv src/utils/Hello.js src/utils/hello.js
echo "== done $(date)"
