# The Windows "App execution alias" python.exe stub: what it prints, and how PATH order decides who answers.
$wa = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
"WindowsApps contents: " + ((Get-ChildItem $wa -ErrorAction SilentlyContinue | Where-Object Name -match 'python' | Select-Object -ExpandProperty Name) -join ', ')
"== run the stub directly"
foreach ($n in 'python.exe','python3.exe') { $p = Join-Path $wa $n; if (Test-Path $p) { "-- $n"; & $p --version 2>&1 | Select-Object -First 2; "exit $LASTEXITCODE" } }
"== where.exe python (PATH order)"
where.exe python 2>&1 | Select-Object -First 4
"== python --version with only WindowsApps + system dirs on PATH"
$env:PATH = "$wa;C:\Windows\System32;C:\Windows"
python --version 2>&1 | Select-Object -First 2
"exit $LASTEXITCODE"
"== py launcher present?"; (Get-Command py -ErrorAction SilentlyContinue).Source
