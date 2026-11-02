# EADDRINUSE on Windows: find and stop the process holding the port (PowerShell and netstat/taskkill), Python's
# WinError 10048, npx kill-port, reserved port ranges (EACCES), and two apps on one port via IPv4 vs IPv6.
$ErrorActionPreference = 'Continue'
"== $(Get-Date -Format o) node $(node -v) $(python --version) $((Get-CimInstance Win32_OperatingSystem).Caption)"
$srv = 'const p=+process.argv[2],h=process.argv[3];require("http").createServer((q,r)=>r.end("node app")).listen(p,h,()=>console.log("listening",p,h||"(default)")).on("error",e=>{console.log(e.code+": "+e.message);process.exit(1)})'
Set-Content srv.js $srv
function Start-Bg($port, $hostname) { Start-Process node -ArgumentList "srv.js $port $hostname" -PassThru -WindowStyle Hidden }
"######## 1. second server on a busy port"
$a = Start-Bg 3000; Start-Sleep 2
"-- second node on 3000:"; node srv.js 3000
$pid1 = (Get-NetTCPConnection -LocalPort 3000 -State Listen | Select-Object -First 1).OwningProcess
"-- Get-NetTCPConnection OwningProcess: $pid1 (started server PID $($a.Id)) match=$($pid1 -eq $a.Id)"
$ns = (netstat -ano | findstr ":3000" | findstr LISTENING | Select-Object -First 1); "-- netstat line: $($ns.Trim())"
Stop-Process -Id $pid1 -Force; Start-Sleep 1
"-- after Stop-Process:"; $b = Start-Bg 3000; Start-Sleep 2; "   localhost:3000 -> $(curl.exe -s http://localhost:3000/)"
"-- taskkill:"; $pid2 = (Get-NetTCPConnection -LocalPort 3000 -State Listen | Select-Object -First 1).OwningProcess; taskkill /PID $pid2 /F
"######## 2. Python on the busy port"
$c = Start-Bg 3001; Start-Sleep 2
$pyout = cmd /c "python -c ""import socket; s=socket.socket(); s.bind(('0.0.0.0',3001)); s.listen(); print('python bound 0.0.0.0:3001 without error')"" 2>&1"; "   python: $(($pyout | Select-Object -Last 1))"
$pyout6 = cmd /c "python -c ""import socket; s=socket.socket(socket.AF_INET6); s.bind(('::',3001)); s.listen(); print('python bound [::]:3001 without error')"" 2>&1"; "   python (IPv6 ::): $(($pyout6 | Select-Object -Last 1))"
"   node holds: $((netstat -ano | findstr ':3001' | findstr LISTENING | ForEach-Object { ($_ -split '\s+')[2] }) -join ' ')"
"-- Python holding 3002, a second Python binds it:"
$h = Start-Process python -ArgumentList "-c `"import socket,time; s=socket.socket(); s.bind(('0.0.0.0',3002)); s.listen(); time.sleep(60)`"" -PassThru -WindowStyle Hidden; Start-Sleep 2
$o = cmd /c "python -c ""import socket; s=socket.socket(); s.bind(('0.0.0.0',3002)); print('bound without error')"" 2>&1"; "   $(($o | Select-String 'OSError|bound' | Select-Object -First 1))"
"-- Python holding 3002, node listens on it:"; $j = Start-Job { node "$using:PWD\srv.js" 3002 }; Wait-Job $j -Timeout 5 | Out-Null; "   $((Receive-Job $j) -join ' ')"; Stop-Job $j; Get-Process node -EA 0 | Where-Object { (Get-NetTCPConnection -OwningProcess $_.Id -LocalPort 3002 -State Listen -EA 0) } | Stop-Process -Force
"######## 3. npx kill-port"
npx -y kill-port 3001 2>&1 | Select-Object -Last 1; Start-Sleep 1; "   port 3001 free: $(-not (Get-NetTCPConnection -LocalPort 3001 -State Listen -EA 0))"
"######## 4. reserved port ranges"
$ranges = netsh interface ipv4 show excludedportrange protocol=tcp | Select-String '^\s+\d+\s+\d+' | ForEach-Object { $p = ($_ -split '\s+') | Where-Object { $_ }; [pscustomobject]@{Start=[int]$p[0]; End=[int]$p[1]} }
"   excluded ranges: $(($ranges | ForEach-Object { "$($_.Start)-$($_.End)" }) -join ', ')"
if ($ranges) { $r = $ranges | Select-Object -First 1; "-- node on $($r.Start) (inside a range):"; node srv.js $r.Start } else { "   (no excluded ranges on this machine)" }
"######## 5. IPv4 127.0.0.1 vs IPv6 :: on the same port"
$py = Start-Process python -ArgumentList "-c `"import http.server as h; h.HTTPServer(('127.0.0.1',3013), type('H',(h.BaseHTTPRequestHandler,),{'do_GET':lambda s:(s.send_response(200),s.end_headers(),s.wfile.write(b'python app'))})).serve_forever()`"" -PassThru -WindowStyle Hidden
Start-Sleep 2; $n = Start-Bg 3013 '::'; Start-Sleep 2
"-- curl localhost:3013 -> $(curl.exe -s http://localhost:3013/)"; "-- curl 127.0.0.1:3013 -> $(curl.exe -s http://127.0.0.1:3013/)"
netstat -ano | findstr ":3013" | findstr LISTENING | ForEach-Object { "   $($_.Trim())" }
Get-Process node, python -EA 0 | Stop-Process -Force -EA 0
"== done"
