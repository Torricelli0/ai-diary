#!/bin/bash
# ai-diary 主脚本：提取当天多 agent 会话 → AI 总结 → 写入 Obsidian/Markdown 日记。
# 由 install_schedule.sh 安装的 launchd/cron 定时触发，也可手动运行。
# 配置：AI_DIARY_DIR（日记目录，默认 ~/Documents/Obsidian Vault/个人/日记）
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
PY="$(command -v python3 || echo /usr/bin/python3)"
VAULT="${AI_DIARY_DIR:-$HOME/Documents/Obsidian Vault/个人/日记}"
TODAY=$(date "+%m.%d")
FULL=$(date "+%Y-%m-%d")
DIARY="$VAULT/${TODAY}.md"
TMP=$(mktemp /tmp/ai-diary-evidence.XXXXXX)
LOG="$HOME/.ai-diary.log"
mkdir -p "$VAULT"

AI_CMD=$("$HERE/detect_ai.sh")

{
  echo "# ai-diary 证据采集：$(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  echo "## 一、当天各 AI agent 的对话提问（主证据）"
  "$PY" "$HERE/extract_sessions.py" "$FULL" 2>/dev/null
  echo ""
  echo "## 二、当天 Git 提交"
  for repo in ${AI_DIARY_REPOS:-}; do
    [ -d "$repo/.git" ] || continue
    echo "### $(basename "$repo")"
    git -C "$repo" log --since="${FULL} 00:00" --until="${FULL} 23:59" \
      --date=format:'%H:%M' --pretty=format:'- %ad %h %s' 2>/dev/null
    echo ""
  done
  echo ""
  echo "## 三、当天日记已有内容（若存在，作为背景，不要重复）"
  [ -f "$DIARY" ] && head -80 "$DIARY"
} > "$TMP"

if [ -z "$AI_CMD" ]; then
  echo "[$(date '+%H:%M:%S')] 未找到可用 AI CLI（claude/codex/API key），跳过总结" >> "$LOG"
  rm -f "$TMP"; exit 1
fi

PROMPT=$(cat <<EOF
你是我的日志整理助手。根据"当天证据"，用我的 Obsidian 日记风格写一段总结，供追加到日记末尾。

风格：
- 中文；按主题分小节，每节一个小标题；不是流水账；
- 保留证据里的关键时间点（如"11:05 提交 xxx"），不编造没有的时间；
- 写"做了什么 + 为什么 + 结论/下一步"；
- 证据少就简短，不硬凑；没发生的不写；
- 只输出 Markdown 正文，不要解释。

当天证据：
$(cat "$TMP")
EOF
)

if [ "$AI_CMD" = "api-key" ]; then
  echo "[$(date '+%H:%M:%S')] 检测到 API Key 但本脚本未内置直连，请配置 claude/codex CLI" >> "$LOG"
  rm -f "$TMP"; exit 1
fi

SUMMARY=$(printf '%s' "$PROMPT" | $AI_CMD 2>/dev/null)

if [ -n "$SUMMARY" ]; then
  {
    echo ""
    echo "---"
    echo ""
    echo "## 自动总结（$(date '+%H:%M') ai-diary 生成）"
    echo ""
    echo "$SUMMARY"
  } >> "$DIARY"
  echo "[$(date '+%H:%M:%S')] 已写入 $DIARY" >> "$LOG"
else
  echo "[$(date '+%H:%M:%S')] AI 总结为空，未写入" >> "$LOG"
fi
rm -f "$TMP"
