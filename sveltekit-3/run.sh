#!/bin/bash
# SvelteKit 2.40 -> 3 with `sv migrate sveltekit-3 --tasks all`: the plain bump (ERESOLVE), the migration, each build
# error in turn, the {base} link that becomes ".//about", and fail(400) changing the HTTP status.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W/app/src/routes/about" "$W/app/src/routes/form"; cd "$W/app" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date -u) node $(node -v) npm $(npm -v) sv ${SV:-1.1.1}"
cat > package.json <<'J'
{ "name": "kit2-app", "private": true, "type": "module",
  "scripts": { "build": "vite build", "preview": "vite preview" },
  "devDependencies": { "@sveltejs/kit": "2.40.0", "@sveltejs/adapter-auto": "^6.0.0", "@sveltejs/vite-plugin-svelte": "^6.0.0",
    "svelte": "^5.0.0", "svelte-check": "^4.0.0", "typescript": "~5.9.0", "vite": "7.3.7" } }
J
cat > svelte.config.js <<'J'
import adapter from '@sveltejs/adapter-auto';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';
export default { preprocess: vitePreprocess(), kit: { adapter: adapter(), csrf: { checkOrigin: true }, output: { preloadStrategy: 'modulepreload' } } };
J
echo "import { sveltekit } from '@sveltejs/kit/vite'; import { defineConfig } from 'vite'; export default defineConfig({ plugins: [sveltekit()] });" > vite.config.ts
echo '{ "extends": "./.svelte-kit/tsconfig.json", "compilerOptions": { "strict": true } }' > tsconfig.json
echo '<!doctype html><html><head>%sveltekit.head%</head><body>%sveltekit.body%</body></html>' > src/app.html
cat > src/hooks.server.ts <<'J'
import { installPolyfills } from '@sveltejs/kit/node/polyfills';
import type { Handle } from '@sveltejs/kit';
installPolyfills();
export const handle: Handle = ({ event, resolve }) => resolve(event);
J
printf '<script lang="ts">\n  import { base } from "$app/paths";\n</script>\n<a href="{base}/about">About</a>\n' > src/routes/+page.svelte
echo '<h1>about</h1>' > src/routes/about/+page.svelte
cat > src/routes/form/+page.server.ts <<'J'
import { fail } from '@sveltejs/kit';
export const actions = { default: async ({ request }) => { const d = await request.formData(); if (!d.get('name')) return fail(400, { missing: true }); return { ok: true }; } };
J
printf '<script lang="ts">\n  import { enhance } from "$app/forms";\n  let { form } = $props();\n</script>\n<form method="POST" use:enhance><input name="name" /><button>go</button></form>\n{#if form?.missing}<p>missing</p>{/if}\n' > src/routes/form/+page.svelte
npm install $Q 2>&1 | tail -1
v() { node -p "require('./node_modules/$1/package.json').version"; }
b() { npm run build > b.log 2>&1; local c=$?; if [ $c = 0 ]; then echo "   build OK"; else sed 's/\x1b\[[0-9;]*m//g' b.log | grep -aE "config_option_removed[a-z_]*|has been removed|is not exported under|error during build|Error: " | head -3 | sed 's/^/   /' | cut -c1-200; fi; }
serve() { (npx vite preview --port 4173 --strictPort > p.log 2>&1 &); sleep 5
  echo "   / link: $(curl -s localhost:4173/ | grep -oE 'href="[^"]*about"' | head -1) -> /about $(curl -s -o /dev/null -w '%{http_code}' localhost:4173/about), //about from / $(curl -s -o /dev/null -w '%{http_code}' 'localhost:4173//about')"
  echo "   form POST, empty field: plain $(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Origin: http://localhost:4173' -d name= localhost:4173/form) | enhance $(curl -s -o enh.json -w '%{http_code}' -X POST -H 'Origin: http://localhost:4173' -H 'x-sveltekit-action: true' -H 'accept: application/json' -d name= localhost:4173/form) $(grep -oE '"status":[0-9]+' enh.json)"
  echo "   foreign Origin POST: $(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Origin: https://evil.example' -d name=x localhost:4173/form)"
  pkill -f "vite preview"; sleep 1; }
echo "######## Kit $(v @sveltejs/kit), Vite $(v vite)"; b; serve
echo "######## Way 1: npm install -D @sveltejs/kit@latest"
npm install -D @sveltejs/kit@latest $Q 2>&1 | grep -aE "code E|Found:|peer @sveltejs" | head -3 | sed 's/^/   /'
echo "######## Way 2: sv migrate sveltekit-3 --tasks all"
npx -y sv@${SV:-1.1.1} migrate sveltekit-3 --tasks all --no-git-check --confirm --install npm < /dev/null > m.log 2>&1; echo "   exit $?"; sed 's/\[[0-9;]*m//g' m.log | grep -av '^\s*$' | grep -aiE 'task|applied|success|error|warn' | head -14 | cut -c1-170 | sed 's/^/   log: /' 
npm install $Q > /dev/null 2>&1
echo "   now: Kit $(v @sveltejs/kit), Vite $(v vite), svelte $(v svelte), TS $(v typescript), adapter-auto $(v @sveltejs/adapter-auto) | svelte.config.js exists: $([ -f svelte.config.js ] && echo yes || echo no) | MIGRATION_TASKS.md: $([ -f MIGRATION_TASKS.md ] && echo yes || echo no)"
echo "   +page.svelte now: $(grep -oE 'href=[^>]*' src/routes/+page.svelte | head -1)"
for i in 1 2 3 4; do echo "-- build $i"; b; grep -q "build OK" <(b) && break
  if grep -q "checkOrigin" b.log; then sed -i 's/csrf: *{ *checkOrigin: *true *},\? *//' vite.config.ts; echo "   removed csrf.checkOrigin"
  elif grep -q "preloadStrategy" b.log; then sed -i "s/output: *{ *preloadStrategy: *'modulepreload' *},\? *//" vite.config.ts; echo "   removed output.preloadStrategy"
  elif grep -q "node/polyfills" b.log; then sed -i '/node\/polyfills/d; /installPolyfills()/d' src/hooks.server.ts; echo "   removed the polyfills import and call"
  else sed -n 1,20p vite.config.ts; break; fi; done
serve
sed -i "s|href=\"{resolve('')}/about\"|href={resolve('/about')}|" src/routes/+page.svelte; echo "-- after resolve('/about'): $(grep -oE 'href=[^>]*' src/routes/+page.svelte | head -1)"; b; serve
echo "== done"
