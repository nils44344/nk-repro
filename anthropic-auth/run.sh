#!/bin/bash
# Anthropic SDK "Could not resolve authentication method": wording per SDK, which header each variable becomes
# (local echo server), and the API's 401 for invented keys in each variable. Invented keys only.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN
npm init -y >/dev/null; npm pkg set type=module; npm install @anthropic-ai/sdk $Q 2>&1 | tail -1
python3 -m venv py && py/bin/pip install -q anthropic 2>&1 | tail -1
echo "== $(date) node $(node -v) @anthropic-ai/sdk $(node -p 'require("./node_modules/@anthropic-ai/sdk/package.json").version') anthropic(py) $(py/bin/python -c 'import anthropic;print(anthropic.__version__)')"
echo "-- JS, no credentials"; node -e 'import("@anthropic-ai/sdk").then(async ({default:A})=>{try{await new A().messages.create({model:"claude-haiku-4-5",max_tokens:5,messages:[{role:"user",content:"hi"}]})}catch(e){console.log("   "+e.message.replace(/\n/g," ").slice(0,220))}})'
echo "-- Python, no credentials"; py/bin/python -c '
import anthropic
try: anthropic.Anthropic().messages.create(model="claude-haiku-4-5",max_tokens=5,messages=[{"role":"user","content":"hi"}])
except Exception as e: print("   "+type(e).__name__+": "+str(e)[:200])'
node -e 'require("http").createServer((q,r)=>{console.log(JSON.stringify({x:q.headers["x-api-key"]?"x-api-key":null,auth:q.headers["authorization"]?q.headers["authorization"].split(" ")[0]:null}));r.writeHead(401,{"content-type":"application/json"});r.end("{}")}).listen(8787)' > hdr.log 2>&1 &
sleep 1
call='import("@anthropic-ai/sdk").then(async ({default:A})=>{try{await new A({maxRetries:0,...(process.env.BASE?{baseURL:process.env.BASE}:{})}).messages.create({model:"claude-haiku-4-5",max_tokens:5,messages:[{role:"user",content:"hi"}]})}catch(e){console.log("   "+(e.status||"")+" "+String(e.message).replace(/\n/g," ").slice(0,140))}})'
echo "######## headers seen by a local server"
for C in "ANTHROPIC_API_KEY=sk-ant-api03-invented" "ANTHROPIC_AUTH_TOKEN=sk-ant-api03-invented" "ANTHROPIC_API_KEY=sk-ant-api03-a ANTHROPIC_AUTH_TOKEN=tok-b"; do
  : > hdr.log; echo "-- $C"; env $C BASE=http://127.0.0.1:8787 node -e "$call" 2>&1 | grep -v "^   401" | head -1; echo "   headers: $(cat hdr.log)"; done
echo "######## 401 from the real API, invented values"
for C in "ANTHROPIC_API_KEY=sk-ant-api03-invented" "ANTHROPIC_API_KEY=sk-ant-oat01-invented" "ANTHROPIC_AUTH_TOKEN=sk-ant-api03-invented" "ANTHROPIC_AUTH_TOKEN=sk-ant-oat01-invented" "ANTHROPIC_AUTH_TOKEN=random-invented"; do
  echo "-- $C"; env $C node -e "$call"; done
echo "== done"
