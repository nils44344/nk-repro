#!/bin/bash
# Tailwind v4 "trying to use tailwindcss directly as a PostCSS plugin": postcss-cli and Vite, the half-fix, both fixes.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v)"
npm init -y >/dev/null; npm pkg set type=module
npm install -D tailwindcss@4 @tailwindcss/postcss@4 @tailwindcss/vite@4 postcss postcss-cli vite@8 $Q 2>&1 | tail -1
echo "tailwindcss $(node -p 'require("./node_modules/tailwindcss/package.json").version') postcss $(node -p 'require("./node_modules/postcss/package.json").version') vite $(node -p 'require("./node_modules/vite/package.json").version')"
echo '@import "tailwindcss";' > in.css; echo '<!doctype html><link rel="stylesheet" href="/in.css"><p class="p-4 text-red-500">hi</p>' > index.html
e() { grep -aoE "trying to use .tailwindcss. directly as a PostCSS plugin|plugin vite:css|built in [0-9.]+m?s" | head -1; }
cfg() { printf 'export default { plugins: { %s } };\n' "$1" > postcss.config.js; }
echo "######## postcss-cli"
cfg '"tailwindcss": {}'; echo "-- tailwindcss: {}"; npx postcss in.css -o out.css 2>&1 | e
echo "-- @tailwindcss/postcss installed, config unchanged (half-fix)"; npx postcss in.css -o out.css 2>&1 | e
cfg '"@tailwindcss/postcss": {}'; rm -f out.css; echo "-- @tailwindcss/postcss in config"; npx postcss in.css -o out.css 2>&1 | e; echo "   out.css has text-red-500: $(grep -c 'text-red-500' out.css 2>/dev/null)"
echo "######## Vite"
cfg '"tailwindcss": {}'; echo "-- vite build, tailwindcss: {}"; npx vite build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | e
cfg '"@tailwindcss/postcss": {}'; echo "-- vite build, @tailwindcss/postcss"; npx vite build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | e; echo "   css has text-red-500: $(cat dist/assets/*.css | grep -c 'text-red-500')"
rm postcss.config.js; echo 'import tailwindcss from "@tailwindcss/vite"; export default { plugins: [tailwindcss()] };' > vite.config.js
echo "-- vite build, @tailwindcss/vite plugin, no postcss config"; npx vite build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | e; echo "   css has text-red-500: $(cat dist/assets/*.css | grep -c 'text-red-500')"
echo "== done"
