# Claude Code's claude.exe after an npm 12 global install on Windows: blocked postinstall, 500-byte placeholder, and each fix.
$ErrorActionPreference = 'Continue'
$npmMajor = if ($env:NPM_MAJOR) { $env:NPM_MAJOR } else { '12' }
npm install -g npm@$npmMajor --no-audit --no-fund --loglevel=error | Out-Null
"claude-code on npm: $(npm view @anthropic-ai/claude-code version)"
"== $(Get-Date -Format o) node $(node -v) npm $(npm -v) $((Get-CimInstance Win32_OperatingSystem).Caption)"
function Try-Prefix($name, $extra) {
  $p = "$env:RUNNER_TEMP\$name"; New-Item -ItemType Directory -Force $p | Out-Null
  "-- $name : npm install -g @anthropic-ai/claude-code $extra"
  $out = & cmd /c "npm install -g @anthropic-ai/claude-code --prefix `"$p`" $extra --no-audit --no-fund 2>&1"
  $out | Select-String -Pattern 'added|install-scripts|EALLOW|error' | Select-Object -First 4 | ForEach-Object { "   $_" }
  $exe = Get-ChildItem "$p\node_modules\@anthropic-ai\claude-code\bin\claude.exe" -EA 0
  "   claude.exe bytes: $($exe.Length)"
  $v = & cmd /c "`"$p\claude.cmd`" --version 2>&1"; "   claude --version: $(($v | Select-Object -First 2) -join ' | ')"
}
Try-Prefix 'plain' ''
Try-Prefix 'allow' '--allow-scripts=@anthropic-ai/claude-code'
$cfg = "$env:RUNNER_TEMP\userrc"; Set-Content -Path $cfg -Value 'allow-scripts=@anthropic-ai/claude-code' -Encoding ascii
$env:NPM_CONFIG_USERCONFIG = $cfg; Try-Prefix 'userconfig' ''; Remove-Item Env:NPM_CONFIG_USERCONFIG
"== done"
