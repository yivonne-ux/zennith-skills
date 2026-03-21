#!/usr/bin/env bash
# Ensure Pinchtab is running with Shopify-ready Chrome profile
set -euo pipefail

PORT="${BRIDGE_PORT:-9867}"
PROFILE="${BRIDGE_PROFILE:-$HOME/.chrome-cdp}"

if curl -s "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
    echo "Pinchtab already running on :${PORT}"
    exit 0
fi

echo "Starting Pinchtab (headed, port ${PORT}, profile ${PROFILE})..."
mkdir -p "${PROFILE}"

BRIDGE_HEADLESS=false \
BRIDGE_PROFILE="${PROFILE}" \
BRIDGE_PORT="${PORT}" \
BRIDGE_BIND=127.0.0.1 \
pinchtab &

# Wait for ready
for i in $(seq 1 30); do
    if curl -s "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
        echo "Pinchtab ready on :${PORT}"
        exit 0
    fi
    sleep 1
done

echo "ERROR: Pinchtab failed to start"
exit 1
