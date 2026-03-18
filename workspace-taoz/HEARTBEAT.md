# HEARTBEAT.md — Taoz (CTO + Auditor)

## On Heartbeat

1. Run routing audit:
   ```bash
   gaia-auditor audit
   ```
2. If failed dispatches found (>0 failures):
   ```bash
   gaia-auditor orchestrate
   ```
3. If orchestration produced new patterns:
   ```bash
   gaia-auditor learn
   gaia-auditor test
   ```
4. If tests pass and patterns ready for promotion:
   ```bash
   gaia-auditor promote
   ```
5. Check gateway memory usage:
   ```bash
   ps aux | grep openclaw-gateway | grep -v grep | awk '{print $6}' | head -1
   ```
6. If memory >500MB: log warning to /Users/jennwoeiloh/.openclaw/workspace/rooms/ops.jsonl
7. If nothing to do: HEARTBEAT_OK
