# ai-diary

把每天与多个 AI agent 的对话，自动总结成 Markdown 日记。本地运行，复用已有的 AI CLI，不产生额外费用。

## 功能

- 解析 DSH、Codex、Claude Code 三者的会话记录，提取当天的用户提问（带时间戳）
- 结合当天的 Git 提交和文件修改，生成按主题分节、带时间点的日记
- 系统定时自动执行；也可手动触发
- 输出普通 `.md` 文件，默认写到 Obsidian 的日记目录

现有的同类工具多只支持 Claude Code / Codex，输出 SQLite + Web UI。本项目覆盖 DSH，输出纯文本文件，可以直接纳入已有的笔记工作流。

## 输出格式

纯 Markdown，如 `11.24.md`。任何编辑器都能打开：Typora、VS Code、文本编辑器均可。输出目录由 `AI_DIARY_DIR` 指定，改动即可换到任意笔记软件。

默认路径是 `~/Documents/Obsidian Vault/个人/日记`，因为 Obsidian 以本地纯文本文件存储笔记、支持双向链接和知识图谱，适合长期按日期积累日记。它不内置 AI，但有社区插件可扩展。这只是默认值，不是依赖。

## 工作原理

```
各 agent 的会话文件
   ↓ extract_sessions.py（适配器，统一提取"提问 + 时间戳"）
当天提问 + Git 提交 + 修改文件 → 证据文件
   ↓ 本机 AI CLI
按日记风格生成 Markdown
   ↓
写入日记，定时任务每天触发
```

DSH 的会话是 zstd 压缩的 `session.v4.jsonl.zstd`，Codex 和 Claude Code 是明文 JSONL。提取脚本把三种格式归一化，后续流程不关心数据来源。

## 安装

```bash
git clone https://github.com/Torricelli0/ai-diary.git
cd ai-diary
chmod +x scripts/*.sh
bash scripts/install_schedule.sh        # 默认每天 23:30
bash scripts/summarize.sh               # 立即手动运行一次
```

也可以把仓库地址发给 agent，让它执行上述步骤。

**环境变量**（可选）：

| 变量 | 作用 | 默认 |
|---|---|---|
| `AI_DIARY_DIR` | 日记输出目录 | `~/Documents/Obsidian Vault/个人/日记` |
| `AI_DIARY_REPOS` | 纳入的 Git 仓库（空格分隔） | 无 |
| `AI_DIARY_HOUR` / `AI_DIARY_MIN` | 定时时间 | 23 / 30 |

## 依赖

- Python 3（仅标准库）
- 本机已安装 `claude` 或 `codex` CLI 之一，脚本自动检测并使用其登录态：
  1. 有 `claude` → `claude -p --model haiku`
  2. 否则有 `codex` → `codex exec`
  3. 都没有 → 报错退出
- DSH 会话解析需要 `zstd`；缺失时跳过 DSH，不影响另外两个

不需要单独的 API Key。

## 定时方式

`install_schedule.sh` 在 macOS 上安装 launchd 任务，在 Linux 上安装 cron 任务。系统级调度的好处是：不要求任何 agent 保持运行，且在当天结束后一次性读取已落盘的完整会话。

也支持 agent 内的 hook 或产品自带自动化，但那些绑定单个软件、且需要对应进程运行；skill（`SKILL.md`）仅提供"总结今天"的手动入口，不负责定时。

Windows 未做一键安装：可用任务计划程序调用 `scripts/summarize.sh`（Git Bash 环境），或自行改成 PowerShell。

## 隐私

- 只读本地会话文件
- 总结通过本机的 AI CLI 完成，数据发给用户已有的服务
- 系统注入内容（环境上下文、后台通知等）被过滤，只保留真实提问
- 无云存储、无遥测

## 文件

| 文件 | 作用 |
|---|---|
| `scripts/extract_sessions.py` | 三种 agent 会话提取与格式归一化 |
| `scripts/detect_ai.sh` | 检测本机可用的 AI CLI |
| `scripts/summarize.sh` | 主流程：收集证据 → 调用 AI → 写入日记 |
| `scripts/install_schedule.sh` | 安装 launchd / cron 定时任务 |
| `SKILL.md` | agent skill 封装（手动触发） |
