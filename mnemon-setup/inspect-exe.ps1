param([string]$Path = 'D:\memos.exe')
if (-not (Test-Path -LiteralPath $Path)) { "MISSING: $Path"; exit 1 }
$fs = [IO.File]::OpenRead($Path)
try {
  $len = [int]$fs.Length
  $buf = New-Object byte[] $len
  $read = 0
  while ($read -lt $len) { $n = $fs.Read($buf, $read, $len - $read); if ($n -le 0) { break }; $read += $n }
  "read=$read bytes"
} finally { $fs.Dispose() }
$s = [Text.Encoding]::ASCII.GetString($buf)
foreach ($k in 'usememos','memos.APP','mnemon','MemOS','memtensor') {
  "{0}`t{1}" -f $k, ([regex]::Matches($s, [regex]::Escape($k))).Count
}
