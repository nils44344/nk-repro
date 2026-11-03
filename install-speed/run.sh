#!/bin/bash
# npm vs pnpm vs Bun vs Yarn 1 install speed on the blog's own package.json: cold (empty cache, no lockfile),
# warm (cache + lockfile, node_modules deleted), no change. Separate cache per tool and round; rotating order.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; HERE=$(cd "$(dirname "$0")" && pwd); ROUNDS=${ROUNDS:-3}
npm install -g pnpm@12.5.1 yarn@1.22.22 --no-audit --no-fund --loglevel=error >/dev/null 2>&1
echo "== $(date -u) $(uname -s) node $(node -v) npm $(npm -v) pnpm $(pnpm -v) bun $(bun -v) yarn $(yarn -v), $(nproc 2>/dev/null || echo $NUMBER_OF_PROCESSORS) cpus"
now() { node -e 'console.log(Date.now())'; }
t() { local s=$(now); "$@" > last.log 2>&1; local c=$?; local e=$(now); node -e "process.stdout.write(((${e}-${s})/1000).toFixed(2))"; [ $c = 0 ] || { printf '(exit %s: %s)' $c "$(grep -m1 -aiE 'err|error' last.log | cut -c1-90)"; }; }
cmd() { case $1 in
  npm) echo "npm install --no-audit --no-fund --cache $C" ;;
  pnpm) echo "pnpm install --store-dir $C/store" ;;
  bun) echo "env BUN_INSTALL_CACHE_DIR=$C bun install" ;;
  yarn) echo "yarn install --cache-folder $C --non-interactive" ;; esac; }
order=(npm pnpm bun yarn)
for r in $(seq 1 $ROUNDS); do
  for tool in "${order[@]}"; do
    D=$W/r$r-$tool; C=$W/cache-r$r-$tool; rm -rf $D $C; mkdir -p $D; cp $HERE/package.json $D/
    [ $tool = pnpm ] && printf 'allowBuilds:\n  esbuild: true\n  workerd: true\n  sharp: true\n' > $D/pnpm-workspace.yaml
    [ $tool = bun ] && node -e 'const f=process.argv[1],p=require(f);p.trustedDependencies=["esbuild","workerd","sharp"];require("fs").writeFileSync(f,JSON.stringify(p,null,2))' $D/package.json
    cd $D; c=$(t $(cmd $tool)); rm -rf node_modules; w=$(t $(cmd $tool)); n=$(t $(cmd $tool))
    sz=$(du -sm $C 2>/dev/null | cut -f1); nm=$(ls node_modules 2>/dev/null | wc -l); echo "round $r $tool: cold $c s | warm $w s | no change $n s | cache ${sz:-0} MB | node_modules entries $nm"; cd $W
  done
  order=("${order[@]:1}" "${order[0]}")
done
echo "######## pnpm 12 without allowBuilds"
D=$W/pnpm-noallow; rm -rf $D; mkdir -p $D; cp $HERE/package.json $D/; cd $D
pnpm install --store-dir $W/st2 2>&1 | grep -aE "ERR_PNPM|Ignored build|allowBuilds|approve" | head -3 | cut -c1-180; echo "   exit ${PIPESTATUS[0]}"
echo "== done"
