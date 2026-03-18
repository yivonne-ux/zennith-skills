#!/bin/bash
# Quick QMDJ engine validator — check against yrydai.com app
# Usage: bash validate-qmdj.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cat << 'HEADER'
=============================================
  QMDJ Engine Validator — vs yrydai.com
=============================================
Open the app, enter each date, and type
the 局数 you see (just the number).

Press Enter to skip, q to quit.

HEADER

python3 "$SCRIPT_DIR/qmdj-engine.py" --validate-interactive 2>&1
