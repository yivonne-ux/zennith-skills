#!/usr/bin/env bash
# list-output-types.sh — List registered output types with optional filters
# Bash 3.2 compatible (macOS). Uses python3 for JSON reading.
#
# Usage:
#   bash list-output-types.sh                          # list all
#   bash list-output-types.sh --funnel TOFU             # filter by funnel stage
#   bash list-output-types.sh --tool kling              # filter by generation tool
#   bash list-output-types.sh --funnel MOFU --tool sora # combine filters
#   bash list-output-types.sh --json                    # output raw JSON
#   bash list-output-types.sh --ids                     # output IDs only, one per line

set -euo pipefail

DATA_DIR="$HOME/.openclaw/workspace/data"
OUTPUT_TYPES_FILE="$DATA_DIR/output-types.json"

# Parse arguments (Bash 3.2 compatible — no associative arrays)
FILTER_FUNNEL=""
FILTER_TOOL=""
OUTPUT_FORMAT="table"

while [ $# -gt 0 ]; do
    case "$1" in
        --funnel)
            shift
            if [ $# -eq 0 ]; then
                echo "ERROR: --funnel requires a value (TOFU, MOFU, BOFU, POST-PURCHASE)" >&2
                exit 1
            fi
            FILTER_FUNNEL="$1"
            ;;
        --tool)
            shift
            if [ $# -eq 0 ]; then
                echo "ERROR: --tool requires a value (kling, sora, zimage, etc.)" >&2
                exit 1
            fi
            FILTER_TOOL="$1"
            ;;
        --json)
            OUTPUT_FORMAT="json"
            ;;
        --ids)
            OUTPUT_FORMAT="ids"
            ;;
        --help|-h)
            echo "Usage: bash list-output-types.sh [--funnel TOFU|MOFU|BOFU] [--tool kling|sora|zimage] [--json] [--ids]"
            echo ""
            echo "Options:"
            echo "  --funnel STAGE   Filter by funnel stage (TOFU, MOFU, BOFU, POST-PURCHASE)"
            echo "  --tool TOOL      Filter by generation tool (kling, sora, zimage, etc.)"
            echo "  --json           Output as raw JSON array"
            echo "  --ids            Output type IDs only, one per line"
            echo "  --help           Show this help"
            exit 0
            ;;
        *)
            echo "ERROR: Unknown option '$1'. Use --help for usage." >&2
            exit 1
            ;;
    esac
    shift
done

# Check file exists
if [ ! -f "$OUTPUT_TYPES_FILE" ]; then
    echo "No output types registered yet. File not found: $OUTPUT_TYPES_FILE" >&2
    exit 0
fi

python3 -c "
import json, sys

filter_funnel = '''$FILTER_FUNNEL'''.strip().upper()
filter_tool = '''$FILTER_TOOL'''.strip().lower()
output_format = '''$OUTPUT_FORMAT'''

try:
    with open('$OUTPUT_TYPES_FILE', 'r') as f:
        types = json.load(f)
except (json.JSONDecodeError, FileNotFoundError) as e:
    print('ERROR: Cannot read output-types.json: ' + str(e), file=sys.stderr)
    sys.exit(1)

if not isinstance(types, list):
    print('ERROR: output-types.json is not an array', file=sys.stderr)
    sys.exit(1)

# Apply filters
filtered = []
for t in types:
    if not isinstance(t, dict):
        continue

    # Funnel filter
    if filter_funnel:
        stage = t.get('funnel_stage', '').upper()
        if stage != filter_funnel:
            continue

    # Tool filter
    if filter_tool:
        tools = t.get('generation_tools', [])
        tool_names = [x.lower() for x in tools if isinstance(x, str)]
        if filter_tool not in tool_names:
            continue

    filtered.append(t)

if len(filtered) == 0:
    filters_desc = []
    if filter_funnel:
        filters_desc.append('funnel=' + filter_funnel)
    if filter_tool:
        filters_desc.append('tool=' + filter_tool)
    if filters_desc:
        print('No output types match filters: ' + ', '.join(filters_desc))
    else:
        print('No output types registered.')
    sys.exit(0)

# Output
if output_format == 'json':
    print(json.dumps(filtered, indent=2, ensure_ascii=False))
elif output_format == 'ids':
    for t in filtered:
        print(t.get('id', ''))
else:
    # Table format
    print('{:<20} {:<25} {:<12} {:<20} {:<30}'.format(
        'ID', 'NAME', 'FUNNEL', 'RATIOS', 'TOOLS'))
    print('-' * 107)
    for t in filtered:
        tid = t.get('id', '?')
        name = t.get('name', '?')
        if len(name) > 23:
            name = name[:20] + '...'
        funnel = t.get('funnel_stage', '?')
        ratios = ', '.join(t.get('aspect_ratios', []))
        if len(ratios) > 18:
            ratios = ratios[:15] + '...'
        tools = ', '.join(t.get('generation_tools', []))
        if len(tools) > 28:
            tools = tools[:25] + '...'
        print('{:<20} {:<25} {:<12} {:<20} {:<30}'.format(
            tid, name, funnel, ratios, tools))

    print('')
    print('Total: {} output type(s)'.format(len(filtered)))
"
