#!/bin/bash
# TS1294 erasableSyntaxOnly across TypeScript 5.9 / 6.0 / 7.0 and Node's own TypeScript support (Nov 2026).
set +e
W=${W:-/tmp/erasable}; rm -rf $W; mkdir -p $W/src; cd $W
cat > src/a.ts <<'T'
enum Status { Active, Inactive }
namespace NS { export const x = 1; }
class P { constructor(private id: number) {} get v() { return this.id; } }
console.log(Status.Active, Status.Inactive, NS.x, new P(1).v);
T
cat > src/b.ts <<'T'
export const Status = { Active: 0, Inactive: 1 } as const;
export type Status = (typeof Status)[keyof typeof Status];
class P { id: number; constructor(id: number) { this.id = id; } }
console.log(Status.Active, Status.Inactive, 'a#' + new P(1).id);
T
echo '{"type":"module"}' > package.json
echo "node $(node -v)"
for ts in 5.9.3 6.0.3 7.0.2; do
  echo "== tsc $ts --erasableSyntaxOnly (a.ts: enum, namespace, parameter property)"
  npx -y -p typescript@$ts tsc --version
  npx -y -p typescript@$ts tsc --noEmit --strict --erasableSyntaxOnly --module nodenext --target es2022 src/a.ts 2>&1 | grep -oE "error TS[0-9]+: .*" | sort | uniq -c
  echo "-- b.ts (rewritten):"; npx -y -p typescript@$ts tsc --noEmit --strict --erasableSyntaxOnly --module nodenext --target es2022 src/b.ts && echo "b.ts OK"
done
echo "== node src/a.ts (strip-only)"; node src/a.ts 2>&1 | grep -E "Error|^[0-9]" | head -2
echo "== node --experimental-transform-types src/a.ts"; node --experimental-transform-types src/a.ts 2>&1 | grep -vE "ExperimentalWarning|trace-warnings" | head -2
echo "== node src/b.ts"; node src/b.ts 2>&1 | head -1
