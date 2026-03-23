#!/usr/bin/env bash
# jade-ig-loop-runner.sh — Master orchestration loop for Jade Oracle Instagram
#
# This is the MAIN script that keeps the entire Jade IG pipeline running.
# It orchestrates: research → generate → image → post → learn → repeat
#
# Usage:
#   bash jade-ig-loop-runner.sh              # Run full daily cycle now
#   bash jade-ig-loop-runner.sh morning      # Run morning cycle only
#   bash jade-ig-loop-runner.sh afternoon    # Run afternoon cycle only
#   bash jade-ig-loop-runner.sh evening      # Run evening cycle (includes posting)
#   bash jade-ig-loop-runner.sh research     # Run research only
#   bash jade-ig-loop-runner.sh post         # Run posting only
#   bash jade-ig-loop-runner.sh learn        # Run learning loop only
#   bash jade-ig-loop-runner.sh health       # Run health check
#   bash jade-ig-loop-runner.sh setup-meta   # Interactive Meta API setup
#   bash jade-ig-loop-runner.sh install-cron # Install crontab entries
#   bash jade-ig-loop-runner.sh --dry-run    # Full cycle, no actual posting
#
# Designed to be called by cron or manually. Self-healing — checks health
# before each step and skips gracefully on failure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW_DIR="$HOME/.openclaw"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
DATE=$(date +%Y-%m-%d)
HOUR=$(date +%H)

# Core scripts
DAILY_DISPATCH="$OPENCLAW_DIR/skills/psychic-reading-engine/scripts/jade-daily-dispatch.sh"
IG_RESEARCH="$OPENCLAW_DIR/skills/auto-research/scripts/jade-ig-daily.sh"
AUTO_LOOP="$OPENCLAW_DIR/skills/auto-research/scripts/auto-loop.sh"
AUTO_POST="$SCRIPT_DIR/jade-auto-post.sh"
TOKEN_MGR="$SCRIPT_DIR/meta-token-manager.sh"
HEALTH_CHECK="$SCRIPT_DIR/jade-ig-health-check.sh"
IG_SETUP="$OPENCLAW_DIR/skills/browser-use/scripts/meta-ig-setup.py"

# 9-post system scripts
SOCIAL_DIRECTOR="$SCRIPT_DIR/jade-social-director.sh"
POST_GENERATOR="$SCRIPT_DIR/jade-9post-generator.sh"
ORACLE_CARD_GEN="$SCRIPT_DIR/jade-oracle-card-gen.sh"
QUOTE_GEN="$SCRIPT_DIR/jade-quote-gen.sh"
VIBE_REEL="$SCRIPT_DIR/jade-vibe-reel.sh"
SCHEDULE_JSON="$SKILL_DIR/data/jade-9post-schedule.json"
IG_PUBLISH="$SCRIPT_DIR/ig-publish.py"

# Config files
IG_LOOP_CONFIG="$OPENCLAW_DIR/skills/auto-research/configs/jade-instagram-loop.yaml"
CONTENT_PIPELINE="$OPENCLAW_DIR/skills/auto-research/configs/jade-content-pipeline.yaml"
AUDIT_CONFIG="$OPENCLAW_DIR/skills/auto-research/configs/jade-ig-content-audit.yaml"

# Output dirs
LOG_DIR="$OPENCLAW_DIR/logs"
CONTENT_DIR="$OPENCLAW_DIR/workspace/data/content/jade-oracle/daily/$DATE"
ROOM_FILE="$OPENCLAW_DIR/workspace/rooms/mission-jade-oracle-launch.jsonl"
HEALTH_FILE="$OPENCLAW_DIR/workspace/data/social-publish/health-status.json"

mkdir -p "$LOG_DIR" "$CONTENT_DIR" "$(dirname "$HEALTH_FILE")"

LOG_FILE="$LOG_DIR/jade-ig-loop-$(date +%Y%m%d).log"

# Parse args
DRY_RUN=0
CMD="${1:-full}"
for arg in "$@"; do
    [[ "$arg" == "--dry-run" ]] && DRY_RUN=1
done

###############################################################################
# Logging
###############################################################################

log() {
    local msg="[jade-loop $(date +%H:%M:%S)] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

err() {
    local msg="[jade-loop $(date +%H:%M:%S)] ERROR: $1"
    echo "$msg" >&2
    echo "$msg" >> "$LOG_FILE"
}

room_msg() {
    local type="$1" body="$2"
    [[ -f "$ROOM_FILE" ]] || return 0
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"from\":\"zenni\",\"type\":\"$type\",\"body\":\"$body\"}" >> "$ROOM_FILE" 2>/dev/null || true
}

###############################################################################
# Health Checks
###############################################################################

check_health() {
    log "Running health checks..."
    local status="ok"
    local issues=""

    # Check token
    if [[ -f "$TOKEN_MGR" ]]; then
        if bash "$TOKEN_MGR" validate >> "$LOG_FILE" 2>&1; then
            log "  Token: OK"
        else
            status="degraded"
            issues="${issues}token_invalid,"
            log "  Token: INVALID"
        fi
    else
        status="critical"
        issues="${issues}token_mgr_missing,"
        err "  Token manager not found: $TOKEN_MGR"
    fi

    # Check content generation tools
    if [[ -f "$DAILY_DISPATCH" ]]; then
        log "  Dispatch: OK"
    else
        status="degraded"
        issues="${issues}dispatch_missing,"
        err "  Dispatch script not found: $DAILY_DISPATCH"
    fi

    # Check auto-research
    if [[ -f "$AUTO_LOOP" ]]; then
        log "  Auto-research: OK"
    else
        status="degraded"
        issues="${issues}auto_research_missing,"
        err "  Auto-loop not found: $AUTO_LOOP"
    fi

    # Check today's content
    local content_count=$(find "$CONTENT_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    log "  Today's content files: $content_count"

    # Check posting history
    local post_log="$OPENCLAW_DIR/workspace/data/social-publish/posting-history.jsonl"
    if [[ -f "$post_log" ]]; then
        local total_posts=$(wc -l < "$post_log" | tr -d ' ')
        local today_posts=$(grep -c "\"$DATE\"" "$post_log" 2>/dev/null || echo "0")
        log "  Total posts: $total_posts, Today: $today_posts"
    else
        log "  No posting history yet"
    fi

    # Save health status
    "$PYTHON3" << PYEOF
import json
from datetime import datetime

status = {
    "status": "$status",
    "issues": "$issues".rstrip(",").split(",") if "$issues" else [],
    "content_files_today": $content_count,
    "checked_at": datetime.utcnow().isoformat() + "Z",
    "date": "$DATE"
}

with open("$HEALTH_FILE", "w") as f:
    json.dump(status, f, indent=2)
PYEOF

    log "Health: $status"
    [[ "$status" != "critical" ]]
}

###############################################################################
# Cycle Runners
###############################################################################

run_research() {
    log "=== RESEARCH CYCLE ==="

    if [[ ! -f "$IG_RESEARCH" ]]; then
        err "Research script not found: $IG_RESEARCH"
        return 1
    fi

    log "Running daily IG research..."
    if [[ "$DRY_RUN" -eq 1 ]]; then
        bash "$IG_RESEARCH" --dry-run >> "$LOG_FILE" 2>&1 || {
            err "Research dry-run failed"
            return 1
        }
    else
        bash "$IG_RESEARCH" >> "$LOG_FILE" 2>&1 || {
            err "Research failed (non-fatal, continuing)"
            return 0
        }
    fi

    log "Research complete"
    room_msg "research" "Daily IG research complete for $DATE"
}

run_morning() {
    log "=== MORNING CYCLE (Content Generation) ==="

    if [[ ! -f "$DAILY_DISPATCH" ]]; then
        err "Dispatch script not found: $DAILY_DISPATCH"
        return 1
    fi

    log "Dispatching morning content generation..."
    bash "$DAILY_DISPATCH" morning >> "$LOG_FILE" 2>&1 || {
        err "Morning dispatch failed"
        return 1
    }

    # Also run auto-research content pipeline for extra quality
    if [[ -f "$AUTO_LOOP" ]] && [[ -f "$CONTENT_PIPELINE" ]]; then
        log "Running content quality loop..."
        bash "$AUTO_LOOP" "$CONTENT_PIPELINE" >> "$LOG_FILE" 2>&1 || {
            log "Content pipeline loop finished (may have hit iteration limit)"
        }
    fi

    log "Morning cycle complete"
    room_msg "content" "Morning content generated for $DATE"
}

run_afternoon() {
    log "=== AFTERNOON CYCLE (Research + Education) ==="

    if [[ ! -f "$DAILY_DISPATCH" ]]; then
        err "Dispatch script not found"
        return 1
    fi

    log "Dispatching afternoon content..."
    bash "$DAILY_DISPATCH" afternoon >> "$LOG_FILE" 2>&1 || {
        err "Afternoon dispatch failed"
        return 1
    }

    log "Afternoon cycle complete"
    room_msg "content" "Afternoon content (reel script + competitor check) for $DATE"
}

run_evening() {
    log "=== EVENING CYCLE (Review + Post) ==="

    # Run dispatch evening review
    if [[ -f "$DAILY_DISPATCH" ]]; then
        bash "$DAILY_DISPATCH" evening >> "$LOG_FILE" 2>&1 || {
            err "Evening dispatch failed (non-fatal)"
        }
    fi

    # Auto-post to Instagram
    run_post
}

run_post() {
    log "=== POSTING ==="

    # Check if already posted today
    local post_log="$OPENCLAW_DIR/workspace/data/social-publish/posting-history.jsonl"
    if [[ -f "$post_log" ]] && grep -q "\"$DATE\"" "$post_log" 2>/dev/null; then
        log "Already posted today. Skipping."
        return 0
    fi

    if [[ ! -f "$AUTO_POST" ]]; then
        err "Auto-post script not found: $AUTO_POST"
        return 1
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        bash "$AUTO_POST" "$DATE" --dry-run >> "$LOG_FILE" 2>&1 || {
            err "Auto-post dry-run failed"
            return 1
        }
    else
        bash "$AUTO_POST" "$DATE" >> "$LOG_FILE" 2>&1 || {
            err "Auto-post failed"
            return 1
        }
    fi

    log "Posting complete"
    room_msg "ig-post" "Instagram post published for $DATE"
}

run_learn() {
    log "=== LEARNING CYCLE ==="

    if [[ ! -f "$AUTO_LOOP" ]] || [[ ! -f "$IG_LOOP_CONFIG" ]]; then
        err "Auto-research loop not available"
        return 1
    fi

    log "Running feedback learning loop..."
    bash "$AUTO_LOOP" "$IG_LOOP_CONFIG" >> "$LOG_FILE" 2>&1 || {
        log "Learning loop completed (may have hit iteration limit)"
    }

    log "Learning cycle complete"
    room_msg "learn" "IG engagement learning loop updated for $DATE"
}

run_full() {
    log "========================================="
    log "JADE ORACLE — FULL DAILY IG CYCLE"
    log "Date: $DATE"
    [[ "$DRY_RUN" -eq 1 ]] && log "MODE: DRY RUN"
    log "========================================="

    room_msg "cycle-start" "Full daily IG cycle starting for $DATE"

    # Health check first
    check_health || {
        err "Health check failed — running in degraded mode"
    }

    # Token refresh if needed (every 50 days, auto-refresh)
    if [[ "$DRY_RUN" -eq 0 ]] && [[ -f "$TOKEN_MGR" ]]; then
        local token_output
        token_output=$(bash "$TOKEN_MGR" validate 2>&1 || true)
        echo "$token_output" >> "$LOG_FILE"
        # Skip refresh for permanent tokens
        local token_days="99"
        if echo "$token_output" | grep -q "never (permanent)"; then
            token_days="999"
        else
            token_days=$(echo "$token_output" | grep "Expires" | grep -oE '[0-9]+' | head -1 || echo "99")
        fi
        if [[ "${token_days:-99}" -lt 10 ]]; then
            log "Token expiring in ${token_days} days — refreshing..."
            bash "$TOKEN_MGR" refresh >> "$LOG_FILE" 2>&1 || {
                err "Token refresh failed — manual intervention needed"
                room_msg "alert" "Meta token expiring in ${token_days} days and auto-refresh failed!"
            }
        fi
    fi

    # Run all cycles
    run_research || true
    run_morning || true
    run_afternoon || true
    run_evening || true
    run_learn || true

    log "========================================="
    log "FULL DAILY CYCLE COMPLETE"
    log "========================================="

    room_msg "cycle-end" "Full daily IG cycle complete for $DATE"
}

###############################################################################
# Setup helpers
###############################################################################

setup_meta() {
    log "=== META API SETUP ==="
    log "Starting interactive Meta API setup..."

    # Step 1: Check if meta-ig-setup.py exists
    if [[ ! -f "$IG_SETUP" ]]; then
        err "meta-ig-setup.py not found at $IG_SETUP"
        return 1
    fi

    # Step 2: Run setup
    bash "$TOKEN_MGR" setup

    echo
    log "After completing the setup steps above, run:"
    log "  bash jade-ig-loop-runner.sh health"
    log "  bash jade-ig-loop-runner.sh post --dry-run"
}

install_cron() {
    log "=== INSTALLING CRON JOBS ==="

    local RUNNER="$SCRIPT_DIR/jade-ig-loop-runner.sh"
    local LOG_BASE="$LOG_DIR"

    # Generate crontab entries — 9 POSTS/DAY SYSTEM
    local cron_entries="# Jade Oracle IG Pipeline — 9 Posts/Day — installed by jade-ig-loop-runner.sh
# ── PREPARATION (run once in early morning) ──
# 5:00 AM MYT (21:00 UTC) — Social director scrapes competitors + plans
0 21 * * * /bin/bash $RUNNER director >> $LOG_BASE/jade-ig-cron.log 2>&1
# 6:00 AM MYT (22:00 UTC) — Generate all 9 posts for the day
0 22 * * * /bin/bash $RUNNER generate-all >> $LOG_BASE/jade-ig-cron.log 2>&1

# ── 9 POSTING SLOTS (spread across the day, MYT) ──
# Slot 1: 7:00 AM MYT (23:00 UTC) — Oracle card of the day
0 23 * * * /bin/bash $RUNNER post-slot 1 >> $LOG_BASE/jade-ig-post.log 2>&1
# Slot 2: 8:30 AM MYT (00:30 UTC) — Jade lifestyle
30 0 * * * /bin/bash $RUNNER post-slot 2 >> $LOG_BASE/jade-ig-post.log 2>&1
# Slot 3: 10:00 AM MYT (02:00 UTC) — Spiritual quote
0 2 * * * /bin/bash $RUNNER post-slot 3 >> $LOG_BASE/jade-ig-post.log 2>&1
# Slot 4: 12:00 PM MYT (04:00 UTC) — QMDJ insight carousel
0 4 * * * /bin/bash $RUNNER post-slot 4 >> $LOG_BASE/jade-ig-post.log 2>&1
# Slot 5: 2:00 PM MYT (06:00 UTC) — Aesthetic flat lay
0 6 * * * /bin/bash $RUNNER post-slot 5 >> $LOG_BASE/jade-ig-post.log 2>&1
# Slot 6: 4:00 PM MYT (08:00 UTC) — Jade reading scene
0 8 * * * /bin/bash $RUNNER post-slot 6 >> $LOG_BASE/jade-ig-post.log 2>&1
# Slot 7: 6:00 PM MYT (10:00 UTC) — Subtle animation + music reel
0 10 * * * /bin/bash $RUNNER post-slot 7 >> $LOG_BASE/jade-ig-post.log 2>&1
# Slot 8: 8:00 PM MYT (12:00 UTC) — Pick-a-card interactive
0 12 * * * /bin/bash $RUNNER post-slot 8 >> $LOG_BASE/jade-ig-post.log 2>&1
# Slot 9: 10:00 PM MYT (14:00 UTC) — Jade behind-scenes
0 14 * * * /bin/bash $RUNNER post-slot 9 >> $LOG_BASE/jade-ig-post.log 2>&1

# ── LEARNING + MAINTENANCE ──
# 11:00 PM MYT (15:00 UTC) — Learning loop
0 15 * * * /bin/bash $RUNNER learn >> $LOG_BASE/jade-ig-cron.log 2>&1
# Health check every 6 hours
0 */6 * * * /bin/bash $RUNNER health >> $LOG_BASE/jade-ig-health.log 2>&1
# Weekly audit Sunday 11PM MYT
0 15 * * 0 /bin/bash $AUTO_LOOP $AUDIT_CONFIG >> $LOG_BASE/jade-ig-audit.log 2>&1
# Token validation Monday 6AM MYT
0 22 * * 0 /bin/bash $TOKEN_MGR validate >> $LOG_BASE/jade-ig-token.log 2>&1
"

    echo "$cron_entries"
    echo
    log "Review the cron entries above."
    log "To install, run:"
    log "  (crontab -l 2>/dev/null; cat << 'CRON'"
    echo "$cron_entries"
    log "CRON"
    log "  ) | crontab -"
    echo

    # Save to file for reference
    echo "$cron_entries" > "$SKILL_DIR/data/jade-ig-crontab.txt"
    log "Cron entries saved to: $SKILL_DIR/data/jade-ig-crontab.txt"

    # Ask to install
    echo
    read -p "Install these cron entries now? (y/N) " -n 1 -r REPLY 2>/dev/null || REPLY="n"
    echo
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        # Merge with existing crontab, removing old jade entries
        local tmp=$(mktemp)
        (crontab -l 2>/dev/null | grep -v "jade-ig-loop-runner\|jade-ig-daily\|jade-ig-cron\|jade-ig-health\|jade-ig-audit\|jade-ig-token" || true) > "$tmp"
        echo "$cron_entries" >> "$tmp"
        crontab "$tmp"
        rm -f "$tmp"
        log "Cron entries installed!"
        crontab -l
    else
        log "Cron entries NOT installed. Install manually when ready."
    fi
}

###############################################################################
# 9-Post System Commands
###############################################################################

run_director() {
    log "=== SOCIAL DIRECTOR ==="
    if [[ -f "$SOCIAL_DIRECTOR" ]]; then
        bash "$SOCIAL_DIRECTOR" full >> "$LOG_FILE" 2>&1 || {
            err "Social director failed (non-fatal)"
        }
        log "Social director complete"
    else
        err "Social director script not found: $SOCIAL_DIRECTOR"
    fi
}

run_generate_all() {
    log "=== GENERATING 9 POSTS ==="
    if [[ -f "$POST_GENERATOR" ]]; then
        local gen_flags=""
        [[ "$DRY_RUN" -eq 1 ]] && gen_flags="--dry-run"
        bash "$POST_GENERATOR" $gen_flags >> "$LOG_FILE" 2>&1 || {
            err "9-post generator failed"
            return 1
        }
        log "All 9 posts generated"
        room_msg "content" "9 posts generated for $DATE"
    else
        err "9-post generator not found: $POST_GENERATOR"
        return 1
    fi
}

run_post_slot() {
    local slot_num="${1:-}"
    if [[ -z "$slot_num" ]]; then
        err "Usage: jade-ig-loop-runner.sh post-slot N"
        return 1
    fi

    log "=== POSTING SLOT $slot_num ==="

    # Find the content for this slot
    local slot_image=$(find "$CONTENT_DIR" -name "slot-${slot_num}-*" -type f \( -name "*.png" -o -name "*.jpg" \) 2>/dev/null | head -1)
    local slot_caption="$CONTENT_DIR/slot-${slot_num}-caption.txt"

    if [[ -z "$slot_image" ]] || [[ ! -f "$slot_caption" ]]; then
        err "Content not found for slot $slot_num. Run generate-all first."
        return 1
    fi

    local caption=$(cat "$slot_caption")

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "[DRY RUN] Would post slot $slot_num: $slot_image"
        log "[DRY RUN] Caption: $(echo "$caption" | head -2)..."
        return 0
    fi

    # Check if already posted this slot today
    local post_log="$OPENCLAW_DIR/workspace/data/social-publish/posting-history.jsonl"
    if [[ -f "$post_log" ]] && grep -q "\"$DATE\".*\"slot\":$slot_num" "$post_log" 2>/dev/null; then
        log "Slot $slot_num already posted today. Skipping."
        return 0
    fi

    # Post via ig-publish.py
    local result
    result=$("$PYTHON3" "$IG_PUBLISH" image --image-path "$slot_image" --caption "$caption" 2>&1) || {
        err "Slot $slot_num posting failed: $result"
        return 1
    }

    log "Slot $slot_num posted! $result"
    echo "{\"date\":\"$DATE\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"slot\":$slot_num,\"image\":\"$slot_image\",\"status\":\"published\"}" >> "$post_log"
    room_msg "ig-post" "Slot $slot_num posted for $DATE"
}

run_9post_cycle() {
    log "========================================="
    log "JADE ORACLE — 9-POST DAILY CYCLE"
    log "Date: $DATE"
    [[ "$DRY_RUN" -eq 1 ]] && log "MODE: DRY RUN"
    log "========================================="

    room_msg "cycle-start" "9-post daily cycle starting for $DATE"

    # 1. Health check
    check_health || err "Health check failed — continuing in degraded mode"

    # 2. Social director (scrape + analyze + plan)
    run_director || true

    # 3. Generate all 9 posts
    run_generate_all || { err "Generation failed — aborting"; return 1; }

    # 4. Posts will be published by individual cron jobs (post-slot 1-9)
    log "9 posts generated and ready for scheduled publishing"
    log "Cron jobs will publish each slot at its scheduled time"

    # 5. Learning loop
    run_learn || true

    log "========================================="
    log "9-POST CYCLE COMPLETE"
    log "========================================="
    room_msg "cycle-end" "9-post cycle complete for $DATE"
}

###############################################################################
# Main
###############################################################################

case "$CMD" in
    full)           run_full ;;
    9post)          run_9post_cycle ;;
    morning)        run_morning ;;
    afternoon)      run_afternoon ;;
    evening)        run_evening ;;
    research)       run_research ;;
    post)           run_post ;;
    post-slot)      run_post_slot "${2:-}" ;;
    generate-all)   run_generate_all ;;
    director)       run_director ;;
    learn)          run_learn ;;
    health)         check_health ;;
    setup-meta)     setup_meta ;;
    install-cron)   install_cron ;;
    --dry-run)      DRY_RUN=1; run_9post_cycle ;;
    *)
        echo "Usage: jade-ig-loop-runner.sh [9post|full|generate-all|post-slot N|director|research|learn|health|setup-meta|install-cron] [--dry-run]"
        exit 1
        ;;
esac
