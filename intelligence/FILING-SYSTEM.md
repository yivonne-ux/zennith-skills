# Universal Filing System
## Where EVERYTHING goes. For ALL agents, ALL brands, ALL collaborators.
## Version 1.0 | 2026-03-30

---

## RULE #1: EVERY FILE HAS ONE HOME

Before saving ANY file, ask: **"What TYPE is this, and which BRAND does it serve?"**

If it serves ALL brands → `_WORK/_shared/`
If it serves ONE brand → `_WORK/[brand]/[numbered-folder]/`

---

## FILE TYPE → DESTINATION MAP

### STRATEGY & PLANNING DOCS (.md)

| File Type | Where It Goes | Examples |
|-----------|--------------|---------|
| **Brand DNA** (voice, palette, audience, values) | `00_brand-guide/BRAND-DNA.md` | Mirra sparkle glamour, PX heritage Chinese |
| **Content taxonomy** (categories, funnel mapping) | `02_strategy/CONTENT-TAXONOMY.md` | CAT-01 to CAT-12, TOFU/MOFU/BOFU |
| **Copy rules** (voice, banned words, language) | `02_strategy/COPY-DOCTRINE.md` | No exclamation marks, first-person, etc. |
| **Ads strategy** (campaigns, targeting, budget) | `02_strategy/META-ADS-STRATEGY.md` | Campaign architecture, bid strategy |
| **Social strategy** (posting cadence, engagement) | `02_strategy/SOCIAL-STRATEGY.md` | 3/day schedule, grid rhythm |
| **Campaign plan** (specific dates, budget, creative) | `02_strategy/CAMPAIGN-[name].md` | MARCH-APRIL-CAMPAIGN-V2.md |
| **Approved copy** (all copy variations) | `02_strategy/CAMPAIGN-COPY-ALL.md` | 50 numbered copy variations |
| **Content calendar** (what posts when) | `02_strategy/content-calendar/` | Weekly plans, 42-post schedules |
| **Video brief** (video production specs) | `02_strategy/VIDEO-BRIEF.md` | Tricia's video automation specs |
| **Pricing** (current prices, bundles) | `02_strategy/PRICING.md` | RM19/meal, combos |
| **Production rules** (how to generate content) | `02_strategy/PRODUCTION-INTELLIGENCE.md` | NANO settings, color rules |
| **Compound ledger** (win/loss record) | `02_strategy/COMPOUND-LEDGER.md` | Every yes/no, campaign IDs, spend |

### RESEARCH DOCS (.md)

| File Type | Where It Goes | Examples |
|-----------|--------------|---------|
| **Brand-specific research** (competitors, audience) | `03_research/` | COMPETITOR-INTEL.md, AUDIENCE-MAP.md |
| **Universal Meta research** (algorithm, API, benchmarks) | `_shared/03_research/meta-ads/` | Andromeda, CAPI guide, bidding research |
| **Universal design research** (trends, techniques) | `_shared/03_research/design/` | PIL techniques, design trends 2026 |
| **Universal creative research** (AI automation, workflows) | `_shared/03_research/creative-automation/` | Multi-agent, creative workflow |
| **Viral content research** (brand-specific niche) | `03_research/VIRAL-[topic].md` | Viral girl content, viral quotes |
| **Market intelligence** (brand-specific market) | `03_research/MARKET-INTEL.md` | Malaysia pulse, HK supplement market |

**Decision rule:** If 2+ brands would use this research → `_shared/`. If only 1 brand → that brand's `03_research/`.

### REFERENCE IMAGES

| File Type | Where It Goes | How to Use |
|-----------|--------------|-----------|
| **FORMAT ref** (layout template) | `04_references/FORMAT/[name]/` | Describe in TEXT prompt. Never as Image 1. |
| **AESTHETIC ref** (art style, color mood) | `04_references/AESTHETIC/[name]/` | Pass as Image 1 to NANO. |
| **CONTENT ref** (text/quotes to copy) | `04_references/CONTENT/[name]/` | Extract words, put in prompt. |
| **FOOD ref** (real food photo) | `04_references/FOOD/` or `01_assets/photos/` | Pass as Image 2+. Never modify. |
| **Ad library ref** (competitive intel) | `04_references/ads-library/` | Study format, never copy directly. |
| **Proven ref** (own winning posts) | `04_references/proven/` | Use as style anchor. |

**Brand-specific layers** (add folder only when needed):
- `pinterest/` — Pinterest-sourced refs
- `ig-refs/` — Instagram scraped
- `xhs-refs/` — XHS/RED (Chinese market)
- `video-refs/` — Video production refs
- `product-refs/` — Product photography
- `photography-mood/` — Mood/color direction

### SCRIPTS & CODE

| File Type | Where It Goes | Examples |
|-----------|--------------|---------|
| **Active production script** | `05_scripts/[name].py` | px_cron_publish.py, produce_social_42.py |
| **Data files** (JSON, CSV, TSV) | `05_scripts/data/` | adset_ids.json, sales_export.csv |
| **Utility/helper** | `05_scripts/utils/` | smart_logo.py, meta_token.py |
| **Old/superseded script** | `07_working/_archived_scripts/` | v1-v4 when v5 exists |
| **Universal automation** | `_shared/creative-intelligence/autoads/` | autoads_report.py |

### EXPORTS & OUTPUTS

| File Type | Where It Goes | Examples |
|-----------|--------------|---------|
| **Social media posts** (production) | `06_exports/social/week-YYYY-MM-DD/` | PXW-01.png + pending_posts.json |
| **Ad campaign creatives** | `06_exports/campaigns/[campaign-name]/` | march_ads_finals/ |
| **Video exports** | `06_exports/video/` | Reels, stories |
| **Rejected output** | Log in `06_exports/_REJECTION-LOG.md` then DELETE file | Never keep rejected images |

### ASSETS (Raw Brand Materials)

| File Type | Where It Goes | Examples |
|-----------|--------------|---------|
| **Logos** | `01_assets/logos/` | Full, mark, wordmark variants |
| **Fonts** | `01_assets/fonts/` | Brand typefaces |
| **Product photos** | `01_assets/product-photos/` or `photos/` | Real product shots |
| **Food photos** (real) | `01_assets/photos/food-library/` | Bento, dishes, ingredients |
| **Mascot/character files** | `01_assets/mascots/` or `characters/` | All pose/expression variants |
| **Testimonials** | `01_assets/testimonials/` | Customer photos, screenshots |
| **Frequently used cache** | `01_assets/local-cache/` | Logo marks, cutouts |

---

## NAMING CONVENTIONS

### Files
```
[BRAND]-[TYPE]-[DESCRIPTION].md     → MIRRA-ADS-STRATEGY.md
[TYPE]-[DESCRIPTION]-[YEAR].md      → META-ADS-INTELLIGENCE-2026.md
[action]_[target]_[version].py      → px_wisdom_v5_production.py
[BRAND]-[ID]-[name].png             → PXW-01-stupid-behavior.png
```

### Folders
```
lowercase-with-hyphens/              → korean-webtoon/, sparkle-glamour/
NO version suffixes in folder names   → curated/ NOT curated-v2/
NO spaces in folder names             → food-library/ NOT food library/
NO uppercase unless TYPE folder        → FORMAT/, AESTHETIC/, CONTENT/
```

### Versioning
```
Keep ONLY the latest version in 05_scripts/
Archive old versions to 07_working/_archived_scripts/
NEVER: v1.py + v2.py + v3.py + v4.py in same folder
ALWAYS: v4.py active, v1-v3 archived
```

---

## WHEN NEW FILES ARRIVE — DECISION TREE

```
NEW FILE ARRIVES
    │
    ├─ Is it UNIVERSAL (2+ brands would use it)?
    │   YES → _shared/[appropriate-folder]/
    │   NO  ↓
    │
    ├─ Is it a STRATEGY doc?
    │   YES → [brand]/02_strategy/
    │         (check: does it replace an existing doc? Archive the old one)
    │   NO  ↓
    │
    ├─ Is it a REFERENCE IMAGE?
    │   YES → [brand]/04_references/[FORMAT|AESTHETIC|CONTENT|FOOD]/[subfolder]/
    │         (classify BEFORE saving: what PURPOSE does this ref serve?)
    │   NO  ↓
    │
    ├─ Is it a PRODUCTION OUTPUT?
    │   YES → [brand]/06_exports/[social|campaigns|video]/
    │         (if rejected: log reason in _REJECTION-LOG.md, then DELETE file)
    │   NO  ↓
    │
    ├─ Is it a SCRIPT?
    │   YES → [brand]/05_scripts/
    │         (if it replaces an older version: archive old to 07_working/_archived_scripts/)
    │   NO  ↓
    │
    ├─ Is it a RAW ASSET (logo, font, photo)?
    │   YES → [brand]/01_assets/[appropriate-subfolder]/
    │   NO  ↓
    │
    ├─ Is it RESEARCH?
    │   YES → Is it brand-specific? → [brand]/03_research/
    │         Is it universal?      → _shared/03_research/[topic]/
    │   NO  ↓
    │
    └─ Is it TEMPORARY/WORKING?
        YES → [brand]/07_working/
        (clean up when done — don't let files rot here)
```

---

## REJECTION LEARNING LOOP (for outputs)

Every rejected output follows this EXACT sequence:

```
1. CAPTURE → Write in 06_exports/_REJECTION-LOG.md:
   - Date, filename, rejection reason, which layer failed

2. CLASSIFY → What type of failure?
   ART_STYLE | CHARACTER | COLOR | FOOD | TEXT | LAYOUT | VEGAN | BRAND_FIT | AGE

3. EXTRACT → Create or update a rule:
   → feedback_[brand]_[topic].md in memory
   → Or update existing compound ledger

4. DELETE → Remove the rejected file from disk
   (Learning persists in memory. File doesn't persist on disk.)

5. VERIFY → Next generation checks against the new rule
   (Production pipeline reads rejection rules BEFORE generating)
```

---

## PERIODIC HYGIENE (run monthly or after every major batch)

```
□ Empty placeholder folders?          → DELETE them
□ Old version iterations (v1-v4)?     → ARCHIVE to 07_working/
□ Broken symlinks?                    → DELETE them
□ Files at brand root (outside 00-07)? → MOVE to correct numbered folder
□ Data files in 02_strategy?          → MOVE to 05_scripts/data/
□ Universal research in brand folder? → MOVE to _shared/
□ Duplicate folders in 04_references? → MERGE, keep one
□ Rejected outputs still on disk?     → Log + DELETE
□ 07_working/ growing stale?          → Review, delete if >30 days old
```

---

## BRAND-SPECIFIC ADDITIONS

Each brand can ADD to this system but never SUBTRACT from it.

| Brand | Additional Layers | Why |
|-------|-------------------|-----|
| **Mirra** | `04_references/ads-library/` (17 ad types) | Running Meta ads at scale |
| **Pinxin** | `04_references/FORMAT/` `AESTHETIC/` `CONTENT/` + CHARACTER layer | Illustrated character IP |
| **DotDot** | `04_references/xhs-refs/` + `product-refs/` | XHS platform + supplement products |
| **BB** | `01_assets/mascots/` (6 characters × 4 resolutions) | Mascot-heavy brand |

New brands onboarding: follow `BRAND-ONBOARDING-STANDARD.md` first, then add layers as needed.

---

## FOR AI AGENTS / COLLABORATORS

When you start a session on ANY brand:

1. **READ** `_WORK/_shared/FILING-SYSTEM.md` (this file)
2. **READ** `_WORK/_shared/BRAND-ONBOARDING-STANDARD.md` (folder structure)
3. **READ** `_WORK/[brand]/ENGINE.md` or `WORKFLOW.md` (session handoff)
4. **FOLLOW** the decision tree above for every new file you create
5. **NEVER** dump files at root level or in wrong folders
6. **ALWAYS** archive old versions when creating new ones
7. **ALWAYS** classify reference images before saving (FORMAT/AESTHETIC/CONTENT/FOOD)

---

*This system evolves. When a new pattern emerges, add it. When a rule breaks, fix it.*
*The goal: ANY agent, ANY collaborator can find ANY file in <5 seconds.*
