# Claude Code — WhatsApp Bridges

## Forward Bridge (Claude Code → Rooms)
- Script: `cc-bridge.sh` (cron every 5 min)
- Reads Claude Code transcripts → posts activity summaries to build room
- Significant activity (>5 tool uses) also posted to exec room

## Reverse Bridge (Rooms → WhatsApp)
- Script: `wa-reverse-bridge.sh` (cron every 2 min)
- Scans rooms for messages with `"to":"jenn"` or `type:"taoz-result"`
- Creates `[WA-RELAY]` entries in exec room for Zenni to forward via WhatsApp
- Capped at 5 relays per run to prevent spam
