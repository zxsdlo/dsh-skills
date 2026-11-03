# 项目名

一句话说明这个仓库是什么。

## Agent skills

### Issue tracker

议题和规格说明存放在 GitHub Issues 里，用 `gh` CLI 读写。见 `docs/agents/issue-tracker.md`。

### Triage labels

分诊使用五个规范角色标签（`needs-triage`、`needs-info`、`ready-for-agent`、`ready-for-human`、`wontfix`）。见 `docs/agents/triage-labels.md`。

### Domain docs

单上下文布局：仓库根目录一份 `GLOSSARY.md` 加 `docs/adr/`。见 `docs/agents/domain.md`。

## DSH 沙箱注意事项

- `gh` 在 workspace-write 沙箱里无法用管道派生 `git`（报 `failed to run git: pipe: Access is denied.`）。`C:\Program Files\GitHub CLI\bin\gh` 装了垫片，会自己设置 `GH_REPO`，所以直接写 `gh issue ...` 即可；兜底用 `GH_REPO=<owner>/<repo>` 或 `-R <owner>/<repo>`。细节见 `docs/agents/issue-tracker.md`。
- 提交可以在沙箱里做；`git push` 不行（`cannot create standard input pipe for remote-https`），要在普通终端里推。
