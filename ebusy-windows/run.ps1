# npm EBUSY / EPERM on Windows: a process whose current folder is inside node_modules, esbuild.exe running,
# a Node process with sharp loaded; finding the process; retries that don't help.
$ErrorActionPreference = 'Continue'
$P = "$env:RUNNER_TEMP\ebusy\proj"; New-Item -ItemType Directory -Force $P | Out-Null; Set-Location $P
"== $(Get-Date -Format o) node $(node -v) npm $(npm -v)"
npm init -y | Out-Null; npm install esbuild sharp --no-audit --no-fund --loglevel=error 2>&1 | Select-Object -Last 1
"esbuild $((Get-Content node_modules\esbuild\package.json -Raw | ConvertFrom-Json).version) sharp $((Get-Content node_modules\sharp\package.json -Raw | ConvertFrom-Json).version)"
function Ci { (cmd /c "npm ci --no-audit --no-fund 2>&1") | Select-String -Pattern 'code E|syscall|errno|path |added' | Select-Object -First 4 | ForEach-Object { "   $($_.Line)" } }
"######## 1. a process sitting inside node_modules\esbuild"
$p1 = Start-Process node -ArgumentList '-e "setInterval(()=>{},1000)"' -WorkingDirectory "$P\node_modules\esbuild" -PassThru -WindowStyle Hidden; Start-Sleep 2
"-- npm ci"; Ci
"-- Get-CimInstance shows:"; Get-CimInstance Win32_Process -Filter "Name='node.exe'" | Where-Object { $_.ProcessId -eq $p1.Id } | ForEach-Object { "   $($_.ProcessId) $($_.CommandLine)" }
Stop-Process -Id $p1.Id -Force; Start-Sleep 1; "-- after Stop-Process"; Ci
"######## 2. esbuild.exe running"
Set-Content in.js 'console.log(1)'
$p2 = Start-Process "$P\node_modules\@esbuild\win32-x64\esbuild.exe" -ArgumentList 'in.js --watch=forever --outfile=out.js' -PassThru -WindowStyle Hidden; Start-Sleep 2
"-- npm ci"; Ci
"-- fs.rmSync(node_modules, maxRetries: 3)"; node -e "try{require('fs').rmSync('node_modules',{recursive:true,force:true,maxRetries:3,retryDelay:300});console.log('   removed')}catch(e){console.log('   '+e.code+' '+e.message.slice(0,90))}"
Stop-Process -Id $p2.Id -Force; Start-Sleep 1; Remove-Item -Recurse -Force node_modules -EA 0; "-- after stopping it"; Ci
"######## 3. a Node process with sharp loaded"
$p3 = Start-Process node -ArgumentList '-e "require(''sharp''); setInterval(()=>{},1000)"' -WorkingDirectory $P -PassThru -WindowStyle Hidden; Start-Sleep 3
"-- npm ci"; Ci
"-- Get-Process node | Modules like *\proj\node_modules\*:"; Get-Process node | Where-Object { $_.Modules.FileName -like '*\proj\node_modules\*' } | ForEach-Object { "   $($_.Id) found (started $($p3.Id))" }
Stop-Process -Id $p3.Id -Force; Start-Sleep 1; "-- after stopping it"; Ci
"== done"
