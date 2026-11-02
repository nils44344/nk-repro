#!/bin/bash
# Puppeteer "Could not find Chrome": download skipped (--ignore-scripts, npm 12), browser behind after an upgrade,
# cache dir mismatch (.puppeteerrc.cjs fix), headless shell not installed, and channel: 'chrome' (system Chrome).
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
export HOME=$W/home; mkdir -p $HOME   # throwaway cache home (~/.cache/puppeteer)
echo "== $(date) node $(node -v), system chrome: $(google-chrome --version 2>/dev/null)"
cat > t.cjs <<'J'
const p = require("puppeteer"); const opt = { args: ["--no-sandbox"], ...(process.env.OPT ? JSON.parse(process.env.OPT) : {}) }; // --no-sandbox: Ubuntu 24.04 runners block the sandbox of a downloaded Chrome
p.launch(opt).then(async b => { console.log("launched " + await b.version()); await b.close(); }).catch(e => console.log("ERR " + e.message.split("\n").slice(0,2).join(" | ").slice(0,220)));
J
pr() { rm -rf $1; mkdir $1 && cd $1 && npm init -y >/dev/null; cp ../t.cjs .; }
echo "######## 1. download skipped"
pr a; npm install puppeteer --ignore-scripts $Q 2>&1 | tail -1; echo "puppeteer $(node -p 'require("./node_modules/puppeteer/package.json").version')"
echo "-- --ignore-scripts"; node t.cjs
npx puppeteer browsers install chrome 2>&1 | grep -aoE "chrome@[0-9.]+" | head -1; echo "-- after npx puppeteer browsers install chrome"; node t.cjs
echo "-- 5. same cache (only chrome installed by hand), headless: 'shell'"; OPT='{"headless":"shell"}' node t.cjs
npx puppeteer browsers install chrome-headless-shell >/dev/null 2>&1; echo "-- after browsers install chrome-headless-shell"; OPT='{"headless":"shell"}' node t.cjs; cd ..
rm -rf $HOME/.cache/puppeteer
pr n12; npx -y npm@12 install puppeteer $Q 2>&1 | grep -aE "install-scripts   puppeteer" | head -1 | cut -c1-120; echo "-- npm 12 default"; node t.cjs
npx -y npm@12 install-scripts approve puppeteer >/dev/null 2>&1; npx -y npm@12 rebuild $Q >/dev/null 2>&1; echo "-- after approve + rebuild"; node t.cjs; cd ..
echo "######## 2. upgraded, browser behind"
rm -rf $HOME/.cache/puppeteer; PREV=$(npm view puppeteer versions --json | node -e 'const v=JSON.parse(require("fs").readFileSync(0)).filter(x=>/^\d+\.\d+\.\d+$/.test(x)); console.log(v[v.length-3])')
pr up; npm install puppeteer@$PREV $Q 2>&1 | tail -1; echo "-- on $PREV"; node t.cjs; npm install puppeteer@latest --ignore-scripts $Q 2>&1 | tail -1
echo "-- upgraded to $(node -p 'require("./node_modules/puppeteer/package.json").version') without download"; node t.cjs; cd ..
echo "######## 3. installed in one cache, run from another"
rm -rf $HOME/.cache/puppeteer; pr c; PUPPETEER_CACHE_DIR=$W/othercache npm install puppeteer $Q 2>&1 | tail -1; echo "-- installed with PUPPETEER_CACHE_DIR, run without"; node t.cjs
echo 'const {join}=require("path"); module.exports={cacheDirectory: join(__dirname, ".cache", "puppeteer")};' > .puppeteerrc.cjs; rm -rf node_modules; npm install $Q 2>&1 | tail -1
echo "-- with .puppeteerrc.cjs (project cache), no env vars"; node t.cjs; cd ..
echo "######## 5b. normal npm install downloads the shell too"
cd c; echo "-- headless: 'shell'"; OPT='{"headless":"shell"}' node t.cjs; cd ..
echo "######## 6. system Chrome"
rm -rf $HOME/.cache/puppeteer; pr s; npm install puppeteer --ignore-scripts $Q 2>&1 | tail -1
echo "-- empty cache, channel: 'chrome'"; OPT='{"channel":"chrome"}' node t.cjs
echo "-- empty cache, executablePath"; OPT="{\"executablePath\":\"$(which google-chrome)\"}" node t.cjs
echo "== done"
