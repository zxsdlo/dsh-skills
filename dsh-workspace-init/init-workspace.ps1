param(
  [string]$Target = "",
  [switch]$Push,
  [switch]$SkipShim
)

# ---------------------------------------------------------------------------
# dsh-workspace-init: 把一个工作区初始化成 mattpocock 技能套件可用的状态
# 幂等：已存在的文件不覆盖，只补缺失的部分
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false } catch {}

$kit = $PSScriptRoot
if (-not $kit) { $kit = Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $Target) { $Target = $kit }
$Target = $Target.Trim().Trim([char]34).TrimEnd([char]92)
try { $Target = (Resolve-Path -LiteralPath $Target -ErrorAction Stop).Path }
catch { Write-Host ('目标目录无效：' + $Target) -ForegroundColor Red; exit 1 }

$script:problems = 0
function Step($n, $t) { Write-Host ''; Write-Host ("== {0}. {1}" -f $n, $t) -ForegroundColor Cyan }
function Ok($m)   { Write-Host ('   [OK]   ' + $m) -ForegroundColor Green }
function Skip($m) { Write-Host ('   [SKIP] ' + $m) -ForegroundColor DarkGray }
function Bad($m)  { Write-Host ('   [WARN] ' + $m) -ForegroundColor Yellow; $script:problems++ }
function Info($m) { Write-Host ('   ...    ' + $m) -ForegroundColor Gray }

function Find-Exe {
  param([string[]]$paths)
  foreach ($p in $paths) { if ($p -and (Test-Path -LiteralPath $p)) { return $p } }
  return $null
}
function Cmd-Source($name) {
  $c = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($c) { return $c.Source }
  return $null
}
function Append-Lines {
  param([string]$Path, [string[]]$Lines)
  $existing = @()
  if (Test-Path -LiteralPath $Path) { $existing = [IO.File]::ReadAllLines($Path) }
  $add = @()
  foreach ($l in $Lines) { if ($existing -notcontains $l) { $add += $l } }
  if ($add.Count -eq 0) { return 0 }
  $out = ($existing + $add) -join "`r`n"
  [IO.File]::WriteAllText($Path, $out + "`r`n", (New-Object System.Text.UTF8Encoding $false))
  return $add.Count
}

Write-Host 'dsh-workspace-init' -ForegroundColor White
Write-Host ('  target : ' + $Target)
Write-Host ('  kit    : ' + $kit)
Write-Host ('  push   : ' + [bool]$Push)

# ---------------------------------------------------------------- 1. 工具
Step 1 '定位 git / gh / bash'
$bashCand = Cmd-Source 'bash.exe'
if ($bashCand -and $bashCand -like '*\System32\bash.exe') { $bashCand = $null }  # WSL 存根，不能用
$git  = Find-Exe @((Cmd-Source 'git.exe'), (Join-Path $env:LOCALAPPDATA 'Programs\PortableGit\bin\git.exe'), 'C:\Program Files\Git\cmd\git.exe')
$bash = Find-Exe @($bashCand, (Join-Path $env:LOCALAPPDATA 'Programs\PortableGit\bin\bash.exe'), 'C:\Program Files\Git\bin\bash.exe')
$gh   = Find-Exe @((Cmd-Source 'gh.exe'), 'C:\Program Files\GitHub CLI\bin\gh.exe')

if (-not $git)  { Bad '找不到 git，后面的步骤做不了'; exit 1 } else { Ok ('git  : ' + $git) }
if ($gh)        { Ok ('gh   : ' + $gh) } else { Bad '找不到 gh（先装 GitHub CLI：https://cli.github.com/）' }
if ($bash)      { Ok ('bash : ' + $bash) } else { Info '没找到 bash，自检会少一项' }

# ---------------------------------------------------------------- 2. git init
Step 2 '初始化 git 仓库'
if (Test-Path -LiteralPath (Join-Path $Target '.git')) {
  Skip '已经是 git 仓库'
} else {
  & $git -C $Target init -b main 2>&1 | Out-Null
  if ($LASTEXITCODE -eq 0) { Ok 'git init -b main' } else { Bad 'git init 失败' }
}

# ---------------------------------------------------------------- 3. docs/agents
Step 3 '写入 docs/agents 配置'
$tplDocs = Join-Path $kit 'templates\docs-agents'
$dstDocs = Join-Path $Target 'docs\agents'
New-Item -ItemType Directory -Force -Path $dstDocs | Out-Null
foreach ($n in @('issue-tracker.md', 'triage-labels.md', 'domain.md')) {
  $dst = Join-Path $dstDocs $n
  $src = Join-Path $tplDocs $n
  if (Test-Path -LiteralPath $dst) { Skip ($n + ' 已存在') }
  elseif (-not (Test-Path -LiteralPath $src)) { Bad ('模板缺失：' + $src) }
  else { Copy-Item -LiteralPath $src -Destination $dst -Force; Ok ($n + ' 已写入') }
}
$wsYaml = Join-Path $dstDocs 'workspace.yaml'
if (Test-Path -LiteralPath $wsYaml) {
  Skip 'workspace.yaml 已存在'
} else {
  $ms = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  $yaml = "version: 2`r`nbackendId: github`r`npickedAt: $ms`r`nsource: user`r`n"
  [IO.File]::WriteAllText($wsYaml, $yaml, (New-Object System.Text.UTF8Encoding $false))
  Ok 'workspace.yaml（backendId: github）'
}

# ---------------------------------------------------------------- 4. AGENTS.md
Step 4 '写入 AGENTS.md'
$agentsPath = Join-Path $Target 'AGENTS.md'
$tplAgents  = Join-Path $kit 'templates\AGENTS.md'
if (-not (Test-Path -LiteralPath $agentsPath)) {
  if (Test-Path -LiteralPath $tplAgents) { Copy-Item -LiteralPath $tplAgents -Destination $agentsPath -Force; Ok 'AGENTS.md 已写入（整份模板）' }
  else { Bad '模板缺失：templates\AGENTS.md' }
} else {
  $txt = [IO.File]::ReadAllText($agentsPath, (New-Object System.Text.UTF8Encoding $false))
  if ($txt -match '##\s*Agent skills') {
    Skip 'AGENTS.md 已有 Agent skills 段'
  } else {
    $block = [IO.File]::ReadAllText($tplAgents, (New-Object System.Text.UTF8Encoding $false)).Trim()
    $block = ($block -replace '(?m)^#\s.*$', '').Trim()
    [IO.File]::WriteAllText($agentsPath, $txt.TrimEnd() + "`r`n`r`n" + $block + "`r`n", (New-Object System.Text.UTF8Encoding $false))
    Ok 'AGENTS.md 已追加 Agent skills 段（原有内容保留）'
  }
}

# ---------------------------------------------------------------- 5. gh 垫片
Step 5 '安装 gh 垫片（沙箱内裸写 gh issue create 也能用）'
$shimSrc   = Join-Path $kit 'gh-shim\gh'
$shimLocal = Join-Path $Target 'gh-shim\gh'
$binDir    = 'C:\Program Files\GitHub CLI\bin'
$shimDst   = Join-Path $binDir 'gh'

if (-not (Test-Path -LiteralPath $shimSrc)) {
  Bad ('垫片源缺失：' + $shimSrc)
} else {
  if (Test-Path -LiteralPath $shimLocal) { Skip '工作区里已有 gh-shim\gh' }
  else {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $shimLocal) | Out-Null
    Copy-Item -LiteralPath $shimSrc -Destination $shimLocal -Force
    Ok '已放一份到工作区 gh-shim\gh'
  }

  if ($SkipShim) {
    Skip '按 -SkipShim 跳过系统安装'
  } elseif (-not (Test-Path -LiteralPath $binDir)) {
    Bad ('没有目录 ' + $binDir + '，先装 GitHub CLI')
  } else {
    $needInstall = $true
    if (Test-Path -LiteralPath $shimDst) {
      $a = (Get-FileHash -LiteralPath $shimLocal -Algorithm SHA256).Hash
      $b = (Get-FileHash -LiteralPath $shimDst   -Algorithm SHA256).Hash
      if ($a -eq $b) { $needInstall = $false; Skip '系统里已是最新垫片' }
    }
    if ($needInstall) {
      $cmd = "Copy-Item -LiteralPath '" + $shimLocal + "' -Destination '" + $shimDst + "' -Force; exit 0"
      $b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
      Info '需要管理员权限，稍等 UAC 弹窗…'
      $p = Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -PassThru -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $b64)
      Start-Sleep -Milliseconds 300
      if ((Test-Path -LiteralPath $shimDst) -and $p.ExitCode -eq 0) { Ok '垫片已装到 ' + $shimDst }
      else { Bad ('垫片没装上（exit=' + $p.ExitCode + '），可手动执行：Copy-Item .\gh-shim\gh ''C:\Program Files\GitHub CLI\bin\gh'' -Force') }
    }
  }
}

# ---------------------------------------------------------------- 6. ignore / attributes
Step 6 '补 .gitignore / .gitattributes'
$gi = Join-Path $Target '.gitignore'
$n1 = Append-Lines -Path $gi -Lines @('.dsh/', 'node_modules/', '*.zip', '*.msi', '*.exe', '*.7z', '*.db', '.push-token')
if ($n1 -gt 0) { Ok ('.gitignore 补了 ' + $n1 + ' 行') } else { Skip '.gitignore 已齐' }
$ga = Join-Path $Target '.gitattributes'
$n2 = Append-Lines -Path $ga -Lines @('gh-shim/gh text eol=lf', '*.sh text eol=lf')
if ($n2 -gt 0) { Ok ('.gitattributes 补了 ' + $n2 + ' 行') } else { Skip '.gitattributes 已齐' }

# ---------------------------------------------------------------- 7. 分诊标签
Step 7 'GitHub 分诊标签（仅当已有 origin）'
$origin = ''
if (Test-Path -LiteralPath (Join-Path $Target '.git')) {
  $origin = (& $git -C $Target config --get remote.origin.url 2>$null | Select-Object -First 1)
}
$repo = $null
if ($origin -and $origin -match 'github\.com[:/]([^/\s]+/[^/\s]+?)(\.git)?$') { $repo = $Matches[1] }

if (-not $repo) {
  Skip '没有 GitHub origin，跳过（先建仓库并 git remote add origin …）'
} elseif (-not $gh) {
  Bad '没有 gh，跳过标签'
} else {
  Info ('仓库：' + $repo)
  $authOut = (& $gh auth status 2>&1 | Out-String)
  if ($authOut -match 'not logged into any') {
    Bad 'gh 未登录（gh auth login），跳过标签'
  } else {
    $labels = @(
      @('needs-triage',   'fbca04', '维护者需要评估这条议题'),
      @('needs-info',     'd4c5f9', '等待报告者补充更多信息'),
      @('ready-for-agent','0e8a16', '已经完整说明，可以交给 AFK 代理'),
      @('ready-for-human','1d76db', '需要由人来实现'),
      @('wontfix',        'ffffff', '不打算处理')
    )
    foreach ($l in $labels) {
      $out = (& $gh label create $l[0] -R $repo --color $l[1] --description $l[2] 2>&1 | Out-String)
      if ($out -match 'already exists') { Skip ('标签 ' + $l[0] + ' 已存在') }
      elseif ($LASTEXITCODE -eq 0) { Ok ('标签 ' + $l[0]) }
      else { Bad ('标签 ' + $l[0] + ' 失败：' + $out.Trim()) }
    }
  }
}

# ---------------------------------------------------------------- 8. 自检
Step 8 '自检'
if (Test-Path -LiteralPath (Join-Path $Target '.git')) {
  $gv = (& $git --version 2>&1 | Out-String).Trim()
  Ok $gv
  if ($origin) { Ok ('origin : ' + $origin) } else { Info 'origin : 未设置' }
}
if ($gh) {
  $hv = (& $gh --version 2>&1 | Select-Object -First 1)
  Ok $hv
}
if (Test-Path -LiteralPath $shimDst) { Ok ('垫片在 ' + $shimDst) } else { Bad '垫片缺失，沙箱里裸写 gh 会被 git 管道限制挡住' }
if ($bash) {
  $which = (& $bash -c 'command -v gh' 2>&1 | Out-String).Trim()
  if ($which) { Ok ('bash 解析到 gh：' + $which) } else { Bad 'bash 里找不到 gh（检查 PATH）' }
  if ($which -and ($which -notmatch '\bgh$')) { Bad '解析到的不是垫片（应以 \gh 结尾且无 .exe）' }
}
# 配置完整性
foreach ($f in @('AGENTS.md', 'docs\agents\issue-tracker.md', 'docs\agents\triage-labels.md', 'docs\agents\domain.md')) {
  if (Test-Path -LiteralPath (Join-Path $Target $f)) { Ok ('存在 ' + $f) } else { Bad ('缺 ' + $f) }
}

# ---------------------------------------------------------------- 9. 可选推送
Step 9 '提交与推送（-Push）'
if (-not $Push) {
  Info '未加 -Push，跳过。需要时：init-workspace.cmd /push 或 git add -A && git commit && git push -u origin HEAD'
} elseif (-not $repo) {
  Bad '没有 GitHub origin，无法推送'
} else {
  & $git -C $Target add -A 2>&1 | Out-Null
  $hasHead = ((& $git -C $Target rev-parse --verify HEAD 2>$null) -ne $null)
  $msg = 'chore: 初始化工作区配置（dsh-workspace-init）'
  & $git -C $Target -c user.name='dsh-workspace-init' -c user.email='init@localhost' commit -m $msg 2>&1 | Out-Null
  if ($LASTEXITCODE -eq 0) { Ok 'commit 完成' } elseif ($hasHead) { Skip '没有可提交改动' } else { Bad 'commit 失败（可能缺 user 身份）' }
  & $git -C $Target push -u origin HEAD 2>&1 | ForEach-Object { Write-Host ('        ' + $_) -ForegroundColor Gray }
  if ($LASTEXITCODE -eq 0) { Ok 'push 完成' } else { Bad 'push 失败（检查 gh auth / 凭据）' }
}

# ---------------------------------------------------------------- 汇总
Write-Host ''
if ($script:problems -eq 0) {
  Write-Host 'DONE 全部通过' -ForegroundColor Green
  exit 0
} else {
  Write-Host ('DONE 有 ' + $script:problems + ' 个警告，按上面 [WARN] 逐条处理') -ForegroundColor Yellow
  exit 2
}
