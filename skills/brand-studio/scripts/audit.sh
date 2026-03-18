#!/usr/bin/env bash
# audit.sh — Visual QA audit via Gemini Vision
# Usage: audit.sh --brand mirra --image /path/to/generated.png [--reference /path/to/ref.jpg]
set -euo pipefail

[ -z "${GEMINI_API_KEY:-}" ] && [ -f "$HOME/.openclaw/.env" ] && \
  eval "$(grep '^GEMINI_API_KEY=' "$HOME/.openclaw/.env")"
[ -z "${GEMINI_API_KEY:-}" ] && [ -f "$HOME/.openclaw/secrets/gemini.env" ] && \
  export "$(grep '^GEMINI_API_KEY=' "$HOME/.openclaw/secrets/gemini.env" | head -1)"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRANDS_DIR="$HOME/.openclaw/brands"
AUDIT_DIR="$HOME/.openclaw/workspace/data/brand-studio/audits"

BRAND="" IMAGE="" REFERENCE="" OUTPUT_JSON=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand)     BRAND="$2";     shift 2 ;;
    --image)     IMAGE="$2";     shift 2 ;;
    --reference) REFERENCE="$2"; shift 2 ;;
    --output)    OUTPUT_JSON="$2"; shift 2 ;;
    --help)
      echo "audit.sh — Visual QA audit for brand compliance"
      echo "Usage: audit.sh --brand <slug> --image <path> [--reference <path>]"
      exit 0 ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$BRAND" ]] && { echo "ERROR: --brand required" >&2; exit 1; }
[[ -z "$IMAGE" ]] && { echo "ERROR: --image required" >&2; exit 1; }
[[ -f "$IMAGE" ]] || { echo "ERROR: Image not found: $IMAGE" >&2; exit 1; }

DNA_FILE="$BRANDS_DIR/$BRAND/DNA.json"
[[ -f "$DNA_FILE" ]] || { echo "ERROR: DNA not found: $DNA_FILE" >&2; exit 1; }

# Auto-select reference if not provided
if [[ -z "$REFERENCE" ]]; then
  ASSETS_DIR="$BRANDS_DIR/$BRAND/assets"
  for f in "$ASSETS_DIR"/ref-comparison*.jpg "$ASSETS_DIR"/brand-guide*.jpg; do
    [[ -f "$f" ]] && REFERENCE="$f" && break
  done
fi

mkdir -p "$AUDIT_DIR"
TS=$(date '+%Y%m%d_%H%M%S')
[[ -z "$OUTPUT_JSON" ]] && OUTPUT_JSON="$AUDIT_DIR/${BRAND}_audit_${TS}.json"

echo "=== Brand Studio: Visual Audit ==="
echo "  Brand:     $BRAND"
echo "  Image:     $IMAGE"
echo "  Reference: ${REFERENCE:-none}"
echo "  Output:    $OUTPUT_JSON"
echo ""

# Run the standalone Python audit script
AUDIT_ARGS=("$IMAGE" "$DNA_FILE" "$OUTPUT_JSON")
[[ -n "$REFERENCE" ]] && AUDIT_ARGS+=("$REFERENCE")

python3 "$SCRIPT_DIR/visual-audit.py" "${AUDIT_ARGS[@]}"
