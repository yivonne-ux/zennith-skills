#!/usr/bin/env bash
# room-rotation.sh — Daily room file rotation
# Moves today's room files to dated archives, creates fresh ones.
# Run nightly via cron (e.g., 11:59pm MYT).

set -euo pipefail

ROOMS_DIR="${HOME}/.openclaw/workspace/rooms"
ARCHIVE_DIR="${ROOMS_DIR}/archive"
DATE=$(date +%Y-%m-%d)

mkdir -p "$ARCHIVE_DIR"

for f in "$ROOMS_DIR"/*.jsonl; do
  [[ -f "$f" ]] || continue
  name=$(basename "$f" .jsonl)
  # Only rotate if file has content
  if [[ -s "$f" ]]; then
    cp "$f" "${ARCHIVE_DIR}/${name}-${DATE}.jsonl"
    # Keep last 5 entries as context seed for tomorrow
    tail -5 "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
    echo "[$(date)] Rotated $name (kept last 5 entries)"
  fi
done
