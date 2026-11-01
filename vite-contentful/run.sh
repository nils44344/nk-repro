#!/bin/bash
# contentful/rich-text#713: @contentful/rich-text-from-markdown in a fresh Vite app, dev and build, in Chromium.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v)"
npm init -y >/dev/null; npm pkg set type=module
npm install @contentful/rich-text-from-markdown $Q 2>&1 | tail -1; npm install -D vite@8 playwright vite-plugin-node-polyfills $Q 2>&1 | tail -1
npx playwright install chromium >/dev/null 2>&1
echo "rich-text-from-markdown $(node -p 'require("./node_modules/@contentful/rich-text-from-markdown/package.json").version'), vite $(node -p 'require("./node_modules/vite/package.json").version')"
echo '<!doctype html><pre id="out"></pre><script type="module" src="/main.js"></script>' > index.html
cat > main.js <<'JS'
const out = document.getElementById("out");
window.addEventListener("error", (e) => { out.textContent += "window error: " + e.message + "\nDONE"; });
import("@contentful/rich-text-from-markdown").then(async (m) => {
  const doc = await m.richTextFromMarkdown("# Hi **there**");
  out.textContent += "ok: " + doc.content[0].nodeType + "\nDONE";
}).catch((e) => { out.textContent += e.constructor.name + ": " + e.message + "\nDONE"; });
JS
cat > read.mjs <<'JS'
import { chromium } from "playwright";
const b = await chromium.launch(); const p = await b.newPage(); const errs = [];
p.on("pageerror", (e) => errs.push(e.message));
await p.goto(process.argv[2]); await p.waitForFunction(() => document.getElementById("out").textContent.includes("DONE"), null, { timeout: 30000 }).catch(() => {});
console.log("   page: " + (await p.textContent("#out")).replace(/\nDONE/g, " ").trim() + (errs.length ? " | pageerror: " + errs[0] : "")); await b.close();
JS
run() {
  echo "######## $1"; printf '%s\n' "$2" > vite.config.js; rm -rf node_modules/.vite dist
  (npx vite --port 5181 --strictPort > dev.log 2>&1 &); sleep 8; echo "-- dev"; node read.mjs http://localhost:5181/; pkill -f "vite --port 5181"; sleep 1
  npx vite build > build.log 2>&1 || tail -4 build.log
  (npx vite preview --port 5182 --strictPort > prev.log 2>&1 &); sleep 4; echo "-- build + preview"; node read.mjs http://localhost:5182/; pkill -f "vite preview --port 5182"; sleep 1
}
run "no config" 'export default {};'
run "define process.env: {}" 'export default { define: { "process.env": {} } };'
run "vite-plugin-node-polyfills" 'import { nodePolyfills } from "vite-plugin-node-polyfills"; export default { plugins: [nodePolyfills()] };'
echo "== done"
