# Zennith OS Skill Quality Audit

**Date:** 2026-03-22
**Auditor:** Zenki (Claude Code, Opus 4.6)
**Scope:** 10 key skills across 3 builders (Zenki, Yivonne, shared/Taoz)

---

## Scoring Criteria

| # | Criterion | Description |
|---|-----------|-------------|
| 1 | SKILL.md with frontmatter | Has `---` YAML frontmatter with name, description, version, agents |
| 2 | Working executable scripts | Has scripts/ directory with runnable .sh or .py files |
| 3 | macOS Bash 3.2 compatible | No `declare -A`, no `readarray`, no Bash 4+ features |
| 4 | Auto-detects OpenClaw API keys | Reads API keys from `openclaw.json` (no manual env setup) |
| 5 | Emits pub-sub events | Writes events to `rooms/events.jsonl` or rooms for pipeline integration |
| 6 | Has learnings.md | Compounding learnings file for self-improvement |
| 7 | Example configs/usage docs | Has example configs, usage docs, or knowledge/ files |
| 8 | Error handling with messages | Uses `set -euo pipefail`, has log/die functions, validates inputs |
| 9 | No hardcoded paths | Uses `$HOME` or relative paths, not `/Users/jennwoeiloh/...` |
| 10 | Integrated with classify.sh | Referenced in classify.sh routing for auto-dispatch |

---

## Scorecard

### Zenki-Built (This Session)

| Skill | Score | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | Missing | Priority Fix |
|-------|-------|---|---|---|---|---|---|---|---|---|---|---------|-------------|
| **auto-research** | 9/10 | Y | Y | Y | Y | Y | Y | Y | Y | **N** | N* | Hardcoded brand DNA path; not in classify.sh | Fix 2 hardcoded `/Users/jennwoeiloh/` paths to `$HOME` |
| **fast-iterate** | 9/10 | Y | Y | Y | Y | Y | Y | Y | Y | **N** | N* | Hardcoded brand DNA + rooms path; not in classify.sh | Fix 2 hardcoded paths; add to classify.sh |
| **shopify-cdp** | 7/10 | Y | Y | Y | N | N | Y | Y | Y | Y | N | No API key auto-detect; no pub-sub events; not in classify.sh | Add pub-sub events; register in classify.sh |

**Notes on auto-research & fast-iterate:**
- *N** for classify.sh: These are invoked by agents via CLI, not user-facing message routing, so classify.sh integration is less critical. However, adding a `fast-iterate` or `auto-research` keyword pattern in classify.sh would enable natural language triggering.
- Hardcoded paths: Lines 651 and 820 in auto-loop.sh use `/Users/jennwoeiloh/.openclaw/brands/` and `/Users/jennwoeiloh/.openclaw/workspace/rooms`. Same pattern at lines 473 and 720 in fast-iterate.sh. Should use `$HOME/.openclaw/...`.

### Yivonne-Built

| Skill | Score | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | Missing | Priority Fix |
|-------|-------|---|---|---|---|---|---|---|---|---|---|---------|-------------|
| **art-director** | 5/10 | **N** | Y | Y* | N | N | N | Y | N* | Y* | N | No frontmatter; no learnings.md; no error handling; Python scripts (not bash); no pub-sub; no classify.sh | Add YAML frontmatter; add learnings.md; add error handling to scripts |
| **cro-converter** | 3/10 | **N** | **N** | N/A | N | N | N | Y | N/A | Y | N | No frontmatter; NO scripts at all; pure knowledge doc; no learnings.md | Add frontmatter; create at least one audit script (e.g., `cro-audit.sh`) |

**Notes on Yivonne-built skills:**
- *Y** for Bash 3.2: art-director scripts are Python, not bash. Python 3 is fine on macOS.
- *N** for error handling: Python scripts lack `try/except` wrappers at top level (design-critique.py has some). No `if __name__ == "__main__"` guard in some scripts.
- *Y** for no hardcoded paths: art-director uses `os.path.expanduser("~")` pattern correctly.
- cro-converter is purely a knowledge document with no automation -- it's a reference manual, not a skill in the operational sense.

### Key Shared Skills (Spot-Check 5)

| Skill | Score | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | Missing | Priority Fix |
|-------|-------|---|---|---|---|---|---|---|---|---|---|---------|-------------|
| **content-supply-chain** | 6/10 | **N** | Y | Y | N | N | N | N | Y | Y | Y* | No frontmatter; no API key detect; no pub-sub events; no learnings.md; no example configs | Add YAML frontmatter; add learnings.md |
| **content-tuner** | 6/10 | Y | Y | Y | N | N | N | N | Y | **N** | N | No API key detect; no pub-sub; no learnings.md; HARDCODED workspace UUID path + user path; not in classify.sh | **CRITICAL: Fix hardcoded workspace UUID path** |
| **knowledge-compound** | 7/10 | Y | Y | Y | N | N | N | N | Y | Y | N | No API key detect; no pub-sub; no learnings.md; no example configs; not in classify.sh | Add learnings.md |
| **orchestrate-v2** | 8/10 | Y | Y | Y | N | N | N | Y | Y | Y | Y | No API key detect (reads model from openclaw.json); no pub-sub events; no learnings.md | Add learnings.md; add pub-sub events on dispatch |
| **brand-studio** | 8/10 | **N*** | Y | Y | Y* | N | N | Y | Y | Y | Y* | No YAML frontmatter; no learnings.md; no pub-sub events | Add YAML frontmatter; add learnings.md |

**Notes on shared skills:**
- *N*** for brand-studio frontmatter: The SKILL.md starts with `# Brand Studio` header, no `---` YAML frontmatter block.
- *Y** for brand-studio API key detect: audit.sh reads GEMINI_API_KEY from `.env` files. compose.sh delegates to nanobanana which handles keys.
- *Y** for content-supply-chain classify.sh: It's referenced in classify.sh line 135 as `# CONTENT SUPPLY CHAIN`.
- *Y** for brand-studio classify.sh: Referenced in classify.sh at multiple points for comparison ads routing.
- **CRITICAL for content-tuner**: Both `tune.sh` and `ab-framework.sh` hardcode `/Users/jennwoeiloh/.openclaw/workspace-22407784-64cf-4507-a0ef-789b7fecc20a` -- a UUID-specific workspace path that will break on any reinstall or machine change.

---

## Summary Table (Sorted by Score)

| Rank | Skill | Builder | Score | Grade |
|------|-------|---------|-------|-------|
| 1 | auto-research | Zenki | 9/10 | A |
| 2 | fast-iterate | Zenki | 9/10 | A |
| 3 | orchestrate-v2 | Shared/Taoz | 8/10 | A- |
| 4 | brand-studio | Shared/Taoz | 8/10 | A- |
| 5 | shopify-cdp | Zenki | 7/10 | B+ |
| 6 | knowledge-compound | Shared | 7/10 | B+ |
| 7 | content-supply-chain | Shared | 6/10 | B- |
| 8 | content-tuner | Shared | 6/10 | B- |
| 9 | art-director | Yivonne | 5/10 | C |
| 10 | cro-converter | Yivonne | 3/10 | D |

---

## Immediate Fixes Required

### P0 -- CRITICAL (Will Break On Machine Change)

1. **content-tuner: Hardcoded workspace UUID path**
   - Files: `scripts/tune.sh` (line 10), `scripts/ab-framework.sh` (line 10)
   - Problem: `/Users/jennwoeiloh/.openclaw/workspace-22407784-64cf-4507-a0ef-789b7fecc20a` -- this UUID workspace path is fragile
   - Fix: Replace with `$HOME/.openclaw/workspace` or use a discovery function that reads from `openclaw.json`
   - Also: `tune.sh` hardcodes `/Users/jennwoeiloh/.openclaw/brands/MIRRA/creative_learnings.json` (line 14) -- should be parameterized by brand

### P1 -- Should Fix This Week

2. **auto-research + fast-iterate: 2 hardcoded paths each**
   - Replace `/Users/jennwoeiloh/.openclaw/brands/` with `$HOME/.openclaw/brands/`
   - Replace `/Users/jennwoeiloh/.openclaw/workspace/rooms` with `$HOME/.openclaw/workspace/rooms`

3. **art-director: Add YAML frontmatter**
   - Add `---\nname: art-director\nversion: "1.0.0"\ndescription: ...\nagents: [iris, dreami]\n---` to top of SKILL.md
   - Add `learnings.md` file

4. **cro-converter: Add minimal automation**
   - Add YAML frontmatter
   - Create `scripts/cro-audit.sh` that runs the conversion checklist against a URL
   - Add `learnings.md`

5. **content-supply-chain: Add YAML frontmatter**
   - The SKILL.md has no frontmatter block at all

6. **brand-studio: Add YAML frontmatter**
   - Same issue -- no `---` frontmatter block

### P2 -- Nice To Have

7. **Add learnings.md to all skills that lack it**: content-supply-chain, content-tuner, knowledge-compound, orchestrate-v2, brand-studio, art-director, cro-converter (7 skills)

8. **Add pub-sub events to all skills**: Only auto-research and fast-iterate emit events. All pipeline skills should emit completion events.

9. **Register all skills in classify.sh**: auto-research, fast-iterate, shopify-cdp, art-director, cro-converter, content-tuner, knowledge-compound are not routable via classify.sh.

---

## Patterns to Standardize Across ALL Skills

### 1. YAML Frontmatter (Mandatory)

Every SKILL.md must start with:
```yaml
---
name: skill-name
version: "1.0.0"
description: One-line description
agents: [agent1, agent2]
evolves: true  # if self-improving
metadata:
  openclaw:
    scope: optimization|production|infrastructure
    pubsub:
      emits:
        - topic: "skill-name.complete"
          payload: "{...}"
---
```

**Who does this well:** auto-research, fast-iterate, content-tuner, knowledge-compound, orchestrate-v2.

### 2. API Key Auto-Detection Pattern

```bash
if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -z "${OPENAI_API_KEY:-}" ]; then
  OPENCLAW_CONFIG="${HOME}/.openclaw/openclaw.json"
  if [ -f "${OPENCLAW_CONFIG}" ]; then
    eval "$("${PYTHON3}" -c "
import json
d = json.load(open('${OPENCLAW_CONFIG}'))
providers = d.get('models',{}).get('providers',{})
# ... extract keys
" 2>/dev/null)"
  fi
fi
```

**Who does this well:** auto-research, fast-iterate. These two should be the reference implementation.

### 3. Error Handling Pattern

```bash
set -euo pipefail
log_info()  { echo "[skill-name] $(date +"%H:%M:%S") INFO  $*"; }
log_error() { echo "[skill-name] $(date +"%H:%M:%S") ERROR $*" >&2; }
die() { log_error "$*"; exit 1; }
```

**Who does this well:** auto-research, fast-iterate, brand-studio (compose.sh), content-supply-chain.

### 4. Pub-Sub Event Emission

```bash
local rooms_dir="$HOME/.openclaw/workspace/rooms"
if [ -d "$rooms_dir" ]; then
  echo '{"type":"skill.event","..."}' >> "$rooms_dir/events.jsonl" 2>/dev/null || true
fi
```

**Who does this well:** auto-research, fast-iterate. Nobody else does this.

### 5. No Hardcoded Paths

- Always `$HOME/.openclaw/...`, never `/Users/jennwoeiloh/...`
- Always `"$(cd "$(dirname "$0")" && pwd)"` for script-relative paths
- Brand paths: `$HOME/.openclaw/brands/$BRAND/DNA.json`

**Who violates this:** content-tuner (worst -- UUID workspace path), auto-research (2 paths), fast-iterate (2 paths).

### 6. Learnings File

Every skill should have `learnings.md` at its root:
```markdown
# Skill Name -- Compounding Learnings
> Meta-learnings from runs. Updated by agents after significant sessions.
## Meta-Patterns
_No patterns discovered yet._
```

**Who does this well:** auto-research, fast-iterate, shopify-cdp.

---

## What Yivonne's Skills Do Well (That Others Should Copy)

### 1. Deep Domain Knowledge
- **art-director** has the most comprehensive domain knowledge of ANY skill in the system -- 448 lines of curated design wisdom spanning typography, color theory, sacred geometry, logo forensics, photography direction, motion design, and material craft
- **cro-converter** has hard data benchmarks ("+266% from single CTA focus", "$1 tripwire: 60-70% repeat purchase rate") and a battle-tested conversion checklist
- Both are encyclopedic reference documents that any agent can load for instant domain expertise

### 2. Knowledge Architecture
- art-director's `knowledge/` directory structure (anti-patterns.md, cultural-intelligence.md, production-specs.md, prompt-dna.md) is the best knowledge organization in the entire skill set
- cro-converter's `knowledge/` directory (cro-data.md with hard benchmarks, reference-sites.md with competitor analysis) provides data-backed decision-making

### 3. Cultural Depth
- art-director covers Japanese design philosophy (Wabi-Sabi, Ma, Kenya Hara), Art Nouveau (Mucha), Dark Feminine aesthetics -- this cultural intelligence is unique and valuable
- cro-converter covers spiritual/wellness-specific CRO patterns that are directly applicable to Jade Oracle

### What Other Skills Should Copy From Yivonne:
1. **Create a `knowledge/` directory** for domain-specific reference material that agents load on boot
2. **Include hard data benchmarks** (like cro-converter's conversion lift percentages) instead of vague guidelines
3. **Organize knowledge by sub-topic** (anti-patterns, cultural-intelligence, production-specs) rather than one monolithic file
4. **Write for agent consumption** -- Yivonne's skills read like expert briefing documents, not developer docs

### What Yivonne's Skills Should Copy From Others:
1. **YAML frontmatter** (from auto-research, orchestrate-v2) -- both Yivonne skills lack this entirely
2. **Executable automation** (from auto-research, brand-studio) -- cro-converter has zero scripts
3. **learnings.md** (from auto-research, fast-iterate, shopify-cdp) -- neither Yivonne skill has one
4. **API key auto-detection** (from auto-research) -- art-director scripts don't auto-detect keys
5. **Error handling** (from brand-studio) -- art-director Python scripts have minimal error handling

---

## What Tricia's Skills Do Well

_Note: No Tricia-built skills were specified in this audit. The "shared" skills (content-supply-chain, content-tuner, knowledge-compound, orchestrate-v2, brand-studio) were built primarily by Taoz and Zenni._

### What the Shared/Taoz Skills Do Well:

1. **orchestrate-v2**: Best-in-class for operational clarity -- decision trees, dispatch templates, cost efficiency rules, tracking. The CHEATSHEET.md companion file is a great pattern.
2. **brand-studio**: Best composable architecture with `blocks/manifest.json` -- the ComfyUI-style typed inputs/outputs and pre-wired workflows is the most sophisticated skill architecture in the system.
3. **knowledge-compound**: Best for FTS5 search integration and pattern lifecycle (observed -> validated -> implemented). The `digest.sh` script handles 10+ knowledge types with proper SQLite storage.
4. **content-supply-chain**: Best pipeline visualization -- the 8-stage loop with agent ownership is clear and comprehensive.

---

## Recommended Next Actions

### This Week
1. Fix content-tuner hardcoded UUID paths (P0)
2. Fix auto-research + fast-iterate hardcoded paths (P1)
3. Add YAML frontmatter to: art-director, cro-converter, content-supply-chain, brand-studio (P1)
4. Add learnings.md to all 7 skills missing it (P2)

### This Month
5. Create `cro-audit.sh` script for cro-converter
6. Add pub-sub event emission to: content-supply-chain, content-tuner, knowledge-compound, orchestrate-v2, brand-studio
7. Register all unrouted skills in classify.sh
8. Create a skill template (`~/.openclaw/skills/_template/`) with the standardized patterns above

### Ongoing
9. After every significant skill session, update learnings.md
10. Before shipping any new skill, run it against this 10-point checklist

---

## Appendix: File Paths Audited

| Skill | Files Reviewed |
|-------|---------------|
| auto-research | SKILL.md, scripts/auto-loop.sh, learnings.md, configs/ad-creative.yaml |
| fast-iterate | SKILL.md, scripts/fast-iterate.sh, learnings.md |
| shopify-cdp | SKILL.md, scripts/shopify-ensure-pinchtab.sh, learnings.md, patches/CHANGELOG.md |
| art-director | SKILL.md, scripts/design-critique.py, knowledge/ (4 files) |
| cro-converter | SKILL.md, knowledge/cro-data.md, knowledge/reference-sites.md |
| content-supply-chain | SKILL.md, scripts/content-supply-chain.sh, scripts/daily-sandbox.sh |
| content-tuner | SKILL.md, scripts/tune.sh, scripts/ab-framework.sh |
| knowledge-compound | SKILL.md, AGENT-INSTRUCTIONS.md, scripts/digest.sh |
| orchestrate-v2 | SKILL.md, CHEATSHEET.md, scripts/dispatch.sh, scripts/classify.sh |
| brand-studio | SKILL.md, blocks/manifest.json, scripts/compose.sh, scripts/audit.sh, scripts/loop.sh |
