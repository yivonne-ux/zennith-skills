#!/bin/bash
#
# Shopify Webhook Handler for Psychic Readings
# Captures order data (name, DOB, questions) and triggers reading generation
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.openclaw/logs/shopify-webhook-handler.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] $1" | tee -a "$LOG_FILE"
}

# Parse incoming webhook data
parse_webhook() {
    local payload_file="$1"

    if [ ! -f "$payload_file" ]; then
        log "❌ Payload file not found: $payload_file" "$RED"
        return 1
    fi

    # Extract customer data using Python
    python3 <<'PYTHON_SCRIPT'
import json
import sys

# Read payload from file
with open('/dev/stdin', 'r') as f:
    payload = json.load(f)

# Shopify webhook types we care about
webhook_type = payload.get('webhook_subscription_id')

if not webhook_type:
    print(json.dumps({"error": "No webhook type detected"}))
    sys.exit(0)

# Extract order data
customer = payload.get('customer', {})
line_items = payload.get('line_items', [])

# Map order to reading parameters
reading_data = {
    "webhook_type": webhook_type,
    "order_id": payload.get('id'),
    "order_number": payload.get('order_number'),
    "customer": {
        "email": customer.get('email'),
        "first_name": customer.get('first_name', ''),
        "last_name": customer.get('last_name', ''),
        "name": customer.get('name', ''),
        "phone": customer.get('phone')
    },
    "shipping_address": payload.get('shipping_address', {}),
    "billing_address": payload.get('billing_address', {}),
    "line_items": line_items,
    "created_at": payload.get('created_at')
}

print(json.dumps(reading_data))
PYTHON_SCRIPT
}

# Check if order is a reading product
is_reading_product() {
    local line_items_json="$1"

    # Check if any line item contains reading-related keywords
    echo "$line_items_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
line_items = data.get('line_items', [])

# Define keywords that indicate a reading product
reading_keywords = ['reading', 'tarot', 'astrology', 'qmdj', 'psychic', 'divination']

for item in line_items:
    name = item.get('name', '').lower()
    product_type = item.get('product_type', '').lower()
    vendor = item.get('vendor', '').lower()

    # Check if any keyword is present
    for keyword in reading_keywords:
        if keyword in name or keyword in product_type or keyword in vendor:
            print('true')
            sys.exit(0)

print('false')
" 2>/dev/null || echo "false"
}

# Extract order questions from custom fields or notes
extract_questions() {
    local payload_file="$1"

    # Read full payload and extract questions from custom properties
    python3 <<'PYTHON_SCRIPT'
import json
import sys

with open('/dev/stdin', 'r') as f:
    payload = json.load(f)

customer_note = payload.get('customer', {}).get('note', '')
custom_properties = payload.get('line_items', [{}])[0].get('properties', [])

questions = []

# Check customer note
if customer_note and any(keyword in customer_note.lower() for keyword in ['what', 'how', 'why', 'when', 'who']):
    questions.append(customer_note)

# Check custom properties
for prop in custom_properties:
    if prop.get('key', '').lower() == 'question' or prop.get('key', '').lower() == 'main_question':
        questions.append(prop.get('value', ''))
    elif prop.get('key', '').lower() in ['question', 'reading_question']:
        questions.append(prop.get('value', ''))

# Clean up questions
questions = [q.strip() for q in questions if q and len(q) > 5]

if questions:
    print(json.dumps({"questions": questions}))
else:
    print(json.dumps({"questions": ["general reading", "guidance needed"]}))
PYTHON_SCRIPT
}

# Main handler
handle_reading_order() {
    local payload_file="$1"
    local output_dir="$2"

    log "📥 Receiving Shopify webhook" "$BLUE"
    log "Order ID: $(basename "$payload_file" .json)" "$BLUE"

    # Parse webhook data
    local order_data=$(parse_webhook "$payload_file")
    local order_json=$(echo "$order_data" | python3 -c "import json, sys; print(json.dumps(json.load(sys.stdin)))" 2>/dev/null)

    # Check if this is a reading product
    local is_reading=$(echo "$order_json" | python3 -c "import json, sys; data = json.load(sys.stdin); print(json.dumps({'is_reading': 'true' if data['webhook_type'].find('orders') != -1 else 'false'}))")

    if [ "$is_reading" == "false" ]; then
        log "ℹ️  Not a reading order (webhook type: $webhook_type)" "$YELLOW"
        return 0
    fi

    log "✅ Reading order detected" "$GREEN"

    # Extract customer info
    local customer_name=$(echo "$order_json" | python3 -c "import json, sys; data = json.load(sys.stdin); print(data['customer']['name'])" 2>/dev/null || echo "Customer")
    local customer_email=$(echo "$order_json" | python3 -c "import json, sys; data = json.load(sys.stdin); print(data['customer']['email'])" 2>/dev/null || echo "not provided")

    log "Customer: $customer_name" "$GREEN"
    log "Email: $customer_email" "$GREEN"

    # Extract birth date (from customer note or custom property)
    local birth_date=$(echo "$order_json" | python3 -c "
import json
import re
import sys

data = json.load(sys.stdin)
note = data['customer'].get('note', '').lower()
props = data['line_items'][0].get('properties', [])

# Look for date patterns in format YYYY-MM-DD
date_pattern = r'(\d{4}-\d{2}-\d{2})'
dates = re.findall(date_pattern, note)

if dates:
    print(dates[0])
else:
    for prop in props:
        key = prop.get('key', '').lower()
        value = prop.get('value', '')
        if 'birth' in key or 'dob' in key:
            print(value)
" 2>/dev/null || echo "")

    # If no date found, set default for testing
    if [ -z "$birth_date" ]; then
        birth_date="2000-01-15"  # Default test date
        log "⚠️  No birth date found, using default" "$YELLOW"
    fi

    log "Birth date: $birth_date" "$GREEN"

    # Extract question
    local questions_json=$(extract_questions "$payload_file")
    local question=$(echo "$questions_json" | python3 -c "import json, sys; data = json.load(sys.stdin); print(data['questions'][0] if data['questions'] else 'general')" 2>/dev/null || echo "general guidance")

    log "Question: $question" "$GREEN"

    # For testing, extract location from address
    local city=$(echo "$order_json" | python3 -c "import json, sys; data = json.load(sys.stdin); print(data['shipping_address'].get('city', ''))" 2>/dev/null || echo "")

    # Create output file
    local reading_id=$(date +%Y%m%d-%H%M%S)
    local reading_file="${output_dir}/reading-${reading_id}.json"
    local input_payload="${output_dir}/order-${reading_id}.json"

    # Save input order
    cp "$payload_file" "$input_payload"

    # Create reading parameters
    local reading_params="$output_dir/params-${reading_id}.sh"
    cat > "$reading_params" <<PARAM_EOF
#!/bin/bash
NAME="$customer_name"
DATE="$birth_date"
TIME="14:30"  # Default time for testing
LAT="3.1390"
LON="101.6869"  # Kuala Lumpur default
TZ="Asia/Kuala_Lumpur"
QUESTION="$question"
MODE="destiny"
PARAM_EOF

    chmod +x "$reading_params"

    log "Created reading parameters: $reading_id" "$GREEN"
    log "Output file: $reading_file" "$GREEN"

    # Trigger the reading
    local result
    result=$(bash "$SCRIPT_DIR/../scripts/psychic-reading.sh" \
        --name "$customer_name" \
        --date "$birth_date" \
        --time "14:30" \
        --lat 3.1390 \
        --lon 101.6869 \
        --tz "Asia/Kuala_Lumpur" \
        --spread celtic-cross \
        --question "$question" \
        --output json 2>&1)

    # Save raw result
    echo "$result" > "$reading_file"

    log "✅ Reading generated for: $customer_name" "$GREEN"

    # Return metadata
    cat <<EOF
{
  "reading_id": "${reading_id}",
  "order_id": "$(basename "$payload_file" .json)",
  "customer": "${customer_name}",
  "email": "${customer_email}",
  "birth_date": "${birth_date}",
  "question": "${question}",
  "reading_file": "${reading_file}",
  "input_payload": "${input_payload}",
  "status": "completed"
}
EOF
}

# Test webhook handler
test_handler() {
    local test_payload="$SCRIPT_DIR/test-order.json"

    log "🧪 Testing webhook handler with sample data" "$BLUE"

    # Create sample order payload
    cat > "$test_payload" <<EOF
{
  "id": 123456789,
  "order_number": 10001,
  "email": "customer@example.com",
  "customer": {
    "email": "customer@example.com",
    "first_name": "Alice",
    "last_name": "Chen",
    "name": "Alice Chen",
    "note": "Birth date: 1995-08-20. Question: What does the future hold for my career?",
    "phone": "+60123456789"
  },
  "line_items": [
    {
      "name": "QMDJ Session - Career Guidance",
      "product_type": "reading",
      "vendor": "gaia-psychic",
      "properties": [
        {"key": "question", "value": "What does the future hold for my career?"}
      ]
    }
  ],
  "shipping_address": {
    "first_name": "Alice",
    "last_name": "Chen",
    "address1": "123 Main St",
    "city": "Kuala Lumpur",
    "state": "Wilayah Persekutuan",
    "zip": "50000",
    "country": "MY",
    "phone": "+60123456789"
  },
  "billing_address": {
    "first_name": "Alice",
    "last_name": "Chen",
    "address1": "123 Main St",
    "city": "Kuala Lumpur",
    "state": "Wilayah Persekutuan",
    "zip": "50000",
    "country": "MY",
    "phone": "+60123456789"
  },
  "created_at": "2026-03-09T10:30:00+08:00"
}
EOF

    local output_dir="$SCRIPT_DIR/../data/readings"
    mkdir -p "$output_dir"

    handle_reading_order "$test_payload" "$output_dir"
}

# Listen mode (for development)
listen_mode() {
    local port="${1:-3000}"

    log "🎧 Listening on port $port for Shopify webhooks..." "$BLUE"
    log "Use ngrok to expose: ngrok http $port" "$YELLOW"

    # Simple HTTP server to receive webhooks
    python3 -m http.server "$port" &
    local server_pid=$!

    log "Server started (PID: $server_pid). Press Ctrl+C to stop." "$GREEN"

    # Keep server running
    wait $server_pid
}

# ============================================
# MAIN
# ============================================

main() {
    case "${1:-help}" in
        test)
            test_handler
            ;;
        listen)
            listen_mode "${2:-3000}"
            ;;
        handle)
            handle_reading_order "${2:-}" "${3:-}"
            ;;
        *)
            cat <<EOF
Shopify Webhook Handler for Psychic Readings

Usage: $0 <command> [options]

Commands:
  test           Run test with sample order data
  listen [port]  Start HTTP server to receive webhooks (dev mode)
  handle file    Handle specific webhook file

Example:
  $0 test
  $0 listen 3000
  $0 handle /tmp/order.json

Setup:
1. Shopify webhook: https://shopify.dev/docs/webhooks/guides/manual-webhooks
2. ngrok to expose: ngrok http 3000
3. Enter ngrok URL in Shopify admin

EOF
            ;;
    esac
}

main "$@"