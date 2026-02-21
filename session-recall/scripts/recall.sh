#!/usr/bin/env bash
# recall.sh — Extract session facts before reset (v2: structured memory)
# Usage: recall.sh [session_key] [reason]
#
# v2 changes:
# - Extracts atomic FACTS from conversations (not raw turns)
# - Stores facts in memory.jsonl via memory-store.sh
# - Daily .md gets only a 1-line pointer
# - No more context bloat on agent boot

set -uo pipefail

OPENCLAW_DIR="$HOME/.openclaw"
SESSIONS_DIR="$OPENCLAW_DIR/agents/main/sessions"
SESSIONS_JSON="$SESSIONS_DIR/sessions.json"
MEMORY_DIR="$OPENCLAW_DIR/workspace/memory"
MEMORY_STORE="$OPENCLAW_DIR/skills/rag-memory/scripts/memory-store.sh"
TODAY=$(date +"%Y-%m-%d")
MEMORY_FILE="$MEMORY_DIR/$TODAY.md"
TS=$(date +"%Y-%m-%d %H:%M:%S %Z")

SESSION_KEY="${1:-all}"
REASON="${2:-auto-reset}"

mkdir -p "$MEMORY_DIR"

echo "--- session-recall v2 ---"
echo "Time: $TS"
echo "Target: $SESSION_KEY"
echo "Reason: $REASON"

# Extract facts from sessions and store in memory.jsonl
python3 - "$SESSIONS_JSON" "$SESSIONS_DIR" "$MEMORY_FILE" "$SESSION_KEY" "$REASON" "$TS" "$MEMORY_STORE" << 'PYEOF'
import json, os, sys, subprocess
from datetime import datetime

sessions_file = sys.argv[1]
sessions_dir = sys.argv[2]
memory_file = sys.argv[3]
target_key = sys.argv[4]
reason = sys.argv[5]
ts = sys.argv[6]
memory_store = sys.argv[7]

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
        if tokens > 100000:
            to_recap.append((key, sid, tokens))
    elif target_key in key:
        to_recap.append((key, sid, tokens))

if not to_recap:
    print("No sessions need recap")
    sys.exit(0)

total_facts = 0

for session_key, session_id, token_count in to_recap:
    jsonl_file = os.path.join(sessions_dir, f"{session_id}.jsonl")
    if not os.path.exists(jsonl_file):
        print(f"WARN: Session file not found: {jsonl_file}")
        continue

    print(f"Extracting facts for: {session_key} ({token_count} tokens)")

    # Read last 200 lines of the session file
    lines = []
    try:
        with open(jsonl_file) as f:
            all_lines = f.readlines()
            lines = all_lines[-200:]
    except:
        print(f"WARN: Could not read {jsonl_file}")
        continue

    # Extract conversation text (assistant messages only — these contain decisions/actions)
    assistant_texts = []
    user_texts = []
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
                content = " ".join(text_parts)
            elif not isinstance(content, str):
                content = str(content)

            content = content.strip()
            if not content or len(content) < 20:
                continue

            # Clean WhatsApp metadata
            if content.startswith("[WhatsApp"):
                parts = content.split("] ", 2)
                content = parts[-1] if len(parts) >= 2 else content

            if role == "assistant":
                assistant_texts.append(content[:500])
            else:
                user_texts.append(content[:300])
        except:
            continue

    # --- EXTRACT ATOMIC FACTS ---
    facts = []

    # 1. Extract decisions (assistant messages with decision language)
    decision_keywords = ["decided", "decision", "approved", "confirmed", "set to", "changed to",
                         "switched", "configured", "enabled", "disabled", "removed", "added",
                         "scheduled", "created", "deployed", "updated"]
    for text in assistant_texts:
        lower = text.lower()
        for kw in decision_keywords:
            if kw in lower:
                # Extract the sentence containing the keyword
                sentences = text.replace("!", ".").replace("?", ".").split(".")
                for s in sentences:
                    s = s.strip()
                    if kw in s.lower() and 15 < len(s) < 300:
                        facts.append(("decision", s, 7))
                        break
                break

    # 2. Extract pending tasks
    pending_keywords = ["will do", "next step", "pending", "todo", "i'll", "i will",
                        "need to", "working on", "in progress", "blocked by"]
    for text in assistant_texts:
        lower = text.lower()
        for kw in pending_keywords:
            if kw in lower:
                sentences = text.replace("!", ".").replace("?", ".").split(".")
                for s in sentences:
                    s = s.strip()
                    if kw in s.lower() and 15 < len(s) < 300:
                        facts.append(("task", s, 8))
                        break
                break

    # 3. Extract learnings / errors
    learning_keywords = ["found that", "root cause", "the fix", "the issue was",
                         "learned", "gotcha", "workaround", "solved by", "fixed by",
                         "turns out", "the problem was", "key insight"]
    for text in assistant_texts:
        lower = text.lower()
        for kw in learning_keywords:
            if kw in lower:
                sentences = text.replace("!", ".").replace("?", ".").split(".")
                for s in sentences:
                    s = s.strip()
                    if kw in s.lower() and 15 < len(s) < 300:
                        facts.append(("learning", s, 7))
                        break
                break

    # 4. Extract user requests (what Jenn asked for — important context)
    for text in user_texts[-5:]:  # Last 5 user messages only
        if len(text) > 20:
            facts.append(("task", f"Jenn asked: {text[:200]}", 6))

    # 5. Always add a session summary fact
    topic_words = []
    for text in (assistant_texts[-5:] + user_texts[-3:]):
        words = text.lower().split()
        for w in words:
            if len(w) > 4 and w.isalpha() and w not in ("about", "their", "which", "would", "could", "should", "there", "these", "those", "being", "after", "before"):
                topic_words.append(w)
    # Get top 5 most common topic words
    from collections import Counter
    top_topics = [w for w, _ in Counter(topic_words).most_common(5)]
    summary = f"Session reset ({token_count:,} tokens). Topics: {', '.join(top_topics)}"
    facts.append(("config", summary, 4))

    # Deduplicate facts
    seen_texts = set()
    unique_facts = []
    for ftype, ftext, fimp in facts:
        key = ftext[:60].lower()
        if key not in seen_texts:
            seen_texts.add(key)
            unique_facts.append((ftype, ftext, fimp))

    # Limit to 10 facts per session (prevent bloat)
    unique_facts = unique_facts[:10]

    # Store facts via memory-store.sh
    session_label = session_key.split(":")[-1][:20] if ":" in session_key else session_key[:20]
    for ftype, ftext, fimp in unique_facts:
        try:
            result = subprocess.run(
                ["bash", memory_store,
                 "--agent", "zenni",
                 "--type", ftype,
                 "--tags", f"session-recall,{session_label}",
                 "--text", ftext,
                 "--importance", str(fimp)],
                capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                total_facts += 1
        except Exception as e:
            print(f"WARN: Failed to store fact: {e}")

    print(f"  Extracted {len(unique_facts)} facts from {len(assistant_texts)} assistant messages")

# Write minimal pointer to daily .md (NOT the full recap)
os.makedirs(os.path.dirname(memory_file), exist_ok=True)
existing = ""
if os.path.exists(memory_file):
    with open(memory_file) as f:
        existing = f.read()

pointer = f"\n- [{ts}] Session recall: {total_facts} facts indexed from {len(to_recap)} session(s) ({reason})\n"

# Only append if daily file is under 5KB (safety cap)
if len(existing) + len(pointer) < 5000:
    with open(memory_file, "a") as f:
        if not existing:
            f.write(f"# Memory — {ts[:10]}\n")
        f.write(pointer)
else:
    print(f"WARN: Daily memory at {len(existing)} chars, skipping pointer append")

print(f"\nTotal: {total_facts} facts indexed into memory.jsonl")
PYEOF

echo "--- session-recall v2 complete ---"
