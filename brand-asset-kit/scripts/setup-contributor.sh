#!/usr/bin/env bash
# setup-contributor.sh — One-command setup for Yvonne/Tricia to paste into Claude Code
# Creates their personal brand asset workspace with auto-classification + GAIA integration
#
# Usage (paste into Claude Code terminal):
#   bash <(curl -sL https://raw.githubusercontent.com/.../setup-contributor.sh) --name yvonne --brand mirra
#
# Or locally:
#   bash ~/.openclaw/skills/brand-asset-kit/scripts/setup-contributor.sh --name yvonne --brand mirra

set -euo pipefail

NAME="" BRAND="mirra"
while [ $# -gt 0 ]; do
  case "$1" in
    --name) shift; NAME="$1" ;;
    --brand) shift; BRAND="$1" ;;
  esac
  shift 2>/dev/null || true
done

if [ -z "$NAME" ]; then
  echo "Usage: setup-contributor.sh --name <yvonne|tricia> --brand <brand>"
  exit 1
fi

GAIA_ROOT="$HOME/.openclaw"
KIT_DIR="$HOME/Desktop/${NAME}-${BRAND}-workspace"
SKILLS="$GAIA_ROOT/skills"

echo ""
echo "═══════════════════════════════════════════════"
echo " GAIA OS — Brand Asset Workspace Setup"
echo " Contributor: $NAME"
echo " Brand: $BRAND"
echo "═══════════════════════════════════════════════"
echo ""

# Step 1: Create workspace via init-kit
echo "[1/5] Creating workspace..."
if [ -f "$SKILLS/brand-asset-kit/scripts/init-kit.sh" ]; then
  bash "$SKILLS/brand-asset-kit/scripts/init-kit.sh" \
    --contributor "$NAME" --brand "$BRAND" --output "$KIT_DIR"
else
  echo "ERROR: brand-asset-kit skill not found at $SKILLS/brand-asset-kit"
  exit 1
fi

# Step 2: Create enhanced CLAUDE.md with full asset pipeline instructions
echo "[2/5] Writing Claude Code instructions..."
cat > "$KIT_DIR/CLAUDE.md" << 'CLAUDE_EOF'
# Brand Asset Workspace — GAIA OS

You are a brand asset manager for GAIA CORP-OS. This workspace handles ALL incoming files,
links, images, and references for the brand team.

## WHEN SOMEONE DROPS A FILE OR ASKS YOU TO PROCESS SOMETHING:

### Images (png, jpg, webp, heic)
1. **Classify**: `python3 tools/classify-asset.py --file inbox/<filename>`
2. **Build manifest**: `python3 tools/build-manifest.py --file references/<type>/elem-<id>/<filename>`
3. **Rebuild index**: `python3 tools/build-index.py`
4. **Report**: Tell the user what type it was classified as, what tags were applied

### Links / URLs
1. **Scrape content**: `curl -sL "https://r.jina.ai/<url>" | head -c 3000`
2. **Classify**: Is it a style reference, product reference, competitor ad, article, or tutorial?
3. **If image URL**: Download and classify as image
4. **If article/tutorial**: Summarize key takeaways, store in `learnings/`
5. **If competitor**: Note brand, product, pricing, creative strategy

### Documents (pdf, docx, txt)
1. Read and summarize
2. Extract any brand guidelines, color codes, typography specs
3. Store insights in `learnings/link-digests.jsonl`

### Videos (mp4, mov)
1. Note: cannot process directly — flag for Iris
2. Store metadata in `learnings/video-refs.jsonl`

## AUTO-TAGGING RULES
Every asset gets tagged with:
- **type**: vibe, character, font, product, product-flat, product-portrait, product-composite, composition, style, footage, color, texture
- **brand**: The brand name
- **source**: who contributed it (check kit-config.json)
- **usage**: reference, sref (style reference for AI gen), context, inspiration, asset, template
- **quality**: draft, reviewed, approved, winner
- **language**: en, cn, bm (if text content)

## METATEXT LABELING
For every image, write a 1-2 sentence description in the manifest.json:
```json
{
  "metatext": "Top-view bento box with salmon, rice, and vegetables on cream background. Warm natural lighting, minimal styling.",
  "usage_tags": ["sref", "product-photography", "food-styling"],
  "ai_gen_prompt": "A description that could recreate this style in AI image generation"
}
```

## STYLE REFERENCE (sref) TAGGING
If an image could be used as a style reference for AI generation:
1. Tag it with `usage: sref`
2. Write an `ai_gen_prompt` in the manifest — this is the prompt that would recreate this style
3. Note the `style_elements`: colors, lighting, composition, mood, typography

## DIGEST & SEED
After processing a batch:
1. Check if any asset is a "winner" (high quality, on-brand, reusable)
2. Winners get promoted to the content seed bank:
   ```bash
   bash ~/.openclaw/skills/content-seed-bank/scripts/seed-store.sh add \
     --type image --brand <brand> --file <path> \
     --tags "<tags>" --source <contributor> --source-type reference
   ```

## MERGE TO GAIA (when batch is done)
```bash
bash ~/.openclaw/skills/brand-asset-kit/scripts/validate-kit.sh --kit-dir .
bash ~/.openclaw/skills/brand-asset-kit/scripts/merge-to-gaia.sh --kit-path . --brand <brand> --dry-run
# If dry-run looks good:
bash ~/.openclaw/skills/brand-asset-kit/scripts/merge-to-gaia.sh --kit-path . --brand <brand>
```

## QUICK COMMANDS
```bash
# Classify everything in inbox
python3 tools/classify-asset.py --dir inbox/

# Build all manifests
python3 tools/build-manifest.py --dir references/ --brand <brand> --contributor <name>

# Rebuild master index
python3 tools/build-index.py

# Find similar references online
python3 tools/scrape-similar.py --image <file> --limit 5

# Validate before merge
bash ~/.openclaw/skills/brand-asset-kit/scripts/validate-kit.sh

# Check LoRA recommendation for a face
python3 tools/lora-check.py --file <face.jpg>

# Stitch multiple refs into composite
python3 tools/stitch-refs.py --images img1.jpg img2.jpg --output composite.jpg
```

## WHAT NOT TO DO
- NEVER delete original files — move them, don't delete
- NEVER merge without validating first
- NEVER skip metatext — every asset needs a description
- NEVER approve without brand DNA check
CLAUDE_EOF

# Step 3: Inject brand-specific context
echo "[3/5] Injecting brand context..."
# Copy brand DNA
if [ -f "$GAIA_ROOT/brands/$BRAND/DNA.json" ]; then
  cp "$GAIA_ROOT/brands/$BRAND/DNA.json" "$KIT_DIR/DNA.json"
  echo "  ✓ Brand DNA copied"
fi

# Copy directions if available
if [ -f "$GAIA_ROOT/brands/$BRAND/campaigns/directions.json" ]; then
  mkdir -p "$KIT_DIR/campaigns"
  cp "$GAIA_ROOT/brands/$BRAND/campaigns/directions.json" "$KIT_DIR/campaigns/"
  echo "  ✓ Campaign directions copied"
fi

# Step 4: Create quick-action scripts
echo "[4/5] Creating quick-action scripts..."

cat > "$KIT_DIR/process-inbox.sh" << 'SCRIPT_EOF'
#!/usr/bin/env bash
# Quick action: classify everything in inbox, build manifests, rebuild index
set -euo pipefail
echo "Processing inbox..."
python3 tools/classify-asset.py --dir inbox/ 2>&1
echo ""
echo "Building manifests..."
BRAND=$(python3 -c "import json; print(json.load(open('kit-config.json'))['brand'])")
CONTRIBUTOR=$(python3 -c "import json; print(json.load(open('kit-config.json'))['contributor'])")
python3 tools/build-manifest.py --dir references/ --brand "$BRAND" --contributor "$CONTRIBUTOR" 2>&1
echo ""
echo "Rebuilding index..."
python3 tools/build-index.py 2>&1
echo ""
echo "✓ Done! Check references/ for organized assets."
SCRIPT_EOF
chmod +x "$KIT_DIR/process-inbox.sh"

cat > "$KIT_DIR/merge-to-gaia.sh" << 'SCRIPT_EOF'
#!/usr/bin/env bash
# Quick action: validate and merge to GAIA
set -euo pipefail
BRAND=$(python3 -c "import json; print(json.load(open('kit-config.json'))['brand'])")
echo "Validating kit..."
bash ~/.openclaw/skills/brand-asset-kit/scripts/validate-kit.sh --kit-dir . 2>&1
echo ""
echo "Dry run merge..."
bash ~/.openclaw/skills/brand-asset-kit/scripts/merge-to-gaia.sh --kit-path . --brand "$BRAND" --dry-run 2>&1
echo ""
read -p "Merge for real? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  bash ~/.openclaw/skills/brand-asset-kit/scripts/merge-to-gaia.sh --kit-path . --brand "$BRAND" 2>&1
  echo "✓ Merged to GAIA!"
fi
SCRIPT_EOF
chmod +x "$KIT_DIR/merge-to-gaia.sh"

# Step 5: Summary
echo "[5/5] Setup complete!"
echo ""
echo "═══════════════════════════════════════════════"
echo " WORKSPACE READY: $KIT_DIR"
echo "═══════════════════════════════════════════════"
echo ""
echo " How to use:"
echo "   1. Open Claude Code in: $KIT_DIR"
echo "   2. Drop files into inbox/"
echo "   3. Tell Claude: 'process inbox' or 'classify this image'"
echo "   4. Claude auto-classifies, labels, tags, creates manifests"
echo "   5. When ready: './merge-to-gaia.sh' to push to GAIA"
echo ""
echo " Quick commands:"
echo "   ./process-inbox.sh     — Classify + manifest + index"
echo "   ./merge-to-gaia.sh     — Validate + merge to GAIA"
echo ""
echo " Asset types: vibe, character, font, product, product-flat,"
echo "   product-portrait, product-composite, composition, style,"
echo "   footage, color, texture"
echo ""
echo " The CLAUDE.md tells Claude Code how to handle ANY file you throw at it."
echo "═══════════════════════════════════════════════"
