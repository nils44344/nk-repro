#!/bin/bash
# Which npm packages throw "process is not defined" when imported into a plain Vite 8 app (8 Nov 2026)?
# One Vite project; each package gets its own entry page that imports it and touches one export.
# Read in Playwright Chromium, in the dev server and after vite build + preview. Errors are page errors.
set +e
W=${W:-$(pwd)/work-pkgs}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
# name|import line|use
CASES='dotenv|import dotenv from "dotenv"|dotenv.config()
jsonwebtoken|import jwt from "jsonwebtoken"|jwt.sign({a:1},"k")
util|import util from "util"|util.inspect({a:1})
readable-stream|import { Readable } from "readable-stream"|Readable.from(["a"])
buffer|import { Buffer } from "buffer"|Buffer.from("a")
crypto-js|import CryptoJS from "crypto-js"|CryptoJS.SHA256("a").toString()
axios|import axios from "axios"|typeof axios.get
debug|import createDebug from "debug"|createDebug("x")("hi")
@supabase/supabase-js|import { createClient } from "@supabase/supabase-js"|createClient("https://a.supabase.co","k")
openai|import OpenAI from "openai"|new OpenAI({apiKey:"k",dangerouslyAllowBrowser:true})
@anthropic-ai/sdk|import Anthropic from "@anthropic-ai/sdk"|new Anthropic({apiKey:"k",dangerouslyAllowBrowser:true})
@google/genai|import { GoogleGenAI } from "@google/genai"|new GoogleGenAI({apiKey:"k"})
firebase|import { initializeApp } from "firebase/app"|initializeApp({apiKey:"k",projectId:"p"})
aws-sdk|import AWS from "aws-sdk"|new AWS.S3()
@aws-sdk/client-s3|import { S3Client } from "@aws-sdk/client-s3"|new S3Client({region:"us-east-1"})
graphql-request|import { GraphQLClient } from "graphql-request"|new GraphQLClient("https://x")
web3|import { Web3 } from "web3"|new Web3()
ethers|import { ethers } from "ethers"|ethers.id("a")
xlsx|import * as XLSX from "xlsx"|XLSX.utils.book_new()
mqtt|import mqtt from "mqtt"|typeof mqtt.connect
socket.io-client|import { io } from "socket.io-client"|typeof io
algoliasearch|import { algoliasearch } from "algoliasearch"|algoliasearch("a","b")
contentful|import { createClient } from "contentful"|createClient({space:"s",accessToken:"t"})
path|import path from "path"|path.join("a","b")
events|import { EventEmitter } from "events"|new EventEmitter()'
echo "== $(date -u +%F) node $(node -v)"
npm init -y >/dev/null; npm pkg set type=module
pk=$(echo "$CASES" | cut -d'|' -f1 | tr '\n' ' ')
npm install -D vite@8 playwright $Q 2>&1 | tail -1
for p in $pk; do npm install "$p" $Q >/dev/null 2>&1 || echo "install failed: $p"; done
npx playwright install chromium >/dev/null 2>&1
echo "vite $(node -p 'require("./node_modules/vite/package.json").version')"
inputs=""
i=0
while IFS='|' read -r name imp use; do
  i=$((i+1))
  echo "<!doctype html><pre id=out></pre><script type=module src=/e$i.js></script>" > "p$i.html"
  printf '%s;\nlet r; try { r = String(%s).slice(0,40); } catch (e) { r = e.constructor.name + ": " + e.message; }\ndocument.getElementById("out").textContent = "OK " + r;\n' "$imp" "$use" > "e$i.js"
  inputs="$inputs\"p$i\": \"p$i.html\","
done <<< "$CASES"
echo "export default { build: { rollupOptions: { input: { ${inputs%,} } } } };" > vite.config.js
cat > read.mjs <<'JS'
import { chromium } from "playwright";
const [base, n] = process.argv.slice(2);
const b = await chromium.launch(); const pg = await b.newPage();
const errs = []; pg.on("pageerror", (e) => errs.push(e.message.split("\n")[0]));
await pg.goto(`${base}/p${n}.html`); await pg.waitForTimeout(2500);
const out = await pg.textContent("#out").catch(() => "");
console.log(errs.length ? "ERR " + errs[0].slice(0, 60) : (out || "no output").slice(0, 60)); await b.close();
JS
(npx vite --port 5191 --strictPort > dev.log 2>&1 &); sleep 8
for n in $(seq 1 $i); do echo "$(node read.mjs http://localhost:5191 $n)" > "dev$n.txt"; done
pkill -f "vite --port 5191"; sleep 1
npx vite build > build.log 2>&1 || { echo "build failed:"; grep -iE "error|fail" build.log | head -8; }
(npx vite preview --port 5192 --strictPort > prev.log 2>&1 &); sleep 4
printf '%-24s | %-9s | %-62s | %s\n' package version "vite dev" "vite build + preview"
n=0
while IFS='|' read -r name imp use; do
  n=$((n+1))
  v=$(node -p "require('./node_modules/$name/package.json').version" 2>/dev/null || echo builtin)
  printf '%-24s | %-9s | %-62s | %s\n' "$name" "$v" "$(cat dev$n.txt)" "$(node read.mjs http://localhost:5192 $n)"
done <<< "$CASES"
pkill -f "vite preview --port 5192"
