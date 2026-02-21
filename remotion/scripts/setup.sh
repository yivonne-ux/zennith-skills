#!/usr/bin/env bash
# MotionKit Setup — Install dependencies and verify Remotion works
# Usage: setup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../project" && pwd)"
LOG_DIR="$HOME/.openclaw/logs"
LOG_FILE="$LOG_DIR/motionkit.log"

mkdir -p "$LOG_DIR"

log() {
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] $1" | tee -a "$LOG_FILE"
}

error() {
  log "ERROR: $1"
  exit 1
}

# ── Check Node.js ──────────────────────────────────────────────────────────

log "Checking Node.js..."
if ! command -v node &>/dev/null; then
  error "Node.js not found. Install Node.js >= 18 (https://nodejs.org)"
fi

NODE_VERSION="$(node -v | sed 's/v//' | cut -d. -f1)"
if [ "$NODE_VERSION" -lt 18 ]; then
  error "Node.js >= 18 required. Found: $(node -v)"
fi
log "Node.js $(node -v) OK"

# ── Check npm ──────────────────────────────────────────────────────────────

if ! command -v npm &>/dev/null; then
  error "npm not found. Install npm."
fi
log "npm $(npm -v) OK"

# ── Install dependencies ──────────────────────────────────────────────────

log "Installing dependencies in $PROJECT_DIR..."
cd "$PROJECT_DIR"

if [ ! -f "package.json" ]; then
  error "package.json not found in $PROJECT_DIR"
fi

npm install 2>&1 | tee -a "$LOG_FILE"
log "Dependencies installed"

# ── Verify Remotion ───────────────────────────────────────────────────────

log "Verifying Remotion..."
REMOTION_VERSION="$(cd "$PROJECT_DIR" && npx remotion --version 2>/dev/null)" || true
if [ -z "$REMOTION_VERSION" ]; then
  error "Remotion CLI not working. Check npm install output above."
fi
log "Remotion $REMOTION_VERSION OK"

# ── Done ──────────────────────────────────────────────────────────────────

log "MotionKit setup complete!"
echo ""
echo "  Project: $PROJECT_DIR"
echo "  Remotion: $REMOTION_VERSION"
echo ""
echo "  Start studio:  cd $PROJECT_DIR && npm start"
echo "  Render video:  bash $SCRIPT_DIR/render.sh <composition> [flags]"
echo ""
