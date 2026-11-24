#!/usr/bin/env python3
"""提取某一天多个 AI agent 的用户提问（带时间戳）。

支持：
- DSH:         ~/.dsh/sessions/**/session.v4.jsonl.zstd（zstd 压缩）
- Codex:       ~/.codex/sessions/**/*.jsonl（纯 JSONL）
- Claude Code: ~/.claude/projects/**/*.jsonl（纯 JSONL）

用法: python3 extract_sessions.py 2026-11-24
输出: "- HH:MM [agent] 提问内容" 列表（供 summarize.sh 作为证据）。
"""
import sys, os, glob, json, datetime, subprocess
from pathlib import Path

HOME = Path.home()
ZSTD_CANDIDATES = ["/usr/local/bin/zstd", "/opt/homebrew/bin/zstd",
                   "/usr/local/Caskroom/miniconda/base/bin/zstd"]

# 系统注入的伪消息（不是人类真实提问），过滤掉
NOISE = ("<environment_context", "agent history whose request action",
         "[model changed", "background job ", "The following is the Codex agent history",
         "你是我的日志整理助手", "<system-reminder")


def find_zstd():
    for p in ZSTD_CANDIDATES:
        if Path(p).exists():
            return p
    return None


def emit(rows, t, agent, text):
    text = " ".join(str(text).split())
    if text and len(text) > 1 and not any(n in text for n in NOISE):
        hm = datetime.datetime.fromtimestamp(t).strftime("%H:%M")
        rows.append((t, hm, agent, text[:200]))


def parse_dsh(path, start, end, rows, zstd):
    try:
        raw = subprocess.run([zstd, "-dc", str(path)], capture_output=True, timeout=30).stdout
    except Exception:
        return
    for line in raw.decode("utf-8", "ignore").splitlines():
        try:
            ev = json.loads(line)
        except Exception:
            continue
        if ev.get("type") != "user/message":
            continue
        t = ev.get("time", 0) / 1000
        if not (start <= t < end):
            continue
        content = ev.get("data", {}).get("content", [])
        text = " ".join(c.get("text", "") for c in content
                        if isinstance(c, dict) and c.get("type") == "text")
        emit(rows, t, "dsh", text)


def parse_codex(path, start, end, rows):
    for line in open(path, encoding="utf-8", errors="ignore"):
        try:
            ev = json.loads(line)
        except Exception:
            continue
        ts = ev.get("timestamp", "")
        if not ts:
            continue
        try:
            t = datetime.datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp()
        except Exception:
            continue
        if not (start <= t < end):
            continue
        payload = ev.get("payload", {})
        if ev.get("type") == "response_item" and payload.get("role") == "user":
            content = payload.get("content", [])
            if isinstance(content, list):
                text = " ".join(c.get("text", "") for c in content
                                if isinstance(c, dict) and c.get("type") in ("input_text", "text"))
            else:
                text = str(content)
            emit(rows, t, "codex", text)
        elif ev.get("type") == "event_msg" and payload.get("type") == "user_message":
            emit(rows, t, "codex", payload.get("message", ""))


def parse_claude(path, start, end, rows):
    for line in open(path, encoding="utf-8", errors="ignore"):
        try:
            ev = json.loads(line)
        except Exception:
            continue
        if ev.get("type") != "user":
            continue
        ts = ev.get("timestamp", "")
        if not ts:
            continue
        try:
            t = datetime.datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp()
        except Exception:
            continue
        if not (start <= t < end):
            continue
        msg = ev.get("message", {})
        content = msg.get("content", "") if isinstance(msg, dict) else ""
        if isinstance(content, list):
            if any(isinstance(c, dict) and c.get("type") == "tool_result" for c in content):
                continue
            text = " ".join(c.get("text", "") for c in content
                            if isinstance(c, dict) and c.get("type") == "text")
        else:
            text = str(content)
        emit(rows, t, "claude", text)


def main():
    day = sys.argv[1] if len(sys.argv) > 1 else datetime.date.today().isoformat()
    start = datetime.datetime.fromisoformat(day + "T00:00:00").timestamp()
    end = start + 86400
    rows = []
    zstd = find_zstd()

    dsh_dir = HOME / ".dsh" / "sessions"
    if dsh_dir.exists() and zstd:
        for f in glob.glob(str(dsh_dir / "**" / "session.v4.jsonl.zstd"), recursive=True):
            parse_dsh(f, start, end, rows, zstd)
    codex_dir = HOME / ".codex" / "sessions"
    if codex_dir.exists():
        for f in glob.glob(str(codex_dir / "**" / "*.jsonl"), recursive=True):
            parse_codex(f, start, end, rows)
    claude_dir = HOME / ".claude" / "projects"
    if claude_dir.exists():
        for f in glob.glob(str(claude_dir / "**" / "*.jsonl"), recursive=True):
            parse_claude(f, start, end, rows)

    rows.sort()
    for _, hm, agent, text in rows:
        print(f"- {hm} [{agent}] {text}")


if __name__ == "__main__":
    main()
