---
name: wa-group-digest
description: Daily digest of WhatsApp group conversations for GAIA CORP-OS. Summarizes key topics, decisions, and action items from all monitored groups into a daily markdown file. Use when asked for "what happened in the groups today", "group digest", "WhatsApp summary", or when reviewing daily group activity.
---

# WA Group Digest

Generates a daily summary of all GAIA WhatsApp group activity.

## Output
- Location: `workspace/rooms/wa-groups/YYYY-MM-DD.md`
- One file per day, 30-day rolling window
- Format: per-group bullets — topics, decisions, action items

## Groups Covered
- Gaia Eats Marketing → myrmidons
- Gaia Sales Group → myrmidons
- Gaia Branding → artemis
- Gaia $$$ → myrmidons
- GAIA Townhall → main
- GAIA War Room → main

## Run Manually
```bash
bash ~/.openclaw/skills/wa-group-digest/scripts/daily-digest.sh
```

## Cron Schedule
Daily at 11pm MYT (3pm UTC)

## Reading a Digest
```bash
cat ~/.openclaw/workspace/rooms/wa-groups/$(date +%Y-%m-%d).md
```

## Search Past Digests
```bash
grep -r "keyword" ~/.openclaw/workspace/rooms/wa-groups/
```
