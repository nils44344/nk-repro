#!/bin/bash
# TypeScript 7 migration: each tsconfig option 6.0 deprecated, on tsc 6 and tsc 7; ignoreDeprecations; the 6.0 defaults.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v)"
for V in 5 6 7; do mkdir -p t$V && (cd t$V && npm init -y >/dev/null && npm install -D typescript@$V $Q >/dev/null 2>&1; echo "tsc $V: $(npx tsc -v)"); done
mkdir -p p && cd p && echo 'export const a: number = 1;' > a.ts
t() { echo "$1" > tsconfig.json; for V in 5 6 7; do echo "   tsc$V: $(../t$V/node_modules/.bin/tsc -p . --noEmit 2>&1 | grep -oE 'error TS[0-9]+: [^.]*' | head -1 | cut -c1-110)"; done; }
base='"strict": true, "module": "esnext", "moduleResolution": "bundler", "target": "es2022"'
while IFS='|' read -r label opts; do
  echo "-- $label"; t "{ \"compilerOptions\": { $opts }, \"files\": [\"a.ts\"] }"
done <<'CASES'
baseUrl|"strict": true, "module": "esnext", "moduleResolution": "bundler", "target": "es2022", "baseUrl": "."
target es5|"strict": true, "module": "esnext", "moduleResolution": "bundler", "target": "es5"
moduleResolution node10|"strict": true, "module": "commonjs", "moduleResolution": "node10", "target": "es2022"
moduleResolution classic|"strict": true, "module": "esnext", "moduleResolution": "classic", "target": "es2022"
module amd|"strict": true, "module": "amd", "target": "es2022"
module umd|"strict": true, "module": "umd", "target": "es2022"
module system|"strict": true, "module": "system", "target": "es2022"
module none|"strict": true, "module": "none", "target": "es2022"
outFile|"strict": true, "module": "esnext", "moduleResolution": "bundler", "target": "es2022", "outFile": "out.js"
esModuleInterop false|"strict": true, "module": "commonjs", "moduleResolution": "bundler", "target": "es2022", "esModuleInterop": false
allowSyntheticDefaultImports false|"strict": true, "module": "esnext", "moduleResolution": "bundler", "target": "es2022", "allowSyntheticDefaultImports": false
downlevelIteration|"strict": true, "module": "esnext", "moduleResolution": "bundler", "target": "es2022", "downlevelIteration": true
alwaysStrict false|"strict": true, "module": "esnext", "moduleResolution": "bundler", "target": "es2022", "alwaysStrict": false
baseUrl + ignoreDeprecations 6.0|"strict": true, "module": "esnext", "moduleResolution": "bundler", "target": "es2022", "baseUrl": ".", "ignoreDeprecations": "6.0"
suppressImplicitAnyIndexErrors|"strict": true, "module": "esnext", "moduleResolution": "bundler", "target": "es2022", "suppressImplicitAnyIndexErrors": true
CASES
echo "######## defaults (no strict, no types in tsconfig)"
echo 'export function f(x) { return x; }' > b.ts; echo 'process.exit(0);' > c.ts
npm init -y >/dev/null; npm install -D @types/node $Q >/dev/null 2>&1
echo "-- implicit any parameter"; t '{ "compilerOptions": { "module": "esnext", "moduleResolution": "bundler", "target": "es2022" }, "files": ["b.ts"] }'
echo "-- @types/node installed, process used"; t '{ "compilerOptions": { "module": "esnext", "moduleResolution": "bundler", "target": "es2022" }, "files": ["c.ts"] }'
echo "== done"
