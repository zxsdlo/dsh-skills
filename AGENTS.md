# dsh-skills

这个仓库存放 `dsh-mattpocock-skills-deck` 插件相关的工作区内容：技能安装与配置脚本、探测/验证脚本，以及工程技能套件所需的按仓库配置（议题跟踪器、分诊标签、领域文档布局）。

## Agent skills

### Issue tracker

议题和规格说明存放在 GitHub Issues 里，用 `gh` CLI 读写。见 `docs/agents/issue-tracker.md`。

### Triage labels

分诊使用五个规范角色标签（`needs-triage`、`needs-info`、`ready-for-agent`、`ready-for-human`、`wontfix`）。见 `docs/agents/triage-labels.md`。

### Domain docs

单上下文布局：仓库根目录一份 `GLOSSARY.md` 加 `docs/adr/`。见 `docs/agents/domain.md`。
