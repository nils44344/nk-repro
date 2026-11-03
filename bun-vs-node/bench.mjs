// Startup, TypeScript file and 300-test timings via spawnSync (includes process creation), medians; then CPU tasks.
import { spawnSync } from "node:child_process"; import { writeFileSync } from "node:fs";
const med = (a) => a.sort((x, y) => x - y)[Math.floor(a.length / 2)];
const time = (cmd, args, n) => med(Array.from({ length: n }, () => { const s = performance.now(); const r = spawnSync(cmd, args, { stdio: "ignore" }); if (r.status) throw new Error(cmd + " " + args + " exit " + r.status); return performance.now() - s; }));
writeFileSync("empty.js", ""); writeFileSync("t.ts", "interface P { x: number; y: number }\nconst p: P = { x: 1, y: 2 };\nconsole.log(p.x + p.y);\n");
let tests = 'import { test } from "node:test"; import assert from "node:assert";\n';
for (let i = 0; i < 300; i++) tests += `test("t${i}", () => { assert.strictEqual([${i},1,2].map(x => x * 2).reduce((a, b) => a + b), ${i * 2 + 6}); });\n`;
writeFileSync("x.test.mjs", tests);
const rows = [["startup", ["node", ["empty.js"]], ["bun", ["empty.js"]], 30], ["typescript file", ["node", ["t.ts"]], ["bun", ["t.ts"]], 20], ["300 tests", ["node", ["--test", "x.test.mjs"]], ["bun", ["test", "./x.test.mjs"]], 7]];
for (const [name, n, b, k] of rows) console.log(`${name}: node ${time(...n, k).toFixed(1)} ms | bun ${time(...b, k).toFixed(1)} ms (median of ${k})`);
for (const rt of ["node", "bun"]) { const out = Array.from({ length: 5 }, () => spawnSync(rt, ["cpu.mjs"], { encoding: "utf8" }).stdout.trim().split("\n").map((l) => l.split(" ")));
  for (let i = 0; i < 3; i++) console.log(`${rt} ${out[0][i][0]}: ${med(out.map((o) => +o[i][1])).toFixed(0)} ms (median of 5), checksum ${out[0][i][2]}`); }
