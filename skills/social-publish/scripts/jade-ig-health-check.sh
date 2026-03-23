#!/usr/bin/env bash
# jade-ig-health-check.sh — Monitors the full Jade Oracle IG pipeline health
#
# Checks: token validity, content generation, posting history, learning loop,
#          cron jobs, disk space, and reports status.
#
# Usage:
#   bash jade-ig-health-check.sh          # Full health report
#   bash jade-ig-health-check.sh --json   # JSON output for monitoring
#   bash jade-ig-health-check.sh --fix    # Attempt auto-fixes

set -euo pipefail

OPENCLAW_DIR="$HOME/.openclaw"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
DATE=$(date +%Y-%m-%d)
OUTPUT_JSON=0
AUTO_FIX=0

for arg in "$@"; do
    [[ "$arg" == "--json" ]] && OUTPUT_JSON=1
    [[ "$arg" == "--fix" ]] && AUTO_FIX=1
done

# Result accumulators
STATUS="healthy"
CHECKS=()
ISSUES=()

check() {
    local name="$1" result="$2" detail="$3"
    CHECKS+=("$name:$result:$detail")
    if [[ "$result" == "FAIL" ]]; then
        [[ "$STATUS" != "critical" ]] && STATUS="degraded"
        ISSUES+=("$name: $detail")
    elif [[ "$result" == "CRITICAL" ]]; then
        STATUS="critical"
        ISSUES+=("$name: $detail")
    fi
    [[ "$OUTPUT_JSON" -eq 0 ]] && printf "  %-25s [%s] %s\n" "$name" "$result" "$detail"
}

###############################################################################
# Checks
###############################################################################

[[ "$OUTPUT_JSON" -eq 0 ]] && echo "=== Jade Oracle IG Pipeline Health Check ==="
[[ "$OUTPUT_JSON" -eq 0 ]] && echo "Date: $DATE"
[[ "$OUTPUT_JSON" -eq 0 ]] && echo

# 1. Meta API Token
SECRETS_FILE="$OPENCLAW_DIR/secrets/meta-marketing.env"
if [[ -f "$SECRETS_FILE" ]]; then
    # Source it
    while IFS='=' read -r key value; do
        key=$(echo "$key" | tr -d '[:space:]')
        [[ -z "$key" || "$key" == \#* ]] && continue
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        export "$key=$value" 2>/dev/null || true
    done < "$SECRETS_FILE"

    if [[ -n "${META_ACCESS_TOKEN:-}" ]]; then
        # Validate token — pipe JSON to Python to avoid shell escaping issues
        token_status=$(curl -s --max-time 10 "https://graph.facebook.com/v21.0/debug_token?input_token=${META_ACCESS_TOKEN}&access_token=${META_ACCESS_TOKEN}" 2>/dev/null | "$PYTHON3" -c "
import json, sys, time
try:
    d = json.load(sys.stdin).get('data', {})
    valid = d.get('is_valid', False)
    exp = d.get('expires_at', 0)
    if not valid:
        print('CRITICAL|Token is invalid')
    elif exp == 0:
        print('OK|Valid, never expires (permanent token)')
    else:
        days = max(0, (exp - int(time.time())) // 86400)
        if days < 7:
            print(f'FAIL|Expires in {days} days — needs refresh')
        else:
            print(f'OK|Valid, expires in {days} days')
except Exception as e:
    print(f'CRITICAL|Parse error: {e}')
" 2>/dev/null || echo "CRITICAL|Could not validate")

        token_result="${token_status%%|*}"
        token_detail="${token_status#*|}"
        check "meta_token" "$token_result" "$token_detail"
    else
        check "meta_token" "CRITICAL" "META_ACCESS_TOKEN not set"
    fi

    [[ -n "${IG_USER_ID:-}" ]] && check "ig_user_id" "OK" "$IG_USER_ID" || check "ig_user_id" "CRITICAL" "Not set — run: meta-token-manager.sh discover"
    [[ -n "${META_APP_SECRET:-}" ]] && check "app_secret" "OK" "Set" || check "app_secret" "FAIL" "Not set — needed for token refresh"
else
    check "secrets_file" "CRITICAL" "No secrets file at $SECRETS_FILE"
fi

# 2. Content Generation
CONTENT_DIR="$OPENCLAW_DIR/workspace/data/content/jade-oracle/daily/$DATE"
if [[ -d "$CONTENT_DIR" ]]; then
    local_count=$(find "$CONTENT_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$local_count" -gt 0 ]]; then
        check "content_today" "OK" "$local_count files generated"
    else
        check "content_today" "FAIL" "Directory exists but empty"
    fi
else
    check "content_today" "FAIL" "No content generated for $DATE"
fi

# 3. Posting History
POST_LOG="$OPENCLAW_DIR/workspace/data/social-publish/posting-history.jsonl"
if [[ -f "$POST_LOG" ]]; then
    total=$(wc -l < "$POST_LOG" | tr -d ' ')
    today=$(grep -c "\"$DATE\"" "$POST_LOG" 2>/dev/null || echo "0")
    last_post=$("$PYTHON3" -c "
import json
with open('$POST_LOG') as f:
    lines = [l.strip() for l in f if l.strip()]
    if lines:
        d = json.loads(lines[-1])
        print(d.get('date', 'unknown'))
    else:
        print('none')
" 2>/dev/null || echo "unknown")
    check "posting_history" "OK" "Total: $total, Today: $today, Last: $last_post"
else
    check "posting_history" "FAIL" "No posting history file"
fi

# 4. Image Assets
IMAGE_DIR="$OPENCLAW_DIR/workspace/data/images/jade-oracle/ig-library/jade"
if [[ -d "$IMAGE_DIR" ]]; then
    img_count=$(find "$IMAGE_DIR" -type f \( -name "*.png" -o -name "*.jpg" \) 2>/dev/null | wc -l | tr -d ' ')
    check "image_library" "OK" "$img_count images available"
else
    check "image_library" "FAIL" "No image library at $IMAGE_DIR"
fi

# 5. Face Refs (check multiple known locations)
FACE_DIR=""
for candidate in \
    "$OPENCLAW_DIR/workspace/data/characters/jade-oracle/jade/lock" \
    "$OPENCLAW_DIR/workspace/data/characters/jade-oracle/jade/face-refs" \
    "$HOME/Desktop/gaia-projects/jade-oracle-site/images/jade/v22-expressions" \
    "$HOME/Desktop/gaia-projects/jade-oracle-site/images/jade/v21-face-fixed"
do
    if [[ -d "$candidate" ]]; then
        FACE_DIR="$candidate"
        break
    fi
done

if [[ -n "$FACE_DIR" ]]; then
    ref_count=$(find "$FACE_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    check "face_refs" "OK" "$ref_count reference images in $FACE_DIR"
else
    check "face_refs" "FAIL" "No face lock refs found"
fi

# 6. Scripts
scripts_ok=0
scripts_total=0
for script in \
    "$OPENCLAW_DIR/skills/psychic-reading-engine/scripts/jade-daily-dispatch.sh" \
    "$OPENCLAW_DIR/skills/auto-research/scripts/jade-ig-daily.sh" \
    "$OPENCLAW_DIR/skills/auto-research/scripts/auto-loop.sh" \
    "$OPENCLAW_DIR/skills/social-publish/scripts/jade-auto-post.sh" \
    "$OPENCLAW_DIR/skills/social-publish/scripts/meta-token-manager.sh" \
    "$OPENCLAW_DIR/skills/social-publish/scripts/ig-publish.py" \
    "$OPENCLAW_DIR/skills/social-publish/scripts/jade-ig-loop-runner.sh"
do
    scripts_total=$((scripts_total + 1))
    [[ -f "$script" ]] && scripts_ok=$((scripts_ok + 1))
done
if [[ "$scripts_ok" -eq "$scripts_total" ]]; then
    check "pipeline_scripts" "OK" "$scripts_ok/$scripts_total scripts present"
else
    check "pipeline_scripts" "FAIL" "$scripts_ok/$scripts_total scripts present"
fi

# 7. Cron Jobs
cron_count=$(crontab -l 2>/dev/null | grep -c "jade-ig" 2>/dev/null || true)
cron_count=$(echo "$cron_count" | tr -d '[:space:]')
cron_count="${cron_count:-0}"
if [[ "$cron_count" -gt 0 ]]; then
    check "cron_jobs" "OK" "$cron_count jade-ig cron entries"
else
    check "cron_jobs" "FAIL" "No cron jobs installed — run: jade-ig-loop-runner.sh install-cron"
fi

# 8. Auto-Research Learnings
LEARNINGS="$OPENCLAW_DIR/workspace/data/auto-research/jade-instagram-loop/learnings.json"
if [[ -f "$LEARNINGS" ]]; then
    learning_count=$("$PYTHON3" -c "import json; d=json.load(open('$LEARNINGS')); print(len(d.get('posts',d.get('daily_digests',[]))))" 2>/dev/null || echo "0")
    check "learnings" "OK" "$learning_count entries"
else
    check "learnings" "FAIL" "No learnings file — auto-research loop hasn't run"
fi

# 9. Disk Space
disk_free=$(df -h "$HOME" 2>/dev/null | tail -1 | awk '{print $4}')
check "disk_space" "OK" "$disk_free free"

###############################################################################
# Summary
###############################################################################

if [[ "$OUTPUT_JSON" -eq 1 ]]; then
    "$PYTHON3" << PYEOF
import json
checks = []
for c in """$(IFS=';'; echo "${CHECKS[*]}")""".split(';'):
    parts = c.split(':', 2)
    if len(parts) == 3:
        checks.append({"name": parts[0], "status": parts[1], "detail": parts[2]})

issues = """$(IFS=';'; echo "${ISSUES[*]:-}")""".split(';') if """${ISSUES[*]:-}""" else []
issues = [i for i in issues if i.strip()]

print(json.dumps({
    "status": "$STATUS",
    "date": "$DATE",
    "checks": checks,
    "issues": issues
}, indent=2))
PYEOF
else
    echo
    echo "=== Overall Status: $STATUS ==="

    if [[ ${#ISSUES[@]} -gt 0 ]]; then
        echo
        echo "Issues to fix:"
        for issue in "${ISSUES[@]}"; do
            echo "  - $issue"
        done
    fi

    echo
    echo "Quick fixes:"
    echo "  Token setup:  bash meta-token-manager.sh setup"
    echo "  Token check:  bash meta-token-manager.sh validate"
    echo "  Install crons: bash jade-ig-loop-runner.sh install-cron"
    echo "  Dry run:      bash jade-ig-loop-runner.sh --dry-run"
    echo "  Full cycle:   bash jade-ig-loop-runner.sh full"
fi
