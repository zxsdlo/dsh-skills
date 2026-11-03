# dsh-mnemon 记忆空间修复记录 / 复核脚本

## 结论
- `D:\memos.exe` **不存在**（已搜索 D: 全盘 6 层 + C:\Users\XYD），且 memos 与 dsh-mnemon 无关：插件所有包中 `memos` 命中 0 次，`mnemon` CLI 才是 provider 需要的后端。
- `mnemon` CLI 已装好：`C:\Users\XYD\AppData\Roaming\npm\mnemon.cmd` → `mnemon version 0.2.13`，且该目录已在用户 PATH 中。
- `cordis.patch.yml` 的 `include:mnemon-strategy-scoped` 两个列表都已含 `source:include:mnemon-source-memory-spaces`（备份 `cordis.patch.yml.bak-20261102-230607` 是修改前的版本），js-yaml 读回 3+3 条、writable 是 source 的子集。
- 写入链路本身可用：工作区内 `MNEMON_DATA_DIR` 指向可写目录时 `mnemon remember --cat fact` 返回 `"action": "added"`（无任何 embedding 端点）。

## 复核
```powershell
node mnemon-setup/check-patch.js            # 需在 profiles\desktop 下执行或用 NODE_PATH
node mnemon-setup/detect-cli.mjs            # 模拟 Host 的 CLI 探测，应输出 ...\npm\mnemon.cmd
powershell -File mnemon-setup/inspect-exe.ps1 -Path 'D:\memos.exe'
```

## 还差一步
重启 DSH 桌面端（完全退出再启动），profile 才会重新加载、面板才会重新探测 CLI；随后用 `mnemon_memory_bodies` 确认 `provider: mnemon-native / remember: true`，再用
`mnemon_remember("自检条目 <时间>：写入通道已打通。无业务含义，可随时删除。", memoryBodyId:"default", category:"context", importance:1, tags:["selftest"])` 打一条自检。

若重启后面板仍显示「未安装 CLI」，说明 Host 进程 PATH 里没有 `%APPDATA%\npm`，在 `include:mnemon-source-memory-spaces` 的 config 里加：
```yaml
            cliPath: C:\Users\XYD\AppData\Roaming\npm\node_modules\@mnemon-dev\mnemon\node_modules\@mnemon-dev\mnemon-win32-x64\bin\mnemon.exe
```
再重启一次。
