#!/usr/bin/env bash
# daily-digest.sh — WhatsApp Group Daily Digest
# Reads yesterday's agent sessions for group chats, writes digest to rooms/wa-groups/
# Runs daily at 11pm MYT via cron

set -uo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

OPENCLAW_DIR="$HOME/.openclaw"
WORKSPACE="$OPENCLAW_DIR/workspace"
DIGEST_DIR="$WORKSPACE/rooms/wa-groups"
LOG="$OPENCLAW_DIR/logs/wa-group-digest.log"
DATE=$(date +"%Y-%m-%d")
TS=$(date +"%Y-%m-%d %H:%M:%S %Z")

mkdir -p "$DIGEST_DIR"

log() { echo "[$TS] $1" | tee -a "$LOG"; }

log "Starting daily group digest for $DATE"

# Dispatch to myrmidons to write the digest
openclaw agent \
  --agent myrmidons \
  --message "You are GAIA CORP-OS daily group digest writer.

Task: Read today's WhatsApp group session activity from the agent sessions and rooms files. Write a concise daily digest.

Output file: $DIGEST_DIR/$DATE.md

Format:
# GAIA WhatsApp Group Digest — $DATE

## [Group Name]
- **Key topics:** ...
- **Decisions made:** ...
- **Action items:** ...
- **Notable messages:** ...

## [Next Group]
...

---
*Generated $(date '+%Y-%m-%d %H:%M %Z') by GAIA CORP-OS*

Sources to check:
- $OPENCLAW_DIR/agents/myrmidons/sessions/ (today's sessions)
- $OPENCLAW_DIR/agents/artemis/sessions/ (branding group)
- $WORKSPACE/rooms/*.jsonl (room logs)

Groups covered:
- Gaia Eats Marketing (120363391028988812)
- Gaia Sales Group (120363151608113425)
- Gaia Branding (120363396623927737)
- Gaia \$\$\$ (120363406856284996)
- GAIA Townhall (120363425482945366)
- GAIA War Room (120363424991479424)

Keep each group section under 5 bullet points. Focus on actionable info only. If a group had no meaningful activity, write 'Quiet day — no notable activity.'

Write the file directly. Confirm with: cat $DIGEST_DIR/$DATE.md | wc -l" \
  >> "$LOG" 2>&1

log "Digest complete → $DIGEST_DIR/$DATE.md"

# Clean up digests older than 30 days (keep 30-day rolling window)
find "$DIGEST_DIR" -name "*.md" -mtime +30 -delete 2>/dev/null
log "Cleanup: removed digests older than 30 days"
