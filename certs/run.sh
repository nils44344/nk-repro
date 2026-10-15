#!/bin/bash
# "self-signed certificate in certificate chain": npm and Node behind a TLS-inspecting proxy whose root CA isn't
# trusted (proxy.mjs on localhost:8443, forwarding to registry.npmjs.org). Each fix only changes the project or env.
cd "$(dirname "$0")"
openssl req -x509 -newkey rsa:2048 -nodes -keyout ca.key -out ca.pem -days 30 -subj "/CN=NK Test Corp Root CA" \
  -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" 2>/dev/null
openssl req -newkey rsa:2048 -nodes -keyout leaf.key -out leaf.csr -subj "/CN=localhost" 2>/dev/null
printf "subjectAltName=DNS:localhost,IP:127.0.0.1\n" > ext.cnf
openssl x509 -req -in leaf.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out leaf.pem -days 30 -extfile ext.cnf 2>/dev/null
cat leaf.pem ca.pem > chain.pem
(node proxy.mjs > proxy.log 2>&1 &); sleep 3
echo "node $(node -v), npm $(npm -v)"
CA="$PWD/ca.pem"
case_() { local label="$1"; shift
  rm -rf p && mkdir p && cd p && npm init -y >/dev/null && echo "registry=https://localhost:8443/" > .npmrc
  out=$(eval "$@" 2>&1); code=$?
  echo "== $label (exit $code)"; echo "$out" | grep -E "^npm error (code|errno|request)|added" | head -3 | cut -c1-220
  cd ..; }
case_ "npm install, no fix" "npm i is-number --no-audit --no-fund --prefer-online"
case_ "npm --cafile" "npm i is-number --no-audit --no-fund --prefer-online --cafile '$CA'"
case_ "cafile in project .npmrc" "echo 'cafile=$CA' >> .npmrc && npm i is-number --no-audit --no-fund --prefer-online"
case_ "NODE_EXTRA_CA_CERTS" "NODE_EXTRA_CA_CERTS='$CA' npm i is-number --no-audit --no-fund --prefer-online"
case_ "strict-ssl=false (insecure)" "npm i is-number --no-audit --no-fund --prefer-online --strict-ssl=false"
case_ "NODE_TLS_REJECT_UNAUTHORIZED=0 (insecure)" "NODE_TLS_REJECT_UNAUTHORIZED=0 npm i is-number --no-audit --no-fund --prefer-online"
f="fetch('https://localhost:8443/is-number').then(r=>console.log('status',r.status)).catch(e=>console.log(e.message,'|',e.cause?.code,'|',e.cause?.message))"
echo "== node fetch, no fix"; node -e "$f"
echo "== node fetch + NODE_EXTRA_CA_CERTS"; NODE_EXTRA_CA_CERTS="$CA" node -e "$f"
echo "== node fetch + NODE_EXTRA_CA_CERTS set inside the script (too late)"; node -e "process.env.NODE_EXTRA_CA_CERTS='$CA'; $f"
