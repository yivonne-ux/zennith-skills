#!/usr/bin/env bash
# ref-picker.sh — Visual Reference Image Picker for GAIA OS
# Solves: "every time I need a ref image I have to search manually"
# Usage: ref-picker.sh <command> [options]
# macOS Bash 3.2 compatible

set -euo pipefail

OPENCLAW_DIR="$HOME/.openclaw"
BRANDS_DIR="$OPENCLAW_DIR/brands"
IMAGES_DIR="$OPENCLAW_DIR/workspace/data/images"
CHARS_DIR="$OPENCLAW_DIR/workspace/data/characters"
CATALOG_FILE="$OPENCLAW_DIR/workspace/data/ref-catalog.jsonl"
GALLERY_DIR="$OPENCLAW_DIR/workspace/apps/ref-gallery"
LOG_FILE="$OPENCLAW_DIR/logs/ref-picker.log"

log() { mkdir -p "$(dirname "$LOG_FILE")"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

die() { echo "ERROR: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# catalog — Scan all image directories, build unified index
# ---------------------------------------------------------------------------
cmd_catalog() {
    local force="false"
    while [ $# -gt 0 ]; do
        case "$1" in
            --force) force="true"; shift ;;
            *) shift ;;
        esac
    done

    # Skip if catalog is fresh (< 1 hour old) unless --force
    if [ "$force" != "true" ] && [ -f "$CATALOG_FILE" ]; then
        local age
        age=$(python3 -c "
import os, time
st = os.stat('$CATALOG_FILE')
print(int(time.time() - st.st_mtime))
" 2>/dev/null || echo "99999")
        if [ "$age" -lt 3600 ]; then
            local count
            count=$(wc -l < "$CATALOG_FILE" | tr -d ' ')
            echo "Catalog fresh ($age s old, $count entries). Use --force to rebuild."
            return 0
        fi
    fi

    echo "Building reference catalog..."
    mkdir -p "$(dirname "$CATALOG_FILE")"

    python3 << 'PYEOF'
import os, json, glob, hashlib, time

OPENCLAW = os.path.expanduser("~/.openclaw")
catalog = []
seen_paths = set()

def file_hash(path):
    """Quick hash for dedup (first 8KB only for speed)"""
    h = hashlib.md5()
    try:
        with open(path, 'rb') as f:
            h.update(f.read(8192))
    except:
        return ""
    return h.hexdigest()[:12]

def add_image(path, brand="", img_type="", agent="", tags=None, source=""):
    path = os.path.abspath(path)
    if path in seen_paths:
        return
    if not os.path.isfile(path):
        return
    seen_paths.add(path)

    ext = path.rsplit('.', 1)[-1].lower()
    if ext not in ('png', 'jpg', 'jpeg', 'webp', 'gif'):
        return

    # Skip _web.jpg variants (compressed copies)
    if '_web.jpg' in path or '_web.jpeg' in path:
        return

    stat = os.stat(path)
    entry = {
        "path": path,
        "brand": brand,
        "type": img_type,
        "agent": agent,
        "tags": tags or [],
        "source": source,
        "size_kb": int(stat.st_size / 1024),
        "modified": int(stat.st_mtime),
        "hash": file_hash(path),
        "filename": os.path.basename(path)
    }
    catalog.append(entry)

# --- 1. Brand references (curated, highest quality) ---
brands_dir = os.path.join(OPENCLAW, "brands")
if os.path.isdir(brands_dir):
    for brand in os.listdir(brands_dir):
        brand_path = os.path.join(brands_dir, brand)
        if not os.path.isdir(brand_path):
            continue

        # References with index.json
        refs_dir = os.path.join(brand_path, "references")
        if os.path.isdir(refs_dir):
            index_path = os.path.join(refs_dir, "index.json")
            ref_index = {}
            if os.path.isfile(index_path):
                try:
                    with open(index_path) as f:
                        ref_index = json.load(f)
                except:
                    pass

            elements = {e.get('id', ''): e for e in ref_index.get('elements', [])}

            for root, dirs, files in os.walk(refs_dir):
                for fn in files:
                    fp = os.path.join(root, fn)
                    ext = fn.rsplit('.', 1)[-1].lower()
                    if ext in ('png', 'jpg', 'jpeg', 'webp'):
                        # Try to match with index entry
                        tags = ["curated", "reference"]
                        img_type = "reference"
                        for eid, elem in elements.items():
                            if eid in root or elem.get('name', '').lower().replace(' ', '-') in fn.lower():
                                tags.extend(elem.get('tags', []))
                                img_type = elem.get('type', 'reference')
                                break
                        add_image(fp, brand=brand, img_type=img_type, tags=tags, source="brand-references")

        # Assets directory
        assets_dir = os.path.join(brand_path, "assets")
        if os.path.isdir(assets_dir):
            for root, dirs, files in os.walk(assets_dir):
                for fn in files:
                    fp = os.path.join(root, fn)
                    # Detect asset subtypes from filename
                    fn_lower = fn.lower()
                    asset_tags = ["brand-asset"]
                    asset_type = "asset"
                    if 'logo' in fn_lower:
                        asset_tags.append("logo")
                        asset_type = "logo"
                    if 'comparison' in fn_lower:
                        asset_tags.append("comparison-template")
                    if 'bento' in fn_lower or 'topview' in fn_lower:
                        asset_tags.append("bento-style")
                    if 'brand-guide' in fn_lower:
                        asset_tags.append("brand-guide")
                    add_image(fp, brand=brand, img_type=asset_type, tags=asset_tags, source="brand-assets")

        # Output directory (generated ads)
        output_dir = os.path.join(brand_path, "output")
        if os.path.isdir(output_dir):
            for root, dirs, files in os.walk(output_dir):
                for fn in files:
                    fp = os.path.join(root, fn)
                    add_image(fp, brand=brand, img_type="generated-ad", tags=["generated", "ad"], source="brand-output")

        # --- 1b. Product SKU photos (march-campaign bento, etc.) ---
        # Check both brands/ and workspace/brands/ locations
        workspace_brand_path = os.path.join(OPENCLAW, "workspace", "brands", brand)
        sku_dirs = [
            os.path.join(brand_path, "march-campaign", "drive-assets", "My product bento"),
            os.path.join(workspace_brand_path, "march-campaign", "drive-assets", "My product bento"),
            os.path.join(brand_path, "product-photos"),
            os.path.join(workspace_brand_path, "product-photos"),
            os.path.join(brand_path, "sku-photos"),
            os.path.join(workspace_brand_path, "sku-photos"),
        ]
        for sku_dir in sku_dirs:
            if not os.path.isdir(sku_dir):
                continue
            for fn in os.listdir(sku_dir):
                fp = os.path.join(sku_dir, fn)
                ext = fn.rsplit('.', 1)[-1].lower() if '.' in fn else ''
                if ext not in ('png', 'jpg', 'jpeg', 'webp'):
                    continue
                fn_lower = fn.lower()
                sku_tags = ["product-sku", "bento"]
                sku_type = "product-sku"

                # Detect view type
                if 'top-view' in fn_lower or 'top view' in fn_lower:
                    sku_tags.append("top-view")
                else:
                    sku_tags.append("angle-view")

                # Extract dish name from filename
                # Pattern: "Dish-Name-Bento-Box-Top-View.png" or "Dish-Name-Bento-Box.png"
                dish = fn
                for strip in ['-Bento-Box-Top-View', '-Top-View', '-Bento-Box', '-Top View',
                              'Bento Box-Top View', 'Bento Box', '.png', '.jpg', '.jpeg', '.webp']:
                    dish = dish.replace(strip, '')
                dish = dish.strip().strip('-').strip()
                dish_tag = dish.lower().replace(' ', '-').replace('--', '-')
                if dish_tag:
                    sku_tags.append("dish:" + dish_tag)
                    # Also add individual words for fuzzy matching
                    for word in dish_tag.split('-'):
                        if len(word) > 2:
                            sku_tags.append(word)

                # Group image (all products together)
                if 'group' in fn_lower:
                    sku_tags.append("group-shot")
                    sku_type = "product-group"

                add_image(fp, brand=brand, img_type=sku_type, tags=sku_tags, source="product-sku")

# --- 1c. Workspace brand assets (workspace/brands/ may have additional drive assets) ---
ws_brands_dir = os.path.join(OPENCLAW, "workspace", "brands")
if os.path.isdir(ws_brands_dir):
    for brand_name in os.listdir(ws_brands_dir):
        ws_brand_path = os.path.join(ws_brands_dir, brand_name)
        if not os.path.isdir(ws_brand_path):
            continue
        # Walk the entire workspace brand dir for images not yet seen
        for root, dirs, files in os.walk(ws_brand_path):
            for fn in files:
                fp = os.path.join(root, fn)
                if fp in seen_paths:
                    continue
                ext = fn.rsplit('.', 1)[-1].lower() if '.' in fn else ''
                if ext not in ('png', 'jpg', 'jpeg', 'webp'):
                    continue
                fn_lower = fn.lower()
                rel_path = root.replace(ws_brand_path, '').lower()
                ws_tags = []
                ws_type = "reference"
                # Detect type from path/filename
                if 'product bento' in rel_path or 'bento' in fn_lower:
                    ws_type = "product-sku"
                    ws_tags.extend(["product-sku", "bento"])
                    if 'top-view' in fn_lower or 'top view' in fn_lower:
                        ws_tags.append("top-view")
                    else:
                        ws_tags.append("angle-view")
                    # Extract dish name
                    dish = fn
                    for strip in ['-Bento-Box-Top-View', '-Top-View', '-Bento-Box', '-Top View',
                                  'Bento Box-Top View', 'Bento Box', '.png', '.jpg', '.jpeg', '.webp']:
                        dish = dish.replace(strip, '')
                    dish = dish.strip().strip('-').strip()
                    dish_tag = dish.lower().replace(' ', '-').replace('--', '-')
                    if dish_tag and dish_tag != 'group image':
                        ws_tags.append("dish:" + dish_tag)
                        for word in dish_tag.split('-'):
                            if len(word) > 2:
                                ws_tags.append(word)
                    if 'group' in fn_lower:
                        ws_tags.append("group-shot")
                        ws_type = "product-group"
                elif 'food photography' in rel_path:
                    ws_type = "style"
                    ws_tags.extend(["food-photography", "style-ref"])
                elif 'ads reference' in rel_path:
                    ws_type = "composition"
                    ws_tags.extend(["ad-reference", "layout"])
                elif 'illustration' in rel_path:
                    ws_type = "graphic"
                    ws_tags.extend(["illustration", "element"])
                elif 'logo' in fn_lower:
                    ws_type = "logo"
                    ws_tags.append("logo")
                elif 'human model' in rel_path:
                    ws_type = "style"
                    ws_tags.extend(["human-model", "lifestyle"])
                else:
                    ws_tags.append("workspace-asset")

                source = "product-sku" if ws_type == "product-sku" else "workspace-brand"
                add_image(fp, brand=brand_name, img_type=ws_type, tags=ws_tags, source=source)

# --- 2. Character assets (locked characters, sheets) ---
chars_dir = os.path.join(OPENCLAW, "workspace/data/characters")
if os.path.isdir(chars_dir):
    for agent_or_file in os.listdir(chars_dir):
        agent_path = os.path.join(chars_dir, agent_or_file)
        if os.path.isdir(agent_path):
            for fn in os.listdir(agent_path):
                fp = os.path.join(agent_path, fn)
                tags = ["character"]
                if "locked" in fn:
                    tags.append("locked")
                if "sheet" in fn:
                    tags.append("character-sheet")
                if "fullbody" in fn:
                    tags.append("fullbody")
                if "expression" in fn:
                    tags.append("expressions")
                add_image(fp, brand="gaia-os", img_type="character", agent=agent_or_file, tags=tags, source="character-vault")

# --- 3. Generated images (workspace/data/images) ---
images_dir = os.path.join(OPENCLAW, "workspace/data/images")
if os.path.isdir(images_dir):
    for brand_folder in os.listdir(images_dir):
        folder_path = os.path.join(images_dir, brand_folder)
        if not os.path.isdir(folder_path):
            continue
        for fn in os.listdir(folder_path):
            fp = os.path.join(folder_path, fn)
            # Infer type from filename
            tags = ["generated"]
            img_type = "generated"
            fn_lower = fn.lower()
            gen_agent = ""
            for kw in ['character', 'lifestyle', 'product', 'recipe', 'comparison', 'beforeafter', 'hero', 'flatlay', 'social', 'food', 'ecommerce']:
                if kw in fn_lower:
                    img_type = kw
                    tags.append(kw)
                    break
            # Detect agent from filename for character images
            for a in ['zenni', 'taoz', 'dreami', 'hermes', 'iris', 'artemis', 'athena', 'argus', 'myrmidons']:
                if a in fn_lower:
                    gen_agent = a
                    tags.append("character")
                    break
            add_image(fp, brand=brand_folder, img_type=img_type, agent=gen_agent, tags=tags, source="generated")

# --- 4. Creative studio assets ---
studio_dir = os.path.join(OPENCLAW, "workspace/apps/gaia-creative-studio/server/data/assets")
if os.path.isdir(studio_dir):
    for fn in os.listdir(studio_dir):
        fp = os.path.join(studio_dir, fn)
        add_image(fp, brand="", img_type="studio-asset", tags=["studio", "uploaded"], source="creative-studio")

# --- 5. Pinterest/Download references ---
# Check both with and without trailing space (macOS directory quirk)
downloads_dir = os.path.expanduser("~/Downloads/gaia os ")
if not os.path.isdir(downloads_dir):
    downloads_dir = os.path.expanduser("~/Downloads/gaia os")
if os.path.isdir(downloads_dir):
    for root, dirs, files in os.walk(downloads_dir):
        for fn in files:
            fp = os.path.join(root, fn)
            tags = ["pinterest", "reference"]
            agent = ""
            if "confirm character" in root.lower():
                tags.append("confirmed-character")
            if "charactors reference" in root.lower() or "characters reference" in root.lower():
                tags.append("attire-reference")
            # Try to detect agent from filename
            for a in ['zenni', 'taoz', 'dreami', 'hermes', 'iris', 'artemis', 'athena', 'argus', 'myrmidons']:
                if a in fn.lower() or a in root.lower():
                    agent = a
                    break
            add_image(fp, brand="gaia-os", img_type="reference", agent=agent, tags=tags, source="pinterest-downloads")

# Sort: curated refs first, then product SKUs, then characters, then generated (most recent first)
priority = {"brand-references": 0, "product-sku": 1, "brand-assets": 2, "character-vault": 3, "pinterest-downloads": 4, "brand-output": 5, "generated": 6, "creative-studio": 7}
catalog.sort(key=lambda x: (priority.get(x['source'], 9), -x['modified']))

# Write catalog
catalog_path = os.path.join(OPENCLAW, "workspace/data/ref-catalog.jsonl")
os.makedirs(os.path.dirname(catalog_path), exist_ok=True)
with open(catalog_path, 'w') as f:
    for entry in catalog:
        f.write(json.dumps(entry) + '\n')

# Summary
by_source = {}
by_brand = {}
for e in catalog:
    by_source[e['source']] = by_source.get(e['source'], 0) + 1
    b = e['brand'] or 'untagged'
    by_brand[b] = by_brand.get(b, 0) + 1

print(f"Cataloged {len(catalog)} reference images")
print(f"\nBy source:")
for s, c in sorted(by_source.items(), key=lambda x: -x[1]):
    print(f"  {s}: {c}")
print(f"\nBy brand:")
for b, c in sorted(by_brand.items(), key=lambda x: -x[1]):
    print(f"  {b}: {c}")
PYEOF

    log "Catalog rebuilt: $(wc -l < "$CATALOG_FILE" | tr -d ' ') entries"
    echo ""
    echo "Catalog: $CATALOG_FILE"
}

# ---------------------------------------------------------------------------
# browse — Search & list reference images
# ---------------------------------------------------------------------------
cmd_browse() {
    local brand="" img_type="" agent="" tag="" limit="20" query=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand)  brand="$2";    shift 2 ;;
            --type)   img_type="$2"; shift 2 ;;
            --agent)  agent="$2";    shift 2 ;;
            --tag)    tag="$2";      shift 2 ;;
            --limit)  limit="$2";    shift 2 ;;
            --query)  query="$2";    shift 2 ;;
            *) query="$1"; shift ;;
        esac
    done

    # Auto-catalog if missing
    if [ ! -f "$CATALOG_FILE" ]; then
        cmd_catalog
    fi

    python3 - "$brand" "$img_type" "$agent" "$tag" "$limit" "$query" << 'PYEOF'
import json, sys, os

brand_filter = sys.argv[1]
type_filter = sys.argv[2]
agent_filter = sys.argv[3]
tag_filter = sys.argv[4]
limit = int(sys.argv[5])
query = sys.argv[6].lower()

catalog_path = os.path.expanduser("~/.openclaw/workspace/data/ref-catalog.jsonl")
results = []

with open(catalog_path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        entry = json.loads(line)

        if brand_filter and entry['brand'] != brand_filter:
            continue
        if type_filter and entry['type'] != type_filter:
            continue
        if agent_filter and entry['agent'] != agent_filter:
            continue
        if tag_filter and tag_filter not in entry['tags']:
            continue
        if query:
            searchable = (entry['filename'] + ' ' + entry['brand'] + ' ' + entry['type'] + ' ' + entry['agent'] + ' ' + ' '.join(entry['tags'])).lower()
            if query not in searchable:
                continue

        results.append(entry)

if not results:
    print("No matching references found.")
    sys.exit(0)

# Group by source for display
print(f"Found {len(results)} references (showing top {limit}):\n")

shown = 0
for entry in results[:limit]:
    size_str = f"{entry['size_kb']}KB" if entry['size_kb'] < 1024 else f"{entry['size_kb']//1024}MB"
    tags_str = ', '.join(entry['tags'][:5])
    print(f"  [{entry['source'][:12]:12s}] {entry['brand'] or '?':14s} {entry['type']:15s} {size_str:>6s}  {entry['filename']}")
    if tags_str:
        print(f"  {'':12s}  tags: {tags_str}")
    print(f"  {'':12s}  path: {entry['path']}")
    print()
    shown += 1

if len(results) > limit:
    print(f"  ... and {len(results) - limit} more. Use --limit to see more.")
PYEOF
}

# ---------------------------------------------------------------------------
# pick — Auto-suggest best refs for a generation task (smart assemble_refs)
# ---------------------------------------------------------------------------
cmd_pick() {
    local brand="" use_case="" agent="" count="3" prompt_text=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand)     brand="$2";    shift 2 ;;
            --use-case)  use_case="$2"; shift 2 ;;
            --agent)     agent="$2";    shift 2 ;;
            --count)     count="$2";    shift 2 ;;
            --prompt)    prompt_text="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    [ -z "$brand" ] && die "pick: --brand required"

    # Auto-catalog if missing
    if [ ! -f "$CATALOG_FILE" ]; then
        cmd_catalog
    fi

    python3 - "$brand" "$use_case" "$agent" "$count" "$prompt_text" << 'PYEOF'
import json, sys, os, re

brand = sys.argv[1]
use_case = sys.argv[2].lower() if sys.argv[2] else ''
agent = sys.argv[3]
count = int(sys.argv[4])
prompt_text = sys.argv[5].lower() if len(sys.argv) > 5 else ''

catalog_path = os.path.expanduser("~/.openclaw/workspace/data/ref-catalog.jsonl")
entries = []
with open(catalog_path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        entries.append(json.loads(line))

# =========================================================================
# USE-CASE-TO-REF-TYPE MAPPING (the smart part)
# Each use case defines priority slots: what TYPE of ref to pick first,
# second, third. The assembler fills each slot with the best match.
# =========================================================================
USE_CASE_SLOTS = {
    'comparison': [
        {'role': 'product-sku', 'prefer_tags': ['top-view'], 'required': True},
        {'role': 'comparison-template', 'prefer_types': ['composition'], 'prefer_tags': ['comparison', 'comparison-template'], 'required': True},
        {'role': 'logo', 'prefer_types': ['logo', 'graphic'], 'prefer_tags': ['logo'], 'required': False},
    ],
    'hero': [
        {'role': 'product-sku', 'prefer_tags': ['top-view'], 'required': True},
        {'role': 'style-ref', 'prefer_types': ['style'], 'prefer_tags': ['bento', 'hero-shot', 'food-styling'], 'required': True},
        {'role': 'logo', 'prefer_types': ['logo', 'graphic'], 'prefer_tags': ['logo'], 'required': False},
    ],
    'lifestyle': [
        {'role': 'product-sku', 'prefer_tags': ['angle-view'], 'required': True},
        {'role': 'style-ref', 'prefer_types': ['style'], 'prefer_tags': ['food-styling', 'lifestyle', 'context'], 'required': False},
        {'role': 'composition-ref', 'prefer_types': ['composition'], 'prefer_tags': ['lifestyle', 'setting'], 'required': False},
    ],
    'product': [
        {'role': 'product-sku-topview', 'prefer_tags': ['top-view'], 'required': True},
        {'role': 'product-sku-angle', 'prefer_tags': ['angle-view'], 'required': True},
        {'role': 'logo', 'prefer_types': ['logo', 'graphic'], 'prefer_tags': ['logo'], 'required': False},
    ],
    'character': [
        {'role': 'confirmed-face', 'prefer_tags': ['confirmed-character', 'locked'], 'prefer_sources': ['pinterest-downloads', 'character-vault'], 'required': True},
        {'role': 'body-ref', 'prefer_tags': ['fullbody', 'attire-reference', 'character-sheet'], 'prefer_sources': ['character-vault', 'pinterest-downloads'], 'required': False},
    ],
    'beforeafter': [
        {'role': 'product-sku', 'prefer_tags': [], 'required': True},
        {'role': 'comparison-template', 'prefer_types': ['composition'], 'prefer_tags': ['comparison', 'comparison-template'], 'required': True},
        {'role': 'logo', 'prefer_types': ['logo', 'graphic'], 'prefer_tags': ['logo'], 'required': False},
    ],
    'recipe': [
        {'role': 'product-sku', 'prefer_tags': [], 'required': True},
        {'role': 'bento-composition', 'prefer_types': ['style'], 'prefer_tags': ['bento', 'food-styling', 'bento-style'], 'required': False},
    ],
    'grid': [
        {'role': 'product-sku-1', 'prefer_tags': ['top-view'], 'required': True, 'multi': True, 'multi_count': 4},
        {'role': 'logo', 'prefer_types': ['logo', 'graphic'], 'prefer_tags': ['logo'], 'required': False},
        {'role': 'brand-template', 'prefer_types': ['graphic', 'composition'], 'prefer_tags': ['brand-guide', 'layout'], 'required': False},
    ],
    'social': [
        {'role': 'style-ref', 'prefer_types': ['style'], 'prefer_tags': ['food-styling', 'lifestyle'], 'required': True},
        {'role': 'product-sku', 'prefer_tags': [], 'required': False},
        {'role': 'logo', 'prefer_types': ['logo', 'graphic'], 'prefer_tags': ['logo'], 'required': False},
    ],
    'testimonial': [
        {'role': 'style-ref', 'prefer_types': ['style'], 'prefer_tags': ['food-styling', 'hero-shot'], 'required': True},
        {'role': 'product-sku', 'prefer_tags': [], 'required': False},
        {'role': 'logo', 'prefer_types': ['logo', 'graphic'], 'prefer_tags': ['logo'], 'required': False},
    ],
}

# =========================================================================
# MIRRA dish name matching — extract dish from prompt or use case context
# =========================================================================
MIRRA_DISH_KEYWORDS = {
    'fusilli': 'fusilli-bolognese',
    'bolognese': 'fusilli-bolognese',
    'pad thai': 'konjac-pad-thai',
    'pad-thai': 'konjac-pad-thai',
    'padthai': 'konjac-pad-thai',
    'konjac': 'konjac-pad-thai',  # default konjac = pad thai unless curry mentioned
    'curry katsu': 'japanese-curry-katsu',
    'katsu': 'japanese-curry-katsu',
    'japanese curry': 'japanese-curry-katsu',
    'japanese-curry': 'japanese-curry-katsu',
    'bbq': 'bbq-pita-mushroom-wrap',
    'pita': 'bbq-pita-mushroom-wrap',
    'mushroom wrap': 'bbq-pita-mushroom-wrap',
    'mushroom-wrap': 'bbq-pita-mushroom-wrap',
    'burrito': 'fierry-buritto-bowl',
    'buritto': 'fierry-buritto-bowl',
    'fierry': 'fierry-buritto-bowl',
    'fragrant rice': 'golden-eryngii-fragrant-rice',
    'fragrant-rice': 'golden-eryngii-fragrant-rice',
    'eryngii': 'golden-eryngii-fragrant-rice',
    'golden eryngii': 'golden-eryngii-fragrant-rice',
    'classic curry': 'dry-classic-curry-konjac-noodle',
    'curry noodle': 'dry-classic-curry-konjac-noodle',
    'konjac noodle': 'dry-classic-curry-konjac-noodle',
    'dry classic': 'dry-classic-curry-konjac-noodle',
    'dry-classic': 'dry-classic-curry-konjac-noodle',
}

def detect_dish(prompt_text, use_case_text):
    """Detect which MIRRA dish is referenced in the prompt/use_case."""
    combined = (prompt_text + ' ' + use_case_text).lower()
    # Fix: konjac + curry should map to dry-classic-curry, not pad thai
    if 'konjac' in combined and ('curry' in combined or 'noodle' in combined):
        return 'dry-classic-curry-konjac-noodle'
    for keyword, dish_id in MIRRA_DISH_KEYWORDS.items():
        if keyword in combined:
            return dish_id
    return None

# =========================================================================
# GAIA OS character matching
# =========================================================================
CONFIRMED_CHAR_DIR = os.path.expanduser("~/Downloads/gaia os /confirm character")
ATTIRE_REF_DIR = os.path.expanduser("~/Downloads/gaia os /charactors reference")

AGENT_ALIASES = {
    'zenni': ['zenni', 'main'],
    'taoz': ['taoz'],
    'dreami': ['dreami'],
    'hermes': ['hermes'],
    'argus': ['argus'],
    'myrmidons': ['myrmidons'],
    'iris': ['iris'],
    'artemis': ['artemis'],
    'athena': ['athena'],
}

def detect_agent(prompt_text, agent_arg):
    """Detect which agent/character is referenced."""
    if agent_arg:
        return agent_arg.lower()
    text = prompt_text.lower()
    for canonical, aliases in AGENT_ALIASES.items():
        for alias in aliases:
            if alias in text:
                return canonical
    return None

# =========================================================================
# assemble_refs — The smart picker
# =========================================================================
def matches_brand(entry):
    """Check if entry matches the target brand."""
    if entry['brand'] == brand:
        return True
    if brand in ('gaia-os', 'gaiaos', 'gaia-eats') and entry['brand'] in ('gaia-os', 'gaiaos', 'gaia-eats'):
        return True
    return False

def score_for_slot(entry, slot, target_dish=None, target_agent=None):
    """Score how well an entry fits a specific slot requirement."""
    if not matches_brand(entry):
        return -1

    s = 0

    # Source quality base
    source_scores = {
        'brand-references': 50,
        'product-sku': 90,  # SKU photos are the best for product slots
        'brand-assets': 40,
        'character-vault': 80,
        'pinterest-downloads': 60,
        'brand-output': 10,
        'generated': 5,
        'creative-studio': 15,
    }
    s += source_scores.get(entry['source'], 5)

    # Role-specific scoring
    role = slot.get('role', '')

    # Product SKU slots: strongly prefer product-sku source
    if 'product-sku' in role:
        if entry['source'] == 'product-sku' or entry['type'] == 'product-sku':
            s += 200
        elif entry['type'] == 'product':
            s += 80
        else:
            s -= 50

        # View type preference
        prefer_tags = slot.get('prefer_tags', [])
        if 'top-view' in prefer_tags and 'top-view' in entry['tags']:
            s += 100
        if 'angle-view' in prefer_tags and 'angle-view' in entry['tags']:
            s += 100

        # Dish matching (critical for MIRRA)
        if target_dish:
            dish_tag = 'dish:' + target_dish
            if dish_tag in entry['tags']:
                s += 300  # Huge bonus for correct dish
            else:
                # Check fuzzy: dish words in tags
                dish_words = target_dish.split('-')
                matches = sum(1 for w in dish_words if any(w in t for t in entry['tags']))
                s += matches * 30
                if matches == 0:
                    s -= 100  # Penalize wrong dish

    # Logo slots
    elif 'logo' in role:
        if 'logo' in entry['tags'] or entry['type'] == 'logo':
            s += 300
            # Prefer logo-black for ad use cases
            if 'black' in entry['filename'].lower():
                s += 50
        else:
            return -1  # Not a logo, skip

    # Comparison template slots
    elif 'comparison-template' in role:
        if 'comparison' in entry['tags'] or 'comparison-template' in entry['tags']:
            s += 300
        elif entry['type'] == 'composition':
            s += 100
        else:
            s -= 100

    # Style/brand reference slots
    elif 'style-ref' in role:
        if entry['type'] == 'style':
            s += 200
        elif entry['type'] in ('composition', 'product'):
            s += 50
        # Tag matching
        for ptag in slot.get('prefer_tags', []):
            if ptag in entry['tags']:
                s += 40

    # Character slots
    elif 'confirmed-face' in role:
        if target_agent:
            # Check confirmed character directory
            if 'confirmed-character' in entry['tags'] and target_agent in entry.get('agent', '') or target_agent in entry['filename'].lower():
                s += 500
            elif 'locked' in entry['tags'] and (entry.get('agent', '') == target_agent or target_agent in entry['path'].lower()):
                s += 400
            elif entry.get('agent', '') == target_agent:
                s += 200
            else:
                s -= 200
        if 'confirmed-character' in entry['tags']:
            s += 100
        if 'locked' in entry['tags']:
            s += 80
        # Prefer front/face images and original locks
        fn = entry['filename'].lower()
        if 'front' in fn or 'face' in fn:
            s += 50
        # Locked v1 = the original face lock, highest priority
        if '-v1' in fn or 'locked-v1' in fn:
            s += 60
        # Penalize non-face references (storyboard, sheet, expressions = not a single face)
        if 'storyboard' in fn or 'sheet' in fn or 'expression' in fn or 'outfit' in fn:
            s -= 40

    elif 'body-ref' in role:
        if target_agent:
            if entry.get('agent', '') == target_agent or target_agent in entry['filename'].lower() or target_agent in entry['path'].lower():
                s += 200
            else:
                s -= 100
        if 'fullbody' in entry['tags']:
            s += 100
        if 'attire-reference' in entry['tags']:
            s += 80
        if 'character-sheet' in entry['tags']:
            s += 60

    # Composition/template slots
    elif 'composition' in role or 'template' in role or 'brand-template' in role:
        if entry['type'] in ('composition', 'graphic'):
            s += 100
        for ptag in slot.get('prefer_tags', []):
            if ptag in entry['tags']:
                s += 40

    # Bento composition slot
    elif 'bento' in role:
        if 'bento' in entry['tags'] or 'bento-style' in entry['tags']:
            s += 200
        if entry['type'] == 'style':
            s += 50

    # Preferred sources
    for psrc in slot.get('prefer_sources', []):
        if entry['source'] == psrc:
            s += 30

    # Preferred types
    for ptype in slot.get('prefer_types', []):
        if entry['type'] == ptype:
            s += 40

    # General tag matching
    for ptag in slot.get('prefer_tags', []):
        if ptag in entry['tags']:
            s += 20

    # Curated bonus
    if 'curated' in entry['tags']:
        s += 15

    return s


def assemble_refs(entries, use_case, agent_name, prompt_text, max_refs):
    """Smart ref assembly: fill slots by use case, not just generic scoring."""

    target_dish = detect_dish(prompt_text, use_case) if brand == 'mirra' else None
    target_agent = detect_agent(prompt_text, agent_name) if use_case == 'character' else None

    # Get slot definitions for this use case
    slots = USE_CASE_SLOTS.get(use_case, [])

    if not slots:
        # Fallback: generic scoring for unknown use cases
        return assemble_refs_generic(entries, use_case, agent_name, max_refs)

    results = []
    used_paths = set()
    used_hashes = set()  # Content-based dedup (same image in different dirs)
    used_dishes = set()  # Dish-level dedup (prevents duplicate foods in grid)
    slot_results = []

    for slot in slots:
        is_multi = slot.get('multi', False)
        multi_count = slot.get('multi_count', 1) if is_multi else 1

        # Score all entries for this slot
        scored = []
        for entry in entries:
            if entry['path'] in used_paths:
                continue
            # Content dedup: skip entries with same hash (same file copied elsewhere)
            if entry.get('hash', '') and entry['hash'] in used_hashes:
                continue
            s = score_for_slot(entry, slot, target_dish, target_agent)
            if s > 0:
                scored.append((s, entry))

        scored.sort(key=lambda x: -x[0])

        slot_picks = []
        pick_idx = 0
        while len(slot_picks) < multi_count and pick_idx < len(scored):
            s, entry = scored[pick_idx]
            pick_idx += 1
            # Skip content duplicates within the same multi-pick
            if entry.get('hash', '') and entry['hash'] in used_hashes:
                continue
            # Dish-level dedup for multi-product slots (grid, carousel)
            if is_multi and 'product-sku' in slot.get('role', ''):
                entry_dish = None
                for t in entry.get('tags', []):
                    if t.startswith('dish:'):
                        entry_dish = t[5:]
                        break
                # Fallback: extract dish from filename
                if not entry_dish:
                    fname = os.path.basename(entry['path']).lower()
                    for kw, dish_id in MIRRA_DISH_KEYWORDS.items():
                        if kw.replace(' ', '-') in fname or kw.replace(' ', '') in fname:
                            entry_dish = dish_id
                            break
                if entry_dish and entry_dish in used_dishes:
                    continue  # Skip — same dish already picked
                if entry_dish:
                    used_dishes.add(entry_dish)
            slot_picks.append((s, entry, slot['role']))
            used_paths.add(entry['path'])
            if entry.get('hash', ''):
                used_hashes.add(entry['hash'])

        slot_results.extend(slot_picks)

    # Trim to max_refs
    final = slot_results[:max_refs]

    return final, target_dish, target_agent


def assemble_refs_generic(entries, use_case, agent_name, max_refs):
    """Fallback generic scoring for unknown use cases."""
    scored = []
    for entry in entries:
        if not matches_brand(entry):
            continue
        s = 50  # base
        source_scores = {
            'brand-references': 80,
            'product-sku': 70,
            'brand-assets': 60,
            'character-vault': 50,
            'pinterest-downloads': 40,
            'brand-output': 20,
            'generated': 10,
            'creative-studio': 25,
        }
        s += source_scores.get(entry['source'], 5)
        if use_case:
            if entry['type'] == use_case:
                s += 60
            for tag in entry['tags']:
                if use_case in tag:
                    s += 15
        if agent_name and entry.get('agent', '') == agent_name:
            s += 40
        if 'curated' in entry['tags']:
            s += 20
        scored.append((s, entry))

    scored.sort(key=lambda x: -x[0])
    return [(s, e, 'generic') for s, e in scored[:max_refs]], None, None


# =========================================================================
# Main execution
# =========================================================================
result, target_dish, target_agent = assemble_refs(entries, use_case, agent, prompt_text, count)

if not result:
    print("NO_REFS")
    print(f"No reference images found for brand={brand}", file=sys.stderr)
    sys.exit(0)

# Output: paths for piping into nanobanana
paths = [e['path'] for _, e, _ in result]
print("REFS:" + ",".join(paths))
print()
print(f"Smart-picked {len(result)} refs for brand={brand} use_case={use_case}:")
if target_dish:
    print(f"  Detected dish: {target_dish}")
if target_agent:
    print(f"  Detected agent: {target_agent}")
print()
for s, e, role in result:
    print(f"  [{s:3d}] slot={role:20s} {e['type']:15s} {e['source']:15s} {e['filename']}")
    print(f"        {e['path']}")
PYEOF
}

# ---------------------------------------------------------------------------
# gallery — Generate HTML visual gallery for browsing
# ---------------------------------------------------------------------------
cmd_gallery() {
    local brand="" port="3848"
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand) brand="$2"; shift 2 ;;
            --port)  port="$2";  shift 2 ;;
            *) shift ;;
        esac
    done

    # Auto-catalog if missing
    if [ ! -f "$CATALOG_FILE" ]; then
        cmd_catalog
    fi

    mkdir -p "$GALLERY_DIR"

    python3 - "$brand" "$CATALOG_FILE" "$GALLERY_DIR" << 'PYEOF'
import json, sys, os, base64

brand_filter = sys.argv[1]
catalog_path = sys.argv[2]
gallery_dir = sys.argv[3]

entries = []
with open(catalog_path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        e = json.loads(line)
        if brand_filter and e['brand'] != brand_filter:
            continue
        entries.append(e)

# Get unique brands, types, agents, sources for filters
brands = sorted(set(e['brand'] for e in entries if e['brand']))
types = sorted(set(e['type'] for e in entries if e['type']))
agents = sorted(set(e['agent'] for e in entries if e['agent']))
sources = sorted(set(e['source'] for e in entries if e['source']))

# Generate gallery HTML
html = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>GAIA OS — Reference Image Gallery</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0a0a0a; color: #e0e0e0; }
.header { padding: 20px 24px; background: #111; border-bottom: 1px solid #222; display: flex; align-items: center; gap: 16px; flex-wrap: wrap; }
.header h1 { font-size: 18px; color: #fff; white-space: nowrap; }
.filters { display: flex; gap: 8px; flex-wrap: wrap; }
.filters select, .filters input { padding: 6px 10px; border-radius: 6px; border: 1px solid #333; background: #1a1a1a; color: #ccc; font-size: 13px; }
.filters input { width: 200px; }
.stats { padding: 8px 24px; background: #0d0d0d; border-bottom: 1px solid #1a1a1a; font-size: 12px; color: #666; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 16px; padding: 24px; }
.card { background: #151515; border-radius: 12px; overflow: hidden; border: 1px solid #222; transition: border-color 0.2s; cursor: pointer; }
.card:hover { border-color: #F7AB9F; }
.card.selected { border-color: #4CAF50; border-width: 2px; }
.card img { width: 100%; height: 200px; object-fit: cover; background: #0a0a0a; }
.card-info { padding: 12px; }
.card-info .filename { font-size: 12px; color: #999; word-break: break-all; margin-bottom: 4px; }
.card-info .meta { display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 6px; }
.card-info .tag { font-size: 10px; padding: 2px 6px; border-radius: 4px; background: #222; color: #888; }
.card-info .tag.brand { background: #1a2a1a; color: #8FBC8F; }
.card-info .tag.type { background: #2a1a2a; color: #D4A0D4; }
.card-info .tag.source { background: #1a1a2a; color: #A0A0D4; }
.card-info .path { font-size: 10px; color: #444; word-break: break-all; }
.card-info .copy-btn { font-size: 10px; padding: 2px 8px; border-radius: 4px; border: 1px solid #333; background: #1a1a1a; color: #888; cursor: pointer; margin-top: 6px; }
.card-info .copy-btn:hover { background: #333; color: #fff; }
.selected-bar { position: fixed; bottom: 0; left: 0; right: 0; background: #1a1a1a; border-top: 2px solid #4CAF50; padding: 12px 24px; display: none; align-items: center; gap: 12px; z-index: 100; }
.selected-bar.show { display: flex; }
.selected-bar .count { color: #4CAF50; font-weight: bold; }
.selected-bar button { padding: 8px 16px; border-radius: 6px; border: none; cursor: pointer; font-size: 13px; }
.selected-bar .copy-paths { background: #4CAF50; color: #fff; }
.selected-bar .clear { background: #333; color: #ccc; }
</style>
</head>
<body>
<div class="header">
  <h1>GAIA Ref Picker</h1>
  <div class="filters">
    <select id="f-brand"><option value="">All Brands</option>""" + "".join(f'<option value="{b}">{b}</option>' for b in brands) + """</select>
    <select id="f-type"><option value="">All Types</option>""" + "".join(f'<option value="{t}">{t}</option>' for t in types) + """</select>
    <select id="f-agent"><option value="">All Agents</option>""" + "".join(f'<option value="{a}">{a}</option>' for a in agents) + """</select>
    <select id="f-source"><option value="">All Sources</option>""" + "".join(f'<option value="{s}">{s}</option>' for s in sources) + """</select>
    <input type="text" id="f-search" placeholder="Search tags, filenames...">
  </div>
</div>
<div class="stats" id="stats">""" + f"{len(entries)} images cataloged" + """</div>
<div class="grid" id="grid"></div>
<div class="selected-bar" id="selbar">
  <span>Selected: <span class="count" id="sel-count">0</span></span>
  <button class="copy-paths" onclick="copySelected()">Copy Paths (for --ref-image)</button>
  <button class="clear" onclick="clearSelected()">Clear</button>
  <span id="copied-msg" style="color:#4CAF50;font-size:12px;display:none">Copied!</span>
</div>
<script>
const DATA = """ + json.dumps(entries, ensure_ascii=False) + """;
let selected = new Set();

function renderGrid() {
  const brand = document.getElementById('f-brand').value;
  const type = document.getElementById('f-type').value;
  const agent = document.getElementById('f-agent').value;
  const source = document.getElementById('f-source').value;
  const search = document.getElementById('f-search').value.toLowerCase();

  let filtered = DATA.filter(e => {
    if (brand && e.brand !== brand) return false;
    if (type && e.type !== type) return false;
    if (agent && e.agent !== agent) return false;
    if (source && e.source !== source) return false;
    if (search) {
      const hay = (e.filename + ' ' + e.brand + ' ' + e.type + ' ' + e.agent + ' ' + e.tags.join(' ')).toLowerCase();
      if (!hay.includes(search)) return false;
    }
    return true;
  });

  document.getElementById('stats').textContent = `Showing ${filtered.length} of ${DATA.length} images`;

  const grid = document.getElementById('grid');
  grid.innerHTML = filtered.slice(0, 200).map((e, i) => {
    const isSelected = selected.has(e.path);
    return `<div class="card ${isSelected ? 'selected' : ''}" data-path="${e.path}" onclick="toggleSelect('${e.path.replace(/'/g, "\\'")}', this)">
      <img src="file://${e.path}" loading="lazy" onerror="this.style.background='#222';this.alt='Preview unavailable'">
      <div class="card-info">
        <div class="filename">${e.filename}</div>
        <div class="meta">
          ${e.brand ? `<span class="tag brand">${e.brand}</span>` : ''}
          <span class="tag type">${e.type}</span>
          <span class="tag source">${e.source}</span>
          <span class="tag">${e.size_kb > 1024 ? Math.round(e.size_kb/1024) + 'MB' : e.size_kb + 'KB'}</span>
        </div>
        <div class="meta">${e.tags.slice(0, 6).map(t => `<span class="tag">${t}</span>`).join('')}</div>
        <div class="path">${e.path}</div>
        <button class="copy-btn" onclick="event.stopPropagation();copyPath('${e.path.replace(/'/g, "\\'")}')">Copy path</button>
      </div>
    </div>`;
  }).join('');
}

function toggleSelect(path, el) {
  if (selected.has(path)) {
    selected.delete(path);
    el.classList.remove('selected');
  } else {
    selected.add(path);
    el.classList.add('selected');
  }
  updateSelBar();
}

function updateSelBar() {
  const bar = document.getElementById('selbar');
  const count = document.getElementById('sel-count');
  count.textContent = selected.size;
  bar.classList.toggle('show', selected.size > 0);
}

function copySelected() {
  const paths = Array.from(selected).join(',');
  navigator.clipboard.writeText(paths).then(() => {
    const msg = document.getElementById('copied-msg');
    msg.style.display = 'inline';
    msg.textContent = `Copied ${selected.size} paths! Use with: --ref-image "${paths}"`;
    setTimeout(() => { msg.style.display = 'none'; }, 3000);
  });
}

function clearSelected() {
  selected.clear();
  updateSelBar();
  renderGrid();
}

function copyPath(path) {
  navigator.clipboard.writeText(path).then(() => {
    // brief visual feedback via alert replacement
  });
}

document.getElementById('f-brand').onchange = renderGrid;
document.getElementById('f-type').onchange = renderGrid;
document.getElementById('f-agent').onchange = renderGrid;
document.getElementById('f-source').onchange = renderGrid;
document.getElementById('f-search').oninput = renderGrid;

renderGrid();
</script>
</body>
</html>"""

output_path = os.path.join(gallery_dir, "index.html")
with open(output_path, 'w') as f:
    f.write(html)

print(f"Gallery generated: {output_path}")
print(f"Images: {len(entries)}")
PYEOF

    echo ""
    echo "Open in browser: file://$GALLERY_DIR/index.html"
    echo "Or serve: cd $GALLERY_DIR && python3 -m http.server $port"
}

# ---------------------------------------------------------------------------
# suggest — For a given NanoBanana command, auto-pick refs and enhance it
# ---------------------------------------------------------------------------
cmd_suggest() {
    local brand="" use_case="" prompt_text=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand)     brand="$2";       shift 2 ;;
            --use-case)  use_case="$2";    shift 2 ;;
            --prompt)    prompt_text="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    [ -z "$brand" ] && die "suggest: --brand required"
    [ -z "$use_case" ] && die "suggest: --use-case required"

    # Auto-catalog if needed
    if [ ! -f "$CATALOG_FILE" ]; then
        cmd_catalog >/dev/null 2>&1
    fi

    # Get top refs (pass prompt for dish/agent detection)
    local pick_output
    local pick_args="--brand $brand --use-case $use_case --count 3"
    if [ -n "$prompt_text" ]; then
        pick_output=$(cmd_pick --brand "$brand" --use-case "$use_case" --prompt "$prompt_text" --count 3 2>/dev/null)
    else
        pick_output=$(cmd_pick --brand "$brand" --use-case "$use_case" --count 3 2>/dev/null)
    fi
    local refs_line
    refs_line=$(echo "$pick_output" | grep "^REFS:" | sed 's/^REFS://')

    if [ -z "$refs_line" ]; then
        echo "# No refs found for brand=$brand. Generate without --ref-image."
        echo "bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \\"
        echo "  --brand $brand \\"
        echo "  --use-case $use_case \\"
        echo "  --prompt \"YOUR_PROMPT_HERE\" \\"
        echo "  --ratio 1:1 --size 2K --model flash"
        return
    fi

    echo "# Auto-suggested refs for $brand / $use_case:"
    echo "$pick_output" | grep -v "^REFS:"
    echo ""
    echo "# Ready-to-run command:"
    echo "bash /Users/jennwoeiloh/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \\"
    echo "  --brand $brand \\"
    echo "  --use-case $use_case \\"
    echo "  --prompt \"YOUR_PROMPT_HERE\" \\"
    echo "  --ref-image \"$refs_line\" \\"
    echo "  --ratio 1:1 --size 2K --model flash"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
usage() {
    echo "ref-picker.sh — Visual Reference Image Picker for GAIA OS"
    echo ""
    echo "Commands:"
    echo "  catalog [--force]                    Scan & index all image assets"
    echo "  browse [--brand X] [--type X] [--agent X] [--tag X] [--query X]"
    echo "                                       Search & list reference images"
    echo "  pick --brand X [--use-case X] [--agent X] [--prompt X] [--count N]"
    echo "                                       Smart-pick refs by use-case-to-ref-type mapping"
    echo "  suggest --brand X --use-case X [--prompt X]"
    echo "                                       Generate ready-to-run NanoBanana command"
    echo "  gallery [--brand X] [--port N]       Generate HTML gallery for visual browsing"
    echo ""
    echo "Examples:"
    echo "  ref-picker.sh catalog                # Build/refresh the catalog"
    echo "  ref-picker.sh browse --brand mirra   # List all MIRRA refs"
    echo "  ref-picker.sh browse --type character # List character refs"
    echo "  ref-picker.sh browse --tag locked    # List locked characters"
    echo "  ref-picker.sh pick --brand mirra --use-case comparison"
    echo "                                       # Auto-pick best refs for comparison ad"
    echo "  ref-picker.sh suggest --brand mirra --use-case lifestyle"
    echo "                                       # Generate NanoBanana command with refs"
    echo "  ref-picker.sh gallery                # Visual HTML gallery"
    echo "  ref-picker.sh gallery --brand mirra  # Gallery filtered to MIRRA"
}

case "${1:-}" in
    catalog)  shift; cmd_catalog "$@" ;;
    browse)   shift; cmd_browse "$@" ;;
    pick)     shift; cmd_pick "$@" ;;
    suggest)  shift; cmd_suggest "$@" ;;
    gallery)  shift; cmd_gallery "$@" ;;
    -h|--help|help|"") usage ;;
    *) die "Unknown command: $1. Run ref-picker.sh --help" ;;
esac
