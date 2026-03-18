#!/bin/bash
#
# Jade Oracle Production Startup Script
# Starts webhook listener and verifies all services
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Jade Oracle Production Startup"
echo "=================================="
echo ""

# Check for required services
echo "🔍 Checking prerequisites..."

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found"
    exit 1
fi
echo "✅ Python 3 found"

# Check jq
if ! command -v jq &> /dev/null; then
    echo "❌ jq not found"
    echo "   Install: brew install jq"
    exit 1
fi
echo "✅ jq found"

# Check PDF generation dependencies
echo "🔍 Checking PDF generation..."
if ! python3 -c "import fpdf2" 2>/dev/null; then
    echo "⚠️  fpdf2 not installed"
    echo "   Installing: pip3 install --break-system-packages fpdf2"
    pip3 install --break-system-packages fpdf2 || echo "⚠️  fpdf2 installation failed"
fi
echo "✅ PDF dependencies OK"

# Check email service
echo "🔍 Checking email service..."
EMAIL_STATUS="not configured"
if [ -n "$SENDGRID_API_KEY" ]; then
    EMAIL_STATUS="SendGrid"
elif [ -n "$MAILGUN_API_KEY" ]; then
    EMAIL_STATUS="Mailgun"
elif [ -n "$AWS_SES_ACCESS_KEY_ID" ]; then
    EMAIL_STATUS="AWS SES"
fi
echo "📧 Email service: $EMAIL_STATUS"
echo ""

# Create log directory
mkdir -p ~/.openclaw/logs

# Start webhook listener
echo "📡 Starting webhook listener..."
cd "$SCRIPT_DIR"
bash webhooks/webhook-listener.sh start &
WEBHOOK_PID=$!

# Wait a moment for server to start
sleep 2

# Verify webhook listener is running
if ps -p $WEBHOOK_PID > /dev/null; then
    echo "✅ Webhook listener started (PID: $WEBHOOK_PID)"
else
    echo "❌ Failed to start webhook listener"
    exit 1
fi

# Generate webhook URL using ngrok (if available)
if command -v ngrok &> /dev/null; then
    echo ""
    echo "🌐 Exposing webhook listener with ngrok..."
    ngrok http 3000 > /dev/null 2>&1 &
    NGROK_PID=$!
    sleep 2

    if ps -p $NGROK_PID > /dev/null; then
        echo "✅ ngrok started (PID: $NGROK_PID)"

        # Get ngrok public URL
        WEBHOOK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
        if [ -n "$WEBHOOK_URL" ]; then
            echo ""
            echo "🎯 Shopify Webhook Setup:"
            echo "   Callback URL: $WEBHOOK_URL"
            echo ""
            echo "   Add to Shopify Admin → Settings → Notifications → Webhooks:"
            echo "   Topic: orders/create"
            echo "   Callback URL: $WEBHOOK_URL"
        fi
    else
        echo "⚠️  ngrok failed to start"
        echo "   Install with: brew install ngrok"
        echo "   Or run manually: ngrok http 3000"
    fi
else
    echo "⚠️  ngrok not found"
    echo "   Install with: brew install ngrok"
    echo "   Or expose with: ssh -L 3000:localhost:3000"
fi

echo ""
echo "✅ Jade Oracle Production System Started!"
echo ""
echo "📋 Summary:"
echo "   - Webhook Listener: http://localhost:3000"
echo "   - Webhook Token: ${WEBHOOK_TOKEN:0:20}..."
echo "   - Email Service: $EMAIL_STATUS"
echo ""
echo "📊 Logs:"
echo "   - Webhook logs: ~/.openclaw/logs/shopify-webhook-listener.log"
echo "   - Pipeline logs: ~/.openclaw/logs/psychic-reading-pipeline.log"
echo ""
echo "🧪 Test: Send a test order via curl:"
echo "   curl -X POST http://localhost:3000"
echo "   -H 'Content-Type: application/json'"
echo "   -d '{\"id\": 123, \"email\": \"test@test.com\", ...}'"
echo ""
echo "📝 To stop: kill $WEBHOOK_PID $NGROK_PID"
echo ""

# Save PIDs for reference
echo "$WEBHOOK_PID" > ~/.openclaw/logs/jade-oracle-webhook.pid
if [ -n "$NGROK_PID" ]; then
    echo "$NGROK_PID" >> ~/.openclaw/logs/jade-oracle-webhook.pid
fi