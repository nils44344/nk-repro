#!/usr/bin/env bash
# Which popular packages (latest versions, 8 Nov 2026) still pull in node-fetch 2 / whatwg-url 5, and does
# loading them print DEP0040 unbundled and after an esbuild bundle? One clean folder per package.
set -u
W=${W:-/tmp/puny-pkgs}
PKGS="cross-fetch isomorphic-fetch gaxios googleapis firebase-admin @google-cloud/storage @supabase/supabase-js openai @anthropic-ai/sdk @google/genai aws-sdk @aws-sdk/client-s3 node-telegram-bot-api discord.js @octokit/rest twilio stripe @sendgrid/mail mongodb graphql-request @apollo/client jsdom puppeteer axios contentful @notionhq/client @slack/web-api airtable algoliasearch langchain @langchain/core replicate cohere-ai @pinecone-database/pinecone ethers web3 node-fetch"
echo "node $(node -v), npm $(npm -v), $(date -u +%F)"
printf '%-30s | %-10s | %-22s | %-10s | %s\n' package version node-fetch@2-chain unbundled bundled
for p in $PKGS; do
  d="$W/$(echo "$p" | tr '/@' '__')"; rm -rf "$d"; mkdir -p "$d"; cd "$d"
  npm init -y >/dev/null 2>&1
  if ! npm i "$p" esbuild@0.28 --no-audit --no-fund --ignore-scripts >/dev/null 2>&1; then echo "$p | install failed"; continue; fi
  v=$(node -p "require('./node_modules/$p/package.json').version" 2>/dev/null)
  chain=$(npm ls whatwg-url --all 2>/dev/null | grep -c 'whatwg-url@5' )
  nf=$(npm ls node-fetch --all 2>/dev/null | grep -o 'node-fetch@[0-9][^ ]*' | sort -u | tr '\n' ' ')
  echo "try{require('$p')}catch(e){ if(e.code==='ERR_REQUIRE_ESM'||/ES Module/.test(e.message)) import('$p') ; else console.log('LOADERR '+e.message.slice(0,80)) }" > a.cjs
  u=$(timeout 60 node a.cjs 2>&1 | grep -c DEP0040)
  npx esbuild a.cjs --bundle --platform=node --log-level=error --outfile=b.cjs >/dev/null 2>&1 && b=$(timeout 60 node b.cjs 2>&1 | grep -c DEP0040) || b="bundle-fail"
  printf '%-30s | %-10s | %-22s | %-10s | %s\n' "$p" "$v" "${nf:-none} whatwg5=$chain" "$([ "$u" -gt 0 ] && echo WARN || echo quiet)" "$([ "$b" = bundle-fail ] && echo bundle-fail || ([ "$b" -gt 0 ] && echo WARN || echo quiet))"
done
