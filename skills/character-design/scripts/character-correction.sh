#!/bin/bash
# character-correction.sh — Notion-driven character correction loop
# Polls Notion Creative Review for "Needs Revision" character pages,
# parses feedback, triggers regeneration, uploads results back.
# macOS Bash 3.2 compatible.

set -euo pipefail

###############################################################################
# Config
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LEARNINGS_FILE="$SKILL_DIR/learnings.jsonl"
ENV_FILE="$HOME/.openclaw/.env"
NOTION_API_VERSION="2022-06-28"
CHARACTERS_DIR="$HOME/.openclaw/workspace/data/characters"
IMAGES_DIR="$HOME/.openclaw/workspace/data/images/gaia-os"
NANOBANANA="$HOME/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh"
NOTION_REVIEW="$HOME/.openclaw/skills/notion-sync/scripts/notion-creative-review.sh"
GDRIVE_UPLOAD="$HOME/.openclaw/skills/notion-sync/scripts/gdrive-upload.sh"
CONFIG_FILE="$HOME/.openclaw/skills/notion-sync/creative-review-config.json"

# Load env
if [ -f "$ENV_FILE" ]; then
    NOTION_API_KEY="$(grep '^NOTION_API_KEY=' "$ENV_FILE" | head -1 | cut -d= -f2-)"
fi
if [ -z "${NOTION_API_KEY:-}" ]; then
    echo "ERROR: NOTION_API_KEY not found" >&2
    exit 1
fi

# Load DB ID
DB_ID="$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['database_id'])" 2>/dev/null)"
if [ -z "$DB_ID" ]; then
    echo "ERROR: database_id not found in $CONFIG_FILE" >&2
    exit 1
fi

###############################################################################
# Notion API helper
###############################################################################
notion_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local args=(-s -X "$method"
        -H "Authorization: Bearer $NOTION_API_KEY"
        -H "Notion-Version: $NOTION_API_VERSION"
        -H "Content-Type: application/json"
    )
    if [ -n "$data" ]; then
        args+=(-d "$data")
    fi
    curl "${args[@]}" "https://api.notion.com/v1${endpoint}"
}

###############################################################################
# cmd_poll — Query Notion for character pages needing revision
###############################################################################
cmd_poll() {
    local dry_run="${1:-}"
    echo "=== Character Correction Poller ==="
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"

    # Query Notion for Status="Needs Revision" + tag contains "character"
    local filter='{
      "filter": {
        "and": [
          {"property": "Status", "select": {"equals": "Needs Revision"}},
          {"property": "Tags", "multi_select": {"contains": "character"}}
        ]
      },
      "page_size": 10
    }'

    local result
    result="$(notion_api POST "/databases/$DB_ID/query" "$filter")"

    local count
    count="$(echo "$result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('results',[])))" 2>/dev/null)"

    if [ "$count" = "0" ]; then
        echo "No character pages need revision."
        return 0
    fi

    echo "Found $count page(s) needing revision."

    # Extract each page's info
    echo "$result" | python3 -c "
import json, sys

data = json.load(sys.stdin)
for page in data.get('results', []):
    props = page.get('properties', {})

    # Name
    name_parts = props.get('Name', {}).get('title', [])
    name = name_parts[0]['plain_text'] if name_parts else 'Unknown'

    # Feedback
    fb_parts = props.get('Feedback', {}).get('rich_text', [])
    feedback = fb_parts[0]['plain_text'] if fb_parts else ''

    # Agent
    agent_sel = props.get('Agent', {}).get('select', {})
    agent = agent_sel.get('name', '') if agent_sel else ''

    # Tags
    tags_ms = props.get('Tags', {}).get('multi_select', [])
    tags = ','.join(t['name'] for t in tags_ms)

    # Prompt
    prompt_parts = props.get('Prompt', {}).get('rich_text', [])
    prompt = prompt_parts[0]['plain_text'] if prompt_parts else ''

    # Page URL
    url = page.get('url', '')
    page_id = page.get('id', '')

    print(f'PAGE_ID:{page_id}')
    print(f'NAME:{name}')
    print(f'AGENT:{agent}')
    print(f'FEEDBACK:{feedback}')
    print(f'TAGS:{tags}')
    print(f'PROMPT:{prompt[:500]}')
    print(f'URL:{url}')
    print('---')
"
    if [ "$dry_run" = "--dry-run" ]; then
        echo "(Dry run — not triggering regeneration)"
        return 0
    fi

    # Process each page
    echo "$result" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for page in data.get('results', []):
    props = page.get('properties', {})
    name_parts = props.get('Name', {}).get('title', [])
    name = name_parts[0]['plain_text'] if name_parts else ''
    agent_sel = props.get('Agent', {}).get('select', {})
    agent = agent_sel.get('name', '') if agent_sel else ''
    fb_parts = props.get('Feedback', {}).get('rich_text', [])
    feedback = fb_parts[0]['plain_text'] if fb_parts else ''
    prompt_parts = props.get('Prompt', {}).get('rich_text', [])
    prompt = prompt_parts[0]['plain_text'] if prompt_parts else ''
    page_id = page.get('id', '')
    print(f'{page_id}|{agent}|{name}|{feedback}|{prompt}')
" | while IFS='|' read -r page_id agent name feedback prompt; do
        [ -z "$page_id" ] && continue
        echo ""
        echo "Processing: $name (agent=$agent)"
        cmd_process_revision "$page_id" "$agent" "$name" "$feedback" "$prompt"
    done
}

###############################################################################
# cmd_process_revision — Handle a single revision request
###############################################################################
cmd_process_revision() {
    local page_id="$1"
    local agent="$2"
    local name="$3"
    local feedback="$4"
    local original_prompt="$5"

    agent="$(echo "$agent" | tr '[:upper:]' '[:lower:]')"
    [ -z "$agent" ] && agent="unknown"

    local char_dir="$CHARACTERS_DIR/$agent"
    local spec_file="$char_dir/${agent}-v3-spec.md"

    echo "  Feedback: $feedback"

    # Parse correction type from feedback
    local corrections
    corrections="$(cmd_parse_feedback "$feedback")"
    echo "  Parsed corrections: $corrections"

    # Determine current version from spec file
    local current_version="v3d"
    if [ -f "$spec_file" ]; then
        current_version="$(grep -o 'V3[a-z]*' "$spec_file" | sort | tail -1 | tr '[:upper:]' '[:lower:]')" || true
        [ -z "$current_version" ] && current_version="v3d"
    fi

    # Increment version letter
    local next_version
    next_version="$(cmd_next_version "$current_version")"
    echo "  Version: $current_version -> $next_version"

    # Build updated prompt from corrections
    local updated_prompt
    updated_prompt="$(cmd_apply_corrections "$original_prompt" "$corrections" "$feedback")"

    # Find latest refs for this agent
    local latest_refs_dir=""
    for d in "$char_dir/refs-"*; do
        [ -d "$d" ] && latest_refs_dir="$d"
    done
    if [ -z "$latest_refs_dir" ]; then
        echo "  ERROR: No refs directory found for $agent" >&2
        cmd_log_learning "$agent" "$current_version" "no_refs_found" "FAILED" ""
        return 1
    fi
    echo "  Using refs from: $latest_refs_dir"

    # Collect ref images
    local face_ref="" body_ref="" costume_ref=""
    for f in "$latest_refs_dir"/*face*; do [ -f "$f" ] && face_ref="$f" && break; done
    for f in "$latest_refs_dir"/*body*; do [ -f "$f" ] && body_ref="$f" && break; done
    for f in "$latest_refs_dir"/*costume*; do [ -f "$f" ] && costume_ref="$f" && break; done

    # Also check for chrome/visor/headgear refs
    for f in "$latest_refs_dir"/*chrome* "$latest_refs_dir"/*visor* "$latest_refs_dir"/*helmet*; do
        [ -f "$f" ] && costume_ref="$f" && break
    done

    local ref_list=""
    [ -n "$face_ref" ] && ref_list="$face_ref"
    [ -n "$body_ref" ] && ref_list="${ref_list:+$ref_list,}$body_ref"
    [ -n "$costume_ref" ] && ref_list="${ref_list:+$ref_list,}$costume_ref"

    if [ -z "$ref_list" ]; then
        echo "  ERROR: No ref images found in $latest_refs_dir" >&2
        return 1
    fi

    echo "  Refs: $ref_list"
    echo "  Updated prompt: ${updated_prompt:0:200}..."

    # Generate via NanoBanana
    echo "  Generating..."
    local gen_output
    gen_output="$(bash "$NANOBANANA" generate \
        --brand gaia-os \
        --use-case character \
        --size 2K \
        --ratio 1:1 \
        --ref-image "$ref_list" \
        --prompt "$updated_prompt" 2>&1)" || true

    # Extract generated image path
    local gen_image=""
    gen_image="$(echo "$gen_output" | grep -o '/Users/[^ ]*\.png' | head -1)" || true

    if [ -z "$gen_image" ] || [ ! -f "$gen_image" ]; then
        echo "  ERROR: Generation failed or no image produced" >&2
        echo "  Output: $gen_output"
        cmd_log_learning "$agent" "$next_version" "generation_failed" "FAILED" "$feedback"
        # Mark in Notion as failed
        cmd_update_notion_status "$page_id" "Pending Review" "Auto-regen failed: $gen_output"
        return 1
    fi

    echo "  Generated: $gen_image"

    # Upload to Drive
    local drive_url=""
    if [ -x "$GDRIVE_UPLOAD" ]; then
        local upload_result
        upload_result="$(bash "$GDRIVE_UPLOAD" upload --file "$gen_image" --subfolder gaia-os-characters 2>/dev/null)" || true
        if echo "$upload_result" | grep -q "^DRIVE_OK"; then
            drive_url="$(echo "$upload_result" | grep "^VIEW_LINK:" | sed 's/^VIEW_LINK://')"
            echo "  Drive: $drive_url"
        fi
    fi

    # Register in Notion
    local notion_url=""
    local add_result
    add_result="$(bash "$NOTION_REVIEW" add \
        --name "$agent ${next_version^^} — Correction from feedback" \
        --use-case persona \
        --brand gaia-os \
        --agent "$agent" \
        --ad-type persona \
        --funnel TOFU \
        --pipeline "notion-feedback -> character-correction.sh -> nanobanana-flash" \
        --prompt "$updated_prompt" \
        --result-url "${drive_url:-}" \
        --date "$(date +%Y-%m-%d)" \
        --tags "character,$agent,${next_version},auto-correction" \
        --status "Pending Review" \
        --feedback "Auto-corrected from: $feedback" 2>&1)" || true

    notion_url="$(echo "$add_result" | grep "^URL:" | sed 's/^URL: //')" || true
    echo "  Notion: $notion_url"

    # Update original page status to "Pending Review" with note
    cmd_update_notion_status "$page_id" "Pending Review" "Auto-corrected -> ${next_version^^}. New page: $notion_url"

    # Log learning
    cmd_log_learning "$agent" "$next_version" "$corrections" "SUCCESS" "$feedback"

    echo "  Done: $agent ${next_version^^}"
}

###############################################################################
# cmd_parse_feedback — Extract correction instructions from feedback text
###############################################################################
cmd_parse_feedback() {
    local feedback="$1"
    local fb_lower
    fb_lower="$(echo "$feedback" | tr '[:upper:]' '[:lower:]')"

    local corrections=""

    # Face changes
    if echo "$fb_lower" | grep -qE "face|skin|eyes|hair|freckle"; then
        corrections="${corrections:+$corrections,}face_change"
    fi

    # Body changes
    if echo "$fb_lower" | grep -qE "body|proportion|ratio|slim|curv|thick|tall|short"; then
        corrections="${corrections:+$corrections,}body_change"
    fi

    # Headgear/helmet
    if echo "$fb_lower" | grep -qE "helmet|headgear|visor|crown|halo|sphere|crystal"; then
        corrections="${corrections:+$corrections,}headgear_change"
    fi

    # Costume
    if echo "$fb_lower" | grep -qE "costume|suit|outfit|bodysuit|boots|cloth"; then
        corrections="${corrections:+$corrections,}costume_change"
    fi

    # Realism
    if echo "$fb_lower" | grep -qE "cartoon|cg|3d|render|fake|plastic|unrealistic|not real"; then
        corrections="${corrections:+$corrections,}realism_fix"
    fi

    # Color/material
    if echo "$fb_lower" | grep -qE "chrome|gold|silver|color|colour|matte|metallic|shiny"; then
        corrections="${corrections:+$corrections,}material_fix"
    fi

    # Pose/angle
    if echo "$fb_lower" | grep -qE "pose|angle|position|stance|sitting|standing"; then
        corrections="${corrections:+$corrections,}pose_change"
    fi

    [ -z "$corrections" ] && corrections="general_revision"
    echo "$corrections"
}

###############################################################################
# cmd_apply_corrections — Modify prompt based on parsed corrections
###############################################################################
cmd_apply_corrections() {
    local prompt="$1"
    local corrections="$2"
    local raw_feedback="$3"

    # Start with original prompt
    local updated="$prompt"

    # Apply realism anchors
    if echo "$corrections" | grep -q "realism_fix"; then
        # Remove any CG/cartoon language
        updated="$(echo "$updated" | sed 's/CG render/photorealistic photograph/g')"
        updated="$(echo "$updated" | sed 's/8K detail/Shot on Canon R5 85mm f\/1.4, real human skin texture with pores/g')"
        # Add realism anchors if not present
        if ! echo "$updated" | grep -q "NOT CG"; then
            updated="$updated NOT CG, NOT cartoon, NOT 3D render, NOT illustration."
        fi
        if ! echo "$updated" | grep -q "real human skin"; then
            updated="$updated Real human skin with visible pores, micro-imperfections, natural subsurface scattering."
        fi
    fi

    # Fix crystal sphere persistence
    if echo "$corrections" | grep -q "headgear_change"; then
        if echo "$raw_feedback" | grep -iq "sphere\|crystal.*head\|no.*sphere"; then
            updated="$updated NO crystal sphere, NO glass orb, NO transparent dome."
        fi
    fi

    # Material correction
    if echo "$corrections" | grep -q "material_fix"; then
        if echo "$raw_feedback" | grep -iq "chrome"; then
            updated="$(echo "$updated" | sed 's/crystal diamond/dark polished chrome/g')"
            updated="$updated Dark polished chrome finish, NOT matte, NOT plastic."
        fi
    fi

    # Append raw feedback as additional guidance
    if [ -n "$raw_feedback" ]; then
        updated="$updated [CORRECTION: $raw_feedback]"
    fi

    echo "$updated"
}

###############################################################################
# cmd_next_version — Increment version letter (v3d -> v3e)
###############################################################################
cmd_next_version() {
    local current="$1"
    # Extract the letter suffix
    local base letter
    base="$(echo "$current" | sed 's/[a-z]$//')"
    letter="$(echo "$current" | grep -o '[a-z]$')" || true

    if [ -z "$letter" ]; then
        echo "${base}b"
    else
        # Increment letter
        local next_letter
        next_letter="$(echo "$letter" | tr 'a-y' 'b-z')"
        echo "${base}${next_letter}"
    fi
}

###############################################################################
# cmd_update_notion_status — Update a page's Status + add feedback note
###############################################################################
cmd_update_notion_status() {
    local page_id="$1"
    local new_status="$2"
    local note="${3:-}"

    local payload
    payload="{\"properties\":{\"Status\":{\"select\":{\"name\":\"$new_status\"}}"
    if [ -n "$note" ]; then
        # Escape quotes in note
        local escaped_note
        escaped_note="$(echo "$note" | sed 's/"/\\"/g' | head -c 500)"
        payload="$payload,\"Learnings\":{\"rich_text\":[{\"text\":{\"content\":\"$escaped_note\"}}]}"
    fi
    payload="$payload}}"

    notion_api PATCH "/pages/$page_id" "$payload" > /dev/null 2>&1 || true
}

###############################################################################
# cmd_log_learning — Append to learnings.jsonl
###############################################################################
cmd_log_learning() {
    local agent="$1"
    local version="$2"
    local corrections="$3"
    local status="$4"
    local feedback="$5"

    local escaped_fb
    escaped_fb="$(echo "$feedback" | sed 's/"/\\"/g' | head -c 500)"

    echo "{\"date\":\"$(date -Iseconds)\",\"character\":\"$agent\",\"version\":\"$version\",\"corrections\":\"$corrections\",\"status\":\"$status\",\"feedback\":\"$escaped_fb\",\"source\":\"character-correction.sh\"}" >> "$LEARNINGS_FILE"
}

###############################################################################
# cmd_status — Show current correction queue
###############################################################################
cmd_status() {
    echo "=== Character Correction Queue ==="

    local filter='{
      "filter": {
        "and": [
          {"property": "Status", "select": {"equals": "Needs Revision"}},
          {"property": "Tags", "multi_select": {"contains": "character"}}
        ]
      },
      "page_size": 20
    }'

    local result
    result="$(notion_api POST "/databases/$DB_ID/query" "$filter")"

    echo "$result" | python3 -c "
import json, sys
data = json.load(sys.stdin)
pages = data.get('results', [])
if not pages:
    print('Queue empty — no characters need revision.')
    sys.exit(0)

print(f'Pending revisions: {len(pages)}')
print()
for page in pages:
    props = page.get('properties', {})
    name_parts = props.get('Name', {}).get('title', [])
    name = name_parts[0]['plain_text'] if name_parts else '?'
    agent_sel = props.get('Agent', {}).get('select', {})
    agent = agent_sel.get('name', '?') if agent_sel else '?'
    fb_parts = props.get('Feedback', {}).get('rich_text', [])
    feedback = fb_parts[0]['plain_text'][:80] if fb_parts else '(no feedback)'
    url = page.get('url', '')
    print(f'  [{agent}] {name}')
    print(f'    Feedback: {feedback}')
    print(f'    {url}')
    print()
"
}

###############################################################################
# cmd_history — Show correction history from learnings
###############################################################################
cmd_history() {
    local agent="${1:-}"

    if [ ! -f "$LEARNINGS_FILE" ]; then
        echo "No learnings recorded yet."
        return 0
    fi

    echo "=== Character Correction History ==="

    if [ -n "$agent" ]; then
        grep "\"character\":\"$agent\"" "$LEARNINGS_FILE" | python3 -c "
import json, sys
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        entry = json.loads(line)
        if entry.get('source') == 'character-correction.sh':
            print(f\"  {entry['date'][:16]} | {entry['character']} {entry['version']} | {entry['corrections']} | {entry['status']}\")
            if entry.get('feedback'):
                print(f\"    Feedback: {entry['feedback'][:80]}\")
    except: pass
"
    else
        grep '"source":"character-correction.sh"' "$LEARNINGS_FILE" | tail -20 | python3 -c "
import json, sys
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        entry = json.loads(line)
        print(f\"  {entry['date'][:16]} | {entry['character']} {entry['version']} | {entry['corrections']} | {entry['status']}\")
    except: pass
"
    fi
}

###############################################################################
# cmd_dispatch — Send correction task to Zenni/Taoz for training
###############################################################################
cmd_dispatch() {
    local target="${1:-zenni}"
    local agent="${2:-iris}"

    echo "=== Dispatching Correction Task to $target ==="

    # Build dispatch message based on current queue
    local status_output
    status_output="$(cmd_status 2>&1)"

    if echo "$status_output" | grep -q "Queue empty"; then
        echo "No corrections pending — nothing to dispatch."
        return 0
    fi

    local message="Character correction needed. $(echo "$status_output" | head -5)"

    case "$target" in
        zenni|main)
            echo "Dispatching to Zenni (router)..."
            openclaw agent --agent main --message "Character correction request: check Notion Creative Review for pages marked 'Needs Revision' with tag 'character'. Parse feedback and coordinate with Iris for regeneration. Run: bash ~/.openclaw/skills/character-design/scripts/character-correction.sh poll" 2>&1 || true
            ;;
        taoz)
            echo "Dispatching to Taoz (builder)..."
            openclaw agent --agent taoz --message "Character correction pipeline check: verify character-correction.sh is working correctly, test with a dry run. Run: bash ~/.openclaw/skills/character-design/scripts/character-correction.sh poll --dry-run" 2>&1 || true
            ;;
        iris)
            echo "Dispatching to Iris (visual QA)..."
            openclaw agent --agent iris --message "Visual QA needed: check Notion Creative Review for character pages marked 'Needs Revision'. Analyze the feedback and suggest ref/prompt corrections. Pages: $(echo "$status_output" | grep 'notion.so')" 2>&1 || true
            ;;
        *)
            echo "Unknown target: $target. Use: zenni, taoz, or iris" >&2
            return 1
            ;;
    esac

    echo "Dispatched."
}

###############################################################################
# Main
###############################################################################
case "${1:-help}" in
    poll)       cmd_poll "${2:-}" ;;
    status)     cmd_status ;;
    history)    cmd_history "${2:-}" ;;
    dispatch)   cmd_dispatch "${2:-zenni}" "${3:-iris}" ;;
    parse)      cmd_parse_feedback "${2:-}" ;;
    help|*)
        echo "character-correction.sh — Notion-driven character correction loop"
        echo ""
        echo "Commands:"
        echo "  poll [--dry-run]       Poll Notion for 'Needs Revision' characters, auto-correct"
        echo "  status                 Show current correction queue"
        echo "  history [agent]        Show correction history from learnings"
        echo "  dispatch <target>      Send correction task to zenni|taoz|iris"
        echo "  parse \"<feedback>\"     Test feedback parsing on a string"
        echo ""
        echo "Flow: Jenn marks Notion page 'Needs Revision' + writes feedback"
        echo "      -> poll detects it -> parses feedback -> regenerates via NanoBanana"
        echo "      -> uploads to Drive + Notion -> marks original as 'Pending Review'"
        echo ""
        echo "Cron: */20 * * * * bash character-correction.sh poll"
        ;;
esac
