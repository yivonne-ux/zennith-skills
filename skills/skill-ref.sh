#!/usr/bin/env bash
# skill-ref.sh — Load a skill's reference file for OpenClaw agents
# OpenClaw agents can't use Claude Code's Read tool.
# This script lets them load reference files via exec.
#
# Usage:
#   bash ~/.openclaw/skills/skill-ref.sh <skill-name> <reference-file>
#   bash ~/.openclaw/skills/skill-ref.sh brand-prompt-library prompt-packs-brands.md
#   bash ~/.openclaw/skills/skill-ref.sh campaign-translate language-matrix.md
#
# Lists available references:
#   bash ~/.openclaw/skills/skill-ref.sh <skill-name> --list
#   bash ~/.openclaw/skills/skill-ref.sh brand-prompt-library --list

set -euo pipefail

SKILL_BASE="$HOME/.openclaw/skills"
SKILL="${1:-}"
REF="${2:-}"

if [[ -z "$SKILL" ]]; then
  echo "Usage: skill-ref.sh <skill-name> <reference-file>"
  echo "       skill-ref.sh <skill-name> --list"
  exit 1
fi

SKILL_DIR="$SKILL_BASE/$SKILL"
REF_DIR="$SKILL_DIR/references"

if [[ ! -d "$SKILL_DIR" ]]; then
  echo "ERROR: Skill '$SKILL' not found at $SKILL_DIR" >&2
  exit 1
fi

if [[ "$REF" == "--list" ]] || [[ -z "$REF" ]]; then
  echo "=== References for: $SKILL ==="
  if [[ -d "$REF_DIR" ]]; then
    for f in "$REF_DIR"/*.md; do
      [[ -f "$f" ]] || continue
      name=$(basename "$f")
      lines=$(wc -l < "$f" | tr -d ' ')
      echo "  $name ($lines lines)"
    done
  else
    echo "  (no references/ directory)"
  fi
  exit 0
fi

REF_FILE="$REF_DIR/$REF"
if [[ ! -f "$REF_FILE" ]]; then
  echo "ERROR: Reference '$REF' not found at $REF_FILE" >&2
  echo "Available references:" >&2
  ls "$REF_DIR"/*.md 2>/dev/null | while read f; do echo "  $(basename "$f")" >&2; done
  exit 1
fi

cat "$REF_FILE"
