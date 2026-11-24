#!/bin/bash
# 安装 ai-diary 定时任务：Mac 用 launchd（每天 23:30），Linux 用 cron。
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
HOUR="${AI_DIARY_HOUR:-23}"
MIN="${AI_DIARY_MIN:-30}"
PLIST="$HOME/Library/LaunchAgents/com.ai-diary.daily.plist"

if [ "$(uname)" = "Darwin" ]; then
  mkdir -p "$HOME/Library/LaunchAgents"
  cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.ai-diary.daily</string>
  <key>ProgramArguments</key>
  <array><string>/bin/bash</string><string>$HERE/summarize.sh</string></array>
  <key>StartCalendarInterval</key>
  <dict><key>Hour</key><integer>$HOUR</integer><key>Minute</key><integer>$MIN</integer></dict>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key><string>$HOME</string>
    <key>AI_DIARY_REPOS</key><string>${AI_DIARY_REPOS:-}</string>
    <key>AI_DIARY_SCAN_DIRS</key><string>${AI_DIARY_SCAN_DIRS:-}</string>
    <key>AI_DIARY_DIR</key><string>${AI_DIARY_DIR:-$HOME/Documents/Obsidian Vault/个人/日记}</string>
  </dict>
  <key>StandardOutPath</key><string>/tmp/ai-diary.out</string>
  <key>StandardErrorPath</key><string>/tmp/ai-diary.err</string>
</dict>
</plist>
EOF
  launchctl unload "$PLIST" 2>/dev/null || true
  launchctl load "$PLIST"
  echo "已安装 launchd 定时任务：每天 $HOUR:$MIN → $PLIST"
else
  ( crontab -l 2>/dev/null; echo "$MIN $HOUR * * * /bin/bash '$HERE/summarize.sh' >> ~/.ai-diary-cron.log 2>&1" ) | crontab -
  echo "已安装 cron 定时任务：每天 $HOUR:$MIN"
fi
echo "日志：~/.ai-diary.log"
