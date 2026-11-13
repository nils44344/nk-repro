#!/bin/bash
# Puppeteer on a bare Debian image: Chrome downloads fine, then fails to START (Code: 127, libnspr4.so missing).
# Finds every missing library with ldd, maps each to its package with apt-file, installs them, launches again.
set +e
export DEBIAN_FRONTEND=noninteractive
W=${W:-/tmp/work}; mkdir -p $W; cd $W || exit 1
echo "== $(date) $(. /etc/os-release; echo $PRETTY_NAME) node $(node -v) user $(id -un)"
mkdir t && cd t && npm init -y >/dev/null
npm install puppeteer --no-audit --no-fund --loglevel=error 2>&1 | tail -1
npm -v; ls $HOME/.cache/puppeteer 2>/dev/null || (echo "no browser from install; running browsers install chrome"; npx puppeteer browsers install chrome 2>&1 | tail -1)
echo "puppeteer $(node -p 'require("./node_modules/puppeteer/package.json").version')"
cat > t.cjs <<'J'
require("puppeteer").launch({args:["--no-sandbox"]}).then(async b=>{console.log("launched "+await b.version());await b.close()}).catch(e=>console.log("ERR "+e.message.split("\n").slice(0,3).join(" | ").slice(0,400)))
J
echo "-- 1. launch on the bare image"; node t.cjs
CH=$(node -e 'Promise.resolve(require("puppeteer").executablePath()).then(console.log)')
echo "-- 2. missing libraries (ldd $CH)"
ldd "$CH" | grep "not found" | awk '{print $1}' | sort -u | tee missing.txt
apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq apt-file >/dev/null 2>&1; apt-file update >/dev/null 2>&1
for round in 1 2 3; do
  LIBS=$(ldd "$CH" | grep "not found" | awk '{print $1}' | sort -u)
  [ -z "$LIBS" ] && break
  PK=""
  for l in $LIBS; do p=$(apt-file search --regexp "/usr/lib/x86_64-linux-gnu/${l}$" | head -1 | cut -d: -f1); PK="$PK $p"; done
  PK=$(echo $PK | tr ' ' '\n' | sort -u | tr '\n' ' ')
  echo "-- round $round: apt-get install $PK"; echo "$PK" >> packages.txt
  apt-get install -y -qq --no-install-recommends $PK >/dev/null 2>&1
done
echo "-- still missing: $(ldd "$CH" | grep -c 'not found')"
echo "-- 3. launch after installing"; node t.cjs
echo "-- packages installed:"; sort -u packages.txt | tr '\n' ' ' | fold -w 150; echo
