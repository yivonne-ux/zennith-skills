---
name: Output organization convention
description: Universal folder structure for all brand outputs — where finals, scripts, and rejected work go. Apply to every generation session.
type: feedback
---

All brand outputs must follow this standard folder structure. NEVER dump outputs in /tmp/ — always save directly to the brand's output folder.

## Universal output folder structure

```
{brand-root}/{batch-name}/
├── finals/       ← approved outputs only (renamed descriptively)
├── scripts/      ← generation scripts (reproducible)
└── rejected/     ← earlier iterations, labeled with version + reason
```

## Brand-specific paths

### MIRRA
- Root: `/Users/yi-vonnehooi/Desktop/mirra-workflow/`
- Content categories: `cat{##}-{version}/` (e.g. cat04-v7/)
- Ad campaigns: `{campaign-name}-v{#}/` (e.g. cn-ads-v4/)
- Seasonal/one-off: `{event}-{monthYYYY}/` (e.g. hariraya-march2026/)
- Approved finals go in `finals/` subfolder within each batch
- All ads final collection: `ALL-ADS-FINAL/`

### BLOOM & BARE
- Root: `/Users/yi-vonnehooi/Desktop/BRANDS/Bloom & Bare/`
- All outputs: `exports/{batch-name}/` (e.g. exports/ref-v4/)
- Rejected: `exports/rejected-v1/`
- Scripts: root level (bloom_*.py)

### PINXIN VEGAN
- Root: `/Users/yi-vonnehooi/Desktop/BRANDS/Pinxin Vegan/`
- All outputs: `exports/{batch-name}/` (e.g. exports/v16/)
- Scripts: root level (pinxin_*.py)

### OTHER BRANDS (yara, SEREIN, NEWMAN, etc.)
- Root: `/Users/yi-vonnehooi/Desktop/BRANDS/{brand-name}/`
- New output: `exports/{batch-name}/finals/`

## Naming convention for finals
- Use descriptive names, not version codes: `invitation-card.png` not `v5a6.png`
- Include format if multiple sizes: `invitation-card-1080x1350.png`
- Ads: keep template ID: `A01-hero-carousel.png`

## Rules
1. NEVER leave outputs in /tmp/ — always copy to brand folder immediately after generation
2. Raw NANO outputs go in rejected/ or are discarded — only post-processed finals in finals/
3. Scripts are always saved alongside outputs for reproducibility
4. Each batch folder is self-contained: finals + scripts + rejected

**Why:** User couldn't find outputs scattered across /tmp/. All work must be traceable and organized by brand.
**How to apply:** At the START of any generation task, create the output folder. Save directly there. At the END, organize finals vs rejected.
