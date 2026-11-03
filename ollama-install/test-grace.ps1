$ErrorActionPreference = 'Continue'
$dir = 'C:\Users\XYD\AppData\Local\Ollama'
$wps = Join-Path $dir 'watchdog.ps1'
$wvbs = Join-Path $dir 'start-watchdog.vbs'
$log = Join-Path $dir 'watchdog.log'

function Test-Port {
  $c = New-Object System.Net.Sockets.TcpClient
  try { $c.Connect('127.0.0.1', 11434); return $c.Connected } catch { return $false } finally { $c.Dispose() }
}

"=== 0. state before ==="
"port = " + (Test-Port)
"ollama pids = " + ((Get-Process -Name 'ollama*','llama-server*' -ErrorAction SilentlyContinue | ForEach-Object { $_.Id }) -join ',')

"=== 1. stop old watchdog (old code loaded) ==="
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
  Where-Object { $_.CommandLine -like '*-File*Ollama\watchdog.ps1*' } |
  ForEach-Object { "killing $($_.ProcessId)"; Stop-Process -Id $_.ProcessId -Force }
Start-Sleep -Seconds 2

"=== 2. grace-period stop test (fake pattern, grace 20s) ==="
$p = Start-Process -FilePath 'powershell.exe' -PassThru -WindowStyle Hidden -ArgumentList @(
  '-NoProfile','-ExecutionPolicy','Bypass','-File',('"' + $wps + '"'),
  '-Pattern','NoSuchAppXYZ*','-GraceSec','20','-IntervalSec','5','-SkipMutex','-ExitAfterStop')
"test watchdog pid = $($p.Id)"
$sw = [Diagnostics.Stopwatch]::StartNew()
$down = $false
while ($sw.Elapsed.TotalSeconds -lt 70) {
  if (-not (Test-Port)) { $down = $true; break }
  Start-Sleep -Milliseconds 500
}
"port_down = $down after " + [math]::Round($sw.Elapsed.TotalSeconds,1) + "s"
$p | Wait-Process -Timeout 20 -ErrorAction SilentlyContinue
"test watchdog exited = " + $p.HasExited

"=== 3. log after stop test ==="
Get-Content $log -Tail 6

"=== 4. restart real watchdog (DSH present, grace 300s) ==="
Start-Process -FilePath (Join-Path $env:WINDIR 'System32\wscript.exe') -ArgumentList ('"' + $wvbs + '"') -WindowStyle Hidden
$sw2 = [Diagnostics.Stopwatch]::StartNew()
$up = $false
while ($sw2.Elapsed.TotalSeconds -lt 60) {
  if (Test-Port) { $up = $true; break }
  Start-Sleep -Milliseconds 1000
}
"port_up = $up after " + [math]::Round($sw2.Elapsed.TotalSeconds,1) + "s"

"=== 5. embedding after heal ==="
try {
  $r = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/embed' -Method Post -ContentType 'application/json' -TimeoutSec 90 -Body '{"model":"nomic-embed-text","input":"grace test"}'
  "embed_dims = " + $r.embeddings[0].Count
} catch { "embed ERR " + $_.Exception.Message }

"=== 6. watchdog instances ==="
(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
  Where-Object { $_.CommandLine -like '*-File*Ollama\watchdog.ps1*' } |
  Select-Object ProcessId, CreationDate | Format-Table -AutoSize | Out-String -Width 160)

"=== 7. log tail ==="
Get-Content $log -Tail 8
