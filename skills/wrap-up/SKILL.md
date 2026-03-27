---
name: wrap-up
description: >
  End-of-session learning capture. Identifies which skills were used during the session,
  extracts feedback and corrections, writes structured learnings to per-skill learnings.md
  files. The compounding memory layer that makes every skill smarter over time.
metadata:
  clawdbot:
    emoji: "\U0001F4DD"
    agents: [taoz, main]
    triggers:
      - "when session ends"
      - "wrap up"
      - "what did we learn"
      - "capture learnings"
      - "session review"
---

# Wrap-Up -- Per-Skill Learning Capture

**Purpose:** At the end of every meaningful session, capture what was learned and write it
to the specific skill's `learnings.md` file. This is how skills get smarter over time.

---

## Procedure

### Step 1 -- Identify Skills Used

Scan the current session for:
- Skill invocations (SKILL.md loads, `/skill-name` triggers)
- Tool calls that map to a skill directory
- Explicit mentions of skill names in conversation

```
Output: list of skill names used this session
Example: [nanobanana, jade-ig-poster, social-publish]
```

### Step 2 -- Extract Feedback Per Skill

For each skill used, scan the session for:
- **Corrections:** "that's wrong", "no, do it like this", "not X, Y instead"
- **Confirmations:** "perfect", "that worked", "exactly right"
- **Failures:** errors, retries, workarounds that indicate a gap
- **New patterns:** novel usage that worked well, unexpected combinations

Flag entries as: `CORRECTION`, `CONFIRMATION`, `FAILURE`, `PATTERN`

### Step 3 -- Generate Structured Learning Entry

For each skill with feedback, write a learning entry:

```markdown
## YYYY-MM-DD — [TYPE]
**What happened:** one-line summary of the situation
**What worked:** what to keep doing (or "N/A")
**What failed:** what to stop doing (or "N/A")
**Pattern:** actionable rule for next time
```

### Step 4 -- Append to Skill Learnings File

Write each entry to `~/.openclaw/skills/{skill-name}/learnings.md`

```bash
SKILL_DIR="/Users/jennwoeiloh/.openclaw/skills/{skill-name}"
LEARNINGS="$SKILL_DIR/learnings.md"

# Create if missing
if [ ! -f "$LEARNINGS" ]; then
  echo "# Learnings — {skill-name}" > "$LEARNINGS"
  echo "" >> "$LEARNINGS"
fi

# Append new entry (agent writes the markdown block)
cat >> "$LEARNINGS" << 'ENTRY'
## 2026-03-27 — CORRECTION
**What happened:** Used listicle format for narrative brand content
**What worked:** N/A
**What failed:** Listicle felt robotic for Mirra brand voice
**Pattern:** Mirra content should use flowing prose, not bullet lists
ENTRY
```

### Step 5 -- Prune If Over 50 Lines

If `learnings.md` exceeds 50 lines after appending:

1. Read all entries
2. Merge duplicate patterns (same lesson learned twice = one entry)
3. Remove obvious entries (things that are already in SKILL.md or DNA.json)
4. Keep only actionable insights — entries that change future behavior
5. Rewrite the file with pruned content

```bash
LINE_COUNT=$(wc -l < "$LEARNINGS" | tr -d ' ')
if [ "$LINE_COUNT" -gt 50 ]; then
  echo "Pruning $LEARNINGS ($LINE_COUNT lines > 50 limit)"
  # Agent reads, deduplicates, and rewrites
fi
```

### Step 6 -- Report Summary

Output a summary of all learnings captured:

```
SESSION WRAP-UP
Skills used: 3
Learnings captured: 5
  - nanobanana: 2 entries (1 CORRECTION, 1 PATTERN)
  - jade-ig-poster: 2 entries (1 FAILURE, 1 CONFIRMATION)
  - social-publish: 1 entry (1 PATTERN)
Files updated:
  - ~/.openclaw/skills/nanobanana/learnings.md
  - ~/.openclaw/skills/jade-ig-poster/learnings.md
  - ~/.openclaw/skills/social-publish/learnings.md
```

---

## Rules

- Only write learnings that **change future behavior** -- skip trivial observations
- Never overwrite existing learnings -- always append, then prune if needed
- One learning = one actionable pattern. No essays.
- If no feedback was given during the session, say so and skip -- don't invent learnings
- Prune threshold: 50 lines. After pruning, aim for 30-40 lines of high-signal entries
- Always use absolute paths (`/Users/jennwoeiloh/.openclaw/skills/...`), never `~`
