#!/usr/bin/env bash
# campaign-planner.sh — Generate ad campaign briefs from templates + directions
# Part of GAIA CORP-OS MIRRA Content Factory
#
# Usage:
#   campaign-planner.sh create --brand mirra --direction en-1 --template-type M2 --variants 5 --week 10
#   campaign-planner.sh directions --brand mirra [--lang en|cn]
#   campaign-planner.sh full-campaign --brand mirra --direction en-1 --mofu-sets "M1,M2,M3" --bofu-sets "B1,B2"
#   campaign-planner.sh list --brand mirra [--status brief|copy|visual|qa|published]
#
# macOS bash 3.2 compatible. No declare -A.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRANDS_DIR="$HOME/.openclaw/brands"
TRACKER_FILE="$HOME/.openclaw/workspace/data/campaign-tracker.jsonl"
ROOMS_DIR="$HOME/.openclaw/workspace/rooms"
EXEC_ROOM="$ROOMS_DIR/exec.jsonl"

# --- Logging ---
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2; }
err() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }

# --- Post to room ---
post_to_room() {
    local room_file="$1" agent="$2" msg="$3"
    local ts
    ts="$(date +%s)000"
    printf '{"ts":%s,"agent":"%s","msg":"%s"}\n' "$ts" "$agent" "$msg" >> "$room_file"
}

# --- Check dependencies ---
check_deps() {
    local brand="$1"
    local brand_dir="$BRANDS_DIR/$brand"

    if [ ! -d "$brand_dir" ]; then
        err "Brand directory not found: $brand_dir"
        exit 1
    fi
    if [ ! -f "$brand_dir/templates/templates.json" ]; then
        err "Templates not found: $brand_dir/templates/templates.json"
        exit 1
    fi
    if [ ! -f "$brand_dir/campaigns/directions.json" ]; then
        err "Directions not found: $brand_dir/campaigns/directions.json"
        exit 1
    fi
    if ! command -v python3 >/dev/null 2>&1; then
        err "python3 required"
        exit 1
    fi
}

# --- Command: directions ---
cmd_directions() {
    local brand="" lang=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand) brand="$2"; shift 2 ;;
            --lang)  lang="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    brand="${brand:-mirra}"
    check_deps "$brand"

    local dir_file="$BRANDS_DIR/$brand/campaigns/directions.json"

    python3 - "$dir_file" "$lang" << 'PYEOF'
import json, sys

dir_file = sys.argv[1]
lang_filter = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else ""

with open(dir_file) as f:
    data = json.load(f)

print("=" * 60)
print(f" Available Campaign Directions")
print("=" * 60)

for lang_key in ["en", "cn"]:
    if lang_filter and lang_filter != lang_key:
        continue
    directions = data.get(lang_key, [])
    if not directions:
        continue
    print(f"\n{'EN' if lang_key == 'en' else 'CN'} Directions:")
    print("-" * 40)
    for d in directions:
        did = d["id"]
        name = d["name"]
        short = d.get("short_name", "")
        funnel = d.get("funnel_focus", "")
        headlines_count = 0
        if "headlines" in d:
            if isinstance(d["headlines"], list):
                headlines_count = len(d["headlines"])
            elif isinstance(d["headlines"], dict):
                for v in d["headlines"].values():
                    headlines_count += len(v)
        personas = ""
        if "personas" in d:
            personas = f", {len(d['personas'])} personas"
        elif "persona" in d:
            personas = f", 1 persona"
        print(f"  {did:8s} | {name[:35]:35s} | {funnel:15s} | {headlines_count} headlines{personas}")

print()
print("=" * 60)
PYEOF
}

# --- Command: create ---
cmd_create() {
    local brand="" direction="" template_type="" variants=5 week=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand)          brand="$2"; shift 2 ;;
            --direction)      direction="$2"; shift 2 ;;
            --template-type)  template_type="$2"; shift 2 ;;
            --variants)       variants="$2"; shift 2 ;;
            --week)           week="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    brand="${brand:-mirra}"
    week="${week:-$(date '+%V' | sed 's/^0//')}"

    if [ -z "$direction" ] || [ -z "$template_type" ]; then
        err "Required: --direction and --template-type"
        echo "Usage: campaign-planner.sh create --brand mirra --direction en-1 --template-type M2 [--variants 5] [--week 10]"
        exit 1
    fi

    check_deps "$brand"

    local dir_file="$BRANDS_DIR/$brand/campaigns/directions.json"
    local tmpl_file="$BRANDS_DIR/$brand/templates/templates.json"
    local dna_file="$BRANDS_DIR/$brand/DNA.json"

    mkdir -p "$(dirname "$TRACKER_FILE")"

    python3 - "$dir_file" "$tmpl_file" "$dna_file" "$direction" "$template_type" "$variants" "$week" "$brand" "$TRACKER_FILE" << 'PYEOF'
import json, sys, os, hashlib, time, random

dir_file = sys.argv[1]
tmpl_file = sys.argv[2]
dna_file = sys.argv[3]
direction_id = sys.argv[4]
template_type = sys.argv[5].upper()
num_variants = int(sys.argv[6])
week = sys.argv[7]
brand = sys.argv[8]
tracker_file = sys.argv[9]

# Load files
with open(dir_file) as f:
    dirs = json.load(f)
with open(tmpl_file) as f:
    tmpls = json.load(f)
with open(dna_file) as f:
    dna = json.load(f)

# Find direction
direction = None
lang = direction_id.split("-")[0]
for d in dirs.get(lang, []):
    if d["id"] == direction_id:
        direction = d
        break

if not direction:
    print(f"ERROR: Direction '{direction_id}' not found", file=sys.stderr)
    sys.exit(1)

# Find template type
tmpl_def = tmpls.get("template_types", {}).get(template_type)
if not tmpl_def:
    print(f"ERROR: Template type '{template_type}' not found", file=sys.stderr)
    sys.exit(1)

# Determine funnel from template type
funnel = tmpl_def["funnel"]

# Get headlines
headlines = []
if isinstance(direction.get("headlines"), list):
    headlines = direction["headlines"]
elif isinstance(direction.get("headlines"), dict):
    # CN directions have headlines by funnel
    funnel_key = funnel.lower()
    headlines = direction["headlines"].get(funnel_key, [])
    if not headlines:
        # Fallback: collect all
        for v in direction["headlines"].values():
            headlines.extend(v)

if not headlines:
    print(f"WARNING: No headlines found for {direction_id} / {funnel}", file=sys.stderr)
    headlines = [f"MIRRA {direction.get('name', '')} — Ad Variant"]

# Get persona info
persona_label = ""
if "persona" in direction:
    p = direction["persona"]
    persona_label = p.get("label", "")
elif "personas" in direction:
    personas = direction["personas"]
    persona_label = ", ".join([p["name"] for p in personas[:3]]) + ("..." if len(personas) > 3 else "")

# Get char limits
char_limits = tmpl_def.get("char_limits", {})
headline_max = char_limits.get("headline", {}).get("max", 50)
subcopy_max = char_limits.get("subcopy", {}).get("max", 90)

# MIRRA menu dishes (for rotation)
dishes = [
    "Carbonara Fusilli Bento", "Thai Basil Chicken Bento", "Pumpkin Rendang Bowl",
    "Green Curry Chickpea", "Teriyaki Salmon Bento", "Korean Bibimbap Bowl",
    "Mediterranean Quinoa", "Japanese Miso Tofu", "Malaysian Nasi Lemak (Lite)",
    "Tom Yum Prawn Bento", "Black Pepper Chicken", "Mushroom Risotto Bowl",
    "Grilled Fish Bento", "Veggie Stir-fry Bowl", "Honey Garlic Tofu Bento"
]
random.shuffle(dishes)

# Get visual specs
visual_specs = tmpl_def.get("visual_specs", {})
visual_style = visual_specs.get("style", "")
layouts = visual_specs.get("layouts", [])

# Get brand colors
colors = dna.get("visual", {}).get("colors", {})

# Generate variants
variants = []
for i in range(num_variants):
    variant_id = chr(65 + i)  # A, B, C, D, E
    headline = headlines[i % len(headlines)]

    # Truncate headline if needed
    if len(headline) > headline_max:
        headline = headline[:headline_max - 3] + "..."

    # Generate subcopy based on direction
    pain = ""
    desire = ""
    if "pain_points" in direction:
        pains = direction["pain_points"]
        pain = pains[i % len(pains)]
    if "desires" in direction:
        desires = direction["desires"]
        desire = desires[i % len(desires)]

    # Pick layout
    layout = layouts[i % len(layouts)] if layouts else "standard"

    # Pick dish
    dish = dishes[i % len(dishes)]

    # Generate unique ID
    ts = str(int(time.time()))
    uid = hashlib.md5(f"{brand}-{direction_id}-{template_type}-{variant_id}-{ts}".encode()).hexdigest()[:8]
    campaign_id = f"CP-{brand[:3].upper()}-W{week}-{direction_id}-{template_type}-{variant_id}-{uid}"

    variant = {
        "campaign_id": campaign_id,
        "brand": brand,
        "direction_id": direction_id,
        "direction_name": direction.get("name", ""),
        "template_type": template_type,
        "template_name": tmpl_def["name"],
        "funnel": funnel,
        "variant": variant_id,
        "week": int(week),
        "headline": headline,
        "subcopy_brief": f"Pain: {pain}. Desire: {desire}." if pain else f"Direction: {direction.get('name', '')}",
        "usp_points": [
            "Nutritionist-designed meals",
            "400-600 kcal per bento",
            "50+ menu variety"
        ],
        "visual_description": f"{visual_style}. Layout: {layout}. Brand colors: {colors.get('primary', '#F7AB9F')} primary.",
        "persona_reference": persona_label,
        "dish_assignment": dish,
        "char_limits": {
            "headline_max": headline_max,
            "subcopy_max": subcopy_max
        },
        "testing_logic": tmpl_def.get("test_logic", ""),
        "status": "Brief",
        "agent": "hermes",
        "created_at": time.strftime("%Y-%m-%dT%H:%M:%S+08:00")
    }
    variants.append(variant)

# Output as JSON
output = {
    "campaign_set": f"{brand.upper()} {direction_id} {template_type} W{week}",
    "brand": brand,
    "direction": direction_id,
    "template_type": template_type,
    "funnel": funnel,
    "week": int(week),
    "total_variants": len(variants),
    "budget_range_rm": tmpls.get("meta_ads_structure", {}).get(funnel.lower(), {}).get("budget_per_set_rm", {}),
    "variants": variants
}

print(json.dumps(output, indent=2, ensure_ascii=False))

# Also write each variant to tracker JSONL
with open(tracker_file, "a") as f:
    for v in variants:
        f.write(json.dumps(v, ensure_ascii=False) + "\n")

PYEOF

    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        log "Campaign brief created: $brand $direction $template_type (${variants} variants, week $week)"
        post_to_room "$EXEC_ROOM" "campaign-planner" "Campaign created: $brand $direction $template_type W$week ($variants variants)"
    fi
    return $exit_code
}

# --- Command: full-campaign ---
cmd_full_campaign() {
    local brand="" direction="" mofu_sets="" bofu_sets="" week=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand)      brand="$2"; shift 2 ;;
            --direction)  direction="$2"; shift 2 ;;
            --mofu-sets)  mofu_sets="$2"; shift 2 ;;
            --bofu-sets)  bofu_sets="$2"; shift 2 ;;
            --week)       week="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    brand="${brand:-mirra}"
    week="${week:-$(date '+%V' | sed 's/^0//')}"
    mofu_sets="${mofu_sets:-M1,M2,M3,M4,M5}"
    bofu_sets="${bofu_sets:-B1,B2,B3,B4}"

    if [ -z "$direction" ]; then
        err "Required: --direction"
        exit 1
    fi

    check_deps "$brand"

    log "Generating full campaign: $brand $direction"
    log "MOFU sets: $mofu_sets"
    log "BOFU sets: $bofu_sets"
    echo ""

    local total_sets=0
    local total_variants=0

    # Process MOFU sets
    IFS=',' read -ra MOFU_ARR <<< "$mofu_sets"
    for tmpl in "${MOFU_ARR[@]}"; do
        tmpl=$(echo "$tmpl" | tr -d ' ')
        echo "--- Creating MOFU set: $tmpl ---"
        cmd_create --brand "$brand" --direction "$direction" --template-type "$tmpl" --week "$week"
        total_sets=$((total_sets + 1))
        echo ""
    done

    # Process BOFU sets
    IFS=',' read -ra BOFU_ARR <<< "$bofu_sets"
    for tmpl in "${BOFU_ARR[@]}"; do
        tmpl=$(echo "$tmpl" | tr -d ' ')
        echo "--- Creating BOFU set: $tmpl ---"
        cmd_create --brand "$brand" --direction "$direction" --template-type "$tmpl" --week "$week"
        total_sets=$((total_sets + 1))
        echo ""
    done

    log "Full campaign complete: $total_sets sets generated"
    post_to_room "$EXEC_ROOM" "campaign-planner" "Full campaign: $brand $direction W$week — $total_sets sets"
}

# --- Command: list ---
cmd_list() {
    local brand="" status=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand)  brand="$2"; shift 2 ;;
            --status) status="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [ ! -f "$TRACKER_FILE" ]; then
        echo "No campaigns tracked yet. File: $TRACKER_FILE"
        exit 0
    fi

    python3 - "$TRACKER_FILE" "$brand" "$status" << 'PYEOF'
import json, sys

tracker_file = sys.argv[1]
brand_filter = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else ""
status_filter = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else ""

campaigns = []
with open(tracker_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            c = json.loads(line)
            if brand_filter and c.get("brand") != brand_filter:
                continue
            if status_filter and c.get("status", "").lower() != status_filter.lower():
                continue
            campaigns.append(c)
        except json.JSONDecodeError:
            continue

if not campaigns:
    print("No campaigns found matching filters.")
    sys.exit(0)

# Group by direction + template
groups = {}
for c in campaigns:
    key = f"{c.get('direction_id', '?')}/{c.get('template_type', '?')}"
    if key not in groups:
        groups[key] = []
    groups[key].append(c)

print(f"{'Direction/Type':<25} {'Funnel':<8} {'Variants':<10} {'Status':<12} {'Week':<6}")
print("-" * 65)
for key, items in sorted(groups.items()):
    funnel = items[0].get("funnel", "?")
    statuses = set(i.get("status", "?") for i in items)
    status_str = "/".join(sorted(statuses))
    week = items[0].get("week", "?")
    print(f"{key:<25} {funnel:<8} {len(items):<10} {status_str:<12} W{week}")

print(f"\nTotal: {len(campaigns)} campaign variants")
PYEOF
}

# --- Command: pre-mortem ---
cmd_pre_mortem() {
    local brand="" campaign="" budget="" launch_date=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand)       brand="$2"; shift 2 ;;
            --campaign)    campaign="$2"; shift 2 ;;
            --budget)      budget="$2"; shift 2 ;;
            --launch-date) launch_date="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    brand="${brand:-mirra}"
    campaign="${campaign:-Untitled Campaign}"
    budget="${budget:-0}"
    launch_date="${launch_date:-$(date -v+7d '+%Y-%m-%d' 2>/dev/null || date -d '+7 days' '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')}"

    local campaign_dir="$HOME/.openclaw/workspace/data/campaigns/$brand"
    mkdir -p "$campaign_dir"

    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    local out_file="$campaign_dir/pre-mortem-${ts}.md"

    # Common failure modes for GAIA brands
    cat > "$out_file" << PMEOF
# Pre-Mortem Analysis

**CAMPAIGN:** $campaign
**BRAND:** $brand
**LAUNCH DATE:** $launch_date
**BUDGET:** RM $budget

> "It's 30 days from now and this campaign failed. Here's why:"

---

## TIGERS (High probability + High impact — MUST fix before launch)

1. [ ] Creative fatigue within first week
   - Mitigation: Have 5+ ad variants ready at launch, schedule refresh at day 7
2. [ ] Wrong audience targeting
   - Mitigation: Validate with RM 50 test budget for 48h before full launch
3. [ ] Landing page broken on mobile
   - Mitigation: QA on iPhone Safari, Android Chrome, and Samsung browser before launch
4. [ ] Low stock / fulfillment delay
   - Mitigation: Confirm inventory count covers 2x projected demand
5. [ ] Platform policy rejection (ad disapproved)
   - Mitigation: Review Meta/TikTok ad policies checklist pre-submit, avoid health claims

## PAPER TIGERS (High probability + Low impact — monitor closely)

1. [ ] Budget burns too fast on day 1
   - Quick fix: Set daily caps at 30% of weekly budget, monitor first 24h
2. [ ] Seasonal timing miss (holiday, competitor promo clash)
   - Quick fix: Cross-check with campaign calendar and competitor intel
3. [ ] Comments section negativity
   - Quick fix: Prepare 3 positive response templates, assign Hermes to monitor

## ELEPHANTS (Low probability + High impact — contingency ready)

1. [ ] Competitor launches identical campaign same week
   - Contingency: Have differentiation messaging ready, pivot ad angle within 24h
2. [ ] Negative PR / brand crisis during campaign
   - Contingency: Pause all ads immediately, Zenni sends crisis template to Jenn
3. [ ] Platform outage (Meta, TikTok, Shopee down)
   - Contingency: Shift budget to alternative platform, extend campaign end date

---

## SIGN-OFF CHECKLIST

- [ ] All Tigers mitigated?
- [ ] Budget approved by Jenn?
- [ ] 5+ creative variants ready?
- [ ] Landing page QA passed?
- [ ] Inventory confirmed?

**STATUS:** [ ] READY TO LAUNCH / [ ] NOT READY — fix Tigers first

---
*Generated by campaign-planner.sh pre-mortem | $(date '+%Y-%m-%d %H:%M')*
PMEOF

    echo "Pre-mortem analysis saved to: $out_file"
    echo ""
    cat "$out_file"

    # Also log to tracker
    local tracker_entry
    tracker_entry=$(python3 -c "
import json, time
print(json.dumps({
    'type': 'pre-mortem',
    'brand': '$brand',
    'campaign': '$campaign',
    'budget_rm': '$budget',
    'launch_date': '$launch_date',
    'file': '$out_file',
    'created_at': time.strftime('%Y-%m-%dT%H:%M:%S+08:00')
}))" 2>/dev/null || echo "")

    if [ -n "$tracker_entry" ]; then
        mkdir -p "$(dirname "$TRACKER_FILE")"
        echo "$tracker_entry" >> "$TRACKER_FILE"
    fi

    post_to_room "$EXEC_ROOM" "campaign-planner" "Pre-mortem created: $brand — $campaign (launch: $launch_date)"
}

# --- Command: drip ---
cmd_drip() {
    local brand="" sequence="" channel=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand)    brand="$2"; shift 2 ;;
            --sequence) sequence="$2"; shift 2 ;;
            --channel)  channel="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    brand="${brand:-mirra}"
    sequence="${sequence:-welcome}"
    channel="${channel:-email}"

    local campaign_dir="$HOME/.openclaw/workspace/data/campaigns/$brand"
    mkdir -p "$campaign_dir"

    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    local out_file="$campaign_dir/drip-${sequence}-${ts}.json"

    python3 - "$brand" "$sequence" "$channel" "$out_file" << 'PYEOF'
import json, sys, time

brand = sys.argv[1]
sequence = sys.argv[2]
channel = sys.argv[3]
out_file = sys.argv[4]

templates = {
    "welcome": {
        "name": "Welcome Series",
        "emails": 5,
        "span_days": 14,
        "steps": [
            {"day": 0, "channel": channel, "type": "welcome", "subject": f"Welcome to {brand.title()}!", "goal": "Make a great first impression"},
            {"day": 2, "channel": channel, "type": "value", "subject": "Here's something most people don't know...", "goal": "Deliver value, build trust"},
            {"day": 5, "channel": channel, "type": "social-proof", "subject": "See what others are saying", "goal": "Social proof, testimonials"},
            {"day": 9, "channel": channel, "type": "offer", "subject": "A special thank you (just for you)", "goal": "First purchase incentive"},
            {"day": 14, "channel": channel, "type": "urgency", "subject": "Your offer expires tomorrow", "goal": "Urgency close"}
        ]
    },
    "abandoned-cart": {
        "name": "Abandoned Cart Recovery",
        "emails": 3,
        "span_days": 3,
        "steps": [
            {"day": 0, "channel": channel, "type": "reminder", "subject": "You left something behind...", "goal": "Gentle reminder"},
            {"day": 1, "channel": channel, "type": "incentive", "subject": "Here's 10% off to complete your order", "goal": "Incentivize return"},
            {"day": 3, "channel": channel, "type": "last-chance", "subject": "Last chance — your cart is expiring", "goal": "Final urgency push"}
        ]
    },
    "re-engagement": {
        "name": "Re-engagement Series",
        "emails": 3,
        "span_days": 7,
        "steps": [
            {"day": 0, "channel": channel, "type": "miss-you", "subject": "We miss you!", "goal": "Reconnect with lapsed customer"},
            {"day": 3, "channel": channel, "type": "whats-new", "subject": "Look what's new since you've been away", "goal": "Show new products/content"},
            {"day": 7, "channel": channel, "type": "win-back", "subject": "Come back for 15% off", "goal": "Win-back offer"}
        ]
    },
    "post-purchase": {
        "name": "Post-Purchase Nurture",
        "emails": 4,
        "span_days": 30,
        "steps": [
            {"day": 0, "channel": channel, "type": "thank-you", "subject": "Thank you for your order!", "goal": "Order confirmation + brand warmth"},
            {"day": 3, "channel": channel, "type": "how-to", "subject": "How to get the most out of your order", "goal": "Usage tips, reduce returns"},
            {"day": 14, "channel": channel, "type": "review", "subject": "How are you enjoying it? Leave a review", "goal": "Collect social proof"},
            {"day": 30, "channel": channel, "type": "upsell", "subject": "You might also love these...", "goal": "Cross-sell / upsell"}
        ]
    }
}

tmpl = templates.get(sequence, templates["welcome"])

drip = {
    "brand": brand,
    "sequence": sequence,
    "name": tmpl["name"],
    "channel": channel,
    "total_steps": tmpl["emails"],
    "span_days": tmpl["span_days"],
    "steps": tmpl["steps"],
    "trigger_rules": {
        "open": "Advance to next stage",
        "no_open_48h": "Switch channel (email->whatsapp or vice versa)",
        "click": "Tag as engaged, fast-track to offer step",
        "unsubscribe": "Remove from all sequences, add to suppression list",
        "purchase": "Move to post-purchase sequence",
        "3_consecutive_no_opens": "Auto-terminate sequence"
    },
    "created_at": time.strftime("%Y-%m-%dT%H:%M:%S+08:00")
}

with open(out_file, "w") as f:
    json.dump(drip, f, indent=2, ensure_ascii=False)

print(json.dumps(drip, indent=2, ensure_ascii=False))
print(f"\nSaved to: {out_file}", file=sys.stderr)
PYEOF
}

# --- Main ---
main() {
    if [ $# -eq 0 ]; then
        echo "campaign-planner.sh — Generate ad campaign briefs from templates + directions"
        echo ""
        echo "Commands:"
        echo "  create          Generate campaign variants for a direction + template type"
        echo "  directions      List available campaign directions"
        echo "  full-campaign   Generate all sets for a direction"
        echo "  list            List tracked campaigns"
        echo "  pre-mortem      Run pre-mortem risk analysis before launch"
        echo "  drip            Generate drip sequence template"
        echo ""
        echo "Examples:"
        echo "  campaign-planner.sh create --brand mirra --direction en-1 --template-type M2 --variants 5 --week 10"
        echo "  campaign-planner.sh directions --brand mirra --lang en"
        echo "  campaign-planner.sh full-campaign --brand mirra --direction en-1"
        echo "  campaign-planner.sh list --brand mirra --status brief"
        echo "  campaign-planner.sh pre-mortem --brand mirra --campaign \"CNY Bundle\" --budget 500 --launch-date 2026-03-15"
        echo "  campaign-planner.sh drip --brand mirra --sequence welcome --channel email"
        exit 0
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        create)         cmd_create "$@" ;;
        directions)     cmd_directions "$@" ;;
        full-campaign)  cmd_full_campaign "$@" ;;
        list)           cmd_list "$@" ;;
        pre-mortem)     cmd_pre_mortem "$@" ;;
        drip)           cmd_drip "$@" ;;
        *)
            err "Unknown command: $cmd"
            exit 1
            ;;
    esac
}

main "$@"
