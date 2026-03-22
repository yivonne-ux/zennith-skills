# Brand Skeleton — Universal Folder Template
> Every brand follows this EXACT structure. Run scaffold command for new brands.
> Source: Yivonne (Ops) — proven from Pinxin, Mirra, Bloom & Bare

## Scaffold Command
```bash
NEW_BRAND="brand-name"
BASE=~/Desktop/_WORK
mkdir -p "$BASE/$NEW_BRAND"/{00_brand-guide,01_assets/{logos,fonts,photos,cutouts,characters,textures,packaging},02_strategy/campaigns,03_research/{competitor,market,ads-intelligence,deep-research},04_references/{curated,format-specific,proven,user-input},05_scripts/utils,06_exports/{finals/{static,video,carousel},campaigns,rejected,archive},07_working}
echo "# $NEW_BRAND — Rejection Log" > "$BASE/$NEW_BRAND/06_exports/rejected/REJECTION-LOG.md"
echo "# $NEW_BRAND" > "$BASE/$NEW_BRAND/README.md"
```

## Folder Map
```
[brand]/
├── 00_brand-guide/     ← Identity (colors, fonts, voice, personas)
├── 01_assets/          ← Raw materials (logos, photos, cutouts, fonts)
├── 02_strategy/        ← Brain (content taxonomy, copy doctrine, campaigns)
├── 03_research/        ← Knowledge (competitor, market, ads intelligence)
├── 04_references/      ← Inspiration (curated mood refs, format refs, proven winners)
├── 05_scripts/         ← Code (production scripts, deploy scripts)
├── 06_exports/         ← Output pipeline
│   ├── finals/         ← ✅ Approved
│   ├── campaigns/      ← Campaign batches
│   ├── rejected/       ← ❌ Failed + REJECTION-LOG.md
│   └── archive/        ← 📦 Old work
└── 07_working/         ← Scratch (daily WIP)
```

## Output Rules
- New generations → `06_exports/campaigns/[campaign]/`
- Approved → `06_exports/finals/`
- Failed → `06_exports/rejected/` + update REJECTION-LOG.md
- NEVER save to /tmp/ or Desktop root
