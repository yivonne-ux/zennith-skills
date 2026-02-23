# Meta Ads Creative Factory — SKILL.md
## Version 1.0 | GAIA Brand System

---

## 🎯 PURPOSE

A complete end-to-end creative production system for Meta Ads that:
- Researches winning ads from competitors and trends
- Analyzes English vs Chinese creative styles separately
- Applies 12 proven ad type frameworks + evolving formats
- Uses brand's actual product assets (never AI-generated products)
- Outputs campaign-ready creatives in 9:16 and 1:1 ratios

---

## 📋 WORKFLOW PHASES

### PHASE 1: RESEARCH & INTELLIGENCE

#### 1.1 Meta Ad Library Scraping
```bash
# Scrape for English ads (Western creative style)
python3 ~/.openclaw/skills/meta-ads-library/scripts/scrape.py \
  --keyword "poon choi,hot pot,festival food" \
  --location MY \
  --language en \
  --limit 50 \
  --output ~/.openclaw/workspace/{campaign}/research/english_ads.json

# Scrape for Chinese ads (Asian creative style)
python3 ~/.openclaw/skills/meta-ads-library/scripts/scrape.py \
  --keyword "盆菜,火锅,团圆饭" \
  --location MY,SG,TW,HK \
  --language zh \
  --limit 50 \
  --output ~/.openclaw/workspace/{campaign}/research/chinese_ads.json
```

#### 1.2 Pinterest Mood Board Analysis
- Access brand's Pinterest boards for visual DNA
- Extract: color palettes, typography styles, composition patterns, cultural motifs
- Document in: `~/.openclaw/workspace/{campaign}/research/pinterest_analysis.md`

#### 1.3 Trend Analysis
- Current CNY/Festival design trends
- Platform-specific best practices (Reels vs Feed)
- Audio/trending formats (if video)

---

### PHASE 2: STRATEGY & MESSAGE ARCHITECTURE

#### 2.1 Campaign Brief Document
Create `~/.openclaw/workspace/{campaign}/brief.md`:

```markdown
# Campaign Brief: [Name]

## Objectives
- Funnel Stage: [TOFU/MOFU/BOFU]
- Primary Goal: [Awareness/Engagement/Conversion]
- Target: [Demographics + Psychographics]

## Key Messages
- Core Hook: [One sentence]
- Supporting Points: [3-5 bullets]
- Offers/Promos: [Details]

## Hooks to Test (Minimum 6)
1. [Hook 1 with angle]
2. [Hook 2 with angle]
...

## Ad Types to Deploy
- [ ] Product-as-Hero
- [ ] Words-Based
- [ ] Ugly/Raw
- [ ] Testimonial
- [ ] Behind-the-Scenes
- [ ] Meme/Comic

## Ratios Required
- [ ] 9:16 (Stories/Reels)
- [ ] 1:1 (Feed)
- [ ] 4:5 (Optional)
```

#### 2.2 Asset Inventory
Download and catalog all brand assets:
```bash
mkdir -p ~/.openclaw/workspace/{campaign}/assets/
# Product hero images
# Logo/masthead variations  
# Lifestyle/context images
# Safe zone guides
# Font references
```

---

### PHASE 3: CREATIVE PRODUCTION

#### 3.1 Ad Type Selection Matrix

Match each hook to optimal ad type:

| Hook | Ad Type | Ratio | Why |
|------|---------|-------|-----|
| Phone 1/6/8 discount | Words-Based + Product | 9:16 | Urgency, clear CTA |
| Surname bonus | Meme/Comic | 9:16 | Engagement, sharing |
| Year of Horse | Product-as-Hero | Both | Visual appeal |
| RM38,888 prize | Words-Based | 9:16 | Bold numbers |
| Final chance | Behind-the-Scenes | Both | Authenticity |

#### 3.2 Image Generation WITH Copy (Not Separate)

**CRITICAL RULE:** Generate the COMPLETE ad with text overlays, not just background.

Prompt structure:
```
Create a professional Meta advertisement in [9:16/1:1] format.

PRODUCT: [Use actual brand product description from assets]
LAYOUT: [Per safe zone guide - top/middle/bottom zones]
TEXT ELEMENTS:
- Headline: "[Exact copy]"
- Body: "[Exact copy]"  
- CTA: "[Exact copy]"
- Offer details: [Any badges, promo codes]

VISUAL STYLE: [From Pinterest/mood analysis]
COLORS: [Brand palette from reference]
TYPOGRAPHY: [From font reference image]

The final image must be publication-ready with all text rendered clearly,
readable on mobile, following Meta safe zones. NO additional text added later.
```

#### 3.3 Two-Ratio Generation
Every winning concept gets BOTH ratios:
- 9:16: Vertical, mobile-first, Stories/Reels
- 1:1: Feed-optimized, square format

---

### PHASE 4: QUALITY & COMPLIANCE

#### 4.1 Meta Safe Zone Check
Verify using brand's safe zone guide:
- [ ] Top 20% clear of UI overlap
- [ ] Bottom 15% CTA visible
- [ ] Text < 20% of image area
- [ ] Logo placement correct

#### 4.2 Brand Compliance
- [ ] Correct product representation
- [ ] Logo usage per brand guide
- [ ] Color palette match
- [ ] Typography consistent

#### 4.3 Copy Check
- [ ] All copy renders clearly
- [ ] No spelling/grammar errors
- [ ] CTA is actionable
- [ ] Hook is prominent

---

## 🛠️ TOOLKIT

### Required Skills
- `meta-ads-library` — Competitive research
- `pinterest-assistant` — Mood board analysis
- `content-seed-bank` — Hook storage and retrieval
- `rag-memory` — Past performance learning

### Required Assets (Per Campaign)
1. Product hero image (transparent PNG preferred)
2. Logo/masthead (multiple variants if available)
3. Safe zone guide (9:16 template)
4. Font reference (English + Chinese samples)
5. Color palette definition
6. Lifestyle/context images (optional)

### Output Structure
```
~/.openclaw/workspace/{campaign}/
├── brief.md                    # Campaign strategy
├── research/
│   ├── english_ads.json       # Meta Ad Library data
│   ├── chinese_ads.json       # Meta Ad Library data
│   ├── pinterest_analysis.md  # Visual DNA
│   └── trend_notes.md         # Current trends
├── assets/                     # All brand assets
├── creative/
│   ├── 9x16/                  # Vertical ads
│   └── 1x1/                   # Square ads
├── copy/                       # All written content
└── final/                      # Approved exports
```

---

## 📊 THE 12 AD TYPES FRAMEWORK

### Ad Type #1: Ugly Ads
- **Purpose:** Grab attention, relatable problem
- **Creative:** Raw, low-fi vertical video, phone-shot aesthetic
- **Copy:** Provocative, conversational, challenges beliefs
- **Best For:** Cold audiences, TOFU

### Ad Type #2: Negative Ads  
- **Purpose:** Highlight pain point, position brand as solution
- **Creative:** Bold on-screen question about frustration
- **Copy:** Problem-focused, empathetic
- **Best For:** MOFU, retargeting

### Ad Type #3: Problem/Solution Ads
- **Purpose:** Clear path from problem to solution
- **Creative:** Split-screen Before/After
- **Copy:** Contrast-focused, relief-oriented
- **Best For:** All funnel stages

### Ad Type #4: Lo-fi Founder Ads
- **Purpose:** Build trust, answer questions
- **Creative:** Founder speaking to camera, real location
- **Copy:** Q&A format, genuine, transparent
- **Best For:** Brand building, objections

### Ad Type #5: Behind-the-Scenes Ads
- **Purpose:** Demonstrate demand, transparency
- **Creative:** Warehouse, packing, shipping footage
- **Copy:** "Overwhelming support" messaging
- **Best For:** Credibility, urgency

### Ad Type #6: Product-as-Hero Ads
- **Purpose:** Showcase benefits, drive desire
- **Creative:** High-quality, polished, close-ups
- **Copy:** Feature-focused, quality emphasis
- **Best For:** Product launches, appetite appeal

### Ad Type #7: Grid Style Ads
- **Purpose:** Present multiple options/features
- **Creative:** Grid layout, carousel
- **Copy:** Minimal, visually informative
- **Best For:** Catalogs, variants

### Ad Type #8: Before & After Ads
- **Purpose:** Tangible proof of results
- **Creative:** Side-by-side comparison
- **Copy:** Positive, quantifiable results
- **Best For:** Results-driven products

### Ad Type #9: Testimonial Ads
- **Purpose:** Overcome objections, social proof
- **Creative:** Customer reviews, screenshots, video
- **Copy:** High volume of positive reviews
- **Best For:** BOFU, conversion

### Ad Type #10: Words-Based Ads
- **Purpose:** Copy-led, bold typography hero
- **Creative:** Typography-first, minimal graphics
- **Copy:** Bold headline, promo announcement
- **Best For:** Sales, urgency, clarity

### Ad Type #11: Album/Compilation Ads
- **Purpose:** Product discovery, decision confidence
- **Creative:** Carousel, multiple images
- **Copy:** Consistent framing, cover + CTA end card
- **Best For:** Browsing, menu-style

### Ad Type #12: Static Meme/Comic Ads
- **Purpose:** Engagement via humor, shares
- **Creative:** 2-4 panels, bold caption, simple backgrounds
- **Copy:** Setup → punchline, product payoff
- **Best For:** Virality, brand personality

---

## 🚀 USAGE

### For Campaign Managers

```bash
# Initialize new campaign
openclaw creative-factory init --campaign "Chap Goh Meh 2026" \
  --funnel BOFU \
  --product "Pinxin Poon Choi" \
  --language "English+Chinese"

# Run research phase
openclaw creative-factory research \
  --campaign "Chap Goh Meh 2026" \
  --keywords "poon choi,盆菜,团圆饭" \
  --pinterest "pin.it/40FRbycp2,pin.it/414DSgSIF"

# Generate creative
openclaw creative-factory produce \
  --campaign "Chap Goh Meh 2026" \
  --hooks hooks.json \
  --ad-types "Words-Based,Product-as-Hero,Meme" \
  --ratios "9:16,1:1"
```

---

## 📝 CHAP GOH MEH 2026 — CORRECTED BRIEF

### Campaign Details
- **Event:** Chap Goh Meh (元宵) — Last day of CNY
- **Product:** Pinxin 2026 Chap Goh Meh Grand Finale Pot
- **Funnel:** BOFU (Final Call)
- **Target:** West Malaysia, 25-50, household decision makers

### Hooks (6 Required)
1. Phone ends 1/6/8 → RM20 off
2. Surnames Ma/Beh/Wong/Ong → RM20 bonus
3. Year of the Horse zodiac → RM20 bonus
4. Buy pot → win iPhone 17 Pro + RM38,888
5. RM38,888 unclaimed → last chance
6. Final chance → no extension

### Ad Type Mapping
| Hook | Primary Ad Type | Secondary | Ratio |
|------|----------------|-----------|-------|
| 1 | Words-Based | Product-as-Hero | 9:16 + 1:1 |
| 2 | Meme/Comic | Testimonial | 9:16 + 1:1 |
| 3 | Product-as-Hero | Words-Based | 9:16 + 1:1 |
| 4 | Words-Based | Behind-the-Scenes | 9:16 + 1:1 |
| 5 | Ugly/Urgency | Words-Based | 9:16 + 1:1 |
| 6 | Behind-the-Scenes | Words-Based | 9:16 + 1:1 |

### Assets to Use
- Poon Choi: `2026%20poon%20choi%20edit-gravy3.png`
- Logo: `2026%20cny%20horse%20masthead.png`
- Safe Zone: `9-16%20ads%20safe%20zone.png`
- Font Ref: `font%20english.jpeg`
- Additional: Google Drive folder (16 images)

---

*Skill v1.0 — Meta Ads Creative Factory*
