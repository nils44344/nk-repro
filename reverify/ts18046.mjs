// Re-checks https://nilaykabariya.blog/fixes/typescript-error-is-of-type-unknown-ts18046 on the newest TypeScript.
import { sh, tmp, files, check, record } from './lib.mjs';

const POST = 'typescript-error-is-of-type-unknown-ts18046';
const latest = sh('npm view typescript dist-tags.latest').trim();
const tsc = `npx -y -p typescript@${latest} tsc`;
const code = 'try { JSON.parse("{") } catch (error) { console.log(error.message) }\n';
const fixed = 'try { JSON.parse("{") } catch (error) { if (error instanceof Error) console.log(error.message) }\n';
const proj = (name, tsconfig, src = code) => {
  const d = tmp(name);
  files(d, { 'a.ts': src, ...(tsconfig ? { 'tsconfig.json': tsconfig } : {}) });
  return d;
};
const opts = { target: 'es2022', module: 'esnext', lib: ['es2022', 'dom'], noEmit: true };

const checks = [
  check('no strict key: TS18046', () => sh(`${tsc} -p .`, proj('nostrict', { compilerOptions: opts })), (o) => /TS18046/.test(o)),
  check('"strict": false: no error', () => sh(`${tsc} -p . && echo TSC_OK`, proj('sfalse', { compilerOptions: { ...opts, strict: false } })), (o) => /TSC_OK/.test(o) && !/TS18046/.test(o)),
  check('instanceof Error fix compiles with strict on', () => sh(`${tsc} -p . && echo TSC_OK`, proj('fix', { compilerOptions: { ...opts, strict: true } }, fixed)), (o) => /TSC_OK/.test(o)),
];
const ok = record(POST, { typescript: latest }, checks);
process.exitCode = ok ? 0 : 1;
