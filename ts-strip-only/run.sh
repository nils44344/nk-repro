#!/bin/bash
# Node's ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX ("not supported in strip-only mode"): five constructs, the flag,
# NODE_OPTIONS, tsx, plain-JS rewrites, and a types-only namespace.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
npm init -y >/dev/null; npm install -D tsx --no-audit --no-fund --loglevel=error 2>&1 | tail -1
echo "== $(date) node $(node -v) tsx $(node -p 'require("./node_modules/tsx/package.json").version')"
echo 'enum Color { Red, Green } console.log(Color.Green);' > enum.ts
echo 'class G { constructor(private name: string) {} hi() { return "hi " + this.name; } } console.log(new G("ada").hi());' > param.ts
echo 'namespace Config { export const port = 3000; } console.log(Config.port);' > ns.ts
echo 'function add(a: number, b: number) { return a + b; } export = add;' > exp.cts; echo 'const add = require("./exp.cts"); console.log(add(1, 2));' > useexp.cjs
echo 'import path = require("node:path"); console.log(path.sep);' > impeq.cts
echo 'const Color = { Red: 0, Green: 1 } as const; console.log(Color.Green);' > enum-r.ts
echo 'class G { private name: string; constructor(name: string) { this.name = name; } hi() { return "hi " + this.name; } } console.log(new G("ada").hi());' > param-r.ts
echo 'const Config = { port: 3000 }; console.log(Config.port);' > ns-r.ts
echo 'namespace Shapes { export type Point = { x: number; y: number } } const p: Shapes.Point = { x: 1, y: 2 }; console.log("types-only ok", p.x);' > ns-types.ts
o() { "$@" 2>&1 | grep -aE "ERR_UNSUPPORTED|not supported|ExperimentalWarning|^[0-9]|^hi |^/|types-only|Error" | grep -v "^\s*at " | head -1 | cut -c1-130; }
for f in enum.ts param.ts ns.ts useexp.cjs impeq.cts; do
  echo "-- $f"; echo "   node:       $(o node $f)"; echo "   flag:       $(o node --experimental-transform-types $f)"
  echo "   NODE_OPTIONS: $(NODE_OPTIONS=--experimental-transform-types o node $f)"
  [ $f != useexp.cjs ] && echo "   tsx:        $(o npx tsx $f)"
done
echo "-- flag + --disable-warning=ExperimentalWarning: $(node --experimental-transform-types --disable-warning=ExperimentalWarning enum.ts 2>&1 | head -2 | tr '\n' ' ')"
for f in enum-r.ts param-r.ts ns-r.ts ns-types.ts; do echo "-- rewrite $f, plain node: $(o node $f)"; done
echo "== done"
