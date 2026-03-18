#!/bin/bash
#
# Shopify Order → Reading Pipeline → PDF → Email
# The money pipeline for The Jade Oracle
#
# Called by the webhook server when a Shopify order comes in.
# Usage: order-handler.sh <order.json>
#
# Flow:
#   1. Parse order JSON (customer email, name, product, birth data from order notes)
#   2. Determine reading type from product
#   3. Run psychic-reading.sh
#   4. Generate PDF
#   5. Email PDF to customer
#   6. Log to rooms/orders.jsonl
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE_DIR="$(dirname "$SCRIPT_DIR")"  # points to scripts/ dir
READINGS_DIR="/Users/jennwoeiloh/.openclaw/workspace/data/readings"
ROOM_FILE="/Users/jennwoeiloh/.openclaw/workspace/rooms/orders.jsonl"

mkdir -p "$READINGS_DIR"

# --- Parse order JSON ---
ORDER_FILE="$1"
if [ ! -f "$ORDER_FILE" ]; then
    echo "❌ Order file not found: $ORDER_FILE"
    exit 1
fi

# Extract fields
CUSTOMER_EMAIL=$(python3 -c "import json,sys; d=json.load(open('$ORDER_FILE')); print(d.get('email','') or d.get('customer',{}).get('email',''))")
CUSTOMER_NAME=$(python3 -c "import json,sys; d=json.load(open('$ORDER_FILE')); c=d.get('customer',{}); print(f\"{c.get('first_name','')} {c.get('last_name','')}\".strip() or d.get('billing_address',{}).get('name','Customer'))")
ORDER_ID=$(python3 -c "import json,sys; d=json.load(open('$ORDER_FILE')); print(d.get('id','unknown'))")
ORDER_NUMBER=$(python3 -c "import json,sys; d=json.load(open('$ORDER_FILE')); print(d.get('order_number',''))")

# Extract product/reading type from line items
READING_TYPE=$(python3 -c "
import json, sys
d = json.load(open('$ORDER_FILE'))
items = d.get('line_items', [])
# Map product titles to reading types
type_map = {
    'intro': 'quick',
    '\$1': 'quick',
    'love': 'love',
    'career': 'career',
    'destiny': 'full',
    'full': 'full',
    'mentorship': 'full',
}
for item in items:
    title = (item.get('title','') + ' ' + item.get('variant_title','')).lower()
    for key, val in type_map.items():
        if key in title:
            print(val)
            sys.exit(0)
print('quick')  # default to quick/intro reading
")

# Extract birth data from order note attributes (customer fills in at checkout)
BIRTH_DATA=$(python3 -c "
import json, sys
d = json.load(open('$ORDER_FILE'))
attrs = d.get('note_attributes', [])
note = d.get('note', '')
birth = {}
for a in attrs:
    name = a.get('name','').lower()
    val = a.get('value','')
    if 'birth' in name and 'date' in name: birth['date'] = val
    elif 'birth' in name and 'time' in name: birth['time'] = val
    elif 'birth' in name and ('place' in name or 'city' in name or 'location' in name): birth['place'] = val
    elif 'question' in name: birth['question'] = val
# Fallback: parse from note field
if not birth.get('date') and note:
    import re
    date_match = re.search(r'(\d{4}-\d{2}-\d{2})', note)
    if date_match: birth['date'] = date_match.group(1)
print(json.dumps(birth))
")

BIRTH_DATE=$(echo "$BIRTH_DATA" | python3 -c "import json,sys; print(json.load(sys.stdin).get('date','1990-01-01'))")
BIRTH_TIME=$(echo "$BIRTH_DATA" | python3 -c "import json,sys; print(json.load(sys.stdin).get('time','12:00'))")
BIRTH_PLACE=$(echo "$BIRTH_DATA" | python3 -c "import json,sys; print(json.load(sys.stdin).get('place','New York'))")
QUESTION=$(echo "$BIRTH_DATA" | python3 -c "import json,sys; print(json.load(sys.stdin).get('question',''))")

echo "📋 Order #$ORDER_NUMBER ($ORDER_ID)"
echo "   Customer: $CUSTOMER_NAME <$CUSTOMER_EMAIL>"
echo "   Reading type: $READING_TYPE"
echo "   Birth: $BIRTH_DATE $BIRTH_TIME @ $BIRTH_PLACE"
echo "   Question: ${QUESTION:-none}"

# --- Generate reading ---
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
READING_DIR="$READINGS_DIR/order-${ORDER_NUMBER:-$ORDER_ID}-$TIMESTAMP"
mkdir -p "$READING_DIR"

echo "🔮 Generating reading..."

# Determine tarot spread based on reading type
case "$READING_TYPE" in
    quick)  SPREAD="3-card"; QUESTION="general" ;;
    love)   SPREAD="relationship"; QUESTION="love" ;;
    career) SPREAD="career"; QUESTION="career" ;;
    full)   SPREAD="celtic-cross"; QUESTION="general" ;;
esac

# Run the reading pipeline
# Convert place to approximate coordinates (default: KL if unknown)
COORDS=$(python3 -c "
places = {
    'kuala lumpur': (3.139, 101.687), 'kl': (3.139, 101.687),
    'singapore': (1.352, 103.820), 'sg': (1.352, 103.820),
    'penang': (5.416, 100.333), 'george town': (5.416, 100.333),
    'johor bahru': (1.492, 103.741), 'jb': (1.492, 103.741),
    'new york': (40.713, -74.006), 'ny': (40.713, -74.006),
    'london': (51.507, -0.128), 'los angeles': (34.052, -118.244),
    'tokyo': (35.682, 139.692), 'hong kong': (22.320, 114.169),
    'jakarta': (6.175, 106.827), 'bangkok': (13.756, 100.502),
    'sydney': (-33.869, 151.209), 'melbourne': (-37.814, 144.963),
    'taipei': (25.033, 121.565), 'seoul': (37.567, 126.978),
}
place = '$BIRTH_PLACE'.lower().strip()
lat, lon = places.get(place, (3.139, 101.687))
print(f'{lat} {lon}')
")
LAT=$(echo "$COORDS" | cut -d' ' -f1)
LON=$(echo "$COORDS" | cut -d' ' -f2)

bash "$ENGINE_DIR/psychic-reading.sh" \
    --name "$CUSTOMER_NAME" \
    --date "$BIRTH_DATE" \
    --time "$BIRTH_TIME" \
    --lat "$LAT" --lon "$LON" \
    --tz "UTC" \
    --spread "$SPREAD" \
    --question "$QUESTION" \
    --output json \
    > "$READING_DIR/reading.json" \
    2> "$READING_DIR/pipeline.log"

if [ ! -f "$READING_DIR/reading.json" ]; then
    echo "❌ Reading generation failed"
    # Log failure
    echo "{\"ts\":$(date +%s)000,\"order_id\":\"$ORDER_ID\",\"order_number\":\"$ORDER_NUMBER\",\"email\":\"$CUSTOMER_EMAIL\",\"status\":\"failed\",\"error\":\"reading generation failed\"}" >> "$ROOM_FILE"
    exit 1
fi

echo "✅ Reading generated"

# --- Generate PDF ---
echo "📄 Generating PDF..."

PDF_PATH="$READING_DIR/reading.pdf"
python3 "$ENGINE_DIR/generate_pdf.py" "$READING_DIR/reading.json" "$PDF_PATH"

if [ ! -f "$PDF_PATH" ]; then
    echo "❌ PDF generation failed"
    echo "{\"ts\":$(date +%s)000,\"order_id\":\"$ORDER_ID\",\"order_number\":\"$ORDER_NUMBER\",\"email\":\"$CUSTOMER_EMAIL\",\"status\":\"failed\",\"error\":\"pdf generation failed\"}" >> "$ROOM_FILE"
    exit 1
fi

echo "✅ PDF generated: $PDF_PATH"

# --- Send email ---
echo "📧 Sending email to $CUSTOMER_EMAIL..."

# Send email via Klaviyo (primary) or SMTP (fallback)
READING_TITLE=$(echo "$READING_TYPE" | python3 -c "import sys; print(sys.stdin.read().strip().title())")
if python3 "$ENGINE_DIR/send-email-klaviyo.py" \
    --to "$CUSTOMER_EMAIL" \
    --name "$CUSTOMER_NAME" \
    --pdf "$PDF_PATH" \
    --reading-type "$READING_TITLE" \
    --subject "Your $READING_TITLE Reading from The Jade Oracle" \
    --provider auto 2>&1; then
    echo "✅ Email sent"
else
    echo "⚠️  Email delivery failed. PDF ready at: $PDF_PATH"
fi

# --- Log success ---
echo "{\"ts\":$(date +%s)000,\"order_id\":\"$ORDER_ID\",\"order_number\":\"$ORDER_NUMBER\",\"email\":\"$CUSTOMER_EMAIL\",\"name\":\"$CUSTOMER_NAME\",\"reading_type\":\"$READING_TYPE\",\"status\":\"delivered\",\"pdf\":\"$PDF_PATH\"}" >> "$ROOM_FILE"

echo "🎉 Order #$ORDER_NUMBER complete — reading delivered to $CUSTOMER_EMAIL"
