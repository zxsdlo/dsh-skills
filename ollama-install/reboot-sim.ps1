$ErrorActionPreference = 'Continue'
$vbs = 'C:\Users\XYD\AppData\Local\Ollama\start-ollama-hidden.vbs'

# --- 1. 固定自启项 ---
$cmd = 'wscript.exe "' + $vbs + '"'
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OllamaEmbedServer' -Value $cmd -Type String
"RUNKEY = " + (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run').OllamaEmbedServer
"VBS_EXISTS = " + (Test-Path $vbs)

function Test-Port {
  $c = New-Object System.Net.Sockets.TcpClient
  try { $c.Connect('127.0.0.1', 11434); return $c.Connected } catch { return $false } finally { $c.Dispose() }
}

# --- 2. 杀光 ollama，模拟关机 ---
Get-Process -Name 'ollama*' -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 3
"port_before = " + (Test-Port)

# --- 3. 只从持久入口拉起（等价于重新登录） ---
Start-Process -FilePath 'wscript.exe' -ArgumentList ('"' + $vbs + '"') -WindowStyle Hidden
Start-Sleep -Seconds 9
"port_after = " + (Test-Port)
(Get-Process -Name 'ollama*' -ErrorAction SilentlyContinue | Select-Object Id, StartTime | Format-Table -AutoSize | Out-String)
try { "version = " + (Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/version' -TimeoutSec 10 -UseBasicParsing).Content } catch { "version ERR " + $_.Exception.Message }
try {
  $r = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/embed' -Method Post -ContentType 'application/json' -TimeoutSec 60 -Body '{"model":"nomic-embed-text","input":"reboot sim"}'
  "embed_dims = " + $r.embeddings[0].Count
} catch { "embed ERR " + $_.Exception.Message }
