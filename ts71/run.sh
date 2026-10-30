#!/bin/bash
# TS 7.1 release day: the same 9-tool matrix as ts7-retest, on TSV (default: the beta tag). Usage: TSV=7.1.0 bash run.sh
export NODE_EXTRA_CA_CERTS=D:/tools/ca-bundle-win.pem
set +e
TSV=${TSV:-beta}; W=D:/nk-ts71/p; rm -rf $W; mkdir -p $W/src $W/test; cd $W
echo 'export const add = (a: number, b: number): number => a + b; console.log(add(1, 2));' > src/index.ts
echo 'import { add } from "../src/index"; test("add", () => { expect(add(1, 2)).toBe(3); });' > test/add.test.ts
echo '{"compilerOptions":{"target":"es2022","module":"commonjs","strict":true,"esModuleInterop":true,"types":["jest","node"]},"include":["src","test"]}' > tsconfig.json
echo 'module.exports={preset:"ts-jest",testEnvironment:"node"};' > jest.config.cjs
cat > eslint.config.mjs <<'E2'
import tseslint from "typescript-eslint";
export default tseslint.config(...tseslint.configs.recommendedTypeChecked, { languageOptions: { parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname } } }, { ignores: ["*.cjs", "*.mjs"] });
E2
npm init -y >/dev/null
echo "== strict install, typescript $TSV + latest tools"
npm install -D typescript@$TSV ts-jest@latest jest@latest @types/jest @types/node typescript-eslint@latest eslint@10 ts-node@latest typedoc@latest --no-audit --no-fund 2>&1 | grep -E "code|ERESOLVE|peer typescript|Could not resolve" | head -6
echo "== legacy-peer-deps install"
npm install -D typescript@$TSV ts-jest@latest jest@latest @types/jest @types/node typescript-eslint@latest eslint@10 ts-node@latest typedoc@latest --legacy-peer-deps --no-audit --no-fund --loglevel=error 2>&1 | tail -2
npx tsc --version
echo "== ts-jest"; npx jest 2>&1 | grep -iE "typescript|error|pass|fail" | head -6
echo "== typescript-eslint"; npx eslint src 2>&1 | head -4
echo "== ts-node"; npx ts-node src/index.ts 2>&1 | grep -E "Error|^3" | head -3
echo "== typedoc"; npx typedoc src/index.ts --out docs 2>&1 | grep -iE "error|generated" | head -3
echo "== npm install @typescript/native (the name in the ts-jest message)"
npm install -D @typescript/native --no-audit --no-fund 2>&1 | grep -E "code|404" | head -3
echo "== side-by-side aliases"
npm install -D "@typescript/native@npm:typescript@$TSV" "typescript@npm:@typescript/typescript6@^6.0.2" --legacy-peer-deps --no-audit --no-fund --loglevel=error 2>&1 | tail -2
rm -rf node_modules; npm install --no-audit --no-fund --loglevel=error 2>&1 | tail -3
echo "tsc from @typescript/native: $(node node_modules/@typescript/native/bin/tsc --version)"
echo "== ts-jest"; npx jest 2>&1 | grep -iE "typescript|error|pass|fail|Tests:" | head -6
echo "== typescript-eslint"; npx eslint src 2>&1 | head -4; echo "eslint exit $?"
echo "== ts-node"; npx ts-node src/index.ts 2>&1 | head -2
echo "== typedoc"; npx typedoc src/index.ts --out docs 2>&1 | grep -iE "error|generated" | head -3
