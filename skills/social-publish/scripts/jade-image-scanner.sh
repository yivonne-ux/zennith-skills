#!/usr/bin/env bash
# jade-image-scanner.sh — Scan, tag, and categorize all Jade Oracle images
#
# Uses Claude Vision to analyze each image and generate detailed tags:
# scene, outfit, mood, expression, setting, activity, lighting, brand_fit, ig_vibe
#
# Usage:
#   bash jade-image-scanner.sh                    # Scan all untagged images
#   bash jade-image-scanner.sh --rescan           # Rescan all (even tagged)
#   bash jade-image-scanner.sh --image PATH       # Scan single image
#   bash jade-image-scanner.sh --pick "warm cozy self-love"  # Find best match
#   bash jade-image-scanner.sh --list             # List all tagged images
#   bash jade-image-scanner.sh --stats            # Show tag statistics

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
CLAUDE_CLI="$(command -v claude 2>/dev/null || echo "")"

IMG_DIR="$OPENCLAW_DIR/workspace/data/images/jade-oracle/ig-library/jade"
REGISTRY="$OPENCLAW_DIR/workspace/data/images/jade-oracle/ig-library/image-registry.json"

CMD="${1:-scan}"
shift 2>/dev/null || true

log() { echo "[image-scanner $(date +%H:%M:%S)] $1"; }

###############################################################################
# Scan a single image using Claude Vision
###############################################################################

scan_image() {
    local img_path="$1"
    local filename
    filename=$(basename "$img_path")

    if [[ -z "$CLAUDE_CLI" ]]; then
        log "ERROR: Claude CLI not found — cannot scan images"
        return 1
    fi

    # Create prompt for Claude Vision
    local tmp_prompt
    tmp_prompt=$(mktemp)
    cat > "$tmp_prompt" << 'SCANEOF'
Analyze this image of an AI-generated woman character (Jade Oracle — Korean woman, early 30s, oracle reader).

Provide a JSON object with these exact fields:

{
  "filename": "FILENAME",
  "scene": "one of: coffee_shop, restaurant, farmers_market, rooftop, home, bedroom, kitchen, bookstore, office, street, park, studio, reading_table, meditation, gym, beach, gallery, abstract_bg, concrete_wall, other",
  "outfit": "describe the outfit in detail — color, style, neckline, fabric",
  "outfit_vibe": "one of: casual, professional, elegant, cozy, spiritual, sexy, sporty, editorial",
  "mood": "one of: warm, intimate, confident, vulnerable, mystical, playful, contemplative, joyful, serene, powerful",
  "expression": "one of: laughing, smiling, contemplative, knowing, serious, looking_away, closed_eyes, surprised, soft_smile",
  "setting": "one of: indoor, outdoor, studio",
  "activity": "what is the person doing — e.g., walking, sitting, reading cards, drinking tea, posing, meditating, cooking",
  "lighting": "one of: golden_hour, natural_window, candlelight, daylight, soft_studio, ambient, dramatic",
  "warmth": "1-10 scale — how warm and inviting does the image feel",
  "brand_fit": "1-10 scale — how well does this match Jade Oracle brand (warm, Korean editorial, spiritual, jade/cream/gold palette)",
  "ig_vibe": "one of: aspirational, relatable, mystical, educational, aesthetic, personal, empowering",
  "best_for": ["list of caption themes this image works for — e.g., self_love, oracle_reading, life_transitions, empowerment, kindness, morning_routine, vulnerability, confidence, spiritual_wisdom, behind_scenes, pick_a_card"],
  "avoid_for": ["caption themes this image should NOT be used for"],
  "quality": "1-10 — overall image quality (composition, lighting, realism)",
  "issues": "any visual issues: weird hands, artifacts, unnatural pose, AI slop, etc. 'none' if clean",
  "one_liner": "one sentence describing this image for quick reference"
}

Output ONLY the JSON. No explanation.
SCANEOF

    # Use Claude with the image
    local result
    result=$(cat "$tmp_prompt" | "$CLAUDE_CLI" --print --model "claude-sonnet-4-6" 2>/dev/null) || true
    rm -f "$tmp_prompt"

    # Fix filename in result
    if [[ -n "$result" ]]; then
        result=$(echo "$result" | "$PYTHON3" -c "
import json, sys
try:
    # Strip markdown code fences if present
    text = sys.stdin.read().strip()
    if text.startswith('\`\`\`'):
        text = text.split('\n', 1)[1]
    if text.endswith('\`\`\`'):
        text = text.rsplit('\n', 1)[0]
    text = text.strip()
    d = json.loads(text)
    d['filename'] = '$filename'
    d['path'] = '$img_path'
    print(json.dumps(d, indent=2))
except Exception as e:
    print(json.dumps({'filename': '$filename', 'path': '$img_path', 'error': str(e)}))
")
    else
        result="{\"filename\": \"$filename\", \"path\": \"$img_path\", \"error\": \"scan_failed\"}"
    fi

    echo "$result"
}

###############################################################################
# Scan all images in the library
###############################################################################

scan_all() {
    local rescan="${1:-false}"

    log "Scanning image library: $IMG_DIR"

    # Load existing registry
    local existing_files=""
    if [[ -f "$REGISTRY" ]] && [[ "$rescan" != "true" ]]; then
        existing_files=$("$PYTHON3" -c "
import json
d = json.load(open('$REGISTRY'))
for img in d.get('images', []):
    print(img.get('filename', ''))
" 2>/dev/null)
    fi

    local scanned=0
    local skipped=0
    local results="["

    for img in "$IMG_DIR"/*.png "$IMG_DIR"/*.jpg "$IMG_DIR"/*.jpeg; do
        [[ -f "$img" ]] || continue
        local fname
        fname=$(basename "$img")

        # Skip if already scanned (unless rescan)
        if [[ "$rescan" != "true" ]] && echo "$existing_files" | grep -q "^${fname}$"; then
            skipped=$((skipped + 1))
            continue
        fi

        log "Scanning: $fname"
        local result
        result=$(scan_image "$img")

        if [[ "$scanned" -gt 0 ]]; then
            results="${results},"
        fi
        results="${results}${result}"
        scanned=$((scanned + 1))

        # Brief pause between scans
        sleep 2
    done

    results="${results}]"

    # Merge with existing registry
    "$PYTHON3" << PYEOF
import json, os

registry_path = "$REGISTRY"
new_scans = json.loads('''$results''')

# Load existing
existing = {"images": [], "updated": "", "total": 0}
if os.path.exists(registry_path):
    try:
        existing = json.load(open(registry_path))
    except:
        pass

# Merge — update existing entries, add new
existing_map = {img["filename"]: img for img in existing.get("images", [])}
for scan in new_scans:
    if "error" not in scan or scan.get("error") == "none":
        existing_map[scan["filename"]] = scan

from datetime import datetime
existing["images"] = sorted(existing_map.values(), key=lambda x: x.get("filename", ""))
existing["total"] = len(existing["images"])
existing["updated"] = datetime.utcnow().isoformat() + "Z"

with open(registry_path, "w") as f:
    json.dump(existing, f, indent=2)

print(f"Registry updated: {existing['total']} images total")
PYEOF

    log "Scanned: $scanned | Skipped: $skipped"
    log "Registry: $REGISTRY"
}

###############################################################################
# Pick best image for a caption theme
###############################################################################

pick_image() {
    local query="$1"

    if [[ ! -f "$REGISTRY" ]]; then
        log "ERROR: No registry. Run: bash jade-image-scanner.sh scan"
        return 1
    fi

    "$PYTHON3" << PYEOF
import json

registry = json.load(open("$REGISTRY"))
query = "$query".lower().split()
images = registry.get("images", [])

scored = []
for img in images:
    score = 0
    best_for = [b.lower() for b in img.get("best_for", [])]
    avoid_for = [a.lower() for a in img.get("avoid_for", [])]
    mood = img.get("mood", "").lower()
    ig_vibe = img.get("ig_vibe", "").lower()
    one_liner = img.get("one_liner", "").lower()

    # Score based on query match
    for q in query:
        if any(q in b for b in best_for):
            score += 10
        if q in mood:
            score += 5
        if q in ig_vibe:
            score += 3
        if q in one_liner:
            score += 2
        if any(q in a for a in avoid_for):
            score -= 20

    # Bonus for quality and brand fit
    score += img.get("quality", 5)
    score += img.get("brand_fit", 5)
    score += img.get("warmth", 5)

    if score > 0:
        scored.append((score, img))

scored.sort(key=lambda x: -x[0])

print(f"Query: {' '.join(query)}")
print(f"Results: {len(scored)} matches\n")

for i, (score, img) in enumerate(scored[:5]):
    print(f"  [{i+1}] Score: {score}")
    print(f"      File: {img['filename']}")
    print(f"      Mood: {img.get('mood','')} | Vibe: {img.get('ig_vibe','')}")
    print(f"      Best for: {', '.join(img.get('best_for',[]))}")
    print(f"      {img.get('one_liner','')}")
    print(f"      Path: {img.get('path','')}")
    print()

if scored:
    print(f"BEST MATCH: {scored[0][1]['path']}")
PYEOF
}

###############################################################################
# List all tagged images
###############################################################################

list_images() {
    if [[ ! -f "$REGISTRY" ]]; then
        log "No registry yet. Run: bash jade-image-scanner.sh scan"
        return 1
    fi

    "$PYTHON3" << PYEOF
import json

registry = json.load(open("$REGISTRY"))
images = registry.get("images", [])
print(f"=== Image Registry: {len(images)} images ===\n")

for img in images:
    q = img.get("quality", "?")
    bf = img.get("brand_fit", "?")
    print(f"  {img['filename']}")
    print(f"    {img.get('one_liner','no description')}")
    print(f"    Mood: {img.get('mood','')} | Vibe: {img.get('ig_vibe','')} | Q:{q} BF:{bf}")
    print(f"    Best: {', '.join(img.get('best_for',[])[:5])}")
    print()
PYEOF
}

###############################################################################
# Stats
###############################################################################

show_stats() {
    if [[ ! -f "$REGISTRY" ]]; then
        log "No registry. Run scan first."
        return 1
    fi

    "$PYTHON3" << PYEOF
import json
from collections import Counter

reg = json.load(open("$REGISTRY"))
images = reg.get("images", [])

print(f"Total images: {len(images)}")
print(f"Updated: {reg.get('updated','unknown')}")
print()

for field in ["mood", "scene", "outfit_vibe", "ig_vibe", "setting", "lighting"]:
    counts = Counter(img.get(field, "unknown") for img in images)
    print(f"{field}:")
    for val, cnt in counts.most_common(5):
        print(f"  {val}: {cnt}")
    print()

# Best-for tags
all_tags = []
for img in images:
    all_tags.extend(img.get("best_for", []))
print("Top best_for tags:")
for tag, cnt in Counter(all_tags).most_common(10):
    print(f"  {tag}: {cnt}")
PYEOF
}

###############################################################################
# Main
###############################################################################

case "$CMD" in
    scan)       scan_all "false" ;;
    --rescan)   scan_all "true" ;;
    --image)    scan_image "${1:-}" ;;
    --pick)     pick_image "${1:-}" ;;
    --list)     list_images ;;
    --stats)    show_stats ;;
    *)
        echo "Usage: jade-image-scanner.sh [scan|--rescan|--image PATH|--pick QUERY|--list|--stats]"
        ;;
esac
