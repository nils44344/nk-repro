#!/bin/bash
# npx tailwindcss init on Tailwind v4: "could not determine executable to run", the v4 CLI way, and v3.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v) npm $(npm -v)"
p() { rm -rf $1; mkdir -p $1/src && cd $1 && npm init -y >/dev/null; }
e() { grep -aE "could not determine|Invalid command|Created|error|Done in|≈" | head -2 | cut -c1-160; }
p v4; npm install -D tailwindcss@4 $Q 2>&1 | tail -1; echo "tailwindcss $(node -p 'require("./node_modules/tailwindcss/package.json").version')"
echo "-- npx tailwindcss init (v4 installed)"; npx tailwindcss init 2>&1 | e; echo "   exit ${PIPESTATUS[0]}"
echo "-- npx tailwindcss@latest init (empty folder)"; (mkdir -p ../empty && cd ../empty && npx -y tailwindcss@latest init 2>&1 | e)
npm install -D @tailwindcss/cli@4 $Q 2>&1 | tail -1
echo "-- npx tailwindcss init after installing @tailwindcss/cli"; npx tailwindcss init 2>&1 | e; echo "   exit ${PIPESTATUS[0]}, tailwind.config.js exists: $([ -f tailwind.config.js ] && echo yes || echo no)"
echo '@import "tailwindcss";' > src/input.css; echo '<h1 class="text-3xl underline">hi</h1>' > index.html
echo "-- v4: npx @tailwindcss/cli -i ./src/input.css -o ./dist/output.css"; npx @tailwindcss/cli -i ./src/input.css -o ./dist/output.css 2>&1 | e
echo "   classes in output: $(grep -oE '\.text-3xl|\.underline' dist/output.css | sort -u | tr '\n' ' ')"
cd ..; p v3; npm install -D tailwindcss@3 $Q 2>&1 | tail -1; echo "-- v3 $(node -p 'require("./node_modules/tailwindcss/package.json").version'): npx tailwindcss init"; npx tailwindcss init 2>&1 | e
echo "== done"
