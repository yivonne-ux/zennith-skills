# Pinxin Vegan — Production Intelligence

> Distilled from 6 proven production runs: cn-ads-v4 (24 CN ads, 4 fix rounds), v4_campaign (22 EN ads, 100%), march_campaign_v3 (30 ads, 100%), v16 (18/18 BB), easter (3/3 BB), BETTER OUTPUTS (breakthrough 5).
> This is not theory. This is what shipped.

---

## THE PROVEN ARCHITECTURE

### Single Law
**NANO Banana Pro Edit renders EVERYTHING. PIL renders NOTHING except post-processing.**

NANO renders: all text, headlines, body copy, logos, illustrations, layouts, characters, badges, prices.
PIL renders: force_size, editorial_grade, paper_texture, logo PNG placement, grain, sharpen.

No exceptions. No PIL text. No multi-pass. Single AI pass per variant.

---

## 7-LAYER PROMPT ARCHITECTURE (from cn-ads-v4 — most relevant for Pinxin)

Pinxin is a Chinese-primary brand. The cn-ads-v4 architecture is the direct blueprint.

```
L1: SAFETY — ANTI_RENDER + NO_BRAND_LEAK
L2: REFERENCE — "Keep EXACT same layout. Edit this image."
L3: BRAND DNA — PINXIN_BRAND_DNA + FOOD_INTEGRITY + CAMERA_CRAFT + FOOD_ANGLE
L4: CAMPAIGN — persona + pain_point + entity_hypothesis + sara_mindstate
L5: COPY — Crafted Chinese headline (from Copy Doctrine formulas)
L6: TYPOGRAPHY — TYPO_EDITORIAL or TYPO_MASSIVE + PINXIN_FONT_BADGE
L7: OUTPUT — 1080×1350, Meta safe zones, PX Green/Gold color anchors
```

### Layer Details for Pinxin

**L1: SAFETY**
```
ANTI_RENDER: "Do NOT render hex codes, font names, pixel coordinates,
bracket contents, or technical instructions as visible text in the image."

NO_BRAND_LEAK: "Do NOT render '品馨', 'PINXIN', 'Pinxin', 'Vegan Cuisine'
as text in the image. Logo is added post-production."
(Learned from cn-ads-v4: NANO renders brand names when prompted — must explicitly ban)
```

**L2: REFERENCE (Edit-First)**
```
"Edit this image. Keep the EXACT same layout, spatial relationships, and
compositional structure. CHANGES — swap only these specific elements:
[list swaps]. PRESERVE — keep everything else exactly as-is."
```
Every variant starts from a real reference image. Never generate from scratch.

**L3: BRAND DNA**
```python
PINXIN_BRAND_DNA = {
    "palette": {
        "primary": "#1C372A",      # PX Green — backgrounds, premium
        "accent": "#D0AA7F",       # PX Gold — frames, accents, prices
        "cream": "#F2EEE7",        # Light mode backgrounds
        "burgundy": "#470E23",     # Festival, cultural
        "dark_brown": "#42210B",   # Deep accent
        "deep_red": "#6C0E0E",     # Spice, warmth
    },
    "visual_dna": "Quiet Luxury Malaysian-Chinese Dining",
    "mood": "abundant yet calm, heritage refinement, warm invitation",
    "surfaces": "teak, walnut, matte stone, terrazzo, cream linen",
    "finish": "matte low-gloss only, visible ceramic texture, woodgrain",
}

FOOD_INTEGRITY = """
Every food photo is SACRED. Never let AI generate, reimagine, or alter
food appearance. Food photo must be INPUT to generation — pixel-perfect
preservation. If food photo provided as Image 2+, anchor it FIRST:
"Image 2 IS the [dish]. Do not generate AI food. Preserve exactly."
"""

CAMERA_CRAFT = """
85mm f/1.4 lens compression. 30-45 degree dining-seat angle.
Directional warm light from upper-left. 5000-5300K daylight.
Fill ratio 4:1. Shallow DOF with creamy bokeh.
Matte ceramic texture visible. Steam at 30% opacity on hot dishes.
"""

FOOD_ANGLE_MATCHING = {
    "hero_45": "30-45 degree angle, dining perspective, hero dish 65-75% frame",
    "overhead": "90 degree top-down, flat-lay, multi-dish spread",
    "side": "Eye-level, soup/noodle depth, steam rising",
}
```

**L4: CAMPAIGN (Persona-Driven)**
```python
# 6 Pinxin personas (from Copy Doctrine)
PERSONAS = {
    "busy_mum": {
        "pain": "No time to cook, guilty about processed food",
        "hook_cn": "15分钟上桌，孩子以为妈妈亲手煮的",
        "entity_hypothesis": "time-starved mother seeking family meal solution",
        "sara_mindstate": "guilt → relief → pride",
    },
    "three_highs_uncle": {
        "pain": "Health restrictions, boring diet, misses heritage flavor",
        "hook_cn": "50%低钠盐，阿公安心吃古早味",
        "entity_hypothesis": "health-restricted elder craving traditional food",
        "sara_mindstate": "restriction → discovery → satisfaction",
    },
    "religious_vegetarian": {
        "pain": "Hard to find tasty allium-free options for 初一十五",
        "hook_cn": "初一十五不知道煮什么？品馨帮你准备好了",
        "entity_hypothesis": "devout practitioner seeking convenient ritual food",
        "sara_mindstate": "obligation → ease → devotion",
    },
    "office_worker": {
        "pain": "Too tired to cook after work, eating unhealthy",
        "hook_cn": "下班后15分钟，正宗槟城味端上桌",
        "entity_hypothesis": "exhausted professional wanting quick real dinner",
        "sara_mindstate": "fatigue → craving → comfort",
    },
    "health_conscious": {
        "pain": "Wants clean eating without sacrificing flavor",
        "hook_cn": "零胆固醇、零味精，但味道满分",
        "entity_hypothesis": "wellness-oriented eater seeking clean indulgence",
        "sara_mindstate": "vigilance → trust → enjoyment",
    },
    "sg_chinese": {
        "pain": "Misses Penang food, can't find authentic vegan in SG",
        "hook_cn": "想念槟城味？品馨直送新加坡",
        "entity_hypothesis": "nostalgic expat craving hometown taste",
        "sara_mindstate": "longing → surprise → homecoming",
    },
}
```

**L5: COPY** — From Copy Doctrine formulas, crafted per persona × funnel stage.

**L6: TYPOGRAPHY**
```python
TYPO_EDITORIAL = """
Chinese headline: artisan display typeface, massive bold characters
occupying 40-60% of canvas width. Elegant, refined, heritage feel.
Body: clean medium-weight Chinese sans-serif underneath.
English accent: wide-tracked ALL CAPS serif underneath Chinese.
Gold #D0AA7F for prices and highlight numbers.
"""

TYPO_MASSIVE = """
Chinese headline fills 60%+ of canvas. Characters are the design itself.
Bold, confident, premium. Like a luxury magazine cover.
Supporting text minimal — dish name + one benefit line only.
"""

PINXIN_FONT_BADGE = """
Small benefit badges in colored rounded rectangles:
'15分钟' in gold badge, '零胆固醇' in green badge, '50%低钠' in cream badge.
Badges arranged horizontally at bottom, max 3.
"""
```

**L7: OUTPUT**
```python
OUTPUT_SPEC = """
Final canvas: 1080×1350px (IG feed 4:5).
META SAFE ZONES: top 14% clean (no critical text), bottom 20% clean (CTA overlay).
Critical content in center 66% of canvas height.
PX Green #1C372A as default dark background.
PX Gold #D0AA7F as accent for frames, prices, badges.
All text fully visible, nothing truncated at edges.
"""
```

---

## 9 PROMPT DNA BLOCKS (from v16 — adapted for Pinxin)

```python
# Block 1: Safety
ANTI_RENDER = "Do NOT render hex codes, font names, pixel coordinates, or bracket contents as visible text."

# Block 2: No brand text leak
NO_BRAND_LEAK = "Do NOT render '品馨' or 'PINXIN' as text. Logo added post-production."

# Block 3: Font DNA
FONT_DNA_PX = """
Headlines: powerful Chinese display characters — bold, architectural, premium.
Think luxury tea brand, not fast food. Characters have weight and presence.
Body: clean Chinese sans-serif, medium weight, generous line spacing.
English: wide-tracked ALL CAPS serif for accent lines. Recoleta energy.
"""

# Block 4: Type Master
TYPE_MASTER_PX = """
Chinese headline: 40-60% of canvas width minimum. This is the hero element.
Size ratio: headline 3:1 to body text.
Maximum 2 typeface styles per design.
ALL CAPS with wide letter-spacing for English accent = luxury feel.
"""

# Block 5: Layout Master
LAYOUT_MASTER_PX = """
80px margins on all sides.
40-60% breathing space (white/negative space).
Maximum 4-5 elements total.
Info block = ONE text group, not scattered.
Triangle composition: hero + 2-3 supporting elements.
"""

# Block 6: Color Master
COLOR_MASTER_PX = """
60-30-10 rule: 60% PX Green or dark bg, 30% food/cream, 10% PX Gold accent.
Gradient backgrounds, never flat solid fills.
Color-match: background echoes food's dominant hue.
Dark mode (70% of designs): PX Green/brown/burgundy.
Light mode (30%): cream/white for English health content.
"""

# Block 7: Logo Safe
LOGO_SAFE_PX = "Keep top 12-15% of canvas clear for post-production logo placement."

# Block 8: Grid Safe
GRID_SAFE_PX = "Center all critical content. IG crops 4:5 to 3:4 for grid thumbnail. Outer 32px is danger zone."

# Block 9: Pinxin Character DNA (for CAT-08)
PX_CHARACTER_DNA = """
Semi-realistic Malaysian Chinese family characters with soft gradients
and warm skin tones. NOT flat cartoon, NOT realistic humans.
Aunty (main), Uncle, Ahma, Young Mom, Chilli Boy.
Characters must feel like they belong in the same family —
consistent art style, proportions, warmth level.
"""
```

---

## 22 PROVEN AD TYPES (from v4_campaign — adapt for Pinxin)

These 22 types achieved 100% success rate. Map to Pinxin categories:

| Ad Type | Pinxin Category | Description |
|---------|----------------|-------------|
| SplitScreen | CAT-02, CAT-03 | Before/after or comparison split |
| NarrativeIdentity | CAT-01 | Storytelling hero with cultural hook |
| ProductHeroCTA | CAT-02, CAT-06 | Single dish hero + price/CTA |
| LifestyleListicle | CAT-03 | Benefits list with lifestyle photo |
| BoldPromo | CAT-06 | Price-dominant promotional |
| RetroPoster | CAT-07 | Festival/cultural vintage poster |
| TestimonialCard | CAT-04 | Quote card with photo/avatar |
| TestimonialQuote | CAT-04 | Large quote, minimal design |
| SocialProofMulti | CAT-04 | Multiple reviews/badges |
| GridMosaic | CAT-06 | Multi-dish grid with price overlay |
| MenuShowcase | CAT-05 | Menu-style dish listing |
| LifestyleHero | CAT-01, CAT-02 | Full-bleed lifestyle photography |
| DreamyProductFloat | CAT-02 | Floating dish on gradient bg |
| SearchSolutionMenu | CAT-10 | Search UI / solution format |
| IGPostMockup | CAT-10 | IG post within mockup frame |
| ComparisonSplit | CAT-03 | Side-by-side comparison |
| ProblemSolution | CAT-03 | Pain point → product solution |
| NarrativeRitualCard | CAT-01, CAT-07 | Cultural ritual storytelling |
| CalendarSchedule | CAT-05 | Weekly meal plan calendar |
| IncomingCallUI | CAT-09 | Raw/lo-fi phone UI mockup |
| BeforeAfterBody | CAT-03 | Health transformation |
| BoldTypography | CAT-01 | Type-dominant cultural statement |

---

## POST-PROCESSING CHAIN (Proven exact sequence)

```python
def post_process_pinxin(raw_path, output_path, logo_path):
    """
    Exact chain from v16 + cn-ads-v4. Do NOT reorder.
    """
    img = Image.open(raw_path)

    # 1. Force size
    img = force_size(img, 1080, 1350)

    # 2. Editorial grade (subtle, luxury feel)
    img = editorial_grade(img, desat=0.08, contrast=1.06)
    # Pinxin: slightly less desat than BB (0.10) — food colors must stay rich

    # 3. Paper texture (quiet luxury tactile feel)
    img = paper_texture(img, opacity=0.020)
    # Pinxin: slightly less than BB (0.025) — darker bgs need less texture

    # 4. Logo placement
    img = place_logo(img, logo_path, position="top_center",
                     max_width=140, padding=40, autocrop=True)
    # Auto-crop alpha bbox before resize (from Mirra logo learnings)
    # Smart variant: gold logo on dark bg, beige on light bg

    # 5. Grain (ALWAYS second-to-last)
    img = add_grain(img, amount=3.5)
    # Pinxin: slightly less than BB (4.0) — preserve food clarity

    # 6. Sharpen (ALWAYS last)
    img = sharpen(img, radius=1.0, percent=85, threshold=4)

    img.save(output_path)
```

---

## DIVERSITY SYSTEM (Andromeda — from cn-ads-v4)

Every batch must have structural diversity across 6 dimensions:

1. **Persona rotation** — All 6 personas represented, never >2 consecutive same persona
2. **Visual style** — Mix of editorial_photo (40%) and graphic_design (60%)
3. **Layout type** — Rotate across 22 ad types, never repeat in same batch
4. **Color world** — Match to dish (amber/brown → green → red → cream), never 3 dark in a row
5. **Funnel stage** — TOFU 15% / MOFU 50% / BOFU 30% / Advocacy 5%
6. **Food angle** — Mix 45-degree, overhead, side across batch

Meta penalizes >60% visual similarity. Diversity is structural, not random.

---

## REFERENCE-FIRST PRODUCTION FLOW

```
1. Collect references (Pinterest, competitor ads, brand refs)
   → Score against quality filters (7 criteria from reference-scraping-criteria)

2. Classify each reference
   → Simple composition (hero, split, testimonial, grid) → System constants
   → Complex UI (>8 elements) → Edit-first god mode

3. Build prompt per variant
   → Assemble 7 layers (L1-L7)
   → Persona + direction from diversity matrix
   → Chinese headline from Copy Doctrine

4. Generate via NANO Banana Pro Edit (2K)
   → Single pass, ~$0.15/image
   → Reference image as Image 1
   → Food photo as Image 2 (if Pipeline B)

5. Post-process
   → force_size → editorial_grade → paper_texture → logo → grain → sharpen

6. Audit (8-dimension)
   → brand_dna, composition, lighting, typography, negative_space,
     conversion, emotional_register, cultural_authenticity
   → Passing threshold: 75+
   → Failures: fix prompt, regenerate (new pass, not edit of output)
```

---

## PINXIN-SPECIFIC ADAPTATIONS vs MIRRA/BB

| Dimension | Mirra | Bloom & Bare | Pinxin |
|-----------|-------|-------------|--------|
| Primary language | EN (60%) → CN (60%) | EN (bilingual EN/CN) | **CN 65% / EN 35%** |
| Visual mode | Lo-fi girlboss | Playful Scandinavian | **Quiet luxury heritage** |
| Background default | Dusty rose/salmon | Cream #F5F0E8 | **PX Green #1C372A** |
| Typography energy | Lowercase, no caps | DX Lactos ultra-bold | **Massive CN display chars** |
| Food handling | Real library, PIL composite | No food | **Real library, NANO input** |
| Logo | "mirra." signature, NANO renders | Mascots + wordmark, PIL places | **Ginkgo + PINXIN, PIL places** |
| Post-process | resize + grain only | editorial_grade + paper + grain + sharpen | **editorial_grade + paper + grain + sharpen** |
| Character system | None | 6 mascots | **12 vector family characters** |
| Grid rhythm | N/A (ads only) | BOLD\|PHOTO\|CLEAN | **BOLD\|PHOTO\|CLEAN (adapted)** |
| Cultural layer | Malaysian casual | Universal playful | **Malaysian-Chinese heritage** |
| Price in creative | Never | N/A | **BOFU only, in gold #D0AA7F** |
| Desat | None | 0.10 | **0.08 (preserve food color)** |
| Grain | 0.016 | 4.0 | **3.5 (preserve food clarity)** |
| Paper texture | None | 0.025 | **0.020 (dark bg needs less)** |

---

## WHAT TO BUILD NEXT

The production pipeline (`pinxin_batch.py`) needs:
1. Brand DNA dict (above)
2. 7-layer prompt assembler
3. 9 DNA blocks
4. 6 persona definitions
5. Reference classifier (simple vs complex)
6. NANO Banana Pro Edit API integration
7. Post-processing chain (6 steps)
8. 8-dimension audit
9. Batch runner with diversity enforcement
10. Naming convention: `PX-{CAT}-{LANG}-{PERSONA}-{ADTYPE}-{VERSION}.png`
