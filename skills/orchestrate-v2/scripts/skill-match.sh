#!/usr/bin/env bash
# skill-match.sh — Fast skill matcher for Zennith OS
# Zero LLM cost — pure keyword matching against skill-registry.v2.json
# Bash 3.2 compatible (macOS). Uses python3 for JSON processing.
#
# Usage:
#   skill-match.sh "generate an image of Jade in a garden"   # top 3 matches
#   skill-match.sh "scrape psychic samira website"            # top 3 matches
#   skill-match.sh --top 1 "audit meta ads"                  # top 1 only
#   skill-match.sh --json "build a shopify page"             # JSON output
#   skill-match.sh --list                                     # list all active skills
#   skill-match.sh --list --agent taoz                       # skills for taoz
#   skill-match.sh --describe nanobanana                     # full skill details

set -euo pipefail

REGISTRY="/Users/jennwoeiloh/.openclaw/workspace/data/skill-registry.v2.json"

# Parse args
MODE="match"
QUERY=""
TOP_N=3
JSON_OUTPUT=0
AGENT_FILTER=""
SKILL_NAME=""

while [ $# -gt 0 ]; do
    case "$1" in
        --list)     MODE="list" ;;
        --describe) MODE="describe"; shift; SKILL_NAME="${1:-}" ;;
        --json)     JSON_OUTPUT=1 ;;
        --top)      shift; TOP_N="${1:-3}" ;;
        --agent)    shift; AGENT_FILTER="${1:-}" ;;
        --help|-h)
            echo "Usage: skill-match.sh [OPTIONS] [QUERY]"
            echo ""
            echo "Modes:"
            echo "  skill-match.sh \"query text\"              Match query to skills (top 3)"
            echo "  skill-match.sh --list                     List all active skills"
            echo "  skill-match.sh --list --agent taoz        List skills for an agent"
            echo "  skill-match.sh --describe <skill>         Show full skill details"
            echo ""
            echo "Options:"
            echo "  --top N      Return top N matches (default: 3)"
            echo "  --json       Output as JSON"
            echo "  --agent X    Filter by agent"
            echo "  --help       Show this help"
            exit 0
            ;;
        -*)
            echo "ERROR: Unknown option '$1'" >&2
            exit 1
            ;;
        *)
            QUERY="$1"
            ;;
    esac
    shift
done

if [ ! -f "$REGISTRY" ]; then
    echo "ERROR: skill-registry.v2.json not found. Run skill-discover.sh first." >&2
    exit 1
fi

python3 - "$MODE" "$QUERY" "$TOP_N" "$JSON_OUTPUT" "$AGENT_FILTER" "$SKILL_NAME" "$REGISTRY" << 'PYEOF'
import json, sys, re

MODE = sys.argv[1]
QUERY = sys.argv[2]
TOP_N = int(sys.argv[3])
JSON_OUTPUT = sys.argv[4] == "1"
AGENT_FILTER = sys.argv[5]
SKILL_NAME = sys.argv[6]
REGISTRY_PATH = sys.argv[7]

with open(REGISTRY_PATH) as f:
    registry = json.load(f)

skills = registry.get("skills", {})


def score_skill(skill, query_words):
    """Score a skill against query words.
    Scoring:
      - Exact match in trigger_patterns: 3 pts
      - Exact match in skill name: 5 pts
      - Partial match in trigger_patterns (query word is substring): 1 pt
      - Match in description words: 1 pt
      - Match in capabilities: 2 pts
      - Match in category: 2 pts
    """
    score = 0
    triggers = [t.lower() for t in skill.get("trigger_patterns", [])]
    desc_words = set(re.findall(r'[a-z][a-z-]+', skill.get("description", "").lower()))
    caps = [c.lower() for c in skill.get("capabilities", [])]
    category = skill.get("category", "").lower()
    name = skill.get("name", "").lower()
    name_parts = set(name.split('-'))

    for qw in query_words:
        qw_lower = qw.lower()
        if len(qw_lower) < 2:
            continue

        # Exact match in skill name or name parts (highest value)
        if qw_lower == name or qw_lower in name_parts:
            score += 5

        # Exact match in trigger_patterns
        if qw_lower in triggers:
            score += 3
        else:
            # Partial match (query word is substring of a trigger or vice versa)
            for t in triggers:
                if qw_lower in t or t in qw_lower:
                    score += 1
                    break

        # Match in description
        if qw_lower in desc_words:
            score += 1

        # Match in capabilities
        if qw_lower in caps:
            score += 2
        else:
            for c in caps:
                if qw_lower in c or c in qw_lower:
                    score += 1
                    break

        # Match in category
        if qw_lower == category or qw_lower in category:
            score += 2

    return score


def filter_by_agent(skills_dict, agent):
    """Filter skills that include the specified agent."""
    if not agent:
        return skills_dict
    return {k: v for k, v in skills_dict.items()
            if agent in v.get("agents", [])}


# === LIST MODE ===
if MODE == "list":
    filtered = filter_by_agent(skills, AGENT_FILTER)
    active = {k: v for k, v in filtered.items() if v.get("active", True)}

    if JSON_OUTPUT:
        out = []
        for name in sorted(active.keys()):
            s = active[name]
            out.append({
                "name": name,
                "category": s.get("category", "other"),
                "description": s.get("description", ""),
                "agents": s.get("agents", []),
                "cli_command": s.get("cli_command", ""),
            })
        print(json.dumps(out, indent=2))
    else:
        # Group by category
        by_cat = {}
        for name, s in sorted(active.items()):
            cat = s.get("category", "other")
            if cat not in by_cat:
                by_cat[cat] = []
            by_cat[cat].append(s)

        agent_label = f" (agent: {AGENT_FILTER})" if AGENT_FILTER else ""
        print(f"ACTIVE SKILLS ({len(active)}){agent_label}\n")

        cat_icons = {
            "creative": "ART", "video": "VID", "ads": "ADS", "content": "CON",
            "scraping": "WEB", "build": "BLD", "ops": "OPS", "knowledge": "KNW",
            "commerce": "COM", "other": "OTH"
        }

        for cat in sorted(by_cat.keys()):
            icon = cat_icons.get(cat, "---")
            print(f"[{icon}] {cat.upper()}")
            for s in sorted(by_cat[cat], key=lambda x: x["name"]):
                name = s["name"]
                desc = s.get("description", "")[:70]
                cli = s.get("cli_command", "").split("/")[-1] if s.get("cli_command") else ""
                agents = ",".join(s.get("agents", []))
                print(f"  {name:<28s} {desc}")
                if cli:
                    print(f"  {'':28s} -> {cli}  [{agents}]")
            print()

    sys.exit(0)


# === DESCRIBE MODE ===
if MODE == "describe":
    if not SKILL_NAME:
        print("ERROR: --describe requires a skill name", file=sys.stderr)
        sys.exit(1)
    if SKILL_NAME not in skills:
        # Try fuzzy
        matches = [k for k in skills if SKILL_NAME in k]
        if matches:
            SKILL_NAME = matches[0]
        else:
            print(f"ERROR: Skill '{SKILL_NAME}' not found", file=sys.stderr)
            sys.exit(1)

    s = skills[SKILL_NAME]
    if JSON_OUTPUT:
        print(json.dumps(s, indent=2))
    else:
        print(f"SKILL: {s['name']}")
        print(f"Category: {s.get('category', 'other')}")
        print(f"Active: {s.get('active', False)}")
        print(f"Description: {s.get('description', 'N/A')}")
        print(f"Agents: {', '.join(s.get('agents', []))}")
        print(f"Capabilities: {', '.join(s.get('capabilities', []))}")
        print(f"CLI Command: {s.get('cli_command', 'N/A')}")
        print(f"Example: {s.get('example_usage', 'N/A')}")
        print(f"Path: {s.get('path', 'N/A')}")
        print(f"Triggers ({len(s.get('trigger_patterns', []))}): {', '.join(s.get('trigger_patterns', []))}")
    sys.exit(0)


# === MATCH MODE ===
if MODE == "match":
    if not QUERY:
        print("ERROR: Query required. Usage: skill-match.sh \"your query here\"", file=sys.stderr)
        sys.exit(1)

    # Tokenize query
    query_words = re.findall(r'[a-zA-Z][a-zA-Z-]+', QUERY.lower())

    # Filter by agent if specified
    filtered = filter_by_agent(skills, AGENT_FILTER)

    # Score all skills
    scored = []
    for name, skill in filtered.items():
        if not skill.get("active", True):
            continue
        s = score_skill(skill, query_words)
        if s > 0:
            scored.append((name, s, skill))

    # Sort by score descending
    scored.sort(key=lambda x: -x[1])

    # Top N
    top = scored[:TOP_N]

    if not top:
        if JSON_OUTPUT:
            print("[]")
        else:
            print("No matching skills found.")
        sys.exit(0)

    if JSON_OUTPUT:
        out = []
        for name, score, skill in top:
            out.append({
                "name": name,
                "score": score,
                "description": skill.get("description", ""),
                "cli_command": skill.get("cli_command", ""),
                "example_usage": skill.get("example_usage", ""),
                "agents": skill.get("agents", []),
                "category": skill.get("category", "other"),
            })
        print(json.dumps(out, indent=2))
    else:
        print(f"Query: \"{QUERY}\"")
        print(f"Top {len(top)} matches:\n")
        for i, (name, score, skill) in enumerate(top, 1):
            desc = skill.get("description", "")[:80]
            cli = skill.get("cli_command", "")
            agents = ", ".join(skill.get("agents", []))
            print(f"  {i}. {name} (score: {score})")
            print(f"     {desc}")
            if cli:
                print(f"     CMD: {cli}")
            print(f"     Agents: {agents}")
            print()
PYEOF
