#!/bin/bash
# Quick health check script for GAIA CORP-OS
# Usage: bash health-check.sh [--json]

set -euo pipefail

OUTPUT_JSON=false
if [[ "${1:-}" == "--json" ]]; then
  OUTPUT_JSON=true
fi

# === Memory Analysis ===
vm_output=$(vm_stat)
pages_free=$(echo "$vm_output" | grep "Pages free" | awk '{print $3}' | tr -d '.')
pages_active=$(echo "$vm_output" | grep "Pages active" | awk '{print $3}' | tr -d '.')
pages_wired=$(echo "$vm_output" | grep "Pages wired" | awk '{print $4}' | tr -d '.')
pages_compressed=$(echo "$vm_output" | grep "occupied by compressor" | awk '{print $5}' | tr -d '.')

page_size=4096
free_gb=$(echo "scale=2; ($pages_free * $page_size) / (1024^3)" | bc)
active_gb=$(echo "scale=2; ($pages_active * $page_size) / (1024^3)" | bc)
wired_gb=$(echo "scale=2; ($pages_wired * $page_size) / (1024^3)" | bc)
compressed_gb=$(echo "scale=2; ($pages_compressed * $page_size) / (1024^3)" | bc)
total_used=$(echo "scale=2; $active_gb + $wired_gb + $compressed_gb" | bc)
memory_pressure=$(echo "scale=1; ($total_used / 8.0) * 100" | bc)

# === Load Average ===
load_avg=$(uptime | awk -F'load averages: ' '{print $2}' | awk '{print $1}')

# === Disk Space ===
disk_usage=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
disk_free=$(df -h / | tail -1 | awk '{print $4}')

# === Gateway Status ===
gateway_pid=$(pgrep -f "openclaw-gateway" || echo "0")
if [[ "$gateway_pid" != "0" ]]; then
  gateway_status="UP"
else
  gateway_status="DOWN"
fi

# === Room Watcher Status ===
watcher_pid=$(cat ~/.openclaw/logs/room-watcher.pid 2>/dev/null || echo "0")
if ps -p "$watcher_pid" >/dev/null 2>&1; then
  watcher_status="UP"
else
  watcher_status="DOWN"
fi

# === Agent Session Sizes ===
session_count=0
large_sessions=0
for agent_dir in ~/.openclaw/agents/*/; do
  if [[ -f "$agent_dir/sessions/sessions.json" ]]; then
    session_count=$((session_count + 1))
    size=$(wc -c < "$agent_dir/sessions/sessions.json" | tr -d ' ')
    if [[ $size -gt 100000 ]]; then
      large_sessions=$((large_sessions + 1))
    fi
  fi
done

# === CPU Hogs ===
teamviewer_pid=$(pgrep -f "TeamViewer" | head -1 || echo "0")
if [[ "$teamviewer_pid" != "0" ]]; then
  teamviewer_cpu=$(ps -p "$teamviewer_pid" -o %cpu | tail -1 | awk '{print int($1)}')
  teamviewer_mem=$(ps -p "$teamviewer_pid" -o rss | tail -1 | awk '{print int($1/1024)}')
else
  teamviewer_cpu=0
  teamviewer_mem=0
fi

# === Health Score Calculation ===
# Gateway: 30 points, Automation: 30 points, Resources: 20 points, Agents: 20 points
gateway_score=30
if [[ "$gateway_status" == "DOWN" ]]; then gateway_score=0; fi

watcher_score=30
if [[ "$watcher_status" == "DOWN" ]]; then watcher_score=10; fi

resource_score=20
mem_pressure_int=$(echo "$memory_pressure" | awk '{print int($1)}')
if [[ $mem_pressure_int -gt 80 ]]; then resource_score=5;
elif [[ $mem_pressure_int -gt 70 ]]; then resource_score=10;
elif [[ $mem_pressure_int -gt 60 ]]; then resource_score=15;
fi

agent_score=20
if [[ $large_sessions -gt 5 ]]; then agent_score=10;
elif [[ $large_sessions -gt 3 ]]; then agent_score=15;
fi

total_score=$((gateway_score + watcher_score + resource_score + agent_score))
overall_score=$(echo "scale=1; $total_score / 10" | bc)

# === Status Determination ===
if [[ $total_score -ge 90 ]]; then
  status="HEALTHY"
elif [[ $total_score -ge 70 ]]; then
  status="STABLE_WITH_WARNINGS"
elif [[ $total_score -ge 50 ]]; then
  status="DEGRADED"
else
  status="CRITICAL"
fi

# === Output ===
if [[ "$OUTPUT_JSON" == true ]]; then
  cat <<JSON
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "status": "$status",
  "overall_score": $overall_score,
  "memory": {
    "free_gb": $free_gb,
    "pressure_percent": $memory_pressure,
    "total_used_gb": $total_used
  },
  "cpu": {
    "load_avg": $load_avg,
    "teamviewer_cpu": $teamviewer_cpu,
    "teamviewer_mem_mb": $teamviewer_mem
  },
  "disk": {
    "usage_percent": $disk_usage,
    "free": "$disk_free"
  },
  "services": {
    "gateway": "$gateway_status",
    "room_watcher": "$watcher_status"
  },
  "agents": {
    "total": $session_count,
    "large_sessions": $large_sessions
  },
  "scores": {
    "gateway": $gateway_score,
    "automation": $watcher_score,
    "resources": $resource_score,
    "agents": $agent_score,
    "total": $total_score
  }
}
JSON
else
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  GAIA CORP-OS Health Check"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Status: $status"
  echo "Score:  $overall_score / 10.0"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  System Metrics"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Memory:"
  echo "  Free:     ${free_gb}GB"
  echo "  Pressure: ${memory_pressure}%"
  if (( $(echo "$memory_pressure > 75" | bc -l) )); then
    echo "  Status:   ⚠️  HIGH"
  elif (( $(echo "$memory_pressure > 60" | bc -l) )); then
    echo "  Status:   ⚠️  MODERATE"
  else
    echo "  Status:   ✅ OK"
  fi
  echo ""
  echo "CPU:"
  echo "  Load Avg: $load_avg"
  if [[ $teamviewer_cpu -gt 50 ]]; then
    echo "  TeamViewer: ⚠️  ${teamviewer_cpu}% CPU, ${teamviewer_mem}MB RAM"
  elif [[ $teamviewer_cpu -gt 0 ]]; then
    echo "  TeamViewer: ${teamviewer_cpu}% CPU, ${teamviewer_mem}MB RAM"
  fi
  echo ""
  echo "Disk:"
  echo "  Usage: ${disk_usage}%"
  echo "  Free:  $disk_free"
  if [[ $disk_usage -gt 80 ]]; then
    echo "  Status: ⚠️  HIGH"
  else
    echo "  Status: ✅ OK"
  fi
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Services"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  if [[ "$gateway_status" == "UP" ]]; then
    echo "Gateway:      ✅ $gateway_status (PID $gateway_pid)"
  else
    echo "Gateway:      ❌ $gateway_status"
  fi

  if [[ "$watcher_status" == "UP" ]]; then
    echo "Room Watcher: ✅ $watcher_status (PID $watcher_pid)"
  else
    echo "Room Watcher: ❌ $watcher_status"
  fi
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Agents"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Total:          $session_count"
  if [[ $large_sessions -gt 0 ]]; then
    echo "Large Sessions: ⚠️  $large_sessions (>100KB)"
  else
    echo "Large Sessions: ✅ $large_sessions"
  fi
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Recommendations"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  if [[ $teamviewer_mem -gt 500 ]]; then
    echo "• Kill TeamViewer to free ${teamviewer_mem}MB RAM:"
    echo "  pkill -9 TeamViewer"
    echo ""
  fi
  if (( $(echo "$memory_pressure > 70" | bc -l) )); then
    echo "• Memory pressure high (${memory_pressure}%)"
    echo "  Consider 32GB RAM upgrade (~RM 250)"
    echo ""
  fi
  if [[ $large_sessions -gt 3 ]]; then
    echo "• $large_sessions agents have large sessions"
    echo "  Watchdog will auto-reset at 85% (171K tokens)"
    echo ""
  fi
  if [[ "$gateway_status" == "DOWN" ]]; then
    echo "• Gateway is DOWN. Restart:"
    echo "  openclaw gateway stop && openclaw gateway"
    echo ""
  fi
  if [[ "$watcher_status" == "DOWN" ]]; then
    echo "• Room Watcher is DOWN. Restart:"
    echo "  bash ~/.openclaw/skills/room-watcher/scripts/room-watcher.sh &"
    echo ""
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi
