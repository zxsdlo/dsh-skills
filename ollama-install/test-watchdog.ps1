$ErrorActionPreference = 'Continue'
$dir = 'C:\Users\XYD\AppData\Local\Ollama'
$wps = Join-Path $dir 'watchdog.ps1'
$wvbs = Join-Path $dir 'start-watchdog.vbs'

function Test-Port {
  $c = New-Object System.Net.Sockets.TcpClient
  try { $c.Connect('127.0.0.1', 11434); return $c.Connected } catch { return $false } finally { $c.Dispose() }
}

"=== 1. negative: fake pattern (should say no action) ==="
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $wps -Once -Pattern 'NoSuchAppXYZ*' 2>&1

"=== 2. register Run key OllamaEmbedWatchdog ==="
$cmd = 'wscript.exe "' + $wvbs + '"'
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OllamaEmbedWatchdog' -Value $cmd -Type String
"RUNKEY = " + (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run').OllamaEmbedWatchdog

"=== 3. start watchdog hidden ==="
Start-Process -FilePath (Join-Path $env:WINDIR 'System32\wscript.exe') -ArgumentList ('"' + $wvbs + '"') -WindowStyle Hidden
Start-Sleep -Seconds 5
(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -like '*watchdog.ps1*' } | Select-Object ProcessId, CommandLine | Format-Table -AutoSize | Out-String -Width 200)

"=== 4. kill ollama (DSH is running) ==="
Get-Process -Name 'ollama*','llama-server*' -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 3
"port_after_kill = " + (Test-Port)

"=== 5. wait for watchdog to heal (max 70s) ==="
$sw = [Diagnostics.Stopwatch]::StartNew()
$ok = $false
while ($sw.Elapsed.TotalSeconds -lt 70) {
  if (Test-Port) { $ok = $true; break }
  Start-Sleep -Milliseconds 1000
}
"healed = $ok in " + [math]::Round($sw.Elapsed.TotalSeconds,1) + "s"

"=== 6. embedding after heal ==="
try {
  $r = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/embed' -Method Post -ContentType 'application/json' -TimeoutSec 90 -Body '{"model":"nomic-embed-text","input":"watchdog heal"}'
  "embed_dims = " + $r.embeddings[0].Count
} catch { "embed ERR " + $_.Exception.Message }

"=== 7. watchdog.log tail ==="
Get-Content (Join-Path $dir 'watchdog.log') -Tail 12 -ErrorAction SilentlyContinue
