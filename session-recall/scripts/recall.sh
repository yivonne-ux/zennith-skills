#!/usr/bin/env bash
# recall.sh — Extract session recap before reset
# Usage: recall.sh [session_key] [reason]
#
# If no session_key given, extracts recaps for ALL sessions with high token counts.
# Saves to ~/.openclaw/workspace/memory/YYYY-MM-DD.md

set -uo pipefail

OPENCLAW_DIR="$HOME/.openclaw"
SESSIONS_DIR="$OPENCLAW_DIR/agents/main/sessions"
SESSIONS_JSON="$SESSIONS_DIR/sessions.json"
MEMORY_DIR="$OPENCLAW_DIR/workspace/memory"
TODAY=$(date +"%Y-%m-%d")
MEMORY_FILE="$MEMORY_DIR/$TODAY.md"
TS=$(date +"%Y-%m-%d %H:%M:%S %Z")

SESSION_KEY="${1:-all}"
REASON="${2:-auto-reset}"

mkdir -p "$MEMORY_DIR"

echo "--- session-recall ---"
echo "Time: $TS"
echo "Target: $SESSION_KEY"
echo "Reason: $REASON"

# Find session IDs that need recap
python3 - "$SESSIONS_JSON" "$SESSIONS_DIR" "$MEMORY_FILE" "$SESSION_KEY" "$REASON" "$TS" << 'PYEOF'
import json, os, sys, glob
from datetime import datetime

sessions_file = sys.argv[1]
sessions_dir = sys.argv[2]
memory_file = sys.argv[3]
target_key = sys.argv[4]
reason = sys.argv[5]
ts = sys.argv[6]

try:
    with open(sessions_file) as f:
        sessions = json.load(f)
except:
    print("ERROR: Could not read sessions.json")
    sys.exit(1)

# Determine which sessions to recap
to_recap = []
for key, session in sessions.items():
    sid = session.get("sessionId")
    tokens = session.get("totalTokens", 0)
    if not sid:
        continue
    if target_key == "all":
        if tokens > 100000:  # Only recap bloated sessions
            to_recap.append((key, sid, tokens))
    elif target_key in key:
        to_recap.append((key, sid, tokens))

if not to_recap:
    print("No sessions need recap")
    sys.exit(0)

recaps = []

for session_key, session_id, token_count in to_recap:
    # Find the session JSONL file
    jsonl_file = os.path.join(sessions_dir, f"{session_id}.jsonl")
    if not os.path.exists(jsonl_file):
        print(f"WARN: Session file not found: {jsonl_file}")
        continue

    print(f"Extracting recap for: {session_key} ({token_count} tokens)")

    # Read last 200 lines of the session file
    lines = []
    try:
        with open(jsonl_file) as f:
            all_lines = f.readlines()
            lines = all_lines[-200:]
    except:
        print(f"WARN: Could not read {jsonl_file}")
        continue

    # Extract conversation turns
    turns = []
    for line in lines:
        try:
            entry = json.loads(line.strip())
            msg = entry.get("message", {})
            role = msg.get("role", "")
            if role not in ("user", "assistant"):
                continue

            content = msg.get("content", "")
            if isinstance(content, list):
                text_parts = []
                for block in content:
                    if isinstance(block, dict):
                        if block.get("type") == "text":
                            text_parts.append(block.get("text", ""))
                        elif block.get("type") == "toolCall":
                            text_parts.append(f"[Tool: {block.get('name', '?')}]")
                        elif block.get("type") == "toolResult":
                            text_parts.append(f"[Tool result]")
                content = " ".join(text_parts)
            elif not isinstance(content, str):
                content = str(content)

            # Skip empty or very short
            content = content.strip()
            if not content or len(content) < 5:
                continue

            # Truncate very long messages
            if len(content) > 500:
                content = content[:500] + "..."

            # Clean up WhatsApp metadata prefix
            if content.startswith("[WhatsApp"):
                # Extract just the message body after the metadata
                parts = content.split("] ", 2)
                if len(parts) >= 3:
                    content = parts[-1]
                elif len(parts) == 2:
                    content = parts[-1]

            turns.append((role, content))
        except:
            continue

    # Take last 30 turns
    recent_turns = turns[-30:]

    # Extract pending tasks / open threads from assistant messages
    pending = []
    for role, text in turns[-50:]:
        if role == "assistant":
            lower = text.lower()
            for keyword in ["will do", "next step", "pending", "todo", "i'll", "i will", "let me", "working on", "in progress"]:
                if keyword in lower:
                    # Extract the sentence containing the keyword
                    sentences = text.split(".")
                    for s in sentences:
                        if keyword in s.lower() and len(s.strip()) > 10:
                            pending.append(s.strip()[:200])
                            break
                    break

    # Build recap text
    recap = f"\n## Session Recap — {session_key}\n"
    recap += f"**Reset reason:** {reason} ({token_count:,} tokens)\n"
    recap += f"**Time:** {ts}\n\n"

    recap += "### Recent Conversation (last 30 turns)\n"
    for role, text in recent_turns:
        prefix = "**Jenn:**" if role == "user" else "**Zenni:**"
        recap += f"- {prefix} {text}\n"

    if pending:
        recap += "\n### Pending / In-Progress\n"
        seen = set()
        for p in pending[-10:]:
            if p not in seen:
                recap += f"- {p}\n"
                seen.add(p)

    recap += "\n---\n"
    recaps.append(recap)
    print(f"  Extracted {len(recent_turns)} turns, {len(pending)} pending items")

# Write to memory file
if recaps:
    # Check if file exists and has content
    existing = ""
    if os.path.exists(memory_file):
        with open(memory_file) as f:
            existing = f.read()

    with open(memory_file, "a") as f:
        if not existing:
            f.write(f"# Memory — {ts[:10]}\n")
        for recap in recaps:
            f.write(recap)

    print(f"\nWrote {len(recaps)} recap(s) to {memory_file}")
else:
    print("No recaps generated")

PYEOF

echo "--- session-recall complete ---"
