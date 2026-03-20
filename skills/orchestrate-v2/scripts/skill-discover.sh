#!/usr/bin/env bash
# skill-discover.sh — Scan all SKILL.md files, extract trigger patterns, usage examples,
# CLI commands, and build skill-registry.v2.json
# Bash 3.2 compatible (macOS). Uses python3 for JSON processing.
#
# Usage:
#   bash skill-discover.sh              # full rebuild of skill-registry.v2.json
#   bash skill-discover.sh --dry-run    # show JSON without writing
#   bash skill-discover.sh --stats      # show summary stats only

set -euo pipefail

SKILLS_DIR="/Users/jennwoeiloh/.openclaw/skills"
DATA_DIR="/Users/jennwoeiloh/.openclaw/workspace/data"
OUTPUT_FILE="$DATA_DIR/skill-registry.v2.json"

DRY_RUN=0
STATS_ONLY=0

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --stats)   STATS_ONLY=1 ;;
        --help|-h)
            echo "Usage: skill-discover.sh [--dry-run] [--stats]"
            echo ""
            echo "Scans all SKILL.md files and builds skill-registry.v2.json with:"
            echo "  - trigger_patterns (keywords that should activate this skill)"
            echo "  - capabilities (what it produces)"
            echo "  - cli_command (primary script to invoke)"
            echo "  - example_usage (one-line example)"
            echo "  - agents (only main, taoz, dreami, scout)"
            exit 0
            ;;
        *) echo "ERROR: Unknown option '$1'" >&2; exit 1 ;;
    esac
    shift
done

mkdir -p "$DATA_DIR"

# Collect SKILL.md paths
SKILL_MDS=""
for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name="$(basename "$skill_dir")"
    [ "$skill_name" = "_archive" ] && continue
    skill_md="$skill_dir/SKILL.md"
    if [ -f "$skill_md" ]; then
        SKILL_MDS="$SKILL_MDS
$skill_md"
    fi
done

python3 << 'PYEOF'
import json, os, re, sys, datetime, glob

SKILLS_DIR = "/Users/jennwoeiloh/.openclaw/skills"
DATA_DIR = "/Users/jennwoeiloh/.openclaw/workspace/data"
OUTPUT_FILE = os.path.join(DATA_DIR, "skill-registry.v2.json")
DRY_RUN = bool(int(os.environ.get("DRY_RUN", "0")))
STATS_ONLY = bool(int(os.environ.get("STATS_ONLY", "0")))

# Valid agents (consolidated roster)
VALID_AGENTS = {"main", "taoz", "dreami", "scout"}

# Agent name mapping (old names -> current IDs)
AGENT_MAP = {
    "zenni": "main", "main": "main",
    "taoz": "taoz",
    "dreami": "dreami", "apollo": "dreami", "calliope": "dreami",
    "scout": "scout", "artemis": "scout",
    # Retired agents map to closest current agent
    "hermes": "dreami",  # marketing -> dreami
    "iris": "dreami",    # creative -> dreami
    "athena": "main",    # strategy -> main
    "argus": "scout",    # research -> scout
    "myrmidons": "taoz", # bulk ops -> taoz
}

# Category mapping based on skill name patterns
CATEGORY_MAP = {
    "creative": ["nanobanana", "image-seed-bank", "character-design", "character-lock",
                 "character-body-pairing", "style-control", "ig-character-gen", "brand-studio",
                 "creative-intake", "creative-studio", "ref-picker", "visual-registry",
                 "ad-composer", "pinterest-ref"],
    "video": ["video-gen", "video-forge", "video-compiler", "clip-factory"],
    "ads": ["ads", "ads-audit", "ads-budget", "ads-competitor", "ads-creative",
            "ads-google", "ads-landing", "ads-linkedin", "ads-meta", "ads-microsoft",
            "ads-plan", "ads-tiktok", "ads-youtube", "campaign-planner"],
    "content": ["content-scraper", "content-supply-chain", "content-tuner",
                "ai-influencer", "social-publish", "learn-youtube"],
    "scraping": ["biz-scraper", "scrapling", "site-scraper", "firecrawl-search",
                 "site-health-auditor", "shopsteal", "browser-use", "agent-reach"],
    "build": ["claude-code", "rigour", "gstack", "taoz-auditor"],
    "ops": ["orchestrate-v2", "workflow-automation", "spawn-templates", "gaia-ops",
            "self-diagnose", "agent-vitality", "evomap", "corp-os-compound"],
    "knowledge": ["knowledge-compound", "knowledge-transfer", "psychic-reading-engine"],
    "commerce": ["shopify-manager", "onboard-brand"],
}

def get_category(skill_name):
    for cat, skills in CATEGORY_MAP.items():
        if skill_name in skills:
            return cat
    return "other"


def parse_frontmatter(filepath):
    """Parse YAML-like frontmatter between --- markers."""
    result = {}
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return result, ""

    body = content
    fm_match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
    if fm_match:
        fm_text = fm_match.group(1)
        body = content[fm_match.end():]
        for line in fm_text.split('\n'):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            m = re.match(r'^(\w[\w-]*)\s*:\s*(.+)', line)
            if m:
                key = m.group(1).strip()
                val = m.group(2).strip()
                if (val.startswith('"') and val.endswith('"')) or \
                   (val.startswith("'") and val.endswith("'")):
                    val = val[1:-1]
                if val.startswith('['):
                    try:
                        val = json.loads(val.replace("'", '"'))
                    except json.JSONDecodeError:
                        inner = val.strip('[]')
                        val = [x.strip().strip('"').strip("'") for x in inner.split(',') if x.strip()]
                result[key] = val
    return result, body


def extract_agents(fm, body):
    """Extract and normalize agent list."""
    agents = fm.get('agents', [])
    if isinstance(agents, str):
        agents = [a.strip() for a in agents.split(',')]

    # Also scan body for agent mentions
    body_lower = body.lower()
    for name, agent_id in AGENT_MAP.items():
        if agent_id in VALID_AGENTS:
            patterns = [
                r'\*\*' + re.escape(name) + r'\*\*',
                r'- ' + re.escape(name) + r'[\s(]',
            ]
            for pat in patterns:
                if re.search(pat, body_lower):
                    agents.append(agent_id)

    # Normalize: map old names, deduplicate, filter valid only
    normalized = set()
    for a in agents:
        a_lower = a.strip().lower()
        mapped = AGENT_MAP.get(a_lower, a_lower)
        if mapped in VALID_AGENTS:
            normalized.add(mapped)

    return sorted(list(normalized))


def extract_trigger_patterns(skill_name, description, body):
    """Extract keywords/phrases that should trigger this skill.
    Focused: only description + section headers + command names. NOT full body."""
    triggers = set()

    stop_words = {'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
                   'have', 'has', 'had', 'do', 'does', 'did', 'will', 'shall', 'would',
                   'should', 'may', 'might', 'can', 'could', 'and', 'but', 'or', 'nor',
                   'not', 'so', 'yet', 'for', 'with', 'from', 'into', 'through', 'during',
                   'before', 'after', 'above', 'below', 'to', 'of', 'in', 'on', 'at', 'by',
                   'about', 'between', 'all', 'each', 'every', 'both', 'few', 'more', 'most',
                   'other', 'some', 'such', 'no', 'than', 'too', 'very', 'just', 'also',
                   'this', 'that', 'these', 'those', 'then', 'how', 'what', 'which', 'who',
                   'its', 'use', 'using', 'used', 'across', 'any', 'new', 'our', 'up',
                   'method', 'best', 'practices', 'comprehensive', 'full', 'based', 'specific',
                   'evaluate', 'covering', 'type', 'types', 'agents', 'gaia', 'corp-os',
                   'skill', 'system', 'tool', 'tools'}

    # 1. Skill name itself + parts
    triggers.add(skill_name.lower())
    for part in skill_name.split('-'):
        if len(part) > 2:
            triggers.add(part.lower())

    # 2. Keywords from description ONLY (not full body)
    if description:
        words = re.findall(r'[a-z][a-z-]+', description.lower())
        for w in words:
            if w not in stop_words and len(w) > 2:
                triggers.add(w)

    # 3. Extract from "When to use" sections only
    sections = re.findall(r'(?:when to use|triggers?)\s*\n[-=]*\n(.*?)(?:\n##|\n---|\Z)',
                          body, re.IGNORECASE | re.DOTALL)
    for section in sections:
        words = re.findall(r'[a-z][a-z-]+', section.lower())
        for w in words:
            if w not in stop_words and len(w) > 3:
                triggers.add(w)

    # 4. Extract command names from code blocks (top-level only)
    commands = re.findall(r'```(?:bash)?\s*\n\s*(?:bash\s+)?(\S+\.sh)', body)
    for cmd in commands:
        cmd_name = cmd.replace('.sh', '').split('/')[-1]
        if len(cmd_name) > 2:
            triggers.add(cmd_name.lower())

    return sorted(list(triggers))


def extract_capabilities(description, body):
    """Extract what this skill produces. Only use description to avoid over-matching."""
    caps = set()
    text = description.lower() if description else ""

    cap_keywords = {
        'image': 'images', 'photo': 'images', 'picture': 'images',
        'video': 'video', 'clip': 'video', 'animation': 'video',
        'caption': 'text', 'copy': 'text', 'copywriting': 'text', 'script': 'text',
        'brand': 'branding', 'dna': 'branding', 'identity': 'branding',
        'audit': 'analysis', 'review': 'analysis', 'score': 'analysis', 'analysis': 'analysis',
        'scrape': 'data', 'crawl': 'data', 'extract': 'data', 'spider': 'data',
        'campaign': 'strategy', 'plan': 'strategy', 'strategy': 'strategy',
        'code': 'code', 'build': 'code', 'deploy': 'code', 'ship': 'code',
        'publish': 'publishing', 'post': 'publishing', 'schedule': 'publishing',
        'knowledge': 'knowledge', 'learn': 'knowledge', 'digest': 'knowledge',
        'shopify': 'commerce', 'store': 'commerce', 'product': 'commerce',
        'reading': 'readings', 'qmdj': 'readings', 'psychic': 'readings',
        'character': 'characters', 'avatar': 'characters', 'face': 'characters',
        'workflow': 'automation', 'automat': 'automation', 'pipeline': 'automation',
    }
    for keyword, cap in cap_keywords.items():
        if keyword in text:
            caps.add(cap)

    return sorted(list(caps))


def extract_cli_command(skill_name, skill_dir):
    """Find the primary CLI script."""
    scripts_dir = os.path.join(skill_dir, "scripts")
    if not os.path.isdir(scripts_dir):
        return ""

    # Look for scripts matching skill name first
    candidates = []
    for f in sorted(os.listdir(scripts_dir)):
        if f.endswith('.sh') or f.endswith('.py'):
            if not f.endswith('.bak') and not f.startswith('.') and '__pycache__' not in f:
                candidates.append(f)

    if not candidates:
        return ""

    # Prefer script matching skill name exactly
    for c in candidates:
        base = c.replace('.sh', '').replace('.py', '')
        if base == skill_name or base.replace('-', '') == skill_name.replace('-', ''):
            return f"~/.openclaw/skills/{skill_name}/scripts/{c}"

    # Next: prefer the most "main-looking" script (not helpers like install-deps, audit, etc)
    helpers = {'install-deps', 'install', 'setup', 'test', 'README'}
    main_candidates = [c for c in candidates if c.replace('.sh','').replace('.py','') not in helpers]
    if main_candidates:
        return f"~/.openclaw/skills/{skill_name}/scripts/{main_candidates[0]}"

    return f"~/.openclaw/skills/{skill_name}/scripts/{candidates[0]}"


def extract_example_usage(skill_name, body, cli_command):
    """Extract a one-line example of how to trigger the skill."""
    # Look for code blocks with actual invocation examples
    code_blocks = re.findall(r'```(?:bash)?\s*\n(.*?)```', body, re.DOTALL)
    for block in code_blocks:
        lines = block.strip().split('\n')
        for line in lines:
            line = line.strip().lstrip('$ ')
            if not line or line.startswith('#'):
                continue
            # Must look like a command (has .sh or skill name or starts with bash/python3)
            if '.sh' in line or skill_name in line or line.startswith(('bash ', 'python3 ')):
                if len(line) < 120:
                    return line

    # Fallback: construct from cli_command
    if cli_command:
        cmd_base = cli_command.split('/')[-1]
        return f"bash {cli_command} --help"

    return f"# Skill: {skill_name} (reference docs only, no CLI)"


def check_active(skill_dir):
    """A skill is active if it has SKILL.md and at least one script or substantial docs."""
    has_skill_md = os.path.isfile(os.path.join(skill_dir, "SKILL.md"))
    scripts_dir = os.path.join(skill_dir, "scripts")
    has_scripts = os.path.isdir(scripts_dir) and any(
        f.endswith(('.sh', '.py', '.ts')) and not f.endswith('.bak')
        for f in os.listdir(scripts_dir) if not f.startswith('.')
    )
    # Even without scripts, skill can be active if SKILL.md has substance (>500 chars)
    if has_skill_md and not has_scripts:
        try:
            size = os.path.getsize(os.path.join(skill_dir, "SKILL.md"))
            return size > 500
        except:
            return False
    return has_skill_md


# --- Main ---
skills = {}
skill_md_paths = []

for entry in sorted(os.listdir(SKILLS_DIR)):
    skill_dir = os.path.join(SKILLS_DIR, entry)
    if not os.path.isdir(skill_dir) or entry == '_archive':
        continue
    skill_md = os.path.join(skill_dir, "SKILL.md")
    if os.path.isfile(skill_md):
        skill_md_paths.append((entry, skill_dir, skill_md))

for skill_name, skill_dir, skill_md in skill_md_paths:
    fm, body = parse_frontmatter(skill_md)
    description = fm.get('description', '')
    if isinstance(description, list):
        description = ' '.join(description)
    # If no frontmatter description, use first paragraph
    if not description:
        lines = body.strip().split('\n')
        for line in lines:
            line = line.strip()
            if line and not line.startswith('#') and not line.startswith('-') and not line.startswith('|'):
                description = line
                break

    agents = extract_agents(fm, body)
    # Default agents if none found: main (all skills accessible to router)
    if not agents:
        agents = ["main"]

    trigger_patterns = extract_trigger_patterns(skill_name, description, body)
    capabilities = extract_capabilities(description, body)
    cli_command = extract_cli_command(skill_name, skill_dir)
    example_usage = extract_example_usage(skill_name, body, cli_command)
    active = check_active(skill_dir)
    category = get_category(skill_name)

    skills[skill_name] = {
        "name": skill_name,
        "description": description[:200] if description else "",
        "category": category,
        "trigger_patterns": trigger_patterns,
        "agents": agents,
        "capabilities": capabilities,
        "cli_command": cli_command,
        "example_usage": example_usage,
        "active": active,
        "path": f"~/.openclaw/skills/{skill_name}"
    }

# Build registry
registry = {
    "version": "2.0",
    "updated_at": datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    "total_skills": len(skills),
    "active_skills": sum(1 for s in skills.values() if s["active"]),
    "categories": sorted(list(set(s["category"] for s in skills.values()))),
    "skills": skills
}

if STATS_ONLY:
    print(f"Total skills scanned: {len(skills)}")
    print(f"Active skills: {registry['active_skills']}")
    cats = {}
    for s in skills.values():
        cats[s['category']] = cats.get(s['category'], 0) + 1
    for cat in sorted(cats.keys()):
        print(f"  {cat}: {cats[cat]}")
    print(f"Skills with CLI commands: {sum(1 for s in skills.values() if s['cli_command'])}")
    print(f"Skills with triggers: {sum(1 for s in skills.values() if s['trigger_patterns'])}")
    sys.exit(0)

if DRY_RUN:
    print(json.dumps(registry, indent=2, ensure_ascii=False))
    print("\n(dry run -- not written to disk)")
    sys.exit(0)

with open(OUTPUT_FILE, 'w') as f:
    json.dump(registry, f, indent=2, ensure_ascii=False)

print(f"skill-registry.v2.json rebuilt with {len(skills)} skills ({registry['active_skills']} active).")
print(f"Written to: {OUTPUT_FILE}")
PYEOF
