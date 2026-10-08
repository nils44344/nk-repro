// Re-checks https://nilaykabariya.blog/fixes/bun-error-cannot-find-module on the newest Bun (and on both OSes).
import { sh, tmp, files, version, check, record, isWin } from './lib.mjs';

const POST = 'bun-error-cannot-find-module';
const run = (dir, cmd) => sh(cmd, dir);
const checks = [];

// 1. Isolated linker (default for new workspaces) hides an undeclared workspace package; declaring it fixes it.
{
  const d = tmp('ws');
  files(d, {
    'package.json': { name: 'mono', private: true, workspaces: ['packages/*', 'apps/*'] },
    'packages/ui/package.json': { name: '@mono/ui', version: '1.0.0', exports: { '.': './src/index.ts' } },
    'packages/ui/src/index.ts': 'export const Button = () => "button";\n',
    'apps/web/package.json': { name: 'web', version: '1.0.0' },
    'apps/web/index.ts': 'import { Button } from "@mono/ui"; console.log(Button());\n',
  });
  run(d, 'bun install');
  const web = `${d}/apps/web`;
  checks.push(check('Undeclared workspace package: "Cannot find module" on a fresh install', () => run(web, 'bun run index.ts'), (o) => /Cannot find module '@mono\/ui'/.test(o)));
  checks.push(check('Fix: bun add @mono/ui@workspace:* makes it load', () => run(web, 'bun add @mono/ui@workspace:* && bun run index.ts'), (o) => /\bbutton\b/.test(o) && !/Cannot find/.test(o)));
}

// 2. bun test ignores Jest's moduleNameMapper; tsconfig paths works.
{
  const d = tmp('test');
  files(d, {
    'package.json': { name: 't', private: true, jest: { moduleNameMapper: { '^~/(.*)$': '<rootDir>/src/$1' } } },
    'src/lib/math.ts': 'export const sum = (a: number, b: number) => a + b;\n',
    'tests/alias.test.ts': 'import { expect, test } from "bun:test";\nimport { sum } from "~/lib/math";\ntest("sum", () => expect(sum(1, 2)).toBe(3));\n',
  });
  checks.push(check('bun test ignores Jest moduleNameMapper', () => run(d, 'bun test'), (o) => /Cannot find module '~\/lib\/math'/.test(o)));
  files(d, { 'tsconfig.json': { compilerOptions: { paths: { '~/*': ['./src/*'] } } } });
  checks.push(check('Fix: tsconfig paths makes bun test pass', () => run(d, 'bun test'), (o) => /1 pass/.test(o) && /0 fail/.test(o)));
}

// 3. JSX with no React installed. In a folder with NO node_modules anywhere above it, Bun auto-installs React and the
// file just runs; in a real project (node_modules exists) it fails asking for react/jsx-dev-runtime.
{
  const jsx = 'const App = () => <h1>hi</h1>;\nconsole.log(App());\n';
  const d = tmp('jsx');
  files(d, { 'package.json': { name: 'j' }, 'index.tsx': jsx });
  checks.push(check('No node_modules anywhere: Bun auto-installs React and the JSX runs', () => run(d, 'bun run index.tsx'), (o) => /<h1>hi<\/h1>/.test(o)));
  const p = tmp('jsx-proj');
  files(p, { 'package.json': { name: 'j' }, 'index.tsx': jsx, 'node_modules/.keep': '' });
  checks.push(check('Project with node_modules, no React: "Cannot find module react/jsx-dev-runtime"', () => run(p, 'bun run index.tsx'), (o) => /react\/jsx-dev-runtime/.test(o)));
}

// 4. --bun on package.json scripts. The post says it works on Linux and is ignored on Windows.
{
  const d = tmp('flag');
  files(d, { 'package.json': { name: 'f', scripts: { n: 'node -e "console.log(typeof Bun)"' } } });
  const out = () => run(d, 'bun --bun run n');
  if (isWin) checks.push(check('Windows: bun --bun run still runs scripts in Node (bug present)', out, (o) => /\bundefined\b/.test(o)));
  else checks.push(check('Linux: bun --bun run runs scripts in Bun', out, (o) => /\bobject\b/.test(o)));
}

// 5. Linux only: a wrong-case relative import fails with ENOENT (Windows is case-insensitive).
if (!isWin) {
  const d = tmp('case');
  files(d, { 'index.ts': 'import { add } from "./utils"; console.log(add(1, 2));\n', 'Utils.ts': 'export const add = (a: number, b: number) => a + b;\n' });
  checks.push(check('Linux: wrong-case import fails (ENOENT reading ... utils.ts)', () => run(d, 'bun run index.ts'), (o) => /ENOENT|Cannot find module/.test(o)));
}

const ok = record(POST, { bun: version('bun --version') }, checks);
process.exitCode = ok ? 0 : 1;
