# AI coding agent CLIs on Windows: global npm install, --version, and the first run with no account, on npm 11 and 12.
# Each install goes to its own prefix; first runs use a throwaway profile (USERPROFILE/APPDATA/LOCALAPPDATA in temp).
$ErrorActionPreference = 'Continue'
if ($env:NPM) { npm install -g "npm@$env:NPM" --no-audit --no-fund --loglevel=error 2>&1 | Out-Null }
"== $(Get-Date -Format o) node $(node -v) npm $(npm -v) $((Get-CimInstance Win32_OperatingSystem).Caption)"
$agents = @(
  @{ name = 'Claude Code'; pkg = '@anthropic-ai/claude-code'; bin = 'claude' },
  @{ name = 'Codex CLI';   pkg = '@openai/codex';             bin = 'codex' },
  @{ name = 'Gemini CLI';  pkg = '@google/gemini-cli';        bin = 'gemini' },
  @{ name = 'Copilot CLI'; pkg = '@github/copilot';           bin = 'copilot' },
  @{ name = 'OpenCode';    pkg = 'opencode-ai';               bin = 'opencode' })
foreach ($a in $agents) {
  $p = "$env:RUNNER_TEMP\pfx-$($a.bin)"; New-Item -ItemType Directory -Force $p | Out-Null
  $ins = cmd /c "npm install -g $($a.pkg) --prefix `"$p`" --no-audit --no-fund 2>&1"
  $blocked = ($ins | Select-String 'install-scripts   ' | ForEach-Object { ($_.Line -split 'install-scripts\s+')[1] }) -join '; '
  $ver = (Get-Content "$p\node_modules\$($a.pkg)\package.json" -Raw -EA 0 | ConvertFrom-Json).version
  $v = cmd /c "`"$p\$($a.bin).cmd`" --version 2>&1" | Select-Object -First 1
  "-- $($a.name) $ver | blocked: $(if ($blocked) { $blocked } else { 'none' }) | --version: $(([string]$v).Substring(0, [Math]::Min(120, ([string]$v).Length)))"
  $h = "$env:RUNNER_TEMP\home-$($a.bin)"; New-Item -ItemType Directory -Force "$h\AppData\Roaming", "$h\AppData\Local" | Out-Null
  $env:USERPROFILE = $h; $env:HOME = $h; $env:APPDATA = "$h\AppData\Roaming"; $env:LOCALAPPDATA = "$h\AppData\Local"
  $j = Start-Job -ScriptBlock { param($c) cmd /c "`"$c`" -p hi 2>&1 < NUL" } -ArgumentList "$p\$($a.bin).cmd"
  if (Wait-Job $j -Timeout 40) { $o = Receive-Job $j } else { Stop-Job $j; $o = "(still running after 40 s)" }
  "   first run, no account: $((($o | Where-Object { $_ -and $_ -notmatch '^\s*$' } | Select-Object -First 2) -join ' / ').Substring(0, [Math]::Min(170, (($o | Where-Object { $_ }) -join ' / ').Length)))"
  Remove-Job $j -Force -EA 0
  $env:USERPROFILE = $env:ORIG_USERPROFILE; $env:HOME = $env:ORIG_USERPROFILE; $env:APPDATA = $env:ORIG_APPDATA; $env:LOCALAPPDATA = $env:ORIG_LOCALAPPDATA
}
"######## PowerShell execution policy (process scope Restricted), the .ps1 shim"
$c = "$env:RUNNER_TEMP\pfx-codex"
powershell.exe -NoProfile -ExecutionPolicy Restricted -Command "& '$c\codex.ps1' --version" 2>&1 | Select-Object -First 1 | ForEach-Object { "   Restricted: $($_.ToString().Substring(0, [Math]::Min(150, $_.ToString().Length)))" }
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -Command "& '$c\codex.ps1' --version" 2>&1 | Select-Object -First 1 | ForEach-Object { "   RemoteSigned: $_" }
"   via the .cmd under Restricted: $(powershell.exe -NoProfile -ExecutionPolicy Restricted -Command "& '$c\codex.cmd' --version" 2>&1 | Select-Object -First 1)"
"== done"
