#!/bin/bash
#
# Production Webhook Listener for Shopify Orders
# Listens for Shopify webhook payloads and triggers reading generation
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${WORKSPACE:-~/.openclaw}"
ORCHESTRATOR="${WORKSPACE}/skills/psychic-reading-engine/orchestrate.sh"

# Configuration
WEBHOOK_PORT="${WEBHOOK_PORT:-3000}"
WEBHOOK_TOKEN="${WEBHOOK_TOKEN:-jade-oracle-secret-token}"
LOG_FILE="$HOME/.openclaw/logs/shopify-webhook-listener.log"

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

# Generate a secure webhook token if not set
if [ -z "$WEBHOOK_TOKEN" ] || [ "$WEBHOOK_TOKEN" = "jade-oracle-secret-token" ]; then
    WEBHOOK_TOKEN=$(openssl rand -base64 32)
    log "⚠️  Using auto-generated webhook token" "$YELLOW"
    log "   IMPORTANT: Set WEBHOOK_TOKEN env variable or update Shopify webhook to use this value" "$YELLOW"
    log "   Token: ${WEBHOOK_TOKEN:0:20}..." "$YELLOW"
fi

# Webhook handler endpoint
handle_webhook() {
    local webhook_token="$1"
    local request_method="$2"
    local content_type="$3"
    local payload_data="$4"

    # Verify webhook token
    if [ "$webhook_token" != "$WEBHOOK_TOKEN" ]; then
        log "❌ Invalid webhook token" "$RED"
        return 1
    fi

    # Parse webhook type and data
    if [ "$request_method" = "POST" ]; then
        # Read payload from stdin or parameter
        local order_file
        if [ -n "$payload_data" ]; then
            echo "$payload_data" | tee -a "$LOG_FILE"
            order_file=$(mktemp)
            echo "$payload_data" > "$order_file"
        else
            order_file=$(mktemp)
            cat > "$order_file"
        fi

        log "📥 Received Shopify webhook" "$BLUE"
        log "Order ID: $(jq -r '.id // .order_id // .webhook_subscription_id' "$order_file" 2>/dev/null || echo 'unknown')" "$BLUE"

        # Route to orchestrator
        if bash "$ORCHESTRATOR" run "$order_file"; then
            log "✅ Reading generated successfully" "$GREEN"
            
            # Cleanup
            rm -f "$order_file"
            
            # Send success response
            cat <<EOF
{
  "status": "success",
  "message": "Psychic reading generated and queued for email delivery",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
            return 0
        else
            log "❌ Failed to generate reading" "$RED"
            
            # Cleanup
            rm -f "$order_file"
            
            # Send error response
            cat <<EOF
{
  "status": "error",
  "message": "Failed to generate psychic reading",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
            return 1
        fi
    else
        log "❌ Invalid request method: $request_method" "$RED"
        cat <<EOF
{
  "status": "error",
  "message": "Method not allowed",
  "allowed_methods": ["POST"]
}
EOF
        return 1
    fi
}

# Simple HTTP server
start_server() {
    log "🚀 Starting webhook listener on port $WEBHOOK_PORT" "$GREEN"
    log "🎯 Shopify orders will trigger readings automatically" "$BLUE"
    log "📡 Webhook token: ${WEBHOOK_TOKEN:0:20}..." "$YELLOW"
    log "📝 Check $LOG_FILE for webhook logs" "$BLUE"
    log "" "$BLUE"

    # Create log directory
    mkdir -p "$(dirname "$LOG_FILE")"

    # Use Python's http.server for simplicity
    python3 <<PYTHON_SERVER_EOF
import http.server
import socketserver
import json
import os
import sys

# Add workspace to path
sys.path.insert(0, os.path.expanduser('$WORKSPACE'))
WEBHOOK_TOKEN = os.environ.get('WEBHOOK_TOKEN', 'jade-oracle-secret-token')
ORCHESTRATOR = os.environ.get('ORCHESTRATOR', '$ORCHESTRATOR')

class WebhookHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Suppress default logging
        pass
    
    def do_POST(self):
        # Read request body
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode('utf-8')
        
        # Get webhook token from header or body
        webhook_token = self.headers.get('X-Webhook-Token', '')
        if not webhook_token:
            try:
                payload = json.loads(body)
                webhook_token = payload.get('webhook_token', '')
            except:
                pass
        
        # Handle webhook
        try:
            # Import orchestrator
            from subprocess import run, PIPE
            result = run(
                ['bash', ORCHESTRATOR, 'run', '-'],
                input=body.encode('utf-8'),
                capture_output=True,
                text=True,
                timeout=300
            )
            
            # Send response
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(result.stdout.encode('utf-8') if result.stdout else result.stderr.encode('utf-8'))
            
        except Exception as e:
            # Send error response
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            error_response = json.dumps({
                "status": "error",
                "message": str(e),
                "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
            })
            self.wfile.write(error_response.encode('utf-8'))
    
    def do_GET(self):
        # Health check endpoint
        if self.path == '/health':
            response = json.dumps({
                "status": "healthy",
                "service": "jade-oracle-webhook",
                "port": $WEBHOOK_PORT,
                "webhook_token": "${WEBHOOK_TOKEN:0:20}...",
                "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
            })
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(response.encode('utf-8'))
        else:
            # Root endpoint
            response = json.dumps({
                "service": "Jade Oracle Webhook Listener",
                "status": "running",
                "endpoints": {
                    "webhook": "/webhook",
                    "health": "/health"
                },
                "webhook_token": "${WEBHOOK_TOKEN:0:20}...",
                "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
            })
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(response.encode('utf-8'))

# Start server
with socketserver.TCPServer(("0.0.0.0", $WEBHOOK_PORT), WebhookHandler) as httpd:
    print(f"✅ Webhook listener running on http://0.0.0.0:$WEBHOOK_PORT")
    print(f"🎯 Health check: http://0.0.0.0:$WEBHOOK_PORT/health")
    print(f"📝 Webhook endpoint: http://0.0.0.0:$WEBHOOK_PORT")
    print(f"🔑 Webhook token: ${WEBHOOK_TOKEN:0:20}...")
    print(f"📄 Check logs at: $LOG_FILE")
    httpd.serve_forever()
PYTHON_SERVER_EOF
}

# CLI mode - process single webhook
cli_mode() {
    local webhook_token="$1"
    
    # Read payload from stdin
    payload=$(cat -)
    
    # Handle webhook
    handle_webhook "$webhook_token" "POST" "application/json" "$payload"
}

# Main
main() {
    if [ "${1:-}" = "start" ]; then
        start_server
    elif [ "${1:-}" = "handle" ]; then
        cli_mode "${2:-}"
    else
        echo "Jade Oracle Webhook Listener"
        echo ""
        echo "Usage: $0 start|handle [webhook_token]"
        echo ""
        echo "Commands:"
        echo "  start          Start HTTP server (default port: 3000)"
        echo "  handle         Process webhook from stdin"
        echo ""
        echo "Environment:"
        echo "  WEBHOOK_PORT   HTTP server port (default: 3000)"
        echo "  WEBHOOK_TOKEN  Webhook security token (default: auto-generated)"
        echo ""
        echo "Shopify Integration:"
        echo "1. Start listener: $0 start"
        echo "2. Get webhook URL from ngrok: ngrok http $WEBHOOK_PORT"
        echo "3. Add webhook in Shopify admin → Notifications → Webhooks"
        echo "   Topic: orders/create"
        echo "   Callback URL: [your-ngrok-url]"
        echo ""
        exit 1
    fi
}

main "$@"