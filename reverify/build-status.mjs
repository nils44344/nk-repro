// Merge status/<post>--<os>.json into status/status.json: { post: { os: run } }. The blog reads this file.
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const dir = join(import.meta.dirname, '..', 'status');
const all = {};
for (const f of readdirSync(dir).filter((f) => f.includes('--') && f.endsWith('.json')).sort()) {
  const run = JSON.parse(readFileSync(join(dir, f), 'utf8'));
  (all[run.post] ??= {})[run.os] = run;
}
writeFileSync(join(dir, 'status.json'), JSON.stringify(all, null, 2) + '\n');
console.log(Object.entries(all).map(([p, o]) => `${p}: ${Object.entries(o).map(([os, r]) => `${os} ${r.allHold ? 'holds' : 'CHANGED'}`).join(', ')}`).join('\n'));
