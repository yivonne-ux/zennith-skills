# Brand Onboarding Standard
## Universal folder structure + intelligence files for ALL brands
## Version 1.0 | 2026-03-30

---

## PURPOSE

Every brand managed by Zennith follows the SAME base structure. This ensures:
- Tricia, Jenn, and any collaborator can find files in predictable locations
- Claude Code / OpenClaw agents work across brands without per-brand config
- Campaign generation, creative production, and video automation use the same paths
- New brands onboard in minutes, not hours

---

## STANDARD FOLDER STRUCTURE (Numbered 00-07)

```
_WORK/[brand-slug]/
├── 00_brand-guide/          ← Brand DNA, guidelines, voice, identity
│   ├── BRAND-DNA.md         ← Character, voice, palette, typography, values
│   ├── BRAND-GUIDE.pdf      ← Visual identity (if exists)
│   └── COMPETITOR-ANALYSIS.md ← Key competitors + positioning
│
├── 01_assets/               ← Raw brand assets (logos, fonts, photos, video)
│   ├── logos/               ← All logo variants (full, mark, wordmark)
│   ├── logos-full/          ← Full lockup versions
│   ├── fonts/               ← Brand typefaces
│   ├── photos/              ← Product/food/lifestyle photos (REAL only)
│   ├── product-photos/      ← Hero product shots
│   ├── packaging/           ← Packaging photos (REAL only)
│   ├── textures/            ← Brand textures/patterns
│   ├── local-cache/         ← Frequently used assets (logo marks etc.)
│   └── gdrive-sync/         ← GDrive synced folder (if applicable)
│       └── brand-identity/  ← From client GDrive
│
├── 02_strategy/             ← Marketing, ads, content strategy docs
│   ├── CONTENT-TAXONOMY.md  ← Content categories + funnel mapping
│   ├── COPY-DOCTRINE.md     ← Writing rules, voice, banned words
│   ├── META-ADS-STRATEGY.md ← Campaign architecture, targeting, budget
│   ├── SOCIAL-STRATEGY.md   ← Posting cadence, platform rules, engagement
│   └── CAMPAIGN-COPY-ALL.md ← All approved copy variations
│
├── 03_research/             ← Market research, audience, competitive intel
│   ├── AUDIENCE-PERSONAS.md ← Customer segments + pain points
│   ├── MARKET-INTEL.md      ← Market size, trends, seasonality
│   └── VIRAL-RESEARCH.md    ← Viral format/content research
│
├── 04_references/           ← Visual/creative references
│   ├── curated/             ← Approved refs organized by sub-purpose
│   ├── proven/              ← Refs from posts that performed well
│   ├── format-specific/     ← Layout/format templates (describe in TEXT, not as Image 1)
│   ├── _LOCKED/             ← Verified, locked refs (never modify)
│   └── REFERENCE-INDEX.md   ← Master index (optional)
│   │
│   │   OPTIONAL LAYERS (add per brand need):
│   ├── ads-library/         ← If running Meta ads (scraped ad refs)
│   ├── pinterest/           ← If sourcing from Pinterest (group all pinterest here)
│   ├── ig-refs/             ← If sourcing from Instagram
│   ├── xhs-refs/            ← If targeting Chinese market
│   ├── video-refs/          ← If doing video production
│   ├── product-refs/        ← If product-focused brand
│   ├── photography-mood/    ← If brand has photo pipeline
│   ├── viral-formats/       ← If brand adapts viral content
│   └── user-input/          ← Human-provided direction images
│
├── 05_scripts/              ← Production + automation scripts
│   ├── px_cron_publish.py   ← Social media auto-publisher (brand-specific)
│   └── [brand]_*.py         ← Brand-specific production scripts
│
├── 06_exports/              ← ALL outputs go here
│   ├── social/              ← Social media posts (scheduled)
│   │   ├── week-YYYY-MM-DD/ ← Weekly batches
│   │   │   ├── pending_posts.json  ← Queue for cron publisher
│   │   │   └── *.png        ← Production images
│   │   └── _rejected/       ← TEMPORARY: rejected outputs (extract learnings, then delete)
│   ├── campaigns/           ← Ad campaign creatives
│   │   ├── [campaign-name]/ ← Per-campaign folder
│   │   └── _rejected/       ← Rejected ad creatives
│   └── video/               ← Video exports
│
└── 07_working/              ← Temporary working files (safe to delete)
```

---

## REQUIRED INTELLIGENCE FILES (Per Brand)

### Tier 1: MUST HAVE (create on onboarding)

| File | Location | Purpose |
|------|----------|---------|
| `BRAND-DNA.md` | `00_brand-guide/` | Character, voice, palette, typography, values, target audience |
| `CONTENT-TAXONOMY.md` | `02_strategy/` | Content categories mapped to funnel stages (TOFU/MOFU/BOFU) |
| `COPY-DOCTRINE.md` | `02_strategy/` | Writing rules, voice, tone, banned words, language mix |
| `COMPOUND-LEDGER.md` | `02_strategy/` | Running record of what worked, what failed, campaign IDs, spend |

### Tier 2: CREATE WHEN ADS GO LIVE

| File | Location | Purpose |
|------|----------|---------|
| `META-ADS-STRATEGY.md` | `02_strategy/` | Campaign architecture, targeting, budget, bid strategy |
| `CAMPAIGN-COPY-ALL.md` | `02_strategy/` | All approved copy variations (numbered) |
| `AUDIENCE-PERSONAS.md` | `03_research/` | Customer segments, pain points, language, behavior |
| `SOCIAL-STRATEGY.md` | `02_strategy/` | Posting cadence, platform rules, engagement tactics |

### Tier 3: CREATE AS NEEDED

| File | Location | Purpose |
|------|----------|---------|
| `COMPETITOR-ANALYSIS.md` | `00_brand-guide/` | Key competitors, positioning, ad library findings |
| `MARKET-INTEL.md` | `03_research/` | Market size, trends, seasonality, pricing |
| `VIRAL-RESEARCH.md` | `03_research/` | Viral format/content research for the niche |
| `PRODUCTION-INTELLIGENCE.md` | `02_strategy/` | Brand-specific production rules (NANO settings, color, refs) |

---

## BRAND-SPECIFIC LAYERING

The standard structure covers 90% of needs. Some brands need additional layers:

| Layer | When Needed | Additional Files/Folders |
|-------|-------------|-------------------------|
| **WhatsApp Commerce** | Brand sells via WA (Mirra, Pinxin) | `META-CAPI-CTWA-GUIDE.md`, offline conversion scripts |
| **XHS / RED** | Brand targets Chinese market (DotDot) | `04_references/xhs-refs/`, `XHS-STRATEGY.md` |
| **Video Production** | Brand needs video content | `06_exports/video/`, `VIDEO-BRIEF.md` |
| **Menu Pipeline** | Food brand with rotating menu | `MENU-PIPELINE.md`, CSP solver scripts |
| **Character IP** | Brand has illustrated character | Character ref sheets in `01_assets/`, illustration style lock docs |
| **Shopify** | Brand has Shopify store | Shopify integration scripts, product sync |
| **Multi-Language** | Brand serves EN+CN or TC+Cantonese | Language-specific copy files, translation pipeline |

---

## REJECTION LEARNING LOOP

When ANY output is rejected (by human review or audit gate):

```
1. CAPTURE: Save rejection reason
   → "Eyes too realistic" / "Wrong color palette" / "Food looks AI-generated"

2. CLASSIFY: What type of failure?
   → ART_STYLE / CHARACTER / COLOR / FOOD / TEXT / LAYOUT / VEGAN / BRAND_FIT

3. EXTRACT: What rule does this create?
   → "PX character eyes must be soft curves, never realistic iris/pupil"

4. SAVE: Add to brand's compound ledger + relevant memory file
   → feedback_[brand]_[topic].md

5. DELETE: Remove the rejected file from 06_exports/
   → Disk stays clean, system gets smarter

6. VERIFY: Next generation checks against the new rule
   → Rejection never repeats
```

### Anti-Pattern Registry (Per Brand)

Each brand maintains a `_REJECTION-LOG.md` in `06_exports/` that captures:
```markdown
## [Date] [Batch/Session]
- **File:** [filename]
- **Rejection reason:** [what was wrong]
- **Rule created:** [new rule to prevent this]
- **Memory updated:** [which feedback file]
- **Deleted:** YES
```

This log is READ by the production pipeline before generating new content. The rejected FILE is deleted. The LEARNING persists.

---

## ONBOARDING CHECKLIST (New Brand)

```
□ 1. Create folder: _WORK/[brand-slug]/
□ 2. Create numbered subfolders (00-07)
□ 3. Write BRAND-DNA.md (from client brief or research)
□ 4. Write CONTENT-TAXONOMY.md (content categories + funnel)
□ 5. Write COPY-DOCTRINE.md (voice, banned words, language)
□ 6. Create COMPOUND-LEDGER.md (empty, ready for learnings)
□ 7. Collect assets → 01_assets/ (logos, photos, fonts)
□ 8. Set up 04_references/ with curated refs
□ 9. Create memory files in ~/.claude/projects/*/memory/
     - project_[brand]_brand.md (brand summary)
     - feedback_[brand]_brand_specific_learnings.md (empty, ready)
□ 10. Add brand to MEMORY.md index
□ 11. Identify which layers this brand needs (WA, XHS, video, etc.)
□ 12. Create layer-specific files as needed
□ 13. Verify folder structure matches this standard
```

---

## SHARED SOURCE OF TRUTH (Tailscale)

### Architecture
```
┌─────────────────┐     Tailscale VPN     ┌─────────────────┐
│  Jenn's Mac      │◄───────────────────►│  Tricia's Mac    │
│  (Master Files)  │     100Mbps+         │  (Video Engine)  │
│                  │                       │                  │
│  ~/Desktop/      │     Shared via:       │  Accesses:       │
│  _WORK/          │     - Taildrop        │  - Brand assets  │
│  zennith-skills/ │     - SMB shares      │  - Strategy docs │
│                  │     - SSH             │  - Export folders │
└─────────────────┘                       └─────────────────┘
```

### Rules for Shared Access
1. **One source of truth** — Jenn's `_WORK/` is the master. Tricia reads from it.
2. **Write to your own exports** — Tricia writes video to `06_exports/video/`
3. **Never overwrite** — always create new files, never modify others' in-progress work
4. **Standard naming** — `[BRAND]-[TYPE]-[VERSION].[ext]` (e.g., `MIRRA-VIDEO-REEL-V2.mp4`)
5. **Rejected outputs** — follow the rejection learning loop, then delete

---

## ROOT-LEVEL FILE RULES

**ALLOWED at brand root** (max 1 file):
- Session handoff doc: `ENGINE.md` or `WORKFLOW.md` or `README.md`
- This is the "READ THIS FIRST" file for any agent/collaborator starting a session
- Contains: current state, what was done last, what to do next, which memory files to read

**EVERYTHING ELSE** → proper numbered folder:
- Strategy docs → `02_strategy/`
- Brand DNA → `00_brand-guide/`
- Video briefs → `02_strategy/`
- Content system specs → `02_strategy/`

**Why:** When Tricia or another collaborator opens a brand folder, they should see clean numbered folders + 1 handoff doc. Not 5 scattered .md files.

---

## REFERENCE FOLDER NAMING RULES

**Standard folders** (create for every brand):
- `curated/` — approved refs organized by sub-purpose (e.g., curated/elite/, curated/concepts/)
- `proven/` — refs from posts that actually performed well
- `format-specific/` — layout templates (used in TEXT prompt, not as Image 1)

**Optional layers** (add ONLY when the brand needs them):
- `pinterest/` — group ALL pinterest refs here (not pinterest-ads + pinterest-food + pinterest-branding)
- `ig-refs/` — Instagram scraped refs
- `xhs-refs/` — XHS/RED refs (Chinese market brands only)
- `video-refs/` — video production refs
- `ads-library/` — Meta Ad Library scraped refs
- `photography-mood/` — mood/color direction photos
- `user-input/` — human-provided direction images
- `viral-formats/` — proven viral format templates

**Naming rules:**
- NO version suffixes in folder names (`elite-v2/` → `curated/elite/`)
- NO platform-specific splitting unless 20+ refs per platform
- NO duplicate folders with slightly different names
- Consolidate overlapping folders (merge, don't multiply)

---

## VERSION HISTORY

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-03-30 | Initial standard. 7 folders, 3 tiers of intelligence files, rejection loop, layering system. |

---

*This standard evolves. When a new pattern emerges across 2+ brands, add it to the standard.*
*When a brand-specific need becomes universal, promote it from layering to required.*
