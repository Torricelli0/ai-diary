# ai-diary

把每天与多个 AI agent 的对话，自动总结成 Obsidian 日记。

**一句话**：你跟 AI 聊过什么、做过什么，每天自动生成一篇可回顾的 markdown 日记——不用手动记，不用额外付费，全部本地。

## 为什么做

- 同一个软件开了多个对话、还用不同软件（DSH / Codex / Claude Code），回头想找"我那天让 AI 做了什么"很难；
- 已有的日志项目（engineering-notebook 等）只支持 Claude/Codex，不支持 DSH，且输出 SQLite + Web UI——太重；
- 这个工具**支持三种 agent**，输出普通 markdown 文件，零依赖、零 API Key（复用你本机已有的 AI CLI）。

## 关于输出：Markdown 是通用的，Obsidian 只是默认存放地

本工具输出的就是**普通 `.md` 文件**（如 `11.24.md`）——任何 markdown 软件都能打开和编辑：Typora、VS Code、文本编辑器都行。README 里反复提 Obsidian，只是因为它是作者自己的日记存放地，不是技术绑定。想改到 Typora 的目录，只需设置环境变量 `AI_DIARY_DIR`。

**为什么默认用 Obsidian**（可选了解）：Obsidian 是一个本地优先的 markdown 知识库软件——文件以纯文本存在你电脑上（不是云端数据库），核心特色是**双向链接 / 知识图谱**（能看到笔记之间的关联网络），并有上千个社区插件/主题可扩展。它**本身不内置 AI**，但社区有 AI 插件（如 Smart Connections、Text Generator 等）可以接各种模型。这些特性和"每天一篇按日期命名的日记、长期积累成个人知识库"的场景很契合——所以选它当默认示例。但你完全可以用 Typora（更轻的所见即所得 markdown 编辑器）或任何软件代替。

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

## 为什么用系统定时任务，而不是 skill / hook / Trae 那种自动化

三者本质都是"事件触发 → 自动执行"，但调度者不同：

| 方式 | 谁调度 | 需要软件开着吗 | 跨 agent |
|---|---|---|---|
| **系统定时**（本工具） | OS 的 launchd / cron | ❌ 不需要，到点就跑 | ✅ 汇总三个软件 |
| **Hook** | agent 进程内事件（会话开始/结束） | ✅ 必须是那个 agent | ❌ 只覆盖一个 |
| **Trae/产品自动化** | 产品内置调度器 | ✅ 通常要开着并登录 | ❌ 绑定该产品 |

选系统定时的原因：你的数据源是**磁盘上的会话存档文件**，深夜一次性扫描当天所有文件，拿到的是完整落盘的一天——比"每个会话结束时逐个拼"更完整，还能跨软件合并。而且系统调度不受各 agent 更新/改配置影响，最稳定。

**跨平台**：Mac 用 launchd，Linux 用 cron（`install_schedule.sh` 自动识别）；**Windows 用户**需手动用"任务计划程序"调用 `scripts/summarize.sh`（Git Bash 下运行）或改成 PowerShell 版本——目前没有一键安装，欢迎 PR。

skill（`SKILL.md`）只是给"想手动说一句总结今天"的人用的入口，定时任务不依赖它。

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
