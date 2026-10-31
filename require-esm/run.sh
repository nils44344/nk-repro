#!/bin/bash
# ERR_REQUIRE_ESM across real Node versions: plain require of an ESM-only package, the .default trap,
# top-level await (ERR_REQUIRE_ASYNC_MODULE), TypeScript compiled to CommonJS, and the dynamic import() fix.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
echo "== node $(node -v)"
npm init -y >/dev/null
npm install chalk@5 typescript@6 --no-audit --no-fund --loglevel=error 2>&1 | tail -1
run() { echo "-- $1"; node "$2" 2>&1 | grep -vE "^\s+at |^$|Node.js v" | head -4 | cut -c1-220; }

echo 'const chalk = require("chalk"); console.log(typeof chalk.green === "function" ? "require ok, chalk.green works" : "require ok, chalk.green is " + typeof chalk.green);' > a.cjs
run "require('chalk') of ESM-only chalk 5" a.cjs
echo 'const chalk = require("chalk").default; console.log("require(...).default.green:", typeof chalk.green);' > b.cjs
run "require('chalk').default" b.cjs
echo '(async () => { const { default: chalk } = await import("chalk"); console.log("dynamic import ok:", typeof chalk.green); })();' > c.cjs
run "dynamic import() from CommonJS" c.cjs

mkdir -p tla; printf '{"type":"module"}' > tla/package.json
echo 'const v = await Promise.resolve(42); export default v;' > tla/index.js
echo 'console.log(require("./tla/index.js"));' > d.cjs
run "require() of an ES module with top-level await" d.cjs
echo 'import("./tla/index.js").then((m) => console.log("import() of top-level-await module:", m.default));' > e.cjs
run "import() of the same module" e.cjs
echo 'const x = await Promise.resolve(1); console.log(x);' > f.cjs
run "top-level await inside a .cjs file" f.cjs

echo 'import chalk from "chalk"; console.log("ts->cjs:", typeof chalk.green);' > g.ts
npx tsc g.ts --module commonjs --moduleResolution node10 --esModuleInterop --target es2022 --outDir out --skipLibCheck 2>&1 | head -2
mv out/g.js out/g.cjs 2>/dev/null
run "TypeScript compiled to CommonJS (import chalk -> require)" out/g.cjs
echo "== done"
