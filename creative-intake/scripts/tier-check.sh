#!/usr/bin/env bash
# tier-check.sh — Determines automation tier for a given action type
# Bash 3.2 compatible (macOS). No jq, no declare -A.
#
# Tier 1 (auto): classify, tag, analyze, route — no approval needed
# Tier 2 (auto+notify): cheap generation, local processing — runs but human gets notified
# Tier 3 (approve first): new output types, expensive APIs, publishing, brand DNA changes
#
# Usage: bash tier-check.sh <action-type>
# Output: 1, 2, or 3

ACTION_TYPE="${1:-}"

if [ -z "$ACTION_TYPE" ]; then
  echo "2"  # default to tier 2 if no action specified
  exit 0
fi

case "$ACTION_TYPE" in
  # Tier 1 — fully autonomous, no notification
  classify|tag|analyze|route|style-seed|reverse-prompt|intake-process|intake-classify|link-classify|seed-query|seed-count|list-output-types)
    echo "1" ;;

  # Tier 2 — execute + notify human (audit trail)
  nanobanana-gen|video-forge|skill-registry-update|library-ingest|image-seed-add|seed-add|creative-brief|image-analyzed|video-analyzed|technique-extraction|competitor-analysis|social-analysis|product-analysis|general-research|visual-reference)
    echo "2" ;;

  # Tier 3 — queue for human approval before executing
  new-output-type|kling-gen|sora-gen|wan-gen|publish|brand-dna-change|asset-delete|campaign-create|register-output-type|export-publish|brand-voice-update)
    echo "3" ;;

  # Default: tier 2 (safe but not blocking)
  *)
    echo "2" ;;
esac
