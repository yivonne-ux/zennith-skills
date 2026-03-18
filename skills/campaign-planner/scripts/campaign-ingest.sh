#!/usr/bin/env bash
# campaign-ingest.sh — Ingest campaign data for pattern extraction and performance analysis
# Part of GAIA CORP-OS Meta Ads Performance Loop
#
# Usage:
#   campaign-ingest.sh extract-patterns \
#     --campaign-set "MIR W10 EN1 M2" \
#     --from-date "2026-03-01" \
#     --to-date "2026-03-10" \
#     --lookback-weeks 2
#
#   campaign-ingest.sh analyze-funnels \
#     --brand mirra \
#     --funnels "mofu,bofu" \
#     --output analytics-funnels.json
#
#   campaign-ingest.sh performance-summary \
#     --brand mirra \
#     --week 10 \
#     --output performance-summary.md
#
# Requirements:
#   - campaign-tracker.jsonl (briefs)
#   - campaign-uploads logs (performance data)
#   - Optional: Meta Ads Manager API or CSV export

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRANDS_DIR="$HOME/.openclaw/brands"
TRACKER_FILE="$HOME/.openclaw/workspace/data/campaign-tracker.jsonl"
UPLOADS_DIR="$HOME/.openclaw/workspace/data/campaign-uploads"
LOGS_DIR="$UPLOADS_DIR/logs"
VERSIONS_DIR="$UPLOADS_DIR/versions"

# --- Logging ---
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2; }
err() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }
info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }

# --- Post to room ---
post_to_room() {
    local room_file="$1" agent="$2" msg="$3"
    local ts
    ts="$(date +%s)000"
    printf '{"ts":%s,"agent":"%s","msg":"%s"}\n' "$ts" "$agent" "$msg" >> "$room_file"
}

# --- Command: extract-patterns ---
cmd_extract_patterns() {
    local campaign_set="" from_date="" to_date="" lookback_weeks="" brand="" output_dir=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --campaign-set)   campaign_set="$2"; shift 2 ;;
            --from-date)      from_date="$2"; shift 2 ;;
            --to-date)        to_date="$2"; shift 2 ;;
            --lookback-weeks) lookback_weeks="$2"; shift 2 ;;
            --brand)          brand="$2"; shift 2 ;;
            --output-dir)     output_dir="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [ -z "$campaign_set" ]; then
        err "Required: --campaign-set"
        exit 1
    fi

    # Set defaults
    output_dir="${output_dir:-$HOME/.openclaw/workspace/data/campaign-uploads/extracted-patterns}"
    lookback_weeks="${lookback_weeks:-2}"
    to_date="${to_date:-$(date +%Y-%m-%d)}"
    from_date="${from_date:-$(date -v-${lookback_weeks}w +%Y-%m-%d 2>/dev/null || date -d "${lookback_weeks} weeks ago" +%Y-%m-%d)}"

    log "Extracting patterns for: $campaign_set"
    info "Date range: $from_date to $to_date"
    info "Lookback: $lookback_weeks weeks"

    mkdir -p "$output_dir"

    # Load campaigns for this set
    local campaigns=()
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        local cam_json
        cam_json=$(echo "$line" | jq -c .)
        if echo "$cam_json" | jq -e '.campaign_set == "'"$campaign_set"'"' >/dev/null 2>&1; then
            campaigns+=("$line")
        fi
    done < "$TRACKER_FILE"

    if [ ${#campaigns[@]} -eq 0 ]; then
        err "No campaigns found for: $campaign_set"
        exit 1
    fi

    info "Found ${#campaigns[@]} campaigns"

    # Extract patterns from briefs
    local patterns_file="$output_dir/${campaign_set}-patterns.jsonl"

    for camp in "${campaigns[@]}"; do
        local campaign_id=$(echo "$camp" | jq -r '.campaign_id')
        local brand=$(echo "$camp" | jq -r '.brand')
        local funnel=$(echo "$camp" | jq -r '.funnel')
        local template_type=$(echo "$camp" | jq -r '.template_type')
        local variant=$(echo "$camp" | jq -r '.variant')
        local headline=$(echo "$camp" | jq -r '.headline')
        subcopy=$(echo "$camp" | jq -r '.subcopy_brief')
        visual_style=$(echo "$camp" | jq -r '.visual_description')
        dish=$(echo "$camp" | jq -r '.dish_assignment')
        persona=$(echo "$camp" | jq -r '.persona_reference')

        # Extract patterns from subcopy
        local pain=$(echo "$subcopy" | sed -n 's/.*Pain: \([^.]*\).*/\1/p')
        local desire=$(echo "$subcopy" | sed -n 's/.*Desire: \([^.]*\).*/\1/p')
        local usps=$(echo "$camp" | jq -r '.usp_points[]')

        # Analyze headline patterns
        local headline_length=${#headline}
        local has_number=$(echo "$headline" | grep -o '[0-9]\+' || echo "0")
        local has_keyword=$(echo "$headline" | grep -ioE '\b(mirra|health|food|bento|meal|nutrition|plant|vegan|ketogenic|low-carb|gluten-free|dairy-free|high-protein|high-fiber)\b' || echo "")

        # Determine template type archetype
        local archetype=""
        case "$template_type" in
            M1) archetype="KOL Faces" ;;
            M2) archetype="Product Benefit" ;;
            M3) archetype="Group Album" ;;
            M4) archetype="VS Before/After" ;;
            M5) archetype="Testimonial" ;;
            B1) archetype="Sales Boom" ;;
            B2) archetype="Last Call" ;;
            B3) archetype="Raw Truth" ;;
            B4) archetype="Prices/COD" ;;
            *) archetype="Other" ;;
        esac

        local pattern_entry
        pattern_entry=$(python3 -c "
import json, time
entry = {
    'type': 'pattern_extract',
    'campaign_id': '$campaign_id',
    'campaign_set': '$campaign_set',
    'brand': '$brand',
    'funnel': '$funnel',
    'template_type': '$template_type',
    'archetype': '$archetype',
    'variant': '$variant',
    'date_available': '$from_date',
    'headline': '$headline',
    'headline_length': $headline_length,
    'has_number': $has_number,
    'has_keyword': '$has_keyword',
    'pain_point': '$pain',
    'desire': '$desire',
    'visual_style': '$visual_style',
    'dish': '$dish',
    'persona': '$persona',
    'usp_count': $(echo "$usps" | wc -l),
    'usp_first': '$(echo "$usps" | head -n 1)',
    'usp_second': '$(echo "$usps" | head -n 2 | tail -n 1)',
    'created_at': time.strftime('%Y-%m-%dT%H:%M:%S+08:00')
}
print(json.dumps(entry))
" 2>/dev/null || echo "")

        echo "$pattern_entry" >> "$patterns_file"
    done

    log "Patterns extracted: $patterns_file (${#campaigns[@]} entries)"

    # Generate summary report
    local summary_file="$output_dir/${campaign_set}-summary.md"

    python3 - "$campaigns" "$patterns_file" "$summary_file" << 'PYEOF'
import json, sys
import collections

campaigns = json.load(sys.stdin)
patterns_file = sys.argv[2]
summary_file = sys.argv[3]

# Load patterns
patterns = []
with open(patterns_file) as f:
    for line in f:
        line = line.strip()
        if line:
            try:
                patterns.append(json.loads(line))
            except json.JSONDecodeError:
                continue

# Group by funnel
funnels = collections.defaultdict(list)
for p in patterns:
    funnel = p.get('funnel', 'unknown')
    funnels[funnel].append(p)

# Group by template type
archetypes = collections.defaultdict(list)
for p in patterns:
    arch = p.get('archetype', 'unknown')
    archetypes[arch].append(p)

# Headline analysis
headline_lengths = [p.get('headline_length', 0) for p in patterns]
avg_length = sum(headline_lengths) / len(headline_lengths) if headline_lengths else 0

# Funnel templates breakdown
funnel_templates = {}
for funnel, items in funnels.items():
    template_count = collections.defaultdict(int)
    for item in items:
        tmpl = item.get('template_type', 'unknown')
        template_count[tmpl] += 1
    funnel_templates[funnel] = dict(template_count)

# Write summary
with open(summary_file, 'w') as f:
    f.write("# Campaign Pattern Extraction Summary\n\n")
    f.write(f"**Campaign Set**: {patterns[0].get('campaign_set', 'N/A')}\n")
    f.write(f"**Date Available**: {patterns[0].get('date_available', 'N/A')}\n")
    f.write(f"**Total Variants**: {len(patterns)}\n\n")
    f.write("---\n\n")
    f.write("## Funnel Templates\n\n")
    for funnel, templates in sorted(funnels.items()):
        f.write(f"### {funnel.upper()}\n\n")
        f.write("| Template Type | Count |\n")
        f.write("|--------------|-------|\n")
        for tmpl, count in sorted(funnel_templates.get(funnel, {}).items()):
            f.write(f"| {tmpl} | {count} |\n")
        f.write("\n")

    f.write("---\n\n")
    f.write("## Archetypes Breakdown\n\n")
    f.write("| Archetype | Count |\n")
    f.write("|-----------|-------|\n")
    for arch, items in sorted(archetypes.items(), key=lambda x: -len(x[1])):
        f.write(f"| {arch} | {len(items)} |\n")
    f.write("\n")

    f.write("---\n\n")
    f.write("## Headline Analysis\n\n")
    f.write(f"- **Average length**: {avg_length:.1f} characters\n")
    f.write(f"- **Total variants analyzed**: {len(patterns)}\n")
    f.write("\n")

    f.write("---\n\n")
    f.write("## Variants List\n\n")
    f.write("| Campaign ID | Variant | Funnel | Template | Headline |\n")
    f.write("|-------------|---------|--------|----------|----------|\n")
    for p in sorted(patterns, key=lambda x: x.get('campaign_id', '')):
        f.write(f"| {p.get('campaign_id', 'N/A')} | {p.get('variant', 'N/A')} | {p.get('funnel', 'N/A')} | {p.get('template_type', 'N/A')} | {p.get('headline', 'N/A')} |\n")
    f.write("\n")

print(f"Summary saved to: {summary_file}")
PYEOF

    log "Summary report generated: $summary_file"

    # Also create a JSONL of patterns for machine processing
    local patterns_jsonl="$output_dir/${campaign_set}-patterns.jsonl"
    cp "$patterns_file" "$patterns_jsonl"

    info "Output directory: $output_dir"
    info "Files:"
    info "  - $summary_file (human-readable summary)"
    info "  - $patterns_jsonl (machine-processed patterns)"

    post_to_room "$HOME/.openclaw/workspace/rooms/exec.jsonl" "campaign-ingest" "Patterns extracted for $campaign_set — ${#campaigns[@]} variants analyzed"

    echo "$output_dir"
}

# --- Command: analyze-funnels ---
cmd_analyze_funnels() {
    local brand="" funnels="" output=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand)      brand="$2"; shift 2 ;;
            --funnels)    funnels="$2"; shift 2 ;;
            --output)     output="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    brand="${brand:-mirra}"
    funnels="${funnels:-mofu,bofu}"
    output="${output:-$HOME/.openclaw/workspace/data/campaign-uploads/analytics-funnels.json}"

    log "Analyzing funnels: $funnels"

    mkdir -p "$(dirname "$output")"

    # Load all campaigns for this brand
    local campaigns=()
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        camp=$(echo "$line" | jq -c .)
        camp_brand=$(echo "$camp" | jq -r '.brand')
        if [ "$camp_brand" = "$brand" ]; then
            campaigns+=("$line")
        fi
    done < "$TRACKER_FILE"

    if [ ${#campaigns[@]} -eq 0 ]; then
        err "No campaigns found for brand: $brand"
        exit 1
    fi

    info "Found ${#campaigns[@]} campaigns for brand: $brand"

    # Analyze by funnel
    python3 - "$campaigns" "$output" << 'PYEOF'
import json, sys
from collections import defaultdict

campaigns = json.load(sys.stdin)
output_file = sys.argv[2]

# Group by funnel
funnel_data = defaultdict(lambda: {
    'campaigns': [],
    'total_variants': 0,
    'template_types': defaultdict(int),
    'personas': set(),
    'headlines_length_avg': 0,
    'usp_counts': []
})

for camp in campaigns:
    funnel = camp.get('funnel', 'unknown')
    variant = camp.get('variant', 'N/A')

    data = funnel_data[funnel]
    data['campaigns'].append(camp)
    data['total_variants'] += 1

    tmpl = camp.get('template_type', 'unknown')
    data['template_types'][tmpl] += 1

    persona = camp.get('persona_reference', 'unknown')
    if persona:
        data['personas'].add(persona)

    headline_length = len(camp.get('headline', ''))
    data['headlines_length_avg'] += headline_length

    usp_count = len(camp.get('usp_points', []))
    data['usp_counts'].append(usp_count)

# Calculate averages
for funnel, data in funnel_data.items():
    if data['total_variants'] > 0:
        data['headlines_length_avg'] = data['headlines_length_avg'] / data['total_variants']
        data['usp_count_avg'] = sum(data['usp_counts']) / len(data['usp_counts'])

# Build output
analysis = {
    'brand': 'mirra',
    'date_generated': json.loads(sys.argv[1])[0].get('created_at', '') if json.loads(sys.argv[1]) else 'unknown',
    'total_variants': sum(d['total_variants'] for d in funnel_data.values()),
    'funnels': {}
}

for funnel, data in funnel_data.items():
    analysis['funnels'][funnel] = {
        'total_variants': data['total_variants'],
        'template_types': dict(data['template_types']),
        'personas': list(data['personas']),
        'headline_length_avg': round(data['headlines_length_avg'], 1),
        'usp_count_avg': round(data.get('usp_count_avg', 0), 1)
    }

with open(output_file, 'w') as f:
    json.dump(analysis, f, indent=2, ensure_ascii=False)

print(json.dumps(analysis, indent=2))
print(f"\nSaved to: {output_file}")
PYEOF

    log "Funnel analysis complete: $output"
    post_to_room "$HOME/.openclaw/workspace/rooms/exec.jsonl" "campaign-ingest" "Funnel analysis complete: $brand — ${funnels}"
}

# --- Command: performance-summary ---
cmd_performance_summary() {
    local brand="" week="" output="" use_mock_data=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --brand)        brand="$2"; shift 2 ;;
            --week)         week="$2"; shift 2 ;;
            --output)       output="$2"; shift 2 ;;
            --use-mock-data) use_mock_data="true"; shift ;;
            *) shift ;;
        esac
    done

    brand="${brand:-mirra}"
    week="${week:-$(date '+%V' | sed 's/^0//')}"
    output="${output:-$HOME/.openclaw/workspace/data/campaign-uploads/performance-summary.md}"

    log "Generating performance summary: $brand Week $week"

    # Load campaigns for this week
    local campaigns=()
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        camp=$(echo "$line" | jq -c .)
        camp_brand=$(echo "$camp" | jq -r '.brand')
        camp_week=$(echo "$camp" | jq -r '.week // "0"')
        if [ "$camp_brand" = "$brand" ] && [ "$camp_week" = "$week" ]; then
            campaigns+=("$line")
        fi
    done < "$TRACKER_FILE"

    if [ ${#campaigns[@]} -eq 0 ]; then
        err "No campaigns found for $brand Week $week"
        exit 1
    fi

    info "Found ${#campaigns[@]} campaigns for Week $week"

    # For now, use mock performance data (will be enhanced when we integrate with actual Meta Ads data)
    local mock_performance_file="$UPLOADS_DIR/logs/performance-week-$week-mock.jsonl"
    mkdir -p "$(dirname "$mock_performance_file")"

    # Generate mock performance data based on brief structure
    for camp in "${campaigns[@]}"; do
        local campaign_id=$(echo "$camp" | jq -r '.campaign_id')
        local funnel=$(echo "$camp" | jq -r '.funnel')
        local template_type=$(echo "$camp" | jq -r '.template_type')
        local variant=$(echo "$camp" | jq -r '.variant')
        local brand=$(echo "$camp" | jq -r '.brand')

        # Generate random performance metrics (in production, these come from Meta Ads API)
        local roas_mock=$(python3 -c "import random; print(round(random.uniform(0.5, 3.0), 2))")
        local ctr_mock=$(python3 -c "import random; print(round(random.uniform(0.1, 2.5), 3))")
        local cpm_mock=$(python3 -c "import random; print(round(random.uniform(15, 45), 2))")
        local spend_mock=$(python3 -c "import random; print(int(random.uniform(50, 500)))")

        local perf_entry
        perf_entry=$(python3 -c "
import json, time, random
entry = {
    'type': 'performance_data',
    'campaign_id': '$campaign_id',
    'campaign_set': '$brand W$week',
    'brand': '$brand',
    'funnel': '$funnel',
    'template_type': '$template_type',
    'variant': '$variant',
    'roas': $roas_mock,
    'ctr': $ctr_mock,
    'cpm': $cpm_mock,
    'spend_rm': $spend_mock,
    'impressions': $((spend_mock * 1000 / cpm_mock * 1000)),
    'clicks': $((int(spend_mock / cpm_mock * 1000))),
    'date_available': '$(date +%Y-%m-%d)'
}
print(json.dumps(entry))
" 2>/dev/null || echo "")

        echo "$perf_entry" >> "$mock_performance_file"
    done

    # Generate summary
    python3 - "$mock_performance_file" "$output" << 'PYEOF'
import json, sys
from collections import defaultdict

perf_file = sys.argv[1]
output_file = sys.argv[2]

# Load performance data
perfs = []
with open(perf_file) as f:
    for line in f:
        line = line.strip()
        if line:
            try:
                perfs.append(json.loads(line))
            except json.JSONDecodeError:
                continue

if not perfs:
    print("No performance data found.", file=sys.stderr)
    sys.exit(1)

# Group by funnel
funnel_groups = defaultdict(list)
for p in perfs:
    funnel_groups[p.get('funnel', 'unknown')].append(p)

# Calculate averages
summary = {
    'brand': perfs[0].get('brand'),
    'week': perfs[0].get('campaign_set', '').split('W')[1] if 'W' in perfs[0].get('campaign_set', '') else 'unknown',
    'total_variants': len(perfs),
    'total_spend_rm': sum(p.get('spend_rm', 0) for p in perfs),
    'funnels': {}
}

for funnel, items in funnel_groups.items():
    funnel_summary = {
        'variants': len(items),
        'total_spend_rm': sum(p.get('spend_rm', 0) for p in items),
        'avg_roas': sum(p.get('roas', 0) for p in items) / len(items),
        'avg_ctr': sum(p.get('ctr', 0) for p in items) / len(items),
        'avg_cpm': sum(p.get('cpm', 0) for p in items) / len(items),
        'top_performers': []
    }

    # Find top performers
    for p in items:
        if p.get('roas', 0) > 1.0:
            funnel_summary['top_performers'].append({
                'campaign_id': p.get('campaign_id'),
                'template_type': p.get('template_type'),
                'variant': p.get('variant'),
                'roas': p.get('roas'),
                'ctr': p.get('ctr')
            })

    funnel_summary['top_performers'] = sorted(
        funnel_summary['top_performers'],
        key=lambda x: x['roas'],
        reverse=True
    )[:3]

    summary['funnels'][funnel] = funnel_summary

# Write markdown
with open(output_file, 'w') as f:
    f.write("# Performance Summary\n\n")
    f.write(f"**Brand**: {summary['brand']}\n")
    f.write(f"**Week**: {summary['week']}\n")
    f.write(f"**Total Variants**: {summary['total_variants']}\n")
    f.write(f"**Total Spend**: RM {summary['total_spend_rm']:.0f}\n")
    f.write("---\n\n")

    for funnel, data in summary['funnels'].items():
        f.write(f"## {funnel.upper()}\n\n")
        f.write(f"- **Variants**: {data['variants']}\n")
        f.write(f"- **Total Spend**: RM {data['total_spend_rm']:.0f}\n")
        f.write(f"- **Avg ROAS**: {data['avg_roas']:.2f}\n")
        f.write(f"- **Avg CTR**: {data['avg_ctr']:.3f}\n")
        f.write(f"- **Avg CPM**: RM {data['avg_cpm']:.2f}\n\n")

        if data['top_performers']:
            f.write(f"### Top Performers (ROAS)\n\n")
            f.write("| Campaign ID | Template | Variant | ROAS | CTR |\n")
            f.write("|-------------|----------|---------|------|-----|\n")
            for tp in data['top_performers']:
                f.write(f"| {tp['campaign_id']} | {tp['template_type']} | {tp['variant']} | {tp['roas']:.2f} | {tp['ctr']:.3f} |\n")
            f.write("\n")

print(f"Summary saved to: {output_file}")
PYEOF

    log "Performance summary complete: $output"
    post_to_room "$HOME/.openclaw/workspace/rooms/exec.jsonl" "campaign-ingest" "Performance summary complete: $brand W$week"

    echo "$output"
}

# --- Main ---
main() {
    if [ $# -eq 0 ]; then
        echo "campaign-ingest.sh — Ingest campaign data for pattern extraction and performance analysis"
        echo ""
        echo "Commands:"
        echo "  extract-patterns    Extract patterns from campaign briefs"
        echo "  analyze-funnels     Analyze campaign performance by funnel"
        echo "  performance-summary Generate performance summary by week"
        echo ""
        echo "Options for extract-patterns:"
        echo "  --campaign-set       Campaign set name (e.g., 'MIR W10 EN1 M2')"
        echo "  --from-date          Start date (YYYY-MM-DD)"
        echo "  --to-date            End date (YYYY-MM-DD)"
        echo "  --lookback-weeks     Number of weeks to look back (default: 2)"
        echo "  --brand              Brand name (default: mirra)"
        echo "  --output-dir         Output directory (default: campaign-uploads/extracted-patterns)"
        echo ""
        echo "Examples:"
        echo "  campaign-ingest.sh extract-patterns --campaign-set \"MIR W10 EN1 M2\" --from-date \"2026-03-01\" --to-date \"2026-03-10\""
        echo "  campaign-ingest.sh extract-patterns --campaign-set \"MIR W10 EN1 M2\" --lookback-weeks 3"
        echo "  campaign-ingest.sh analyze-funnels --brand mirra --funnels \"mofu,bofu\""
        echo "  campaign-ingest.sh performance-summary --brand mirra --week 10 --use-mock-data"
        exit 0
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        extract-patterns)      cmd_extract_patterns "$@" ;;
        analyze-funnels)       cmd_analyze_funnels "$@" ;;
        performance-summary)   cmd_performance_summary "$@" ;;
        *)
            err "Unknown command: $cmd"
            exit 1
            ;;
    esac
}

main "$@"