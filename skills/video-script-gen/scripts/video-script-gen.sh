#!/usr/bin/env bash
# video-script-gen.sh — LLM Video Script Generator for Zennith OS
# Ported from Tricia's 222KB generate_script_variants.py
#
# Usage:
#   video-script-gen.sh generate --brand <brand> --product <desc> --flow <flow> [options]
#   video-script-gen.sh flows
#   video-script-gen.sh validate --script <json>

set -euo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW="$HOME/.openclaw"
OUTPUT_DIR="${OPENCLAW}/workspace/data/video-scripts/$(date +%Y-%m-%d)"
LOG_FILE="${OPENCLAW}/logs/video-script-gen.log"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
BRANDS_DIR="${OPENCLAW}/brands"

mkdir -p "$OUTPUT_DIR" "$(dirname "$LOG_FILE")"

MODE="${1:-help}"
shift 2>/dev/null || true

# Parse args
BRAND=""
PRODUCT=""
GOAL="conversion"
FLOW="testimonial"
TONE="authentic, relatable"
AUDIENCE=""
VARIANTS=3
DURATION=40
SCRIPT_FILE=""
LANGUAGE="auto"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brand)    BRAND="$2"; shift 2 ;;
    --product)  PRODUCT="$2"; shift 2 ;;
    --goal)     GOAL="$2"; shift 2 ;;
    --flow)     FLOW="$2"; shift 2 ;;
    --tone)     TONE="$2"; shift 2 ;;
    --audience) AUDIENCE="$2"; shift 2 ;;
    --variants) VARIANTS="$2"; shift 2 ;;
    --duration) DURATION="$2"; shift 2 ;;
    --script)   SCRIPT_FILE="$2"; shift 2 ;;
    --language) LANGUAGE="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

log() { echo "[script-gen $(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"; }

case "$MODE" in
  generate)
    [[ -z "$BRAND" ]] && { echo "ERROR: --brand required"; exit 1; }
    [[ -z "$PRODUCT" ]] && { echo "ERROR: --product required"; exit 1; }

    log "=== GENERATE SCRIPT ==="
    log "Brand: $BRAND | Product: $PRODUCT | Flow: $FLOW | Duration: ${DURATION}s"

    # Load brand DNA
    DNA_FILE="${BRANDS_DIR}/${BRAND}/DNA.json"
    BRAND_CONTEXT=""
    if [[ -f "$DNA_FILE" ]]; then
      BRAND_CONTEXT=$("$PYTHON3" -c "
import json, sys
with open('$DNA_FILE') as f:
    dna = json.load(f)
parts = []
parts.append(f\"Brand: {dna.get('name', '$BRAND')}\")
if 'tagline' in dna: parts.append(f\"Tagline: {dna['tagline']}\")
if 'voice' in dna:
    v = dna['voice']
    if isinstance(v, dict):
        parts.append(f\"Voice: {v.get('tone', '')}, {v.get('style', '')}\")
if 'audience' in dna:
    parts.append(f\"Audience: {dna['audience']}\")
if 'never' in dna:
    parts.append(f\"NEVER: {', '.join(dna['never'][:5])}\")
print('\\n'.join(parts))
" 2>/dev/null) || true
    fi

    "$PYTHON3" - << PYEOF
import json, os, sys
from datetime import datetime

brand = "$BRAND"
product = "$PRODUCT"
goal = "$GOAL"
flow = "$FLOW"
tone = "$TONE"
audience = "$AUDIENCE"
num_variants = $VARIANTS
duration = $DURATION
language = "$LANGUAGE"
brand_context = """$BRAND_CONTEXT"""
output_dir = "$OUTPUT_DIR"

# Flow → strategy mapping
FLOW_STRATEGY = {
    "testimonial": "script_first", "PAS": "script_first",
    "challenge": "script_first", "slap": "script_first",
    "convenience_solve": "script_first", "brand_story": "script_first",
    "before_after": "script_first", "curiosity_reveal": "script_first",
    "sales_hype": "script_first",
    "compiled_montage": "two_layer",
    "what_i_eat": "block_first", "brand_montage": "block_first",
    "vo_montage": "script_first",
}

# Flow → letter mapping
FLOW_LETTER = {
    "testimonial": "A", "PAS": "B", "challenge": "C", "slap": "D",
    "convenience_solve": "E", "compiled_montage": "F", "brand_story": "G",
    "what_i_eat": "H", "sales_hype": "I", "curiosity_reveal": "J",
    "before_after": "K", "brand_montage": "L", "vo_montage": "M",
}

# Flow → voice
FLOW_VOICE = {
    "A": "1st person", "B": "2nd person", "C": "1st person", "D": "2nd person",
    "E": "1st person", "F": "mixed", "G": "3rd person", "H": "1st person",
    "I": "2nd person", "J": "2nd person", "K": "1st person", "L": "none",
    "M": "3rd person",
}

# Flow → default AIDA block pattern
FLOW_BLOCKS = {
    "A": ["A3", "I6", "D1", "D2", "Act6"],
    "B": ["A5", "A5", "I3", "D1", "Act6"],
    "C": ["A3", "D1", "D3", "Act6"],
    "D": ["A3", "I3", "D1", "Act6"],
    "E": ["A5", "I4", "D2", "D1", "Act6"],
    "F": ["A3", "A3", "A4", "D1", "Act6"],
    "G": ["I1", "I2", "I3", "D1", "Act6"],
    "H": ["D1", "D1", "D1", "A6", "Act6"],
    "I": ["A5", "Act1", "I6", "Act6"],
    "J": ["A3", "I2", "D3", "A3", "Act6"],
    "K": ["A5", "A6", "D1", "Act6"],
    "L": ["kinetic_text", "product_image", "kinetic_text", "Act6"],
    "M": ["A1", "I1", "I3", "D1", "Act6"],
}

strategy = FLOW_STRATEGY.get(flow, "script_first")
letter = FLOW_LETTER.get(flow, "A")
voice = FLOW_VOICE.get(letter, "1st person")
blocks = FLOW_BLOCKS.get(letter, ["A3", "I1", "D1", "Act6"])

# Emotion arc for the blocks
EMOTION_ARC = ["curiosity", "frustration", "surprise", "relief", "confidence", "urgency"]

# Build block template
num_blocks = len(blocks)
block_duration = duration / num_blocks

script_blocks = []
for i, code in enumerate(blocks):
    phase_map = {"A": "attention", "I": "interest", "D": "desire", "Act": "action", "k": "attention", "p": "interest"}
    code_prefix = code.rstrip("0123456789_textimag")
    aida = phase_map.get(code_prefix, "attention")
    emotion = EMOTION_ARC[i % len(EMOTION_ARC)]

    block = {
        "id": f"{i+1:02d}_{code}",
        "block_code": code,
        "aida_phase": aida,
        "duration_s": round(block_duration, 1),
        "spoken_dialogue": f"[{voice} voice — {emotion} tone — block {i+1}/{num_blocks}]",
        "text_overlay": {
            "text": f"[Caption for {code} block]",
            "style": "bold" if i == 0 else "normal",
            "emphasis": []
        },
        "visual_description": f"[Visual for {code}: {emotion}]",
        "emotion": emotion
    }
    script_blocks.append(block)

# Generate variants
variants = []
for v in range(num_variants):
    variant = {
        "variant_id": f"{brand}_{flow}_v{v+1}",
        "flow": letter,
        "flow_name": flow,
        "strategy": strategy,
        "voice": voice,
        "total_duration_s": duration,
        "brand": brand,
        "product": product,
        "goal": goal,
        "tone": tone,
        "audience": audience,
        "spoken_dialogue": f"[Full {voice} narration for {duration}s {flow} video about {product}]",
        "hook_headline": f"[2-8 char provocative hook for {product}]",
        "blocks": script_blocks,
        "craft_check": {
            "tension_hook": True,
            "emotional_arc_valid": True,
            "emphasis_count": 0,
            "text_image_counterpoint": True,
            "no_silent_gaps": True,
            "variety_pacing": True,
            "callback_structure": True,
            "note": "TEMPLATE — fill with LLM or manually. Craft rules checked on completion."
        },
        "generated_at": datetime.utcnow().isoformat() + "Z"
    }
    variants.append(variant)

output_file = os.path.join(output_dir, f"{brand}-{flow}-variants.json")
with open(output_file, "w") as f:
    json.dump({"variants": variants, "brand_context": brand_context}, f, indent=2, ensure_ascii=False)

print(f"Generated {num_variants} script variant templates")
print(f"Flow: {letter} ({flow}) | Strategy: {strategy} | Voice: {voice}")
print(f"Blocks: {' → '.join(blocks)} ({num_blocks} blocks, ~{block_duration:.1f}s each)")
print(f"Output: {output_file}")
print()
print("Next steps:")
print("  1. Fill templates with real dialogue using Dreami or LLM")
print("  2. Run: video-script-gen.sh validate --script <output.json>")
print("  3. Pass to video-compiler.sh for production")
PYEOF
    ;;

  flows)
    cat << 'FLOWEOF'
Video Script Flows (A-M):

  A  testimonial         1st person story. MOFU.
  B  PAS                 Problem-Agitate-Solve. MOFU/BOFU.
  C  challenge           Day-by-day editorial. MOFU.
  D  slap                Pattern interrupt. MOFU/BOFU.
  E  convenience_solve   Sparse dialogue, visuals carry. MOFU.
  F  compiled_montage    Multi-KOL compilation. MOFU.
  G  brand_story         3rd person editorial. MOFU.
  H  what_i_eat          Day-in-life food diary. MOFU.
  I  sales_hype          Promotional claim stacking. BOFU.
  J  curiosity_reveal    Mystery → reveal. TOFU.
  K  before_after        Transformation contrast. MOFU.
  L  brand_montage       Kinetic text, no VO. MOFU.
  M  vo_montage          Full VO over muted clips. MOFU.

Strategies:
  script_first    Full narrative → segment (A-E, G, I-K, M)
  two_layer       Text + visual separately (F)
  block_first     Structure IS content (H, L)
FLOWEOF
    ;;

  validate)
    [[ -z "$SCRIPT_FILE" ]] && { echo "ERROR: --script required"; exit 1; }
    [[ ! -f "$SCRIPT_FILE" ]] && { echo "ERROR: Script file not found: $SCRIPT_FILE"; exit 1; }

    log "=== VALIDATE SCRIPT ==="

    "$PYTHON3" - "$SCRIPT_FILE" << 'PYEOF'
import json, sys, re

with open(sys.argv[1]) as f:
    data = json.load(f)

variants = data.get("variants", [data]) if "variants" in data else [data]
print(f"Validating {len(variants)} variant(s)...\n")

for v in variants:
    vid = v.get("variant_id", "unknown")
    blocks = v.get("blocks", [])
    dialogue = v.get("spoken_dialogue", "")

    issues = []

    # Rule 1: Tension hook
    if blocks:
        first = blocks[0]
        hook_text = first.get("spoken_dialogue", "") + first.get("text_overlay", {}).get("text", "")
        if not any(c.isdigit() for c in hook_text) and "?" not in hook_text:
            issues.append("Rule 1 FAIL: Hook has no number or question")

    # Rule 2: Emotional arc
    emotions = [b.get("emotion", "") for b in blocks]
    for i in range(1, len(emotions)):
        if emotions[i] and emotions[i] == emotions[i-1]:
            issues.append(f"Rule 2 FAIL: Adjacent blocks share emotion '{emotions[i]}'")
            break

    # Rule 3: Emphasis count
    emphasis_count = len(re.findall(r'\*[^*]+\*', dialogue))
    if emphasis_count < 5:
        issues.append(f"Rule 3 WARN: Only {emphasis_count} emphasis phrases (need 5-7)")
    elif emphasis_count > 7:
        issues.append(f"Rule 3 WARN: {emphasis_count} emphasis phrases (max 7)")

    # Rule 5: No silent gaps
    silent = [b for b in blocks if not b.get("spoken_dialogue") and b.get("block_code") not in ("Act6", "logo_sting")]
    if silent:
        issues.append(f"Rule 5 FAIL: {len(silent)} blocks have no dialogue")

    # Rule 6: Variety pacing
    durations = [b.get("duration_s", 0) for b in blocks]
    if durations and max(durations) - min(durations) < 1.0:
        issues.append("Rule 6 WARN: All blocks same duration — add variety")

    if issues:
        print(f"  {vid}: {len(issues)} issue(s)")
        for issue in issues:
            print(f"    - {issue}")
    else:
        print(f"  {vid}: ✅ All craft rules pass")

print()
PYEOF
    ;;

  help|*)
    cat << 'HELPEOF'
Video Script Generator — Zennith OS

Usage:
  video-script-gen.sh generate  --brand <brand> --product <desc> --flow <flow> [options]
  video-script-gen.sh flows     List all 13 flow types
  video-script-gen.sh validate  --script <json>

Options:
  --brand <name>       Brand name (loads DNA.json)
  --product <desc>     Product description
  --goal <goal>        conversion, awareness, trial (default: conversion)
  --flow <flow>        Flow type: testimonial, PAS, challenge, slap, etc.
  --tone <tone>        Tone description (default: "authentic, relatable")
  --audience <desc>    Target audience description
  --variants <n>       Number of variants (default: 3)
  --duration <sec>     Total video duration (default: 40)
  --language <lang>    zh, en, or auto (default: auto)
HELPEOF
    ;;
esac
