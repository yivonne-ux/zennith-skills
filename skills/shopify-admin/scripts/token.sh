#!/bin/bash
# shopify-admin token.sh — Get/refresh Shopify Admin API token
# Usage: token.sh [--test|--refresh|--json]
set -euo pipefail

CONFIG="${SHOPIFY_CONFIG:-./shopify.config.json}"
[ ! -f "$CONFIG" ] && echo "ERROR: $CONFIG not found" >&2 && exit 1

STORE=$(python3 -c "import json; print(json.load(open('$CONFIG'))['store'])")
CLIENT_ID=$(python3 -c "import json; print(json.load(open('$CONFIG'))['client_id'])")
CLIENT_SECRET=$(python3 -c "import json; print(json.load(open('$CONFIG'))['client_secret'])")
API_VER=$(python3 -c "import json; print(json.load(open('$CONFIG')).get('apiVersion','2024-10'))")
CURRENT_TOKEN=$(python3 -c "import json; print(json.load(open('$CONFIG')).get('token',''))")

test_token() {
  [ -z "$CURRENT_TOKEN" ] && return 1
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "X-Shopify-Access-Token: $CURRENT_TOKEN" \
    "https://$STORE/admin/api/$API_VER/shop.json")
  [ "$STATUS" = "200" ]
}

refresh_token() {
  RESPONSE=$(curl -s -X POST "https://$STORE/admin/oauth/access_token" \
    -H "Content-Type: application/json" \
    -d "{\"client_id\":\"$CLIENT_ID\",\"client_secret\":\"$CLIENT_SECRET\",\"grant_type\":\"client_credentials\"}")
  TOKEN=$(echo "$RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)
  [ -z "$TOKEN" ] && echo "ERROR: Failed to get token: $RESPONSE" >&2 && exit 1
  python3 -c "
import json, time
cfg = json.load(open('$CONFIG'))
cfg['token'] = '$TOKEN'
cfg['token_generated_at'] = time.strftime('%Y-%m-%dT%H:%M:%S%z')
json.dump(cfg, open('$CONFIG', 'w'), indent=2)
"
  CURRENT_TOKEN="$TOKEN"
  [ "${1:-}" = "--json" ] && echo "$RESPONSE" || echo "$TOKEN"
}

case "${1:-}" in
  --test)
    if test_token; then echo "VALID"; echo "$CURRENT_TOKEN"; exit 0
    else echo "EXPIRED" >&2; exit 1; fi ;;
  --refresh)
    refresh_token "$@" ;;
  --json)
    refresh_token --json ;;
  *)
    if test_token; then echo "$CURRENT_TOKEN"
    else refresh_token; fi ;;
esac
