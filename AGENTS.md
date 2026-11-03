# dsh-skills

这个仓库存放 `dsh-mattpocock-skills-deck` 插件相关的工作区内容：技能安装与配置脚本、探测/验证脚本，以及工程技能套件所需的按仓库配置（议题跟踪器、分诊标签、领域文档布局）。

## Agent skills

### Issue tracker

议题和规格说明存放在 GitHub Issues 里，用 `gh` CLI 读写。见 `docs/agents/issue-tracker.md`。

### Triage labels

分诊使用五个规范角色标签（`needs-triage`、`needs-info`、`ready-for-agent`、`ready-for-human`、`wontfix`）。见 `docs/agents/triage-labels.md`。

### Domain docs

单上下文布局：仓库根目录一份 `GLOSSARY.md` 加 `docs/adr/`。见 `docs/agents/domain.md`。

## DSH 沙箱注意事项

- `gh` 在本沙箱里无法用管道派生 `git`（报 `failed to run git: pipe: Access is denied.`）。仓库里装了垫片 `C:\Program Files\GitHub CLI\bin\gh`，会自动设置 `GH_REPO`，所以直接写 `gh issue ...` 即可；兜底用 `GH_REPO=zxsdlo/dsh-skills` 或 `-R zxsdlo/dsh-skills`。细节见 `docs/agents/issue-tracker.md`。
- 提交可以在沙箱里做；`git push` 不行（`cannot create standard input pipe for remote-https`），需要在普通终端或提权脚本里推。

