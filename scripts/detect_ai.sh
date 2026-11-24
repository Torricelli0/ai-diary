#!/bin/bash
# 检测本机可用的 AI CLI，输出调用命令前缀到 stdout（供 summarize.sh 使用）。
# 优先级：claude > codex > 环境变量 API Key。
set -u

if command -v claude >/dev/null 2>&1; then
  echo "claude -p --model haiku"
  exit 0
fi
if command -v codex >/dev/null 2>&1; then
  echo "codex exec --skip-git-repo-check"
  exit 0
fi
if [ -n "${ANTHROPIC_API_KEY:-}" ] || [ -n "${OPENAI_API_KEY:-}" ]; then
  echo "api-key"
  exit 0
fi
echo ""
