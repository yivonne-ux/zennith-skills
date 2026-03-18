# HEARTBEAT.md — Myrmidons (Worker Swarm)

## On Heartbeat

1. Check gateway process health:
   ```bash
   pgrep -f "openclaw-gateway|dist/index.js gateway" >/dev/null && echo "GATEWAY_UP" || echo "GATEWAY_DOWN"
   ```
2. If GATEWAY_DOWN: restart gateway
   ```bash
   nohup /usr/local/bin/node /Users/jennwoeiloh/local/lib/node_modules/openclaw/dist/index.js gateway > /dev/null 2>&1 &
   ```
3. Check disk space:
   ```bash
   df -h / | awk 'NR==2{print $5}' | tr -d '%'
   ```
4. If disk >85%: clean old session transcripts and logs
5. Check stale lock files:
   ```bash
   find /Users/jennwoeiloh/.openclaw/agents/ -name "*.lock" -mmin +30 -type f
   ```
6. If stale locks found: remove them
7. Check cron health (are cron jobs actually running):
   ```bash
   crontab -l | wc -l | tr -d ' '
   ```
8. If nothing broken: HEARTBEAT_OK
