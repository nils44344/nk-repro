#!/bin/bash
# typescript-eslint on TypeScript 7: the ERESOLVE, the "does not support TS 7.0" error after forcing it, and the
# side-by-side alias fix (typescript 7 as @typescript/native, typescript 6 compat package as "typescript").
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund"
echo "== $(date) node $(node -v) npm $(npm -v)"
echo "typescript-eslint latest $(npm view typescript-eslint version), peer typescript: $(npm view typescript-eslint peerDependencies.typescript)"
app() { rm -rf $1; mkdir -p $1/src && cd $1 && npm init -y >/dev/null && npm pkg set type=module
  printf 'import tseslint from "typescript-eslint";\nexport default tseslint.config(...tseslint.configs.recommended);\n' > eslint.config.mjs
  echo 'export const add = (a: number, b: number): number => a + b;' > src/index.ts
  echo '{ "compilerOptions": { "strict": true, "module": "nodenext", "target": "es2022", "noEmit": true }, "include": ["src"] }' > tsconfig.json; }
app strict; echo "######## strict install: typescript@7 + typescript-eslint"
npm install -D typescript@7 typescript-eslint eslint@10 $Q 2>&1 | grep -E "code|While resolving|Found: typescript|peer typescript" | head -4 | cut -c1-200
cd ..; app legacy; echo "######## --legacy-peer-deps, then eslint"
npm install -D typescript@7 typescript-eslint eslint@10 --legacy-peer-deps $Q 2>&1 | tail -1
npx eslint src 2>&1 | grep -E "does not support|See also|Error" | head -2 | cut -c1-200; echo "   eslint exit ${PIPESTATUS[0]}"
cd ..; app fix; echo "######## fix: aliases"
npm install -D "@typescript/native@npm:typescript@7" "typescript@npm:@typescript/typescript6@^6.0.2" typescript-eslint eslint@10 $Q 2>&1 | grep -E "added|ERESOLVE|code" | head -2
npx eslint src; echo "   eslint exit $?"
echo "   tsc: $(npx tsc --version)  | node_modules/typescript is $(node -p 'require("./node_modules/typescript/package.json").version')"
echo "   versions: typescript-eslint $(node -p 'require("./node_modules/typescript-eslint/package.json").version'), eslint $(npx eslint --version)"
cd ..; echo "== done"
