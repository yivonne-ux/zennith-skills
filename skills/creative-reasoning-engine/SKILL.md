---
name: creative-reasoning-engine
description: 5-step concept birth process for ad creative and content. Persona audit → format hijack → concept collision → hook psychology → diversity gate. Produces scroll-stopping concepts, not random brainstorms.
agents:
  - dreami
  - scout
---

# Creative Reasoning Engine — Concept Birth Process

The missing layer between "we need ads" and a specific concept like "horoscope card ad" or "Tinder swipe comparison." Hooks are DISCOVERED from data, not invented from brainstorming. Formats are HIJACKED from the persona's daily life.

Proven at Mirra: RM2.18M revenue, 100+ ad variants/month, concepts like Sales Boom Boom (12-month winner), receipt haul, calculator savings, Tinder swipe.

## When to Use

- Before ANY new ad campaign or content batch
- When creative output feels "template-y" or predictable
- When ROAS is declining (creative fatigue)
- When launching a new brand or entering a new market
- When Dreami needs fresh concepts (not just new variants of old concepts)

## The 5-Step Chain

### Step 1 — Persona Behavioral Audit

**Question:** What does this person interact with DAILY — apps, objects, content, emotions?

Load the brand's target persona. For each persona, map:

| Dimension | What to Map | Example (Mirra: OL-SED) |
|-----------|-------------|------------------------|
| Apps | What's on her home screen? | Grab, XHS, Instagram, WhatsApp, Notes, Calculator |
| Objects | What's on her desk/bag? | Bento box, water bottle, phone, lipstick, receipt |
| Content | What does she scroll? | Food content, OOTD, wellness, horoscopes, memes |
| Emotions | What does she feel at noon? | Hungry, stressed, guilty (grabbed Grab again), tired |
| Rituals | What does she do at specific times? | 11:30 AM hunger pang, 12 PM Grab ordering, 3 PM snack |
| Pain points | What frustrates her repeatedly? | "Healthy food is expensive", "No time to cook", "Gaining weight" |
| Language | What exact words does she use? | Mine from Reddit, XHS, TikTok comments, reviews |

**Output:** Persona behavioral map with 7 dimensions filled.

```bash
# Scout mines real language from platforms
bash ~/.openclaw/skills/content-scraper/scripts/instagram-scan.sh --hashtag "healthylunchkl" --count 50
bash ~/.openclaw/skills/xhs-scraper/scripts/xhs-scrape.sh search "减肥午餐" --count 30
```

### Step 2 — Format Library Cross-Reference

**Question:** Which familiar visual formats match her daily interactions?

Cross-reference persona behaviors with format categories:

| Category | Formats | When It Works |
|----------|---------|---------------|
| **UI Mimicry** | iPhone Notes, Calculator, Search bar, Tinder, WhatsApp chat, Shopee cart, Grab order, Calendar, Health app, Maps | She uses these apps daily — instant recognition |
| **Physical Objects** | Receipt, Boarding pass, Magazine cover, Prescription, Shopping bag, Nutrition label, Gym card | Tangible objects she touches — physical = trustworthy |
| **Cultural** | Horoscope card, Fortune cookie, Red packet, Wedding invite, Report card | Cultural touchpoints — emotional resonance |
| **Editorial** | Magazine spread, Newspaper front page, Book cover, Poster, Billboard | Authority + premium feel |
| **Data** | Infographic, Chart, Comparison table, Before/after, Timeline, Scoreboard | Logic + proof — for skeptics |
| **Social** | DM screenshot, Comment thread, Group chat, Story reply, Poll result | Social proof + FOMO |

**Output:** 5-8 format candidates ranked by persona fit.

### Step 3 — Concept Collision

**Formula:**
```
[Persona behavior] + [Familiar format] + [Brand benefit reframed] = CONCEPT
```

Generate 10-15 collisions. For each:

| Field | What | Example |
|-------|------|---------|
| Behavior | What she's doing | "Checking horoscope on XHS" |
| Format | Visual structure | "Astrology card with zodiac imagery" |
| Benefit | Brand reframed into format | "Lunch benefit categories as fortune readings" |
| Concept name | 3-word title | "Horoscope Lunch Card" |
| Hook line | Scroll-stop text | "Your zodiac says you should eat this today" |
| Share trigger | Why she'd share | Identity ("that's SO me"), Humor, Useful |

**Output:** 10-15 concept collisions with hook lines.

### Step 4 — Hook Psychology Check

Every concept MUST trigger at least 1 of these 7 psychology levers:

| Lever | What It Does | Example |
|-------|-------------|---------|
| **Pattern Interrupt** | Breaks scroll autopilot | Familiar UI in unexpected context |
| **Curiosity Gap** | Opens a loop that needs closing | "You won't believe what your zodiac says about lunch" |
| **Identity Confirmation** | "That's so me!" | Persona sees herself in the ad |
| **FOMO** | Fear of missing out | "Everyone in your office is ordering this" |
| **Value Shock** | Price seems impossible | "RM17 for THIS?!" |
| **Recognition** | Sees familiar format | iPhone Notes screenshot = instant trust |
| **Voyeurism** | Peek into someone's life | "What's in her lunchbox?" |

Score each concept: how many levers does it trigger? **Minimum 2 to proceed.**

**Output:** Concepts scored 1-7 on hook psychology. Kill anything < 2.

### Step 5 — Diversity Gate (Andromeda Rule)

Meta's Andromeda algorithm suppresses ads with >60% visual similarity. Every concept must differ from existing active ads in **4+ of 7 dimensions:**

| Dimension | What Changes |
|-----------|-------------|
| 1. Visual structure | Layout type (UI vs editorial vs photo vs data) |
| 2. Color dominant | Primary background color |
| 3. Format ratio | 4:5 vs 9:16 vs 1:1 |
| 4. Copy angle | Pain vs aspiration vs social proof vs humor |
| 5. Persona focus | Which persona segment |
| 6. Product emphasis | Which product/benefit featured |
| 7. CTA mechanism | Comment vs link vs WhatsApp vs save |

**Score each concept against all currently running ads.** If similarity > 60% in any pairing → KILL or MODIFY.

**Output:** Final 6-10 concepts that pass diversity gate. Ready for production.

## Procedure Summary

```
INPUT: Brand name + campaign goal + target persona

STEP 1: Load persona → Map 7 behavioral dimensions
STEP 2: Cross-reference with 6 format categories → 5-8 candidates
STEP 3: Collision sprint → 10-15 concepts with hooks
STEP 4: Psychology score → Kill < 2 levers
STEP 5: Diversity gate → Kill > 60% similarity to active ads

OUTPUT: 6-10 production-ready concepts with:
  - Concept name
  - Format type + reference direction
  - Hook line
  - Psychology levers triggered
  - Share trigger
  - Diversity score vs active ads
```

## Integration with Production Pipeline

After CRE produces concepts:
1. **Reference sourcing** → Find/scrape format-specific refs for each concept
2. **Brief generation** → campaign-planner creates structured briefs
3. **Image generation** → NanoBanana with edit-first technique + format-specific ref
4. **Copy generation** → fast-iterate with PAS framework
5. **QA** → humanizer + brand-voice-check + diversity recheck
6. **Publish** → social-publish or Meta Ads Manager

## Key Constraints

- NEVER start with "what should we make" — start with "what does she interact with daily"
- NEVER reuse format-ref combos within the same batch
- NEVER skip the diversity gate — Andromeda will punish you
- Always mine REAL language from platforms (Reddit, XHS, TikTok comments) — not invented copy
- Refresh format library every 2 weeks (new app trends, seasonal formats)
- This skill runs BEFORE campaign-planner, not after
