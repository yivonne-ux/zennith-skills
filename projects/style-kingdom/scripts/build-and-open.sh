#!/bin/bash
# Style Kingdom — Build & Open in Roblox Studio
# Usage: bash scripts/build-and-open.sh

set -e
cd "$(dirname "$0")/.."

export PATH="$HOME/.rokit/bin:$PATH"

echo "=== Style Kingdom Build Pipeline ==="

# Step 1: Format
echo "[1/5] Formatting..."
stylua src/

# Step 2: Lint
echo "[2/5] Linting..."
LINT_OUTPUT=$(selene src/ 2>&1)
ERRORS=$(echo "$LINT_OUTPUT" | grep -c "error\[" || true)
WARNINGS=$(echo "$LINT_OUTPUT" | grep -c "warning\[" || true)
echo "  Errors: $ERRORS  Warnings: $WARNINGS"
if [ "$ERRORS" -gt 0 ]; then
    echo "❌ Lint errors found! Fix before publishing."
    echo "$LINT_OUTPUT"
    exit 1
fi

# Step 3: Build .rbxl
echo "[3/5] Building .rbxl..."
rojo build build.project.json -o StyleKingdom.rbxl
SIZE=$(ls -lh StyleKingdom.rbxl | awk '{print $5}')
echo "  Built: StyleKingdom.rbxl ($SIZE)"

# Step 4: Generate sourcemap
echo "[4/5] Generating sourcemap..."
rojo sourcemap default.project.json --output sourcemap.json

# Step 5: Open in Studio
echo "[5/5] Opening in Roblox Studio..."
open StyleKingdom.rbxl

echo ""
echo "=== Build Complete ==="
echo ""
echo "Next steps in Roblox Studio:"
echo "  1. File → Publish to Roblox"
echo "  2. Game Settings → Monetization → Create GamePasses"
echo "  3. Game Settings → Access → Allow Private Servers (price: 0)"
echo "  4. Press F5 to test"
echo ""
echo "For live sync: rojo serve (port 34872)"
