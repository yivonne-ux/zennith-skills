#!/bin/bash
# GAIA OS Self-Diagnose Script
# Checks: sessions, gateway RAM, cron errors
# Run by: cron job every 8 hours

set -e

echo "=== GAIA OS DIAGNOSTICS ==="
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo ""

# Check 1: Session Count
SESSION_COUNT=$(ls ~/.openclaw/sessions/ 2>/dev/null | wc -l | tr -d ' ')
echo "📊 Sessions: $SESSION_COUNT"
if [ "$SESSION_COUNT" -gt 80 ]; then
  echo "  🔴 RED FLAG: Session count > 80"
else
  echo "  ✅ GREEN"
fi
echo ""

# Check 2: Gateway RAM
GATEWAY_PID=$(ps aux | grep "openclaw-gateway" | grep -v grep | awk '{print $2}' | head -1)
if [ -n "$GATEWAY_PID" ]; then
  GATEWAY_RAM=$(ps -o rss= -p "$GATEWAY_PID" 2>/dev/null | awk '{print int($1/1024)"MB"}')
  GATEWAY_RAM_MB=$(ps -o rss= -p "$GATEWAY_PID" 2>/dev/null | awk '{print int($1/1024)}')
  echo "🖥️ Gateway RAM: $GATEWAY_RAM (pid: $GATEWAY_PID)"
  if [ "$GATEWAY_RAM_MB" -gt 1024 ]; then
    echo "  🔴 RED FLAG: Gateway RAM > 1GB"
  else
    echo "  ✅ GREEN"
  fi
else
  echo "🖥️ Gateway: NOT RUNNING"
  echo "  🔴 RED FLAG: Gateway process not found"
fi
echo ""

# Check 3: Gateway Status
if ps aux | grep "openclaw-gateway" | grep -v grep > /dev/null; then
  echo "🟢 Gateway Status: RUNNING"
else
  echo "🔴 Gateway Status: NOT RUNNING"
fi
echo ""

# Check 4: A2A Bridge
A2A_OFFLINE=$(grep -c "Peer gaia-secondary is offline" ~/.openclaw/logs/a2a-bridge.log 2>/dev/null || echo "0")
if [ "$A2A_OFFLINE" -gt 10 ]; then
  echo "⚠️ A2A Bridge: gaia-secondary offline ($A2A_OFFLINE recent pings)"
else
  echo "✅ A2A Bridge: Healthy"
fi
echo ""

# Check 5: Recent Cron Errors
CRON_ERRORS=$(grep -c "error\|fail\|timeout" ~/.openclaw/logs/agent-vitality-cron.log 2>/dev/null || echo "0")
echo "📋 Cron Log Errors (last 24h): $CRON_ERRORS"
if [ "$CRON_ERRORS" -gt 3 ]; then
  echo "  ⚠️ Multiple errors detected"
fi
echo ""

# Summary
echo "=== SUMMARY ==="
echo "Sessions: $SESSION_COUNT/80"
echo "Gateway: $([ -n "$GATEWAY_PID" ] && echo "Running ($GATEWAY_RAM)" || echo "NOT RUNNING")"
echo "A2A Peer: $([ "$A2A_OFFLINE" -gt 10 ] && echo "⚠️ Offline" || echo "Healthy")"
echo ""
echo "Next steps:"
echo "1. If gateway down: openclaw gateway restart"
echo "2. If A2A offline: Check gaia-secondary Fly.io app"
echo "3. If session > 80: Check for zombie sessions"
