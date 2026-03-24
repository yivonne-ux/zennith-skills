---
name: Output routing — ALL outputs go to _WORK/[brand]/06_exports/
description: Consolidated output routing rules. Every brand, every output type, every session. No /tmp, no Desktop root, no random folders. Read OUTPUT-ROUTING-RULES.md for full spec.
type: feedback
---

## Output Routing (2026-03-22)

**Why:** Files were scattered across BRANDS/, mirra-workflow/, /tmp/, Desktop root, video-compiler/, etc. Took a full day to consolidate. Never again.

**How to apply:**

Every output → `~/Desktop/_WORK/[brand]/06_exports/[type]/`

| Output | Path |
|---|---|
| New ad images | `_WORK/[brand]/06_exports/campaigns/[name]/` |
| Approved | `_WORK/[brand]/06_exports/finals/static/` |
| Rejected | `_WORK/[brand]/06_exports/rejected/` |
| Video | `_WORK/[brand]/06_exports/finals/video/` |
| Scripts | `_WORK/[brand]/05_scripts/` |
| Strategy | `_WORK/[brand]/02_strategy/` |
| Research | `_WORK/[brand]/03_research/` |
| Scratch | `_WORK/[brand]/07_working/YYYY-MM-DD/` |

**NEVER:** /tmp/, Desktop root, new random folders, inside 01_assets/

**Brand paths:**
- pinxin: `~/Desktop/_WORK/pinxin/`
- mirra: `~/Desktop/_WORK/mirra/`
- bloom-bare: `~/Desktop/_WORK/bloom-bare/`
- jade-oracle: `~/Desktop/_WORK/jade-oracle/`
- serein: `~/Desktop/_WORK/serein/`
- Shared tools: `~/Desktop/_WORK/_shared/`
- CI Module: `~/Desktop/_WORK/_shared/creative-intelligence/` (symlinked)

**Full spec:** `~/Desktop/_WORK/_shared/OUTPUT-ROUTING-RULES.md`
