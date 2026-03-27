#!/bin/bash
# shopify-admin api.sh — Shopify Admin API caller with auto-token-refresh
# Usage: api.sh METHOD endpoint [body]
# Example: api.sh GET products/count.json
#          api.sh POST products.json '{"product":{...}}'
set -euo pipefail

METHOD="${1:?Usage: api.sh METHOD endpoint [body]}"
ENDPOINT="${2:?Usage: api.sh METHOD endpoint [body]}"
BODY="${3:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="${SHOPIFY_CONFIG:-./shopify.config.json}"
[ ! -f "$CONFIG" ] && echo "ERROR: $CONFIG not found" >&2 && exit 1

# Auto-refresh token
TOKEN=$("$SCRIPT_DIR/token.sh")
STORE=$(python3 -c "import json; print(json.load(open('$CONFIG'))['store'])")
API_VER=$(python3 -c "import json; print(json.load(open('$CONFIG')).get('apiVersion','2024-10'))")

URL="https://$STORE/admin/api/$API_VER/$ENDPOINT"

if [ -n "$BODY" ]; then
  curl -s -X "$METHOD" "$URL" \
    -H "X-Shopify-Access-Token: $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$BODY"
else
  curl -s -X "$METHOD" "$URL" \
    -H "X-Shopify-Access-Token: $TOKEN"
fi
