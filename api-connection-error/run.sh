#!/bin/bash
# OpenAI / Anthropic SDK "Connection error.": ECONNREFUSED, ENOTFOUND, a replaced HTTPS certificate (self-signed local
# server) and its fixes, and HTTPS_PROXY being ignored without NODE_USE_ENV_PROXY. Fake keys only.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
npm init -y >/dev/null; npm pkg set type=module; npm install openai @anthropic-ai/sdk $Q 2>&1 | tail -1
echo "== $(date) node $(node -v) openai $(node -p 'require("./node_modules/openai/package.json").version') anthropic $(node -p 'require("./node_modules/@anthropic-ai/sdk/package.json").version')"
cat > call.mjs <<'J'
import OpenAI from "openai"; import Anthropic from "@anthropic-ai/sdk";
const base = process.env.BASE; const which = process.env.SDK || "openai";
const c = which === "openai" ? new OpenAI({ apiKey: "sk-fake", maxRetries: 0, ...(base ? { baseURL: base } : {}) })
                             : new Anthropic({ apiKey: "sk-ant-fake", maxRetries: 0, ...(base ? { baseURL: base } : {}) });
try { which === "openai" ? await c.models.list() : await c.models.list(); console.log("   " + which + ": ok"); }
catch (e) { let x = e.cause; while (x?.cause) x = x.cause; console.log("   " + which + ": " + (e.status ? e.status + " " : "") + e.message.split("\n")[0].slice(0, 60) + (x ? " | cause: " + (x.code || "") + " " + String(x.message).slice(0, 70) : "")); }
J
both() { SDK=openai node "$@" call.mjs 2>&1 | grep -v "^(node" | tail -1; SDK=anthropic node "$@" call.mjs 2>&1 | grep -v "^(node" | tail -1; }
echo "-- 1. nothing listening (localhost:11434)"; BASE=http://localhost:11434/v1 both
echo "-- 2. typo in host (api.openai.co / api.anthropic.co)"; SDK=openai BASE=https://api.openai.co/v1 node call.mjs; SDK=anthropic BASE=https://api.anthropic.co node call.mjs
echo "######## 3. replaced certificate (self-signed local HTTPS server)"
openssl req -x509 -newkey rsa:2048 -nodes -keyout k.pem -out c.pem -days 2 -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost" 2>/dev/null
node -e 'require("https").createServer({key:require("fs").readFileSync("k.pem"),cert:require("fs").readFileSync("c.pem")},(q,r)=>{r.writeHead(401,{"content-type":"application/json"});r.end("{\"error\":{\"message\":\"fake 401 from local server\"}}")}).listen(8443)' &
sleep 1; export BASE=https://localhost:8443/v1
echo "-- no fix"; both
echo "-- NODE_EXTRA_CA_CERTS"; NODE_EXTRA_CA_CERTS=$W/c.pem both
sudo cp c.pem /usr/local/share/ca-certificates/nk-test.crt && sudo update-ca-certificates >/dev/null 2>&1
echo "-- cert in the system store, plain node"; both
echo "-- --use-system-ca"; both --use-system-ca
echo "-- NODE_USE_SYSTEM_CA=1"; NODE_USE_SYSTEM_CA=1 both
echo "-- NODE_TLS_REJECT_UNAUTHORIZED=0"; NODE_TLS_REJECT_UNAUTHORIZED=0 SDK=openai node call.mjs 2>&1 | grep -E "Warning|openai" | head -2 | cut -c1-140
unset BASE
echo "######## 4. HTTPS_PROXY (local logging proxy)"
node -e 'const net=require("net");require("http").createServer().on("connect",(req,cs,head)=>{console.log("CONNECT "+req.url);const [h,p]=req.url.split(":");const s=net.connect(p,h,()=>{cs.write("HTTP/1.1 200 OK\r\n\r\n");s.write(head);s.pipe(cs);cs.pipe(s)});s.on("error",()=>cs.end())}).listen(3128)' > proxy.log 2>&1 &
sleep 1; export HTTPS_PROXY=http://127.0.0.1:3128
: > proxy.log; echo "-- HTTPS_PROXY set, plain node"; both; echo "   proxy saw: $(sort -u proxy.log | tr '\n' ' ')"
: > proxy.log; echo "-- HTTPS_PROXY + NODE_USE_ENV_PROXY=1"; NODE_USE_ENV_PROXY=1 both; echo "   proxy saw: $(sort -u proxy.log | tr '\n' ' ')"
echo "== done"
