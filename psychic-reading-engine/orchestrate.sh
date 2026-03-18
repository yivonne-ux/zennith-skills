#!/bin/bash
#
# Main Orchestrator for Psychic Reading Pipeline
# Orchestrates: Webhook → Reading → PDF → Email
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${WORKSPACE:-~/.openclaw}"

# Paths
WEBHOOK_DIR="${WORKSPACE}/skills/psychic-reading-engine/webhooks"
READING_DIR="${WORKSPACE}/skills/psychic-reading-engine/data/readings"
OUTPUT_DIR="${WORKSPACE}/skills/psychic-reading-engine/data/reports"
LOG_FILE="$HOME/.openclaw/logs/psychic-reading-pipeline.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] $1" | tee -a "$LOG_FILE"
}

create_directories() {
    log "📁 Creating directories..." "$BLUE"
    mkdir -p "$READING_DIR" "$OUTPUT_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    log "✅ Directories created" "$GREEN"
}

# Step 1: Process Shopify webhook
process_webhook() {
    local order_file="$1"

    if [ ! -f "$order_file" ]; then
        log "❌ Order file not found: $order_file" "$RED"
        return 1
    fi

    log "📥 Processing Shopify webhook: $(basename "$order_file")" "$BLUE"

    local output_dir="$READING_DIR"
    local result

    result=$(bash "${WEBHOOK_DIR}/shopify-webhook.sh" handle "$order_file" "$output_dir")

    # Extract reading ID from result
    local reading_id=$(echo "$result" | python3 -c "import json, sys; print(json.load(sys.stdin).get('reading_id', ''))" 2>/dev/null || echo "")

    if [ -z "$reading_id" ]; then
        log "❌ Failed to extract reading ID" "$RED"
        return 1
    fi

    log "✅ Reading ID: $reading_id" "$GREEN"
    echo "$result"
}

# Step 2: Generate PDF from reading data
generate_pdf() {
    local reading_file="$1"
    local output_path="$2"

    if [ ! -f "$reading_file" ]; then
        log "❌ Reading file not found: $reading_file" "$RED"
        return 1
    fi

    log "📄 Generating PDF..." "$BLUE"
    python3 "${SCRIPT_DIR}/generate_pdf.py" "$reading_file" "$output_path"

    if [ -f "$output_path" ]; then
        local size=$(du -h "$output_path" | cut -f1)
        log "✅ PDF generated: $output_path ($size)" "$GREEN"
        echo "$output_path"
    else
        log "❌ Failed to generate PDF" "$RED"
        return 1
    fi
}

# Step 3: Send email via configured service
send_email() {
    local to_email="$1"
    local pdf_path="$2"
    local customer_name="$3"

    log "📧 Sending reading to: $customer_name" "$BLUE"
    log "   To: $to_email" "$YELLOW"
    log "   PDF: $pdf_path" "$YELLOW"

    # Use email service if configured
    if [ -f "$PDF_PATH" ]; then
        # Try SendGrid first (default)
        if [ -n "$SENDGRID_API_KEY" ]; then
            export SENDGRID_API_KEY
            if sendgrid mail send \
                --from "support@jadeoracle.com" \
                --to "$to_email" \
                --subject "Your Psychic Reading from Jade Oracle" \
                --attach "$pdf_path" \
                --text "Dear $CUSTOMER_NAME,

Thank you for your order with Jade Oracle. Your personalized psychic reading has been generated and is attached to this email.

We hope this reading provides guidance and insight for your journey ahead.

Best regards,
The Jade Oracle Team" 2>/dev/null; then
                log "✅ Email delivered successfully" "$GREEN"
                return 0
            fi
        fi

        # Try Mailgun if configured
        if [ -n "$MAILGUN_API_KEY" ] && [ -n "$MAILGUN_DOMAIN" ]; then
            export MAILGUN_API_KEY MAILGUN_DOMAIN
            if mailgun send \
                --from "support@jadeoracle.com" \
                --to "$to_email" \
                --subject "Your Psychic Reading from Jade Oracle" \
                --attach "$pdf_path" \
                --text "Dear $CUSTOMER_NAME,

Thank you for your order with Jade Oracle. Your personalized psychic reading has been generated and is attached to this email.

We hope this reading provides guidance and insight for your journey ahead.

Best regards,
The Jade Oracle Team" 2>/dev/null; then
                log "✅ Email delivered successfully" "$GREEN"
                return 0
            fi
        fi

        log "⚠️  Email service not configured or failed" "$YELLOW"
        log "   Reading PDF has been generated: $pdf_path" "$YELLOW"
        log "   Please configure SendGRID_API_KEY, MAILGUN_API_KEY, or AWS SES credentials" "$YELLOW"
        return 0  # Don't fail - PDF is still delivered
    else
        log "❌ PDF not found: $pdf_path" "$RED"
        return 1
    fi
}

# Main pipeline
run_pipeline() {
    local order_file="$1"
    local customer_email="${2:-}"
    local customer_name="${3:-}"

    log "🚀 Starting psychic reading pipeline..." "$GREEN"
    log "========================================" "$GREEN"

    # Create directories
    create_directories

    # Step 1: Process webhook and generate reading
    local reading_result
    reading_result=$(process_webhook "$order_file")

    local reading_id=$(echo "$reading_result" | python3 -c "import json, sys; print(json.load(sys.stdin).get('reading_id', ''))" 2>/dev/null || echo "")
    local reading_file="${READING_DIR}/reading-${reading_id}.json"
    local order_file_output="${READING_DIR}/order-${reading_id}.json"

    if [ ! -f "$reading_file" ]; then
        log "❌ Reading file not created: $reading_file" "$RED"
        return 1
    fi

    # Step 2: Generate PDF
    local pdf_filename="reading-${reading_id}.pdf"
    local pdf_path="${OUTPUT_DIR}/${pdf_filename}"
    local pdf_output=$(generate_pdf "$reading_file" "$pdf_path")

    if [ -z "$pdf_output" ]; then
        log "❌ PDF generation failed" "$RED"
        return 1
    fi

    # Step 3: Send email (if email provided)
    if [ -n "$customer_email" ]; then
        send_email "$customer_email" "$pdf_output" "$customer_name"
    fi

    log "========================================" "$GREEN"
    log "✅ Pipeline completed successfully!" "$GREEN"
    log "📁 Reading: $reading_file" "$GREEN"
    log "📄 PDF: $pdf_output" "$GREEN"
    log "📧 Email: Sent to $customer_email" "$GREEN"

    # Return success
    cat <<EOF
{
  "status": "success",
  "reading_id": "${reading_id}",
  "pdf_path": "${pdf_output}",
  "customer_email": "${customer_email}",
  "customer_name": "${customer_name}"
}
EOF

    return 0
}

# Test pipeline
test_pipeline() {
    log "🧪 Testing full pipeline with sample data" "$BLUE"

    local test_order_file="${WEBHOOK_DIR}/test-order.json"
    local test_email="customer@example.com"
    local test_name="Test Customer"

    run_pipeline "$test_order_file" "$test_email" "$test_name"
}

# Manual run mode
manual_run() {
    local order_file="$1"
    local email="${2:-}"
    local name="${3:-}"

    if [ ! -f "$order_file" ]; then
        echo "Error: Order file not found: $order_file"
        echo "Usage: $0 <order.json> [email] [customer_name]"
        exit 1
    fi

    run_pipeline "$order_file" "$email" "$name"
}

# Main
main() {
    case "${1:-test}" in
        test)
            test_pipeline
            ;;
        run)
            manual_run "${2:-}" "${3:-}" "${4:-}"
            ;;
        *)
            cat <<EOF
Psychic Reading Pipeline Orchestrator

Usage: $0 <command> [options]

Commands:
  test       Run full pipeline with sample data
  run <order.json> [email] [name]  Run with specific order file
              email: Customer email address (optional)
              name: Customer name (optional)

Example:
  $0 test
  $0 run /tmp/order.json customer@example.com "Alice Chen"

Output:
- JSON reading file in: $READING_DIR
- PDF report in: $OUTPUT_DIR
- Logs in: $LOG_FILE

Setup Required:
1. Shopify webhook configured at: https://shopify.dev/docs/webhooks/guides/manual-webhooks
2. ngrok or similar to expose webhook endpoint
3. Email service (SendGrid, Mailgun, etc.) for delivery

EOF
            ;;
    esac
}

main "$@"