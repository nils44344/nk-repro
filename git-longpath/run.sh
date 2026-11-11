#!/usr/bin/env bash
# git "Filename too long" on Windows: clone with and without core.longpaths, and rescuing a failed clone.
set -u
W="${RUNNER_TEMP:-/tmp}/lp"; rm -rf "$W"; mkdir -p "$W"; cd "$W"
echo "== git $(git --version)"
echo "== core.longpaths already set anywhere:"; git config --show-origin --get-all core.longpaths || echo "(not set)"
powershell -NoProfile -Command "'LongPathsEnabled = ' + (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem').LongPathsEnabled" 2>/dev/null
# source repo with one file whose full path in a clone at $W/cX is about 290 characters
REL="node_modules/@some-scope/a-rather-long-package-name-for-testing/dist/esm/components/generated/very/deeply/nested/folder/structure/that/keeps/going/and-going-a-little-further-than-most-tools-expect-it-to-go-on-windows/an-equally-long-file-name-for-the-generated-component-module-x.js"
git -c core.longpaths=true init -q src && cd src
git config user.email t@e.st; git config user.name t; git config core.longpaths true
mkdir -p "$(dirname "$REL")" && echo "export default 1" > "$REL" && git add -A && git commit -qm one && cd ..
echo "== full path length in a clone: $(cygpath -w "$W/c1/$REL" | wc -c)"
echo "== 1. clone with core.longpaths=false"
git clone -q -c core.longpaths=false src c1 2>&1 | grep -v "^warning: Clone succeeded" | head -3
(cd c1 && echo "status: $(git status --short | head -2)")
echo "== 2. clone with core.longpaths=true"
git clone -q -c core.longpaths=true src c2 2>&1 | head -3
(cd c2 && echo "status: [$(git status --short)] file exists: $(test -f "$REL" && echo yes || echo no)")
echo "== 3. rescue c1 without --staged"
cp -r c1 c3 2>/dev/null; (cd c1 && git config core.longpaths true && git restore --source=HEAD :/ && echo "status: [$(git status --short)] file exists: $(test -f "$REL" && echo yes || echo no)")
echo "== 4. rescue (fresh failed clone) with --staged --worktree"
git clone -q -c core.longpaths=false src c4 2>/dev/null
(cd c4 && git config core.longpaths true && git restore --source=HEAD --staged --worktree :/ && echo "status: [$(git status --short)] file exists: $(test -f "$REL" && echo yes || echo no)")
echo "== 5. long file names with Node"
for n in 250 255 256 300; do node -e "const p=require('path').join(process.argv[1],'x'.repeat(+process.argv[2]));try{require('fs').writeFileSync(p,'1');console.log(process.argv[2],'ok')}catch(e){console.log(process.argv[2],e.code,e.message.split(',')[0])}" "$W" $n; done
