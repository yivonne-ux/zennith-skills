---
name: CN ads v4 campaign — 24 variants complete
description: Chinese Meta ads campaign for Mirra. 24 variants (V01-V24) in cn-ads-v4/finals/. 4 fix rounds. NANO Banana Pro Edit pipeline. 25 hand-picked refs, 5 personas, 6 creative directions.
type: project
---

## CN Ads v4 Campaign Status (2026-03-13)

**Status:** v4 LOCKED. 24 variants in `cn-ads-v4/finals/`.
**Pipeline:** NANO Banana Pro Edit → resize 1080×1350 → place_logo(auto) → add_grain(0.016)

### Files
- `mirra_cn_ads_batch.py` — original 21 variants (V01-V21)
- `mirra_cn_ads_fix.py` — fix1: 9 variants (V03,V10,V13,V15-V18,V20,V21)
- `mirra_cn_ads_fix2.py` — fix2: 3 variants (V13,V15,V17)
- `mirra_cn_ads_fix3.py` — fix3: 6 fixes + 3 new (V02-V04,V09,V13,V15 + V22-V24)
- `mirra_cn_ads_fix4.py` — fix4: 3 variants (V03,V04,V13) — FINAL fixes
- Output: `cn-ads-v4/finals/` (24 PNGs), `cn-ads-v4/raws/`, `cn-ads-v4/references/`
- Refs: `cn-refs-approved/picked/` (25 hand-picked references)

### 24 Variants
V01-EditorialHero, V02-MinimalEditorial, V03-VarietyCascade, V04-WarmLifestyle,
V05-SocialProof, V06-BoldSplit, V07-NewspaperConcept, V08-CNYBoldType,
V09-FloatingReviews, V10-MassiveTypeHero, V11-BoldFoodHero, V12-ComboProduct,
V13-MenuCascade, V14-FlatLayVariety, V15-UGCMirrorSelfie, V16-GlowUpGrid,
V17-AirdropConcept, V18-TransformationSplit, V19-UsVsThem, V20-NewspaperHands,
V21-NarrativeFlyer, V22-PersonHoldingProduct, V23-FourPanelEmotion, V24-NarrativeNostalgia

### Known persistent issues (NANO limitations)
- NANO renders "MIRRA" text despite ban — unsolvable via prompting
- AI food ≠ real food — NANO reinterprets all food inputs
- AI humans in lifestyle scenes = obviously fake — removed from V04
- Duplicate text in review layouts (V09) — NANO ignores "all unique" instructions sometimes

**Why:** Chinese-speaking Malaysian women 25-35 Meta ad campaign. 5 personas (美容控, 加班OL, 午餐困难户, 忙碌妈妈, 精打细算). 6 creative directions (editorial_hero, bold_typography, social_proof, variety_cascade, concept, lifestyle). Pricing: 从RM19起.
