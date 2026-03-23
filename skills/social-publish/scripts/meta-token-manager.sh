#!/usr/bin/env bash
# meta-token-manager.sh — Token lifecycle management for Meta Graph API
#
# Usage:
#   bash meta-token-manager.sh validate     # Check token validity + permissions
#   bash meta-token-manager.sh exchange     # Short-lived → long-lived token (60 days)
#   bash meta-token-manager.sh refresh      # Refresh long-lived token
#   bash meta-token-manager.sh discover     # Find IG User ID from connected pages
#   bash meta-token-manager.sh setup        # Interactive first-time setup
#   bash meta-token-manager.sh status       # Quick status check
#
# Secrets file: ~/.openclaw/secrets/meta-marketing.env

set -euo pipefail

SECRETS_DIR="$HOME/.openclaw/secrets"
SECRETS_FILE="$SECRETS_DIR/meta-marketing.env"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
API_VERSION="v21.0"
GRAPH_URL="https://graph.facebook.com/$API_VERSION"

log() { echo "[meta-token] $(date +%H:%M:%S) $*"; }
err() { echo "[meta-token] $(date +%H:%M:%S) ERROR: $*" >&2; }

###############################################################################
# Load secrets
###############################################################################

load_secrets() {
    if [[ -f "$SECRETS_FILE" ]]; then
        while IFS='=' read -r key value; do
            key=$(echo "$key" | tr -d '[:space:]')
            [[ -z "$key" || "$key" == \#* ]] && continue
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            export "$key=$value" 2>/dev/null || true
        done < "$SECRETS_FILE"
    fi
}

save_secret() {
    local key="$1" value="$2"
    mkdir -p "$SECRETS_DIR"
    chmod 700 "$SECRETS_DIR"

    if [[ -f "$SECRETS_FILE" ]]; then
        # Update existing key or append
        if grep -q "^${key}=" "$SECRETS_FILE" 2>/dev/null; then
            local tmp=$(mktemp)
            while IFS= read -r line; do
                if [[ "$line" == "${key}="* ]]; then
                    echo "${key}=${value}"
                else
                    echo "$line"
                fi
            done < "$SECRETS_FILE" > "$tmp"
            mv "$tmp" "$SECRETS_FILE"
        else
            echo "${key}=${value}" >> "$SECRETS_FILE"
        fi
    else
        echo "${key}=${value}" > "$SECRETS_FILE"
    fi
    chmod 600 "$SECRETS_FILE"
    log "Saved $key to $SECRETS_FILE"
}

###############################################################################
# API helper
###############################################################################

graph_get() {
    local endpoint="$1"
    shift
    local params="access_token=${META_ACCESS_TOKEN:-}"
    while [[ $# -gt 0 ]]; do
        params="${params}&$1"
        shift
    done
    curl -s --max-time 30 "${GRAPH_URL}${endpoint}?${params}"
}

graph_post() {
    local endpoint="$1"
    shift
    local data="access_token=${META_ACCESS_TOKEN:-}"
    while [[ $# -gt 0 ]]; do
        data="${data}&$1"
        shift
    done
    curl -s --max-time 30 -X POST "${GRAPH_URL}${endpoint}" -d "$data"
}

###############################################################################
# Commands
###############################################################################

cmd_validate() {
    load_secrets

    if [[ -z "${META_ACCESS_TOKEN:-}" ]]; then
        err "META_ACCESS_TOKEN not set. Run: bash meta-token-manager.sh setup"
        return 1
    fi

    log "Validating token..."
    local result
    result=$(graph_get "/debug_token" "input_token=${META_ACCESS_TOKEN}")

    local is_valid expires_at scopes app_id
    is_valid=$("$PYTHON3" -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('data',{}).get('is_valid',False))" <<< "$result")
    expires_at=$("$PYTHON3" -c "import json,sys,time; d=json.loads(sys.stdin.read()); e=d.get('data',{}).get('expires_at',0); print('never (permanent)' if e==0 else f'{(e-int(time.time()))//86400} days')" <<< "$result")
    scopes=$("$PYTHON3" -c "import json,sys; d=json.loads(sys.stdin.read()); print(','.join(d.get('data',{}).get('scopes',[])))" <<< "$result")

    log "Valid: $is_valid"
    log "Expires: $expires_at"
    log "Scopes: $scopes"

    # Check required perms
    local required="instagram_basic,instagram_content_publish,pages_show_list"
    local missing=""
    IFS=',' read -ra REQ <<< "$required"
    for perm in "${REQ[@]}"; do
        if ! echo "$scopes" | grep -q "$perm"; then
            missing="${missing}${perm} "
        fi
    done

    if [[ -n "$missing" ]]; then
        err "Missing permissions: $missing"
        err "Re-run meta-ig-setup.py token to get a token with all permissions"
        return 1
    fi

    # Check IG account
    if [[ -n "${IG_USER_ID:-}" ]]; then
        local ig_info
        ig_info=$(graph_get "/${IG_USER_ID}" "fields=username,followers_count,media_count")
        local username
        username=$("$PYTHON3" -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('username','unknown'))" <<< "$ig_info")
        log "Instagram: @$username"
    fi

    log "Token is valid and ready!"
    return 0
}

cmd_exchange() {
    load_secrets

    if [[ -z "${META_ACCESS_TOKEN:-}" ]]; then
        err "META_ACCESS_TOKEN not set"
        return 1
    fi
    if [[ -z "${META_APP_SECRET:-}" ]]; then
        err "META_APP_SECRET not set. Get it from Meta Developer Console > App Settings > Basic"
        return 1
    fi

    log "Exchanging short-lived token for long-lived token..."
    local result
    result=$(curl -s --max-time 30 \
        "${GRAPH_URL}/oauth/access_token?grant_type=fb_exchange_token&client_id=${META_APP_ID:-1647272119493183}&client_secret=${META_APP_SECRET}&fb_exchange_token=${META_ACCESS_TOKEN}")

    local new_token
    new_token=$("$PYTHON3" -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('access_token',''))" <<< "$result")

    if [[ -n "$new_token" && "$new_token" != "None" ]]; then
        save_secret "META_ACCESS_TOKEN" "$new_token"
        export META_ACCESS_TOKEN="$new_token"
        log "Long-lived token saved (valid ~60 days)"

        # Validate the new token
        cmd_validate
    else
        err "Token exchange failed: $result"
        return 1
    fi
}

cmd_refresh() {
    # Long-lived tokens can be refreshed if not expired
    # Same as exchange but with the long-lived token
    cmd_exchange
}

cmd_discover() {
    load_secrets

    if [[ -z "${META_ACCESS_TOKEN:-}" ]]; then
        err "META_ACCESS_TOKEN not set"
        return 1
    fi

    log "Discovering Instagram accounts from connected Facebook Pages..."
    local result
    result=$(graph_get "/me/accounts" "fields=id,name,instagram_business_account")

    "$PYTHON3" << PYEOF
import json, sys

data = json.loads('''$result''')
pages = data.get("data", [])

if not pages:
    print("[meta-token] No Facebook Pages found.")
    print("[meta-token] Connect a Facebook Page to your Instagram account first.")
    sys.exit(1)

found = False
for page in pages:
    name = page.get("name", "Unknown")
    page_id = page.get("id", "")
    ig = page.get("instagram_business_account", {})
    ig_id = ig.get("id", "")

    print(f"  Page: {name} (ID: {page_id})")
    if ig_id:
        print(f"  -> IG Business Account ID: {ig_id}")
        found = True
    else:
        print(f"  -> No Instagram linked")

if found:
    print()
    print("To save, run:")
    for page in pages:
        ig = page.get("instagram_business_account", {})
        if ig.get("id"):
            print(f"  bash meta-token-manager.sh save IG_USER_ID {ig['id']}")
            print(f"  bash meta-token-manager.sh save IG_PAGE_ID {page['id']}")
            break
PYEOF
}

cmd_save() {
    local key="${1:-}" value="${2:-}"
    if [[ -z "$key" || -z "$value" ]]; then
        err "Usage: meta-token-manager.sh save KEY VALUE"
        return 1
    fi
    save_secret "$key" "$value"
}

cmd_setup() {
    log "=== Meta Instagram API Token Setup ==="
    echo
    log "This will guide you through getting a token for Instagram posting."
    echo
    log "Step 1: Get a short-lived token"
    log "  Run: python3 ~/.openclaw/skills/browser-use/scripts/meta-ig-setup.py all"
    log "  This opens a browser for you to log into Facebook + Instagram"
    log "  The token will be saved to $SECRETS_FILE"
    echo
    log "Step 2: Save your App Secret"
    log "  Go to: https://developers.facebook.com/apps/1647272119493183/settings/basic/"
    log "  Copy the App Secret and run:"
    log "    bash meta-token-manager.sh save META_APP_SECRET <your-secret>"
    echo
    log "Step 3: Exchange for long-lived token (60 days)"
    log "  Run: bash meta-token-manager.sh exchange"
    echo
    log "Step 4: Discover your Instagram account ID"
    log "  Run: bash meta-token-manager.sh discover"
    echo
    log "Step 5: Validate everything"
    log "  Run: bash meta-token-manager.sh validate"
    echo
    log "After setup, the daily loop will auto-refresh tokens before expiry."
}

cmd_status() {
    load_secrets
    echo "=== Meta Token Status ==="
    echo "Secrets file: $SECRETS_FILE"
    echo "META_ACCESS_TOKEN: ${META_ACCESS_TOKEN:+SET (${#META_ACCESS_TOKEN} chars)}${META_ACCESS_TOKEN:-NOT SET}"
    echo "META_APP_ID: ${META_APP_ID:-NOT SET}"
    echo "META_APP_SECRET: ${META_APP_SECRET:+SET}${META_APP_SECRET:-NOT SET}"
    echo "IG_USER_ID: ${IG_USER_ID:-NOT SET}"
    echo "IG_PAGE_ID: ${IG_PAGE_ID:-NOT SET}"

    if [[ -n "${META_ACCESS_TOKEN:-}" ]]; then
        echo
        cmd_validate 2>/dev/null || true
    fi
}

###############################################################################
# Main
###############################################################################

CMD="${1:-status}"
shift 2>/dev/null || true

case "$CMD" in
    validate)  cmd_validate ;;
    exchange)  cmd_exchange ;;
    refresh)   cmd_refresh ;;
    discover)  cmd_discover ;;
    save)      cmd_save "$@" ;;
    setup)     cmd_setup ;;
    status)    cmd_status ;;
    *)
        echo "Usage: meta-token-manager.sh [validate|exchange|refresh|discover|save|setup|status]"
        exit 1
        ;;
esac
