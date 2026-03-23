#!/usr/bin/env bash
# jade-social-director.sh — Social media director for Jade Oracle
#
# Scrapes top spiritual IG accounts, extracts viral patterns, and generates
# a 9-post daily content plan fed by competitor intelligence.
#
# Usage:
#   bash jade-social-director.sh scrape   [--dry-run]  # Research top accounts
#   bash jade-social-director.sh analyze  [--dry-run]  # Extract viral patterns
#   bash jade-social-director.sh plan     [--dry-run]  # Generate tomorrow's 9-post plan
#   bash jade-social-director.sh full     [--dry-run]  # All three in sequence
#
# macOS Bash 3.2 compatible. Uses claude --print for LLM calls ($0 via Claude Max).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW_DIR="$HOME/.openclaw"

DATE=$(date +%Y-%m-%d)
TOMORROW=$(date -v+1d +%Y-%m-%d 2>/dev/null || date -d "+1 day" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)

# Parse args
CMD="${1:-full}"
DRY_RUN=0
for arg in "$@"; do
    [[ "$arg" == "--dry-run" ]] && DRY_RUN=1
done

# ---------------------------------------------------------------------------
# Target accounts
# ---------------------------------------------------------------------------
TIER1_ACCOUNTS="mysticmichaela theholisticpsychologist spiritdaughter girl_and_her_moon"
TIER2_ACCOUNTS="the.tarot.teacher mysticbbyg notes_from_your_therapist bymariandrew"
TIER3_ACCOUNTS="psychicsamira"

ALL_ACCOUNTS="$TIER1_ACCOUNTS $TIER2_ACCOUNTS $TIER3_ACCOUNTS"

PINTEREST_TOPICS="spiritual aesthetic,oracle deck design,tarot card aesthetic,minimalist spiritual quotes,korean wellness aesthetic"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCHEDULE_JSON="$SCRIPT_DIR/../data/jade-9post-schedule.json"
REPORT_DIR="$OPENCLAW_DIR/workspace/data/jade-oracle-content-pipeline/director-reports"
PLAN_DIR="$OPENCLAW_DIR/workspace/data/content/jade-oracle/daily/$TOMORROW"
SCRAPE_DIR="$OPENCLAW_DIR/workspace/data/jade-oracle-content-pipeline/scrapes/$DATE"
BRAND_DNA="$OPENCLAW_DIR/brands/jade-oracle/DNA.json"
ROOM_FILE="$OPENCLAW_DIR/workspace/rooms/mission-jade-oracle-launch.jsonl"
LOG_DIR="$OPENCLAW_DIR/logs"

mkdir -p "$REPORT_DIR" "$PLAN_DIR" "$SCRAPE_DIR" "$LOG_DIR"

LOG_FILE="$LOG_DIR/jade-social-director-$(date +%Y%m%d).log"

# ---------------------------------------------------------------------------
# Claude CLI
# ---------------------------------------------------------------------------
CLAUDE_CLI="$(command -v claude 2>/dev/null || echo "")"
CLAUDE_MODEL="claude-sonnet-4-6"

claude_print() {
    # Usage: claude_print "prompt text"   OR   echo "prompt" | claude_print
    # Returns LLM output on stdout
    if [[ -z "$CLAUDE_CLI" ]]; then
        err "claude CLI not found — cannot run LLM calls"
        return 1
    fi
    local _tmp
    _tmp=$(mktemp)
    if [ $# -gt 0 ]; then
        printf '%s' "$*" > "$_tmp"
    else
        cat > "$_tmp"
    fi
    local _out
    _out=$(cat "$_tmp" | "$CLAUDE_CLI" --print --model "$CLAUDE_MODEL" 2>/dev/null) || true
    rm -f "$_tmp"
    printf '%s' "$_out"
}

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
log() {
    local msg="[jade-social-director $(date +%H:%M:%S)] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

err() {
    local msg="[jade-social-director $(date +%H:%M:%S)] ERROR: $1"
    echo "$msg" >&2
    echo "$msg" >> "$LOG_FILE"
}

room_msg() {
    local type="$1" body="$2"
    [[ -f "$ROOM_FILE" ]] || return 0
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"from\":\"taoz\",\"type\":\"$type\",\"body\":\"$body\"}" >> "$ROOM_FILE" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# PHASE 1: SCRAPE — Research top accounts via Claude + web search
# ---------------------------------------------------------------------------
run_scrape() {
    log "=== SCRAPE PHASE ==="
    log "Researching ${#ALL_ACCOUNTS} accounts + Pinterest trends..."

    if [[ -z "$CLAUDE_CLI" ]]; then
        err "claude CLI not found. Install: https://docs.anthropic.com/claude-code"
        return 1
    fi

    # --- Scrape Instagram accounts ---
    local account_count=0
    local total_accounts=0
    for acct in $ALL_ACCOUNTS; do
        total_accounts=$((total_accounts + 1))
    done

    for acct in $ALL_ACCOUNTS; do
        account_count=$((account_count + 1))
        local tier="tier3"
        local found=0
        for t1 in $TIER1_ACCOUNTS; do
            if [[ "$t1" == "$acct" ]]; then tier="tier1"; found=1; break; fi
        done
        if [[ "$found" -eq 0 ]]; then
            for t2 in $TIER2_ACCOUNTS; do
                if [[ "$t2" == "$acct" ]]; then tier="tier2"; found=1; break; fi
            done
        fi
        if [[ "$found" -eq 0 ]]; then tier="tier3"; fi

        local outfile="$SCRAPE_DIR/${tier}_${acct}.md"
        log "  [$account_count/$total_accounts] Researching @${acct} ($tier)..."

        if [[ "$DRY_RUN" -eq 1 ]]; then
            log "  [DRY RUN] Would research @${acct}"
            echo "# @${acct} — DRY RUN" > "$outfile"
            continue
        fi

        # Skip if already scraped today
        if [[ -f "$outfile" ]] && [[ "$(wc -l < "$outfile" | tr -d ' ')" -gt 5 ]]; then
            log "  Already scraped today, skipping."
            continue
        fi

        # Use Claude to research the account
        local research_output=""
        _tmpf_research_output=$(mktemp)
        cat > "$_tmpf_research_output" << PROMPT
You are a social media intelligence analyst. Research the Instagram account @${acct} in the spiritual/wellness niche.

Based on your knowledge, provide:

1. **Account Overview**: Follower estimate, posting frequency, niche positioning
2. **Recent Content Themes** (last 2-4 weeks likely content):
   - What topics are they covering?
   - What content formats dominate? (carousel, single image, Reel, quote graphic)
   - What visual style? (photography, illustration, text-heavy, aesthetic)
3. **Top Performing Content Patterns**:
   - What hooks do they use? (first lines of captions)
   - What drives saves/shares in their niche?
   - What CTAs work for them?
4. **Engagement Tactics**:
   - How do they drive comments?
   - Do they use Stories/Reels integration?
   - Community building approaches
5. **Viral Post Examples**: Describe 3-5 posts that likely perform best (high saves/shares)
6. **Weakness/Gap**: What are they NOT doing that Jade Oracle could exploit?

Be specific and actionable. This is for competitive intelligence.
PROMPT
        research_output=$(claude_print < "$_tmpf_research_output") || true
        rm -f "$_tmpf_research_output"

        if [[ -n "$research_output" ]]; then
            {
                echo "# @${acct} — Competitive Intelligence"
                echo "## Scraped: $DATE | Tier: $tier"
                echo ""
                echo "$research_output"
            } > "$outfile"
            log "  Saved: $outfile ($(wc -l < "$outfile" | tr -d ' ') lines)"
        else
            err "  Failed to research @${acct}"
            echo "# @${acct} — SCRAPE FAILED $DATE" > "$outfile"
        fi
    done

    # --- Research Pinterest trends ---
    local pinterest_outfile="$SCRAPE_DIR/pinterest_trends.md"
    log "  Researching Pinterest trends..."

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "  [DRY RUN] Would research Pinterest trends"
        echo "# Pinterest Trends — DRY RUN" > "$pinterest_outfile"
    elif [[ -f "$pinterest_outfile" ]] && [[ "$(wc -l < "$pinterest_outfile" | tr -d ' ')" -gt 5 ]]; then
        log "  Already scraped Pinterest today, skipping."
    else
        local pinterest_output=""
        _tmpf_pinterest_output=$(mktemp)
        cat > "$_tmpf_pinterest_output" << PROMPT
You are a visual trend analyst specializing in the spiritual wellness aesthetic space on Pinterest.

Research the following Pinterest trend topics and provide intelligence for an Instagram content strategy:

Topics: ${PINTEREST_TOPICS}

For each topic, provide:
1. **Current Visual Trends**: What styles, color palettes, compositions are trending?
2. **Top Pin Formats**: What types of pins get the most saves? (infographic, quote, photo, collage)
3. **Aesthetic Direction**: Describe the current aesthetic mood in 2-3 sentences
4. **Adaptable Ideas**: 3 specific visual ideas that could be adapted for Instagram posts
5. **Color/Mood Palette**: Dominant colors and mood keywords

Focus on what's fresh and trending NOW (early 2026), not evergreen generic advice.
The brand adapting this is Jade Oracle — Korean-inspired modern spirituality, warm tones, editorial photography feel, jade green + burgundy palette.
PROMPT
        pinterest_output=$(claude_print < "$_tmpf_pinterest_output") || true
        rm -f "$_tmpf_pinterest_output"

        if [[ -n "$pinterest_output" ]]; then
            {
                echo "# Pinterest Trend Intelligence"
                echo "## Scraped: $DATE"
                echo "## Topics: $PINTEREST_TOPICS"
                echo ""
                echo "$pinterest_output"
            } > "$pinterest_outfile"
            log "  Saved Pinterest trends ($(wc -l < "$pinterest_outfile" | tr -d ' ') lines)"
        else
            err "  Failed to research Pinterest trends"
        fi
    fi

    # --- Compile raw scrape summary ---
    local summary_file="$SCRAPE_DIR/scrape-summary.md"
    {
        echo "# Jade Oracle — Social Scrape Summary"
        echo "## Date: $DATE"
        echo ""
        echo "### Accounts Researched"
        echo "- Tier 1 (leaders): $TIER1_ACCOUNTS"
        echo "- Tier 2 (relevant): $TIER2_ACCOUNTS"
        echo "- Tier 3 (competitor): $TIER3_ACCOUNTS"
        echo ""
        echo "### Files Generated"
        local file_count=0
        for f in "$SCRAPE_DIR"/*.md; do
            if [[ -f "$f" ]]; then
                file_count=$((file_count + 1))
                echo "- $(basename "$f") ($(wc -l < "$f" | tr -d ' ') lines)"
            fi
        done
        echo ""
        echo "**Total files: $file_count**"
    } > "$summary_file"

    log "Scrape phase complete. Files in: $SCRAPE_DIR"
    room_msg "social-scrape" "Scraped $total_accounts accounts + Pinterest trends for $DATE"
}

# ---------------------------------------------------------------------------
# PHASE 2: ANALYZE — Extract viral patterns from scraped data
# ---------------------------------------------------------------------------
run_analyze() {
    log "=== ANALYZE PHASE ==="

    if [[ -z "$CLAUDE_CLI" ]]; then
        err "claude CLI not found."
        return 1
    fi

    # Check for scraped data
    if [[ ! -d "$SCRAPE_DIR" ]] || [[ "$(find "$SCRAPE_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')" -lt 2 ]]; then
        err "Not enough scraped data in $SCRAPE_DIR. Run 'scrape' first."
        return 1
    fi

    local report_file="$REPORT_DIR/$DATE.md"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "[DRY RUN] Would analyze scraped data and generate report"
        echo "# Director Report — DRY RUN $DATE" > "$report_file"
        return 0
    fi

    # Skip if already analyzed today
    if [[ -f "$report_file" ]] && [[ "$(wc -l < "$report_file" | tr -d ' ')" -gt 20 ]]; then
        log "Already analyzed today. Report: $report_file"
        return 0
    fi

    # Collect all scrape data (truncate individual files to avoid token overflow)
    local combined_scrapes=""
    for f in "$SCRAPE_DIR"/*.md; do
        if [[ -f "$f" ]] && [[ "$(basename "$f")" != "scrape-summary.md" ]]; then
            combined_scrapes="${combined_scrapes}
--- FILE: $(basename "$f") ---
$(head -80 "$f")
---
"
        fi
    done

    # Load brand DNA summary
    local brand_summary=""
    if [[ -f "$BRAND_DNA" ]]; then
        brand_summary=$(head -40 "$BRAND_DNA")
    fi

    log "Running viral pattern analysis..."

    local analysis_output=""
    _tmpf_analysis_output=$(mktemp)
    cat > "$_tmpf_analysis_output" << PROMPT
You are an elite social media strategist analyzing competitor intelligence for Jade Oracle (@the_jade_oracle), a Korean-inspired QMDJ spiritual brand on Instagram.

## COMPETITOR SCRAPE DATA
${combined_scrapes}

## BRAND DNA (Jade Oracle)
${brand_summary}

## YOUR TASK
Analyze ALL the scraped data above and produce a Social Director Report with these exact sections:

### 1. TOP 5 VIRAL HOOKS
For each hook, provide:
- **Hook text** (the exact first line / scroll-stopping opener)
- **Why it works** (psychology)
- **Engagement estimate** (low/medium/high/viral)
- **Jade Oracle adaptation** (how to remake it with QMDJ angle)

Score each on: hook_power (1-10), visual_appeal (1-10), brand_adaptability (1-10), engagement_design (1-10), save_worthiness (1-10)

Only keep hooks scoring 35+ total (out of 50).

### 2. TOP 3 VISUAL STYLES THAT PERFORMED
- Describe the visual treatment (colors, composition, typography)
- Which accounts use it
- How Jade can adapt it (warm tones, editorial photography, jade+burgundy palette)

### 3. TOP 3 CONTENT FORMATS
- Format name (carousel, single image, quote graphic, Reel, etc.)
- Why it works for spiritual niche
- Specific execution tip for Jade

### 4. EMERGING TRENDS IN SPIRITUAL IG NICHE
- 3-5 trends gaining momentum
- How each trend maps to Jade's brand positioning
- Urgency rating (act now / this month / this quarter)

### 5. JADE'S UNIQUE QMDJ ANGLE — What Nobody Else Has
- Specific content ideas that ONLY Jade can do because of real QMDJ computation
- How to position QMDJ as the "science behind the mysticism"
- Content that makes tarot-only creators look shallow by comparison
- 5 specific QMDJ-powered post ideas competitors cannot copy

### 6. PATTERN SCORECARD
Create a table of the top 15 content patterns found, scored against Jade's brand criteria:
| Pattern | Source | hook_power | visual_appeal | brand_adaptability | engagement_design | save_worthiness | TOTAL |

Only include patterns scoring 30+ out of 50.
Sort by TOTAL descending.

Be ruthlessly specific. No generic advice. Every recommendation must reference actual competitor behavior observed in the data.
PROMPT
    analysis_output=$(claude_print < "$_tmpf_analysis_output") || true
    rm -f "$_tmpf_analysis_output"

    if [[ -n "$analysis_output" ]]; then
        {
            echo "# Jade Oracle — Social Director Report"
            echo "## Date: $DATE"
            echo "## Accounts Analyzed: $(echo "$ALL_ACCOUNTS" | wc -w | tr -d ' ')"
            echo ""
            echo "$analysis_output"
            echo ""
            echo "---"
            echo "*Generated by jade-social-director.sh at $(date +%Y-%m-%dT%H:%M:%S%z)*"
        } > "$report_file"
        log "Director report saved: $report_file ($(wc -l < "$report_file" | tr -d ' ') lines)"
        room_msg "social-analysis" "Director report generated for $DATE — $(wc -l < "$report_file" | tr -d ' ') lines"
    else
        err "Analysis failed — no output from Claude"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# PHASE 3: PLAN — Generate tomorrow's 9-post content plan
# ---------------------------------------------------------------------------
run_plan() {
    log "=== PLAN PHASE ==="
    log "Generating content plan for $TOMORROW..."

    if [[ -z "$CLAUDE_CLI" ]]; then
        err "claude CLI not found."
        return 1
    fi

    local plan_file="$PLAN_DIR/content-plan.json"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "[DRY RUN] Would generate 9-post content plan for $TOMORROW"
        echo '{"dry_run": true, "date": "'"$TOMORROW"'"}' > "$plan_file"
        return 0
    fi

    # Skip if already planned
    if [[ -f "$plan_file" ]] && [[ "$(wc -c < "$plan_file" | tr -d ' ')" -gt 500 ]]; then
        log "Content plan already exists for $TOMORROW. File: $plan_file"
        return 0
    fi

    # Load schedule
    local schedule_data=""
    if [[ -f "$SCHEDULE_JSON" ]]; then
        schedule_data=$(cat "$SCHEDULE_JSON")
    else
        err "Schedule not found: $SCHEDULE_JSON"
        return 1
    fi

    # Load today's director report (if available)
    local report_data=""
    local report_file="$REPORT_DIR/$DATE.md"
    if [[ -f "$report_file" ]]; then
        report_data=$(head -200 "$report_file")
    else
        log "No director report for today — planning without competitor intelligence"
    fi

    # Load brand DNA
    local brand_dna=""
    if [[ -f "$BRAND_DNA" ]]; then
        brand_dna=$(cat "$BRAND_DNA")
    fi

    # Determine day of week for tomorrow
    local dow_name=""
    dow_name=$(date -v+1d +%A 2>/dev/null || date -d "+1 day" +%A 2>/dev/null || echo "Unknown")

    log "Planning for $TOMORROW ($dow_name)..."

    local plan_output=""
    _tmpf_plan_output=$(mktemp)
    cat > "$_tmpf_plan_output" << PROMPT
You are Jade Oracle's social media director. Generate tomorrow's complete 9-post Instagram content plan.

## DATE: $TOMORROW ($dow_name)

## POSTING SCHEDULE (9 slots)
${schedule_data}

## DIRECTOR REPORT (today's competitor analysis)
${report_data}

## BRAND DNA
${brand_dna}

## YOUR TASK
Generate a JSON content plan for all 9 slots. Output ONLY valid JSON (no markdown fences, no commentary).

The JSON must be an object with this exact structure:
{
  "date": "$TOMORROW",
  "day_of_week": "$dow_name",
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "theme_of_day": "<overarching daily theme/energy>",
  "posts": [
    {
      "slot": 1,
      "time_myt": "07:00",
      "pillar": "oracle_wisdom",
      "type": "oracle_card",
      "format": "single_image",
      "ratio": "4:5",
      "scene_description": "<detailed image generation prompt — what Jade is doing, setting, lighting, mood, wardrobe>",
      "caption_hook": "<the crucial first line that stops the scroll — 10 words max>",
      "full_caption_direction": "<2-3 sentences describing the caption arc: hook → story → CTA>",
      "hashtag_focus": "<which hashtag set to use + 3 specific extra hashtags>",
      "inspired_by": "<which competitor post/pattern inspired this, or 'original' if organic>",
      "engagement_strategy": "<what action this post is designed to drive: saves, comments, shares, follows>",
      "scores": {
        "hook_power": 8,
        "visual_appeal": 8,
        "brand_adaptability": 10,
        "engagement_design": 7,
        "save_worthiness": 8
      }
    }
  ]
}

## RULES
1. Each slot MUST match the schedule (pillar, type, format, ratio from the schedule JSON)
2. Scene descriptions must be photorealistic — Jade (Korean woman, early 30s, long dark hair, jade pendant) in real settings. Warm natural light. NO cosmic/fantasy imagery.
3. Caption hooks must be scroll-stopping. Study the viral hooks from the director report.
4. Slot 4 (QMDJ carousel) is the authority post — make it genuinely educational about Qi Men Dun Jia.
5. Slot 8 (pick-a-card) must be interactive — designed to drive comments.
6. Slot 7 (Reel) needs a specific concept/movement/transition idea.
7. Every post must feel cohesive as a daily feed — the 9 posts together should tell a story.
8. Reference specific competitor patterns from the director report where applicable.
9. Scores must be honest — not everything is a 10. Aim for total 35+ per post.
10. The "inspired_by" field should reference real patterns (e.g., "@mysticmichaela's question hooks" or "@girl_and_her_moon's carousel format").

Output ONLY the JSON. No explanation before or after.
PROMPT
    plan_output=$(claude_print < "$_tmpf_plan_output") || true
    rm -f "$_tmpf_plan_output"

    if [[ -z "$plan_output" ]]; then
        err "Plan generation failed — no output from Claude"
        return 1
    fi

    # Strip any markdown code fences if Claude wrapped the JSON
    plan_output=$(echo "$plan_output" | sed '/^```/d')

    # Validate JSON
    if echo "$plan_output" | python3 -m json.tool > /dev/null 2>&1; then
        echo "$plan_output" | python3 -m json.tool > "$plan_file"
        log "Content plan saved: $plan_file"

        # Count posts in plan
        local post_count=""
        post_count=$(python3 -c "
import json, sys
try:
    data = json.load(open('$plan_file'))
    print(len(data.get('posts', [])))
except:
    print('?')
" 2>/dev/null || echo "?")

        log "Plan contains $post_count posts for $TOMORROW"

        # Also save a human-readable version
        local readable_file="$PLAN_DIR/content-plan-readable.md"
        python3 <<PYEOF
import json

try:
    with open("$plan_file") as f:
        plan = json.load(f)
except Exception as e:
    print(f"Failed to parse plan: {e}")
    exit(0)

lines = []
lines.append("# Jade Oracle — Content Plan")
lines.append(f"## {plan.get('date', 'Unknown')} ({plan.get('day_of_week', '')})")
lines.append(f"### Theme: {plan.get('theme_of_day', 'N/A')}")
lines.append("")

for post in plan.get("posts", []):
    slot = post.get("slot", "?")
    time = post.get("time_myt", "?")
    pillar = post.get("pillar", "?")
    ptype = post.get("type", "?")
    fmt = post.get("format", "?")

    lines.append(f"---")
    lines.append(f"## Slot {slot} — {time} MYT | {pillar} | {ptype} ({fmt})")
    lines.append("")
    lines.append(f"**Scene:** {post.get('scene_description', 'N/A')}")
    lines.append("")
    lines.append(f"**Hook:** {post.get('caption_hook', 'N/A')}")
    lines.append("")
    lines.append(f"**Caption direction:** {post.get('full_caption_direction', 'N/A')}")
    lines.append("")
    lines.append(f"**Hashtags:** {post.get('hashtag_focus', 'N/A')}")
    lines.append("")
    lines.append(f"**Inspired by:** {post.get('inspired_by', 'N/A')}")
    lines.append("")
    lines.append(f"**Engagement strategy:** {post.get('engagement_strategy', 'N/A')}")
    lines.append("")

    scores = post.get("scores", {})
    total = sum(scores.values()) if scores else 0
    score_str = " | ".join(f"{k}: {v}" for k, v in scores.items())
    lines.append(f"**Scores:** {score_str} | **TOTAL: {total}/50**")
    lines.append("")

with open("$readable_file", "w") as f:
    f.write("\n".join(lines))

print(f"Readable plan saved: $readable_file")
PYEOF

        room_msg "social-plan" "9-post content plan generated for $TOMORROW ($dow_name)"
    else
        # JSON validation failed — save raw output and try to fix
        log "JSON validation failed. Attempting to extract JSON..."
        local raw_file="$PLAN_DIR/content-plan-raw.txt"
        echo "$plan_output" > "$raw_file"

        # Try to extract JSON from the output (Claude sometimes wraps it)
        local extracted=""
        extracted=$(python3 <<PYEOF
import re, json, sys

raw = open("$raw_file").read()

# Try to find JSON object in the text
match = re.search(r'\{[\s\S]*\}', raw)
if match:
    try:
        data = json.loads(match.group())
        print(json.dumps(data, indent=2))
    except json.JSONDecodeError:
        # Try fixing common issues
        text = match.group()
        # Remove trailing commas before } or ]
        text = re.sub(r',\s*([}\]])', r'\1', text)
        try:
            data = json.loads(text)
            print(json.dumps(data, indent=2))
        except:
            sys.exit(1)
else:
    sys.exit(1)
PYEOF
        ) 2>/dev/null || true

        if [[ -n "$extracted" ]]; then
            echo "$extracted" > "$plan_file"
            log "Extracted and saved valid JSON to: $plan_file"
        else
            err "Could not produce valid JSON. Raw output saved: $raw_file"
            return 1
        fi
    fi
}

# ---------------------------------------------------------------------------
# FULL — Run all phases in sequence
# ---------------------------------------------------------------------------
run_full() {
    log "========================================="
    log "JADE ORACLE — SOCIAL DIRECTOR (FULL RUN)"
    log "Date: $DATE | Planning for: $TOMORROW"
    [[ "$DRY_RUN" -eq 1 ]] && log "MODE: DRY RUN"
    log "========================================="

    room_msg "social-director" "Social Director full run starting for $DATE"

    local failures=0

    # Phase 1: Scrape
    run_scrape || {
        err "Scrape phase failed"
        failures=$((failures + 1))
    }

    # Phase 2: Analyze
    run_analyze || {
        err "Analyze phase failed"
        failures=$((failures + 1))
    }

    # Phase 3: Plan
    run_plan || {
        err "Plan phase failed"
        failures=$((failures + 1))
    }

    log "========================================="
    if [[ "$failures" -eq 0 ]]; then
        log "SOCIAL DIRECTOR COMPLETE — ALL PHASES OK"
    else
        log "SOCIAL DIRECTOR COMPLETE — $failures PHASE(S) FAILED"
    fi
    log "========================================="
    log "Reports: $REPORT_DIR/$DATE.md"
    log "Plan:    $PLAN_DIR/content-plan.json"
    log "Scrapes: $SCRAPE_DIR/"
    log "========================================="

    room_msg "social-director" "Social Director complete. Failures: $failures. Plan for $TOMORROW ready."
    return "$failures"
}

# ---------------------------------------------------------------------------
# Main dispatch
# ---------------------------------------------------------------------------
case "$CMD" in
    scrape)   run_scrape ;;
    analyze)  run_analyze ;;
    plan)     run_plan ;;
    full)     run_full ;;
    --dry-run)
        DRY_RUN=1
        run_full
        ;;
    *)
        echo "Usage: jade-social-director.sh [scrape|analyze|plan|full] [--dry-run]"
        echo ""
        echo "Commands:"
        echo "  scrape   — Research top spiritual IG accounts + Pinterest trends"
        echo "  analyze  — Extract viral patterns and generate director report"
        echo "  plan     — Generate tomorrow's 9-post content plan (JSON)"
        echo "  full     — Run all three phases in sequence"
        echo ""
        echo "Options:"
        echo "  --dry-run  Skip actual LLM calls, create placeholder files"
        echo ""
        echo "Output:"
        echo "  Scrapes:  $SCRAPE_DIR/"
        echo "  Report:   $REPORT_DIR/$DATE.md"
        echo "  Plan:     $PLAN_DIR/content-plan.json"
        exit 1
        ;;
esac
