#!/bin/bash
# npm ERESOLVE: React 19 + react-beautiful-dnd, ESLint 10 + eslint-plugin-react, on npm 11 and npm 12,
# plus the fixes (fork, overrides, .npmrc, --legacy-peer-deps and what happens on the next clean install).
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund"
err() { grep -E "^npm (error|ERR!) (code|ERESOLVE|While resolving|Found|Could not resolve|peer|Conflicting|  peer|node_modules|  dev|  [a-z@])|^npm (error|ERR!) (from|  from)" | grep -v "A complete log" | head -${1:-12} | cut -c1-200; }
echo "== $(date) node $(node -v) npm $(npm -v)"
for NPM in npm "npx -y npm@12"; do
  V=$($NPM -v 2>/dev/null | tail -1); echo; echo "######## npm $V"
  mkdir -p r$V && cd r$V && npm init -y >/dev/null
  echo "-- React 19 + react-beautiful-dnd"; $NPM install react@19 react-dom@19 react-beautiful-dnd@13.1.1 $Q 2>&1 | err 10
  echo "-- fix: @hello-pangea/dnd"; $NPM install react@19 react-dom@19 @hello-pangea/dnd $Q 2>&1 | tail -1
  cd ..; mkdir -p e$V && cd e$V && npm init -y >/dev/null
  echo "-- ESLint 10 + eslint-plugin-react"; $NPM install -D eslint@10 eslint-plugin-react $Q 2>&1 | err 12
  echo "-- peer range of eslint-plugin-react: $(npm view eslint-plugin-react peerDependencies.eslint)"
  cd ..
done
echo; echo "######## fixes, on $(npm -v)"
mkdir -p f && cd f && npm init -y >/dev/null
echo "-- --legacy-peer-deps"; npm install react@19 react-dom@19 react-beautiful-dnd@13.1.1 --legacy-peer-deps $Q 2>&1 | tail -1
rm -rf node_modules package-lock.json; echo "-- next plain npm install (clean)"; npm install $Q 2>&1 | err 3
echo "-- npm ci after a --legacy-peer-deps install"; npm install --legacy-peer-deps $Q >/dev/null 2>&1; npm ci $Q 2>&1 | err 4
echo "-- overrides with \$react"; node -e 'const p=require("./package.json"); p.overrides={"react-beautiful-dnd":{"react":"$react","react-dom":"$react-dom"}}; require("fs").writeFileSync("package.json", JSON.stringify(p,null,2))'
rm -rf node_modules package-lock.json; npm install $Q 2>&1 | tail -1; npm ci $Q 2>&1 | tail -1
echo "-- npm explain react (who wants which react)"; npm explain react 2>&1 | head -12
cd ..; mkdir -p g && cd g && npm init -y >/dev/null
echo "-- eslint 10 + plugin with overrides"; node -e 'const p=require("./package.json"); p.overrides={"eslint-plugin-react":{"eslint":"$eslint"}}; p.devDependencies={"eslint":"^10.0.0","eslint-plugin-react":"*"}; require("fs").writeFileSync("package.json", JSON.stringify(p,null,2))'
npm install $Q 2>&1 | tail -1
printf 'import react from "eslint-plugin-react";\nexport default [react.configs.flat.recommended, { settings: { react: { version: "19" } } }];\n' > eslint.config.mjs
echo 'export const A = () => <div className="x" />;' > a.jsx
echo "-- does eslint-plugin-react run on ESLint 10?"; npx eslint a.jsx 2>&1 | head -6 | cut -c1-200; echo "eslint exit ${PIPESTATUS[0]}"
echo "== done"
