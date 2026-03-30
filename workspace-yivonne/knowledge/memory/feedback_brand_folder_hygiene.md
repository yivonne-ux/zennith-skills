---
name: Brand Folder Hygiene Rules
description: Universal rules for keeping brand folders clean. Rejection learning loop. Standard structure enforcement. All brands.
type: feedback
---

## Brand Folder Organization Rules (Learned 2026-03-30)

### Standard Structure (00-07)
Every brand MUST follow: 00_brand-guide, 01_assets, 02_strategy, 03_research, 04_references, 05_scripts, 06_exports, 07_working.
Standard doc: `_WORK/_shared/BRAND-ONBOARDING-STANDARD.md`

### Rejection Learning Loop
1. Rejected output → extract WHY → save as rule in memory
2. Log in `06_exports/_REJECTION-LOG.md`
3. DELETE the rejected file (learning persists, file doesn't)
4. Next generation checks against the new rule

### Folder Hygiene (run after every batch)
- Empty placeholder folders = DELETE immediately (don't create folders you won't use)
- Old version iterations (v1-v4 when v5 exists) = ARCHIVE to `_archive/` or `07_working/`
- Broken symlinks = DELETE
- Duplicate files (same content, different name) = KEEP canonical, DELETE rest
- Test/calibration folders = ARCHIVE after style is LOCKED
- Stale scripts (superseded by newer versions) = ARCHIVE to `07_working/_archived_scripts/`
- NEVER leave 90+ junk files alongside 12 production files

### Per-Brand Current State (2026-03-30)

| Brand | Size | Structure | Health |
|-------|------|-----------|--------|
| Mirra | 4.3G | 00-07 ✅ | BRAND-DNA.md created, testimonials consolidated, 25 empty folders deleted |
| Pinxin | 30G (97% GDrive) | 00-07 ✅ | Broken symlinks removed, stale scripts archived, refs deduplicated |
| DotDot | 206M | 00-07 ✅ (was broken, fixed) | Reorganized from broken numbering, v5-v10 archived, APPROVED-PROPOSAL is production |
| BB | 424M | 00-07 ✅ | v1-v16 iterations deleted, old campaigns cleaned, most polished structure |

### Security Notes
- Mirra has plaintext tokens in 05_scripts/.env, .meta_token_new, .page_token_new → ROTATE
- Pinxin has GDrive symlinks that break if cloud sync fails → document fallback

**How to apply:** Run folder hygiene check after every production batch. Check for empty folders, old iterations, broken symlinks. Apply rejection learning loop for every rejected output.
