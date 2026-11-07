#!/bin/bash
# Re-test TS7 tool compatibility with latest tool versions (29 Oct 2026)
[ -f D:/tools/ca-bundle-win.pem ] && export NODE_EXTRA_CA_CERTS=D:/tools/ca-bundle-win.pem
set +e
W=${W:-D:/nk-ts7r/p}; rm -rf $W; mkdir -p $W/src $W/test; cd $W
echo 'export const add = (a: number, b: number): number => a + b; console.log(add(1, 2));' > src/index.ts
echo 'import { add } from "../src/index"; test("add", () => { expect(add(1, 2)).toBe(3); });' > test/add.test.ts
echo '{"compilerOptions":{"target":"es2022","module":"commonjs","strict":true,"esModuleInterop":true,"types":["jest","node"]},"include":["src","test"]}' > tsconfig.json
echo 'module.exports={preset:"ts-jest",testEnvironment:"node"};' > jest.config.cjs
cat > eslint.config.mjs <<'E2'
import tseslint from "typescript-eslint";
export default tseslint.config(...tseslint.configs.recommendedTypeChecked, { languageOptions: { parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname } } }, { ignores: ["*.cjs", "*.mjs"] });
E2
npm init -y >/dev/null
echo "== strict install, typescript 7.0.2 + latest tools"
npm install -D typescript@${TS:-7.0.2} ts-jest@${TOOLS:-29.4.15} jest@30.5.2 @types/jest @types/node typescript-eslint@${TOOLS:-8.72.1} eslint@10 ts-node@${TOOLS:-10.9.2} typedoc@${TOOLS:-0.28.20} --no-audit --no-fund 2>&1 | grep -E "code|ERESOLVE|peer typescript|Could not resolve" | head -6
echo "== legacy-peer-deps install"
npm install -D typescript@${TS:-7.0.2} ts-jest@${TOOLS:-29.4.15} jest@30.5.2 @types/jest @types/node typescript-eslint@${TOOLS:-8.72.1} eslint@10 ts-node@${TOOLS:-10.9.2} typedoc@${TOOLS:-0.28.20} --legacy-peer-deps --no-audit --no-fund --loglevel=error 2>&1 | tail -2
npx tsc --version
npm ls ts-jest typescript-eslint ts-node typedoc --depth=0 2>/dev/null | tail -5
echo "== ts-jest"; npx jest 2>&1 | grep -iE "typescript|error|pass|fail" | head -6
echo "== typescript-eslint"; npx eslint src 2>&1 | head -4
echo "== ts-node"; npx ts-node src/index.ts 2>&1 | grep -E "Error|^3" | head -3
echo "== typedoc"; npx typedoc src/index.ts --out docs 2>&1 | grep -iE "error|generated" | head -3
echo "== alternatives on plain TypeScript 7 (before side-by-side)"
npm install -D tsx --no-audit --no-fund --loglevel=error >/dev/null 2>&1
echo "tsx $(npm ls tsx --depth=0 2>/dev/null | grep -o 'tsx@[0-9.]*'): $(npx tsx src/index.ts 2>&1 | head -1)"
echo "node $(node -v) src/index.ts: $(node src/index.ts 2>&1 | grep -vi warning | head -1)"
echo "ts-node latest on npm: $(npm view ts-node version)"
echo "== npm install @typescript/native (the name in the ts-jest message)"
npm install -D @typescript/native --no-audit --no-fund 2>&1 | grep -E "code|404" | head -3
echo "== side-by-side aliases"
npm install -D "@typescript/native@npm:typescript@${TS:-7.0.2}" "typescript@npm:@typescript/typescript6@^6.0.2" --legacy-peer-deps --no-audit --no-fund --loglevel=error 2>&1 | tail -2
rm -rf node_modules; npm install --no-audit --no-fund --loglevel=error 2>&1 | tail -3
echo "tsc from @typescript/native: $(node node_modules/@typescript/native/bin/tsc --version)"
echo "== ts-jest"; npx jest 2>&1 | grep -iE "typescript|error|pass|fail|Tests:" | head -6
echo "== typescript-eslint"; npx eslint src 2>&1 | head -4; echo "eslint exit $?"
echo "== ts-node"; npx ts-node src/index.ts 2>&1 | head -2
echo "== typedoc"; npx typedoc src/index.ts --out docs 2>&1 | grep -iE "error|generated" | head -3
echo "== after side-by-side: tsc"; npx tsc --version; npx tsc -p . --noEmit && echo "tsc --noEmit OK"
echo "== after side-by-side: ts-jest"; npx jest 2>&1 | grep -E "Tests:|FAIL|PASS" | head -3
echo "== after side-by-side: typescript-eslint"; npx eslint src && echo "eslint OK"
echo "== after side-by-side: ts-node"; npx ts-node src/index.ts 2>&1 | head -2
echo "== after side-by-side: typedoc"; npx typedoc src/index.ts --out docs 2>&1 | grep -iE "error|generated" | head -2
