# Pinxin Dual-Channel Strategy — Website + WhatsApp
> Based on forensic analysis of all campaign data (Mar 15-22, 2026)
> Updated: 2026-03-22

---

## THE CORE INSIGHT

Website and WhatsApp are TWO SEPARATE businesses with different buyer psychology:

| | Website | WhatsApp |
|---|---|---|
| **Buyer type** | Self-serve, confident, knows what they want | Needs guidance, wants to ask questions, relationship-driven |
| **What converts** | Promo/urgency, price comparison, format hijack | Food photos, social proof, video (EGC), MOFU content |
| **Conversion path** | See ad → click → browse → cart → checkout | See ad → click WA → chat → trust → order |
| **Tracking** | Meta pixel (accurate, real-time) | Google Sheet (manual, delayed 1-3 days) |
| **AOV** | ~RM155 (pixel data) | ~RM165 (sheet data) |
| **Revenue share** | ~40% | ~60% (the bigger channel) |

---

## CAMPAIGN ARCHITECTURE

### Campaign 1: PX-Website-LowestCost-Test (ACTIVE)
- **Objective:** OUTCOME_SALES (Purchase)
- **ID:** 120240872763100006
- **Budget:** RM300/day
- **Bid:** Lowest Cost
- **Ad set:** 120240872766570006

**Current winners:**
| Ad | CPA | ROAS | 7d Purchases | Why it works |
|---|---|---|---|---|
| BOFU-10 Raw Lofi | RM20 | 6.6x | 2 | Authentic, phone-quality, feels like a friend |
| BOFU-18 Boarding Pass | RM49 | 2.7x | 1 | Format hijack — pattern interrupt |
| BOFU-06 Collection | RM60 | 2.2x | 1 | Shows variety, reduces choice anxiety |
| TNG-PROMO | RM33 (today) | 4.8x | 5 (today) | Specific offer + payment urgency |

**What works here:** BOFU with clear pricing, format hijack, raw/lofi, promo urgency
**What doesn't work:** Food hero photos (0 ATC), TOFU/HUMAN (0 ATC), MOFU (0 ATC)

**Active ads to KEEP (converters + high ATC):**
- PX-TNG-PROMO-LC ← today's star
- PX-BOFU-10-LC ← best CPA overall
- PX-BOFU-18-LC ← format hijack
- PX-BOFU-06-LC ← collection
- PX-BOFU-05-LC ← 23 ATC (checkout issue, not ad issue)
- PX-BOFU-03-LC ← 12 ATC, still learning
- PX-BOFU-02-LC ← receipt format, proven in TROAS

**Ads to PAUSE (no signal after RM20+ spend):**
- All FOOD ads ← 0 ATC on website, kill here
- All TOFU ads ← 0 ATC on website, move to WA campaign
- All HUMAN ads ← 0 signal, move to WA campaign
- BOFU-17, BOFU-01, BOFU-04, BOFU-09, BOFU-11, BOFU-13, BOFU-15, BOFU-16, BOFU-19 ← <RM10 spend, 0 signal

**NEW creatives needed for Website:**
1. More Raw Lofi variations (BOFU-10 DNA: RM20 CPA)
   - Same casual phone-photo style, different dishes
   - Food must blend INTO the scene (not pasted on top)
2. More Promo/Urgency (TNG-PROMO DNA: RM33 CPA)
   - Current promotion with specific offer
   - Different urgency angles (limited time, limited stock, payday special)
3. More Format Hijack (BOFU-18 DNA: RM49 CPA)
   - Week 2 ads already uploaded (parking saman, medical report, grab comparison, etc)
   - Monitor performance over 48 hours
4. Collection/Variety (BOFU-06 DNA: RM60 CPA)
   - Different dish groupings, different visual layouts

---

### Campaign 2: PX-CTWA-SALES-2026 (ACTIVE)
- **Objective:** OUTCOME_SALES (with CONVERSATIONS optimization)
- **ID:** 120240934632520006
- **Budget:** RM400/day
- **Bid:** Lowest Cost
- **Ad set:** 120240934633060006

**Current performance:**
| Ad | Spend | WA Convos | $/Convo | WA Sales (Sheet) |
|---|---|---|---|---|
| FOOD-02 (Namyu Tofu) | RM130 | 9 | RM14 | — |
| BOFU-08 (Bold Price) | RM118 | 7 | RM17 | ✅ 1 sale (RM130) |
| BOFU-02 (Receipt) | RM75 | 3 | RM25 | — |
| TOFU-04 (Family Feast) | RM47 | 1 | RM47 | — |
| FOOD-04 (Black Vinegar) | RM41 | 5 | RM8 | — |
| BOFU-05 (Golden Reveal) | RM33 | 2 | RM16 | — |
| BOFU-06 (Collection) | RM26 | 1 | RM26 | — |
| FOOD-03 (Spicy Asam) | RM5 | 1 | RM5 | — |

**What works here:** Food photos (FOOD-02, FOOD-04 = RM8-14/convo), BOFU with price
**Key difference from Website:** FOOD ads that FAIL on website SUCCEED on WhatsApp

**Ads to ADD from old WA winners:**
1. EGC PROMO SHORTS + TNG Day (creative: 949392527583633) ← 4 WA sales, RM629
2. MOFU -初一十五不知道该吃什么素 (creative: 798740166613503) ← RM8/convo, 51 convos
3. MOFU 吃素不想吃"素料" (creative: 945648507990563) ← RM8/convo, 14 convos

**NEW creatives needed for WhatsApp:**
1. More FOOD photos — food hero works for WA because people want to see the dish before chatting
   - FOOD ads killed from website campaign → MOVE HERE
   - Different dishes, different plates, warm styling
2. More MOFU social proof — testimonials, checklist, family WhatsApp group
   - MOFU-01 (Notes confession), MOFU-04 (WA group chat) → add here
3. Video (EGC) — the #1 WA converter was a video ad
   - Short-form video showing food preparation/unboxing
   - EGC-style (employee/customer generated content)
4. TOFU curiosity hooks — TOFU-01 (Incoming Call), TOFU-04 (Family Feast)
   - Not for purchase — for starting conversations

---

### Campaign 3: Retarget (ACTIVE but low volume)
- **ID:** 120240686358240006
- **Budget:** RM100/day
- **Status:** Keep at current budget, monitor

---

### Campaign 4: ZEN Cost Cap (ACTIVE but not spending)
- **ID:** 120239703308610006
- **Status:** Not spending today. CBO allocating to old ad set.
- **Action:** Monitor. If still RM0 tomorrow, investigate.

---

## CREATIVE PRODUCTION PLAN

### For Website (Lowest Cost campaign)

| Priority | Concept | Format DNA | Dish | Status |
|---|---|---|---|---|
| 1 | Promo urgency (current offer) | TNG-PROMO DNA | Multiple | Need to create |
| 2 | Raw Lofi — BKT | BOFU-10 DNA | BKT | Generated, needs fix (scene blend) |
| 3 | Raw Lofi — Green Curry | BOFU-10 DNA | Green Curry | Generated, needs fix |
| 4 | Raw Lofi — Sambal Petai | BOFU-10 DNA | Sambal | Generated, needs fix |
| 5 | Week 2 format hijacks | Various | Various | Uploaded, learning |

### For WhatsApp (CTWA-SALES campaign)

| Priority | Concept | Why | Status |
|---|---|---|---|
| 1 | Add EGC PROMO SHORTS | 4 WA sales proven | Ready — copy creative |
| 2 | Add MOFU 初一十五 | RM8/convo, 51 conversations | Ready — copy creative |
| 3 | Add MOFU 吃素不想吃素料 | RM8/convo, 14 conversations | Ready — copy creative |
| 4 | Move FOOD ads from website | FOOD works on WA, not website | Ready — copy creatives |
| 5 | Move TOFU/HUMAN from website | Better for conversations than purchases | Ready — copy creatives |
| 6 | New food photography ads | Fresh food content for WA | Need to create |
| 7 | Short video ads | Video = #1 WA converter | Need to create |

---

## BUDGET ALLOCATION

| Campaign | Daily Budget | Expected |
|---|---|---|
| Website Lowest Cost | RM300 | 6-10 purchases/day at RM30-60 CPA |
| WA CTWA-SALES | RM400 | 20-25 WA conversations at RM16-20/convo |
| Retarget | RM100 | Catch cart abandoners |
| ZEN (if revives) | RM300 | Cost Cap backup |
| **Total** | **RM1,100** | |

---

## MEASUREMENT

### Website — Meta Pixel (real-time)
- CPA target: <RM80
- ROAS target: >2.5x
- Kill: CPA >RM120 after 7 days

### WhatsApp — Google Sheet (delayed 1-3 days)
- Cost/convo target: <RM20
- Conversion rate target: >20% of conversations → orders
- Kill: >RM50/convo after 7 days AND 0 sheet sales
- **CRITICAL:** Check Google Sheet BEFORE killing WA ads. Meta shows 0 purchases but sheet may show sales.

### Combined True ROAS
- Total ad spend / (Shopify revenue + WA sheet revenue)
- Target: >2.5x combined
- Current: RM8,447 spend / (RM5,521 pixel + RM10,655 sheet) ≈ 1.9x (improving)

---

## NEXT ACTIONS (in order)

1. ☐ Add 3 old WA winners to PX-CTWA-SALES-2026 (EGC, 2 MOFUs)
2. ☐ Move FOOD/TOFU/HUMAN ads from website → WA campaign
3. ☐ Pause non-performing website ads (keep only converters + high ATC)
4. ☐ Fix 3 Lofi ads (scene integration) → review → upload to website campaign
5. ☐ Create 2-3 new promo urgency ads (current offer) for website
6. ☐ Monitor Week 2 format hijacks (48 hours)
7. ☐ Cross-reference Google Sheet daily for WA attribution
8. ☐ Day 7 (Mar 24): Full kill/scale round on both campaigns
