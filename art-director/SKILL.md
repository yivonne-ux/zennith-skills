---
name: art-director
description: Art direction system for Gaia/Pinxin. Uses brand libraries + references to produce Style DNA, prompt packs (NanoBanana + Midjourney), variants, and QA-guided iteration.
---

# art-director (v2)

This is a **creative process** skill, not just a prompt generator.

It distinguishes:
- **Brand Style Library** (stable identity: palette, fonts, tone, rules)
- **Campaign Style / Reference Set** (temporary vibe for a specific campaign)

## Brand library (where we store the truth)
Repo path: `brand-library/{brand}/...`
- `refs/` Pinterest links + anchor images
- `palettes/` hex + color words
- `typography/` font names + usage rules
- `ci/` logos, spacing rules, grids
- `copy/` tone, phrases, hooks
- `voice/` voice notes (e.g., Sze Wei Chinese voice, speed, manner)

If library is missing, start with `templates/brand-profile.template.md`.

---

## Creative process (what I do each time)

### 1) Research → scrape → reference
- If a website is provided: use `site-scraper` to pull key text + claims + FAQs.
- If Pinterest: use `pinterest-assistant` workflow (links/screenshots) to extract vibe.

### 2) Analyse (director-level)
- art style / brush / texture
- palette (primary/secondary/accent + banned)
- vibes, setting, tone
- composition + hierarchy
- silhouette readability
- positive/negative space for text
- foreground/mid/background separation
- highlight/shadow direction + contrast
- aspect ratio + safe margins

### 3) Adapt + repurpose
Generate a plan for:
- 1:1 WhatsApp
- 4:5 IG feed
- 9:16 Story/Reels
with consistent hierarchy and text legibility.

### 4) Generate
- NanoBanana prompt pack (base + 3 variants)
- Midjourney prompt pack (base + params)

### 5) QA rubric + iterate
Use `templates/qa-rubric.md`. Output:
- scores
- exactly what to change next (3 edits max)

---

## Inputs (minimum)
- Brand: Gaia / Pinxin (or new)
- Goal: what asset is for
- Format: ratios + platform
- Refs: links/screenshots
- Exact text to place (if any)
- Constraints: must include / avoid

## Outputs (standard)
1) Brand-fit **Style DNA**
2) Prompt packs (NanoBanana + Midjourney)
3) 3 controlled variants
4) QA scores + next iteration notes

## Notes
- Do not claim exact replication of any specific studio’s copyrighted style; aim for **similar vibe** with original compositions.
