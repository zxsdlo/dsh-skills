# dsh-workspace-init

把一个普通目录初始化成「`dsh-mattpocock-skills-deck` 技能套件能用」的工作区：写 `AGENTS.md`、`docs/agents/` 三份配置、补 `.gitignore`，并把 **gh 垫片** 装进 `C:\Program Files\GitHub CLI\bin\gh`（解决 DSH `workspace-write` 沙箱里 `gh` 调 git 报 `failed to run git: pipe: Access is denied.` 的问题）。

幂等：已存在的文件不覆盖，只补缺失的部分。可以反复跑。

## 用法

把整个 `dsh-workspace-init` 文件夹放到目标目录里（或者留在任意位置），然后：

| 场景 | 命令 |
| --- | --- |
| 就地初始化（双击运行） | 双击 `init-workspace.cmd`，初始化它所在的文件夹 |
| 初始化指定目录 | `init-workspace.cmd "D:\path\to\workspace"` |
| 初始化并提交 + 推送 | `init-workspace.cmd /push`（或 `init-workspace.cmd "D:\ws" /push`） |
| 只写配置、不装系统垫片 | `powershell -ExecutionPolicy Bypass -File init-workspace.ps1 -Target . -SkipShim` |

需要管理员权限的只有「把垫片拷进 `C:\Program Files\GitHub CLI\bin`」这一步，脚本会自己弹一次 UAC。没有 GitHub CLI 时这步跳过并告警。

## 它到底改了什么

1. `git init -b main`（已经是仓库就跳过）
2. `docs/agents/`：`issue-tracker.md`、`triage-labels.md`、`domain.md`、`workspace.yaml`（`backendId: github`，面板据此显示「已选择后端 explicit:github」）
3. `AGENTS.md`：没有就整份写入；有但缺 `## Agent skills` 段就追加，原有内容保留
4. `gh-shim\gh` 放一份到工作区，并比较 SHA256 决定是否把系统里那份更新
5. `.gitignore` 补 `.dsh/`、`node_modules/`、`*.zip/*.msi/*.exe/*.7z/*.db`、`.push-token`；`.gitattributes` 补 `gh-shim/gh text eol=lf`
6. 有 GitHub origin 且 `gh` 已登录时，幂等创建五个分诊标签
7. 自检：git/gh 版本、垫片是否存在、bash 里 `command -v gh` 解析到哪个文件、四份配置是否齐全
8. 加 `/push` 才 `git add -A` + commit + `push -u origin HEAD`

## gh 垫片解决的是什么

DSH 的 `workspace-write` 沙箱里，任何程序用**管道**派生 `git` 都会 EPERM，于是 `gh` 的 `repo view`、`issue create`（不带 `-R`）全部失败：

```
failed to run git: pipe: Access is denied.
```

但 bash 自己派生 git 是允许的。垫片是放在 `C:\Program Files\GitHub CLI\bin\gh` 的 bash 脚本（无扩展名，PATH 解析时排在 `gh.exe` 之前）：它先 `git config --get remote.origin.url` 解析出 `owner/repo`，`export GH_REPO`，再 `exec` 真正的 `gh.exe`。这样技能里裸写 `gh issue create` 就能用。

已知限制：

- `gh repo view` **不带参数**时不认 `GH_REPO`，写 `gh repo view <owner>/<repo>`。
- `gh pr create` / `gh pr checkout` 这类真正要 git 的命令在沙箱里仍然不行，到普通终端做。
- 沙箱里 `git push` 也不行（`cannot create standard input pipe for remote-https`），提交可以、推送不行。

## 目录

```
dsh-workspace-init\
  init-workspace.cmd          # 入口，双击即用
  init-workspace.ps1          # 全部逻辑（UTF-8 BOM，PS 5.1 才不会把中文当 ANSI）
  gh-shim\gh                  # 垫片源码
  templates\
    AGENTS.md                 # AGENTS.md 母版
    docs-agents\*.md          # docs/agents 三份母版
```

## 排错

- **中文变乱码**：`init-workspace.cmd` 里已经 `chcp 65001`；如果你自己改 `.ps1`，务必存成「UTF-8 带 BOM」，否则 PowerShell 5.1 按 ANSI 解析，中文注释可能吞掉换行、把下一行当注释。
- **`$PSScriptRoot` 为空**：只有 `-EncodedCommand` 或管道方式运行时才会；正常 `-File` 调用没问题。
- **垫片没生效**：`command -v gh` 应输出 `/c/Program Files/GitHub CLI/bin/gh`（没有 `.exe`）。输出 `gh.exe` 说明 PATH 里另有目录排在前面。
- **gh 更新后被覆盖**：重新跑一次本脚本即可，会按 SHA256 重新拷。
