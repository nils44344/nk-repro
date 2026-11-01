#!/bin/bash
# "process is not defined" in Vite: what each expression gives in the dev server and in the build, in a real browser
# (Playwright Chromium), with no config, define 'process.env': {}, and vite-plugin-node-polyfills.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v)"
npm init -y >/dev/null; npm pkg set type=module
npm install -D vite@8 playwright vite-plugin-node-polyfills $Q 2>&1 | tail -1
npx playwright install chromium >/dev/null 2>&1
echo "vite $(node -p 'require("./node_modules/vite/package.json").version'), polyfills $(node -p 'require("./node_modules/vite-plugin-node-polyfills/package.json").version')"
mkdir -p node_modules/fake-dep && echo '{"name":"fake-dep","version":"1.0.0","type":"module","main":"index.js"}' > node_modules/fake-dep/package.json
echo 'export const mode = () => process.env.NODE_ENV; export const debug = () => process.env.DEBUG;' > node_modules/fake-dep/index.js
printf 'VITE_API_KEY=from-env\nAPI_KEY=secret\n' > .env
echo '<!doctype html><pre id="out"></pre><script type="module" src="/main.js"></script>' > index.html
cat > main.js <<'JS'
import { mode, debug } from "fake-dep";
const cases = {
  "process.env.API_KEY": () => process.env.API_KEY,
  "process.env.NODE_ENV": () => process.env.NODE_ENV,
  "process.platform": () => process.platform,
  "dep: process.env.NODE_ENV": () => mode(),
  "dep: process.env.DEBUG": () => debug(),
  "import.meta.env.VITE_API_KEY": () => import.meta.env.VITE_API_KEY,
};
let s = "";
for (const [k, f] of Object.entries(cases)) { try { s += `${k} => ${JSON.stringify(f())}\n`; } catch (e) { s += `${k} => ${e.constructor.name}: ${e.message}\n`; } }
document.getElementById("out").textContent = s + "DONE";
JS
cat > read.mjs <<'JS'
import { chromium } from "playwright";
const b = await chromium.launch(); const p = await b.newPage();
await p.goto(process.argv[2]); await p.waitForFunction(() => document.getElementById("out").textContent.includes("DONE"), null, { timeout: 30000 }).catch(() => {});
console.log((await p.textContent("#out")).replace("DONE", "").trimEnd().split("\n").map(l => "   " + l).join("\n")); await b.close();
JS
run() { # $1 label, $2 vite.config.js body
  echo; echo "######## $1"; printf '%s\n' "$2" > vite.config.js; rm -rf node_modules/.vite dist
  (npx vite --port 5181 --strictPort > dev.log 2>&1 &); sleep 6; echo "-- dev"; node read.mjs http://localhost:5181/
  pkill -f "vite --port 5181"; sleep 1
  npx vite build > build.log 2>&1 || tail -5 build.log
  (npx vite preview --port 5182 --strictPort > prev.log 2>&1 &); sleep 4; echo "-- build + preview"; node read.mjs http://localhost:5182/
  pkill -f "vite preview --port 5182"; sleep 1
  echo "   secret in dist: $(grep -l secret dist/assets/*.js 2>/dev/null | wc -l) file(s)"
}
run "no config" 'export default {};'
run "define process.env: {}" 'export default { define: { "process.env": {} } };'
run "vite-plugin-node-polyfills" 'import { nodePolyfills } from "vite-plugin-node-polyfills"; export default { plugins: [nodePolyfills()] };'
echo "== done"
