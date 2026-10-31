// TS 7.1 beta API probe. Run from a folder with typescript@7.1.0-beta installed: node D:/nk-scratch/ts71-api.mjs
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import { writeFileSync } from 'node:fs';
const require = createRequire(process.cwd() + '/');
const ts = require('typescript');
console.log('require("typescript") keys:', Object.keys(ts).join(', '), '| version', ts.version);
console.log('ts.createProgram:', typeof ts.createProgram, '| ts.transpileModule:', typeof ts.transpileModule);

const { API } = await import(pathToFileURL(require.resolve('typescript/sync')).href);
const t0 = Date.now();
const api = new API({ cwd: process.cwd() });
const out = api.transpileModule('const x: number = 1; export default x;', { module: 'esnext' });
console.log('api.transpileModule ->', JSON.stringify(out.outputText ?? out).slice(0, 120));
writeFileSync('probe.ts', 'const n: number = "not a number";\nexport {};\n');
const program = api.createProgram(['probe.ts'], { strict: true, noEmit: true });
const diags = program.getSemanticDiagnostics();
console.log('semantic diagnostics:', diags.length, 'keys:', Object.keys(diags[0] ?? {}).join(','), JSON.stringify(diags[0]).slice(0, 300));
console.log('elapsed ms', Date.now() - t0);
api.close?.();
