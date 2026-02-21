#!/usr/bin/env bash
# continuous-scout.sh — Continuous business idea & innovation scouting
# Runs every 4 hours to find new opportunities

set -uo pipefail

SCOUT_TYPE="${1:-all}"
OPENCLAW_DIR="$HOME/.openclaw"
ROOMS_DIR="$OPENCLAW_DIR/workspace/rooms"
LOG_FILE="$OPENCLAW_DIR/logs/continuous-scout.log"

TS=$(date +"%Y-%m-%d %H:%M:%S %Z")
LABEL="continuous-scout-$(date +%s)"

log() {
  echo "[$TS] $1" >> "$LOG_FILE"
  echo "$1"
}

log "=== Continuous Scout: $SCOUT_TYPE ==="

case "$SCOUT_TYPE" in
  innovation|all)
    log "Scouting AI innovations..."
    openclaw sessions spawn --label "$LABEL-innovation" --timeout 300 "You are Artemis. Read ~/.openclaw/workspace-artemis/SOUL.md. 

SCOUT TASK: Find 3 new AI agent innovations from GitHub trending, Product Hunt, or HN that could help GAIA Eats. Focus on: e-commerce automation, social media tools, content creation, or multi-agent systems.

For each innovation found, post to townhall.jsonl:
{\"ts\":$(date +%s)000,\"agent\":\"artemis\",\"room\":\"townhall\",\"type\":\"scout-find\",\"msg\":\"[Idea Title] - [1-line what it does] - Source: [URL] - Relevance: [1-10]\"}" 2>&1 | tail -5
    ;;
    
  business|all)
    log "Scouting business opportunities..."
    openclaw sessions spawn --label "$LABEL-business" --timeout 300 "You are Artemis + Hermes collaboration. Read both SOUL.md files.

SCOUT TASK: Research 2-3 business opportunities for GAIA Eats based on:
1. Current food trends in Malaysia (vegan/plant-based)
2. Competitor gaps (check Shopee/Lazada for underserved niches)
3. New revenue streams (bundles, subscriptions, B2B)

Post structured brief to exec.jsonl with:
- Opportunity name
- Estimated market size
- Competition level (low/medium/high)
- Suggested action
- Revenue potential (RM/month estimate)" 2>&1 | tail -5
    ;;
    
  content|all)
    log "Scouting content ideas..."
    openclaw sessions spawn --label "$LABEL-content" --timeout 300 "You are Apollo. Read ~/.openclaw/workspace-apollo/SOUL.md.

SCOUT TASK: Generate 5 content ideas for GAIA Eats social media. Based on:
- Upcoming holidays/events
- Current food trends
- Customer pain points (from reviews/feedback)

Post to social.jsonl with format:
{\"ts\":$(date +%s)000,\"agent\":\"apollo\",\"room\":\"social\",\"type\":\"content-ideas\",\"msg\":\"Idea: [title] | Format: [Reel/Carousel/Story] | Hook: [first 3 words]\"}" 2>&1 | tail -5
    ;;
    
  *)
    echo "Usage: continuous-scout.sh [innovation|business|content|all]"
    exit 1
    ;;
esac

log "=== Scout cycle complete ==="
