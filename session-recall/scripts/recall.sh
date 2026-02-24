#!/usr/bin/env bash
# recall.sh — Extract conversation recap before session reset (v3: readable recap)
# Usage: recall.sh [session_key] [reason]
#
# v3 changes:
# - Writes human-readable recap to memory/YYYY-MM-DD.md (auto-read on boot)
# - Captures last 15 conversation turns (user + assistant)
# - No more RAG-only storage that never gets read
# - Simple, reliable, zero external dependencies

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

echo "--- session-recall v3 ---"
echo "Time: $TS"
echo "Target: $SESSION_KEY"
echo "Reason: $REASON"

python3 - "$SESSIONS_JSON" "$SESSIONS_DIR" "$MEMORY_FILE" "$SESSION_KEY" "$REASON" "$TS" << 'PYEOF'
import json, os, sys

sessions_file = sys.argv[1]
sessions_dir = sys.argv[2]
memory_file = sys.argv[3]
target_key = sys.argv[4]
reason = sys.argv[5]
ts = sys.argv[6]

try:
    with open(sessions_file) as f:
        sessions = json.load(f)
except Exception as e:
    print(f"ERROR: Could not read sessions.json: {e}")
    sys.exit(1)

# Determine which sessions to recap
to_recap = []
for key, session in sessions.items():
    tokens = session.get("totalTokens", 0)
    # Use sessionFile field (correct path) — fall back to sessionId-based guess
    jsonl_path = session.get("sessionFile", "")
    if not jsonl_path:
        sid = session.get("sessionId", "")
        jsonl_path = os.path.join(sessions_dir, f"{sid}.jsonl") if sid else ""
    if not jsonl_path:
        continue
    if target_key == "all":
        if tokens > 80000:  # capture sessions approaching limit
            to_recap.append((key, jsonl_path, tokens))
    elif target_key in key:
        to_recap.append((key, jsonl_path, tokens))

if not to_recap:
    print("No sessions need recap")
    sys.exit(0)

recaps_written = 0

for session_key, jsonl_file, token_count in to_recap:
    if not os.path.exists(jsonl_file):
        print(f"WARN: Session file not found: {jsonl_file}")
        continue

    print(f"Recapping: {session_key} ({token_count:,} tokens)")
    print(f"  JSONL: {jsonl_file}")

    # Read last 300 lines of the session JSONL
    try:
        with open(jsonl_file) as f:
            all_lines = f.readlines()
            lines = all_lines[-300:]
    except Exception as e:
        print(f"WARN: Could not read {jsonl_file}: {e}")
        continue

    # Extract conversation turns (user + assistant only)
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
                    if isinstance(block, dict) and block.get("type") == "text":
                        text_parts.append(block.get("text", ""))
                content = " ".join(text_parts)
            elif not isinstance(content, str):
                content = str(content)

            content = content.strip()
            if not content or len(content) < 10:
                continue

            # Strip WhatsApp metadata prefix
            if content.startswith("[WhatsApp") or content.startswith("[Wed") or content.startswith("[Tue") or content.startswith("[Mon"):
                parts = content.split("] ", 2)
                content = parts[-1] if len(parts) >= 2 else content

            # Skip system-like messages
            if content.startswith("HEARTBEAT") or content.startswith("NO_REPLY"):
                continue

            turns.append((role, content[:600]))
        except:
            continue

    # Keep only last 15 turns
    turns = turns[-15:]

    if not turns:
        print(f"  No conversation turns found in {session_key}")
        continue

    # Build readable recap block
    session_label = session_key.split(":")[-1] if ":" in session_key else session_key
    recap_lines = [
        f"\n## 🔁 Session Recap — {ts}",
        f"**Session:** {session_key} | **Tokens:** {token_count:,} | **Reason:** {reason}",
        f"**Last {len(turns)} turns:**",
        ""
    ]

    for role, text in turns:
        prefix = "**Jenn:**" if role == "user" else "**Zenni:**"
        # Truncate long texts
        display = text[:400] + "..." if len(text) > 400 else text
        # Flatten newlines for compact display
        display = display.replace("\n", " ").strip()
        recap_lines.append(f"{prefix} {display}")

    recap_lines.append("")
    recap_lines.append("---")
    recap_block = "\n".join(recap_lines)

    # Read existing memory file
    existing = ""
    if os.path.exists(memory_file):
        with open(memory_file) as f:
            existing = f.read()

    # Safety cap: don't grow memory file beyond 8KB
    if len(existing) + len(recap_block) > 8000:
        # Trim existing to make room
        existing = existing[-4000:]
        print(f"WARN: Memory file trimmed to make room for recap")

    # Write
    os.makedirs(os.path.dirname(memory_file), exist_ok=True)
    with open(memory_file, "a") as f:
        if not existing:
            f.write(f"# Memory — {ts[:10]}\n")
        f.write(recap_block)

    print(f"  ✅ Wrote {len(turns)}-turn recap to {memory_file}")
    recaps_written += 1

print(f"\nTotal: {recaps_written} session(s) recapped → {memory_file}")
PYEOF

echo "--- session-recall v3 complete ---"
