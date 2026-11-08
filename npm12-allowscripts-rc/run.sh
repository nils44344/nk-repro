#!/bin/bash
# npm 12: where can a persistent allow-scripts entry for a GLOBAL package live without breaking project installs? (8 Nov 2026)
set +e
npm install -g npm@12 --no-audit --no-fund --loglevel=error >/dev/null 2>&1
echo "node $(node -v) npm $(npm -v)"
W=${W:-/tmp/rc}; rm -rf $W; mkdir -p $W/proj $W/pfx; cd $W
echo '{"name":"p","version":"1.0.0"}' > proj/package.json
try() { # $1 label, $2 userconfig content, $3 globalconfig content
  printf '%s\n' "$2" > user.rc; printf '%s\n' "$3" > global.rc
  echo "== $1"
  (cd proj && rm -rf node_modules package-lock.json && npm install is-number@7 --no-audit --no-fund --userconfig ../user.rc --globalconfig ../global.rc 2>&1 | grep -E "EALLOW|not allowed|added|Unknown" | head -2 | sed 's/^/   project install: /')
  rm -rf pfx && mkdir pfx
  npm install -g @anthropic-ai/claude-code --prefix "$W/pfx" --no-audit --no-fund --userconfig user.rc --globalconfig global.rc 2>&1 | grep -E "EALLOW|blocked|added" | head -2 | sed 's/^/   global install: /'
  f=$(find pfx -path '*claude-code/bin/claude*' -type f | head -1); echo "   claude binary bytes: $(stat -c %s "$f" 2>/dev/null)"
}
try "no config" "" ""
try "user .npmrc: allow-scripts=@anthropic-ai/claude-code" "allow-scripts=@anthropic-ai/claude-code" ""
try "global npmrc: allow-scripts=@anthropic-ai/claude-code" "" "allow-scripts=@anthropic-ai/claude-code"
try "user .npmrc: allowScripts[]=@anthropic-ai/claude-code" "allowScripts[]=@anthropic-ai/claude-code" ""

echo "== child npm install (via npm run / npx), user .npmrc has allow-scripts=@anthropic-ai/claude-code"
printf 'allow-scripts=@anthropic-ai/claude-code\n' > user.rc; printf '' > global.rc
cd proj && rm -rf node_modules package-lock.json
npm pkg set scripts.inst="npm install is-number@7 --no-audit --no-fund" >/dev/null
echo "   direct npm install:"; npm install is-number@7 --no-audit --no-fund --userconfig ../user.rc 2>&1 | grep -E "EALLOW|added" | head -1 | sed 's/^/      /'
rm -rf node_modules package-lock.json
echo "   npm run inst (child npm):"; NPM_CONFIG_USERCONFIG=../user.rc npm run inst 2>&1 | grep -E "EALLOW|added" | head -1 | sed 's/^/      /'
rm -rf node_modules package-lock.json
echo "   env npm_config_allow_scripts set:"; npm_config_allow_scripts=@anthropic-ai/claude-code npm install is-number@7 --no-audit --no-fund 2>&1 | grep -E "EALLOW|added" | head -1 | sed 's/^/      /'
