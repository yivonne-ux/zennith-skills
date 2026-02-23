#!/usr/bin/env bash
# image-seed.sh — Image Seed Bank CLI for GAIA CORP-OS
# macOS-compatible (bash 3.2, no declare -A, no ${var,,}, no timeout)
# Data: ~/.openclaw/workspace/data/image-seeds.jsonl
# Lock: /tmp/image-seed.lock

set -euo pipefail

DATA_DIR="$HOME/.openclaw/workspace/data"
DATA_FILE="$DATA_DIR/image-seeds.jsonl"
LOCK_FILE="/tmp/image-seed.lock"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die() {
  echo "ERROR: $*" >&2
  exit 1
}

ensure_data_file() {
  if [ ! -d "$DATA_DIR" ]; then
    mkdir -p "$DATA_DIR"
  fi
  if [ ! -f "$DATA_FILE" ]; then
    touch "$DATA_FILE"
  fi
}

# --- Locking (flock-free, macOS-safe) ---

acquire_lock() {
  local attempts=0
  while [ $attempts -lt 50 ]; do
    if ( set -o noclobber; echo $$ > "$LOCK_FILE" ) 2>/dev/null; then
      trap release_lock EXIT INT TERM HUP
      return 0
    fi
    local lock_pid
    lock_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [ -n "$lock_pid" ] && ! kill -0 "$lock_pid" 2>/dev/null; then
      rm -f "$LOCK_FILE"
      continue
    fi
    attempts=$((attempts + 1))
    sleep 0.1
  done
  die "Could not acquire lock after 5 seconds. Stale lock? Remove $LOCK_FILE"
}

release_lock() {
  rm -f "$LOCK_FILE"
}

# --- ID generation ---

generate_id() {
  local ts
  ts=$(date +%s)
  local rand
  rand=$(python3 -c "import random,string; print(''.join(random.choices(string.ascii_lowercase+string.digits,k=4)))")
  echo "img-${ts}-${rand}"
}

# --- Epoch ms ---

epoch_ms() {
  python3 -c "import time; print(int(time.time()*1000))"
}

# --- Today ISO ---

today_iso() {
  date +%Y-%m-%d
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat <<'USAGE'
image-seed.sh — Image Seed Bank CLI

USAGE:
  image-seed.sh <command> [options]

COMMANDS:
  add       Store a new image seed
  query     Query seeds with filters
  tag       Update performance metrics on a seed
  promote   Mark a seed as winner (shorthand)
  export    Set drive_url on a seed
  count     Count seeds matching filters
  --help    Show this help

ADD OPTIONS:
  --type <type>           key_visual|key_image|logo|model|action|tone|headline (required)
  --file-path <path>      Path to image file (required)
  --drive-url <url>       Google Drive URL
  --brand <slug>          Brand slug (e.g., gaia-eats)
  --campaign <id>         Campaign ID
  --tags <t1,t2,...>      Comma-separated tags
  --colors <#hex,#hex>    Comma-separated hex colors
  --mood <text>           Mood description
  --subject <text>        What the image depicts
  --prompt <text>         NanoBanana/generation prompt
  --gen-params <k:v,...>  Generation params (model:x,aspect_ratio:y)
  --parent <seed_id>      Parent seed ID (for lineage)
  --generation <n>        Generation number (default: 1)
  --status <s>            draft|approved|winner|retired (default: draft)
  --created-by <agent>    Which agent created this (default: artee)

QUERY OPTIONS:
  --id <seed_id>          Find by exact ID
  --type <type>           Filter by type
  --brand <slug>          Filter by brand
  --tag <tag>             Filter by tag (matches any tag in array)
  --mood <text>           Filter by mood (substring match)
  --status <s>            Filter by status
  --campaign <id>         Filter by campaign
  --created-by <agent>    Filter by creator
  --sort <mode>           recent (default) | performance (by CTR desc)
  --top <N>               Limit results (default: 10)

TAG OPTIONS:
  --id <seed_id>          Seed to tag (required)
  --performance <metrics> ctr:X,roas:Y,impressions:Z
  --status <s>            Optionally change status too

PROMOTE OPTIONS:
  --id <seed_id>          Seed to promote to winner (required)

EXPORT OPTIONS:
  --id <seed_id>          Seed to export (required)
  --drive-url <url>       Google Drive URL to set

COUNT OPTIONS:
  Same filters as query (--type, --brand, --tag, --status, --campaign, --created-by)

EXAMPLES:
  image-seed.sh add --type key_visual --file-path "brands/gaia-eats/hero.jpg" --brand gaia-eats --tags "rendang,vegan" --created-by artee
  image-seed.sh query --type key_visual --brand gaia-eats --top 10
  image-seed.sh query --status winner --sort performance
  image-seed.sh tag --id img-123 --performance "ctr:3.2,roas:4.1" --status winner
  image-seed.sh promote --id img-123
  image-seed.sh export --id img-123 --drive-url "https://drive.google.com/..."
  image-seed.sh count --type key_visual --brand gaia-eats
USAGE
}

# ---------------------------------------------------------------------------
# Command: add
# ---------------------------------------------------------------------------

cmd_add() {
  local seed_type="" file_path="" drive_url="" brand="" campaign=""
  local tags="" colors="" mood="" subject="" prompt="" gen_params=""
  local parent_seed="" generation="1" status="draft" created_by="artee"

  while [ $# -gt 0 ]; do
    case "$1" in
      --type)        seed_type="$2";  shift 2 ;;
      --file-path)   file_path="$2";  shift 2 ;;
      --drive-url)   drive_url="$2";  shift 2 ;;
      --brand)       brand="$2";      shift 2 ;;
      --campaign)    campaign="$2";   shift 2 ;;
      --tags)        tags="$2";       shift 2 ;;
      --colors)      colors="$2";     shift 2 ;;
      --mood)        mood="$2";       shift 2 ;;
      --subject)     subject="$2";    shift 2 ;;
      --prompt)      prompt="$2";     shift 2 ;;
      --gen-params)  gen_params="$2"; shift 2 ;;
      --parent)      parent_seed="$2"; shift 2 ;;
      --generation)  generation="$2"; shift 2 ;;
      --status)      status="$2";     shift 2 ;;
      --created-by)  created_by="$2"; shift 2 ;;
      *) die "add: unknown option: $1" ;;
    esac
  done

  [ -z "$seed_type" ] && die "add: --type is required"
  [ -z "$file_path" ] && die "add: --file-path is required"

  local seed_id
  seed_id=$(generate_id)
  local ts
  ts=$(epoch_ms)
  local created_at
  created_at=$(today_iso)

  # Build JSON arrays for tags and colors
  local tags_json="[]"
  if [ -n "$tags" ]; then
    tags_json=$(python3 -c "
import json, sys
tags = [t.strip() for t in sys.argv[1].split(',') if t.strip()]
print(json.dumps(tags))
" "$tags")
  fi

  local colors_json="[]"
  if [ -n "$colors" ]; then
    colors_json=$(python3 -c "
import json, sys
colors = [c.strip() for c in sys.argv[1].split(',') if c.strip()]
print(json.dumps(colors))
" "$colors")
  fi

  # Build generation_params object
  local gen_params_json="null"
  if [ -n "$gen_params" ]; then
    gen_params_json=$(python3 -c "
import json, sys
params = {}
for pair in sys.argv[1].split(','):
    pair = pair.strip()
    if ':' in pair:
        k, v = pair.split(':', 1)
        params[k.strip()] = v.strip()
print(json.dumps(params))
" "$gen_params")
  fi

  python3 -c "
import json, sys

seed = {
    'id': sys.argv[1],
    'ts': int(sys.argv[2]),
    'type': sys.argv[3],
    'file_path': sys.argv[4],
    'drive_url': sys.argv[5] if sys.argv[5] else None,
    'brand': sys.argv[6] if sys.argv[6] else None,
    'campaign': sys.argv[7] if sys.argv[7] else None,
    'tags': json.loads(sys.argv[8]),
    'colors': json.loads(sys.argv[9]),
    'mood': sys.argv[10] if sys.argv[10] else None,
    'subject': sys.argv[11] if sys.argv[11] else None,
    'nanobanana_prompt': sys.argv[12] if sys.argv[12] else None,
    'generation_params': json.loads(sys.argv[13]) if sys.argv[13] != 'null' else None,
    'parent_seed': sys.argv[14] if sys.argv[14] else None,
    'generation': int(sys.argv[15]),
    'performance': {'ctr': None, 'roas': None, 'impressions': None},
    'status': sys.argv[16],
    'created_by': sys.argv[17],
    'created_at': sys.argv[18]
}
print(json.dumps(seed, ensure_ascii=False))
" "$seed_id" "$ts" "$seed_type" "$file_path" "$drive_url" \
  "$brand" "$campaign" "$tags_json" "$colors_json" \
  "$mood" "$subject" "$prompt" "$gen_params_json" \
  "$parent_seed" "$generation" "$status" "$created_by" "$created_at" >> "$DATA_FILE"

  echo "$seed_id"
}

# ---------------------------------------------------------------------------
# Command: query
# ---------------------------------------------------------------------------

cmd_query() {
  local filter_id="" filter_type="" filter_brand="" filter_tag=""
  local filter_mood="" filter_status="" filter_campaign="" filter_created_by=""
  local sort_mode="recent" top_n="10"

  while [ $# -gt 0 ]; do
    case "$1" in
      --id)         filter_id="$2";         shift 2 ;;
      --type)       filter_type="$2";       shift 2 ;;
      --brand)      filter_brand="$2";      shift 2 ;;
      --tag)        filter_tag="$2";        shift 2 ;;
      --mood)       filter_mood="$2";       shift 2 ;;
      --status)     filter_status="$2";     shift 2 ;;
      --campaign)   filter_campaign="$2";   shift 2 ;;
      --created-by) filter_created_by="$2"; shift 2 ;;
      --sort)       sort_mode="$2";         shift 2 ;;
      --top)        top_n="$2";             shift 2 ;;
      *) die "query: unknown option: $1" ;;
    esac
  done

  ensure_data_file
  if [ ! -s "$DATA_FILE" ]; then
    return 0
  fi

  python3 -c "
import json, sys

filter_id         = sys.argv[1] if sys.argv[1] else None
filter_type       = sys.argv[2] if sys.argv[2] else None
filter_brand      = sys.argv[3] if sys.argv[3] else None
filter_tag        = sys.argv[4] if sys.argv[4] else None
filter_mood       = sys.argv[5] if sys.argv[5] else None
filter_status     = sys.argv[6] if sys.argv[6] else None
filter_campaign   = sys.argv[7] if sys.argv[7] else None
filter_created_by = sys.argv[8] if sys.argv[8] else None
sort_mode         = sys.argv[9]
top_n             = int(sys.argv[10])
data_file         = sys.argv[11]

seeds = []
with open(data_file, 'r') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            seed = json.loads(line)
        except json.JSONDecodeError:
            continue
        if filter_id and seed.get('id') != filter_id:
            continue
        if filter_type and seed.get('type') != filter_type:
            continue
        if filter_brand and seed.get('brand') != filter_brand:
            continue
        if filter_tag and filter_tag not in seed.get('tags', []):
            continue
        if filter_mood and filter_mood.lower() not in (seed.get('mood') or '').lower():
            continue
        if filter_status and seed.get('status') != filter_status:
            continue
        if filter_campaign and seed.get('campaign') != filter_campaign:
            continue
        if filter_created_by and seed.get('created_by') != filter_created_by:
            continue
        seeds.append(seed)

if sort_mode == 'performance':
    def perf_key(s):
        perf = s.get('performance', {})
        ctr = perf.get('ctr') if perf else None
        if ctr is None:
            return (1, 0)
        return (0, -ctr)
    seeds.sort(key=perf_key)
else:
    seeds.sort(key=lambda s: s.get('ts', 0), reverse=True)

seeds = seeds[:top_n]

for s in seeds:
    print(json.dumps(s, ensure_ascii=False))
" "$filter_id" "$filter_type" "$filter_brand" "$filter_tag" \
  "$filter_mood" "$filter_status" "$filter_campaign" "$filter_created_by" \
  "$sort_mode" "$top_n" "$DATA_FILE"
}

# ---------------------------------------------------------------------------
# Command: tag
# ---------------------------------------------------------------------------

cmd_tag() {
  local target_id="" performance_str="" new_status=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --id)          target_id="$2";       shift 2 ;;
      --performance) performance_str="$2"; shift 2 ;;
      --status)      new_status="$2";      shift 2 ;;
      *) die "tag: unknown option: $1" ;;
    esac
  done

  [ -z "$target_id" ] && die "tag: --id is required"
  [ -z "$performance_str" ] && [ -z "$new_status" ] && die "tag: --performance or --status required"

  ensure_data_file
  [ ! -s "$DATA_FILE" ] && die "tag: data file is empty"

  acquire_lock

  local tmp_file
  tmp_file=$(mktemp "${DATA_FILE}.tmp.XXXXXX")

  local found
  found=$(python3 -c "
import json, sys

target_id   = sys.argv[1]
perf_str    = sys.argv[2]
new_status  = sys.argv[3]
data_file   = sys.argv[4]
tmp_file    = sys.argv[5]

perf_updates = {}
if perf_str:
    for pair in perf_str.split(','):
        pair = pair.strip()
        if ':' in pair:
            k, v = pair.split(':', 1)
            k = k.strip()
            v = v.strip()
            try:
                perf_updates[k] = float(v)
            except ValueError:
                perf_updates[k] = v

found = False
with open(data_file, 'r') as rf, open(tmp_file, 'w') as wf:
    for line in rf:
        stripped = line.strip()
        if not stripped:
            continue
        try:
            seed = json.loads(stripped)
        except json.JSONDecodeError:
            wf.write(line)
            continue
        if seed.get('id') == target_id:
            found = True
            perf = seed.get('performance', {})
            if perf is None:
                perf = {}
            for k, v in perf_updates.items():
                perf[k] = v
            seed['performance'] = perf
            if new_status:
                seed['status'] = new_status
            wf.write(json.dumps(seed, ensure_ascii=False) + '\n')
        else:
            wf.write(stripped + '\n')

print('1' if found else '0')
" "$target_id" "$performance_str" "$new_status" "$DATA_FILE" "$tmp_file")

  if [ "$found" = "1" ]; then
    mv "$tmp_file" "$DATA_FILE"
    echo "OK: tagged $target_id"
  else
    rm -f "$tmp_file"
    release_lock
    die "tag: seed '$target_id' not found"
  fi
}

# ---------------------------------------------------------------------------
# Command: promote
# ---------------------------------------------------------------------------

cmd_promote() {
  local target_id=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --id) target_id="$2"; shift 2 ;;
      *) die "promote: unknown option: $1" ;;
    esac
  done

  [ -z "$target_id" ] && die "promote: --id is required"

  # Reuse tag command to set status=winner
  cmd_tag --id "$target_id" --status winner
  echo "OK: promoted $target_id to winner"
}

# ---------------------------------------------------------------------------
# Command: export
# ---------------------------------------------------------------------------

cmd_export() {
  local target_id="" drive_url=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --id)        target_id="$2"; shift 2 ;;
      --drive-url) drive_url="$2"; shift 2 ;;
      *) die "export: unknown option: $1" ;;
    esac
  done

  [ -z "$target_id" ] && die "export: --id is required"
  [ -z "$drive_url" ] && die "export: --drive-url is required"

  ensure_data_file
  [ ! -s "$DATA_FILE" ] && die "export: data file is empty"

  acquire_lock

  local tmp_file
  tmp_file=$(mktemp "${DATA_FILE}.tmp.XXXXXX")

  local found
  found=$(python3 -c "
import json, sys

target_id  = sys.argv[1]
drive_url  = sys.argv[2]
data_file  = sys.argv[3]
tmp_file   = sys.argv[4]

found = False
with open(data_file, 'r') as rf, open(tmp_file, 'w') as wf:
    for line in rf:
        stripped = line.strip()
        if not stripped:
            continue
        try:
            seed = json.loads(stripped)
        except json.JSONDecodeError:
            wf.write(line)
            continue
        if seed.get('id') == target_id:
            found = True
            seed['drive_url'] = drive_url
            wf.write(json.dumps(seed, ensure_ascii=False) + '\n')
        else:
            wf.write(stripped + '\n')

print('1' if found else '0')
" "$target_id" "$drive_url" "$DATA_FILE" "$tmp_file")

  if [ "$found" = "1" ]; then
    mv "$tmp_file" "$DATA_FILE"
    echo "OK: exported $target_id with drive URL"
  else
    rm -f "$tmp_file"
    release_lock
    die "export: seed '$target_id' not found"
  fi
}

# ---------------------------------------------------------------------------
# Command: count
# ---------------------------------------------------------------------------

cmd_count() {
  local filter_type="" filter_brand="" filter_tag=""
  local filter_status="" filter_campaign="" filter_created_by=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --type)       filter_type="$2";       shift 2 ;;
      --brand)      filter_brand="$2";      shift 2 ;;
      --tag)        filter_tag="$2";        shift 2 ;;
      --status)     filter_status="$2";     shift 2 ;;
      --campaign)   filter_campaign="$2";   shift 2 ;;
      --created-by) filter_created_by="$2"; shift 2 ;;
      *) die "count: unknown option: $1" ;;
    esac
  done

  ensure_data_file
  if [ ! -s "$DATA_FILE" ]; then
    echo "0"
    return 0
  fi

  python3 -c "
import json, sys

filter_type       = sys.argv[1] if sys.argv[1] else None
filter_brand      = sys.argv[2] if sys.argv[2] else None
filter_tag        = sys.argv[3] if sys.argv[3] else None
filter_status     = sys.argv[4] if sys.argv[4] else None
filter_campaign   = sys.argv[5] if sys.argv[5] else None
filter_created_by = sys.argv[6] if sys.argv[6] else None
data_file         = sys.argv[7]

count = 0
with open(data_file, 'r') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            seed = json.loads(line)
        except json.JSONDecodeError:
            continue
        if filter_type and seed.get('type') != filter_type:
            continue
        if filter_brand and seed.get('brand') != filter_brand:
            continue
        if filter_tag and filter_tag not in seed.get('tags', []):
            continue
        if filter_status and seed.get('status') != filter_status:
            continue
        if filter_campaign and seed.get('campaign') != filter_campaign:
            continue
        if filter_created_by and seed.get('created_by') != filter_created_by:
            continue
        count += 1

print(count)
" "$filter_type" "$filter_brand" "$filter_tag" \
  "$filter_status" "$filter_campaign" "$filter_created_by" "$DATA_FILE"
}

# ---------------------------------------------------------------------------
# Main dispatch
# ---------------------------------------------------------------------------

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

COMMAND="$1"
shift

case "$COMMAND" in
  add)
    ensure_data_file
    acquire_lock
    cmd_add "$@"
    ;;
  query)
    cmd_query "$@"
    ;;
  tag)
    cmd_tag "$@"
    ;;
  promote)
    cmd_promote "$@"
    ;;
  export)
    cmd_export "$@"
    ;;
  count)
    cmd_count "$@"
    ;;
  --help|-h|help)
    usage
    exit 0
    ;;
  *)
    die "Unknown command: $COMMAND. Run with --help for usage."
    ;;
esac

# Ensure clean exit
release_lock 2>/dev/null || true
trap - EXIT
exit 0
