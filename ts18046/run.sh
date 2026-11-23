#!/bin/bash
# TS18046 "'error' is of type 'unknown'" in catch: which TypeScript versions and configs raise it, and which fixes pass.
# Each TypeScript version runs from npx in a fresh folder. No accounts, no keys.
set +e
VERS=${VERS:-"5.9.3 6.0.3 7.0.2 7.1.0-beta"}
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
export npm_config_update_notifier=false
echo "== $(uname -s) | node $(node -v)"
tsc_() { npx -y -p typescript@$V tsc "$@" 2>&1 | sed -E 's/\x1b\[[0-9;]*m//g'; return ${PIPESTATUS[0]}; }
new() { rm -rf "$W/p"; mkdir -p "$W/p"; cd "$W/p" || exit 1; }
base='try { JSON.parse("{") } catch (error) { console.log(error.message) }'
for V in $VERS; do
  echo; echo "########## typescript $V ($(npx -y -p typescript@$V tsc -v 2>&1 | tail -1))"
  new; echo "$base" > a.ts
  echo "-- 1a. tsc a.ts (no tsconfig)"; tsc_ --noEmit a.ts | head -4; echo "   exit ${PIPESTATUS[0]}"
  echo "-- 1b. tsconfig from tsc --init"; tsc_ --init > /dev/null; grep -E '"(strict|useUnknownInCatchVariables)"' tsconfig.json | sed -E 's/^\s+//' | tr '\n' ' '; echo; tsc_ --noEmit -p . | head -4; echo "   exit ${PIPESTATUS[0]}"
  echo "-- 1c. tsconfig with no strict key"; printf '{ "compilerOptions": { "noEmit": true }, "files": ["a.ts"] }\n' > tsconfig.json; tsc_ -p . | head -4; echo "   exit ${PIPESTATUS[0]}"
  echo "-- 1d. strict: false"; printf '{ "compilerOptions": { "noEmit": true, "strict": false }, "files": ["a.ts"] }\n' > tsconfig.json; tsc_ -p . | head -4; echo "   exit ${PIPESTATUS[0]}"
  printf '{ "compilerOptions": { "noEmit": true, "strict": true }, "files": ["a.ts"] }\n' > tsconfig.json
  t() { echo "-- $1"; echo "$2" > a.ts; tsc_ -p . | head -4; echo "   exit ${PIPESTATUS[0]}"; }
  t "2. instanceof Error" 'try { JSON.parse("{") } catch (error) { if (error instanceof Error) console.log(error.message) }'
  t "3. helper getErrorMessage(e: unknown)" 'function getErrorMessage(e: unknown): string { if (e instanceof Error) return e.message; return String(e) }
try { JSON.parse("{") } catch (error) { console.log(getErrorMessage(error)) }'
  t "4a. catch (error: any)" 'try { JSON.parse("{") } catch (error: any) { console.log(error.message) }'
  t "4b. catch (error: Error)" 'try { JSON.parse("{") } catch (error: Error) { console.log(error.message) }'
  t "5. useUnknownInCatchVariables: false (strict on)" "$base"; printf '{ "compilerOptions": { "noEmit": true, "strict": true, "useUnknownInCatchVariables": false }, "files": ["a.ts"] }\n' > tsconfig.json; tsc_ -p . | head -4; echo "   exit ${PIPESTATUS[0]} (with useUnknownInCatchVariables false)"
  printf '{ "compilerOptions": { "noEmit": true, "strict": true, "lib": ["es2022"] }, "files": ["a.ts"] }\n' > tsconfig.json
  t "6. promise .catch((e) => e.message)" 'Promise.reject(new Error("x")).catch((e) => console.log(e.message))'
  t "8. error.cause narrowing" 'try { JSON.parse("{") } catch (error) { if (error instanceof Error && error.cause instanceof Error) console.log(error.cause.message) }'
done

echo; echo "########## 7. what instanceof misses at run time (node $(node -v), type stripping)"
new
cat > b.ts <<'B'
function getErrorMessage(e: unknown): string { if (e instanceof Error) return e.message; return String(e) }
for (const thrown of [new Error("an Error"), "a string", { message: "an object with message" }]) {
  try { throw thrown } catch (error) {
    console.log(JSON.stringify(thrown), "| instanceof Error:", error instanceof Error, "| helper:", getErrorMessage(error))
  }
}
B
node b.ts 2>&1 | grep -v ExperimentalWarning | head -6; echo "   exit ${PIPESTATUS[0]}"
echo; echo "== done"
