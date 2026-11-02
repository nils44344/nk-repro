#!/bin/bash
# Vite "Failed to load PostCSS config": CommonJS config in a "type": "module" project, a missing plugin,
# a stray config in a parent folder (found with the post's one-liner), and the fixes.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
HERE=$(cd "$(dirname "$0")" && pwd)
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v)"
mkdir -p parent/app && cd parent/app && npm init -y >/dev/null && npm pkg set type=module
npm install -D vite@8 postcss autoprefixer $Q 2>&1 | tail -1
echo "vite $(node -p 'require("./node_modules/vite/package.json").version') postcss $(node -p 'require("./node_modules/postcss/package.json").version')"
echo '<!doctype html><link rel="stylesheet" href="/s.css"><p>x</p>' > index.html; echo 'p { display: flex; }' > s.css
b() { npx vite build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -aE "Failed to load PostCSS|built in|SyntaxError|Cannot find module|not defined" | head -1 | cut -c1-200; }
echo "######## 1. CommonJS config in a type=module project"
echo 'module.exports = { plugins: { autoprefixer: {} } };' > postcss.config.js; echo "-- module.exports in postcss.config.js"; b
mv postcss.config.js postcss.config.cjs; echo "-- renamed to .cjs"; b
rm postcss.config.cjs; echo 'export default { plugins: { autoprefixer: {} } };' > postcss.config.js; echo "-- export default in .js"; b
mv postcss.config.js postcss.config.cjs; echo "-- export default renamed to .cjs (what didn't work)"; b; rm postcss.config.cjs
echo "######## 2. plugin not installed"
echo 'export default { plugins: { "postcss-nesting": {} } };' > postcss.config.js; echo "-- postcss-nesting in config, not installed"; b
npm install -D postcss-nesting $Q 2>&1 | tail -1; echo "-- after installing it"; b; rm postcss.config.js
echo "######## 3. stray config in the parent folder"
echo 'module.exports = { plugins: { tailwindcss: {} } };' > ../postcss.config.cjs; echo "-- no config in app/"; b
echo "-- the post's finder one-liner, run from app/:"; bash "$HERE/find-postcss-config.sh" 2>&1 | head -3 | cut -c1-200
echo 'export default { css: { postcss: {} } };' > vite.config.js; echo "-- inline css.postcss in vite.config.js, stray file still there"; b
rm vite.config.js ../postcss.config.cjs; echo "-- stray file removed"; b
echo "== done"
