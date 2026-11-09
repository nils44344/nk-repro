#!/bin/bash
# jsdom 31 changed its optional canvas backend from `canvas` to `@napi-rs/canvas` (9 Nov 2026).
# Which install makes HTMLCanvasElement.getContext('2d') work, on jsdom 30 and 31, plain and under Vitest?
set +e
W=${W:-$(pwd)/work}; rm -rf "$W"; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
cat > probe.cjs <<'JS'
const { JSDOM, VirtualConsole } = require('jsdom');
const vc = new VirtualConsole(); const errs = [];
vc.on('jsdomError', (e) => errs.push(e.message.split('\n')[0]));
const dom = new JSDOM('<canvas id="c" width="10" height="10"></canvas>', { virtualConsole: vc });
const ctx = dom.window.document.getElementById('c').getContext('2d');
console.log(`getContext('2d'): ${ctx ? 'a context (' + ctx.constructor.name + ')' : 'null'}${errs.length ? ' | jsdomError: ' + errs[0] : ''}`);
JS
cat > c.test.js <<'JS'
import { test, expect } from 'vitest';
test('canvas', () => { const c = document.createElement('canvas'); const ctx = c.getContext('2d'); console.log('vitest getContext:', ctx ? 'a context' : 'null'); expect(ctx).not.toBeNull(); });
JS
echo "== $(date -u +%F) node $(node -v) $(uname -s)"
for J in 30 31; do
  for B in none canvas @napi-rs/canvas; do
    d="j$J-$(echo $B | tr '/@' '__')"; mkdir -p $d && cd $d && npm init -y >/dev/null && npm pkg set type=commonjs >/dev/null
    npm i jsdom@$J $Q >/dev/null 2>&1
    [ $B != none ] && npm i $B $Q >/dev/null 2>&1
    jv=$(node -p "require('jsdom/package.json').version")
    bv=$([ $B != none ] && node -p "require('$B/package.json').version" 2>/dev/null || echo -)
    printf 'jsdom %-7s | backend %-17s %-8s | %s\n' "$jv" "$B" "$bv" "$(cp ../probe.cjs . && node probe.cjs 2>&1 | grep -m1 -E "getContext|Error" | cut -c1-170)"
    cd ..
  done
done
echo "### Vitest 5 (environment jsdom), jsdom 31"
mkdir -p vt && cd vt && npm init -y >/dev/null && npm pkg set type=module >/dev/null
npm i -D vitest@5 jsdom@31 $Q >/dev/null 2>&1; cp ../c.test.js .
r1=$(npx vitest run --environment jsdom 2>&1 | grep -m2 -E "getContext|Not implemented|passed|failed" | tr '\n' ' ' | cut -c1-200); echo "no backend      | $r1"
npm i -D @napi-rs/canvas $Q >/dev/null 2>&1
r2=$(npx vitest run --environment jsdom 2>&1 | grep -m2 -E "getContext|Not implemented|passed|failed" | tr '\n' ' ' | cut -c1-200); echo "@napi-rs/canvas | $r2"
echo "== done"
