#!/usr/bin/env bash
# ingest-meta.sh — Pull ad performance data from Meta Marketing API
# Part of the Ad Performance skill (Content Factory Phase 2)
#
# STATUS: STUB — Placeholder until Meta Marketing API token is configured.
#
# To set up:
#   1. Go to Meta Business Settings > System Users > Generate Token
#   2. Required permissions: ads_management, ads_read, read_insights
#   3. Save the token to: ~/.openclaw/secrets/meta-marketing.env
#      Format: META_MARKETING_TOKEN=EAAxxxxxxx
#              META_AD_ACCOUNT_ID=act_123456789
#   4. Run this script: bash ingest-meta.sh
#
# Usage:
#   bash ingest-meta.sh                     # pull last 7 days
#   bash ingest-meta.sh --days 30           # pull last 30 days
#   bash ingest-meta.sh --date-range 2026-02-01 2026-02-13
#
# Until the API token is configured, use the CSV export fallback:
#   bash ingest-csv.sh ~/Downloads/meta-report.csv
#   bash ingest-csv.sh --auto
#
# macOS-compatible: bash 3.2, no declare -A, no ${var,,}

set -euo pipefail

# --- Paths ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SECRETS_FILE="$HOME/.openclaw/secrets/meta-marketing.env"
SEED_STORE="$HOME/.openclaw/skills/content-seed-bank/scripts/seed-store.sh"
SEEDS_FILE="$HOME/.openclaw/workspace/data/seeds.jsonl"
ROOMS_DIR="$HOME/.openclaw/workspace/rooms"
EXEC_ROOM="$ROOMS_DIR/exec.jsonl"

# --- Meta API Config ---
META_API_BASE="https://graph.facebook.com/v21.0"
META_MARKETING_TOKEN=""
META_AD_ACCOUNT_ID=""

# --- Logging ---
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
err() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }

# --- Post to room ---
post_to_room() {
    local room_file="$1"
    local agent="$2"
    local msg="$3"
    local ts
    ts="$(date +%s)000"
    printf '{"ts":%s,"agent":"%s","msg":"%s"}\n' "$ts" "$agent" "$msg" >> "$room_file"
}

# --- Check for API token ---
check_token() {
    if [ ! -f "$SECRETS_FILE" ]; then
        echo ""
        echo "============================================"
        echo "  Meta Marketing API — Not Configured"
        echo "============================================"
        echo ""
        echo "The Meta Marketing API token has not been set up yet."
        echo ""
        echo "To configure:"
        echo "  1. Go to Meta Business Settings"
        echo "     https://business.facebook.com/settings/system-users"
        echo ""
        echo "  2. Create a System User (or use existing one)"
        echo ""
        echo "  3. Generate a token with these permissions:"
        echo "     - ads_management"
        echo "     - ads_read"
        echo "     - read_insights"
        echo ""
        echo "  4. Find your Ad Account ID in Ads Manager URL:"
        echo "     https://adsmanager.facebook.com/adsmanager/manage/campaigns?act=XXXXXXXXX"
        echo ""
        echo "  5. Create the secrets file:"
        echo "     mkdir -p ~/.openclaw/secrets"
        echo "     cat > ~/.openclaw/secrets/meta-marketing.env << EOF"
        echo "     META_MARKETING_TOKEN=EAAxxxxxxxxxxxxxxx"
        echo "     META_AD_ACCOUNT_ID=act_123456789"
        echo "     EOF"
        echo "     chmod 600 ~/.openclaw/secrets/meta-marketing.env"
        echo ""
        echo "  6. Run this script again: bash ingest-meta.sh"
        echo ""
        echo "============================================"
        echo "  FALLBACK: Use CSV export instead"
        echo "============================================"
        echo ""
        echo "  1. Go to Meta Ads Manager > Campaigns"
        echo "  2. Select campaigns > Export > Download CSV"
        echo "  3. Run: bash ingest-csv.sh ~/Downloads/your-report.csv"
        echo "     Or:  bash ingest-csv.sh --auto"
        echo ""
        exit 0
    fi

    # Source the secrets file
    # shellcheck source=/dev/null
    . "$SECRETS_FILE"

    if [ -z "${META_MARKETING_TOKEN:-}" ]; then
        err "META_MARKETING_TOKEN is empty in $SECRETS_FILE"
        exit 1
    fi

    if [ -z "${META_AD_ACCOUNT_ID:-}" ]; then
        err "META_AD_ACCOUNT_ID is empty in $SECRETS_FILE"
        exit 1
    fi

    log "Meta Marketing API token loaded"
    log "Ad Account: $META_AD_ACCOUNT_ID"
}

# --- Parse arguments ---
DAYS=7
DATE_START=""
DATE_END=""

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --days)
                DAYS="$2"
                shift 2
                ;;
            --date-range)
                DATE_START="$2"
                DATE_END="$3"
                shift 3
                ;;
            --help|-h)
                echo "Usage: bash ingest-meta.sh [--days N] [--date-range START END]"
                echo ""
                echo "Options:"
                echo "  --days N                Pull last N days (default: 7)"
                echo "  --date-range START END  Pull specific date range (YYYY-MM-DD)"
                echo "  --help                  Show this help"
                exit 0
                ;;
            *)
                err "Unknown argument: $1"
                exit 1
                ;;
        esac
    done

    # Calculate date range if not explicitly provided
    if [ -z "$DATE_START" ]; then
        # macOS date syntax
        DATE_END="$(date '+%Y-%m-%d')"
        DATE_START="$(date -v-${DAYS}d '+%Y-%m-%d')"
    fi
}

# --- TODO: Fetch campaigns from Meta API ---
fetch_campaigns() {
    # TODO: Implement when API token is available
    #
    # API endpoint: GET /{ad_account_id}/campaigns
    # Fields: id,name,status,objective,daily_budget,lifetime_budget
    #
    # Example curl:
    # curl -s "${META_API_BASE}/${META_AD_ACCOUNT_ID}/campaigns" \
    #     -d "fields=id,name,status,objective" \
    #     -d "access_token=${META_MARKETING_TOKEN}" \
    #     -d "limit=100"
    #
    # Response format:
    # {
    #   "data": [
    #     {"id": "123", "name": "Campaign Name", "status": "ACTIVE", ...}
    #   ],
    #   "paging": {"cursors": {"after": "..."}, "next": "..."}
    # }

    log "TODO: fetch_campaigns not yet implemented"
    echo "[]"
}

# --- TODO: Fetch campaign insights from Meta API ---
fetch_insights() {
    # TODO: Implement when API token is available
    #
    # API endpoint: GET /{ad_account_id}/insights
    # Fields: campaign_name,impressions,ctr,cpc,cpm,spend,
    #         actions,action_values,reach,
    #         cost_per_action_type
    # Breakdowns: campaign_id
    # Time range: {"since":"YYYY-MM-DD","until":"YYYY-MM-DD"}
    # Level: campaign
    #
    # Example curl:
    # curl -s "${META_API_BASE}/${META_AD_ACCOUNT_ID}/insights" \
    #     -d "fields=campaign_name,impressions,ctr,cpc,cpm,spend,actions,action_values,reach" \
    #     -d "level=campaign" \
    #     -d "time_range={\"since\":\"${DATE_START}\",\"until\":\"${DATE_END}\"}" \
    #     -d "access_token=${META_MARKETING_TOKEN}" \
    #     -d "limit=500"
    #
    # Response format:
    # {
    #   "data": [
    #     {
    #       "campaign_name": "...",
    #       "impressions": "12345",
    #       "ctr": "2.5",
    #       "cpc": "0.35",
    #       "spend": "150.00",
    #       "actions": [{"action_type":"purchase","value":"10"}, ...],
    #       ...
    #     }
    #   ]
    # }
    #
    # After fetching, transform to same JSON lines format as ingest-csv.sh
    # and feed through the same seed-matching logic.

    log "TODO: fetch_insights not yet implemented"
    echo "[]"
}

# --- TODO: Process insights and tag seeds ---
process_insights() {
    # TODO: Implement when API token is available
    #
    # 1. Parse insights JSON from fetch_insights
    # 2. Extract: campaign_name, impressions, ctr, cpc, cpm, spend, roas, engagement
    #    - ROAS: calculate from action_values (purchase) / spend
    #    - Engagement: sum of post_engagement actions
    #    - Conversions: count of purchase actions
    # 3. Match each campaign to seeds (same logic as ingest-csv.sh)
    # 4. Tag seeds with performance data
    # 5. Post summary to exec room

    log "TODO: process_insights not yet implemented"
}

# --- Main ---
main() {
    parse_args "$@"

    log "Meta Marketing API Ingest"
    log "Date range: $DATE_START to $DATE_END"

    # Check if API token is configured
    check_token

    # If we get here, the token is configured but the API calls are not yet implemented
    log ""
    log "API token is configured, but API integration is not yet implemented."
    log "This is a placeholder for future development."
    log ""
    log "For now, please use the CSV export method:"
    log "  bash ingest-csv.sh ~/Downloads/your-report.csv"
    log "  bash ingest-csv.sh --auto"
    log ""
    log "TODO list for full API integration:"
    log "  1. Implement fetch_campaigns() — GET /${META_AD_ACCOUNT_ID}/campaigns"
    log "  2. Implement fetch_insights() — GET /${META_AD_ACCOUNT_ID}/insights"
    log "  3. Implement process_insights() — transform + tag seeds"
    log "  4. Handle pagination (Meta API uses cursor-based paging)"
    log "  5. Handle rate limiting (200 calls per hour per ad account)"
    log "  6. Add incremental sync (track last-synced timestamp)"

    post_to_room "$EXEC_ROOM" "ad-performance" "Meta API ingest attempted but not yet implemented. Using CSV fallback."
}

main "$@"
