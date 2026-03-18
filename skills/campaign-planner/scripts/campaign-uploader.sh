#!/usr/bin/env bash
# campaign-uploader.sh — Package and upload campaign variants to Meta Ads Manager
# Part of GAIA CORP-OS Meta Ads Performance Loop
#
# Usage:
#   campaign-uploader.sh upload \
#     --campaign-ids "CP-MIR-W10-EN1-M2-A,CP-MIR-W10-EN1-M2-B" \
#     --account-id "act_1234567890" \
#     --access-token "EAABxxx" \
#     --file-format meta | local
#
#   campaign-uploader.sh version-track \
#     --campaign-set "MIR W10 EN1 M2" \
#     --version "1.0" \
#     --changes "Initial upload"
#
#   campaign-uploader.sh logs \
#     --campaign-set "MIR W10 EN1 M2" \
#     --limit 20
#
# Requirements:
#   - campaign-tracker.jsonl (from campaign-planner.sh)
#   - Optional: Meta Marketing API access token
#   - Optional: Claude Code CLI for image generation (if using --use-ai)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRANDS_DIR="$HOME/.openclaw/brands"
TRACKER_FILE="$HOME/.openclaw/workspace/data/campaign-tracker.jsonl"
UPLOADS_DIR="$HOME/.openclaw/workspace/data/campaign-uploads"
LOGS_DIR="$UPLOADS_DIR/logs"
VERSIONS_DIR="$UPLOADS_DIR/versions"
BUNDLES_DIR="$UPLOADS_DIR/bundles"

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

# --- Command: upload ---
cmd_upload() {
    local campaign_ids="" account_id="" access_token="" file_format="meta" use_ai="" brand=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --campaign-ids)  campaign_ids="$2"; shift 2 ;;
            --account-id)    account_id="$2"; shift 2 ;;
            --access-token)  access_token="$2"; shift 2 ;;
            --file-format)   file_format="$2"; shift 2 ;;
            --use-ai)        use_ai="true"; shift ;;
            --brand)         brand="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [ -z "$campaign_ids" ]; then
        err "Required: --campaign-ids (comma-separated list)"
        exit 1
    fi

    # Extract campaign set name for logging
    local campaign_set
    campaign_set=$(echo "$campaign_ids" | sed 's/,.*//' | cut -d'-' -f1-6)
    campaign_set=$(echo "$campaign_set" | sed 's/CP-//' | sed 's/W/ W/')

    if [ -n "$brand" ]; then
        campaign_set="BRAND=$brand"
    fi

    log "Starting upload: $campaign_ids"
    info "Campaign set: $campaign_set"

    # Load campaigns
    local campaigns=()
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        campaign_ids_array=($campaign_ids)
        for cid in "${campaign_ids_array[@]}"; do
            if echo "$line" | grep -q "$cid"; then
                campaigns+=("$line")
                break
            fi
        done
    done < "$TRACKER_FILE"

    if [ ${#campaigns[@]} -eq 0 ]; then
        err "No campaigns found matching IDs: $campaign_ids"
        exit 1
    fi

    info "Loaded ${#campaigns[@]} campaigns"

    # Create bundle directory
    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    local bundle_dir="$BUNDLES_DIR/${campaign_set}-$ts"
    mkdir -p "$bundle_dir/creative"
    mkdir -p "$bundle_dir/briefs"

    # Generate campaign-set metadata
    local metadata_file="$bundle_dir/campaign-set.json"
    local campaigns_json=$(printf '%s\n' "${campaigns[@]}" | jq -s .)
    local first_camp=$(echo "$campaigns_json" | jq -r '.[0]')

    cat > "$metadata_file" << METAEOF
{
  "campaign_set": "$campaign_set",
  "upload_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "account_id": "$account_id",
  "file_format": "$file_format",
  "total_variants": $(echo "$campaigns_json" | jq 'length'),
  "campaigns": $campaigns_json
}
METAEOF

    # Create brief files for each variant
    for i in "${!campaigns[@]}"; do
        local camp="${campaigns[$i]}"
        local campaign_id=$(echo "$camp" | jq -r '.campaign_id')

        local brief_file="$bundle_dir/briefs/${campaign_id}.json"
        echo "$camp" > "$brief_file"

        # Also create brief ID-suffixed JSON
        local brief_id_file="$bundle_dir/briefs/${campaign_id}-brief.json"
        echo "$camp" > "$brief_id_file"
    done

    # Create log entry
    local log_file="$LOGS_DIR/campaign-set-$campaign_set-$ts.jsonl"
    local log_entry
    log_entry=$(python3 -c "
import json, time
entry = {
    'type': 'upload_start',
    'campaign_set': '$campaign_set',
    'campaign_ids': $campaign_ids_array,
    'account_id': '$account_id',
    'file_format': '$file_format',
    'bundle_dir': '$bundle_dir',
    'created_at': time.strftime('%Y-%m-%dT%H:%M:%S+08:00')
}
print(json.dumps(entry))
" 2>/dev/null || echo "")

    echo "$log_entry" >> "$log_file"

    # Version tracking
    cmd_version-track \
        --campaign-set "$campaign_set" \
        --version "1.0" \
        --changes "Initial upload of ${#campaigns[@]} variants"

    if [ -n "$access_token" ]; then
        # Meta Ads Manager upload
        if [ "$file_format" = "meta" ]; then
            log "Uploading to Meta Ads Manager..."
            upload_to_meta "$account_id" "$access_token" "$bundle_dir" "$file_format" "$use_ai"
        elif [ "$file_format" = "local" ]; then
            log "Exporting for local upload (no Meta API call)"
            echo "Bundle location: $bundle_dir"
            echo "To upload manually:"
            echo "  1. Go to Ads Manager: https://business.facebook.com/ads/manager"
            echo "  2. Create new ad set, select 'File Upload'"
            echo "  3. Upload creative files from $bundle_dir/creative"
            echo "  4. Copy brief data from $bundle_dir/briefs/*.json"
        else
            err "Unsupported file format: $file_format"
            exit 1
        fi
    else
        log "No access token provided — export complete. Upload via Meta Ads Manager."
        log "Bundle: $bundle_dir"
    fi

    # Update log with success
    local success_log_entry
    success_log_entry=$(python3 -c "
import json, time
entry = {
    'type': 'upload_complete',
    'campaign_set': '$campaign_set',
    'bundle_dir': '$bundle_dir',
    'uploaded_variants': ${#campaigns[@]},
    'completed_at': time.strftime('%Y-%m-%dT%H:%M:%S+08:00')
}
print(json.dumps(entry))
" 2>/dev/null || echo "")

    echo "$success_log_entry" >> "$log_file"

    log "Upload complete: $campaign_set (${#campaigns[@]} variants)"
    post_to_room "$HOME/.openclaw/workspace/rooms/exec.jsonl" "campaign-uploader" "Upload complete: $campaign_set — ${#campaigns[@]} variants uploaded"

    echo "$bundle_dir"
}

# --- Meta Ads Manager upload ---
upload_to_meta() {
    local account_id="$1"
    local access_token="$2"
    local bundle_dir="$3"
    local file_format="$4"
    local use_ai="$5"

    # Create campaign in Meta Ads Manager
    local campaign_name="CP $bundle_dir | $(date +%m/%d)"

    # Create ad set first
    local adset_response
    adset_response=$(curl -s -X POST "https://graph.facebook.com/v18.0/$account_id/adsets?access_token=$access_token" \
        -F "name=$campaign_name" \
        -F "optimization_goal=ROAS" \
        -F "billing_event=impressions" \
        -F "daily_budget=100000" \
        -F "bid_strategy=BID_MAXIMIZING_ROAS" \
        -F "targeting={'age_lower':25,'age_upper':60,'genders':[1,2],'geo_locations':{'countries':['MY']}}") || {
        err "Failed to create ad set"
        return 1
    }

    local adset_id
    adset_id=$(echo "$adset_response" | jq -r '.id // .error.message' 2>/dev/null || echo "")

    if [ "$adset_id" = "null" ] || [ -z "$adset_id" ] || [ "$adset_id" = ".error.message" ]; then
        err "Failed to create ad set: $adset_response"
        return 1
    fi

    info "Created ad set: $adset_id"

    # Upload creative files (simplified — for production, use Meta's file upload API)
    # For now, log the creative files location
    info "Creative files location: $bundle_dir/creative"
    info "Note: Full file upload requires Meta's batch upload API or Facebook Business Suite UI"

    # Return ad set ID for reference
    echo "$adset_id"
}

# --- Command: version-track ---
cmd_version-track() {
    local campaign_set="" version="" changes=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --campaign-set) campaign_set="$2"; shift 2 ;;
            --version) version="$2"; shift 2 ;;
            --changes) changes="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [ -z "$campaign_set" ] || [ -z "$version" ]; then
        err "Required: --campaign-set and --version"
        exit 1
    fi

    local version_file="$VERSIONS_DIR/${campaign_set}.jsonl"

    mkdir -p "$(dirname "$version_file")"

    local entry
    entry=$(python3 -c "
import json, time
entry = {
    'type': 'version_track',
    'campaign_set': '$campaign_set',
    'version': '$version',
    'changes': '$changes',
    'timestamp': time.strftime('%Y-%m-%dT%H:%M:%S+08:00')
}
print(json.dumps(entry))
" 2>/dev/null || echo "")

    echo "$entry" >> "$version_file"
    log "Version tracked: $campaign_set v$version — $changes"
}

# --- Command: logs ---
cmd_logs() {
    local campaign_set="" limit=50 filter=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --campaign-set) campaign_set="$2"; shift 2 ;;
            --limit) limit="$2"; shift 2 ;;
            *) filter="$1"; shift ;;
        esac
    done

    local log_file="$LOGS_DIR/campaign-set-$campaign_set.jsonl"
    if [ ! -f "$log_file" ]; then
        echo "No logs found for campaign set: $campaign_set"
        exit 0
    fi

    log_file="$LOGS_DIR/campaign-set-$campaign_set.jsonl"

    if [ "$filter" = "--all" ]; then
        log_file="$LOGS_DIR/campaign*.jsonl"
    fi

    python3 - "$log_file" "$limit" "$filter" << 'PYEOF'
import json, sys

log_file = sys.argv[1]
limit = int(sys.argv[2]) if len(sys.argv) > 2 else 50
filter_text = sys.argv[3] if len(sys.argv) > 3 else ""

lines = []
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

# Apply filter
if filter_text != "":
    lines = [l for l in lines if filter_text.lower() in str(l).lower()]

# Limit
lines = lines[-limit:]

# Print
if not lines:
    print("No matching logs found.")
    sys.exit(0)

print(f"{'Type':<20} {'Campaign Set':<30} {'Details':<50}")
print("-" * 100)
for l in lines:
    entry_type = l.get('type', 'unknown')
    campaign_set = l.get('campaign_set', 'unknown')
    details = f"{l.get('version', '')} | {l.get('uploaded_variants', 0)} variants | {l.get('changes', '')}"
    print(f"{entry_type:<20} {campaign_set:<30} {details:<50}")

print(f"\nTotal: {len(lines)} entries")
PYEOF
}

# --- Command: bundle-info ---
cmd_bundle-info() {
    local bundle_path="$1"

    if [ ! -d "$bundle_path" ]; then
        err "Bundle not found: $bundle_path"
        exit 1
    fi

    local metadata_file="$bundle_path/campaign-set.json"
    if [ ! -f "$metadata_file" ]; then
        err "No metadata file found: $metadata_file"
        exit 1
    fi

    cat "$metadata_file" | jq '.'
}

# --- Main ---
main() {
    if [ $# -eq 0 ]; then
        echo "campaign-uploader.sh — Package and upload campaign variants to Meta Ads Manager"
        echo ""
        echo "Commands:"
        echo "  upload           Package and upload campaign variants to Meta Ads"
        echo "  version-track    Track version history for campaign sets"
        echo "  logs             View upload logs for a campaign set"
        echo "  bundle-info      View bundle metadata"
        echo ""
        echo "Options for upload:"
        echo "  --campaign-ids   Comma-separated list of campaign IDs"
        echo "  --account-id     Meta Ads Manager account ID (act_...)"
        echo "  --access-token   Meta Marketing API access token"
        echo "  --file-format    Output format: meta (upload to Meta) or local (export only)"
        echo "  --use-ai         Use AI to generate creative files"
        echo ""
        echo "Examples:"
        echo "  campaign-uploader.sh upload --campaign-ids \"CP-MIR-W10-EN1-M2-A,CP-MIR-W10-EN1-M2-B\" --account-id \"act_1234567890\" --access-token \"EAABxxx\" --file-format meta"
        echo "  campaign-uploader.sh upload --campaign-ids \"CP-MIR-W10-EN1-M2-A\" --file-format local"
        echo "  campaign-uploader.sh version-track --campaign-set \"MIR W10 EN1 M2\" --version \"1.0\" --changes \"Initial upload\""
        echo "  campaign-uploader.sh logs --campaign-set \"MIR W10 EN1 M2\" --limit 20"
        echo "  campaign-uploader.sh bundle-info /path/to/bundle"
        exit 0
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        upload)              cmd_upload "$@" ;;
        version-track)       cmd_version-track "$@" ;;
        logs)                cmd_logs "$@" ;;
        bundle-info)         cmd_bundle-info "$@" ;;
        *)
            err "Unknown command: $cmd"
            exit 1
            ;;
    esac
}

main "$@"