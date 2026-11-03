# npm ENOENT on Windows: no package.json, spawn ENOENT (missing program, npx without .cmd, npx.cmd -> EINVAL, the fixes),
# a file: dependency pointing at a missing folder, and a script calling a missing file.
$ErrorActionPreference = 'Continue'
$W = "$env:RUNNER_TEMP\enoent"; New-Item -ItemType Directory -Force $W | Out-Null; Set-Location $W
"== $(Get-Date -Format o) node $(node -v) npm $(npm -v)"
function C($cmd) { (cmd /c "$cmd 2>&1") | Where-Object { $_ -and $_ -notmatch '^\s*at |^\s*$|^> ' } | Select-Object -First 3 | ForEach-Object { "   $_" } }
"######## 1. no package.json here"; New-Item -ItemType Directory -Force c1 | Out-Null; Set-Location c1
C "npm install"; Set-Location $W
"######## 2. spawn ENOENT"; New-Item -ItemType Directory -Force c2 | Out-Null; Set-Location c2; npm init -y | Out-Null
npm install cross-spawn --no-audit --no-fund --loglevel=error 2>&1 | Out-Null
"cross-spawn $((Get-Content node_modules\cross-spawn\package.json -Raw | ConvertFrom-Json).version)"
$js = @{
  'missing program' = "require('child_process').spawn('git-lfs-nope',['x']).on('error',e=>console.log(e.message))";
  "spawn('npx')" = "require('child_process').spawn('npx',['--version']).on('error',e=>console.log(e.message))";
  "spawn('npx.cmd')" = "try{require('child_process').spawn('npx.cmd',['--version']).on('error',e=>console.log(e.message))}catch(e){console.log(e.code+' '+e.message)}";
  "spawn('npx --version', {shell:true})" = "require('child_process').spawn('npx --version',{shell:true,stdio:'inherit'})";
  "cross-spawn('npx',['--version'])" = "require('cross-spawn')('npx',['--version'],{stdio:'inherit'})";
  "spawn('npx',['--version'],{shell:true})" = "require('child_process').spawn('npx',['--version'],{shell:true,stdio:'inherit'})" }
foreach ($k in $js.Keys) { Set-Content t.js $js[$k]; "-- $k"; C "node t.js" }
Set-Location $W
"######## 3. file: dependency to a missing folder"; New-Item -ItemType Directory -Force c3 | Out-Null; Set-Location c3; npm init -y | Out-Null
npm pkg set "dependencies.mylib=file:../mylib"; "-- npm install"; C "npm install --no-audit --no-fund"; "   exit code $LASTEXITCODE"
Set-Content u.js "require('mylib')"; "-- node u.js"; C "node u.js"; Set-Location $W
"######## 4. script calls a missing file"; New-Item -ItemType Directory -Force c4 | Out-Null; Set-Location c4; npm init -y | Out-Null
npm pkg set "scripts.build=node scripts/build.js"; "-- npm run build"; C "npm run build"
"== done"
