#!/bin/bash
# "Cannot apply unknown utility class" in Tailwind v4: three causes, in the CLI, Vite and a Vue SFC.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
I="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v)"
npm init -y >/dev/null; npm pkg set type=module
npm install -D tailwindcss@4 @tailwindcss/cli@4 @tailwindcss/vite@4 vite@8 vue @vitejs/plugin-vue $I 2>&1 | tail -1
npm ls tailwindcss vite vue 2>&1 | grep -E "^[+\`]-- " | head -4
cli() { echo "-- $1"; printf '%s\n' "$2" > in.css; npx @tailwindcss/cli -i in.css -o out.css 2>&1 | grep -vE "^\s*$|^≈|Done in" | head -3 | cut -c1-200; [ -s out.css ] && grep -o "$3" out.css | head -1; rm -f out.css; }

echo "######## cause 1: custom colour not in @theme"
cli "border-border, no @theme" '@import "tailwindcss";
:root { --border: oklch(0.92 0 0); }
@layer base { * { @apply border-border; } }' 'border-color[^;]*'
cli "border-border with @theme inline" '@import "tailwindcss";
:root { --border: oklch(0.92 0 0); }
@theme inline { --color-border: var(--border); }
@layer base { * { @apply border-border; } }' 'border-color[^;]*'
echo 'export default { theme: { extend: { colors: { border: "hsl(214 32% 91%)" } } } };' > tailwind.config.js
cli "border-border from tailwind.config.js via @config" '@import "tailwindcss";
@config "./tailwind.config.js";
@layer base { * { @apply border-border; } }' 'border-color[^;]*'

echo "######## cause 2: file without Tailwind (CSS module / component style)"
cli "font-bold in a file without @import" '.title { @apply font-bold text-xl; }' 'font-weight[^;]*'
cli "same with @reference" '@reference "tailwindcss";
.title { @apply font-bold text-xl; }' 'font-weight[^;]*'

echo "######## cause 3: v3 utilities removed in v4"
for c in bg-opacity-50 text-opacity-50 flex-shrink-0 flex-grow overflow-ellipsis decoration-slice shadow-sm; do
  cli "@apply $c" "@import \"tailwindcss\";
.x { @apply $c; }" '\.x[^}]*'
done

echo "######## Vite + Vue SFC <style> with @apply"
mkdir -p src; echo '<!doctype html><div id="app"></div><script type="module" src="/src/main.js"></script>' > index.html
echo 'import { createApp } from "vue"; import App from "./App.vue"; import "./main.css"; createApp(App).mount("#app");' > src/main.js
echo '@import "tailwindcss";' > src/main.css
printf '<template><h1 class="title">hi</h1></template>\n<style scoped>\n.title { @apply font-bold text-xl; }\n</style>\n' > src/App.vue
echo 'import { defineConfig } from "vite"; import vue from "@vitejs/plugin-vue"; import tailwindcss from "@tailwindcss/vite"; export default defineConfig({ plugins: [vue(), tailwindcss()] });' > vite.config.js
echo "-- vite build, Vue <style> without @reference"; npx vite build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "Cannot apply|plugin|built in|error" | head -3 | cut -c1-220
printf '<template><h1 class="title">hi</h1></template>\n<style scoped>\n@reference "../main.css";\n.title { @apply font-bold text-xl; }\n</style>\n' > src/App.vue
echo "-- vite build, Vue <style> with @reference \"../main.css\""; npx vite build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "Cannot apply|built in|error" | head -2; grep -o "\.title\[data-v-[a-z0-9]*\]{[^}]*}" dist/assets/*.css | head -1
echo "== done"
