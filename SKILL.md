---
name: ai-diary
description: 把每天与多个 AI agent（DSH/Codex/Claude Code）的对话总结成 Markdown 日记。用户说"总结今天/记日记/我今天做了什么"或要求安装每日自动日志时使用。
---

# AI Diary

汇总多个 AI 软件的对话，生成每日 Markdown 日记。

## 何时用
- 用户说"总结今天""记一下今天的日记""我今天用 AI 做了什么"
- 用户要安装/配置每日自动日志
- 用户想查"前几天我跟 AI 聊了什么"

## 手动总结今天
直接运行主脚本（它会自动检测本机可用的 AI CLI）：
```bash
bash <本skill目录>/scripts/summarize.sh
```
输出写入 `AI_DIARY_DIR`（默认 `~/Documents/Obsidian Vault/个人/日记/MM.DD.md`）。

## 安装定时任务
```bash
bash <本skill目录>/scripts/install_schedule.sh
```
Mac 用 launchd（默认每天 23:30），Linux 用 cron。可用环境变量 `AI_DIARY_HOUR` / `AI_DIARY_MIN` 改时间。

## 只看某天的对话（不总结）
```bash
python3 <本skill目录>/scripts/extract_sessions.py 2026-11-24
```
输出 `- HH:MM [agent] 提问` 列表。

## 配置
- `AI_DIARY_DIR`：日记输出目录
- `AI_DIARY_REPOS`：要纳入 Git 提交的仓库路径（空格分隔）
- `AI_DIARY_HOUR` / `AI_DIARY_MIN`：定时时间

## 依赖
- Python 3（标准库即可）
- 本机有 `claude` 或 `codex` CLI 之一（脚本自动检测，复用你已有的登录态，不额外收费）
- DSH 会话解析需要 `zstd`（可选；没有则跳过 DSH，不影响 Codex/Claude）

## 边界
- 只读本地会话文件，不上传任何数据（总结时发给用户自己的 AI CLI）
- 过滤系统注入消息（环境上下文、后台任务通知等），只记录真实人类提问
- 不读取其他 agent 的对话（除非它们把会话存成上述三种格式）
