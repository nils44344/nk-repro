#!/bin/bash
# ERR_MODULE_NOT_FOUND in ES modules (8 Nov 2026): extensionless and folder imports, and the TypeScript twist:
# tsc wants './greet.js', Node's own type stripping wants './greet.ts', and rewriteRelativeImportExtensions joins them.
set +e
W=${W:-$(pwd)/work}; rm -rf "$W"; mkdir -p "$W/src/lib"; cd "$W" || exit 1
npm init -y >/dev/null; npm pkg set type=module
npm i -D typescript@latest @types/node --no-audit --no-fund --loglevel=error >/dev/null 2>&1
echo "== $(date -u +%F) node $(node -v) typescript $(npx tsc -v | awk '{print $2}')"
echo 'export const add = (a, b) => a + b;' > src/utils.js
echo 'export const mul = (a, b) => a * b;' > src/lib/index.js
r(){ printf '%-52s | ' "$1"; shift; "$@" > o.txt 2>&1; e=$?; out=$(grep -m1 -oE "ERR_[A-Z_]+|^[0-9]+$|error TS[0-9]+[^.]*|SyntaxError[^\n]{0,60}" o.txt); echo "exit $e | ${out:-$(head -1 o.txt | cut -c1-90)}"; }
echo "import { add } from './utils'; console.log(add(2, 3));" > src/a.js
echo "import { add } from './utils.js'; console.log(add(2, 3));" > src/b.js
echo "import { mul } from './lib'; console.log(mul(2, 3));" > src/c.js
echo "import { mul } from './lib/index.js'; console.log(mul(2, 3));" > src/d.js
r "import './utils'" node src/a.js
r "import './utils.js'" node src/b.js
r "import './lib' (folder)" node src/c.js
r "import './lib/index.js'" node src/d.js
r "--experimental-specifier-resolution=node './utils'" node --experimental-specifier-resolution=node src/a.js
echo "### TypeScript files"
mkdir -p ts && echo 'export const hi = (): string => "hi";' > ts/greet.ts
for spec in greet greet.js greet.ts; do echo "import { hi } from './$spec'; console.log(hi());" > "ts/main-$spec.ts"; done
r "node ts/main-greet.ts      (import './greet')" node ts/main-greet.ts
r "node ts/main-greet.js.ts   (import './greet.js')" node ts/main-greet.js.ts
r "node ts/main-greet.ts.ts   (import './greet.ts')" node ts/main-greet.ts.ts
printf '{"compilerOptions":{"module":"nodenext","target":"es2022","outDir":"out","types":["node"],"rootDir":"ts"},"include":["ts/greet.ts","ts/main-greet.ts.ts"]}' > tsconfig.json
r "tsc on import './greet.ts' (plain nodenext)" npx tsc -p tsconfig.json
printf '{"compilerOptions":{"module":"nodenext","target":"es2022","outDir":"out","types":["node"],"rootDir":"ts","rewriteRelativeImportExtensions":true},"include":["ts/greet.ts","ts/main-greet.ts.ts"]}' > tsconfig.json
r "tsc + rewriteRelativeImportExtensions" npx tsc -p tsconfig.json
echo "   compiled import line: $(grep -o "from '[^']*'" out/main-greet.ts.js 2>/dev/null)"
r "node out/main-greet.ts.js (compiled)" node out/main-greet.ts.js
echo "== done"
