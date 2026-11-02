#!/bin/bash
# OpenAI 401 "Incorrect API key provided": an old key in the environment beats .env. Invented keys only;
# OpenAI rejects both, and the 401 shows which one was sent (first 8 and last 4 characters).
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
echo "== $(date) node $(node -v) $(python3 --version)"
npm init -y >/dev/null; npm pkg set type=module; npm install openai dotenv $Q 2>&1 | tail -1
python3 -m venv py && py/bin/pip install -q openai python-dotenv 2>&1 | tail -1
echo "openai $(node -p 'require("./node_modules/openai/package.json").version') / $(py/bin/python -c 'import openai;print(openai.__version__)'), dotenv $(node -p 'require("./node_modules/dotenv/package.json").version') / $(py/bin/pip show python-dotenv | grep Version | cut -d' ' -f2)"
echo 'OPENAI_API_KEY=sk-new-key-from-dotenv-22222222222222222222222222222222' > .env
export OPENAI_API_KEY=sk-old-key-in-the-shell-11111111111111111111111111111111
call='const c=new OpenAI(); try { await c.models.list(); console.log("ok") } catch(e) { console.log((e.status||"")+" "+String(e.message).match(/Incorrect API key provided: [^.]*/)?.[0]) }'
printf 'import "dotenv/config"; import OpenAI from "openai";\n%s\n' "$call" > a.mjs
printf 'import dotenv from "dotenv"; dotenv.config({ override: true }); import OpenAI from "openai";\n%s\n' "$call" > b.mjs
printf 'import OpenAI from "openai";\n%s\n' "$call" > c.mjs
echo "-- shell has old key; import 'dotenv/config'"; node a.mjs
echo "-- shell has old key; node --env-file=.env"; node --env-file=.env c.mjs
echo "-- shell has old key; dotenv.config({ override: true })"; node b.mjs
py() { py/bin/python -c "
from dotenv import load_dotenv; load_dotenv($1)
from openai import OpenAI
import re
try: OpenAI().models.list(); print('ok')
except Exception as e: print(getattr(e,'status_code',''), (re.search(r'Incorrect API key provided: [^.]*', str(e)) or [''])[0])"; }
echo "-- Python load_dotenv()"; py ""
echo "-- Python load_dotenv(override=True)"; py "override=True"
echo "== done"
