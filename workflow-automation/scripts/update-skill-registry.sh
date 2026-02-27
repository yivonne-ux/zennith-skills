#!/usr/bin/env bash
# update-skill-registry.sh — Scan all skills and rebuild skill-registry.json
# Reads each SKILL.md frontmatter for agents, description, and capabilities.
# Bash 3.2 compatible (macOS). Uses python3 for YAML-like parsing and JSON.
#
# Usage:
#   bash update-skill-registry.sh              # full rebuild
#   bash update-skill-registry.sh --dry-run    # show what would change without writing
#   bash update-skill-registry.sh --diff       # show diff between current and new

set -euo pipefail

SKILLS_DIR="$HOME/.openclaw/skills"
DATA_DIR="$HOME/.openclaw/workspace/data"
SKILL_REGISTRY_FILE="$DATA_DIR/skill-registry.json"
OUTPUT_TYPES_FILE="$DATA_DIR/output-types.json"

DRY_RUN=0
SHOW_DIFF=0

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=1
            ;;
        --diff)
            SHOW_DIFF=1
            ;;
        --help|-h)
            echo "Usage: bash update-skill-registry.sh [--dry-run] [--diff]"
            echo ""
            echo "Scans all SKILL.md files and rebuilds skill-registry.json."
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be written without writing"
            echo "  --diff       Show diff between current and new registry"
            echo "  --help       Show this help"
            exit 0
            ;;
        *)
            echo "ERROR: Unknown option '$1'" >&2
            exit 1
            ;;
    esac
    shift
done

# Ensure data directory exists
mkdir -p "$DATA_DIR"

# Collect all SKILL.md paths (excluding _archive)
SKILL_MDS=""
for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name="$(basename "$skill_dir")"
    # Skip archive and dispatch.sh (it is a file, not a dir)
    if [ "$skill_name" = "_archive" ]; then
        continue
    fi
    skill_md="$skill_dir/SKILL.md"
    if [ -f "$skill_md" ]; then
        SKILL_MDS="$SKILL_MDS
$skill_md"
    fi
done

# Build the registry using python3
python3 -c "
import json, sys, os, re, datetime

skills_dir = os.path.expanduser('$SKILLS_DIR')
data_dir = os.path.expanduser('$DATA_DIR')
output_types_file = os.path.expanduser('$OUTPUT_TYPES_FILE')
registry_file = os.path.expanduser('$SKILL_REGISTRY_FILE')
dry_run = $DRY_RUN
show_diff = $SHOW_DIFF

# Parse SKILL.md frontmatter (YAML-like between --- markers)
def parse_frontmatter(filepath):
    result = {}
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return result

    # Find frontmatter between --- markers
    fm_match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
    if not fm_match:
        return result

    fm_text = fm_match.group(1)
    for line in fm_text.split('\n'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        # Simple key: value parsing
        m = re.match(r'^(\w[\w-]*)\s*:\s*(.+)', line)
        if m:
            key = m.group(1).strip()
            val = m.group(2).strip()
            # Remove surrounding quotes
            if (val.startswith('\"') and val.endswith('\"')) or (val.startswith(\"'\") and val.endswith(\"'\")):
                val = val[1:-1]
            # Parse arrays: [\"a\", \"b\"]
            if val.startswith('['):
                try:
                    val = json.loads(val.replace(\"'\", '\"'))
                except json.JSONDecodeError:
                    # Try simple comma split
                    inner = val.strip('[]')
                    val = [x.strip().strip('\"').strip(\"'\") for x in inner.split(',') if x.strip()]
            result[key] = val

    return result

# Parse body for agent mentions (## Who Uses This, agent assignments, etc.)
def extract_agents_from_body(filepath):
    agents = set()
    known_agents = {
        'zenni': 'main', 'artemis': 'artemis', 'dreami': 'dreami',
        'athena': 'athena', 'hermes': 'hermes', 'iris': 'iris',
        'taoz': 'taoz', 'myrmidons': 'myrmidons', 'bee001': 'bee001',
        'argus': 'argus',
        # Old names that may appear in older skills
        'apollo': 'dreami', 'artee': 'iris', 'daedalus': 'iris',
        'calliope': 'dreami'
    }
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read().lower()
    except Exception:
        return list(agents)

    for name, agent_id in known_agents.items():
        # Look for agent mentions like **Iris**, Iris (, - Iris, etc.
        patterns = [
            r'\*\*' + re.escape(name) + r'\*\*',
            r'- ' + re.escape(name) + r'[\s(]',
            r'\b' + re.escape(name) + r'\b.*(?:agent|director|builder|swarm|merchant|strategist|router|scout|researcher|tester|qa)',
        ]
        for pat in patterns:
            if re.search(pat, content):
                agents.add(agent_id)
                break

    return sorted(list(agents))

# Extract capabilities from description
def extract_capabilities(description):
    caps = []
    if not description:
        return caps
    desc_lower = description.lower()
    cap_keywords = {
        'image': 'image-generation',
        'video': 'video-processing',
        'caption': 'captioning',
        'brand': 'branding',
        'music': 'music-mixing',
        'effect': 'effects',
        'export': 'multi-platform-export',
        'scrape': 'web-scraping',
        'trend': 'trend-detection',
        'performance': 'performance-analysis',
        'optimization': 'optimization',
        'compress': 'compression',
        'character': 'character-design',
        'avatar': 'avatar-generation',
        'voice': 'voice-synthesis',
        'copy': 'copywriting',
        'formula': 'marketing-frameworks',
        'funnel': 'funnel-strategy',
        'review': 'quality-review',
        'seed': 'seed-management',
        'tuning': 'auto-tuning',
        'a/b': 'ab-testing',
        'campaign': 'campaign-management',
        'api': 'api-integration',
        'register': 'output-type-registration',
        'workflow': 'workflow-management',
    }
    for keyword, cap in cap_keywords.items():
        if keyword in desc_lower:
            caps.append(cap)
    return caps

# Read existing output types to map to skills
output_type_ids = []
try:
    with open(output_types_file, 'r') as f:
        ot_data = json.load(f)
        if isinstance(ot_data, list):
            for item in ot_data:
                if isinstance(item, dict) and 'id' in item:
                    output_type_ids.append(item['id'])
except Exception:
    pass

# Read existing registry to preserve manually set data
existing_registry = {}
try:
    with open(registry_file, 'r') as f:
        existing = json.load(f)
        if 'skills' in existing:
            existing_registry = existing['skills']
except Exception:
    pass

# Scan all skills
new_skills = {}
skill_md_lines = '''$(echo "$SKILL_MDS")'''.strip().split('\n')

for skill_md_path in skill_md_lines:
    skill_md_path = skill_md_path.strip()
    if not skill_md_path or not os.path.isfile(skill_md_path):
        continue

    skill_dir = os.path.dirname(skill_md_path)
    skill_name = os.path.basename(skill_dir)

    # Skip non-production skills
    if skill_name in ('_archive',):
        continue

    fm = parse_frontmatter(skill_md_path)
    body_agents = extract_agents_from_body(skill_md_path)

    # Get agents from frontmatter or body
    agents = fm.get('agents', [])
    if isinstance(agents, str):
        agents = [a.strip() for a in agents.split(',')]
    if not agents:
        agents = body_agents

    # Get description
    description = fm.get('description', '')

    # Get capabilities
    capabilities = extract_capabilities(description)

    # Preserve existing output_types and capabilities if they were manually curated
    existing_entry = existing_registry.get(skill_name, {})
    existing_output_types = existing_entry.get('output_types', [])
    existing_capabilities = existing_entry.get('capabilities', [])

    # Merge: keep existing if richer, otherwise use extracted
    if len(existing_capabilities) > len(capabilities):
        capabilities = existing_capabilities
    if len(existing_output_types) > 0:
        output_types = existing_output_types
    else:
        output_types = []

    new_skills[skill_name] = {
        'path': '~/.openclaw/skills/' + skill_name,
        'agents': agents if agents else [],
        'output_types': output_types,
        'capabilities': capabilities
    }

# Build final registry
registry = {
    'version': '1.0',
    'updated_at': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'skills': new_skills
}

if show_diff:
    # Show what changed
    old_skills = set(existing_registry.keys())
    new_skill_names = set(new_skills.keys())
    added = new_skill_names - old_skills
    removed = old_skills - new_skill_names
    updated = set()
    for s in old_skills & new_skill_names:
        if json.dumps(existing_registry.get(s, {}), sort_keys=True) != json.dumps(new_skills.get(s, {}), sort_keys=True):
            updated.add(s)

    print('=== Skill Registry Diff ===')
    print('Skills in new registry: {}'.format(len(new_skill_names)))
    print('Skills in old registry: {}'.format(len(old_skills)))
    if added:
        print('ADDED:   {}'.format(', '.join(sorted(added))))
    if removed:
        print('REMOVED: {}'.format(', '.join(sorted(removed))))
    if updated:
        print('UPDATED: {}'.format(', '.join(sorted(updated))))
    if not added and not removed and not updated:
        print('No changes detected.')
    sys.exit(0)

if dry_run:
    print(json.dumps(registry, indent=2, ensure_ascii=False))
    print('')
    print('(dry run -- not written to disk)')
    sys.exit(0)

# Write
with open(registry_file, 'w') as f:
    json.dump(registry, f, indent=2, ensure_ascii=False)

skill_count = len(new_skills)
print('skill-registry.json rebuilt with {} skills.'.format(skill_count))
print('Written to: {}'.format(registry_file))
"
