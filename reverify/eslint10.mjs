// Re-checks https://nilaykabariya.blog/fixes/eslint-couldnt-find-an-eslint-config-file on the newest ESLint.
import { sh, tmp, files, check, record } from './lib.mjs';

const POST = 'eslint-couldnt-find-an-eslint-config-file';
const d = tmp('eslint');
files(d, {
  'package.json': { name: 'e', private: true },
  '.eslintrc.json': { root: true, extends: 'eslint:recommended' },
  'index.js': 'const unused = 1;\n',
});
sh('npm i -D eslint@latest --no-fund --no-audit', d);
const version = sh('npx eslint --version', d).trim();
const peer = sh('npm view eslint-plugin-react peerDependencies.eslint').trim();
const reactVer = sh('npm view eslint-plugin-react version').trim();

const checks = [
  check('.eslintrc only: "couldn\'t find an eslint.config.* file"', () => sh('npx eslint .', d), (o) => /couldn't find an eslint\.config/.test(o)),
  check('ESLINT_USE_FLAT_CONFIG=false is ignored (same error)', () => sh('npx eslint .', d, { ESLINT_USE_FLAT_CONFIG: 'false' }), (o) => /couldn't find an eslint\.config/.test(o)),
  check(`eslint-plugin-react (${reactVer}) still does not declare ESLint 10`, () => `peer eslint: ${peer}`, () => !/(^|[^d.])10(D|$)/.test(peer)),
];
const ok = record(POST, { eslint: version, 'eslint-plugin-react': reactVer }, checks);
process.exitCode = ok ? 0 : 1;
