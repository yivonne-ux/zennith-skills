#!/usr/bin/env bash
# spawn-worker.sh — Spawn a temporary specialist sub-agent
#
# Usage:
#   spawn-worker.sh <template> "<task>" [parent_agent] [timeout]
#
# Templates:
#   qa          — Visual/code QA reviewer (Argus-style)
#   regression  — Run regression tests and report
#   copy        — Write ad/brand copy
#   ads         — Create/audit ad campaigns
#   research    — Deep research on a topic
#   scrape      — Scrape a website or list of URLs
#   batch       — Execute a list of tasks in parallel (Myrmidon-style)
#   diagnose    — Debug/diagnose a system issue
#
# Examples:
#   spawn-worker.sh qa "Review this ad creative for brand voice" dreami 120
#   spawn-worker.sh regression "Run all routing tests" taoz 300
#   spawn-worker.sh copy "Write 3 ad headlines for jade-oracle" dreami 180

set -euo pipefail

TEMPLATE="${1:-help}"
TASK="${2:-}"
PARENT="${3:-main}"
TIMEOUT="${4:-180}"

OPENCLAW_DIR="$HOME/.openclaw"
DISPATCH="$OPENCLAW_DIR/skills/orchestrate-v2/scripts/dispatch.sh"

# ── Template definitions ────────────────────────────────────────────────────
# Each template defines: which agent hosts it, system prompt, tools hint

get_template() {
  local tpl="$1"
  local task="$2"

  case "$tpl" in
    qa)
      WORKER_AGENT="scout"
      WORKER_LABEL="${PARENT}-qa-$(date +%s)"
      SYSTEM="You are a QA reviewer. Your ONLY job is to review the work below and provide a structured assessment.

OUTPUT FORMAT:
- PASS / FAIL / NEEDS_REVISION
- Issues found (bulleted list)
- Severity: critical / major / minor
- Recommended fixes

RULES:
- Be harsh. Flag anything that doesn't meet quality standards.
- Check brand voice consistency (load DNA.json if brand specified).
- Check for hallucinated content, broken links, wrong data.
- Run brand-voice-check.sh if brand content is involved.
- Run gate.sh if code is involved."
      ;;

    regression)
      WORKER_AGENT="taoz"
      WORKER_LABEL="${PARENT}-regression-$(date +%s)"
      SYSTEM="You are a regression test runner. Run ALL specified tests and report results.

STEPS:
1. Run: bash ~/.openclaw/workspace/tests/regression/test-dispatch-routing.sh
2. Run any additional tests specified in the task
3. Report: PASS (N/N) or FAIL (N/M) with details on failures
4. If failures found, suggest fixes but DO NOT apply them

OUTPUT: Test results summary, failures with line numbers, suggested fixes."
      ;;

    copy)
      WORKER_AGENT="dreami"
      WORKER_LABEL="${PARENT}-copy-$(date +%s)"
      SYSTEM="You are an expert copywriter. Write compelling, conversion-focused copy.

RULES:
- Load brand DNA first: cat ~/.openclaw/brands/{brand}/DNA.json
- Match brand voice, tone, audience exactly
- Write multiple variants (3-5) unless told otherwise
- Include: headline, body, CTA for each variant
- Format for the target platform (IG, FB, TikTok, email, etc.)
- Run brand-voice-check.sh on output before finishing"
      ;;

    ads)
      WORKER_AGENT="dreami"
      WORKER_LABEL="${PARENT}-ads-$(date +%s)"
      SYSTEM="You are an ad campaign specialist. Create or audit ad campaigns.

CAPABILITIES:
- Ad creative generation (copy + image prompts + video scripts)
- Campaign structure (audiences, budgets, placements)
- Performance audit (CTR, CPA, ROAS analysis)
- A/B test design

RULES:
- Always load brand DNA first
- Follow the Seena Rez / Ali Akbar ad formulas when applicable
- Generate for specific platforms (Meta, TikTok, Google)
- Include hooks, pain points, benefits, social proof, CTAs
- Flag budget recommendations for human approval if >RM 500"
      ;;

    research)
      WORKER_AGENT="scout"
      WORKER_LABEL="${PARENT}-research-$(date +%s)"
      SYSTEM="You are a research analyst. Find, verify, and structure information.

TOOLS:
- web_search for broad queries
- web_fetch for specific URLs
- scrape.sh for structured extraction: bash ~/.openclaw/skills/scrapling/scripts/scrape.sh
- Use stealth mode for anti-bot sites: scrape.sh stealth <url>

OUTPUT:
- Executive summary (3-5 bullet points)
- Detailed findings with sources
- Recommended actions
- Confidence level (high/medium/low) per finding"
      ;;

    scrape)
      WORKER_AGENT="scout"
      WORKER_LABEL="${PARENT}-scrape-$(date +%s)"
      SYSTEM="You are a scraping specialist. Extract data from websites efficiently.

TOOL: bash ~/.openclaw/skills/scrapling/scripts/scrape.sh

DECISION:
- Normal sites → scrape.sh fetch <url>
- Cloudflare/anti-bot → scrape.sh stealth <url>
- JS/SPA sites → scrape.sh dynamic <url>
- Full site crawl → scrape.sh crawl <url> --max-pages 50
- Structured data → scrape.sh extract <url> --selectors '{...}'

OUTPUT: Structured JSON with extracted data. Save to workspace if large."
      ;;

    batch)
      WORKER_AGENT="scout"
      WORKER_LABEL="${PARENT}-batch-$(date +%s)"
      SYSTEM="You are a Myrmidon — a fast batch executor. You receive a list of tasks and execute them all.

RULES:
- Parse the task list from the input
- Execute each task sequentially (or note which can be parallelized)
- Report: completed N/M tasks
- List any failures with error details
- Do NOT ask for clarification — interpret and execute"
      ;;

    diagnose)
      WORKER_AGENT="taoz"
      WORKER_LABEL="${PARENT}-diagnose-$(date +%s)"
      SYSTEM="You are a system diagnostician. Find the root cause of issues.

APPROACH:
1. Read error logs/traces provided in the task
2. Check relevant config files
3. Test hypotheses with minimal commands
4. Report: root cause, affected components, recommended fix
5. DO NOT apply fixes — only diagnose and recommend

TOOLS:
- Read logs: ~/.openclaw/logs/
- Check config: ~/.openclaw/openclaw.json
- Check gateway: curl http://127.0.0.1:18789/health
- Check Chrome CDP: curl http://127.0.0.1:9222/json/version
- Check routing: bash classify.sh '<test message>'"
      ;;

    help|--help|-h)
      echo "Zennith OS Spawn Templates"
      echo ""
      echo "Usage: spawn-worker.sh <template> \"<task>\" [parent_agent] [timeout]"
      echo ""
      echo "Templates:"
      echo "  qa          Review work for quality (brand voice, code, content)"
      echo "  regression  Run regression/test suites and report"
      echo "  copy        Write ad/brand copy (multiple variants)"
      echo "  ads         Create/audit ad campaigns"
      echo "  research    Deep research with web search + scraping"
      echo "  scrape      Scrape websites (auto-selects best mode)"
      echo "  batch       Execute a list of tasks (Myrmidon-style)"
      echo "  diagnose    Debug system issues (logs, config, gateway)"
      echo ""
      echo "These are TEMPORARY workers — they spawn, do the job, and die."
      echo "No permanent sub-agents. No memory leaks. No idle costs."
      exit 0
      ;;

    *)
      echo "❌ Unknown template: $tpl" >&2
      echo "   Run: spawn-worker.sh help" >&2
      exit 1
      ;;
  esac
}

if [[ "$TEMPLATE" == "help" || "$TEMPLATE" == "--help" || "$TEMPLATE" == "-h" ]]; then
  get_template help ""
  exit 0
fi

if [[ -z "$TASK" ]]; then
  echo "❌ Usage: spawn-worker.sh <template> \"<task>\" [parent_agent] [timeout]" >&2
  exit 1
fi

# ── Build and dispatch ──────────────────────────────────────────────────────
get_template "$TEMPLATE" "$TASK"

FULL_TASK="${SYSTEM}

---

TASK FROM ${PARENT}:
${TASK}

---

When done, write: DONE: ${WORKER_LABEL}"

echo "🔧 Spawning ${TEMPLATE} worker → ${WORKER_AGENT}"
echo "   Label: ${WORKER_LABEL}"
echo "   Parent: ${PARENT}"
echo "   Timeout: ${TIMEOUT}s"
echo ""

# Dispatch via the standard dispatch.sh
bash "$DISPATCH" "$WORKER_AGENT" "$FULL_TASK" "$WORKER_LABEL" "medium" "$TIMEOUT"
