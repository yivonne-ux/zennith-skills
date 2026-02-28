#!/usr/bin/env bash
# install-deps.sh — Check required dependencies for Persona skill
# macOS Bash 3.2 compatible

set -euo pipefail

PASS=0
FAIL=0
WARN=0

check_pass() { echo "  [OK]   $1"; PASS=$((PASS + 1)); }
check_fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }
check_warn() { echo "  [WARN] $1"; WARN=$((WARN + 1)); }

echo ""
echo "=== Persona Skill — Dependency Check ==="
echo ""

# --- python3 ---
echo "Checking runtime..."
if command -v python3 >/dev/null 2>&1; then
  check_pass "python3 found: $(python3 --version 2>&1)"
else
  check_fail "python3 not found (required for JSON parsing)"
fi

# --- curl ---
if command -v curl >/dev/null 2>&1; then
  check_pass "curl found"
else
  check_fail "curl not found (required for API calls)"
fi

# --- PyJWT (for Kling) ---
if python3 -c "import jwt" 2>/dev/null; then
  check_pass "PyJWT installed (for Kling JWT auth)"
else
  check_warn "PyJWT not installed — run: pip3 install PyJWT"
  echo "         (Required for Kling AI video generation)"
fi

echo ""
echo "Checking API keys..."

# --- GEMINI_API_KEY ---
if [ -n "${GEMINI_API_KEY:-}" ]; then
  check_pass "GEMINI_API_KEY set in environment"
elif [ -f "$HOME/.openclaw/secrets/gemini.env" ]; then
  check_pass "GEMINI_API_KEY found in secrets file"
else
  check_fail "GEMINI_API_KEY not found"
  echo "         Set via: export GEMINI_API_KEY=your_key"
  echo "         Or add to: ~/.openclaw/secrets/gemini.env"
fi

# --- ELEVENLABS_API_KEY ---
if [ -n "${ELEVENLABS_API_KEY:-}" ]; then
  check_pass "ELEVENLABS_API_KEY set in environment"
elif [ -f "$HOME/.openclaw/secrets/elevenlabs.env" ]; then
  check_pass "ELEVENLABS_API_KEY found in secrets file"
else
  check_warn "ELEVENLABS_API_KEY not found (needed for voice commands)"
  echo "         Set via: export ELEVENLABS_API_KEY=your_key"
  echo "         Or add to: ~/.openclaw/secrets/elevenlabs.env"
fi

# --- Kling credentials ---
if [ -n "${KLING_ACCESS_KEY:-}" ] && [ -n "${KLING_SECRET_KEY:-}" ]; then
  check_pass "Kling credentials set in environment"
elif [ -f "$HOME/.openclaw/workspace/ops/.kling-env" ]; then
  check_pass "Kling credentials found in .kling-env"
else
  check_warn "Kling credentials not found (needed for animate command)"
  echo "         Create: ~/.openclaw/workspace/ops/.kling-env"
fi

echo ""
echo "Checking integrated scripts..."

# --- NanoBanana ---
if [ -f "$HOME/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh" ]; then
  check_pass "NanoBanana script found"
else
  check_fail "NanoBanana script not found at ~/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh"
fi

# --- Kling (via video-gen.sh) ---
if [ -f "$HOME/.openclaw/skills/video-gen/scripts/video-gen.sh" ]; then
  check_pass "Video gen script found (includes Kling)"
else
  check_fail "Video gen script not found at ~/.openclaw/skills/video-gen/scripts/video-gen.sh"
fi

echo ""
echo "Checking directories..."

# --- Data directories ---
mkdir -p "$HOME/.openclaw/workspace/data/videos" 2>/dev/null && check_pass "Videos directory ready"
mkdir -p "$HOME/.openclaw/workspace/data/audio" 2>/dev/null && check_pass "Audio directory ready"
mkdir -p "$HOME/.openclaw/workspace/data/characters" 2>/dev/null && check_pass "Characters directory ready"
mkdir -p "$HOME/.openclaw/logs" 2>/dev/null && check_pass "Logs directory ready"
mkdir -p "$HOME/.openclaw/skills/persona/personas" 2>/dev/null && check_pass "Personas directory ready"

echo ""
echo "=== Results ==="
echo "  Passed: $PASS"
echo "  Warnings: $WARN"
echo "  Failed: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Fix FAIL items before using Persona skill."
  exit 1
else
  echo ""
  echo "Persona skill is ready."
  exit 0
fi
