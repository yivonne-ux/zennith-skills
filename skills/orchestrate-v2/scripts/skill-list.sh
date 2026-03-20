#!/usr/bin/env bash
# skill-list.sh — Human-readable skill catalog for Zennith OS
# Bash 3.2 compatible (macOS). Uses python3 for JSON processing.
#
# Usage:
#   skill-list.sh                    # all skills grouped by category
#   skill-list.sh --agent taoz       # skills for taoz
#   skill-list.sh --category ads     # show ads-related skills
#   skill-list.sh --trigger "video"  # skills triggered by "video" keyword
#   skill-list.sh --compact          # one skill per line
#   skill-list.sh --json             # JSON output

set -euo pipefail

REGISTRY="/Users/jennwoeiloh/.openclaw/workspace/data/skill-registry.v2.json"

AGENT_FILTER=""
CATEGORY_FILTER=""
TRIGGER_FILTER=""
COMPACT=0
JSON_OUTPUT=0

while [ $# -gt 0 ]; do
    case "$1" in
        --agent)    shift; AGENT_FILTER="${1:-}" ;;
        --category) shift; CATEGORY_FILTER="${1:-}" ;;
        --trigger)  shift; TRIGGER_FILTER="${1:-}" ;;
        --compact)  COMPACT=1 ;;
        --json)     JSON_OUTPUT=1 ;;
        --help|-h)
            echo "Usage: skill-list.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --agent NAME      Filter by agent (main, taoz, dreami, scout)"
            echo "  --category NAME   Filter by category (creative, video, ads, content, scraping, build, ops, knowledge, commerce)"
            echo "  --trigger WORD    Find skills with this trigger keyword"
            echo "  --compact         One skill per line"
            echo "  --json            Output as JSON"
            echo "  --help            Show this help"
            exit 0
            ;;
        *) echo "ERROR: Unknown option '$1'" >&2; exit 1 ;;
    esac
    shift
done

if [ ! -f "$REGISTRY" ]; then
    echo "ERROR: skill-registry.v2.json not found. Run skill-discover.sh first." >&2
    exit 1
fi

python3 - "$AGENT_FILTER" "$CATEGORY_FILTER" "$TRIGGER_FILTER" "$COMPACT" "$JSON_OUTPUT" "$REGISTRY" << 'PYEOF'
import json, sys

AGENT_FILTER = sys.argv[1]
CATEGORY_FILTER = sys.argv[2].lower()
TRIGGER_FILTER = sys.argv[3].lower()
COMPACT = sys.argv[4] == "1"
JSON_OUTPUT = sys.argv[5] == "1"
REGISTRY_PATH = sys.argv[6]

with open(REGISTRY_PATH) as f:
    registry = json.load(f)

skills = registry.get("skills", {})

# Apply filters
filtered = {}
for name, skill in skills.items():
    if not skill.get("active", True):
        continue
    if AGENT_FILTER and AGENT_FILTER not in skill.get("agents", []):
        continue
    if CATEGORY_FILTER and skill.get("category", "") != CATEGORY_FILTER:
        continue
    if TRIGGER_FILTER:
        triggers = [t.lower() for t in skill.get("trigger_patterns", [])]
        if not any(TRIGGER_FILTER in t or t in TRIGGER_FILTER for t in triggers):
            continue
    filtered[name] = skill

if JSON_OUTPUT:
    out = []
    for name in sorted(filtered.keys()):
        s = filtered[name]
        out.append({
            "name": name,
            "category": s.get("category", "other"),
            "description": s.get("description", ""),
            "agents": s.get("agents", []),
            "cli_command": s.get("cli_command", ""),
            "example_usage": s.get("example_usage", ""),
            "trigger_patterns": s.get("trigger_patterns", []),
        })
    print(json.dumps(out, indent=2))
    sys.exit(0)

# Category display config
CAT_CONFIG = {
    "creative": {"icon": "ART", "label": "Creative"},
    "video":    {"icon": "VID", "label": "Video"},
    "ads":      {"icon": "ADS", "label": "Ads & Marketing"},
    "content":  {"icon": "CON", "label": "Content"},
    "scraping": {"icon": "WEB", "label": "Web & Scraping"},
    "build":    {"icon": "BLD", "label": "Build & Code"},
    "ops":      {"icon": "OPS", "label": "Operations"},
    "knowledge":{"icon": "KNW", "label": "Knowledge"},
    "commerce": {"icon": "COM", "label": "Commerce"},
    "other":    {"icon": "OTH", "label": "Other"},
}

# Group by category
by_cat = {}
for name, s in filtered.items():
    cat = s.get("category", "other")
    if cat not in by_cat:
        by_cat[cat] = []
    by_cat[cat].append(s)

# Build filter label
labels = []
if AGENT_FILTER:
    labels.append(f"agent={AGENT_FILTER}")
if CATEGORY_FILTER:
    labels.append(f"category={CATEGORY_FILTER}")
if TRIGGER_FILTER:
    labels.append(f"trigger=\"{TRIGGER_FILTER}\"")
filter_label = f" ({', '.join(labels)})" if labels else ""

if COMPACT:
    print(f"ACTIVE SKILLS ({len(filtered)}){filter_label}")
    print("-" * 60)
    for cat in sorted(by_cat.keys()):
        cfg = CAT_CONFIG.get(cat, CAT_CONFIG["other"])
        for s in sorted(by_cat[cat], key=lambda x: x["name"]):
            name = s["name"]
            desc = s.get("description", "")[:50]
            agents = ",".join(s.get("agents", []))
            cli = s.get("cli_command", "").split("/")[-1] if s.get("cli_command") else "-"
            print(f"[{cfg['icon']}] {name:<26s} {cli:<30s} [{agents}]")
    sys.exit(0)

# Full display
print(f"ACTIVE SKILLS ({len(filtered)}){filter_label}")
print("=" * 70)
print()

cat_order = ["creative", "video", "ads", "content", "scraping", "build", "ops", "knowledge", "commerce", "other"]
for cat in cat_order:
    if cat not in by_cat:
        continue
    cfg = CAT_CONFIG.get(cat, CAT_CONFIG["other"])
    print(f"[{cfg['icon']}] {cfg['label']}")
    print("-" * 50)

    for s in sorted(by_cat[cat], key=lambda x: x["name"]):
        name = s["name"]
        desc = s.get("description", "")
        # Truncate description smartly
        if len(desc) > 75:
            desc = desc[:72] + "..."
        cli = s.get("cli_command", "")
        agents = ", ".join(s.get("agents", []))
        example = s.get("example_usage", "")

        print(f"  {name}")
        print(f"    {desc}")
        if cli:
            cmd_short = cli.replace("~/.openclaw/skills/", "").replace("/scripts/", " -> ")
            print(f"    CMD: {cmd_short}")
        print(f"    Agents: {agents}")
        if TRIGGER_FILTER and s.get("trigger_patterns"):
            matching = [t for t in s["trigger_patterns"] if TRIGGER_FILTER in t.lower()]
            if matching:
                print(f"    Matching triggers: {', '.join(matching[:5])}")
        print()

    print()
PYEOF
