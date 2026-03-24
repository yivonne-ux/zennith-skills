#!/usr/bin/env bash
# jade-daily-dispatch.sh — Zenni calls this to trigger daily Jade Oracle content cycle
# This is the orchestration script that dispatches work to agents via dispatch.sh
#
# Usage: bash jade-daily-dispatch.sh [cycle]
#   cycle: morning | afternoon | evening | full (default: full)
#
# Called by: Zenni heartbeat, classify.sh SCRIPT tier, or manual
# Requires: dispatch.sh, oracle engine, NanoBanana

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"
DISPATCH="$OPENCLAW_DIR/skills/orchestrate-v2/scripts/dispatch.sh"
QMDJ_CALC="$OPENCLAW_DIR/skills/psychic-reading-engine/scripts/qmdj-calc.py"
CONTENT_DIR="$OPENCLAW_DIR/workspace/data/content/jade-oracle/daily"
ROOM_FILE="$OPENCLAW_DIR/workspace/rooms/mission-jade-oracle-launch.jsonl"
DATE=$(date +%Y-%m-%d)
TODAY_DIR="$CONTENT_DIR/$DATE"

mkdir -p "$TODAY_DIR"

CYCLE="${1:-full}"

log() {
    local msg="[jade-daily $(date +%H:%M:%S)] $1"
    echo "$msg"
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"from\":\"taoz\",\"type\":\"log\",\"body\":\"$1\"}" >> "$ROOM_FILE"
}

# ── MORNING CYCLE: Content Generation ──────────────────────────────────
morning_cycle() {
    log "Starting morning content cycle"

    # 1. Generate real-time oracle energy for today
    local qmdj_output="$TODAY_DIR/qmdj-realtime.json"
    if [[ -f "$QMDJ_CALC" ]]; then
        python3 "$QMDJ_CALC" --mode realtime > "$qmdj_output" 2>/dev/null || true
        log "oracle real-time energy generated: $qmdj_output"
    fi

    # 2. Dispatch to Dreami: daily oracle forecast
    local qmdj_context=""
    [[ -f "$qmdj_output" ]] && qmdj_context=$(cat "$qmdj_output" | head -50)

    bash "$DISPATCH" dreami \
        "Generate today's Jade Oracle daily energy reading for social media. Use the energy data as background inspiration but DO NOT mention QMDJ, 奇门遁甲, BaZi, or Chinese metaphysics terms in the output. Write as an oracle reader, not a metaphysics educator. Write 3 variations: (1) Short TikTok caption with emotional hook about self-love/growth, (2) IG carousel text (5 slides) about today's energy theme — use language like 'the cards say' or 'today's oracle energy', (3) Story script (15 sec). Brand voice: warm, personal, like a trusted friend. Topics: self-love, kindness, life transitions, trusting your intuition. Max 5-7 hashtags. Save to $TODAY_DIR/forecast-captions.md" \
        "jade-daily-forecast-$DATE" \
        "false" \
        "300" &

    # 3. Dispatch to Dreami: pick-a-card post
    bash "$DISPATCH" dreami \
        "Create a pick-a-card social post for Jade Oracle. Theme: 3 oracle card options (Left/Center/Right). Write the reveal for each card as a warm spiritual message about self-love, growth, or intuition. DO NOT use QMDJ or Chinese metaphysics terms — keep it accessible. Include: IG caption with soft CTA, TikTok caption with hook. Brand voice: warm, playful, encouraging. Max 5-7 hashtags. Save to $TODAY_DIR/pick-a-card.md" \
        "jade-pick-a-card-$DATE" \
        "false" \
        "300" &

    # 4. Dispatch to Dreami: ad copy variants
    bash "$DISPATCH" dreami \
        "Write 3 ad copy variants for Jade Oracle \$1 intro oracle reading. Hook types: (1) Curiosity - 'I tried a \$1 oracle reading and...', (2) Story - 'She almost did not book the reading. Here is what happened next.', (3) Urgency - 'Only 50 readings this week'. Each variant: headline, body (under 125 chars for FB), CTA. Target: spiritual women 25-44 navigating life transitions. DO NOT mention oracle or Chinese terms. Save to $TODAY_DIR/ad-copy.md" \
        "jade-ad-copy-$DATE" \
        "false" \
        "300" &

    wait
    log "Morning cycle dispatched (forecast + pick-a-card + ad copy)"
}

# ── AFTERNOON CYCLE: Research & Education ──────────────────────────────
afternoon_cycle() {
    log "Starting afternoon content cycle"

    # 1. Dispatch to Dreami: reel script (oracle-focused, NOT oracle)
    bash "$DISPATCH" dreami \
        "Write a 30-second TikTok/Reel script for Jade Oracle. Topics (pick one based on day of week): Mon=Self-love ritual morning routine, Tue=Signs the universe is speaking to you, Wed=How to trust your intuition, Thu=Oracle card meaning deep dive, Fri=Weekend energy forecast, Sat=Kindness as a spiritual practice, Sun=Week ahead oracle reading. DO NOT mention QMDJ, 奇门遁甲, or Chinese metaphysics. Jade is an oracle reader, not a metaphysics teacher. Format: HOOK (0-3s) → PAIN (3-8s) → TEASE (8-15s) → VALUE (15-25s) → CTA (25-30s). Save to $TODAY_DIR/reel-script.md" \
        "jade-reel-script-$DATE" \
        "false" \
        "300" &

    # 2. Dispatch to Scout: competitor check
    bash "$DISPATCH" scout \
        "Quick competitor check for Jade Oracle: Check Psychic Samira's latest TikTok posts (search @psychicsamira). Report: (1) Any new products or pricing changes, (2) Top performing hooks this week, (3) New ad creatives spotted. Keep it brief — 5 bullet points max. Save to $TODAY_DIR/competitor-intel.md" \
        "jade-competitor-check-$DATE" \
        "false" \
        "300" &

    wait
    log "Afternoon cycle dispatched (reel script + competitor check)"
}

# ── EVENING CYCLE: Review & Report ─────────────────────────────────────
evening_cycle() {
    log "Starting evening review cycle"

    # Count today's output files
    local file_count=$(find "$TODAY_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')

    # Post summary to room
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"from\":\"zenni\",\"type\":\"review\",\"body\":\"Daily Jade Oracle content review: $file_count files generated in $TODAY_DIR. Ready for posting approval.\"}" >> "$ROOM_FILE"

    log "Evening review: $file_count files generated today"

    # Auto-queue posts for IG
    local AUTO_POST="$OPENCLAW_DIR/skills/social-publish/scripts/jade-auto-post.sh"
    if [[ -f "$AUTO_POST" ]]; then
        bash "$AUTO_POST" "$DATE" 2>&1 || log "Auto-post queueing had errors (non-fatal)"
    fi

    # List what was produced
    if [[ -d "$TODAY_DIR" ]]; then
        echo "=== Today's Jade Oracle Content ($DATE) ==="
        ls -la "$TODAY_DIR/"
    fi
}

# ── RUN CYCLE ──────────────────────────────────────────────────────────
case "$CYCLE" in
    morning)   morning_cycle ;;
    afternoon) afternoon_cycle ;;
    evening)   evening_cycle ;;
    full)
        morning_cycle
        afternoon_cycle
        evening_cycle
        ;;
    *)
        echo "Usage: jade-daily-dispatch.sh [morning|afternoon|evening|full]"
        exit 1
        ;;
esac

log "Jade Oracle daily dispatch ($CYCLE) complete"
