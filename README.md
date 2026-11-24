# ai-diary

把每天与多个 AI agent 的对话，自动总结成 Obsidian 日记。

**一句话**：你跟 AI 聊过什么、做过什么，每天自动生成一篇可回顾的 markdown 日记——不用手动记，不用额外付费，全部本地。

## 为什么做

- 同一个软件开了多个对话、还用不同软件（DSH / Codex / Claude Code），回头想找"我那天让 AI 做了什么"很难；
- 已有的日志项目（engineering-notebook 等）只支持 Claude/Codex，不支持 DSH，且输出 SQLite + Web UI——太重；
- 这个工具**支持三种 agent**，输出你自己的 Obsidian markdown，零依赖、零 API Key（复用你本机已有的 AI CLI）。

## 原理

```
各 agent 会话文件（格式不同）
   ↓ extract_sessions.py  适配器：统一提取"用户提问 + 时间戳"
当天提问 + Git 提交 + 修改文件  →  证据文件
   ↓ AI CLI（自动检测 claude/codex，复用你的登录态）
按你的日记风格生成 Markdown
   ↓
追加到 Obsidian 日记 MM.DD.md
   ↑
install_schedule.sh 装的定时任务（Mac launchd / Linux cron）每天自动触发
```

**适配器模式**是核心：DSH 是 zstd 压缩的 `session.v4.jsonl.zstd`，Codex/Claude 是明文 JSONL——脚本把三种格式归一化成同样的输出，后面的总结逻辑不关心来源。

## 安装（给 AI 一句话）

把这句发给你的 agent（Claude Code / DSH / Codex 都行）：

> 帮我安装 https://github.com/Torricelli0/ai-diary ：克隆到本地，运行 `bash scripts/install_schedule.sh` 安装定时任务，然后告诉我日记输出目录怎么配。

## 手动安装

```bash
git clone https://github.com/Torricelli0/ai-diary.git
cd ai-diary
chmod +x scripts/*.sh
bash scripts/install_schedule.sh        # 默认每天 23:30
bash scripts/summarize.sh               # 立即手动跑一次
```

**配置（可选，环境变量）**：

| 变量 | 作用 | 默认 |
|---|---|---|
| `AI_DIARY_DIR` | 日记输出目录 | `~/Documents/Obsidian Vault/个人/日记` |
| `AI_DIARY_REPOS` | 要纳入的 Git 仓库（空格分隔） | 无 |
| `AI_DIARY_HOUR` / `AI_DIARY_MIN` | 定时时间 | 23 / 30 |

## 用的是谁的 AI

脚本自动检测本机：
1. 有 `claude` CLI → 用 `claude -p --model haiku`（复用你已有的登录态/额度）；
2. 否则有 `codex` CLI → 用 `codex exec`；
3. 都没有 → 提示配置（不内置直连 API）。

**不额外收费、不需要新 API Key**——用你本来就在用的那个 AI。

## 作为 skill 使用

仓库根目录的 `SKILL.md` 是给 agent 用的薄封装：你把仓库加进它的 skills 目录后，说"总结今天"就会触发手动总结。定时功能仍由 `install_schedule.sh` 负责（skill 不能自己定时）。

## 隐私

- 只读本地会话文件；
- 总结时把当天提问发给**你自己的** AI CLI（走你已有的服务）；
- 系统注入内容（环境上下文、后台任务通知）会被过滤，只记录真实提问；
- 无云存储、无遥测。

## 文件

| 文件 | 作用 |
|---|---|
| `scripts/extract_sessions.py` | 三 agent 会话提取（核心适配器） |
| `scripts/detect_ai.sh` | 自动检测本机 AI CLI |
| `scripts/summarize.sh` | 主脚本：证据 → AI → 日记 |
| `scripts/install_schedule.sh` | 安装 launchd / cron 定时任务 |
| `SKILL.md` | agent skill 封装（手动触发入口） |
