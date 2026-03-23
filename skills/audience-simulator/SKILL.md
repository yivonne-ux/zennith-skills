---
name: audience-simulator
description: Pre-test content by simulating audience reactions with persona-based LLM agents. Test ad hooks, captions, product descriptions, and campaigns against simulated audiences before spending budget. Inspired by MiroFish's multi-agent simulation concept.
agents: [dreami, taoz]
version: 1.0.0
---

# Audience Simulator -- Pre-Test Content with Persona-Based LLM Agents

> Instead of publishing content and hoping it works, simulate how your target audience would react FIRST.

Uses LLM-as-judge with brand-specific persona profiles to score content before it goes live. Not 1 million agents like MiroFish -- we use 5-10 well-defined personas per brand, drawn from the brand's DNA.json audience definitions.

## How It Works

```
CONTENT --> Load brand personas --> Each persona "reacts" --> Aggregate scores --> Pass/Fail/Refine
```

Each persona has: name, age, occupation, values, pain points, social media behavior, purchase triggers, deal-breakers.

---

## Persona Library

Personas are calibrated for the Malaysian market. They are real archetypes from our customer base, not generic marketing segments.

### MIRRA Personas (weight management meal subscription)

1. **Sarah, 32** -- KL marketing exec at a Bangsar agency. Tracks macros on MyFitnessPal religiously. Wants healthy lunch without cooking because her office pantry only has Gardenia bread and Milo. Scrolls IG during lunch, saves meal prep content. Will pay premium for convenience but judges value by cost-per-calorie. Deal-breaker: vague "healthy" claims with no nutritional info.

2. **Aishah, 28** -- Fitness-conscious hijabi, hits the gym in Damansara 4x/week (mix of CrossFit and pilates). Meticulous about halal certification AND calories -- not either/or. Follows Malaysian fitness influencers, shares workout stories daily. Purchase trigger: seeing real transformation photos from people who look like her. Deal-breaker: any ambiguity about halal status.

3. **Michelle, 38** -- Working mom in Subang, two kids (7 and 4). Nutrition-conscious for the whole family but stretched thin between school runs and a WFH accounting job. Price-sensitive -- compares per-meal cost against cooking at home. Buys in weekly bundles to save. Purchase trigger: family plans, kids-friendly options. Deal-breaker: portions too small for a family or pricing that only works for singles.

4. **Priya, 26** -- Young professional at a Bangsar South startup. Tired of rotating between mamak, mixed rice, and Grab delivery junk. Wants to look good and feel good -- posts her lunch on IG stories if it's aesthetic enough. Follows food bloggers. Purchase trigger: IG-worthy packaging + relatable content (not preachy health talk). Deal-breaker: boring branding that looks like a hospital meal.

### Pinxin Vegan Personas

1. **Wei Ling, 30** -- Flexitarian foodie based in PJ. Eats plant-based 3-4 days a week but will NOT sacrifice Malaysian flavour for health virtue. Judges vegan food against the real thing -- if your vegan rendang doesn't taste like rendang, she's out. Follows food review accounts, trusts peer reviews over brand claims. Purchase trigger: "tastes like the real thing" testimonials. Deal-breaker: anything that tastes like cardboard dressed as Malaysian food.

2. **Raj, 35** -- Fitness bro in Cheras, eats 180g protein daily. Thinks vegan = tasteless tofu and rabbit food. Needs hard evidence (protein per serving, amino acid profile) to even consider it. Follows bodybuilding accounts, skeptical of anything "green." Purchase trigger: macros that compete with chicken breast. Deal-breaker: weak protein content or preachy "save the planet" messaging.

3. **Siti, 42** -- Home cook in Shah Alam exploring plant-based for health reasons (husband's cholesterol is high). Traditional Malay palate -- sambal, santan, rempah. Cares deeply about halal compliance at every level (ingredients, production, certification). Purchase trigger: recipes that fit into her existing cooking style. Deal-breaker: Western-style vegan food that doesn't belong on a Malaysian dinner table.

4. **James, 27** -- Hipster millennial in KL, already committed vegan for 3 years. Follows global vegan accounts, knows his tempeh from his tofu. Wants authentic Southeast Asian plant-based, not another imported Beyond Burger situation. Hangs out at TTDI cafes. Purchase trigger: local, authentic, craft-quality. Deal-breaker: mass-market processed vegan that pretends to be artisanal.

### Jade Oracle Personas

1. **Emma, 29** -- Spiritual explorer in Penang, does tarot weekly with her own Rider-Waite deck. Skeptical of generic readings that could apply to anyone ("you are going through a transition" -- no kidding). Wants depth, specificity, a reader who clearly knows their system. Active on spiritual IG communities. Purchase trigger: a reading that names something she hasn't told anyone. Deal-breaker: cookie-cutter horoscope energy.

2. **Mei Lin, 34** -- Chinese diaspora entrepreneur running an e-commerce biz from KL. Interested in Qi Men Dun Jia (QMDJ) for business timing -- when to launch products, sign contracts, expand. Treats metaphysics as a strategic tool, not entertainment. Purchase trigger: case studies showing QMDJ applied to business decisions with outcomes. Deal-breaker: woo-woo presentation that would embarrass her if a business partner saw it.

3. **Sophie, 25** -- TikTok-native in KL, watches tarot pick-a-card videos between classes. Low commitment but high engagement volume -- will watch 10 tarot TikToks in a row but hasn't paid for a reading yet. Follows for entertainment and emotional validation. Purchase trigger: a hook so specific she screenshots it and sends to friends. Deal-breaker: long-form content that doesn't get to the point in 3 seconds.

4. **Diana, 41** -- Going through a major life transition (recent divorce, career pivot from corporate to freelance). Based in JB. Needs real guidance, not entertainment. Willing to pay premium (RM500+) for a comprehensive reading that helps her make actual decisions. Purchase trigger: testimonials from people in similar life situations. Deal-breaker: anything that feels superficial or mass-produced.

### Dr. Stan Personas

1. **Dr. Ahmad, 45** -- GP in Klang Valley, evidence-based decision maker. Reads ingredient labels front and back, checks PubMed for ingredient claims. Trusts science, not hype. Will recommend supplements to patients only if the evidence is solid. Purchase trigger: clinical studies, transparent ingredient sourcing, proper dosages (not fairy-dust amounts). Deal-breaker: proprietary blends that hide dosages, unsubstantiated claims, MLM vibes.

2. **Karen, 38** -- Wellness mom in Mont Kiara, researches everything on Google before buying. Three browser tabs of "is [ingredient] safe for kids" at any time. Wants natural but proven -- not either/or. Active in parent WhatsApp groups where product recommendations spread fast. Purchase trigger: clean label + scientific backing + other moms vouching for it. Deal-breaker: synthetic ingredients disguised as natural, or "natural" products with no evidence.

### Wholey Wonder Personas

1. **Jess, 24** -- Gym girl in Bukit Jalil, smoothie bowl is both breakfast and content. Posts everything from her morning routine to her post-workout shake. Follows fitness influencers, discovers brands through IG reels. Purchase trigger: photogenic product + influencer endorsement + something she can film herself making. Deal-breaker: ugly packaging or a product that doesn't blend well (literally and visually).

2. **Ryan, 29** -- Health-conscious corporate guy in Cyberjaya. Wants quick nutritious breakfast because he's in back-to-back meetings by 9am. Doesn't cook, barely has time to blend. Values convenience and clean macros over aesthetics. Purchase trigger: "ready in 2 minutes" + high protein + not too sweet. Deal-breaker: complicated prep or sugar-bomb disguised as healthy.

### Rasaya Personas

1. **Aunty Lim, 55** -- Lives in Ipoh, believes in traditional remedies because they worked for her mother and grandmother. Drinks jamu weekly, keeps a turmeric-ginger supply in the kitchen at all times. Heritage-conscious -- suspicious of modern repackaging of ancient wisdom. Purchase trigger: authentic recipes, traditional preparation methods, connection to heritage. Deal-breaker: trendy branding that strips away the cultural roots, or Western "superfood" framing of ingredients she's known her whole life.

2. **Nadia, 31** -- Modern Malay woman in KL who grew up watching her nenek make traditional remedies. Wants that same wellness but in packaging she's not embarrassed to have on her office desk. Active on Shopee, compares reviews before buying. Purchase trigger: traditional formulation + modern, clean packaging + good reviews. Deal-breaker: packaging that looks like it's from the 1990s pasar malam, or products that don't list ingredients clearly.

### Serein Personas

1. **Amanda, 36** -- Corporate lawyer in KL, works 12-hour days and desperately needs self-care rituals that actually calm her down (not just look calming on IG). High spending power, low time. Will pay RM200+ for a product that genuinely works. Purchase trigger: real efficacy backed by ingredients she can Google, minimal time investment. Deal-breaker: products that are all aesthetic and no substance, or routines that require 45 minutes she doesn't have.

2. **Yuki, 28** -- Half-Japanese Malaysian, minimalist lifestyle, lives in a MUJI-like apartment in Mont Kiara. Values calm aesthetics and intentional design. Follows Japanese wellness and skincare accounts. Purchase trigger: minimal, beautiful design + Japanese-inspired wellness philosophy + quality ingredients. Deal-breaker: cluttered packaging, loud branding, or anything that feels mass-produced.

### Iris Personas

1. **Rina, 33** -- Visual merchandiser in KL, lives on Pinterest and IG. Has an eye for brand consistency and notices when a grid is off. Follows design-forward accounts across fashion, food, and lifestyle. Purchase trigger: striking, cohesive visual identity that tells a story. Deal-breaker: inconsistent brand visuals or stock-photo energy.

2. **Daniel, 30** -- Social media manager for a Penang boutique hotel. Manages 4 accounts and benchmarks everything against engagement rate. Follows competing brands, screenshots good creative for inspo. Purchase trigger: content that demonstrably outperforms similar posts. Deal-breaker: pretty visuals with zero strategic intent behind them.

### Gaia Eats Personas (multi-restaurant delivery platform)

1. **Haziq, 26** -- Grab-addicted software dev in Cyberjaya, orders delivery 5x a week. Compares platforms by speed, variety, and promo codes. Has GrabFood, ShopeeFood, and FoodPanda installed. Purchase trigger: exclusive restaurants or faster delivery than competitors. Deal-breaker: RM8 delivery fee on a RM12 meal.

2. **Farah, 34** -- Office manager in Petaling Jaya who orders team lunches for 8 people. Needs variety (halal, vegetarian, allergy-friendly) in a single order. Purchase trigger: group ordering features, consolidated delivery. Deal-breaker: no dietary filters, or 3 separate deliveries for one team lunch.

### Gaia Learn Personas (educational content platform)

1. **Teacher Tan, 40** -- Secondary school science teacher in Penang who supplements classroom teaching with online content. Values curriculum-aligned, locally relevant material. Purchase trigger: content mapped to Malaysian SPM syllabus. Deal-breaker: US/UK-centric content that doesn't apply to Malaysian students.

2. **Amirah, 22** -- University student in KL prepping for professional exams. Studies in 25-minute Pomodoro sprints, needs bite-sized content. Purchase trigger: structured micro-lessons with quizzes. Deal-breaker: hour-long lectures with no chapter markers.

### Gaia OS Personas (AI operating system / platform)

1. **Marcus, 37** -- Tech lead at a KL startup, evaluates AI tools for team productivity. Reads Hacker News, cares about API docs, uptime SLAs, and data privacy. Purchase trigger: developer-friendly docs, transparent pricing, self-hostable option. Deal-breaker: vendor lock-in or vague "AI-powered" marketing with no technical detail.

2. **Suyin, 44** -- COO of a mid-size Malaysian company exploring AI automation. Needs business outcomes, not tech specs. Purchase trigger: case studies with measurable ROI (hours saved, cost reduced). Deal-breaker: requires dedicated dev team to implement.

### Gaia Print Personas (print-on-demand / merchandise)

1. **Liyana, 27** -- Indie artist in KL selling designs on Shopee. Needs reliable print-on-demand with good colour accuracy and fast fulfilment. Purchase trigger: accurate colour reproduction, no minimum order, local shipping. Deal-breaker: prints that don't match the digital proof.

2. **Ben, 32** -- Small business owner in JB making branded merchandise for corporate clients. Orders in bulk (100-500 units). Purchase trigger: volume discounts, consistent quality across batches, white-label packaging. Deal-breaker: inconsistent quality or slow turnaround on bulk orders.

### Gaia Recipes Personas (recipe content platform)

1. **Mei Fong, 48** -- Home cook in Ipoh, collects recipes from Facebook groups and YouTube. Prefers Malaysian and Nyonya recipes with exact measurements (not "agak-agak"). Purchase trigger: step-by-step videos with local ingredients she can find at Jaya Grocer or wet market. Deal-breaker: recipes that require imported specialty ingredients.

2. **Zara, 25** -- Young professional in KL who just moved out and can barely cook Maggi. Follows quick-recipe reels on IG. Purchase trigger: 15-minute meals with 5 or fewer ingredients. Deal-breaker: recipes that assume she owns a full spice rack or a Dutch oven.

### Gaia Supplements Personas (health supplements line)

1. **Uncle Chong, 58** -- Semi-retired businessman in PJ, takes 6 supplements daily. Reads labels with a magnifying glass, compares brands on iHerb and Lazada. Purchase trigger: transparent sourcing, third-party testing, clear dosage info. Deal-breaker: proprietary blends, exaggerated health claims, or MLM distribution.

2. **Nina, 30** -- Yoga instructor in Bangsar, prefers plant-based supplements. Checks for vegan certification, no gelatin capsules. Purchase trigger: vegan-certified, sustainably sourced, clean-label. Deal-breaker: animal-derived ingredients or excessive fillers.

---

## Brand Coverage

All 14 Zennith brands are supported. Persona count and simulation priority determine test depth.

| # | Brand Slug | Display Name | Personas | Priority | Notes |
|---|-----------|-------------|----------|----------|-------|
| 1 | `pinxin-vegan` | Pinxin Vegan | 4 | **P0 -- Core F&B** | Plant-based Malaysian food |
| 2 | `wholey-wonder` | Wholey Wonder | 2 | **P0 -- Core F&B** | Smoothie bowls & superfoods |
| 3 | `mirra` | MIRRA | 4 | **P0 -- Core F&B** | Bento-style health food (NOT skincare) |
| 4 | `rasaya` | Rasaya | 2 | **P0 -- Core F&B** | Traditional wellness drinks |
| 5 | `gaia-eats` | Gaia Eats | 2 | **P0 -- Core F&B** | Multi-restaurant delivery |
| 6 | `dr-stan` | Dr. Stan | 2 | **P0 -- Core F&B** | Evidence-based supplements |
| 7 | `serein` | Serein | 2 | **P0 -- Core F&B** | Self-care rituals & wellness |
| 8 | `jade-oracle` | Jade Oracle | 4 | **P1 -- Active** | Tarot, QMDJ, metaphysics |
| 9 | `iris` | Iris | 2 | **P1 -- Active** | Visual QA & brand identity |
| 10 | `gaia-os` | Gaia OS | 2 | **P2 -- Platform** | AI operating system |
| 11 | `gaia-learn` | Gaia Learn | 2 | **P2 -- Platform** | Educational content |
| 12 | `gaia-print` | Gaia Print | 2 | **P2 -- Platform** | Print-on-demand merch |
| 13 | `gaia-recipes` | Gaia Recipes | 2 | **P2 -- Platform** | Recipe content platform |
| 14 | `gaia-supplements` | Gaia Supplements | 2 | **P2 -- Platform** | Health supplements line |

**Priority tiers:**
- **P0 -- Core F&B:** These brands run paid ads and publish content daily. Every piece of ad copy MUST be audience-simulated before spend. Brands: pinxin-vegan, wholey-wonder, mirra, rasaya, gaia-eats, dr-stan, serein.
- **P1 -- Active:** Regular content, simulate before campaigns. Brands: jade-oracle, iris.
- **P2 -- Platform:** Simulate on launch campaigns and major content pushes. Brands: gaia-os, gaia-learn, gaia-print, gaia-recipes, gaia-supplements.

---

## Simulation Workflow

```
INPUT: Content (ad copy, caption, image description) + brand name + [optional: specific personas]

STEP 1: Load brand DNA --> extract audience personas
        Source: ~/.openclaw/brands/{brand}/DNA.json
        Fallback: persona library in this SKILL.md

STEP 2: For each persona (5-10 per brand):
  a. Generate persona context:
     - Who they are (demographics, lifestyle, values)
     - How they consume content (platform, scroll speed, attention span)
     - What they care about (pain points, aspirations, triggers)
     - What turns them off (deal-breakers, red flags)
  b. Present the content to the persona
  c. Simulate reaction:
     - Would they stop scrolling?
     - Would they read beyond the first line?
     - Would they engage (like, comment, save, share)?
     - Would they click through?
     - Would they buy / take action?
  d. Score: 1-10 for each dimension (see Scoring Dimensions below)
  e. Generate persona-voice feedback:
     "As Sarah, I would... because..."
     Written in the persona's actual voice, not marketer-speak.

STEP 3: Aggregate scores across all personas
        - Per-persona breakdown
        - Per-dimension breakdown
        - Overall average

STEP 4: Identify segments:
        - LOVE IT (score >= 8): these personas are your core audience for this content
        - NEUTRAL (score 5-7): content doesn't repel them but won't convert
        - TURNED OFF (score < 5): content actively alienates this segment

STEP 5: Generate improvement suggestions
        - Specific, actionable rewrites (not generic "make it more engaging")
        - Tied to specific persona feedback
        - Prioritized by impact (fixing a deal-breaker > optimizing a nice-to-have)

STEP 6: Pass/Fail decision
        - avg >= 7.0 across all personas = PASS (ship it)
        - avg 5.0 - 6.9 = REFINE (fixable, see suggestions)
        - avg < 5.0 = FAIL (fundamental mismatch, rethink approach)

OUTPUT: Persona reaction report + aggregate score + improvement suggestions
        Saved to: ~/.openclaw/workspace/data/audience-sim/{brand}/
```

---

## Scoring Dimensions

Each persona scores on 4 dimensions (1-10 scale):

| Dimension | What It Measures | Scoring Guide |
|-----------|-----------------|---------------|
| **Attention** | Would this stop my scroll? | 1-3: scrolls past. 4-6: glances but moves on. 7-8: stops, reads. 9-10: stops, screenshots. |
| **Relevance** | Is this for me? | 1-3: wrong audience entirely. 4-6: adjacent but not quite. 7-8: speaks to my situation. 9-10: feels personally written for me. |
| **Emotion** | How does this make me feel? | 1-3: nothing / negative. 4-6: mild interest. 7-8: genuine desire or curiosity. 9-10: "I need this NOW." |
| **Action** | Would I do something? | 1-3: no action. 4-6: might save for later. 7-8: would click / inquire. 9-10: would buy / sign up immediately. |

**Overall score** = average of 4 dimensions across all personas.

---

## CLI Usage

```bash
# Script location
~/.openclaw/skills/audience-simulator/scripts/audience-simulator.sh

# Test ad copy against all brand personas
bash scripts/audience-simulator.sh test \
  --brand mirra \
  --content "Your weight management meals, delivered fresh daily. Order now."

# Test with specific personas only
bash scripts/audience-simulator.sh test \
  --brand jade-oracle \
  --content "Your tarot reader can't do math" \
  --personas "emma,mei-lin"

# Test image concept (pre-flight before generating with ad-composer)
bash scripts/audience-simulator.sh test \
  --brand pinxin-vegan \
  --content "Bold overhead shot of vegan nasi lemak, steam rising, dark green background" \
  --type image-concept

# Batch test multiple content variants from a file
bash scripts/audience-simulator.sh batch \
  --brand mirra \
  --input variants.txt

# A/B pre-test: compare two content options head-to-head
bash scripts/audience-simulator.sh compare \
  --brand mirra \
  --a "Try our calorie-controlled bento" \
  --b "Weight management has never tasted this good"

# Full campaign pre-test from a brief
bash scripts/audience-simulator.sh campaign \
  --brand jade-oracle \
  --brief campaign-brief.md
```

### Core F&B Brand Examples

These brands are P0 priority -- every ad should be simulated before budget is allocated.

```bash
# Test pinxin-vegan ad copy
bash scripts/audience-simulator.sh test --brand pinxin-vegan --content "Vegan nasi lemak that'll make you forget it's plant-based"

# Test pinxin-vegan campaign (A/B pre-test)
bash scripts/audience-simulator.sh compare \
  --brand pinxin-vegan \
  --a "Plant-based rendang, zero compromise" \
  --b "Your mak's rendang recipe, but vegan"

# Test wholey-wonder smoothie hook
bash scripts/audience-simulator.sh test --brand wholey-wonder --content "Your morning acai bowl, ready in 30 seconds"

# Test wholey-wonder protein positioning
bash scripts/audience-simulator.sh test --brand wholey-wonder --content "28g protein per bowl. No powder taste. Just real fruit and gains."

# Test gaia-eats delivery promo
bash scripts/audience-simulator.sh test --brand gaia-eats --content "50 restaurants, one app, delivered in 30 min"

# Test gaia-eats group order feature
bash scripts/audience-simulator.sh test --brand gaia-eats --content "Team lunch sorted — everyone picks their own, one delivery fee"

# Test dr-stan supplement ad
bash scripts/audience-simulator.sh test --brand dr-stan --content "Your daily vitamins, backed by clinical trials"

# Test dr-stan transparency angle
bash scripts/audience-simulator.sh test --brand dr-stan --content "Every ingredient, every dosage, every study — right on the label"

# Test rasaya wellness drink
bash scripts/audience-simulator.sh test --brand rasaya --content "Turmeric latte your grandmother would approve of"

# Test rasaya heritage positioning
bash scripts/audience-simulator.sh test --brand rasaya --content "Traditional jamu, modern standards. Same recipe your nenek trusted."

# Test serein self-care
bash scripts/audience-simulator.sh test --brand serein --content "Your evening ritual starts here"

# Test serein efficacy-first messaging
bash scripts/audience-simulator.sh test --brand serein --content "10 minutes. 3 products. Calm that actually works."
```

### Flags Reference

| Flag | Description | Default |
|------|-------------|---------|
| `--brand` | Brand name (must match DNA.json) | Required |
| `--content` | Content string to test | Required (or --input) |
| `--type` | Content type: `ad-copy`, `caption`, `image-concept`, `product-desc`, `email-subject`, `campaign` | `ad-copy` |
| `--personas` | Comma-separated persona names to test against (lowercase, hyphenated) | All brand personas |
| `--input` | Path to file with multiple variants (one per line or JSON array) | -- |
| `--brief` | Path to campaign brief markdown file | -- |
| `--output` | Custom output path | `~/.openclaw/workspace/data/audience-sim/{brand}/` |
| `--verbose` | Show full persona reasoning, not just scores | `false` |
| `--json` | Output as JSON instead of markdown | `false` |

---

## Output Report Format

### Markdown Report (default)

```markdown
# Audience Simulation Report
**Brand:** mirra | **Content type:** ad copy | **Date:** 2026-03-23

## Content Tested
> "Your weight management meals, delivered fresh daily. Order now."

## Persona Reactions

| Persona | Attention | Relevance | Emotion | Action | Overall | Key Feedback |
|---------|-----------|-----------|---------|--------|---------|--------------|
| Sarah, 32 | 7 | 9 | 6 | 7 | 7.3 | "Relevant but the CTA is generic -- I see 'order now' 50 times a day" |
| Aishah, 28 | 8 | 8 | 7 | 8 | 7.8 | "Would click, but where's the halal cert? I need to see JAKIM logo" |
| Michelle, 38 | 6 | 7 | 5 | 5 | 5.8 | "How much per meal? Is there a family plan? I'm feeding 4 people lah" |
| Priya, 26 | 5 | 6 | 4 | 4 | 4.8 | "So boring. Show me the food. Show me someone eating it. This is just words" |

## Aggregate Score: 6.4 / 10 -- REFINE

## Segment Breakdown
- **LOVE IT (>= 8):** None
- **NEUTRAL (5-7):** Sarah, Aishah, Michelle
- **TURNED OFF (< 5):** Priya

## Dimension Breakdown
- Attention: 6.5 avg (weakest for Priya -- no visual hook)
- Relevance: 7.5 avg (strongest dimension -- product-market fit is there)
- Emotion: 5.5 avg (too rational, no desire trigger)
- Action: 6.0 avg (CTA is generic, no urgency or specificity)

## Improvement Suggestions
1. **Add specific numbers** for Sarah and Aishah -- they track macros. "380 cal" or "32g protein" stops their scroll.
2. **Show halal cert** or mention JAKIM for Aishah -- this is non-negotiable, not a nice-to-have.
3. **Add family pricing** for Michelle -- "From RM12/meal, family plans available" converts her.
4. **Make it visual** for Priya -- this copy needs an image or video. Text-only won't work for her feed.
5. **Replace generic CTA** -- "Order now" is invisible. Try "Try your first week at RM10/meal" or "See this week's menu."

## Suggested Revision
> "380 cal bentos that actually taste like real food. JAKIM halal certified. KL delivery, fresh daily. Your lunch upgrade starts at RM12/meal. [See this week's menu]"

## Revised Score Estimate: 7.6 / 10 -- PASS
```

### JSON Report (with --json flag)

```json
{
  "brand": "mirra",
  "content_type": "ad-copy",
  "date": "2026-03-23",
  "content_tested": "Your weight management meals, delivered fresh daily. Order now.",
  "personas": [
    {
      "name": "Sarah",
      "age": 32,
      "scores": { "attention": 7, "relevance": 9, "emotion": 6, "action": 7 },
      "overall": 7.3,
      "segment": "neutral",
      "feedback": "Relevant but the CTA is generic",
      "suggestions": ["Add calorie count", "Replace generic CTA"]
    }
  ],
  "aggregate": {
    "overall": 6.4,
    "verdict": "REFINE",
    "by_dimension": { "attention": 6.5, "relevance": 7.5, "emotion": 5.5, "action": 6.0 }
  },
  "suggestions": ["Add specific numbers", "Show halal cert", "Add family pricing"],
  "revised_content": "380 cal bentos that actually taste like real food..."
}
```

---

## Integration Points

### Feeds INTO (this skill's output is used by):
- **auto-research** -- as the eval/scoring function in optimization loops
- **fast-iterate** -- persona scores drive iteration priority
- **content-supply-chain** -- pre-flight check before publishing

### Feeds FROM (this skill consumes output from):
- **campaign-planner** -- campaign briefs to pre-test
- **meta-ads-creative** / **ad-composer** -- ad copy and image concepts to score
- **brand-prompt-library** -- image concepts and visual direction to validate

### Auto-Research Integration

The audience-simulator replaces generic LLM-as-judge with persona-aware-LLM-as-audience:

```
auto-research generates variant
  --> audience-simulator scores it against brand personas
  --> score >= 7? keep variant : discard
  --> persona feedback feeds back into next variant generation
```

This is more realistic than a single LLM judge because it surfaces segment-specific failure modes (e.g., copy that works for fitness personas but alienates family personas).

---

## Malaysian Market Calibration

All persona behaviors are calibrated for Malaysia. The simulator accounts for:

- **Halal sensitivity** -- not just a preference, it's a deal-breaker for Muslim personas. JAKIM certification specifically (not generic "halal").
- **Price anchoring in RM** -- all pricing in Malaysian Ringgit. "RM12/meal" resonates, "$3/meal" does not.
- **Local purchase channels** -- Shopee, GrabFood, WhatsApp ordering. Not Amazon, not Uber Eats.
- **Manglish / code-switching** -- casual content in mixed English-Malay-Chinese resonates more than pure Queen's English for younger personas. "Sedap gila" > "Absolutely delicious."
- **WhatsApp as engagement channel** -- Malaysians don't DM on IG to buy. They WhatsApp. CTAs should point to WhatsApp, not "DM us."
- **Cultural calendar** -- persona behavior shifts around Hari Raya (Aishah/Siti spend more on food), CNY (Wei Ling/Aunty Lim prioritize family meals), Deepavali (Priya/Raj engage more with festive content).
- **Local reference points** -- Mamak, pasar malam, kopitiam, Jaya Grocer, Village Grocer, TTDI market. Not Whole Foods, not Trader Joe's.
- **Social proof dynamics** -- Malaysian consumers trust WhatsApp group recommendations and Xiaohongshu reviews over brand claims. Persona reactions factor in "would I share this in my group chat?"

---

## Output & Storage

- Reports saved to: `~/.openclaw/workspace/data/audience-sim/{brand}/`
- Filename format: `{brand}-{content-type}-{YYYY-MM-DD-HHmm}.md` (or `.json`)
- Historical reports enable trend analysis: "Is our MIRRA copy getting better over time?"

---

## Quality Gate

When audience-simulator is used as a gate (e.g., in content-supply-chain):

| Score | Verdict | Action |
|-------|---------|--------|
| >= 7.0 | **PASS** | Content approved for publishing/ad spend |
| 5.0 - 6.9 | **REFINE** | Apply suggestions, re-test before publishing |
| < 5.0 | **FAIL** | Fundamental mismatch -- go back to brief/strategy |

No content should go to paid ad spend without scoring >= 7.0 across brand personas.
