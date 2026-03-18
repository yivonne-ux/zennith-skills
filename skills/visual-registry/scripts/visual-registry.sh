#!/usr/bin/env bash
# visual-registry.sh — Visual Asset Registry for GAIA OS
# Multi-angle SKU, model, scene registration + assembly engine
# Every product/character/scene gets angles → refs for consistent generation
# macOS Bash 3.2 compatible

set -euo pipefail

OPENCLAW_DIR="$HOME/.openclaw"
REGISTRY_FILE="$OPENCLAW_DIR/workspace/data/visual-registry.json"
BRANDS_DIR="$OPENCLAW_DIR/brands"
NANOBANANA="$OPENCLAW_DIR/skills/nanobanana/scripts/nanobanana-gen.sh"
LOG_FILE="$OPENCLAW_DIR/logs/visual-registry.log"

log() { mkdir -p "$(dirname "$LOG_FILE")"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }
die() { echo "ERROR: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# init — Create registry if not exists
# ---------------------------------------------------------------------------
ensure_registry() {
    if [ ! -f "$REGISTRY_FILE" ]; then
        mkdir -p "$(dirname "$REGISTRY_FILE")"
        python3 -c "
import json
registry = {
    'version': '1.0',
    'updated': '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
    'assets': [],
    'assemblies': []
}
with open('$REGISTRY_FILE', 'w') as f:
    json.dump(registry, f, indent=2)
print('Registry initialized: $REGISTRY_FILE')
"
    fi
}

# ---------------------------------------------------------------------------
# register — Register a visual asset with angles
# ---------------------------------------------------------------------------
cmd_register() {
    local name="" asset_type="" brand="" agent="" tags="" angles=""
    local sku="" description="" primary_image="" lock_status=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --name)          name="$2";          shift 2 ;;
            --type)          asset_type="$2";    shift 2 ;;
            --brand)         brand="$2";         shift 2 ;;
            --agent)         agent="$2";         shift 2 ;;
            --sku)           sku="$2";           shift 2 ;;
            --tags)          tags="$2";          shift 2 ;;
            --description)   description="$2";   shift 2 ;;
            --primary)       primary_image="$2"; shift 2 ;;
            --angles)        angles="$2";        shift 2 ;;
            --locked)        lock_status="locked";   shift ;;
            --unlocked)      lock_status="unlocked"; shift ;;
            *) die "register: unknown option: $1" ;;
        esac
    done

    [ -z "$name" ] && die "register: --name required"
    [ -z "$asset_type" ] && die "register: --type required (sku|model|scene|prop|character)"
    [ -z "$brand" ] && die "register: --brand required"

    ensure_registry

    python3 - "$name" "$asset_type" "$brand" "$agent" "$sku" "$tags" "$description" "$primary_image" "$angles" "$lock_status" << 'PYEOF'
import json, sys, os, hashlib, time

name = sys.argv[1]
asset_type = sys.argv[2]
brand = sys.argv[3]
agent = sys.argv[4]
sku = sys.argv[5]
tags_str = sys.argv[6]
description = sys.argv[7]
primary_image = sys.argv[8]
angles_str = sys.argv[9]
lock_status = sys.argv[10] if len(sys.argv) > 10 else ''

registry_path = os.path.expanduser("~/.openclaw/workspace/data/visual-registry.json")

with open(registry_path) as f:
    registry = json.load(f)

# Generate asset ID
asset_id = f"va-{hashlib.md5((name + brand + asset_type).encode()).hexdigest()[:8]}"

# Check if already exists
existing = [a for a in registry['assets'] if a['id'] == asset_id]
if existing:
    print(f"Asset already registered: {asset_id} ({name})")
    print(f"Use 'add-angle' to add more angles")
    sys.exit(0)

# Parse angles (comma-separated paths with optional labels)
angle_entries = []
if angles_str:
    for item in angles_str.split(','):
        item = item.strip()
        if not item:
            continue
        # Format: path or label:path
        if ':' in item and not item.startswith('/'):
            label, path = item.split(':', 1)
        else:
            path = item
            # Auto-label from filename
            fn = os.path.basename(path).lower()
            if 'front' in fn: label = 'front'
            elif 'side' in fn: label = 'side'
            elif 'back' in fn: label = 'back'
            elif 'top' in fn or 'topview' in fn: label = 'top-view'
            elif '3-4' in fn or '34' in fn or 'three-quarter' in fn: label = '3/4-view'
            elif 'profile' in fn: label = 'profile'
            elif 'detail' in fn: label = 'detail'
            elif 'fullbody' in fn or 'full-body' in fn: label = 'full-body'
            elif 'sheet' in fn: label = 'turnaround-sheet'
            elif 'locked' in fn: label = 'locked-ref'
            elif 'hero' in fn: label = 'hero'
            elif 'lifestyle' in fn: label = 'lifestyle-context'
            else: label = f'angle-{len(angle_entries)+1}'

        if os.path.isfile(path):
            size = os.path.getsize(path)
            # Get dimensions via sips if possible
            dims = None
            try:
                import subprocess
                r = subprocess.run(['sips', '--getProperty', 'pixelWidth', '--getProperty', 'pixelHeight', path],
                                   capture_output=True, text=True, timeout=5)
                lines = r.stdout.strip().split('\n')
                w = h = 0
                for l in lines:
                    if 'pixelWidth' in l: w = int(l.split(':')[-1].strip())
                    if 'pixelHeight' in l: h = int(l.split(':')[-1].strip())
                if w and h:
                    dims = f"{w}x{h}"
            except:
                pass

            angle_entries.append({
                'label': label,
                'path': os.path.abspath(path),
                'size_bytes': size,
                'dimensions': dims
            })

# Build asset entry
tags = [t.strip() for t in tags_str.split(',') if t.strip()] if tags_str else []
tags.append(asset_type)
tags.append(brand)

# Auto-tag based on type
if asset_type == 'sku':
    tags.extend(['product', 'reference'])
elif asset_type == 'character':
    tags.extend(['character', 'reference'])
elif asset_type == 'model':
    tags.extend(['person', 'reference'])
elif asset_type == 'scene':
    tags.extend(['background', 'setting'])
elif asset_type == 'prop':
    tags.extend(['element', 'reference'])

tags = list(set(tags))

asset = {
    'id': asset_id,
    'name': name,
    'type': asset_type,
    'brand': brand,
    'agent': agent or '',
    'sku': sku or '',
    'description': description or '',
    'tags': tags,
    'primary_image': os.path.abspath(primary_image) if primary_image and os.path.isfile(primary_image) else (angle_entries[0]['path'] if angle_entries else ''),
    'angles': angle_entries,
    'angle_count': len(angle_entries),
    'registered': time.strftime('%Y-%m-%dT%H:%M:%S+0800'),
    'locked': lock_status == 'locked' if lock_status else any('locked' in a['label'] for a in angle_entries),
    'lock_status': lock_status or ('locked' if any('locked' in a['label'] for a in angle_entries) else 'unlocked')
}

registry['assets'].append(asset)
registry['updated'] = time.strftime('%Y-%m-%dT%H:%M:%SZ')

with open(registry_path, 'w') as f:
    json.dump(registry, f, indent=2, ensure_ascii=False)

print(f"Registered: {asset_id}")
print(f"  Name:   {name}")
print(f"  Type:   {asset_type}")
print(f"  Brand:  {brand}")
print(f"  Angles: {len(angle_entries)}")
for a in angle_entries:
    d = f" ({a['dimensions']})" if a.get('dimensions') else ""
    print(f"    [{a['label']}] {os.path.basename(a['path'])}{d}")
PYEOF
}

# ---------------------------------------------------------------------------
# add-angle — Add more angles to an existing asset
# ---------------------------------------------------------------------------
cmd_add_angle() {
    local asset_id="" label="" image_path=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --id)    asset_id="$2";   shift 2 ;;
            --label) label="$2";      shift 2 ;;
            --image) image_path="$2"; shift 2 ;;
            *) die "add-angle: unknown option: $1" ;;
        esac
    done

    [ -z "$asset_id" ] && die "add-angle: --id required"
    [ -z "$image_path" ] && die "add-angle: --image required"
    [ ! -f "$image_path" ] && die "add-angle: image not found: $image_path"

    ensure_registry

    python3 - "$asset_id" "$label" "$image_path" << 'PYEOF'
import json, sys, os, subprocess

asset_id = sys.argv[1]
label = sys.argv[2] or f'angle-new'
image_path = os.path.abspath(sys.argv[3])

registry_path = os.path.expanduser("~/.openclaw/workspace/data/visual-registry.json")
with open(registry_path) as f:
    registry = json.load(f)

found = False
for asset in registry['assets']:
    if asset['id'] == asset_id:
        # Get dims
        dims = None
        try:
            r = subprocess.run(['sips', '--getProperty', 'pixelWidth', '--getProperty', 'pixelHeight', image_path],
                               capture_output=True, text=True, timeout=5)
            lines = r.stdout.strip().split('\n')
            w = h = 0
            for l in lines:
                if 'pixelWidth' in l: w = int(l.split(':')[-1].strip())
                if 'pixelHeight' in l: h = int(l.split(':')[-1].strip())
            if w and h: dims = f"{w}x{h}"
        except: pass

        angle = {
            'label': label,
            'path': image_path,
            'size_bytes': os.path.getsize(image_path),
            'dimensions': dims
        }
        asset['angles'].append(angle)
        asset['angle_count'] = len(asset['angles'])
        found = True
        print(f"Added angle [{label}] to {asset['name']} ({asset_id})")
        print(f"  Total angles: {asset['angle_count']}")
        break

if not found:
    print(f"ERROR: Asset not found: {asset_id}", file=sys.stderr)
    sys.exit(1)

with open(registry_path, 'w') as f:
    json.dump(registry, f, indent=2, ensure_ascii=False)
PYEOF
}

# ---------------------------------------------------------------------------
# gen-angles — Generate missing angles for an asset using NanoBanana
# ---------------------------------------------------------------------------
cmd_gen_angles() {
    local asset_id="" target_angles="front,3/4-left,3/4-right,side,top-view" dry_run="false"
    while [ $# -gt 0 ]; do
        case "$1" in
            --id)      asset_id="$2";      shift 2 ;;
            --angles)  target_angles="$2"; shift 2 ;;
            --dry-run) dry_run="true";     shift ;;
            *) shift ;;
        esac
    done

    [ -z "$asset_id" ] && die "gen-angles: --id required"
    ensure_registry

    # Get asset info
    local asset_json
    asset_json=$(python3 -c "
import json, os
with open(os.path.expanduser('~/.openclaw/workspace/data/visual-registry.json')) as f:
    reg = json.load(f)
for a in reg['assets']:
    if a['id'] == '$asset_id':
        print(json.dumps(a))
        break
else:
    print('NOT_FOUND')
" 2>/dev/null)

    if [ "$asset_json" = "NOT_FOUND" ]; then
        die "Asset not found: $asset_id"
    fi

    local name brand asset_type primary_image existing_labels
    name=$(echo "$asset_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['name'])")
    brand=$(echo "$asset_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['brand'])")
    asset_type=$(echo "$asset_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['type'])")
    primary_image=$(echo "$asset_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['primary_image'])")
    existing_labels=$(echo "$asset_json" | python3 -c "import json,sys; print(','.join(a['label'] for a in json.load(sys.stdin)['angles']))")

    echo "Generating missing angles for: $name ($asset_id)"
    echo "  Brand: $brand | Type: $asset_type"
    echo "  Existing angles: $existing_labels"
    echo "  Target angles: $target_angles"
    echo ""

    # Determine which angles are missing
    local IFS=','
    for angle in $target_angles; do
        angle=$(echo "$angle" | sed 's/^ *//;s/ *$//')
        if echo "$existing_labels" | grep -qi "$angle"; then
            echo "  [SKIP] $angle — already exists"
            continue
        fi

        echo "  [GEN]  $angle — generating..."

        # Build angle-specific prompt
        local angle_prompt=""
        case "$angle" in
            front)       angle_prompt="front-facing view, centered, direct eye contact or forward facing" ;;
            "3/4-left")  angle_prompt="three-quarter view from the left, slight angle showing depth" ;;
            "3/4-right") angle_prompt="three-quarter view from the right, slight angle showing depth" ;;
            side|profile) angle_prompt="side profile view, clean silhouette" ;;
            back)        angle_prompt="back view, showing rear details" ;;
            top-view)    angle_prompt="overhead top-down view, looking straight down" ;;
            detail)      angle_prompt="close-up detail shot, showing texture and fine details" ;;
            "full-body") angle_prompt="full body shot head to toe, standing pose" ;;
            action)      angle_prompt="dynamic action pose, showing movement and energy" ;;
            *)           angle_prompt="$angle view" ;;
        esac

        local full_prompt
        if [ "$asset_type" = "sku" ] || [ "$asset_type" = "product" ]; then
            full_prompt="Professional product photography of $name. $angle_prompt. Same product, same lighting, same style. Clean background, studio quality. Maintain exact product appearance and branding."
        elif [ "$asset_type" = "character" ] || [ "$asset_type" = "model" ]; then
            full_prompt="Character reference sheet: $name. $angle_prompt. Sacred Futurism aesthetic, photorealistic CG render. SAME character, SAME outfit, SAME colors. Maintain exact face and costume consistency. NOT cartoon. Dark background, cinematic lighting."
        elif [ "$asset_type" = "scene" ]; then
            full_prompt="Scene reference: $name. $angle_prompt. Same location, same lighting, same atmosphere. Consistent environment details."
        else
            full_prompt="$name — $angle_prompt. Maintain visual consistency with reference image."
        fi

        if [ "$dry_run" = "true" ]; then
            echo "    DRY RUN: Would generate with prompt: $full_prompt"
            echo "    Ref image: $primary_image"
            continue
        fi

        # Generate with NanoBanana using primary as ref
        local ref_arg=""
        if [ -n "$primary_image" ] && [ -f "$primary_image" ]; then
            ref_arg="--ref-image $primary_image"
        fi

        local output
        output=$(bash "$NANOBANANA" generate \
            --brand "$brand" \
            --use-case "character" \
            --prompt "$full_prompt" \
            --ratio "1:1" \
            --size "2K" \
            --model flash \
            $ref_arg 2>&1) || true

        # Extract generated path
        local gen_path
        gen_path=$(echo "$output" | grep "^/" | tail -1)
        if [ -n "$gen_path" ] && [ -f "$gen_path" ]; then
            echo "    Generated: $gen_path"
            # Register the new angle
            cmd_add_angle --id "$asset_id" --label "$angle" --image "$gen_path"
        else
            echo "    FAILED: $(echo "$output" | tail -3)"
        fi
    done

    echo ""
    echo "Done. Run 'visual-registry.sh info --id $asset_id' to see all angles."
}

# ---------------------------------------------------------------------------
# list — List all registered assets
# ---------------------------------------------------------------------------
cmd_list() {
    local brand="" asset_type="" query=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand) brand="$2";      shift 2 ;;
            --type)  asset_type="$2"; shift 2 ;;
            --query) query="$2";      shift 2 ;;
            *) query="$1"; shift ;;
        esac
    done

    ensure_registry

    python3 - "$brand" "$asset_type" "$query" << 'PYEOF'
import json, sys, os

brand_f = sys.argv[1]
type_f = sys.argv[2]
query = sys.argv[3].lower()

with open(os.path.expanduser("~/.openclaw/workspace/data/visual-registry.json")) as f:
    registry = json.load(f)

assets = registry['assets']
if brand_f:
    assets = [a for a in assets if a['brand'] == brand_f]
if type_f:
    assets = [a for a in assets if a['type'] == type_f]
if query:
    assets = [a for a in assets if query in (a['name'] + ' ' + a['brand'] + ' ' + ' '.join(a['tags'])).lower()]

if not assets:
    print("No assets found.")
    sys.exit(0)

print(f"{'ID':<14s} {'Type':<10s} {'Brand':<14s} {'Angles':<7s} {'Locked':<7s} Name")
print("-" * 80)
for a in assets:
    lock = "YES" if a.get('locked') else ""
    print(f"{a['id']:<14s} {a['type']:<10s} {a['brand']:<14s} {a['angle_count']:<7d} {lock:<7s} {a['name']}")
PYEOF
}

# ---------------------------------------------------------------------------
# info — Show full details of an asset
# ---------------------------------------------------------------------------
cmd_info() {
    local asset_id=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --id) asset_id="$2"; shift 2 ;;
            *) asset_id="$1"; shift ;;
        esac
    done

    [ -z "$asset_id" ] && die "info: --id required"
    ensure_registry

    python3 - "$asset_id" << 'PYEOF'
import json, sys, os

asset_id = sys.argv[1]
with open(os.path.expanduser("~/.openclaw/workspace/data/visual-registry.json")) as f:
    registry = json.load(f)

for a in registry['assets']:
    if a['id'] == asset_id:
        print(f"Asset: {a['name']} ({a['id']})")
        print(f"  Type:        {a['type']}")
        print(f"  Brand:       {a['brand']}")
        print(f"  Agent:       {a.get('agent', '-')}")
        print(f"  SKU:         {a.get('sku', '-')}")
        print(f"  Description: {a.get('description', '-')}")
        print(f"  Tags:        {', '.join(a['tags'])}")
        print(f"  Locked:      {'YES' if a.get('locked') else 'no'}")
        print(f"  Registered:  {a.get('registered', '-')}")
        print(f"  Primary:     {a.get('primary_image', '-')}")
        print(f"\n  Angles ({a['angle_count']}):")
        for ang in a['angles']:
            d = f" ({ang['dimensions']})" if ang.get('dimensions') else ""
            s = f" {ang['size_bytes']//1024}KB" if ang.get('size_bytes') else ""
            print(f"    [{ang['label']:15s}] {os.path.basename(ang['path'])}{d}{s}")
            print(f"                    {ang['path']}")
        sys.exit(0)

print(f"Asset not found: {asset_id}", file=sys.stderr)
sys.exit(1)
PYEOF
}

# ---------------------------------------------------------------------------
# assemble — Compose refs from SKU x Model x Scene for generation
# ---------------------------------------------------------------------------
cmd_assemble() {
    local sku_id="" model_id="" scene_id="" max_refs="14" output_mode="refs"
    while [ $# -gt 0 ]; do
        case "$1" in
            --sku)      sku_id="$2";    shift 2 ;;
            --model)    model_id="$2";  shift 2 ;;
            --scene)    scene_id="$2";  shift 2 ;;
            --max-refs) max_refs="$2";  shift 2 ;;
            --command)  output_mode="command"; shift ;;
            *) shift ;;
        esac
    done

    ensure_registry

    python3 - "$sku_id" "$model_id" "$scene_id" "$max_refs" "$output_mode" << 'PYEOF'
import json, sys, os

sku_id = sys.argv[1]
model_id = sys.argv[2]
scene_id = sys.argv[3]
max_refs = int(sys.argv[4])
output_mode = sys.argv[5]

with open(os.path.expanduser("~/.openclaw/workspace/data/visual-registry.json")) as f:
    registry = json.load(f)

def find_asset(aid):
    if not aid:
        return None
    for a in registry['assets']:
        if a['id'] == aid or a['name'].lower() == aid.lower():
            return a
    return None

sku = find_asset(sku_id)
model = find_asset(model_id)
scene = find_asset(scene_id)

# Collect refs with priority: primary images first, then best angles
refs = []
brands = set()

def add_refs(asset, priority_labels=None):
    if not asset:
        return
    brands.add(asset['brand'])
    # Primary image first
    if asset.get('primary_image') and os.path.isfile(asset['primary_image']):
        refs.append(asset['primary_image'])
    # Then angles by priority
    if priority_labels:
        for label in priority_labels:
            for ang in asset['angles']:
                if label in ang['label'].lower() and ang['path'] not in refs:
                    refs.append(ang['path'])
    # Remaining angles
    for ang in asset['angles']:
        if ang['path'] not in refs:
            refs.append(ang['path'])

# SKU gets most refs (product consistency is key)
add_refs(sku, ['front', 'hero', '3/4', 'top', 'detail'])
# Model/character gets face + body refs
add_refs(model, ['locked', 'front', 'full-body', '3/4'])
# Scene gets 1-2 refs
add_refs(scene, ['hero', 'front'])

# Trim to max
refs = refs[:max_refs]

# Dedup
seen = set()
unique_refs = []
for r in refs:
    if r not in seen:
        seen.add(r)
        unique_refs.append(r)
refs = unique_refs

if not refs:
    print("NO_REFS — no registered angles found for the given assets")
    sys.exit(1)

brand = list(brands)[0] if brands else 'gaia-eats'

if output_mode == 'command':
    refs_str = ','.join(refs)
    print(f"bash ~/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \\")
    print(f"  --brand {brand} \\")
    print(f"  --use-case product \\")
    print(f"  --prompt \"YOUR_PROMPT_HERE\" \\")
    print(f"  --ref-image \"{refs_str}\" \\")
    print(f"  --ratio 1:1 --size 2K --model flash")
else:
    print(f"ASSEMBLY: {len(refs)} refs from {len(brands)} brand(s)")
    print(f"  SKU:   {sku['name'] if sku else '-'} ({len(sku['angles']) if sku else 0} angles)")
    print(f"  Model: {model['name'] if model else '-'} ({len(model['angles']) if model else 0} angles)")
    print(f"  Scene: {scene['name'] if scene else '-'} ({len(scene['angles']) if scene else 0} angles)")
    print(f"\n  Ref images ({len(refs)}, max {max_refs}):")
    for i, r in enumerate(refs):
        print(f"    {i+1}. {os.path.basename(r)}")
        print(f"       {r}")
    print(f"\n  REFS:{','.join(refs)}")
PYEOF
}

# ---------------------------------------------------------------------------
# scan — Auto-discover and register assets from existing files
# ---------------------------------------------------------------------------
cmd_scan() {
    local brand="" dry_run="false"
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand)   brand="$2";     shift 2 ;;
            --dry-run) dry_run="true"; shift ;;
            *) shift ;;
        esac
    done

    ensure_registry

    echo "Scanning for unregistered visual assets..."

    python3 - "$brand" "$dry_run" << 'PYEOF'
import json, sys, os, hashlib, subprocess, time

brand_filter = sys.argv[1]
dry_run = sys.argv[2] == 'true'

OPENCLAW = os.path.expanduser("~/.openclaw")
registry_path = os.path.join(OPENCLAW, "workspace/data/visual-registry.json")

with open(registry_path) as f:
    registry = json.load(f)

# Get already-registered paths
registered_paths = set()
for asset in registry['assets']:
    registered_paths.add(asset.get('primary_image', ''))
    for ang in asset.get('angles', []):
        registered_paths.add(ang['path'])

new_assets = []

def get_dims(path):
    try:
        r = subprocess.run(['sips', '--getProperty', 'pixelWidth', '--getProperty', 'pixelHeight', path],
                           capture_output=True, text=True, timeout=5)
        w = h = 0
        for l in r.stdout.strip().split('\n'):
            if 'pixelWidth' in l: w = int(l.split(':')[-1].strip())
            if 'pixelHeight' in l: h = int(l.split(':')[-1].strip())
        return f"{w}x{h}" if w and h else None
    except:
        return None

def make_id(name, brand, atype):
    return f"va-{hashlib.md5((name + brand + atype).encode()).hexdigest()[:8]}"

# --- 1. Character vault → character assets ---
chars_dir = os.path.join(OPENCLAW, "workspace/data/characters")
if os.path.isdir(chars_dir):
    for agent_name in os.listdir(chars_dir):
        agent_path = os.path.join(chars_dir, agent_name)
        if not os.path.isdir(agent_path):
            continue
        if brand_filter and brand_filter not in ('gaia-os', 'gaia-eats', agent_name):
            continue

        images = []
        for fn in sorted(os.listdir(agent_path)):
            fp = os.path.join(agent_path, fn)
            if not os.path.isfile(fp):
                continue
            ext = fn.rsplit('.', 1)[-1].lower()
            if ext not in ('png', 'jpg', 'jpeg', 'webp'):
                continue
            if '_web.' in fn or '.bak' in fn:
                continue
            images.append(fp)

        if not images:
            continue

        # Check if already registered
        aid = make_id(f"Character: {agent_name.title()}", "gaia-os", "character")
        if any(a['id'] == aid for a in registry['assets']):
            continue

        angles = []
        primary = None
        for img in images:
            fn = os.path.basename(img).lower()
            if 'locked-v1' in fn or ('locked' in fn and 'v2' not in fn and 'sheet' not in fn and 'fullbody' not in fn and 'storyboard' not in fn):
                label = 'locked-ref'
                if not primary:
                    primary = img
            elif 'locked-v2' in fn:
                label = 'locked-v2'
            elif 'fullbody' in fn or 'full-body' in fn:
                label = 'full-body'
            elif 'sheet' in fn or '9angle' in fn:
                label = 'turnaround-sheet'
            elif 'storyboard' in fn:
                label = 'storyboard'
            elif 'expression' in fn:
                label = 'expressions'
            elif 'casual' in fn:
                label = 'casual-outfit'
            elif 'formal' in fn:
                label = 'formal-outfit'
            elif 'mission' in fn or 'work' in fn:
                label = 'work-mission'
            elif 'accessories' in fn:
                label = 'accessories'
            elif 'color' in fn and 'palette' in fn:
                label = 'color-palette'
            elif 'front' in fn:
                label = 'front'
            elif 'side' in fn:
                label = 'side'
            elif 'profile' in fn:
                label = 'profile'
            elif 'action' in fn:
                label = 'action'
            else:
                label = f'view-{len(angles)+1}'

            dims = get_dims(img) if len(images) < 20 else None
            angles.append({
                'label': label,
                'path': img,
                'size_bytes': os.path.getsize(img),
                'dimensions': dims
            })

        if not primary and angles:
            primary = angles[0]['path']

        tags = ['character', 'gaia-os', agent_name]
        if any('locked' in a['label'] for a in angles):
            tags.append('locked')

        asset = {
            'id': aid,
            'name': f"Character: {agent_name.title()}",
            'type': 'character',
            'brand': 'gaia-os',
            'agent': agent_name,
            'sku': '',
            'description': f"GAIA OS agent character — {agent_name.title()}",
            'tags': tags,
            'primary_image': primary or '',
            'angles': angles,
            'angle_count': len(angles),
            'registered': time.strftime('%Y-%m-%dT%H:%M:%S+0800'),
            'locked': any('locked' in a['label'] for a in angles)
        }
        new_assets.append(asset)

# --- 2. Brand references → product/style assets ---
brands_dir = os.path.join(OPENCLAW, "brands")
if os.path.isdir(brands_dir):
    for brand_name in os.listdir(brands_dir):
        if brand_filter and brand_name != brand_filter:
            continue
        brand_path = os.path.join(brands_dir, brand_name)
        refs_dir = os.path.join(brand_path, "references")
        assets_dir = os.path.join(brand_path, "assets")

        # Scan assets folder
        for scan_dir, source_name in [(refs_dir, "reference"), (assets_dir, "asset")]:
            if not os.path.isdir(scan_dir):
                continue
            images = []
            for root, dirs, files in os.walk(scan_dir):
                for fn in files:
                    ext = fn.rsplit('.', 1)[-1].lower()
                    if ext in ('png', 'jpg', 'jpeg', 'webp') and '_web.' not in fn:
                        images.append(os.path.join(root, fn))

            if not images:
                continue

            # Group by type hints
            products = [i for i in images if any(k in os.path.basename(i).lower() for k in ['product', 'carbonara', 'fusilli', 'tortilla', 'bento', 'food'])]
            logos = [i for i in images if any(k in os.path.basename(i).lower() for k in ['logo'])]
            styles = [i for i in images if any(k in os.path.basename(i).lower() for k in ['style', 'ref-', 'topview'])]
            compositions = [i for i in images if any(k in os.path.basename(i).lower() for k in ['comparison', 'template', 'layout'])]

            # Register product group
            if products:
                aid = make_id(f"{brand_name} Product Refs", brand_name, "sku")
                if not any(a['id'] == aid for a in registry['assets']):
                    angles = [{'label': f'product-{j+1}', 'path': p, 'size_bytes': os.path.getsize(p), 'dimensions': get_dims(p)} for j, p in enumerate(products)]
                    new_assets.append({
                        'id': aid, 'name': f"{brand_name.title()} Product References",
                        'type': 'sku', 'brand': brand_name, 'agent': '', 'sku': brand_name,
                        'description': f"Product reference photos for {brand_name}",
                        'tags': ['product', 'sku', brand_name, 'reference'],
                        'primary_image': products[0], 'angles': angles,
                        'angle_count': len(angles),
                        'registered': time.strftime('%Y-%m-%dT%H:%M:%S+0800'),
                        'locked': False
                    })

            # Register compositions as scene/templates
            if compositions:
                aid = make_id(f"{brand_name} Composition Templates", brand_name, "scene")
                if not any(a['id'] == aid for a in registry['assets']):
                    angles = [{'label': f'template-{j+1}', 'path': p, 'size_bytes': os.path.getsize(p), 'dimensions': get_dims(p)} for j, p in enumerate(compositions)]
                    new_assets.append({
                        'id': aid, 'name': f"{brand_name.title()} Composition Templates",
                        'type': 'scene', 'brand': brand_name, 'agent': '', 'sku': '',
                        'description': f"Layout/composition templates for {brand_name}",
                        'tags': ['composition', 'template', 'scene', brand_name],
                        'primary_image': compositions[0], 'angles': angles,
                        'angle_count': len(angles),
                        'registered': time.strftime('%Y-%m-%dT%H:%M:%S+0800'),
                        'locked': False
                    })

# --- 3. Confirmed characters from Downloads ---
confirm_dir = os.path.expanduser("~/Downloads/gaia os /confirm character")
if os.path.isdir(confirm_dir):
    images = []
    for fn in os.listdir(confirm_dir):
        fp = os.path.join(confirm_dir, fn)
        if os.path.isfile(fp) and fn.rsplit('.', 1)[-1].lower() in ('png', 'jpg', 'jpeg', 'webp'):
            images.append(fp)

    if images:
        aid = make_id("Jenn Confirmed Characters", "gaia-os", "character")
        if not any(a['id'] == aid for a in registry['assets']):
            angles = []
            for img in images:
                fn = os.path.basename(img).lower()
                label = 'confirmed'
                for agent in ['zenni', 'taoz', 'dreami', 'hermes', 'iris', 'artemis', 'athena', 'argus', 'myrmidons']:
                    if agent in fn:
                        label = f'confirmed-{agent}'
                        break
                angles.append({'label': label, 'path': img, 'size_bytes': os.path.getsize(img), 'dimensions': None})

            new_assets.append({
                'id': aid, 'name': "Jenn Confirmed Characters",
                'type': 'character', 'brand': 'gaia-os', 'agent': '', 'sku': '',
                'description': "Jenn-approved character designs for GAIA OS agents",
                'tags': ['character', 'confirmed', 'approved-by-jenn', 'gaia-os'],
                'primary_image': images[0], 'angles': angles,
                'angle_count': len(angles),
                'registered': time.strftime('%Y-%m-%dT%H:%M:%S+0800'),
                'locked': True
            })

# --- 4. Attire references ---
attire_dir = os.path.expanduser("~/Downloads/gaia os /charactors reference")
if os.path.isdir(attire_dir):
    images = []
    for fn in os.listdir(attire_dir):
        fp = os.path.join(attire_dir, fn)
        if os.path.isfile(fp) and fn.rsplit('.', 1)[-1].lower() in ('png', 'jpg', 'jpeg', 'webp'):
            images.append(fp)

    if images:
        aid = make_id("Pinterest Attire References", "gaia-os", "prop")
        if not any(a['id'] == aid for a in registry['assets']):
            angles = [{'label': f'attire-{j+1}', 'path': p, 'size_bytes': os.path.getsize(p), 'dimensions': None} for j, p in enumerate(images)]
            new_assets.append({
                'id': aid, 'name': "Pinterest Attire References",
                'type': 'prop', 'brand': 'gaia-os', 'agent': '', 'sku': '',
                'description': "Pinterest costume/attire references for GAIA OS agents",
                'tags': ['prop', 'attire', 'pinterest', 'reference', 'costume', 'gaia-os'],
                'primary_image': images[0], 'angles': angles,
                'angle_count': len(angles),
                'registered': time.strftime('%Y-%m-%dT%H:%M:%S+0800'),
                'locked': False
            })

# Add new assets
if dry_run:
    print(f"\nDRY RUN — Would register {len(new_assets)} assets:")
    for a in new_assets:
        print(f"  {a['id']} | {a['type']:<10s} | {a['brand']:<14s} | {a['angle_count']} angles | {a['name']}")
else:
    registry['assets'].extend(new_assets)
    registry['updated'] = time.strftime('%Y-%m-%dT%H:%M:%SZ')
    with open(registry_path, 'w') as f:
        json.dump(registry, f, indent=2, ensure_ascii=False)
    print(f"\nRegistered {len(new_assets)} new assets:")
    for a in new_assets:
        print(f"  {a['id']} | {a['type']:<10s} | {a['brand']:<14s} | {a['angle_count']} angles | {a['name']}")

total = len(registry['assets']) + (len(new_assets) if dry_run else 0)
print(f"\nTotal assets in registry: {total}")
PYEOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
usage() {
    cat << 'EOF'
visual-registry.sh — Visual Asset Registry for GAIA OS

Register SKUs, characters, models, scenes with multi-angle refs.
Assemble refs for consistent generation: SKU x Model x Scene → refs.

Commands:
  register    Register a new visual asset with angles
  add-angle   Add an angle to an existing asset
  gen-angles  Generate missing angles via NanoBanana
  list        List all registered assets
  info        Show full details of an asset
  assemble    Compose refs from SKU x Model x Scene
  scan        Auto-discover and register from existing files

Examples:
  # Auto-scan and register everything
  visual-registry.sh scan

  # Register a specific SKU
  visual-registry.sh register --name "MIRRA Fusilli Carbonara" --type sku \
    --brand mirra --sku fusilli-carbonara \
    --angles "front:/path/front.png,top:/path/top.png,side:/path/side.png"

  # Generate missing angles for a character
  visual-registry.sh gen-angles --id va-abc12345 --angles "front,3/4-left,side,back"

  # Assemble refs for a shoot: product + character + scene
  visual-registry.sh assemble --sku va-abc --model va-def --scene va-ghi

  # Get ready-to-paste NanoBanana command
  visual-registry.sh assemble --sku va-abc --model va-def --command
EOF
}

case "${1:-}" in
    register)   shift; cmd_register "$@" ;;
    add-angle)  shift; cmd_add_angle "$@" ;;
    gen-angles) shift; cmd_gen_angles "$@" ;;
    list)       shift; cmd_list "$@" ;;
    info)       shift; cmd_info "$@" ;;
    assemble)   shift; cmd_assemble "$@" ;;
    scan)       shift; cmd_scan "$@" ;;
    -h|--help|help|"") usage ;;
    *) die "Unknown command: $1" ;;
esac
