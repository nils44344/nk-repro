#!/bin/bash
# Vitest 4 -> 5: the six changes from the post, each run on vitest 4.1.11 and on the current vitest 5.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v)"
npm init -y >/dev/null; npm pkg set type=module
mkdir -p t sub
cat > t/spy.test.js <<'T'
import { test, expect, vi } from 'vitest';
const spy = vi.fn();
test('first call', () => { spy('a'); expect(spy).toHaveBeenCalledTimes(1); });
test('counts calls across tests', () => { spy('b'); expect(spy).toHaveBeenCalledTimes(2); });
T
cat > t/async.test.js <<'T'
import { test, expect } from 'vitest';
test('unawaited resolves', () => { expect(Promise.resolve(1)).resolves.toBe(1); });
T
cat > t/hoist.test.js <<'T'
import { test, expect, vi } from 'vitest';
function setup() { vi.mock('node:path', () => ({ sep: 'mocked' })); }
setup();
test('runs', () => { expect(1).toBe(1); });
T
cat > t/each.test.js <<'T'
import { test, expect } from 'vitest';
test.each([{ name: 'alice' }])('greets $name', ({ name }) => { expect(`hi ${name}`).toMatchSnapshot(); });
T
cat > t/poll.test.js <<'T'
import { test, expect } from 'vitest';
test('slow poll', async () => { await expect.poll(() => new Promise((r) => setTimeout(() => r(1), 3000)), { timeout: 500 }).toBe(1); });
T
echo 'export default { test: { globals: true } };' > vitest.config.js
echo "test('global', () => { expect(1).toBe(1); });" > sub/g.test.js
r() { env -u CI npx vitest run "$@" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -aE "✓|×|FAIL|Error|AssertionError|not awaited|outside of the module|not at the top level|not defined|didn't resolve|Obsolete|mismatched|written|removed|Tests +[0-9]" | grep -v "^\s*at " | head -${N:-4} | cut -c1-200; }
r_ci() { CI=true npx vitest run "$@" 2>&1 | sed 's/[[0-9;]*m//g' | grep -aE "Obsolete|mismatched|×|✓|Tests +[0-9]" | head -${N:-4} | cut -c1-200; }
for V in 4.1.11 5; do
  npm install -D vitest@$V $Q 2>&1 | tail -1; rm -rf t/__snapshots__/.v5 2>/dev/null
  echo; echo "######## vitest $(npx vitest --version)"
  echo "-- 1 spy across tests"; r t/spy.test.js
  echo "-- 2 unawaited resolves"; r t/async.test.js
  echo "-- 3 vi.mock in a function"; r t/hoist.test.js
  echo "-- 4 config in parent folder, run from sub/"; (cd sub && N=3 r)
  echo "-- 5 test.each title"; N=3 r t/each.test.js
  [ $V != 4.1.11 ] && { echo "-- 5 CI=true with the v4 snapshot"; git -C . status >/dev/null 2>&1; cp t/__snapshots__/each.test.js.snap.v4 t/__snapshots__/each.test.js.snap; N=4 r_ci t/each.test.js; echo "-- 5 -u"; N=3 r t/each.test.js -u; }
  [ $V = 4.1.11 ] && cp t/__snapshots__/each.test.js.snap t/__snapshots__/each.test.js.snap.v4
  echo "-- 6 slow expect.poll"; r t/poll.test.js
done
echo "== done"
