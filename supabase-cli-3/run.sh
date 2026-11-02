#!/bin/bash
# Supabase CLI 3.0.0 on release day: local stack on v2 vs v3, the 42501 RLS results from the blog's post, and the
# breaking changes that can be checked without a hosted project. Nothing touches a hosted project.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v) docker $(docker --version | cut -d' ' -f3)"
V=${CLI:-3}; mkdir app && cd app && npm init -y >/dev/null; npm pkg set type=module
npm install supabase@$V @supabase/supabase-js $Q 2>&1 | tail -1
S="npx supabase"; echo "supabase CLI $($S --version 2>&1 | tail -1), supabase-js $(node -p 'require("./node_modules/@supabase/supabase-js/package.json").version')"
$S init >/dev/null 2>&1; echo "-- config.toml has project_id: $(grep -c '^project_id' supabase/config.toml)"
echo "-- supabase start"; timeout 900 $S start > start.log 2>&1; echo "   exit $? | $(grep -aE 'API URL|Studio URL|error|Error' start.log | head -2 | tr '\n' ' ' | cut -c1-160)"
eval "$($S status -o env 2>/dev/null | grep -E '^(API_URL|ANON_KEY|SERVICE_ROLE_KEY|DB_URL)=')"
echo "   status: API_URL=$API_URL"
docker ps --format '{{.Names}}' | head -3 | sed 's/^/   container: /'
psql() { docker exec -i $(docker ps --format '{{.Names}}' | grep -m1 _db_) psql -U postgres -d postgres -tAc "$1" 2>&1 | head -2; }
psql "create table notes(id bigint generated always as identity primary key, body text, user_id uuid default auth.uid()); alter table notes enable row level security; grant all on notes to anon, authenticated;"
cat > rls.mjs <<J
import { createClient } from "@supabase/supabase-js";
const s = createClient(process.env.API_URL, process.env.ANON_KEY);
const r = async (label, p) => { const { error, data } = await p; console.log("   " + label + ": " + (error ? error.code + " " + error.message : "ok " + JSON.stringify(data))); };
await r(process.argv[2] + " insert", s.from("notes").insert({ body: "hi" }));
await r(process.argv[2] + " insert().select()", s.from("notes").insert({ body: "hi" }).select());
J
echo "######## 42501 (anon)"
API_URL=$API_URL ANON_KEY=$ANON_KEY node rls.mjs "no policy"
psql "create policy ins on notes for insert to anon with check (true);" >/dev/null
API_URL=$API_URL ANON_KEY=$ANON_KEY node rls.mjs "insert policy only"
psql "create policy sel on notes for select to anon using (true);" >/dev/null
API_URL=$API_URL ANON_KEY=$ANON_KEY node rls.mjs "insert + select policies"
echo "######## v3 behaviour changes (local only)"
echo "-- db push with no target"; timeout 120 $S db push 2>&1 | grep -aE "Target|local|remote|error|Error|Finished|up to date" | head -3 | cut -c1-160
echo "-- gen types with no target"; timeout 120 $S gen types --lang typescript 2>&1 | grep -aE "Target|notes|error" | head -2 | cut -c1-120
echo "-- db push --linked (not linked)"; timeout 60 $S db push --linked 2>&1 | grep -aiE "deprecated|remote|link|error" | head -2 | cut -c1-180
echo "-- removed command: db remote commit"; timeout 60 $S db remote commit 2>&1 | head -2 | cut -c1-180
printf '\n[inbucket]\nenabled = true\nport = 54324\n' >> supabase/config.toml; echo "-- config.toml with [inbucket]"; timeout 60 $S status 2>&1 | grep -aiE "inbucket|local_smtp|error|unknown" | head -2 | cut -c1-180
sed -i '/^\[inbucket\]/,/^port = 54324/d' supabase/config.toml
echo "-- SUPABASE_STUDIO_PORT=abc"; SUPABASE_STUDIO_PORT=abc timeout 60 $S status 2>&1 | grep -aiE "error|invalid|abc" | head -2 | cut -c1-180
$S stop >/dev/null 2>&1
echo "== done"
