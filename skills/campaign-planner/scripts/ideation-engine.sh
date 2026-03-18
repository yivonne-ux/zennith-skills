#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# ideation-engine.sh — GAIA CORP-OS Ideation Engine
# Generates ad ideas from seed bank + directions + templates (no LLM calls)
#
# Commands:
#   generate --brand <b> --direction <d> --count <n>
#   batch   --brand <b> --directions "d1,d2,d3" --count <n>
#   score   --brand <b> --idea-file /path/to/ideas.json
#
# Bash 3.2 compatible (macOS — no declare -A, no ${var,,})
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"
BRANDS_DIR="$OPENCLAW_DIR/brands"
SEED_STORE="$OPENCLAW_DIR/skills/content-seed-bank/scripts/seed-store.sh"
ENV_FILE="$OPENCLAW_DIR/.env"

# Load .env if it exists
if [ -f "$ENV_FILE" ]; then
  set +e
  while IFS='=' read -r key value; do
    case "$key" in
      ''|\#*) continue ;;
    esac
    # Strip surrounding quotes from value
    value="$(echo "$value" | sed 's/^["'\'']//' | sed 's/["'\'']$//')"
    export "$key=$value" 2>/dev/null
  done < "$ENV_FILE"
  set -e
fi

log() {
  local ts
  ts="$(date '+%Y-%m-%dT%H:%M:%S%z')"
  echo "[$ts] $*" >&2
}

usage() {
  cat >&2 <<'USAGE'
Usage:
  ideation-engine.sh generate --brand <brand> --direction <dir_id> [--count N]
  ideation-engine.sh batch   --brand <brand> --directions "d1,d2,d3" [--count N]
  ideation-engine.sh score   --brand <brand> --idea-file /path/to/ideas.json

Examples:
  ideation-engine.sh generate --brand mirra --direction en-1 --count 9
  ideation-engine.sh batch --brand mirra --directions "en-1,en-2,cn-1" --count 9
  ideation-engine.sh score --brand mirra --idea-file /tmp/ideas.json
USAGE
  exit 1
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
CMD="${1:-}"
[ -z "$CMD" ] && usage
shift

BRAND=""
DIRECTION=""
DIRECTIONS=""
COUNT=9
IDEA_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --brand)    BRAND="$2";      shift 2 ;;
    --direction) DIRECTION="$2"; shift 2 ;;
    --directions) DIRECTIONS="$2"; shift 2 ;;
    --count)    COUNT="$2";      shift 2 ;;
    --idea-file) IDEA_FILE="$2"; shift 2 ;;
    *) log "Unknown arg: $1"; usage ;;
  esac
done

[ -z "$BRAND" ] && { log "ERROR: --brand required"; usage; }

BRAND_DIR="$BRANDS_DIR/$BRAND"
DIRECTIONS_FILE="$BRAND_DIR/campaigns/directions.json"
TEMPLATES_FILE="$BRAND_DIR/templates/templates.json"
DNA_FILE="$BRAND_DIR/DNA.json"

# Validate brand data exists
for f in "$DNA_FILE" "$DIRECTIONS_FILE" "$TEMPLATES_FILE"; do
  if [ ! -f "$f" ]; then
    log "ERROR: Missing data file: $f"
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# Fetch top hooks from seed bank (graceful fallback)
# ---------------------------------------------------------------------------
fetch_seed_hooks() {
  local hooks_json="[]"
  if [ -f "$SEED_STORE" ] && [ -x "$SEED_STORE" ]; then
    hooks_json="$(bash "$SEED_STORE" top --type hook --brand "$BRAND" --limit 10 2>/dev/null || echo '[]')"
    # Validate it's valid JSON array
    echo "$hooks_json" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null || hooks_json="[]"
  fi
  echo "$hooks_json"
}

# ---------------------------------------------------------------------------
# Core generation logic — pure Python3 (deterministic, no LLM)
# ---------------------------------------------------------------------------
generate_ideas() {
  local brand="$1"
  local direction_id="$2"
  local count="$3"
  local seed_hooks
  seed_hooks="$(fetch_seed_hooks)"

  python3 - "$brand" "$direction_id" "$count" "$DIRECTIONS_FILE" "$TEMPLATES_FILE" "$DNA_FILE" "$seed_hooks" <<'PYEOF'
import json
import sys
import hashlib
import math
from datetime import datetime, timezone, timedelta

brand = sys.argv[1]
direction_id = sys.argv[2]
count = int(sys.argv[3])
directions_path = sys.argv[4]
templates_path = sys.argv[5]
dna_path = sys.argv[6]
seed_hooks_raw = sys.argv[7]

# ---- Load data ----
with open(directions_path) as f:
    directions_data = json.load(f)
with open(templates_path) as f:
    templates_data = json.load(f)
with open(dna_path) as f:
    dna_data = json.load(f)

try:
    seed_hooks = json.loads(seed_hooks_raw)
    if not isinstance(seed_hooks, list):
        seed_hooks = []
except (json.JSONDecodeError, TypeError):
    seed_hooks = []

# ---- Find the direction ----
direction = None
# Determine language prefix
lang_prefix = direction_id.split("-")[0]  # "en" or "cn"

if lang_prefix == "en":
    for d in directions_data.get("en", []):
        if d["id"] == direction_id:
            direction = d
            break
elif lang_prefix == "cn":
    for d in directions_data.get("cn", []):
        if d["id"] == direction_id:
            direction = d
            break

if direction is None:
    print(json.dumps({"error": f"Direction {direction_id} not found"}))
    sys.exit(1)

# ---- Extract direction data ----
dir_name = direction.get("name", "")
dir_short = direction.get("short_name", "")
funnel_focus = direction.get("funnel_focus", "MOFU")

# Handle persona differences between EN (single persona) and CN (personas array)
personas = []
if "persona" in direction:
    p = direction["persona"]
    label = p.get("label", dir_short)
    age_range = p.get("age_range", "25-40")
    location = p.get("location", "KL")
    income = p.get("income", "")
    occupation = p.get("occupation", "")
    persona_str = f"{label} ({age_range}, {location}"
    if income:
        persona_str += f", {income}"
    persona_str += ")"
    personas.append(persona_str)
elif "personas" in direction:
    for p in direction["personas"]:
        name = p.get("name", "")
        age = p.get("age", "")
        role = p.get("role", "")
        trait = p.get("trait", "")
        personas.append(f"{name} ({age}, {role} - {trait})")

pain_points = direction.get("pain_points", [])
desires = direction.get("desires", [])

# Headlines — EN has flat list, CN has dict with tofu/mofu/bofu
headlines_raw = direction.get("headlines", [])
headlines = []
if isinstance(headlines_raw, list):
    headlines = headlines_raw
elif isinstance(headlines_raw, dict):
    for stage in ["tofu", "mofu", "bofu"]:
        headlines.extend(headlines_raw.get(stage, []))

# Template preferences from direction (or defaults)
template_prefs = direction.get("template_preferences", ["M1", "M2", "M3", "M4", "M5"])

# ---- Extract DNA data ----
content_pillars = list(dna_data.get("content_pillars", {}).keys())
brand_usps = dna_data.get("values", [])
products = dna_data.get("products", [])
audience_primary = dna_data.get("audience", {}).get("primary", "")
dna_personas = dna_data.get("audience", {}).get("personas", [])

# ---- Extract template specs ----
template_types = templates_data.get("template_types", {})
all_template_keys = sorted(template_types.keys())
mofu_templates = [k for k in all_template_keys if k.startswith("M")]
bofu_templates = [k for k in all_template_keys if k.startswith("B")]

# ---- USP categories for diversity ----
usp_categories = {
    "health": ["Nutritionist-designed", "No MSG, all natural", "Under 500 calories", "Low GI, balanced macros", "Plant-based protein options"],
    "convenience": ["Ready in 3 minutes", "Delivered to your door", "50+ menu variety", "Weekly plans available", "No cooking needed"],
    "taste": ["Real Malaysian flavours", "Not cold salad — hot, tasty meals", "Nasi lemak, rendang, laksa — made healthy", "Different bento every day", "Chef-crafted recipes"],
    "value": ["From RM19 per bento", "Cheaper than poke bowls", "Save RM200+/month vs Grab", "5-day plans with free delivery", "No hidden charges"],
    "results": ["Customers losing 3-5kg/month", "Calorie-counted by nutritionist", "Real results, real people", "Designed for sustainable weight loss", "Track your progress weekly"]
}
usp_keys = list(usp_categories.keys())

# ---- Visual concept templates per format ----
visual_concepts_by_format = {
    "image": [
        "Top-view bento box on {bg} background, {badge} badge, {persona_hint}",
        "Split comparison: regular {food} vs Mirra bento, calorie callouts",
        "Hero bento shot with {usp_focus} highlight, clean {bg} background",
        "Lifestyle shot: {persona_hint} opening Mirra bento at desk, natural light",
        "{grid_or_single} product showcase with nutritionist-designed badge",
        "Before/after comparison: greasy takeout vs colorful Mirra bento",
        "Ingredient spotlight: fresh vegetables and protein in Mirra bento",
        "Price comparison card: Grab/poke RM28-45 vs Mirra RM19",
        "Weekly menu carousel preview with calorie badges on each bento"
    ],
    "video": [
        "15s top-down bento unboxing reveal, steam rising, {persona_hint} hands",
        "Side-by-side comparison animation: regular lunch vs Mirra, calorie counter",
        "Day-in-the-life: {persona_hint} ordering Mirra, microwave 3min, enjoying at desk",
        "Weekly rotation montage: Day 1-5 different bentos, upbeat music",
        "Testimonial-style: {persona_hint} talking about switching from {food} to Mirra",
        "Stop-motion bento assembly: ingredients flying into box, badge stamps",
        "Split-screen: stressful Grab scrolling vs quick Mirra ordering"
    ],
    "short_animation": [
        "Animated calorie counter: regular nasi goreng 800kcal shrinking to Mirra 450kcal",
        "Motion graphics: {usp_focus} benefits popping in with Mirra bento reveal",
        "Animated comparison slider: junk food morphing into Mirra bento",
        "Text animation: {hook_preview} with bento product shots fading in",
        "Animated badge stamps landing on bento: No MSG, Low Cal, Nutritionist Designed",
        "Price ticker animation: daily lunch spend dropping from RM30 to RM19",
        "Infographic animation: macro breakdown of Mirra bento vs typical lunch"
    ]
}

# ---- CTA pool ----
cta_pool = [
    "Order your first box today",
    "Try Mirra — from RM19",
    "WhatsApp us to order",
    "Start your 5-day plan",
    "Get your bento delivered",
    "Swap your lunch today",
    "Order now — free delivery",
    "Try your first Mirra bento",
    "Start eating better today",
    "Claim your trial box"
]

# CN CTAs
cta_pool_cn = [
    "立即WhatsApp订购",
    "从RM19开始你的健康午餐",
    "马上下单试试Mirra便当",
    "开始你的5天瘦身计划",
    "立即咨询优惠方案",
    "点击订购，改变从今天开始",
    "立即领取试吃优惠",
    "WhatsApp下单享首单优惠"
]

# ---- Deterministic hash for reproducible variation ----
def det_hash(s):
    return int(hashlib.md5(s.encode("utf-8")).hexdigest(), 16)

def pick(items, seed_str, offset=0):
    if not items:
        return ""
    h = det_hash(seed_str + str(offset))
    return items[h % len(items)]

def pick_n(items, n, seed_str):
    if not items:
        return []
    results = []
    seen = set()
    for i in range(n * 3):  # over-sample to get unique
        h = det_hash(seed_str + str(i))
        idx = h % len(items)
        item = items[idx]
        if item not in seen:
            seen.add(item)
            results.append(item)
        if len(results) >= n:
            break
    # If not enough unique, pad with cycling
    while len(results) < n:
        results.append(items[len(results) % len(items)])
    return results[:n]

# ---- Determine funnel stage per idea ----
def get_funnel_stage(template_type, direction_funnel):
    if template_type.startswith("B"):
        return "BOFU"
    if "/" in direction_funnel:
        stages = [s.strip() for s in direction_funnel.split("/")]
        return stages[0] if template_type in ["M1", "M2"] else stages[-1] if template_type in ["M4", "M5"] else "MOFU"
    return direction_funnel

# ---- Scoring logic ----
def score_idea(idea, template_type, direction, template_spec, format_type, all_hooks_in_batch, all_usps_in_batch):
    scores = {}

    # 1. Template-direction alignment (0.3 weight)
    dir_prefs = direction.get("template_preferences", [])
    if template_type in dir_prefs:
        scores["template_alignment"] = 0.9 + (0.1 * (1.0 / max(1, dir_prefs.index(template_type) + 1)))
    elif template_type.startswith("M") and any(p.startswith("M") for p in dir_prefs):
        scores["template_alignment"] = 0.6
    elif template_type.startswith("B"):
        scores["template_alignment"] = 0.5
    else:
        scores["template_alignment"] = 0.4

    # 2. Format match (0.2 weight)
    supported_formats = template_spec.get("formats", [])
    format_map = {
        "image": ["single_image", "carousel", "grid_image", "quote_card", "screenshot_style"],
        "video": ["video", "ugc_reel"],
        "short_animation": ["animated", "video"]
    }
    matching = format_map.get(format_type, [])
    overlap = len(set(matching) & set(supported_formats))
    if overlap > 0:
        scores["format_match"] = min(1.0, 0.7 + 0.15 * overlap)
    else:
        scores["format_match"] = 0.4

    # 3. Persona coverage (0.2 weight)
    hook = idea.get("hook", "")
    persona_terms = []
    for p in personas:
        persona_terms.extend(p.lower().split())
    for pp in pain_points:
        persona_terms.extend(pp.lower().split()[:3])
    hook_lower = hook.lower()
    relevance = sum(1 for t in persona_terms if t in hook_lower and len(t) > 3)
    scores["persona_coverage"] = min(1.0, 0.6 + 0.08 * relevance)

    # 4. Headline uniqueness (0.15 weight)
    if all_hooks_in_batch:
        similar_count = sum(1 for h in all_hooks_in_batch if h == hook)
        scores["headline_uniqueness"] = max(0.3, 1.0 - 0.2 * (similar_count - 1))
    else:
        scores["headline_uniqueness"] = 0.8

    # 5. USP diversity (0.15 weight)
    idea_usps = idea.get("usp_highlights", [])
    usp_cats_hit = set()
    for u in idea_usps:
        u_lower = u.lower()
        for cat, examples in usp_categories.items():
            for ex in examples:
                if any(word in u_lower for word in ex.lower().split()[:2] if len(word) > 3):
                    usp_cats_hit.add(cat)
                    break
    # Check against batch diversity
    scores["usp_diversity"] = min(1.0, 0.5 + 0.15 * len(usp_cats_hit))

    # Clamp all scores
    for k in scores:
        scores[k] = round(min(1.0, max(0.0, scores[k])), 2)

    # Weighted final
    fit = (
        scores["template_alignment"] * 0.3 +
        scores["format_match"] * 0.2 +
        scores["persona_coverage"] * 0.2 +
        scores["headline_uniqueness"] * 0.15 +
        scores["usp_diversity"] * 0.15
    )

    return round(fit, 2), scores

# ---- Build ideas ----
formats = ["image", "video", "short_animation"]
ideas = []

# Determine how many per format
per_format = count // 3
remainder = count % 3
format_counts = {}
for i, fmt in enumerate(formats):
    format_counts[fmt] = per_format + (1 if i < remainder else 0)

# Determine available templates for this direction
available_templates = []
if funnel_focus == "MOFU":
    available_templates = mofu_templates
elif funnel_focus == "BOFU":
    available_templates = bofu_templates
else:
    # Mixed funnel (e.g., TOFU/MOFU/BOFU) — use all
    available_templates = mofu_templates + bofu_templates

# Prefer direction's template_preferences, then fill with others
ordered_templates = []
for tp in template_prefs:
    if tp in available_templates:
        ordered_templates.append(tp)
for tp in available_templates:
    if tp not in ordered_templates:
        ordered_templates.append(tp)

if not ordered_templates:
    ordered_templates = all_template_keys

# Use direction's visual concepts if available
dir_visual_concepts = direction.get("visual_concepts", [])

# Merge seed bank hooks with direction headlines
all_hooks = list(headlines)
if seed_hooks:
    for sh in seed_hooks:
        if isinstance(sh, dict):
            hook_text = sh.get("text", sh.get("content", sh.get("hook", "")))
        elif isinstance(sh, str):
            hook_text = sh
        else:
            continue
        if hook_text and hook_text not in all_hooks:
            all_hooks.append(hook_text)

# Foods for visual variety
local_foods = ["nasi lemak", "nasi goreng", "char kuey teow", "roti canai", "mamak food", "fast food", "poke bowl"]
backgrounds = ["salmon pink", "cream", "warm white", "light pink", "soft peach"]

# Track all hooks and USPs for scoring
all_hooks_in_batch = []
all_usps_in_batch = []

idea_counter = 0
for fmt in formats:
    fmt_count = format_counts[fmt]
    for i in range(fmt_count):
        idea_counter += 1
        seed_str = f"{brand}-{direction_id}-{fmt}-{i}"
        dir_tag = direction_id.replace("-", "")

        # Cycle template type
        tmpl_key = ordered_templates[i % len(ordered_templates)]
        tmpl_spec = template_types.get(tmpl_key, {})
        char_limits = tmpl_spec.get("char_limits", {})

        # Pick headline
        headline = pick(all_hooks, seed_str, offset=0) if all_hooks else f"Discover Mirra — {dir_short}"

        # Truncate headline to char limits if available
        max_headline = char_limits.get("headline", {}).get("max", 50)
        if len(headline) > max_headline:
            # Trim at word boundary, add ellipsis
            cut = headline[:max_headline - 3]
            if " " in cut:
                cut = cut.rsplit(" ", 1)[0]
            headline = cut.rstrip() + "..."

        # Generate sub_copy from pain points + desires
        pain = pick(pain_points, seed_str, offset=1) if pain_points else "Tired of unhealthy lunches"
        desire = pick(desires, seed_str, offset=2) if desires else "a healthier option"
        product = pick(products, seed_str, offset=3) if products else "calorie-conscious bentos"

        # Build sub_copy
        sub_copy_templates = [
            f"{product} — designed for {dir_short.lower()} who want better",
            f"Stop settling for {pain.lower().rstrip('.')}. {product} delivered to you",
            f"Nutritionist-designed {product.lower()} that solve {pain.lower().rstrip('.')}",
            f"Finally, {desire.lower().rstrip('.')} — {product} from RM19",
            f"Real Malaysian flavours, calorie-counted. {product} for your lifestyle"
        ]
        sub_copy = pick(sub_copy_templates, seed_str, offset=4)

        # Truncate sub_copy at word boundary
        max_subcopy = char_limits.get("subcopy", {}).get("max", 90)
        if len(sub_copy) > max_subcopy:
            cut = sub_copy[:max_subcopy - 3]
            if " " in cut:
                cut = cut.rsplit(" ", 1)[0]
            sub_copy = cut.rstrip() + "..."

        # USP highlights — pick 3 from different categories
        usp_cat_cycle = [(i + j) % len(usp_keys) for j in range(3)]
        usp_highlights = []
        for ci in usp_cat_cycle:
            cat = usp_keys[ci]
            usp = pick(usp_categories[cat], seed_str, offset=10 + ci)
            usp_highlights.append(usp)

        # Truncate USP items
        max_usp = char_limits.get("usp_points", {}).get("max_per", 35)
        usp_highlights = [u[:max_usp] if len(u) > max_usp else u for u in usp_highlights]

        # CTA
        cta_list = cta_pool_cn if lang_prefix == "cn" else cta_pool
        cta = pick(cta_list, seed_str, offset=20)
        max_cta = char_limits.get("cta", {}).get("max", 25)
        if len(cta) > max_cta:
            # Truncate at word boundary to avoid cut-off mid-word
            trimmed = cta[:max_cta].rsplit(" ", 1)[0] if " " in cta[:max_cta] else cta[:max_cta]
            cta = trimmed

        # Visual concept
        visual_templates = visual_concepts_by_format.get(fmt, visual_concepts_by_format["image"])
        raw_visual = pick(visual_templates, seed_str, offset=30)

        # Fill in visual template placeholders
        persona_hint = personas[i % len(personas)] if personas else dir_short
        # Simplify persona hint for visual concept
        if "(" in persona_hint:
            persona_hint = persona_hint.split("(")[0].strip()
        food = pick(local_foods, seed_str, offset=31)
        bg = pick(backgrounds, seed_str, offset=32)
        usp_focus_label = usp_keys[(i + 1) % len(usp_keys)]
        hook_preview = headline[:30] if len(headline) > 30 else headline

        visual_concept = raw_visual.replace("{persona_hint}", persona_hint)
        visual_concept = visual_concept.replace("{food}", food)
        visual_concept = visual_concept.replace("{bg}", bg)
        visual_concept = visual_concept.replace("{usp_focus}", usp_focus_label)
        visual_concept = visual_concept.replace("{badge}", pick(["Nutritionist Designed", "No MSG", "Low Cal", "Plant-Based"], seed_str, 33))
        visual_concept = visual_concept.replace("{grid_or_single}", pick(["Grid", "Single hero"], seed_str, 34))
        visual_concept = visual_concept.replace("{hook_preview}", hook_preview)

        # If direction has its own visual concepts, blend them in occasionally
        if dir_visual_concepts and (i % 2 == 0):
            dvc = dir_visual_concepts[i % len(dir_visual_concepts)]
            visual_concept = dvc.get("desc", visual_concept)

        # Target persona
        target_persona = personas[i % len(personas)] if personas else f"{audience_primary}"

        # Funnel stage
        funnel_stage = get_funnel_stage(tmpl_key, funnel_focus)

        idea = {
            "id": f"IDEA-{dir_tag}-{idea_counter:03d}",
            "format": fmt,
            "template_type": tmpl_key,
            "hook": headline,
            "sub_copy": sub_copy,
            "usp_highlights": usp_highlights,
            "cta": cta,
            "visual_concept": visual_concept,
            "target_persona": target_persona,
            "funnel_stage": funnel_stage,
            "fit_score": 0.0,
            "scoring_breakdown": {}
        }

        all_hooks_in_batch.append(headline)
        all_usps_in_batch.extend(usp_highlights)
        ideas.append(idea)

# ---- Score all ideas ----
for idea in ideas:
    tmpl_key = idea["template_type"]
    tmpl_spec = template_types.get(tmpl_key, {})
    fit, breakdown = score_idea(
        idea, tmpl_key, direction, tmpl_spec,
        idea["format"], all_hooks_in_batch, all_usps_in_batch
    )
    idea["fit_score"] = fit
    idea["scoring_breakdown"] = breakdown

# ---- Sort by fit_score descending ----
ideas.sort(key=lambda x: x["fit_score"], reverse=True)

# ---- Build output ----
myt = timezone(timedelta(hours=8))
now = datetime.now(myt).strftime("%Y-%m-%dT%H:%M:%S%z")
# Fix timezone format: +0800 -> +08:00
if len(now) > 5 and now[-5] in ("+", "-") and ":" not in now[-5:]:
    now = now[:-2] + ":" + now[-2:]

output = {
    "brand": brand,
    "direction": direction_id,
    "direction_name": dir_name,
    "generated_at": now,
    "total_ideas": len(ideas),
    "ideas": ideas
}

print(json.dumps(output, indent=2, ensure_ascii=False))
PYEOF
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------
cmd_generate() {
  if [ -z "$DIRECTION" ]; then
    log "ERROR: --direction required for generate"
    usage
  fi
  generate_ideas "$BRAND" "$DIRECTION" "$COUNT"
  log "Generated $COUNT ideas for $BRAND direction $DIRECTION"
}

cmd_batch() {
  if [ -z "$DIRECTIONS" ]; then
    log "ERROR: --directions required for batch"
    usage
  fi

  # Split comma-separated directions (Bash 3.2 compatible)
  local dir_list=""
  local IFS_SAVE="$IFS"
  IFS=","
  set +u
  local all_results=""
  local first=1
  for dir_id in $DIRECTIONS; do
    IFS="$IFS_SAVE"
    # Trim whitespace
    dir_id="$(echo "$dir_id" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
    [ -z "$dir_id" ] && continue
    local result
    result="$(generate_ideas "$BRAND" "$dir_id" "$COUNT")"
    log "Generated $COUNT ideas for $BRAND direction $dir_id"
    if [ "$first" -eq 1 ]; then
      all_results="$result"
      first=0
    else
      all_results="$all_results
$result"
    fi
  done
  set -u
  IFS="$IFS_SAVE"

  # Combine into single JSON array
  echo "$all_results" | python3 -c "
import json, sys

results = []
decoder = json.JSONDecoder()
raw = sys.stdin.read()
pos = 0
while pos < len(raw):
    try:
        obj, end = decoder.raw_decode(raw, pos)
        results.append(obj)
        pos = end
    except json.JSONDecodeError:
        pos += 1

from datetime import datetime, timezone, timedelta
myt = timezone(timedelta(hours=8))
now = datetime.now(myt).strftime('%Y-%m-%dT%H:%M:%S%z')
if len(now) > 5 and now[-5] in ('+', '-') and ':' not in now[-5:]:
    now = now[:-2] + ':' + now[-2:]

output = {
    'brand': '$BRAND',
    'batch': True,
    'directions': [r['direction'] for r in results],
    'generated_at': now,
    'total_ideas': sum(r['total_ideas'] for r in results),
    'results': results
}
print(json.dumps(output, indent=2, ensure_ascii=False))
"
  log "Batch complete: $(echo "$DIRECTIONS" | tr ',' ' ' | wc -w | tr -d ' ') directions processed"
}

cmd_score() {
  if [ -z "$IDEA_FILE" ]; then
    log "ERROR: --idea-file required for score"
    usage
  fi
  if [ ! -f "$IDEA_FILE" ]; then
    log "ERROR: File not found: $IDEA_FILE"
    exit 1
  fi

  python3 - "$BRAND" "$IDEA_FILE" "$DIRECTIONS_FILE" "$TEMPLATES_FILE" "$DNA_FILE" <<'PYEOF'
import json
import sys
from datetime import datetime, timezone, timedelta

brand = sys.argv[1]
idea_file = sys.argv[2]
directions_path = sys.argv[3]
templates_path = sys.argv[4]
dna_path = sys.argv[5]

with open(idea_file) as f:
    idea_data = json.load(f)
with open(directions_path) as f:
    directions_data = json.load(f)
with open(templates_path) as f:
    templates_data = json.load(f)
with open(dna_path) as f:
    dna_data = json.load(f)

template_types = templates_data.get("template_types", {})
brand_usps = dna_data.get("values", [])

# Build USP categories (same as generate)
usp_categories = {
    "health": ["Nutritionist-designed", "No MSG, all natural", "Under 500 calories", "Low GI, balanced macros", "Plant-based protein options"],
    "convenience": ["Ready in 3 minutes", "Delivered to your door", "50+ menu variety", "Weekly plans available", "No cooking needed"],
    "taste": ["Real Malaysian flavours", "Not cold salad", "Nasi lemak, rendang, laksa", "Different bento every day", "Chef-crafted recipes"],
    "value": ["From RM19 per bento", "Cheaper than poke bowls", "Save RM200+/month vs Grab", "5-day plans with free delivery", "No hidden charges"],
    "results": ["Customers losing 3-5kg/month", "Calorie-counted by nutritionist", "Real results", "Designed for sustainable weight loss", "Track your progress weekly"]
}

# Extract ideas — handle both single direction and batch format
ideas = []
direction_map = {}
if "ideas" in idea_data:
    ideas = idea_data["ideas"]
    dir_id = idea_data.get("direction", "")
    # Find direction
    lang = dir_id.split("-")[0] if dir_id else ""
    for d in directions_data.get(lang, []):
        if d["id"] == dir_id:
            direction_map[dir_id] = d
            break
elif "results" in idea_data:
    for r in idea_data["results"]:
        ideas.extend(r.get("ideas", []))
        dir_id = r.get("direction", "")
        lang = dir_id.split("-")[0] if dir_id else ""
        for d in directions_data.get(lang, []):
            if d["id"] == dir_id:
                direction_map[dir_id] = d
                break

all_hooks = [idea.get("hook", "") for idea in ideas]

# Re-score each idea
for idea in ideas:
    tmpl_key = idea.get("template_type", "M1")
    tmpl_spec = template_types.get(tmpl_key, {})
    fmt = idea.get("format", "image")

    scores = {}

    # Determine which direction this idea belongs to
    idea_id = idea.get("id", "")
    # Parse direction from id: IDEA-en1-001 -> en-1
    id_parts = idea_id.replace("IDEA-", "").split("-")
    if len(id_parts) >= 2:
        # Reconstruct direction id: en1 -> en-1, cn2 -> cn-2
        tag = id_parts[0]
        # Extract letters and numbers
        letters = ""
        numbers = ""
        for c in tag:
            if c.isalpha():
                letters += c
            else:
                numbers += c
        dir_id_guess = f"{letters}-{numbers}" if numbers else tag
    else:
        dir_id_guess = ""

    direction = direction_map.get(dir_id_guess, {})
    dir_prefs = direction.get("template_preferences", [])

    # 1. Template alignment
    if tmpl_key in dir_prefs:
        idx = dir_prefs.index(tmpl_key)
        scores["template_alignment"] = round(0.9 + (0.1 / max(1, idx + 1)), 2)
    elif tmpl_key.startswith("M") and any(p.startswith("M") for p in dir_prefs):
        scores["template_alignment"] = 0.6
    else:
        scores["template_alignment"] = 0.5

    # 2. Format match
    supported = tmpl_spec.get("formats", [])
    fmt_map = {
        "image": ["single_image", "carousel", "grid_image", "quote_card", "screenshot_style"],
        "video": ["video", "ugc_reel"],
        "short_animation": ["animated", "video"]
    }
    matching = fmt_map.get(fmt, [])
    overlap = len(set(matching) & set(supported))
    scores["format_match"] = round(min(1.0, 0.7 + 0.15 * overlap) if overlap > 0 else 0.4, 2)

    # 3. Persona coverage
    hook = idea.get("hook", "").lower()
    pain_points = direction.get("pain_points", [])
    pain_words = []
    for pp in pain_points:
        pain_words.extend(pp.lower().split()[:3])
    relevance = sum(1 for t in pain_words if t in hook and len(t) > 3)
    scores["persona_coverage"] = round(min(1.0, 0.6 + 0.08 * relevance), 2)

    # 4. Headline uniqueness
    similar = sum(1 for h in all_hooks if h == idea.get("hook", ""))
    scores["headline_uniqueness"] = round(max(0.3, 1.0 - 0.2 * (similar - 1)), 2)

    # 5. USP diversity
    usps = idea.get("usp_highlights", [])
    cats_hit = set()
    for u in usps:
        u_l = u.lower()
        for cat, examples in usp_categories.items():
            for ex in examples:
                if any(word in u_l for word in ex.lower().split()[:2] if len(word) > 3):
                    cats_hit.add(cat)
                    break
    scores["usp_diversity"] = round(min(1.0, 0.5 + 0.15 * len(cats_hit)), 2)

    fit = round(
        scores["template_alignment"] * 0.3 +
        scores["format_match"] * 0.2 +
        scores["persona_coverage"] * 0.2 +
        scores["headline_uniqueness"] * 0.15 +
        scores["usp_diversity"] * 0.15,
        2
    )

    idea["fit_score"] = fit
    idea["scoring_breakdown"] = scores

ideas.sort(key=lambda x: x["fit_score"], reverse=True)

myt = timezone(timedelta(hours=8))
now = datetime.now(myt).strftime("%Y-%m-%dT%H:%M:%S%z")
if len(now) > 5 and now[-5] in ("+", "-") and ":" not in now[-5:]:
    now = now[:-2] + ":" + now[-2:]

output = {
    "brand": brand,
    "rescored_at": now,
    "total_ideas": len(ideas),
    "avg_fit_score": round(sum(i["fit_score"] for i in ideas) / max(1, len(ideas)), 2),
    "ideas": ideas
}

print(json.dumps(output, indent=2, ensure_ascii=False))
PYEOF

  log "Re-scored $(python3 -c "import json; print(len(json.load(open('$IDEA_FILE')).get('ideas', [])))" 2>/dev/null || echo '?') ideas from $IDEA_FILE"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "$CMD" in
  generate) cmd_generate ;;
  batch)    cmd_batch ;;
  score)    cmd_score ;;
  *)        log "Unknown command: $CMD"; usage ;;
esac
