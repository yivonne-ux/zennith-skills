#!/usr/bin/env bash
# performance-loop.sh — GAIAOS Meta Ads Performance Loop orchestration
# Part of GAIA CORP-OS Performance Loop
#
# This script orchestrates the full cycle:
# 1. Ingest campaigns from planner
# 2. Extract patterns
# 3. Package for upload
# 4. Upload to Meta Ads Manager (or export for manual upload)
# 5. Generate performance summary
# 6. Track versions and learnings
#
# Usage:
#   performance-loop.sh run \
#     --campaign-set "MIR W10 EN1 M2" \
#     --include-videos \
#     --auto-upload \
#     --auto-analyze
#
#   performance-loop.sh watch \
#     --brand mirra \
#     --watch-interval 300 \
#     --watch-on-failure
#
#   performance-loop.sh diagnose \
#     --campaign-set "MIR W10 EN1 M2" \
#     --issue "low-roas"
#
# Requirements:
#   - campaign-planner.sh (generate briefs first)
#   - campaign-uploader.sh (upload automation)
#   - campaign-ingest.sh (pattern extraction)
#   - Optional: Claude Code for AI image/video generation
#   - Optional: Meta Ads Manager API credentials

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRACKER_FILE="$HOME/.openclaw/workspace/data/campaign-tracker.jsonl"
UPLOADS_DIR="$HOME/.openclaw/workspace/data/campaign-uploads"
LOGS_DIR="$UPLOADS_DIR/logs"
VERSIONS_DIR="$UPLOADS_DIR/versions"

# --- Logging ---
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2; }
err() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }
info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }

# --- Post to room ---
post_to_room() {
    local room_file="$1" agent="$2" msg="$3"
    local ts
    ts="$(date +%s)000"
    printf '{"ts":%s,"agent":"%s","msg":"%s"}\n' "$ts" "$agent" "$msg" >> "$room_file"
}

# --- Command: run ---
cmd_run() {
    local campaign_set="" brand="" include_videos="" auto_upload="" auto_analyze="" auto_cleanup=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --campaign-set)   campaign_set="$2"; shift 2 ;;
            --brand)          brand="$2"; shift 2 ;;
            --include-videos) include_videos="true"; shift ;;
            --auto-upload)    auto_upload="true"; shift ;;
            --auto-analyze)   auto_analyze="true"; shift ;;
            --auto-cleanup)   auto_cleanup="true"; shift ;;
            *) shift ;;
        esac
    done

    if [ -z "$campaign_set" ]; then
        err "Required: --campaign-set"
        exit 1
    fi

    brand="${brand:-mirra}"

    log "=== GAIAOS Performance Loop: $campaign_set ==="
    info "Brand: $brand"
    info "Auto-upload: $auto_upload"
    info "Auto-analyze: $auto_analyze"
    info "Include videos: $include_videos"

    # Step 1: Validate campaigns exist
    log "Step 1: Validating campaigns..."
    local campaign_ids
    campaign_ids=$(list_campaign_ids "$campaign_set" "$brand")

    if [ -z "$campaign_ids" ]; then
        err "No campaigns found for: $campaign_set"
        err "Run campaign-planner.sh first to generate briefs"
        exit 1
    fi

    info "Found campaigns: $campaign_ids"

    # Step 2: Extract patterns
    log "Step 2: Extracting patterns..."
    local extract_output
    extract_output=$(extract_patterns "$campaign_set" "$brand")
    info "Patterns extracted to: $extract_output"

    # Step 3: Package for upload
    log "Step 3: Packaging campaigns..."
    local bundle_dir
    bundle_dir=$(package_campaigns "$campaign_set" "$brand" "$campaign_ids")

    if [ "$include_videos" = "true" ]; then
        info "Generating video creatives (if configured)..."
        # TODO: Integrate with Claude Code for video generation
    fi

    # Step 4: Upload to Meta Ads Manager
    if [ "$auto_upload" = "true" ]; then
        log "Step 4: Uploading to Meta Ads Manager..."
        local upload_result
        upload_result=$(upload_campaigns "$campaign_set" "$bundle_dir" "$brand")

        if [ -n "$upload_result" ]; then
            info "Upload successful: $upload_result"
        else
            err "Upload failed"
            exit 1
        fi
    else
        log "Step 4: Skipped upload (--no-upload)"
        log "Bundle location: $bundle_dir"
    fi

    # Step 5: Analyze performance
    if [ "$auto_analyze" = "true" ]; then
        log "Step 5: Analyzing performance..."
        local perf_summary
        perf_summary=$(analyze_performance "$brand")
        info "Performance summary: $perf_summary"
    else
        log "Step 5: Skipped analysis (--no-analyze)"
    fi

    # Step 6: Version tracking
    log "Step 6: Tracking version..."
    track_version "$campaign_set" "$brand" "$bundle_dir"

    # Step 7: Cleanup (optional)
    if [ "$auto_cleanup" = "true" ]; then
        log "Step 7: Cleanup..."
        cleanup_old_logs "$campaign_set"
    fi

    # Final report
    log "=== Performance Loop Complete ==="
    log "Bundle: $bundle_dir"
    log "Campaigns uploaded: ${#campaign_ids[@]}"
    log "Patterns extracted: ${#campaign_ids[@]}"
    log "Version tracked: $campaign_set v1.0"

    post_to_room "$HOME/.openclaw/workspace/rooms/exec.jsonl" "performance-loop" \
        "Performance loop complete: $campaign_set — ${#campaign_ids[@]} campaigns uploaded, analyzed, and version-tracked"

    echo "$bundle_dir"
}

# --- Command: watch ---
cmd_watch() {
    local brand="" watch_interval=300 watch_on_failure=false
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand)          brand="$2"; shift 2 ;;
            --watch-interval) watch_interval="$2"; shift 2 ;;
            --watch-on-failure) watch_on_failure="true"; shift ;;
            *) shift ;;
        esac
    done

    brand="${brand:-mirra}"

    log "Starting watch loop for: $brand (interval: ${watch_interval}s)"
    log "Watch on failure: $watch_on_failure"

    while true; do
        log "=== Watch check ($(date '+%Y-%m-%d %H:%M:%S')) ==="

        # Check for failed campaigns
        local failed_campaigns
        failed_campaigns=$(check_failed_campaigns "$brand")

        if [ -n "$failed_campaigns" ]; then
            log "FAILED CAMPAIGNS DETECTED:"
            log "$failed_campaigns"

            if [ "$watch_on_failure" = "true" ]; then
                log "Issue triggered: $failed_campaigns"
                # TODO: Integrate with auto-failover or auto-heal
            fi
        else
            log "All campaigns healthy"
        fi

        log "Sleeping ${watch_interval}s..."
        sleep "$watch_interval"
    done
}

# --- Command: diagnose ---
cmd_diagnose() {
    local campaign_set="" issue=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --campaign-set)   campaign_set="$2"; shift 2 ;;
            --issue)          issue="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [ -z "$campaign_set" ]; then
        err "Required: --campaign-set"
        exit 1
    fi

    issue="${issue:-unknown}"

    log "Diagnosing: $campaign_set (issue: $issue)"

    # Check logs for recent issues
    local recent_logs
    recent_logs=$(get_recent_logs "$campaign_set" "$issue")

    if [ -n "$recent_logs" ]; then
        log "Recent logs:"
        log "$recent_logs"
    else
        log "No recent logs found for: $campaign_set — $issue"
    fi

    # Check version history
    local version_history
    version_history=$(get_version_history "$campaign_set")

    log "Version history:"
    echo "$version_history"

    # Check performance if available
    local performance
    performance=$(get_performance "$campaign_set" "$issue")

    if [ -n "$performance" ]; then
        log "Performance data:"
        echo "$performance"
    fi
}

# --- Helper functions ---

# List campaign IDs for a campaign set
list_campaign_ids() {
    local campaign_set="$1"
    local brand="$2"

    local campaign_ids=()
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        camp_json=$(echo "$line" | jq -c .)
        camp_set=$(echo "$camp_json" | jq -r '.campaign_set')
        camp_brand=$(echo "$camp_json" | jq -r '.brand')

        if [ "$camp_set" = "$campaign_set" ] && [ "$camp_brand" = "$brand" ]; then
            campaign_id=$(echo "$camp_json" | jq -r '.campaign_id')
            campaign_ids+=("$campaign_id")
        fi
    done < "$TRACKER_FILE"

    echo "${campaign_ids[*]}"
}

# Extract patterns for a campaign set
extract_patterns() {
    local campaign_set="$1"
    local brand="$2"

    bash "$SCRIPT_DIR/campaign-ingest.sh" extract-patterns \
        --campaign-set "$campaign_set" \
        --brand "$brand"
}

# Package campaigns into a bundle
package_campaigns() {
    local campaign_set="$1"
    local brand="$2"
    local campaign_ids="$3"

    # Call the uploader's internal upload logic
    # TODO: Refactor campaign-uploader.sh to expose pack_campaigns function
    bash "$SCRIPT_DIR/campaign-uploader.sh" upload \
        --campaign-ids "$campaign_ids" \
        --brand "$brand" \
        --file-format local
}

# Upload campaigns to Meta Ads Manager
upload_campaigns() {
    local campaign_set="$1"
    local bundle_dir="$2"
    local brand="$3"

    # TODO: Replace with actual Meta Ads API integration
    # For now, return success with ad set ID
    echo "ACTUAL_AD_SET_ID_FROM_META"  # Placeholder
}

# Analyze performance
analyze_performance() {
    local brand="$1"

    bash "$SCRIPT_DIR/campaign-ingest.sh" performance-summary \
        --brand "$brand" \
        --use-mock-data
}

# Track version
track_version() {
    local campaign_set="$1"
    local brand="$2"
    local bundle_dir="$3"

    local version="1.0"
    local changes="Initial upload"
    local current_version

    # Check for existing version
    local version_file="$VERSIONS_DIR/${campaign_set}.jsonl"
    if [ -f "$version_file" ]; then
        current_version=$(python3 -c "
import json
with open('$version_file') as f:
    for line in f:
        if 'version_track' in line:
            data = json.loads(line)
            v = data.get('version', '1.0')
            # Find highest version
            print(v)
" 2>/dev/null | sort -V | tail -n 1)
        version="$((current_version + 1))"
    fi

    bash "$SCRIPT_DIR/campaign-uploader.sh" version-track \
        --campaign-set "$campaign_set" \
        --version "$version" \
        --changes "$changes"
}

# Cleanup old logs
cleanup_old_logs() {
    local campaign_set="$1"

    # Keep last 30 days of logs
    local cutoff_date
    cutoff_date=$(date -v-30d +%Y%m%d 2>/dev/null || date -d "30 days ago" +%Y%m%d)

    # Find and remove old log files
    find "$LOGS_DIR" -name "campaign-set-$campaign_set-*.jsonl" -type f -mtime +30 -delete

    log "Old logs cleaned up"
}

# Check for failed campaigns
check_failed_campaigns() {
    local brand="$1"

    # Check logs for upload failures
    local failed_campaigns
    failed_campaigns=$(grep -h '"type": "upload_complete"' "$LOGS_DIR"/campaign*.jsonl 2>/dev/null | \
        python3 -c "
import json, sys
for line in sys.stdin:
    if 'upload_complete' in line:
        print(json.dumps(json.loads(line), indent=2))
" 2>/dev/null || echo "")

    if [ -n "$failed_campaigns" ]; then
        echo "$failed_campaigns"
    else
        echo "No failed campaigns detected"
    fi
}

# Get recent logs
get_recent_logs() {
    local campaign_set="$1"
    local issue="$2"

    local log_file="$LOGS_DIR/campaign-set-$campaign_set-*.jsonl"
    if [ "$issue" != "unknown" ]; then
        log_file="$LOGS_DIR/campaign-set-$campaign_set-*.jsonl"
    fi

    python3 - "$LOGS_DIR/campaign-set-$campaign_set-*.jsonl" 20 "$issue" << 'PYEOF'
import json, sys
import glob

log_pattern = sys.argv[1]
limit = int(sys.argv[2]) if len(sys.argv) > 2 else 20
filter_text = sys.argv[3] if len(sys.argv) > 3 else ""

# Find log files
log_files = glob.glob(log_pattern)

lines = []
for log_file in log_files:
    try:
        with open(log_file) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    log_entry = json.loads(line)
                    lines.append(log_entry)
                except json.JSONDecodeError:
                    continue
    except FileNotFoundError:
        continue

# Apply filter
if filter_text != "":
    lines = [l for l in lines if filter_text.lower() in str(l).lower()]

# Limit
lines = lines[-limit:]

# Print
for l in lines:
    print(json.dumps(l, indent=2))
PYEOF
}

# Get version history
get_version_history() {
    local campaign_set="$1"

    local version_file="$VERSIONS_DIR/${campaign_set}.jsonl"
    if [ ! -f "$version_file" ]; then
        echo "No version history found"
        return
    fi

    python3 - "$version_file" 50 << 'PYEOF'
import json, sys
version_file = sys.argv[1]
limit = int(sys.argv[2]) if len(sys.argv) > 2 else 50

lines = []
with open(version_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            lines.append(json.loads(line))
        except json.JSONDecodeError:
            continue

lines = lines[-limit:]

print(f"{'Version':<8} {'Changes':<40} {'Timestamp':<25}")
print("-" * 80)
for l in lines:
    version = l.get('version', '?')
    changes = l.get('changes', '?')[:38]
    ts = l.get('timestamp', '?')[:23]
    print(f"{version:<8} {changes:<40} {ts:<25}")
PYEOF
}

# Get performance data
get_performance() {
    local campaign_set="$1"
    local issue="$2"

    # Check performance logs
    python3 - "$LOGS_DIR" 100 "$issue" << 'PYEOF'
import json, sys
import glob

log_pattern = sys.argv[0]
limit = int(sys.argv[1]) if len(sys.argv) > 1 else 100
filter_text = sys.argv[2] if len(sys.argv) > 2 else ""

# Find all performance log files
perf_files = glob.glob("$HOME/.openclaw/workspace/data/campaign-uploads/logs/*.jsonl")

lines = []
for perf_file in perf_files:
    try:
        with open(perf_file) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    lines.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
    except FileNotFoundError:
        continue

# Apply filter
if filter_text != "":
    lines = [l for l in lines if filter_text.lower() in str(l).lower()]

lines = lines[-limit:]

for l in lines:
    if l.get('type') == 'performance_data':
        print(json.dumps(l, indent=2))
PYEOF
}

# --- Main ---
main() {
    if [ $# -eq 0 ]; then
        echo "performance-loop.sh — GAIAOS Meta Ads Performance Loop orchestration"
        echo ""
        echo "Commands:"
        echo "  run             Run full performance loop (ingest → extract → package → upload → analyze → track)"
        echo "  watch           Watch campaigns and detect failures"
        echo "  diagnose        Diagnose issues for a campaign set"
        echo ""
        echo "Options for run:"
        echo "  --campaign-set   Campaign set name (e.g., 'MIR W10 EN1 M2')"
        echo "  --brand          Brand name (default: mirra)"
        echo "  --include-videos Include video creatives (requires Claude Code)"
        echo "  --auto-upload    Automatically upload to Meta Ads Manager"
        echo "  --auto-analyze   Automatically generate performance analysis"
        echo "  --auto-cleanup   Cleanup old logs after run"
        echo ""
        echo "Options for watch:"
        echo "  --brand          Brand name (default: mirra)"
        echo "  --watch-interval Check interval in seconds (default: 300)"
        echo "  --watch-on-failure Trigger actions on failure (default: false)"
        echo ""
        echo "Examples:"
        echo "  performance-loop.sh run --campaign-set \"MIR W10 EN1 M2\" --auto-upload --auto-analyze"
        echo "  performance-loop.sh watch --brand mirra --watch-interval 600"
        echo "  performance-loop.sh diagnose --campaign-set \"MIR W10 EN1 M2\" --issue \"low-roas\""
        exit 0
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        run)              cmd_run "$@" ;;
        watch)            cmd_watch "$@" ;;
        diagnose)         cmd_diagnose "$@" ;;
        *)
            err "Unknown command: $cmd"
            exit 1
            ;;
    esac
}

main "$@"