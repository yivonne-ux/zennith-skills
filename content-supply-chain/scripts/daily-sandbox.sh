#!/usr/bin/env bash
# daily-sandbox.sh — Daily automated testing, scouting, and learning for GAIA OS
# Runs via cron: 0 6 * * * (6am MYT daily)
#
# 3 phases:
#   1. SCOUT — scrape top players, new models, latest updates
#   2. TEST  — run E2E through OpenClaw gateway, verify routing, check agents
#   3. LEARN — compound results, publish to EvoMap, update agent knowledge
#
# Usage:
#   daily-sandbox.sh full          Run all 3 phases
#   daily-sandbox.sh scout         Scout only
#   daily-sandbox.sh test          Test only
#   daily-sandbox.sh learn         Learn only

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
SKILLS="$HOME/.openclaw/skills"
ROOMS="$WORKSPACE/rooms"
DATA="$WORKSPACE/data/sandbox"
LOG="$HOME/.openclaw/logs/daily-sandbox.log"
GW_TOKEN="2a11e48d086d44a061b19b61fbcebabcbe30fd0c9f862a5f"
TODAY=$(date +%Y-%m-%d)

mkdir -p "$DATA/$TODAY" "$(dirname "$LOG")"

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$1" | tee -a "$LOG"; }
post_room() {
  printf '{"ts":%s000,"agent":"sandbox","room":"%s","msg":"%s"}\n' \
    "$(date +%s)" "$1" "$2" >> "$ROOMS/${1}.jsonl" 2>/dev/null
}

# Check gateway is alive
check_gateway() {
  local health
  health=$(curl -s -m 5 http://127.0.0.1:3001/api/health 2>/dev/null || echo "")
  if echo "$health" | grep -q '"status":"ok"'; then
    return 0
  else
    log "⚠ Gateway not responding. Attempting restart..."
    nohup /usr/local/bin/node "$HOME/local/lib/node_modules/openclaw/dist/index.js" gateway > /dev/null 2>&1 &
    sleep 5
    health=$(curl -s -m 5 http://127.0.0.1:3001/api/health 2>/dev/null || echo "")
    if echo "$health" | grep -q '"status":"ok"'; then
      log "✓ Gateway restarted"
      return 0
    else
      log "✗ Gateway failed to start"
      return 1
    fi
  fi
}

# ═══════════════════════════════════════════
# PHASE 1: SCOUT
# ═══════════════════════════════════════════
phase_scout() {
  log "═══ PHASE 1: SCOUT ═══"
  local scout_file="$DATA/$TODAY/scout-report.json"
  local findings=0

  # 1a. Full Artemis scout via Gemini CLI (trends + competitors + ads + new models)
  if [ -f "$SKILLS/gemini-cli/scripts/artemis-scout.sh" ]; then
    log "Running Artemis daily scout (Gemini CLI, \$0)..."
    bash "$SKILLS/gemini-cli/scripts/artemis-scout.sh" daily --brand mirra >> "$LOG" 2>&1 || true
    findings=$((findings + 1))
  fi

  # 1b. Check seed bank health
  if [ -f "$SKILLS/content-seed-bank/scripts/seed-store.sh" ]; then
    for brand in mirra pinxin-vegan wholey-wonder; do
      local count
      count=$(bash "$SKILLS/content-seed-bank/scripts/seed-store.sh" count --brand "$brand" 2>/dev/null || echo "0")
      log "  Seed bank $brand: $count seeds"
    done
    findings=$((findings + 1))
  fi

  log "Scout complete: $findings data sources checked"
  printf '{"ts":%s000,"phase":"scout","findings":%s}\n' "$(date +%s)" "$findings" >> "$DATA/$TODAY/sandbox-log.jsonl"
}

# ═══════════════════════════════════════════
# PHASE 2: TEST
# ═══════════════════════════════════════════
phase_test() {
  log "═══ PHASE 2: TEST ═══"

  if ! check_gateway; then
    log "SKIP: Gateway unavailable"
    return 1
  fi

  local pass=0 fail=0 total=0

  # 2a. Routing regression (49 tests, no API cost)
  log "Running routing regression..."
  local routing_result
  routing_result=$(bash "$WORKSPACE/tests/regression/test-dispatch-routing.sh" 2>&1 || echo "FAIL")
  if echo "$routing_result" | grep -q "PASS"; then
    local routing_score
    routing_score=$(echo "$routing_result" | grep -oE '[0-9]+/[0-9]+' | head -1)
    log "  Routing: PASS ($routing_score)"
    pass=$((pass + 1))
  else
    log "  Routing: FAIL"
    fail=$((fail + 1))
  fi
  total=$((total + 1))

  # 2b. Gateway agent dispatch (real E2E, costs API tokens)
  log "Testing gateway dispatches..."
  local agents=("artemis" "dreami" "hermes" "athena")
  local messages=("status check" "hello, quick ack" "campaign status for mirra" "how are mirra ads performing")

  for i in 0 1 2 3; do
    local agent="${agents[$i]}"
    local msg="${messages[$i]}"
    local result
    result=$(timeout 60 openclaw agent --agent "$agent" --message "$msg" --json --channel webchat 2>&1 || echo '{"status":"error"}')
    local status
    status=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','error'))" 2>/dev/null || echo "error")
    if [ "$status" = "ok" ]; then
      log "  $agent dispatch: PASS"
      pass=$((pass + 1))
    else
      log "  $agent dispatch: FAIL ($status)"
      fail=$((fail + 1))
    fi
    total=$((total + 1))
  done

  # 2c. EvoMap connectivity
  log "Testing EvoMap..."
  local evo_status
  evo_status=$(bash "$SKILLS/evomap/scripts/evomap-gaia.sh" status 2>&1 || echo "FAIL")
  if echo "$evo_status" | grep -q "active"; then
    local reputation
    reputation=$(echo "$evo_status" | grep "Reputation" | awk '{print $NF}')
    log "  EvoMap: PASS (reputation: $reputation)"
    pass=$((pass + 1))
  else
    log "  EvoMap: FAIL"
    fail=$((fail + 1))
  fi
  total=$((total + 1))

  # 2d. Vault.db integrity
  log "Testing vault.db..."
  local vault_count
  vault_count=$(python3 -c "import sqlite3; db=sqlite3.connect('$WORKSPACE/vault/vault.db'); print(db.execute('SELECT COUNT(*) FROM vault').fetchone()[0])" 2>/dev/null || echo "0")
  if [ "$vault_count" -gt 0 ]; then
    log "  vault.db: PASS ($vault_count rows)"
    pass=$((pass + 1))
  else
    log "  vault.db: FAIL (empty or missing)"
    fail=$((fail + 1))
  fi
  total=$((total + 1))

  # 2e. SOUL.md obsession check (canonical 9 agents only)
  log "Testing SOUL.md obsessions..."
  local soul_pass=0 soul_total=0
  for agent_id in main taoz dreami artemis athena hermes iris argus myrmidons; do
    local soul_file="$HOME/.openclaw/workspace-${agent_id}/SOUL.md"
    soul_total=$((soul_total + 1))
    if grep -q "Obsession" "$soul_file" 2>/dev/null; then
      soul_pass=$((soul_pass + 1))
    fi
  done
  if [ "$soul_pass" -eq "$soul_total" ]; then
    log "  SOUL obsessions: PASS ($soul_pass/$soul_total)"
    pass=$((pass + 1))
  else
    log "  SOUL obsessions: FAIL ($soul_pass/$soul_total)"
    fail=$((fail + 1))
  fi
  total=$((total + 1))

  # 2f. Content supply chain status
  log "Testing content supply chain..."
  local chain_status
  chain_status=$(bash "$SKILLS/content-supply-chain/scripts/content-supply-chain.sh" status --brand mirra 2>&1 || echo "FAIL")
  local chain_installed
  chain_installed=$(echo "$chain_status" | grep -c "installed" || echo "0")
  if [ "$chain_installed" -ge 8 ]; then
    log "  Supply chain: PASS ($chain_installed/8 stages installed)"
    pass=$((pass + 1))
  else
    log "  Supply chain: FAIL ($chain_installed/8 stages)"
    fail=$((fail + 1))
  fi
  total=$((total + 1))

  # Summary
  log ""
  log "TEST RESULTS: $pass/$total passed, $fail failed"
  printf '{"ts":%s000,"phase":"test","pass":%s,"fail":%s,"total":%s}\n' \
    "$(date +%s)" "$pass" "$fail" "$total" >> "$DATA/$TODAY/sandbox-log.jsonl"

  post_room "exec" "[Daily Sandbox] Test: $pass/$total passed. $([ $fail -gt 0 ] && echo "FAILURES: $fail" || echo "All green.")"
}

# ═══════════════════════════════════════════
# PHASE 3: LEARN
# ═══════════════════════════════════════════
phase_learn() {
  log "═══ PHASE 3: LEARN ═══"

  # 3a. Run compound digest
  if [ -f "$SKILLS/knowledge-compound/scripts/digest.sh" ]; then
    log "Running knowledge digest..."
    bash "$SKILLS/knowledge-compound/scripts/digest.sh" --quick 2>/dev/null || true
  fi

  # 3b. Run content tuner (weekly on Sundays, daily A/B eval)
  local dow
  dow=$(date +%u)  # 1=Mon, 7=Sun
  if [ "$dow" -eq 7 ] && [ -f "$SKILLS/content-tuner/scripts/tune.sh" ]; then
    log "Running weekly content tuner..."
    bash "$SKILLS/content-tuner/scripts/tune.sh" 2>/dev/null || true
  fi
  if [ -f "$SKILLS/content-tuner/scripts/ab-framework.sh" ]; then
    log "Running A/B evaluation..."
    bash "$SKILLS/content-tuner/scripts/ab-framework.sh" evaluate 2>/dev/null || true
  fi

  # 3c. Publish to EvoMap (daily — we ship fast, reputation compounds daily)
  if [ -f "$SKILLS/evomap/scripts/evomap-gaia.sh" ]; then
    log "Publishing to EvoMap..."
    bash "$SKILLS/evomap/scripts/evomap-gaia.sh" publish --type skill --name "gaia-os-daily" --version "$TODAY" 2>/dev/null || true
  fi

  # 3d. Store scout findings in vault.db
  if [ -f "$DATA/$TODAY/new-models.txt" ]; then
    local model_text
    model_text=$(head -c 500 "$DATA/$TODAY/new-models.txt" 2>/dev/null | tr "'" "")
    if [ -n "$model_text" ]; then
      python3 -c "
import sqlite3, time
db = sqlite3.connect('$WORKSPACE/vault/vault.db')
db.execute('''INSERT OR IGNORE INTO vault (source_ref, source_type, text, agent, created_at)
              VALUES (?, 'scout-daily', ?, 'sandbox', datetime('now'))''',
           ('scout-$TODAY', '''$model_text'''))
db.commit()
print('  Stored scout findings in vault.db')
" 2>/dev/null || true
    fi
  fi

  # 3e. Post daily summary to townhall
  local test_summary=""
  if [ -f "$DATA/$TODAY/sandbox-log.jsonl" ]; then
    test_summary=$(tail -1 "$DATA/$TODAY/sandbox-log.jsonl" 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    if d.get('phase') == 'test':
        print(f\"Tests: {d['pass']}/{d['total']} passed\")
    else:
        print('Tests: not run')
except: print('Tests: unknown')
" 2>/dev/null || echo "Tests: unknown")
  fi

  post_room "townhall" "[Daily Sandbox $TODAY] $test_summary. Scout + Learn complete. System evolving."
  log "Learn complete"
  printf '{"ts":%s000,"phase":"learn","status":"complete"}\n' "$(date +%s)" >> "$DATA/$TODAY/sandbox-log.jsonl"
}

# ═══════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════
CMD="${1:-full}"

log ""
log "═══════════════════════════════════════════"
log " DAILY SANDBOX — $TODAY"
log "═══════════════════════════════════════════"

case "$CMD" in
  full)
    phase_scout
    phase_test
    phase_learn
    ;;
  scout) phase_scout ;;
  test) phase_test ;;
  learn) phase_learn ;;
  *)
    echo "Usage: daily-sandbox.sh <full|scout|test|learn>"
    exit 1
    ;;
esac

log ""
log "═══ DAILY SANDBOX COMPLETE ═══"
