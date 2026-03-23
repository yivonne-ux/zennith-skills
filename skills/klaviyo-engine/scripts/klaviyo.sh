#!/usr/bin/env bash
# Klaviyo Engine — Full email marketing CLI for Zennith OS
# Usage: klaviyo.sh <command> [args]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SECRETS_DIR="$REPO_DIR/secrets"
KEY_FILE="$SECRETS_DIR/klaviyo-api-key"
API="https://a.klaviyo.com/api"
REV="2025-04-15"
P3="$(command -v python3 || echo /usr/bin/python3)"

get_key() {
  if [ ! -f "$KEY_FILE" ]; then
    echo "No Klaviyo API key. Run: klaviyo.sh setup <your_api_key>"
    exit 1
  fi
  cat "$KEY_FILE"
}

api_get() {
  curl -s "$API/$1" -H "Authorization: Klaviyo-API-Key $(get_key)" -H "revision: $REV"
}

api_post() {
  local endpoint="$1" payload_file="$2"
  curl -s -X POST "$API/$endpoint" \
    -H "Authorization: Klaviyo-API-Key $(get_key)" \
    -H "revision: $REV" \
    -H "Content-Type: application/json" \
    -d @"$payload_file"
}

parse_json() {
  "$P3" -c "$1"
}

msg_block() {
  local name="$1" subject="$2" template="$3"
  echo "{\"from_email\":\"hello@jadeoracle.co\",\"from_label\":\"Jade Oracle\",\"reply_to_email\":\"hello@jadeoracle.co\",\"cc_email\":\"\",\"bcc_email\":\"\",\"subject_line\":\"$subject\",\"preview_text\":\"\",\"template_id\":\"$template\",\"smart_sending_enabled\":true,\"transactional\":false,\"name\":\"$name\"}"
}

case "${1:-help}" in
  setup)
    mkdir -p "$SECRETS_DIR"
    echo "${2:?Usage: klaviyo.sh setup <api_key>}" > "$KEY_FILE"
    chmod 600 "$KEY_FILE"
    echo "API key saved to $KEY_FILE"
    ;;

  status)
    echo "=== KLAVIYO STATUS ==="
    echo "Lists:"
    api_get "lists" | parse_json "
import sys,json;d=json.loads(sys.stdin.read())
for i in d.get('data',[]): print(f'  {i[\"id\"]}: {i[\"attributes\"][\"name\"]}')"
    echo "Flows:"
    api_get "flows" | parse_json "
import sys,json;d=json.loads(sys.stdin.read())
for i in d.get('data',[]): print(f'  {i[\"id\"]}: {i[\"attributes\"][\"name\"]} ({i[\"attributes\"].get(\"status\",\"?\")})')"
    echo "Templates:"
    api_get "templates" | parse_json "
import sys,json;d=json.loads(sys.stdin.read());print(f'  {len(d.get(\"data\",[]))} templates')"
    ;;

  lists)
    api_get "lists" | parse_json "
import sys,json;d=json.loads(sys.stdin.read())
for i in d.get('data',[]): print(f'{i[\"id\"]}  {i[\"attributes\"][\"name\"]}')"
    ;;

  list-create)
    local name="${2:?Usage: klaviyo.sh list-create <name>}"
    tmp=$(mktemp)
    echo "{\"data\":{\"type\":\"list\",\"attributes\":{\"name\":\"$name\"}}}" > "$tmp"
    api_post "lists" "$tmp" | parse_json "
import sys,json;d=json.loads(sys.stdin.read())
if 'data' in d: print(f'Created: {d[\"data\"][\"id\"]} — {d[\"data\"][\"attributes\"][\"name\"]}')
else: print(f'Error: {d.get(\"errors\",[{}])[0].get(\"detail\",\"?\")}')"
    rm -f "$tmp"
    ;;

  templates)
    api_get "templates" | parse_json "
import sys,json;d=json.loads(sys.stdin.read())
for i in d.get('data',[]): print(f'{i[\"id\"]}  {i[\"attributes\"][\"name\"]}')"
    ;;

  flows)
    api_get "flows" | parse_json "
import sys,json;d=json.loads(sys.stdin.read())
for i in d.get('data',[]): print(f'{i[\"id\"]}  {i[\"attributes\"][\"name\"]}  [{i[\"attributes\"].get(\"status\",\"?\")}]')"
    ;;

  metrics)
    api_get "metrics" | parse_json "
import sys,json;d=json.loads(sys.stdin.read())
for m in d.get('data',[]): print(f'{m[\"id\"]}  {m[\"attributes\"][\"name\"]}')"
    ;;

  flow-create)
    shift
    local name="${1:?}" trigger_id="${2:?}" template_id="${3:?}"
    local msg=$(msg_block "$name email" "$name" "$template_id")
    tmp=$(mktemp)
    cat > "$tmp" << PEOF
{"data":{"type":"flow","attributes":{"name":"$name","definition":{"triggers":[{"type":"metric","id":"$trigger_id"}],"profile_filter":null,"entry_action_id":"a1","actions":[{"temporary_id":"a1","type":"send-email","links":{"next":null},"data":{"message":$msg,"status":"draft"}}]}}}}
PEOF
    api_post "flows" "$tmp" | parse_json "
import sys,json;d=json.loads(sys.stdin.read())
if 'data' in d: print(f'Created flow: {d[\"data\"][\"id\"]} — {d[\"data\"][\"attributes\"][\"name\"]}')
else: [print(f'Error: {e.get(\"detail\",\"\")}') for e in d.get('errors',[])]"
    rm -f "$tmp"
    ;;

  subscribe)
    local list_id="${2:?}" email="${3:?}" name="${4:-}"
    tmp=$(mktemp)
    "$P3" -c "
import json
data = {'data':{'type':'profile-subscription-bulk-create-job','attributes':{'profiles':{'data':[{'type':'profile','attributes':{'email':'$email','first_name':'$name'}}]},'historical_import':False},'relationships':{'list':{'data':{'type':'list','id':'$list_id'}}}}}
print(json.dumps(data))" > "$tmp"
    api_post "profile-subscription-bulk-create-jobs" "$tmp" | parse_json "
import sys,json;d=json.loads(sys.stdin.read())
if 'data' in d: print(f'Subscribed {\"$email\"} to list {\"$list_id\"}')
else: print(f'Error: {d.get(\"errors\",[{}])[0].get(\"detail\",\"?\")}')"
    rm -f "$tmp"
    ;;

  help|--help|-h|*)
    echo "Klaviyo Engine — Full email marketing CLI"
    echo ""
    echo "Usage: klaviyo.sh <command> [args]"
    echo ""
    echo "Setup:"
    echo "  setup <api_key>              Save API key"
    echo ""
    echo "Read:"
    echo "  status                       Account overview"
    echo "  lists                        List all lists"
    echo "  templates                    List all templates"
    echo "  flows                        List all flows"
    echo "  metrics                      List all metrics"
    echo ""
    echo "Create:"
    echo "  list-create <name>           Create a list"
    echo "  flow-create <name> <trigger_metric_id> <template_id>"
    echo "  subscribe <list_id> <email> [name]"
    ;;
esac
