$vbs = 'C:\Users\XYD\AppData\Local\Ollama\start-ollama-hidden.vbs'
$cmd = 'wscript.exe "' + $vbs + '"'
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OllamaEmbedServer' -Value $cmd -Type String
"RUNKEY = " + (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run').OllamaEmbedServer
"VBS_EXISTS = " + (Test-Path $vbs)
