#!/bin/bash
# bun check vs tsc 6 / tsc 7 on Zod @680d19f and Hono @588ec13: time, error count, same errors; and the trap where a
# "check" script in package.json makes `bun check` run that script instead of type-checking.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
echo "== $(date -u) $(uname -s) node $(node -v) bun $(bun -v), $(nproc) cpus"
mkdir -p ts6 ts7 && (cd ts6 && npm init -y >/dev/null && npm i -D typescript@6.0.3 --no-audit --no-fund --loglevel=error >/dev/null 2>&1) && (cd ts7 && npm init -y >/dev/null && npm i -D typescript@7.0.2 --no-audit --no-fund --loglevel=error >/dev/null 2>&1)
TSC6=$W/ts6/node_modules/.bin/tsc; TSC7=$W/ts7/node_modules/.bin/tsc; echo "tsc6 $($TSC6 -v) tsc7 $($TSC7 -v)"
tm() { local s=$(date +%s.%N); "$@" > out.txt 2>&1; local e=$(date +%s.%N); printf '%.1f s, %s errors' $(echo "$e - $s" | bc) $(grep -cE "error TS[0-9]+" out.txt); }
run() { # $1 repo $2 commit $3 dir $4 extra args
  git clone -q https://github.com/$1 $3 && cd $3 && git checkout -q $2 && (bun install >/dev/null 2>&1 || npm install --no-audit --no-fund --loglevel=error >/dev/null 2>&1)
  echo "-- $1 @ $2"; echo "   tsc 6.0.3 $4: $(tm $TSC6 $4 --noEmit)"
  echo "   tsc 7.0.2 $4: $(tm $TSC7 $4 --noEmit)"; grep -oE "^[^(]+\([0-9]+,[0-9]+\): error TS[0-9]+" out.txt | sort > ../tsc7-$3.txt
  echo "   bun check $4: $(tm bun check $4)"; grep -oE "^[^(]+\([0-9]+,[0-9]+\): error TS[0-9]+|^[^ :]+:[0-9]+:[0-9]+ - error TS[0-9]+" out.txt | sed -E 's/:([0-9]+):([0-9]+) - /(\1,\2): /' | sort > ../bun-$3.txt
  echo "   tsc 7 vs bun check, same error lines: $(diff -q ../tsc7-$3.txt ../bun-$3.txt >/dev/null && echo yes || echo "no ($(diff ../tsc7-$3.txt ../bun-$3.txt | grep -c '^[<>]') lines differ)")"
  cd $W; }
run colinhacks/zod 680d19f zod ""
run honojs/hono 588ec13 hono "-b"
echo "######## the trap: a \"check\" script"
mkdir -p trap && cd trap && npm init -y >/dev/null && npm pkg set scripts.check="echo RAN-THE-CHECK-SCRIPT"
echo 'const n: number = "oops"; export {};' > a.ts; echo '{ "compilerOptions": { "strict": true, "noEmit": true }, "files": ["a.ts"] }' > tsconfig.json
echo "-- bun check with a check script: $(bun check 2>&1 | grep -aoE 'RAN-THE-CHECK-SCRIPT|error TS[0-9]+' | head -1)"
npm pkg delete scripts.check; echo "-- bun check without it: $(bun check 2>&1 | grep -aoE 'RAN-THE-CHECK-SCRIPT|error TS[0-9]+' | head -1)"
echo "== done"
