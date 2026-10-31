#!/bin/bash
# "bigint: Failed to load bindings, pure JS will be used (try npm run rebuild?)": when it appears and what fixes it.
# Runs on Windows (Git Bash) and Linux. Usage: bash run.sh   (work dir: $W, default ./work)
set +e
W=${W:-$(pwd)/work}; rm -rf "$W"; mkdir -p "$W"; cd "$W"
I="--no-audit --no-fund"
echo "== $(date) $(uname -s) node $(node -v) npm $(npm -v)"
probe='const m=require("bigint-buffer"); const fs=require("fs"); const p=require.resolve("bigint-buffer").replace(/dist[\\/]node\.js$/,"build/Release"); console.log("native build present:", fs.existsSync(p)); console.log("toBigIntLE:", m.toBigIntLE(Buffer.from([1,2,3,4])).toString());'

echo; echo "######## npm $(npm -v), plain install"
mkdir a && cd a && npm init -y >/dev/null
npm install bigint-buffer@1.1.5 $I --foreground-scripts 2>&1 | grep -E "gyp ERR! (stack Error|find)|Couldn't build|added|warn install-scripts" | head -6
node -e "$probe" 2>&1 | head -4; cd ..

echo; echo "######## npm 12 (npx npm@12), plain install"
mkdir b && cd b && npm init -y >/dev/null
npx -y npm@12 install bigint-buffer@1.1.5 $I 2>&1 | grep -E "install-scripts|added" | head -4
node -e "$probe" 2>&1 | head -4
echo "== npm 12: approve the script and rebuild"
npx -y npm@12 install-scripts approve bigint-buffer 2>&1 | tail -2; grep -A2 allowScripts package.json
npx -y npm@12 rebuild bigint-buffer --foreground-scripts 2>&1 | grep -E "gyp ERR! (stack Error|find)|Couldn't build|gyp info ok|rebuilt" | head -4
node -e "$probe" 2>&1 | head -4; cd ..

echo; echo "######## a real dependency chain: @solana/spl-token"
mkdir c && cd c && npm init -y >/dev/null
npm install @solana/spl-token $I 2>&1 | tail -1
npm ls bigint-buffer 2>&1 | head -6
node -e 'require("@solana/spl-token"); console.log("spl-token loaded")' 2>&1 | head -3
echo "== npm audit"; npm audit 2>&1 | grep -iE -A3 "bigint-buffer" | head -10; cd ..

echo; echo "######## speed: native vs pure JS (only where the native build exists)"
cd a && node -e '
const fs=require("fs");
const m=require("bigint-buffer");
const buf=Buffer.alloc(32,7); let t=process.hrtime.bigint(); for(let i=0;i<1e6;i++) m.toBigIntLE(buf); const a=Number(process.hrtime.bigint()-t)/1e6;
const js=(b)=>{const r=Buffer.from(b).reverse().toString("hex"); return r.length===0?0n:BigInt("0x"+r)};
t=process.hrtime.bigint(); for(let i=0;i<1e6;i++) js(buf); const c=Number(process.hrtime.bigint()-t)/1e6;
console.log("1e6 x toBigIntLE(32 bytes): module", a.toFixed(0), "ms | pure JS fallback", c.toFixed(0), "ms");' 2>&1 | tail -2
echo "== done $(date)"
