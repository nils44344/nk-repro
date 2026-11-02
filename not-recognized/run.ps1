# Windows "'x' is not recognized as an internal or external command": the five causes, in cmd.exe and PowerShell.
$ErrorActionPreference = 'Continue'
$W = "$env:RUNNER_TEMP\nr"; New-Item -ItemType Directory -Force $W | Out-Null; Set-Location $W
"== $(Get-Date -Format o) node $(node -v) npm $(npm -v) $((Get-CimInstance Win32_OperatingSystem).Caption)"
npm init -y | Out-Null; npm pkg set scripts.dev="vite --version"; npm install -D vite@8 --no-audit --no-fund --loglevel=error 2>&1 | Select-Object -Last 1
function C($cmd) { (cmd /c "$cmd 2>&1" | Select-Object -First 2 | ForEach-Object { "   $_" }) }
"######## 1. installed locally, called directly"
"-- cmd: vite --version"; C "vite --version"
"-- PowerShell: vite --version"; try { vite --version 2>&1 | Out-Null } catch { "   $($_.Exception.Message.Split([Environment]::NewLine)[0])" }
"-- npx vite --version"; C "npx vite --version"; "-- npm run dev"; C "npm run dev" | Select-String "vite/" 
"######## 2. not installed in this folder (node_modules renamed)"
Rename-Item node_modules nm_away; "-- npm run dev"; C "npm run dev" | Select-String "not recognized|vite/"; Rename-Item nm_away node_modules
"######## 3. shim gone"
Remove-Item node_modules\.bin\vite, node_modules\.bin\vite.cmd, node_modules\.bin\vite.ps1 -EA 0
"-- npm ls vite: $((npm ls vite 2>&1 | Select-String 'vite@') -join ' ')"; "-- npm run dev"; C "npm run dev" | Select-String "not recognized|vite/"
npm install vite --force --no-audit --no-fund --loglevel=error 2>&1 | Out-Null; "-- after npm install vite --force: shims $((Get-ChildItem node_modules\.bin\vite* | ForEach-Object Name) -join ', ')"; C "npm run dev" | Select-String "vite/"
"######## 4. installed globally, prefix not on PATH"
npm install -g cowsay --prefix "$W\gtemp" --no-audit --no-fund --loglevel=error 2>&1 | Select-Object -Last 1
"-- cowsay hi"; C "cowsay hi"; "-- full path"; C "`"$W\gtemp\cowsay.cmd`" hi" | Select-Object -First 1
"######## 5. NODE_ENV=... in a script"
npm pkg set scripts.env="NODE_ENV=development node -e `"console.log('NODE_ENV='+process.env.NODE_ENV)`""
"-- npm run env"; C "npm run env" | Select-String "not recognized|NODE_ENV="
npm install -D cross-env --no-audit --no-fund --loglevel=error 2>&1 | Out-Null
npm pkg set scripts.env="cross-env NODE_ENV=development node -e `"console.log('NODE_ENV='+process.env.NODE_ENV)`""
"-- with cross-env ($(node -p 'require(\"./node_modules/cross-env/package.json\").version'))"; C "npm run env" | Select-String "not recognized|NODE_ENV="
"== done"
