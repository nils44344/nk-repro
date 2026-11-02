#!/bin/bash
# "OPENAI_API_KEY environment variable is missing or empty": current openai SDKs (JS, Python) and Codex CLI.
# Uses an invented key only; the errors happen before any request, and Codex's 401 proves the key was read.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v) $(python3 --version)"
mkdir -p js/src && cd js && npm init -y >/dev/null && npm pkg set type=module
npm install openai dotenv $Q 2>&1 | tail -1
echo "openai $(node -p 'require("./node_modules/openai/package.json").version') dotenv $(node -p 'require("./node_modules/dotenv/package.json").version')"
echo 'OPENAI_API_KEY=sk-invented-test-key' > .env
echo 'import OpenAI from "openai"; try { new OpenAI(); console.log("client created"); } catch (e) { console.log(e.constructor.name + ": " + e.message.split("\n")[0].slice(0, 200)); }' > src/plain.mjs
printf 'import "dotenv/config";\n%s\n' "$(cat src/plain.mjs)" > src/dotenv.mjs
echo "-- no loader"; node src/plain.mjs
echo "-- dotenv/config"; node src/dotenv.mjs 2>&1 | tail -2
echo "-- node --env-file=.env"; node --env-file=.env src/plain.mjs
cd src; echo "-- dotenv/config, run from another folder"; node dotenv.mjs 2>&1 | tail -2
echo "-- --env-file=.env from another folder"; node --env-file=.env plain.mjs 2>&1 | head -1; cd ../..
echo "######## Python"
python3 -m venv py && py/bin/pip install -q openai python-dotenv 2>&1 | tail -1
echo "openai $(py/bin/python -c 'import openai;print(openai.__version__)') python-dotenv $(py/bin/pip show python-dotenv | grep Version | cut -d' ' -f2)"
cd js
echo "-- no loader"; ../py/bin/python -c 'from openai import OpenAI
try:
  OpenAI(); print("client created")
except Exception as e: print(type(e).__module__+"."+type(e).__name__+": "+str(e)[:200])'
echo "-- load_dotenv()"; ../py/bin/python -c 'from dotenv import load_dotenv; load_dotenv()
from openai import OpenAI; OpenAI(); print("client created")'
cd ..
echo "######## Codex CLI"
npm install -g @openai/codex $Q 2>&1 | tail -1; echo "codex $(codex --version 2>&1 | tail -1)"
export CODEX_HOME=$W/codexhome; mkdir -p $CODEX_HOME
printf 'model_provider = "openai-key"\n\n[model_providers.openai-key]\nname = "OpenAI with an API key"\nbase_url = "https://api.openai.com/v1"\nenv_key = "OPENAI_API_KEY"\nwire_api = "responses"\n' > $CODEX_HOME/config.toml
mkdir -p proj && cd proj && echo 'OPENAI_API_KEY=sk-invented-test-key' > .env
c() { timeout 90 codex exec --skip-git-repo-check "reply ok" < /dev/null 2>&1 | grep -aE "Missing environment variable|401|Incorrect API key|ERROR" | head -2 | cut -c1-200; }
echo "-- no key (project .env present)"; c
echo "-- OPENAI_API_KEY empty"; OPENAI_API_KEY= c
echo "-- exported"; OPENAI_API_KEY=sk-invented-test-key c
echo "-- .env in CODEX_HOME"; cp .env $CODEX_HOME/.env; c; rm $CODEX_HOME/.env
sed -i 's/env_key = "OPENAI_API_KEY"/env_key = "AI_GATEWAY_API_KEY"/' $CODEX_HOME/config.toml; echo "-- env_key AI_GATEWAY_API_KEY"; c
echo "== done"
