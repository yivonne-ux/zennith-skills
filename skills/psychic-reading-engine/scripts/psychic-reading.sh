#!/usr/bin/env bash
#
# psychic-reading.sh — Master CLI wrapper for the Psychic Reading Engine
# Runs all 3 engines in parallel, feeds results to synthesizer.
# Supports JSON or markdown output, and batch mode.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMPDIR="${TMPDIR:-/tmp}"

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
NAME=""
DATE=""
TIME=""
LAT=""
LON=""
TZ=""
SPREAD="3-card"
QUESTION="general"
OUTPUT="json"
SEED=""
BATCH=""
MODE="destiny"
QUESTION_TEXT=""

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
    cat <<'USAGE'
Usage: psychic-reading.sh [OPTIONS]

Options:
  --name NAME           Name of the person
  --date YYYY-MM-DD     Birth date
  --time HH:MM          Birth time (24h)
  --lat FLOAT           Birth latitude
  --lon FLOAT           Birth longitude
  --tz TIMEZONE         Timezone (e.g. Asia/Kuala_Lumpur)
  --spread TYPE         Tarot spread: 3-card, celtic-cross, relationship, career
  --question CATEGORY   Question: career, love, health, wealth, travel, legal, study, general
  --output FORMAT       Output format: json or markdown
  --seed INT            Random seed for reproducibility
  --mode MODE           QMDJ chart mode: destiny (命盘), realtime (实时盘), reading (热卜盘)
  --question-text TEXT  Free-text question (for reading mode)
  --batch FILE.csv      Batch mode: CSV with columns name,date,time,lat,lon,tz,spread,question

Examples:
  psychic-reading.sh --name "Alice" --date "1990-05-15" --time "14:30" \
    --lat 3.1390 --lon 101.6869 --tz "Asia/Kuala_Lumpur" \
    --spread celtic-cross --question career --output markdown

  psychic-reading.sh --batch readings.csv --output json
USAGE
    exit 1
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)      NAME="$2"; shift 2 ;;
        --date)      DATE="$2"; shift 2 ;;
        --time)      TIME="$2"; shift 2 ;;
        --lat)       LAT="$2"; shift 2 ;;
        --lon)       LON="$2"; shift 2 ;;
        --tz)        TZ="$2"; shift 2 ;;
        --spread)    SPREAD="$2"; shift 2 ;;
        --question)  QUESTION="$2"; shift 2 ;;
        --output)    OUTPUT="$2"; shift 2 ;;
        --seed)      SEED="$2"; shift 2 ;;
        --mode)      MODE="$2"; shift 2 ;;
        --question-text) QUESTION_TEXT="$2"; shift 2 ;;
        --batch)     BATCH="$2"; shift 2 ;;
        --help|-h)   usage ;;
        *)           echo "Unknown option: $1"; usage ;;
    esac
done

# ---------------------------------------------------------------------------
# Single reading function
# ---------------------------------------------------------------------------
run_single_reading() {
    local name="$1" date="$2" time="$3" lat="$4" lon="$5" tz="$6"
    local spread="$7" question="$8" output="$9" seed="${10:-}"
    local mode="${11:-destiny}" question_text="${12:-}"

    local work_dir
    work_dir=$(mktemp -d "${TMPDIR}/psychic-reading-XXXXXX")

    local chart_json="${work_dir}/chart.json"
    local qmdj_json="${work_dir}/qmdj.json"
    local tarot_json="${work_dir}/tarot.json"
    local synthesis_json="${work_dir}/synthesis.json"

    local seed_arg=""
    if [[ -n "$seed" ]]; then
        seed_arg="--seed $seed"
    fi

    # Run all 3 engines in parallel
    python3 "${SCRIPT_DIR}/birth-chart.py" \
        --name "$name" --date "$date" --time "$time" \
        --lat "$lat" --lon "$lon" --tz "$tz" \
        > "$chart_json" 2>/dev/null &
    local pid_chart=$!

    local qmdj_mode_args="--mode $mode"
    if [[ -n "$question_text" ]]; then
        qmdj_mode_args="$qmdj_mode_args --question-text \"$question_text\""
    fi
    if [[ "$mode" == "destiny" ]]; then
        qmdj_mode_args="$qmdj_mode_args --datetime \"${date} ${time}\""
    fi

    eval python3 "${SCRIPT_DIR}/qmdj-calc.py" \
        $qmdj_mode_args --tz "$tz" --question "$question" \
        > "$qmdj_json" 2>/dev/null &
    local pid_qmdj=$!

    python3 "${SCRIPT_DIR}/tarot-engine.py" \
        --spread "$spread" --question "$question" --name "$name" \
        $seed_arg \
        > "$tarot_json" 2>/dev/null &
    local pid_tarot=$!

    # Wait for all engines
    wait $pid_chart $pid_qmdj $pid_tarot 2>/dev/null || true

    # Verify outputs exist and are non-empty
    local synth_args="--name \"$name\""
    if [[ -s "$chart_json" ]]; then
        synth_args="$synth_args --chart \"$chart_json\""
    fi
    if [[ -s "$qmdj_json" ]]; then
        synth_args="$synth_args --qmdj \"$qmdj_json\""
    fi
    if [[ -s "$tarot_json" ]]; then
        synth_args="$synth_args --tarot \"$tarot_json\""
    fi
    if [[ -n "$seed" ]]; then
        synth_args="$synth_args --seed $seed"
    fi

    # Run synthesizer
    eval python3 "${SCRIPT_DIR}/reading-synthesizer.py" $synth_args > "$synthesis_json" 2>/dev/null

    if [[ "$output" == "markdown" ]]; then
        json_to_markdown "$synthesis_json" "$chart_json" "$qmdj_json" "$tarot_json"
    else
        cat "$synthesis_json"
    fi

    # Cleanup
    rm -rf "$work_dir"
}

# ---------------------------------------------------------------------------
# JSON to Markdown converter
# ---------------------------------------------------------------------------
json_to_markdown() {
    local synthesis="$1" chart="$2" qmdj="$3" tarot="$4"

    python3 -c "
import json, sys

with open('$synthesis', 'r') as f:
    data = json.load(f)

name = data.get('reading_for', 'Unknown')
dt = data.get('generated_at', '')
systems = ', '.join(data.get('systems_used', []))
confidence = data.get('overall_confidence', 0)
dominant = data.get('dominant_element', '')

print(f'# Psychic Reading for {name}')
print(f'*Generated: {dt}*')
print(f'*Systems: {systems}*')
print(f'*Dominant Element: {dominant} | Overall Confidence: {confidence}%*')
print()

# Cross-system themes
themes = data.get('cross_system_themes', [])
if themes:
    print('## Cross-System Themes')
    for t in themes:
        match_pct = t.get('confidence', 0)
        print(f'### {t[\"theme_name\"].replace(\"_\", \" \").title()} ({match_pct}% convergence)')
        print(f'{t[\"interpretation\"]}')
        print()
        for e in t.get('evidence', []):
            print(f'- {e}')
        print()

# Sections
for section in data.get('sections', []):
    name_s = section.get('section', '').title()
    print(f'## {name_s}')
    print()

    insight = section.get('core_insight', '')
    if insight:
        print(f'**Core Insight:** {insight}')
        print()

    evidence = section.get('supporting_evidence', [])
    if evidence:
        print('**Evidence:**')
        for ev in evidence:
            print(f'- *{ev[\"system\"]}*: {ev[\"data\"]}')
        print()

    barnum = section.get('barnum_layer', [])
    if barnum:
        print('**Deeper Reflections:**')
        for b in barnum:
            print(f'> {b}')
        print()

    cold = section.get('cold_reading', [])
    if cold:
        for c in cold:
            print(f'*{c}*')
        print()

    conf = section.get('confidence_level', 0)
    timing = section.get('timing_window', '')
    if timing:
        print(f'Timing: {timing} | Confidence: {conf}%')
    print()
    print('---')
    print()

print()
print('*' + data.get('methodology_note', '') + '*')
" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Batch mode
# ---------------------------------------------------------------------------
run_batch() {
    local csv_file="$1"
    local output="$2"

    if [[ ! -f "$csv_file" ]]; then
        echo "Error: Batch file not found: $csv_file" >&2
        exit 1
    fi

    local results=()
    local count=0

    # Skip header line, read CSV
    tail -n +2 "$csv_file" | while IFS=',' read -r name date time lat lon tz spread question; do
        # Trim whitespace
        name=$(echo "$name" | xargs)
        date=$(echo "$date" | xargs)
        time=$(echo "$time" | xargs)
        lat=$(echo "$lat" | xargs)
        lon=$(echo "$lon" | xargs)
        tz=$(echo "$tz" | xargs)
        spread=$(echo "${spread:-3-card}" | xargs)
        question=$(echo "${question:-general}" | xargs)

        count=$((count + 1))
        echo "--- Processing reading $count: $name ---" >&2

        if [[ "$output" == "markdown" ]]; then
            run_single_reading "$name" "$date" "$time" "$lat" "$lon" "$tz" "$spread" "$question" "markdown" ""
            echo ""
            echo "============================================"
            echo ""
        else
            run_single_reading "$name" "$date" "$time" "$lat" "$lon" "$tz" "$spread" "$question" "json" ""
        fi
    done

    echo "--- Batch complete: processed $count readings ---" >&2
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if [[ -n "$BATCH" ]]; then
    run_batch "$BATCH" "$OUTPUT"
else
    # Validate required args (realtime/reading modes don't need date/time)
    if [[ "$MODE" == "destiny" ]]; then
        if [[ -z "$NAME" || -z "$DATE" || -z "$TIME" || -z "$LAT" || -z "$LON" || -z "$TZ" ]]; then
            echo "Error: destiny mode requires --name, --date, --time, --lat, --lon, --tz" >&2
            echo "Run with --help for usage" >&2
            exit 1
        fi
    else
        if [[ -z "$NAME" || -z "$TZ" ]]; then
            echo "Error: --name and --tz are required for all modes" >&2
            echo "Run with --help for usage" >&2
            exit 1
        fi
        # Set defaults for non-destiny modes if not provided
        if [[ -z "$DATE" ]]; then DATE=$(date +%Y-%m-%d); fi
        if [[ -z "$TIME" ]]; then TIME=$(date +%H:%M); fi
        if [[ -z "$LAT" ]]; then LAT="0"; fi
        if [[ -z "$LON" ]]; then LON="0"; fi
    fi

    run_single_reading "$NAME" "$DATE" "$TIME" "$LAT" "$LON" "$TZ" "$SPREAD" "$QUESTION" "$OUTPUT" "$SEED" "$MODE" "$QUESTION_TEXT"
fi
