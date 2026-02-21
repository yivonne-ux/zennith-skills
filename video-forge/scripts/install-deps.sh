#!/usr/bin/env bash
# install-deps.sh — Check and install VideoForge dependencies
# macOS compatible (Homebrew + pip3)

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[MISSING]${NC} $1"; }

echo "=== VideoForge Dependency Check ==="
echo ""

ALL_OK=1

# --- ffmpeg ---
echo "Checking ffmpeg..."
if command -v ffmpeg >/dev/null 2>&1; then
  VER=$(ffmpeg -version 2>&1 | head -1)
  ok "ffmpeg found: $VER"

  # Check for h264_videotoolbox (Apple Silicon hardware encoding)
  if ffmpeg -encoders 2>&1 | grep -q h264_videotoolbox; then
    ok "h264_videotoolbox hardware encoder available"
  else
    warn "h264_videotoolbox not available — will use software encoding (slower)"
  fi
else
  fail "ffmpeg not found"
  ALL_OK=0
  echo "  Install with: brew install ffmpeg"
  echo ""
  read -r -p "  Install ffmpeg now via Homebrew? [y/N] " answer
  case "$answer" in
    y|Y)
      if command -v brew >/dev/null 2>&1; then
        echo "  Installing ffmpeg..."
        brew install ffmpeg
        ok "ffmpeg installed"
      else
        fail "Homebrew not found. Install from https://brew.sh first"
      fi
      ;;
    *)
      echo "  Skipping ffmpeg installation"
      ;;
  esac
fi

echo ""

# --- ffprobe (comes with ffmpeg) ---
echo "Checking ffprobe..."
if command -v ffprobe >/dev/null 2>&1; then
  ok "ffprobe found"
else
  fail "ffprobe not found (should come with ffmpeg)"
  ALL_OK=0
fi

echo ""

# --- python3 ---
echo "Checking python3..."
if command -v python3 >/dev/null 2>&1; then
  PYVER=$(python3 --version 2>&1)
  ok "python3 found: $PYVER"
else
  fail "python3 not found"
  ALL_OK=0
  echo "  Install with: brew install python3"
fi

echo ""

# --- faster-whisper ---
echo "Checking faster-whisper..."
WHISPER_FOUND=0

if command -v faster-whisper >/dev/null 2>&1; then
  ok "faster-whisper CLI found"
  WHISPER_FOUND=1
elif python3 -c "import faster_whisper" 2>/dev/null; then
  ok "faster-whisper Python module found"
  WHISPER_FOUND=1
fi

if [ "$WHISPER_FOUND" -eq 0 ]; then
  echo "  Checking fallback: whisper..."
  if command -v whisper >/dev/null 2>&1; then
    ok "whisper CLI found (fallback)"
    WHISPER_FOUND=1
  elif python3 -c "import whisper" 2>/dev/null; then
    ok "whisper Python module found (fallback)"
    WHISPER_FOUND=1
  fi
fi

if [ "$WHISPER_FOUND" -eq 0 ]; then
  fail "No whisper variant found (needed for caption subcommand)"
  ALL_OK=0
  echo ""
  echo "  Install faster-whisper (recommended — faster, lower memory):"
  echo "    pip3 install faster-whisper"
  echo ""
  echo "  Or install OpenAI whisper (fallback):"
  echo "    pip3 install openai-whisper"
  echo ""
  read -r -p "  Install faster-whisper now? [y/N] " answer
  case "$answer" in
    y|Y)
      echo "  Installing faster-whisper..."
      pip3 install faster-whisper
      if python3 -c "import faster_whisper" 2>/dev/null; then
        ok "faster-whisper installed successfully"
      else
        fail "faster-whisper installation may have failed"
      fi
      ;;
    *)
      echo "  Skipping whisper installation"
      echo "  Note: caption subcommand will not work without whisper"
      ;;
  esac
fi

echo ""

# --- Summary ---
echo "=== Summary ==="
if [ "$ALL_OK" -eq 1 ]; then
  ok "All dependencies satisfied. VideoForge is ready."
else
  warn "Some dependencies are missing. Install them to enable full functionality."
  echo ""
  echo "  Quick install all:"
  echo "    brew install ffmpeg"
  echo "    pip3 install faster-whisper"
fi

echo ""
echo "VideoForge script: $(cd "$(dirname "$0")" && pwd)/video-forge.sh"
echo "Log file: ~/.openclaw/logs/video-forge.log"
