#!/bin/bash
# require / __dirname / __filename in ES module scope: the three errors, import.meta.dirname, the fileURLToPath fallback,
# import, createRequire, a .cjs file, a JSON import, and the .mjs rename that doesn't help.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
echo "== $(date -u) node $(node -v)"
echo '{"type":"module"}' > package.json; echo '{"name":"demo"}' > data.json
o() { node "$1" 2>&1 | grep -aE "ReferenceError|TypeError|^ok|^dir |^file |demo" | head -1 | cut -c1-140; }
echo 'const fs = require("node:fs"); console.log("ok");' > a.js; echo "-- require: $(o a.js)"
echo 'console.log(__dirname);' > b.js; echo "-- __dirname: $(o b.js)"
echo 'console.log(__filename);' > c.js; echo "-- __filename: $(o c.js)"
cp a.js a.mjs; echo "-- require in .mjs: $(o a.mjs)"
echo 'import path from "node:path"; console.log("dir", import.meta.dirname); console.log("file", path.basename(import.meta.filename)); console.log("ok", path.join(import.meta.dirname, "data.json").endsWith("data.json"));' > d.js; echo "-- import.meta.dirname/filename:"; node d.js 2>&1 | sed 's/^/   /'
echo 'import { fileURLToPath } from "node:url"; import { dirname } from "node:path"; const __filename = fileURLToPath(import.meta.url); console.log("ok", dirname(__filename) === process.cwd());' > e.js; echo "-- fileURLToPath fallback: $(o e.js)"
echo 'import fs from "node:fs"; console.log("ok", typeof fs.readFileSync);' > f.js; echo "-- import: $(o f.js)"
echo 'import { createRequire } from "node:module"; const require = createRequire(import.meta.url); console.log("ok", typeof require("node:fs").readFileSync);' > g.js; echo "-- createRequire: $(o g.js)"
echo 'const fs = require("node:fs"); console.log("ok", typeof fs.readFileSync, typeof __dirname);' > h.cjs; echo "-- .cjs file: $(o h.cjs)"
echo 'import data from "./data.json" with { type: "json" }; console.log("ok", data.name);' > i.js; echo "-- JSON import with type json: $(o i.js)"
echo 'import data from "./data.json"; console.log("ok", data.name);' > j.js; echo "-- JSON import without it: $(o j.js)"
echo "== done"
