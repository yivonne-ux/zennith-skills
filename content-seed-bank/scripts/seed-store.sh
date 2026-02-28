#!/usr/bin/env bash
# seed-store.sh — Content Seed Bank CLI for GAIA CORP-OS
# macOS-compatible (bash 3.2, no declare -A, no ${var,,}, no timeout)
# Data: ~/.openclaw/workspace/data/seeds.jsonl
# Lock: /tmp/seed-store.lock

set -euo pipefail

DATA_DIR="$HOME/.openclaw/workspace/data"
DATA_FILE="$DATA_DIR/seeds.jsonl"
LOCK_FILE="/tmp/seed-store.lock"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die() {
  echo "ERROR: $*" >&2
  exit 1
}

warn() {
  echo "WARN: $*" >&2
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
    # Check if holding process is still alive
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
  echo "seed-${ts}-${rand}"
}

# --- Epoch ms ---

epoch_ms() {
  python3 -c "import time; print(int(time.time()*1000))"
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat <<'USAGE'
seed-store.sh — Content Seed Bank CLI

USAGE:
  seed-store.sh <command> [options]

COMMANDS:
  add       Add a new seed to the bank
  query     Query seeds with filters
  tag       Update performance metrics on a seed
  update    Update arbitrary fields on a seed
  count     Count seeds matching filters
  top       Quick shorthand for top performers
  --help    Show this help

ADD OPTIONS:
  --type <type>           hook|copy|image|video|ad|storyboard|template|headline|cta (required)
  --text <text>           Content text or file path (required)
  --tags <t1,t2,...>      Comma-separated tags
  --source <agent>        Source agent name (e.g., artemis, dreami, iris)
  --source-type <stype>   trend-scout|cso-pipeline|manual|winning-ad
  --campaign <id>         Campaign ID (e.g., cso-42)
  --channel <ch>          ig|tiktok|shopee|edm|facebook
  --persona <p>           health-seeker|foodie|conscious|parent|genz
  --parent <seed_id>      Parent seed ID (for lineage)
  --generation <n>        Generation number (default: 1)
  --status <s>            draft|published|tested|winner|retired (default: draft)

QUERY OPTIONS:
  --id <seed_id>          Find by exact ID
  --type <type>           Filter by type
  --tag <tag>             Filter by tag (matches any tag in array)
  --channel <ch>          Filter by channel
  --persona <p>           Filter by persona
  --status <s>            Filter by status
  --campaign <id>         Filter by campaign
  --source <agent>        Filter by source agent
  --sort <mode>           recent (default) | performance (by CTR desc, nulls last)
  --top <N>               Limit results (default: 10)

TAG OPTIONS:
  --id <seed_id>          Seed to tag (required)
  --performance <metrics> ctr:X,roas:Y,impressions:Z,engagement:W
  --status <s>            Optionally change status too

UPDATE OPTIONS:
  --id <seed_id>          Seed to update (required)
  --status <s>            New status
  --channel <ch>          New channel
  --type <type>           New type
  --text <text>           New text
  --tags <t1,t2>          New tags (replaces existing)
  --campaign <id>         New campaign ID
  --persona <p>           New persona
  --source <agent>        New source agent
  --source-type <stype>   New source type

COUNT OPTIONS:
  Same filters as query (--type, --tag, --channel, --persona, --status, --campaign, --source)

TOP OPTIONS:
  --type <type>           Filter by type
  --channel <ch>          Filter by channel
  --metric <m>            ctr|roas|impressions|engagement (default: ctr)
  --top <N>               Number of results (default: 5)

EXAMPLES:
  seed-store.sh add --type hook --text "Rendang can be vegan" --tags "trending,vegan" --source artemis --source-type trend-scout
  seed-store.sh query --type hook --tag tiktok --top 10
  seed-store.sh query --channel ig --status winner --sort performance
  seed-store.sh tag --id seed-123 --performance "ctr:3.2,roas:4.1" --status winner
  seed-store.sh update --id seed-123 --status published
  seed-store.sh count --type hook --status winner
  seed-store.sh top --type hook --channel tiktok --metric ctr --top 5
USAGE
}

# ---------------------------------------------------------------------------
# Command: add
# ---------------------------------------------------------------------------

cmd_add() {
  local seed_type="" text="" tags="" source_agent="" source_type=""
  local campaign_id="" channel="" persona="" parent_seed="" generation="1" status="draft"

  while [ $# -gt 0 ]; do
    case "$1" in
      --type)        seed_type="$2";   shift 2 ;;
      --text)        text="$2";        shift 2 ;;
      --tags)        tags="$2";        shift 2 ;;
      --source)      source_agent="$2"; shift 2 ;;
      --source-type) source_type="$2"; shift 2 ;;
      --campaign)    campaign_id="$2"; shift 2 ;;
      --channel)     channel="$2";     shift 2 ;;
      --persona)     persona="$2";     shift 2 ;;
      --parent)      parent_seed="$2"; shift 2 ;;
      --generation)  generation="$2";  shift 2 ;;
      --status)      status="$2";      shift 2 ;;
      *) die "add: unknown option: $1" ;;
    esac
  done

  # Validate required fields
  [ -z "$seed_type" ] && die "add: --type is required"
  [ -z "$text" ]      && die "add: --text is required"

  local seed_id
  seed_id=$(generate_id)
  local ts
  ts=$(epoch_ms)

  # Build tags JSON array
  local tags_json="[]"
  if [ -n "$tags" ]; then
    tags_json=$(python3 -c "
import json, sys
tags = [t.strip() for t in sys.argv[1].split(',') if t.strip()]
print(json.dumps(tags))
" "$tags")
  fi

  # Build the seed JSON
  python3 -c "
import json, sys

seed = {
    'id': sys.argv[1],
    'ts': int(sys.argv[2]),
    'type': sys.argv[3],
    'text': sys.argv[4],
    'tags': json.loads(sys.argv[5]),
    'source_agent': sys.argv[6] if sys.argv[6] else None,
    'source_type': sys.argv[7] if sys.argv[7] else None,
    'campaign_id': sys.argv[8] if sys.argv[8] else None,
    'channel': sys.argv[9] if sys.argv[9] else None,
    'persona': sys.argv[10] if sys.argv[10] else None,
    'performance': {'ctr': None, 'roas': None, 'impressions': None, 'engagement': None},
    'parent_seed': sys.argv[11] if sys.argv[11] else None,
    'generation': int(sys.argv[12]),
    'status': sys.argv[13]
}
print(json.dumps(seed, ensure_ascii=False))
" "$seed_id" "$ts" "$seed_type" "$text" "$tags_json" \
  "$source_agent" "$source_type" "$campaign_id" "$channel" "$persona" \
  "$parent_seed" "$generation" "$status" >> "$DATA_FILE"

  echo "$seed_id"
}

# ---------------------------------------------------------------------------
# Command: query
# ---------------------------------------------------------------------------

cmd_query() {
  local filter_id="" filter_type="" filter_tag="" filter_channel=""
  local filter_persona="" filter_status="" filter_campaign="" filter_source=""
  local sort_mode="recent" top_n="10"

  while [ $# -gt 0 ]; do
    case "$1" in
      --id)       filter_id="$2";       shift 2 ;;
      --type)     filter_type="$2";     shift 2 ;;
      --tag)      filter_tag="$2";      shift 2 ;;
      --channel)  filter_channel="$2";  shift 2 ;;
      --persona)  filter_persona="$2";  shift 2 ;;
      --status)   filter_status="$2";   shift 2 ;;
      --campaign) filter_campaign="$2"; shift 2 ;;
      --source)   filter_source="$2";   shift 2 ;;
      --sort)     sort_mode="$2";       shift 2 ;;
      --top)      top_n="$2";           shift 2 ;;
      *) die "query: unknown option: $1" ;;
    esac
  done

  ensure_data_file
  if [ ! -s "$DATA_FILE" ]; then
    return 0
  fi

  python3 -c "
import json, sys

filter_id       = sys.argv[1] if sys.argv[1] else None
filter_type     = sys.argv[2] if sys.argv[2] else None
filter_tag      = sys.argv[3] if sys.argv[3] else None
filter_channel  = sys.argv[4] if sys.argv[4] else None
filter_persona  = sys.argv[5] if sys.argv[5] else None
filter_status   = sys.argv[6] if sys.argv[6] else None
filter_campaign = sys.argv[7] if sys.argv[7] else None
filter_source   = sys.argv[8] if sys.argv[8] else None
sort_mode       = sys.argv[9]
top_n           = int(sys.argv[10])
data_file       = sys.argv[11]

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
        # Apply filters
        if filter_id and seed.get('id') != filter_id:
            continue
        if filter_type and seed.get('type') != filter_type:
            continue
        if filter_tag and filter_tag not in seed.get('tags', []):
            continue
        if filter_channel and seed.get('channel') != filter_channel:
            continue
        if filter_persona and seed.get('persona') != filter_persona:
            continue
        if filter_status and seed.get('status') != filter_status:
            continue
        if filter_campaign and seed.get('campaign_id') != filter_campaign:
            continue
        if filter_source and seed.get('source_agent') != filter_source:
            continue
        seeds.append(seed)

# Sort
if sort_mode == 'performance':
    def perf_key(s):
        perf = s.get('performance', {})
        ctr = perf.get('ctr') if perf else None
        if ctr is None:
            return (1, 0)  # nulls last
        return (0, -ctr)
    seeds.sort(key=perf_key)
else:
    # recent: by ts descending
    seeds.sort(key=lambda s: s.get('ts', 0), reverse=True)

# Limit
seeds = seeds[:top_n]

for s in seeds:
    print(json.dumps(s, ensure_ascii=False))
" "$filter_id" "$filter_type" "$filter_tag" "$filter_channel" \
  "$filter_persona" "$filter_status" "$filter_campaign" "$filter_source" \
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
import json, sys, os

target_id   = sys.argv[1]
perf_str    = sys.argv[2]
new_status  = sys.argv[3]
data_file   = sys.argv[4]
tmp_file    = sys.argv[5]

# Parse performance string: 'ctr:3.2,roas:4.1,...'
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
# Command: update
# ---------------------------------------------------------------------------

cmd_update() {
  local target_id=""
  local upd_status="" upd_channel="" upd_type="" upd_text="" upd_tags=""
  local upd_campaign="" upd_persona="" upd_source="" upd_source_type=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --id)          target_id="$2";      shift 2 ;;
      --status)      upd_status="$2";     shift 2 ;;
      --channel)     upd_channel="$2";    shift 2 ;;
      --type)        upd_type="$2";       shift 2 ;;
      --text)        upd_text="$2";       shift 2 ;;
      --tags)        upd_tags="$2";       shift 2 ;;
      --campaign)    upd_campaign="$2";   shift 2 ;;
      --persona)     upd_persona="$2";    shift 2 ;;
      --source)      upd_source="$2";     shift 2 ;;
      --source-type) upd_source_type="$2"; shift 2 ;;
      *) die "update: unknown option: $1" ;;
    esac
  done

  [ -z "$target_id" ] && die "update: --id is required"

  ensure_data_file
  [ ! -s "$DATA_FILE" ] && die "update: data file is empty"

  acquire_lock

  local tmp_file
  tmp_file=$(mktemp "${DATA_FILE}.tmp.XXXXXX")

  local found
  found=$(python3 -c "
import json, sys

target_id      = sys.argv[1]
upd_status     = sys.argv[2]
upd_channel    = sys.argv[3]
upd_type       = sys.argv[4]
upd_text       = sys.argv[5]
upd_tags       = sys.argv[6]
upd_campaign   = sys.argv[7]
upd_persona    = sys.argv[8]
upd_source     = sys.argv[9]
upd_source_type = sys.argv[10]
data_file      = sys.argv[11]
tmp_file       = sys.argv[12]

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
            if upd_status:
                seed['status'] = upd_status
            if upd_channel:
                seed['channel'] = upd_channel
            if upd_type:
                seed['type'] = upd_type
            if upd_text:
                seed['text'] = upd_text
            if upd_tags:
                seed['tags'] = [t.strip() for t in upd_tags.split(',') if t.strip()]
            if upd_campaign:
                seed['campaign_id'] = upd_campaign
            if upd_persona:
                seed['persona'] = upd_persona
            if upd_source:
                seed['source_agent'] = upd_source
            if upd_source_type:
                seed['source_type'] = upd_source_type
            wf.write(json.dumps(seed, ensure_ascii=False) + '\n')
        else:
            wf.write(stripped + '\n')

print('1' if found else '0')
" "$target_id" "$upd_status" "$upd_channel" "$upd_type" "$upd_text" \
  "$upd_tags" "$upd_campaign" "$upd_persona" "$upd_source" "$upd_source_type" \
  "$DATA_FILE" "$tmp_file")

  if [ "$found" = "1" ]; then
    mv "$tmp_file" "$DATA_FILE"
    echo "OK: updated $target_id"
  else
    rm -f "$tmp_file"
    release_lock
    die "update: seed '$target_id' not found"
  fi
}

# ---------------------------------------------------------------------------
# Command: count
# ---------------------------------------------------------------------------

cmd_count() {
  local filter_type="" filter_tag="" filter_channel=""
  local filter_persona="" filter_status="" filter_campaign="" filter_source=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --type)     filter_type="$2";     shift 2 ;;
      --tag)      filter_tag="$2";      shift 2 ;;
      --channel)  filter_channel="$2";  shift 2 ;;
      --persona)  filter_persona="$2";  shift 2 ;;
      --status)   filter_status="$2";   shift 2 ;;
      --campaign) filter_campaign="$2"; shift 2 ;;
      --source)   filter_source="$2";   shift 2 ;;
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

filter_type     = sys.argv[1] if sys.argv[1] else None
filter_tag      = sys.argv[2] if sys.argv[2] else None
filter_channel  = sys.argv[3] if sys.argv[3] else None
filter_persona  = sys.argv[4] if sys.argv[4] else None
filter_status   = sys.argv[5] if sys.argv[5] else None
filter_campaign = sys.argv[6] if sys.argv[6] else None
filter_source   = sys.argv[7] if sys.argv[7] else None
data_file       = sys.argv[8]

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
        if filter_tag and filter_tag not in seed.get('tags', []):
            continue
        if filter_channel and seed.get('channel') != filter_channel:
            continue
        if filter_persona and seed.get('persona') != filter_persona:
            continue
        if filter_status and seed.get('status') != filter_status:
            continue
        if filter_campaign and seed.get('campaign_id') != filter_campaign:
            continue
        if filter_source and seed.get('source_agent') != filter_source:
            continue
        count += 1

print(count)
" "$filter_type" "$filter_tag" "$filter_channel" "$filter_persona" \
  "$filter_status" "$filter_campaign" "$filter_source" "$DATA_FILE"
}

# ---------------------------------------------------------------------------
# Command: top
# ---------------------------------------------------------------------------

cmd_top() {
  local filter_type="" filter_channel="" metric="ctr" top_n="5"

  while [ $# -gt 0 ]; do
    case "$1" in
      --type)    filter_type="$2";    shift 2 ;;
      --channel) filter_channel="$2"; shift 2 ;;
      --metric)  metric="$2";         shift 2 ;;
      --top)     top_n="$2";          shift 2 ;;
      *) die "top: unknown option: $1" ;;
    esac
  done

  ensure_data_file
  if [ ! -s "$DATA_FILE" ]; then
    return 0
  fi

  python3 -c "
import json, sys

filter_type    = sys.argv[1] if sys.argv[1] else None
filter_channel = sys.argv[2] if sys.argv[2] else None
metric         = sys.argv[3]
top_n          = int(sys.argv[4])
data_file      = sys.argv[5]

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
        if filter_type and seed.get('type') != filter_type:
            continue
        if filter_channel and seed.get('channel') != filter_channel:
            continue
        # Only include seeds that have the metric set
        perf = seed.get('performance', {})
        if perf is None:
            continue
        val = perf.get(metric)
        if val is None:
            continue
        seeds.append(seed)

# Sort by metric descending
seeds.sort(key=lambda s: s.get('performance', {}).get(metric, 0), reverse=True)
seeds = seeds[:top_n]

for s in seeds:
    print(json.dumps(s, ensure_ascii=False))
" "$filter_type" "$filter_channel" "$metric" "$top_n" "$DATA_FILE"
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
  update)
    cmd_update "$@"
    ;;
  count)
    cmd_count "$@"
    ;;
  top)
    cmd_top "$@"
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
