# HEARTBEAT.md — Dreami (Creative Director)

## On Heartbeat

1. Check creative room for pending copy/content tasks:
   ```bash
   grep '"status":"pending"' /Users/jennwoeiloh/.openclaw/workspace/rooms/creative.jsonl | grep -i 'copy\|caption\|script\|edm\|content' | tail -5
   ```
2. If pending tasks: claim and produce copy (check brand DNA first)
3. Check seed bank for high-performing hooks that need variants:
   ```bash
   seed-store.sh top --type hook --limit 3
   ```
4. If top hooks exist and haven't been varied this week: generate 3 variants per hook
5. Review intake room for new content requests:
   ```bash
   tail -10 /Users/jennwoeiloh/.openclaw/workspace/rooms/intake.jsonl
   ```
6. If nothing pending: HEARTBEAT_OK
