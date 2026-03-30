# MIRRA Ad Creative Strategy
## Reverse-Engineered from 28 Research Docs, Live Account Data, and Sales Intelligence

**Date:** 2026-03-14
**Purpose:** Every ad we build follows this playbook

---

## THE 5 LAWS (from research synthesis)

### Law 1: Creative is 70-80% of performance
Not budget, not targeting, not bidding. The ad itself determines success. (AppsFlyer 2025, Pilothouse, AG1's $600M spend)

### Law 2: Lo-fi destroys polished
- UGC-style: 4x higher engagement, 4.5x ROAS, 50% lower CPC
- EveryPlate's zero-budget 30-minute ad = their top earner for 1 year
- $5K on 50 raw concepts > $5K on 1 polished production
- iPhone-shot > $10K production shoot

### Law 3: CTWA is a different species
- 3x higher conversion than website ads
- 2 friction points vs 7 for website
- 95-98% open rate (vs 20% email)
- The ad starts a conversation, it doesn't close a sale
- CTA = "Chat us" not "Buy now"

### Law 4: The first 0.4 seconds decide everything
- Users see 1,500+ ads/day. 0.4 seconds to decide engage vs skip
- Pattern interrupt > pretty design
- Text-on-food or bold typography > subtle branding

### Law 5: Andromeda rewards diversity, punishes duplication
- Minor variations (color swap, headline swap) = SAME signal to Meta
- Need radically different angles, tones, formats, voices
- 10% hit rate is realistic — test 10 to find 1 winner
- Some winners run 500+ days without fatigue (AG1 data)

---

## THE 10 AD ARCHETYPES (priority order)

Based on what converts best for meal subscription + CTWA + Malaysian market:

### Priority 1: High-conversion formats (proven by data)

**Archetype 1: FAKE UI SCREENSHOT**
*Why:* 42% more effective than brand content. Feels like friend sharing, not advertising.
```
Formats:
A. Fake iMessage — "bestie" asking where lunch is from
B. Fake Apple Notes — meal plan / savings list
C. Fake Calculator — RM19 vs RM40 math
D. Fake Google Search — "healthy lunch KL under RM20"
E. Fake Screen Time — "45 min deciding what to eat"
```
*Mirra has:* EN A03 (iMessage), A07 (receipt), A08 (AirDrop), A09 (search), cat06 (24 UI templates)
*Build new:* Calculator, Notes app, Screen Time variants

**Archetype 2: FOOD HERO (45-degree, minimal text)**
*Why:* 45-degree = highest conversion angle. Warm background +18%. Zero text overlay = best reach.
```
Formats:
A. Single bento hero — 45-degree, warm cream bg, "RM19" price badge only
B. Macro close-up — extreme texture detail, sauce drip, steam
C. Overhead flat-lay — 4-5 bentos arranged, variety proof
```
*Color rule:* Cream/warm bg (#FFF5EE) NEVER pure white. NEVER blue.
*Mirra has:* EN A01, A02, CN V01, V03, V11, V14
*Build new:* Macro close-ups, flat-lay variety grid

**Archetype 3: PRICE COMPARISON / "THE MATH"**
*Why:* Loss aversion = #1 emotional trigger. Show expensive FIRST, then RM19.
```
Formats:
A. Receipt comparison — Grab RM38 receipt vs Mirra RM19 bento
B. Calculator breakdown — monthly savings RM242
C. Split screen — "what you pay" vs "what you get"
D. Stacked list — ✗ cooking (2hrs, RM30 groceries) vs ✓ Mirra (30sec, RM19)
```
*Mirra has:* EN A10 (split screen), A14 (binary choice)
*Build new:* Receipt comparison, calculator, stacked list

**Archetype 4: CAROUSEL STORY (5-card or 7-card)**
*Why:* Carousels cut CPC 20-30% and CPA 30-50%. 4.2x ROAS format. Mirra has ZERO carousels.
```
5-Card Sequence:
1. HOOK → Bold text, pattern interrupt ("Your RM40 lunch could be RM19")
2. PROBLEM → Sad desk lunch / expensive receipt
3. SOLUTION → Mirra bento hero shot
4. PROOF → "2,000+ KL professionals. 50+ rotating menu"
5. CTA → "First order 50% off. WhatsApp us"

7-Card Menu Showcase:
1. HOOK → "This week's menu just dropped"
2-6. Five different dishes (one per card, 45-degree, warm bg)
7. CTA → "Pick yours. Chat us on WhatsApp"
```
*Cards:* 1080×1080 (1:1). Disable auto-ordering for story sequences.
*Build:* mirra_carousel_batch.py — P0 priority

### Priority 2: Engagement + social proof formats

**Archetype 5: UGC / KOL TESTIMONIAL**
*Why:* UGC = 10x higher conversion. KOL Leann = RM0.41 CPC (best in account).
```
Formats:
A. KOL video (15-30s) — unboxing, taste reaction, recommendation
B. Text-over-UGC static — customer quote on real photo
C. WhatsApp screenshot — customer DM praising Mirra (blur name)
D. Star rating overlay — "4.9/5 from 1,200+ reviews" on food photo
```
*Mirra has:* Leann, ZiQian, Chris, Sunny, evelynsmem, Veggieeats KOL content
*Build new:* Commission 3-5 more KOLs. Text-over-UGC statics from reviews

**Archetype 6: FIRST-PERSON STORY ("I stopped cooking...")**
*Why:* First-person = +90% CTR vs second-person. Journey format = high engagement.
```
Formats:
A. "Day 30 of not cooking" — streak/journey
B. "I stopped cooking and this happened" — transformation
C. "My colleague made me try this" — third-party discovery
D. "I was skeptical too until..." — objection-first trust builder
```
*Copy pattern:* First-person hook → second-person CTA
*"I stopped cooking and saved RM200/month. You can too."*

**Archetype 7: TYPOGRAPHIC DOMINANT (bold text IS the creative)**
*Why:* Massive Chinese characters (50%+ canvas) = expensive/premium feel. Text-only on solid color = highest thumb-stop for cold audience.
```
Formats:
A. Single punchy line on solid warm color — "午餐不用想了"
B. Bold serif on food photo — "RM19" as hero element
C. List format — "things i stopped wasting money on:"
D. Hybrid handwritten — messy text overlay on casual food photo
```
*Mirra has:* CN V08, V10 (bold typography), cat08 (39 typographic quotes)
*Build new:* EN typographic variants, hybrid handwritten

### Priority 3: Conversion + urgency formats

**Archetype 8: SOCIAL PROOF EXPLOSION**
*Why:* Social proof ads = 300% increase in conversion. Ads with customer count = authority.
```
Formats:
A. Review bubbles around food hero shot
B. "2,400+ KL women already switched"
C. 4-5 review quotes in carousel
D. Star rating badge + subscriber count
```
*Use for:* MOFU and retargeting

**Archetype 9: URGENCY / OFFER**
*Why:* Urgency = #1 emotion in top-performing creative (AG1 AI analysis). Payday window is real.
```
Formats:
A. "Last 50 slots this week" — scarcity
B. "MIRRA50 expires Sunday" — deadline
C. "Payday treat: 50% off first order" — timing
D. "Chat us for the price not on the website" — WhatsApp-exclusive
```
*Use for:* BOFU and retargeting. Payday window (25th-3rd).

**Archetype 10: BEHIND-THE-SCENES / TRUST**
*Why:* Subscription = recurring trust. BTS builds it. CookUnity's chef-as-hero = 75% growth.
```
Formats:
A. Nutritionist designing menu (authority)
B. Kitchen prep process (quality proof)
C. Ingredient sourcing (premium signal)
D. "Meet Chef [name]" — human behind the food
```
*Use for:* Cold audience trust-building, retarget warm audience

---

## COPY BANK (ready to deploy)

### Primary text templates (first 125 chars = everything)

**PAS (Problem-Agitate-Solution) — COLD:**
1. "spending 2 hours cooking after a 10-hour day? by the time you're done, you're too tired to enjoy it. mirra delivers nutritionist-designed bentos from RM19. zero cooking. MIRRA50 for 50% off"
2. "你每天花RM80叫外卖 吃的也不健康。同样的钱可以吃4天mirra营养便当。50+菜式 营养师设计。首单半价 MIRRA50"

**BAB (Before-After-Bridge) — TESTIMONIAL:**
3. "i used to spend RM2,000/month on unhealthy grab orders. now i eat nutritionist-designed meals for half the price. mirra changed everything. MIRRA50 for 50% off first order"
4. "以前每天纠结午餐 现在30秒搞定。2个月瘦了3kg 同事都问我怎么做到的。是mirra。首单半价 MIRRA50"

**AG1 FRAMEWORK — SCALE WINNER:**
5. "mirra combines meal prep, calorie counting, and nutritionist planning into one weekly delivery with 50+ chef-crafted dishes. under RM19/meal. under 500 calories. delivered before noon. MIRRA50"
6. "mirra帮你解决meal prep + 算卡路里 + 营养规划。50+菜式 营养师设计 每餐低于RM19 低于500卡。中午前送到。MIRRA50 首单半价"

**FIRST-PERSON — ENGAGEMENT:**
7. "my RM19 lunch is better than your RM40 grab order and i'm not even sorry. 50+ dishes, nutritionist-designed, delivered to my desk. code MIRRA50 for 50% off"
8. "i stopped cooking lunch 2 months ago. lost 3kg without trying. saved RM400/month. my colleagues think i'm on some expensive diet plan. it's just mirra. RM19/meal. MIRRA50"
9. "同事天天看我的bento 偷偷去order了。50+菜式 低于600卡 从RM19起。MIRRA50 半价试试"

**CODE-SWITCH — MALAYSIAN MARKET:**
10. "午餐不知道吃什么？Low cal还这么好吃 order了再说lah。从RM19起 code MIRRA50"
11. "办公室三个人都在吃mirra了。nutritionist designed somemore。RM19 per meal only wor。try la MIRRA50 半价"

**SOCIAL PROOF — AUTHORITY:**
12. "2,400+ KL professionals eat mirra every week. 50+ rotating dishes. nutritionist-designed. from RM19. join them — MIRRA50 for 50% off"
13. "2,400+ KL上班族每周都在吃mirra。50+菜式 每周新菜单 营养师设计 从RM19起。MIRRA50 首单半价"

**LOSS AVERSION — THE MATH:**
14. "you spend RM660/month on grab food. mirra is RM418/month for nutritionist-designed meals. that's RM242 saved and 44 hours of cooking you never have to do. MIRRA50"
15. "grab午餐 RM38。自己煮 2小时+RM30食材。mirra便当 RM19 直接送到。你选哪个？MIRRA50 首单半价"

### Headlines (40 chars max)
- EN: "RM19 Bentos, Delivered Daily" / "50% Off Your First Order" / "50+ Dishes From RM19" / "Nutritionist-Designed Lunch" / "Stop Spending RM40 On Lunch"
- CN: "RM19营养便当 每日配送" / "首单半价 MIRRA50" / "50+菜式 从RM19起" / "营养师设计午餐" / "午餐只要RM19"

### Descriptions
- EN: "50+ dishes. Nutritionist-designed. Free delivery. Cancel anytime."
- CN: "50+菜式 营养师设计 免费配送 随时取消"

### CTA button
- CTWA: "Send WhatsApp Message" (default, cannot customize)

---

## PRODUCTION PLAN: 40 AD UNITS IN 4 BATCHES

### Batch 1: SCALE FUEL (March 17-19) — 12 ads
Deploy immediately using existing assets + fast production

| # | Archetype | Format | Lang | Asset source | Copy # |
|---|-----------|--------|------|-------------|--------|
| 1 | Fake UI | iMessage | EN | A03 refresh | 7 |
| 2 | Fake UI | Notes app | EN | NEW | 8 |
| 3 | Fake UI | Calculator | EN | NEW | 14 |
| 4 | Fake UI | iMessage | CN | cn-ads style | 9 |
| 5 | Food Hero | 45-deg single bento | EN | A02 refresh | 5 |
| 6 | Food Hero | Macro close-up | EN | NEW | 7 |
| 7 | Food Hero | Overhead flat-lay | CN | V14 refresh | 6 |
| 8 | Price Compare | Receipt vs bento | EN | NEW | 14 |
| 9 | Price Compare | Stacked list | CN | NEW | 15 |
| 10 | Typography | Bold single line | CN | V10 style | 10 |
| 11 | First-Person | "I stopped cooking" | EN | NEW | 8 |
| 12 | Social Proof | Star rating + count | EN | NEW | 12 |

### Batch 2: CAROUSEL LAUNCH (March 20-22) — 8 ads (5 carousels + 3 statics)

| # | Type | Cards | Angle |
|---|------|-------|-------|
| 13 | Carousel | 5 | Hook → Problem → Solution → Proof → CTA (EN) |
| 14 | Carousel | 5 | Menu showcase — 5 dishes of the week (EN) |
| 15 | Carousel | 5 | Hook → Problem → Solution → Proof → CTA (CN) |
| 16 | Carousel | 7 | Full funnel story (EN) |
| 17 | Carousel | 3 | Price comparison: Grab vs Cook vs Mirra (EN+CN) |
| 18 | Static | 1 | "Things I stopped wasting money on" Notes app (EN) |
| 19 | Static | 1 | "Day 30 of not cooking" journey (EN) |
| 20 | Static | 1 | WhatsApp screenshot — customer review (EN) |

### Batch 3: DIVERSITY PUSH (March 25-27) — 10 ads
Fill Andromeda diversity requirement — radically different angles

| # | Archetype | Format | Lang | Angle |
|---|-----------|--------|------|-------|
| 21 | BTS/Trust | Kitchen process | EN | Authority — nutritionist designing menu |
| 22 | BTS/Trust | Ingredient close-up | CN | Premium signal — fresh ingredients |
| 23 | Urgency | "Last 50 slots" | EN | Scarcity for BOFU |
| 24 | Urgency | "首单半价 本周日截止" | CN | Deadline for retarget |
| 25 | First-Person | "My colleague made me try" | EN | Third-party discovery |
| 26 | Social Proof | Review carousel | EN | 5 customer quotes |
| 27 | Typography | "RM19" as massive hero element | EN | Price as design |
| 28 | Comparison | Split screen: before/after lunch | EN | Lifestyle transform (Meta-safe) |
| 29 | Code-switch | Bilingual viral copy | MIX | "Low cal还这么好吃 order了再说lah" |
| 30 | Food Hero | Macro ASMR (steam/sauce) | EN | Sensory pattern interrupt |

### Batch 4: WINNERS VARIATION (April 1-3) — 10 ads
Take Batch 1-3 winners and create format variations

| # | Source winner | New format | Why |
|---|-------------|-----------|-----|
| 31-33 | Top static → Carousel | 5-card version | Test carousel lift on proven concept |
| 34-36 | Top carousel → Static | Extract best card as standalone | Scale in more placements |
| 37-38 | Top EN → CN adaptation | Same concept, CN copy | Language expansion |
| 39-40 | Top concept → Retarget variant | Different CTA + urgency | Fresh retarget creative |

---

## ANDROMEDA DIVERSITY CHECK

Each ad must differ in at least 1 of these 6 dimensions:

| Dimension | Values in our 40 ads |
|-----------|---------------------|
| Message frame | Price value, social proof, convenience, loss aversion, identity, trust, urgency |
| Authority | Brand, customer, nutritionist, KOL, data/numbers, peer |
| Proof type | Testimonial, statistic, visual demo, comparison, review screenshot |
| Voice | First-person, second-person, third-person, code-switch |
| Composition | UI screenshot, food hero, typography, split screen, carousel, flat-lay, macro |
| Format | Static 4:5, Carousel 1:1, Story 9:16 |

**7 × 6 × 5 × 4 × 6 × 3 = 15,120 possible combinations.** We only need 40. Zero overlap risk.

---

## VISUAL PRODUCTION RULES

### Food photography
- **Default angle:** 45-degree (70% of shots)
- **Variety shots:** Overhead flat-lay
- **Pattern interrupt:** Macro close-up (steam, texture, sauce)
- **Background:** Cream/warm (#FFF5EE) NEVER pure white, NEVER blue
- **Props:** Minimal — chopsticks, napkin, desk context. NOT styled studio
- **Food source:** Variety Dishes Mirra library ONLY (ZERO AI food)

### Typography
- Bold, expensive-looking fonts (Spiritual Gangster / Nastygal energy)
- Chinese: massive characters 50%+ canvas = premium
- English: lowercase informal = brand voice ("my lunch" not "MY LUNCH")
- Price "RM19" always prominent — either hero element or clear badge

### Color palette
- Blush (248,190,205) — backgrounds
- Dusty rose (235,170,185) — accents
- Crimson (172,55,75) — CTA buttons, price badges (+21-34% CTR on red CTA)
- Cream (255,245,238) — food photo backgrounds
- Black/near-black — text on light backgrounds

### Post-processing (from god mode OS)
- AI output → resize to 1080×1350 (static) or 1080×1080 (carousel) → grain (0.014-0.018) → DONE
- NO heavy filters. NO logo stamp if AI rendered branding. Photography IS the aesthetic.

### Meta safe zones (4:5 feed)
- Top 14% (~150px): keep clean for Meta labels
- Bottom 20% (~270px): keep clean for CTA button
- All critical content in middle 66%

---

## TESTING PROTOCOL

### Launch cadence
- **Monday + Thursday:** New creatives launch
- **Wednesday + Saturday:** Kill round

### Kill criteria
| Timeframe | Kill if |
|-----------|---------|
| 24 hours | CTR < 0.5% |
| 3 days | Cost/WA > RM12 AND spend > RM100 |
| 7 days | Cost/WA > RM10 AND spend > RM200 |

### Scale criteria
| Metric | Action |
|--------|--------|
| Cost/WA < RM7 for 5 days | Move to SCALE via Post ID |
| Cost/WA < RM5 sustained | Increase 20% every 24h |
| Carousel > static ROAS | Shift 30% more budget to carousel |

### Weekly creative review
1. Rank all ads by cost/WA message
2. Top 5 → what do they have in common? (archetype, copy, format, language)
3. Bottom 5 → what pattern? Kill pattern, not just individual ads
4. Missing archetype → test next week
5. Frequency > 2.0 → rotate creative, not audience

---

## WHATSAPP CONVERSATION FLOW (CTWA-SPECIFIC)

### Pre-filled message (user sends):
"Hi! I saw the RM19 bento deal 🍱"

### Auto-greeting (instant):
```
hey babe ✨ welcome to mirra

what sounds good this week?
we've got 50+ dishes, all under 500 cal, from RM19/meal

[Quick Reply: Show me the menu]
[Quick Reply: How does it work?]
[Quick Reply: I want to order]
```

### If "Show me the menu":
Send menu PDF/link + "anything catch your eye?"

### If "How does it work":
```
super easy 💕

1. pick your meals (5, 10, or 20 per week)
2. we prep fresh + deliver before noon
3. open, eat, done. zero cooking

first order is 50% off with code MIRRA50
want to try?
```

### If no reply (2 hours):
"still thinking? no pressure — here's 50% off your first order: MIRRA50 💕"

### If no reply (7 days):
"hey — your 50% off code expires this Sunday. just wanted to make sure you didn't miss it 💕"

### Quick reply buttons convert 3-5x higher than open-ended questions.

---

## KEY NUMBERS TO REMEMBER

| Metric | Number | Source |
|--------|--------|--------|
| Creative = % of performance | 70-80% | AppsFlyer 2025 |
| UGC vs polished ROAS lift | 4.5x | Emplifi Q3 2025 |
| Carousel CPA reduction | 30-50% | Meta/Pilothouse |
| CTWA vs website conversion | 3x higher | Multiple sources |
| Red CTA CTR lift | 21-34% | Psychology research |
| Warm bg vs white lift | 18% | Food ad A/B tests |
| First-person vs second-person CTR | +90% | Copy A/B tests |
| Social proof conversion lift | 300% | Meta data |
| Price anchor (show expensive first) | Proven | Behavioral econ |
| Malaysian CPC vs US | 75% cheaper | Market data |
| AG1 winner longevity | 500+ days | Public data |
| Hit rate on new concepts | 10% | Industry standard |
