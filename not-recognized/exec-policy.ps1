# The neighbour of "is not recognized": a globally installed CLI found on PATH, but PowerShell refuses its .ps1 shim
# under the Restricted execution policy (8 Nov 2026). Policies are set per process only.
$ErrorActionPreference = 'Continue'
"== $(Get-Date -Format o) node $(node -v) npm $(npm -v)"
npm install -g cowsay@1.6.0 --no-audit --no-fund --loglevel=error 2>&1 | Select-Object -Last 1
"shims: $((Get-ChildItem "$(npm prefix -g)\cowsay*" | ForEach-Object Name) -join ', ')"
foreach ($p in 'Restricted', 'RemoteSigned') {
  "-- Windows PowerShell 5.1, -ExecutionPolicy $p : cowsay hi"
  powershell.exe -NoProfile -ExecutionPolicy $p -Command "try { cowsay hi | Select-Object -First 2 } catch { `$_.Exception.Message.Split([Environment]::NewLine)[0] }" 2>&1 | Select-Object -First 2 | ForEach-Object { "   $_" }
}
"-- Windows PowerShell 5.1, -ExecutionPolicy Restricted : cowsay.cmd hi"
powershell.exe -NoProfile -ExecutionPolicy Restricted -Command "cowsay.cmd hi | Select-Object -First 2" 2>&1 | Select-Object -First 2 | ForEach-Object { "   $_" }
"-- cmd.exe : cowsay hi"
cmd /c "cowsay hi 2>&1" | Select-Object -First 2 | ForEach-Object { "   $_" }
"== done"
