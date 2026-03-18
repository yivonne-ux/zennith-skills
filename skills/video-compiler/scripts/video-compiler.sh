#!/usr/bin/env bash
# video-compiler.sh — Main CLI Orchestrator for GAIA Video Compiler
#
# Blends Tricia's WAT architecture (AIDA blocks, ad frameworks, combinatorial)
# with GAIA's existing tools (video-gen.sh, nanobanana-gen.sh, video-forge.sh, seed-store.sh).
#
# Usage:
#   video-compiler.sh run      --brand <brand> --product <desc> [options]
#   video-compiler.sh script   --brand <brand> --product <desc> [options]
#   video-compiler.sh generate --plan <plan.json> [--concurrency 5]
#   video-compiler.sh produce  --work-dir <dir> [--brand <brand>]
#   video-compiler.sh review   --input <video>
#   video-compiler.sh list     --work-dir <dir>
#   video-compiler.sh batch    --input-dir <dir> --brand <brand>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_ROOT="$HOME/.openclaw/skills"
BRANDS_DIR="$HOME/.openclaw/brands"
WORKSPACE="$HOME/.openclaw/workspace"

# GAIA tool paths
VIDEO_GEN="$SKILLS_ROOT/video-gen/scripts/video-gen.sh"
VIDEO_FORGE="$SKILLS_ROOT/video-forge/scripts/video-forge.sh"
NANOBANANA="$SKILLS_ROOT/nanobanana/scripts/nanobanana-gen.sh"
SEED_STORE="$SKILLS_ROOT/content-seed-bank/scripts/seed-store.sh"
VIDEO_REVIEW="$SCRIPT_DIR/video-review.sh"
PARALLEL_GEN="$SCRIPT_DIR/parallel-gen.py"
SCRIPT_GEN="$SCRIPT_DIR/script-gen.py"

# Defaults
DEFAULT_CONCURRENCY=5
DEFAULT_VARIANTS=3
DEFAULT_MODE="assembled"
DEFAULT_GOAL="conversion"
DEFAULT_TONE="authentic"

info()  { echo "[video-compiler] $*"; }
warn()  { echo "[video-compiler] WARNING: $*" >&2; }
error() { echo "[video-compiler] ERROR: $*" >&2; }

timestamp() { date +%Y%m%d-%H%M%S; }

get_duration() {
  ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$1" 2>/dev/null | cut -d. -f1
}

get_resolution() {
  ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$1" 2>/dev/null
}

# ============================================================
# STAGE 1: SCRIPT — Generate video scripts with ad frameworks
# ============================================================
stage_script() {
  local brand="$1" product="$2" goal="$3" tone="$4" framework="${5:-}" \
        variants="${6:-$DEFAULT_VARIANTS}" mode="$7" work_dir="$8" language="${9:-en}"

  info "=== STAGE 1: SCRIPT GENERATION ==="
  info "Brand: $brand | Product: $product | Goal: $goal | Framework: ${framework:-auto}"

  local duration_hint="medium"
  case "$mode" in
    single-shot) duration_hint="short" ;;
    assembled)   duration_hint="medium" ;;
    combinatorial) duration_hint="long" ;;
  esac

  local script_output="$work_dir/scripts.json"

  python3 "$SCRIPT_GEN" \
    --brand "$brand" \
    --product "$product" \
    --goal "$goal" \
    --tone "$tone" \
    ${framework:+--framework "$framework"} \
    --duration "$duration_hint" \
    --variants "$variants" \
    --language "$language" \
    --output "$script_output"

  if [ ! -f "$script_output" ]; then
    error "Script generation failed — no output"
    return 1
  fi

  local num_variants
  num_variants=$(python3 -c "import json; print(len(json.load(open('$script_output'))['variants']))")
  info "Generated $num_variants script variants → $script_output"
}

# ============================================================
# STAGE 2: PLAN — Resolve blocks to sources (A/B/C) + build gen plan
# ============================================================
stage_plan() {
  local work_dir="$1" brand="$2" mode="$3"

  info "=== STAGE 2: PLANNING ==="

  local scripts_file="$work_dir/scripts.json"
  [ ! -f "$scripts_file" ] && { error "No scripts.json in $work_dir"; return 1; }

  # Convert scripts to generation plan
  local plan_file="$work_dir/gen_plan.json"

  python3 -c "
import json, os, glob, random

scripts = json.load(open('$scripts_file'))
brand = scripts.get('brand', '$brand')
product = scripts.get('product', '')
plan = []
variant_num = 0

# Auto-discover product reference images for this brand
# Priority: portrait (720x1280, best for video) > flat (top-view PNGs)
product_refs = []
for subdir in ['products-portrait', 'products-flat']:
    refs_dir = os.path.expanduser(f'~/.openclaw/brands/{brand}/references/{subdir}')
    if os.path.isdir(refs_dir):
        for ext in ['*.png', '*.jpg', '*.jpeg', '*.webp']:
            product_refs.extend(glob.glob(os.path.join(refs_dir, ext)))
    # If product specified, prefer matching refs
    if product:
        matching = [r for r in product_refs if product.lower() in os.path.basename(r).lower()]
        if matching:
            product_refs = matching + [r for r in product_refs if r not in matching]

if product_refs:
    print(f'Found {len(product_refs)} product refs for {brand}' + (f' (product match: {product})' if product else ''))

# Phases where product refs should be injected (show the actual product)
PRODUCT_PHASES = {'interest', 'desire', 'action'}
PRODUCT_TYPES = {'broll_video', 'product_image'}

for variant in scripts['variants']:
    variant_num += 1
    blocks = variant.get('blocks', [])
    ref_idx = 0
    for i, block in enumerate(blocks):
        gen_type = block.get('gen_type', 'kol_video')
        aida_phase = block.get('aida_phase', '')

        if gen_type == 'text_card':
            plan.append({
                'id': f'v{variant_num}_b{i+1}_{block[\"label\"]}',
                'prompt': block.get('text_overlay', block.get('dialogue', 'CTA')),
                'model': 'text_card',
                'duration': block.get('duration_s', 5),
                'gen_type': 'text_card',
                'variant': variant_num,
                'position': i + 1,
                'aida_phase': aida_phase,
                'block_code': block.get('block_code', ''),
            })
        else:
            visual = block.get('visual', block.get('dialogue', ''))
            model = 'sora' if gen_type == 'kol_video' else 'kling'
            dur = block.get('duration_s', 8)
            if model == 'sora':
                dur = min([4, 8, 12], key=lambda x: abs(x - dur))

            job = {
                'id': f'v{variant_num}_b{i+1}_{block[\"label\"]}',
                'prompt': visual,
                'model': model,
                'duration': dur,
                'gen_type': gen_type,
                'variant': variant_num,
                'position': i + 1,
                'aida_phase': aida_phase,
                'block_code': block.get('block_code', ''),
            }

            # Inject product ref for product-showing blocks
            # Use image2video (ref_image) for broll/product blocks in desire/interest
            if product_refs and (aida_phase in PRODUCT_PHASES or gen_type in PRODUCT_TYPES):
                ref = product_refs[ref_idx % len(product_refs)]
                job['ref_image'] = ref
                ref_idx += 1
                print(f'  {job[\"id\"]}: injecting ref {os.path.basename(ref)}')

            plan.append(job)

with open('$plan_file', 'w') as f:
    json.dump(plan, f, indent=2, ensure_ascii=False)
print(f'Plan: {len(plan)} jobs across {variant_num} variants')
"

  if [ ! -f "$plan_file" ]; then
    error "Plan generation failed"
    return 1
  fi

  local num_jobs
  num_jobs=$(python3 -c "import json; print(len(json.load(open('$plan_file'))))")

  # Cost estimate
  python3 -c "
import json
plan = json.load(open('$plan_file'))
costs = {'sora': 0.10, 'kling': 0.056, 'wan': 0.03, 'text_card': 0, 'nanobanana': 0}
total = sum(costs.get(j['model'], 0.05) * j['duration'] for j in plan)
print(f'Estimated cost: \${total:.2f} ({len(plan)} jobs)')
for model in set(j['model'] for j in plan):
    count = sum(1 for j in plan if j['model'] == model)
    print(f'  {model}: {count} jobs')
"

  info "$num_jobs generation jobs planned → $plan_file"
}

# ============================================================
# STAGE 3: GENERATE — Parallel video/image generation
# ============================================================
stage_generate() {
  local work_dir="$1" concurrency="${2:-$DEFAULT_CONCURRENCY}"

  info "=== STAGE 3: PARALLEL GENERATION ==="

  local plan_file="$work_dir/gen_plan.json"
  [ ! -f "$plan_file" ] && { error "No gen_plan.json in $work_dir"; return 1; }

  local gen_dir="$work_dir/generated"
  mkdir -p "$gen_dir"

  python3 "$PARALLEL_GEN" \
    --plan "$plan_file" \
    --concurrency "$concurrency" \
    --output-dir "$gen_dir"

  local results_file="$gen_dir/generation_results.json"
  if [ -f "$results_file" ]; then
    local completed failed
    completed=$(python3 -c "import json; print(json.load(open('$results_file'))['completed'])")
    failed=$(python3 -c "import json; print(json.load(open('$results_file'))['failed'])")
    info "Generation complete: $completed succeeded, $failed failed"
  fi
}

# ============================================================
# STAGE 4: PRODUCE — Post-production via VideoForge
# ============================================================
stage_produce() {
  local work_dir="$1" brand="${2:-}"

  info "=== STAGE 4: POST-PRODUCTION ==="

  local gen_dir="$work_dir/generated"
  local produced_dir="$work_dir/produced"
  mkdir -p "$produced_dir"

  if [ ! -d "$gen_dir" ]; then
    error "No generated/ directory in $work_dir"
    return 1
  fi

  local clip_count=0
  for clip in "$gen_dir"/*.mp4; do
    [ -f "$clip" ] || continue
    clip_count=$((clip_count + 1))
    local base
    base=$(basename "$clip")

    info "Producing: $base"

    # Check if already portrait
    local res width height skip_crop=0
    res=$(get_resolution "$clip")
    width=$(echo "$res" | cut -d, -f1)
    height=$(echo "$res" | cut -d, -f2)
    if [ "$height" -gt "$((width * 3 / 2))" ] 2>/dev/null; then
      skip_crop=1
    fi

    # Post-production via VideoForge
    if [ -f "$VIDEO_FORGE" ] && [ -n "$brand" ]; then
      bash "$VIDEO_FORGE" produce "$clip" --type ugc --brand "$brand" \
        --output "$produced_dir" 2>/dev/null || {
        warn "VideoForge failed for $base, copying raw"
        cp "$clip" "$produced_dir/"
      }
    else
      # No brand or no VideoForge — just copy
      cp "$clip" "$produced_dir/"
    fi
  done

  info "Produced $clip_count clips → $produced_dir/"
}

# ============================================================
# STAGE 5: REVIEW — Video QA via video-review.sh
# ============================================================
stage_review() {
  local work_dir="$1"

  info "=== STAGE 5: VIDEO QA ==="

  local produced_dir="$work_dir/produced"
  local review_dir="$work_dir/review"
  mkdir -p "$review_dir"

  if [ ! -d "$produced_dir" ]; then
    warn "No produced/ directory, skipping review"
    return 0
  fi

  local pass_count=0 fail_count=0

  for clip in "$produced_dir"/*.mp4; do
    [ -f "$clip" ] || continue
    local base
    base=$(basename "$clip")

    # Quick score
    if bash "$VIDEO_REVIEW" score "$clip" 2>/dev/null; then
      pass_count=$((pass_count + 1))
    else
      fail_count=$((fail_count + 1))
      # Full review for failures
      bash "$VIDEO_REVIEW" full "$clip" --output "$review_dir" 2>/dev/null || true
    fi
  done

  info "QA: $pass_count passed, $fail_count failed"
  if [ "$fail_count" -gt 0 ]; then
    info "Review artifacts → $review_dir/"
  fi
}

# ============================================================
# STAGE 6: DELIVER — Export + register in seed-store
# ============================================================
stage_deliver() {
  local work_dir="$1" brand="${2:-}"

  info "=== STAGE 6: DELIVERY ==="

  local produced_dir="$work_dir/produced"
  local export_dir="$work_dir/export"
  mkdir -p "$export_dir"

  if [ ! -d "$produced_dir" ]; then
    warn "No produced/ directory, skipping delivery"
    return 0
  fi

  local export_count=0

  for clip in "$produced_dir"/*.mp4; do
    [ -f "$clip" ] || continue

    # Skip already-prefixed platform files
    local base
    base=$(basename "$clip")
    case "$base" in
      tiktok_*|reels_*|shorts_*|feed_*|youtube_*) continue ;;
    esac

    # Export to all platforms
    if [ -f "$VIDEO_FORGE" ]; then
      bash "$VIDEO_FORGE" export "$clip" --platforms tiktok,reels,shorts --output "$export_dir" 2>/dev/null || {
        warn "Export failed for $base, copying as-is"
        cp "$clip" "$export_dir/"
      }
    else
      cp "$clip" "$export_dir/"
    fi
    export_count=$((export_count + 1))

    # Register in seed-store
    if [ -f "$SEED_STORE" ] && [ -n "$brand" ]; then
      bash "$SEED_STORE" add --type video --brand "$brand" \
        --tags "video-compiler,ugc,auto-generated" \
        --source "video-compiler" --file "$clip" 2>/dev/null || true
    fi
  done

  # Also move any platform-prefixed files from produced to export
  for clip in "$produced_dir"/{tiktok,reels,shorts,feed,youtube}_*.mp4; do
    [ -f "$clip" ] || continue
    cp "$clip" "$export_dir/"
    export_count=$((export_count + 1))
  done

  info "Exported $export_count files → $export_dir/"

  # Post to creative room
  local room_file="$WORKSPACE/rooms/creative.jsonl"
  if [ -d "$WORKSPACE/rooms" ]; then
    echo "{\"type\":\"video-compiler\",\"brand\":\"$brand\",\"clips\":$export_count,\"work_dir\":\"$work_dir\",\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$room_file"
    info "Posted to creative room"
  fi
}

# ============================================================
# COMMANDS
# ============================================================

cmd_run() {
  local brand="" product="" goal="$DEFAULT_GOAL" tone="$DEFAULT_TONE"
  local framework="" mode="$DEFAULT_MODE" variants="$DEFAULT_VARIANTS"
  local concurrency="$DEFAULT_CONCURRENCY" plan_only=0 resume=""
  local work_dir="" language="en"

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand) brand="$2"; shift 2 ;;
      --product) product="$2"; shift 2 ;;
      --goal) goal="$2"; shift 2 ;;
      --tone) tone="$2"; shift 2 ;;
      --framework) framework="$2"; shift 2 ;;
      --mode) mode="$2"; shift 2 ;;
      --variants) variants="$2"; shift 2 ;;
      --concurrency) concurrency="$2"; shift 2 ;;
      --plan-only) plan_only=1; shift ;;
      --resume) resume="$2"; shift 2 ;;
      --work-dir) work_dir="$2"; shift 2 ;;
      --language|--lang) language="$2"; shift 2 ;;
      *) error "Unknown option: $1"; exit 1 ;;
    esac
  done

  # Resume from existing work dir
  if [ -n "$resume" ]; then
    work_dir="$resume"
    if [ -f "$work_dir/gen_plan.json" ]; then
      info "Resuming from plan: $work_dir/gen_plan.json"
      local plan_brand
      plan_brand=$(python3 -c "import json; print(json.load(open('$work_dir/scripts.json')).get('brand', ''))" 2>/dev/null || echo "")
      [ -n "$plan_brand" ] && brand="$plan_brand"
      stage_generate "$work_dir" "$concurrency"
      stage_produce "$work_dir" "$brand"
      stage_review "$work_dir"
      stage_deliver "$work_dir" "$brand"
      return
    fi
  fi

  # Validate inputs
  [ -z "$brand" ] && { error "--brand required"; exit 1; }
  [ -z "$product" ] && { error "--product required"; exit 1; }

  # Create work directory
  if [ -z "$work_dir" ]; then
    local slug
    slug=$(echo "$product" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | head -c 30)
    work_dir="$HOME/Downloads/video-compiler-${brand}-${slug}-$(timestamp)"
  fi
  mkdir -p "$work_dir"

  info "============================================"
  info "VIDEO COMPILER — GAIA OS"
  info "============================================"
  info "Brand:     $brand"
  info "Product:   $product"
  info "Goal:      $goal"
  info "Mode:      $mode"
  info "Variants:  $variants"
  info "Work dir:  $work_dir"
  info "============================================"
  echo ""

  # Stage 1: Scripts
  stage_script "$brand" "$product" "$goal" "$tone" "$framework" "$variants" "$mode" "$work_dir" "$language"
  echo ""

  # Stage 2: Plan
  stage_plan "$work_dir" "$brand" "$mode"
  echo ""

  # Plan-only mode: stop here
  if [ "$plan_only" -eq 1 ]; then
    info "PLAN ONLY — review $work_dir/gen_plan.json"
    info "To continue: video-compiler.sh run --resume $work_dir"
    return 0
  fi

  # Stage 3: Generate
  stage_generate "$work_dir" "$concurrency"
  echo ""

  # Stage 4: Produce
  stage_produce "$work_dir" "$brand"
  echo ""

  # Stage 5: Review
  stage_review "$work_dir"
  echo ""

  # Stage 6: Deliver
  stage_deliver "$work_dir" "$brand"
  echo ""

  # Summary
  info "============================================"
  info "COMPLETE"
  info "============================================"
  info "Work dir:   $work_dir"
  info "Scripts:    $work_dir/scripts.json"
  info "Plan:       $work_dir/gen_plan.json"
  info "Generated:  $work_dir/generated/"
  info "Produced:   $work_dir/produced/"
  info "Export:     $work_dir/export/"
  info "============================================"
}

cmd_script() {
  local brand="" product="" goal="$DEFAULT_GOAL" tone="$DEFAULT_TONE"
  local framework="" variants="$DEFAULT_VARIANTS" output="" language="en"

  while [ $# -gt 0 ]; do
    case "$1" in
      --brand) brand="$2"; shift 2 ;;
      --product) product="$2"; shift 2 ;;
      --goal) goal="$2"; shift 2 ;;
      --tone) tone="$2"; shift 2 ;;
      --framework) framework="$2"; shift 2 ;;
      --variants) variants="$2"; shift 2 ;;
      --output) output="$2"; shift 2 ;;
      --language|--lang) language="$2"; shift 2 ;;
      *) error "Unknown option: $1"; exit 1 ;;
    esac
  done

  [ -z "$brand" ] && { error "--brand required"; exit 1; }
  [ -z "$product" ] && { error "--product required"; exit 1; }

  [ -z "$output" ] && output="./scripts-${brand}-$(timestamp).json"

  python3 "$SCRIPT_GEN" \
    --brand "$brand" \
    --product "$product" \
    --goal "$goal" \
    --tone "$tone" \
    ${framework:+--framework "$framework"} \
    --variants "$variants" \
    --language "$language" \
    --output "$output"
}

cmd_generate() {
  local plan="" concurrency="$DEFAULT_CONCURRENCY" output_dir="" dry_run=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --plan) plan="$2"; shift 2 ;;
      --concurrency) concurrency="$2"; shift 2 ;;
      --output-dir|--output) output_dir="$2"; shift 2 ;;
      --dry-run) dry_run=1; shift ;;
      *) error "Unknown option: $1"; exit 1 ;;
    esac
  done

  [ -z "$plan" ] && { error "--plan required"; exit 1; }
  [ -z "$output_dir" ] && output_dir="./generated-$(timestamp)"

  local extra_args=""
  [ "$dry_run" -eq 1 ] && extra_args="--dry-run"

  python3 "$PARALLEL_GEN" \
    --plan "$plan" \
    --concurrency "$concurrency" \
    --output-dir "$output_dir" \
    $extra_args
}

cmd_produce() {
  local work_dir="" brand=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --work-dir) work_dir="$2"; shift 2 ;;
      --brand) brand="$2"; shift 2 ;;
      *) error "Unknown option: $1"; exit 1 ;;
    esac
  done

  [ -z "$work_dir" ] && { error "--work-dir required"; exit 1; }
  stage_produce "$work_dir" "$brand"
}

cmd_review() {
  local input=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --input) input="$2"; shift 2 ;;
      *) if [ -z "$input" ]; then input="$1"; fi; shift ;;
    esac
  done

  [ -z "$input" ] && { error "--input required"; exit 1; }
  bash "$VIDEO_REVIEW" full "$input"
}

cmd_list() {
  local work_dir=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --work-dir) work_dir="$2"; shift 2 ;;
      *) if [ -z "$work_dir" ]; then work_dir="$1"; fi; shift ;;
    esac
  done

  [ -z "$work_dir" ] && { error "--work-dir required"; exit 1; }

  echo "=== Video Compiler Output ==="
  echo "Work dir: $work_dir"
  echo ""

  if [ -f "$work_dir/scripts.json" ]; then
    python3 -c "
import json
s = json.load(open('$work_dir/scripts.json'))
print(f'Brand: {s[\"brand\"]}')
print(f'Product: {s[\"product\"]}')
print(f'Framework: {s[\"framework\"]}')
print(f'Variants: {len(s[\"variants\"])}')
"
  fi

  echo ""
  for dir in generated produced export; do
    if [ -d "$work_dir/$dir" ]; then
      local count
      count=$(find "$work_dir/$dir" -name "*.mp4" -o -name "*.png" | wc -l | tr -d ' ')
      echo "$dir/: $count files"
    fi
  done
}

cmd_batch() {
  local input_dir="" brand="" goal="$DEFAULT_GOAL" tone="$DEFAULT_TONE"

  while [ $# -gt 0 ]; do
    case "$1" in
      --input-dir) input_dir="$2"; shift 2 ;;
      --brand) brand="$2"; shift 2 ;;
      --goal) goal="$2"; shift 2 ;;
      --tone) tone="$2"; shift 2 ;;
      *) error "Unknown option: $1"; exit 1 ;;
    esac
  done

  [ -z "$input_dir" ] && { error "--input-dir required"; exit 1; }
  [ -z "$brand" ] && { error "--brand required"; exit 1; }

  info "Batch mode: processing all briefs in $input_dir"

  for brief in "$input_dir"/*.json; do
    [ -f "$brief" ] || continue
    local product
    product=$(python3 -c "import json; print(json.load(open('$brief')).get('product', '$(basename "$brief" .json)'))" 2>/dev/null)

    info "Processing: $product"
    cmd_run --brand "$brand" --product "$product" --goal "$goal" --tone "$tone" || {
      warn "Failed: $product"
    }
  done
}

# ============================================================
# MAIN
# ============================================================
case "${1:-help}" in
  run)      shift; cmd_run "$@" ;;
  script)   shift; cmd_script "$@" ;;
  generate) shift; cmd_generate "$@" ;;
  produce)  shift; cmd_produce "$@" ;;
  review)   shift; cmd_review "$@" ;;
  list)     shift; cmd_list "$@" ;;
  batch)    shift; cmd_batch "$@" ;;
  help|--help|-h)
    echo "video-compiler.sh — GAIA Video Compiler"
    echo ""
    echo "Commands:"
    echo "  run       Full pipeline: script → plan → generate → produce → review → deliver"
    echo "  script    Generate video scripts with ad frameworks (Dreami)"
    echo "  generate  Parallel video generation from plan (Sora/Kling/Wan)"
    echo "  produce   Post-production via VideoForge"
    echo "  review    Video QA (contact sheet, motion-diff, score)"
    echo "  list      Show contents of a work directory"
    echo "  batch     Process multiple briefs from a directory"
    echo ""
    echo "Run options:"
    echo "  --brand <name>       Brand (mirra, pinxin-vegan, etc.)"
    echo "  --product <desc>     Product description"
    echo "  --goal <goal>        awareness | conversion | retargeting"
    echo "  --tone <tone>        authentic | professional | playful | etc."
    echo "  --framework <fw>     ugc_testimonial | pas | slap | emotional_storytelling"
    echo "  --mode <mode>        assembled | single-shot | combinatorial"
    echo "  --variants <n>       Number of script variants (default: 3)"
    echo "  --concurrency <n>    Parallel generation concurrency (default: 5)"
    echo "  --plan-only          Generate scripts + plan, stop before generation"
    echo "  --resume <dir>       Resume from existing work directory"
    echo "  --language <lang>    en | ms | my (default: en)"
    ;;
  *)
    error "Unknown command: $1"
    echo "Run: video-compiler.sh help"
    exit 1
    ;;
esac
