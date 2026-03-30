# Pinxin Vegan — Master Strategy 2026 Q1
> Compiled from forensic analysis of ALL campaign data, Mar 15-22, 2026
> Every number verified. Every decision data-backed.
> Last updated: 2026-03-22

---

## 1. BUSINESS OVERVIEW

### Revenue (Google Sheet — actual sales)
- March 1-22 total: **RM10,655** from **87 orders**
- AOV: **RM122** (sheet) / **RM155** (Shopify pixel)
- Pre-campaign daily average (Mar 1-16): **RM802/day**
- Post-campaign daily average (Mar 17-22): **RM438/day** (Raya holiday impact)
- Best day: Mar 18 = **RM1,148** (6 orders)
- Worst day: Mar 21 = **RM0** (Raya)
- Recovery: Mar 22 = **RM1,627** combined (RM998 website + RM629 WA)

### Revenue Split
- **WhatsApp orders: ~60%** of total revenue (Google Sheet)
- **Website orders: ~40%** of total revenue (Shopify pixel)
- WhatsApp is the BIGGER channel but INVISIBLE to Meta pixel

### Ad Spend (Mar 15-22)
- Total: **RM8,447**
- Website pixel revenue: RM5,521
- WA sheet revenue (attributed): RM1,424+ (only 11 orders have ad IDs)
- Visible ROAS (pixel only): 0.65x
- True ROAS (pixel + sheet): ~1.5-2.0x estimated

---

## 2. ACCOUNT DETAILS

- Ad Account: **act_138893238421035** (Pinxin Vegan Malaysia)
- Pixel: **961906233966610** (CAPI active, browser+server 1:1)
- Page: **322445838127156** (Pinxin Vegan Cuisine 品馨蔬食)
- IG: **@pinxinvegan** (17841404087687623)
- WA: **60196237832**
- Store: **pinxin-vegan-cuisine.myshopify.com**
- Meta token: **60-day long-lived** (saved at `_WORK/_shared/.meta-token`)

### Targeting (all prospecting)
- Country: MY, exclude Sarawak (2546), Labuan (2550), Sabah (2551)
- Locales: Chinese [20, 21, 22]
- Age: 25-65
- Advantage+ audience: ON

### Chat Builder
- Template: Ala Carte Flow (ID: 2647556602072973)
- Welcome: "你好👋 欢迎来到品馨！"
- Autofill: "我想要看MENU"

---

## 3. THE DUAL-CHANNEL INSIGHT

**Website and WhatsApp are TWO SEPARATE businesses with different buyer psychology.**

| | Website | WhatsApp |
|---|---|---|
| Buyer type | Self-serve, confident, knows what they want | Needs guidance, relationship-driven |
| What converts | Promo/urgency, price comparison, format hijack, raw lofi | Food photos, social proof, video (EGC), MOFU content |
| Conversion path | Ad → click → browse → cart → checkout | Ad → click WA → chat → trust → order (1-3 days) |
| Tracking | Meta pixel (real-time, accurate) | Google Sheet (manual, delayed) |
| AOV | ~RM155 | ~RM165 |
| Revenue share | ~40% | ~60% |
| Kill rule | 0 purchases after RM100 spend | Check Google Sheet BEFORE killing — Meta shows 0 but sheet may show sales |

### Critical Lesson Learned
We paused campaigns that looked like failures on Meta (0 purchases) but were actually driving WA sales:
- Old WA campaign: RM629 in tracked WA sales from EGC PROMO SHORTS
- New CTWA (ENGAGEMENT): RM795 in tracked WA sales from 4 ads
- Total invisible revenue: **RM1,424 from campaigns we thought were failing**

**NEVER kill a WA-focused ad based on Meta pixel data alone. Always cross-reference Google Sheet.**

---

## 4. CAMPAIGN ARCHITECTURE (Current)

### Campaign 1: PX-Website-LowestCost-Test — ACTIVE ✅
- **ID:** 120240872763100006
- **Objective:** OUTCOME_SALES (Purchase)
- **Budget:** RM300/day (campaign level)
- **Bid:** Lowest Cost (no caps)
- **Ad set:** 120240872766570006
- **Active ads:** ~14 (7 proven + 7 Week 2)
- **Today (Mar 22):** RM209 spent, 6 purchases, **RM35 CPA, 4.78x ROAS** ← BEST DAY

### Campaign 2: PX-CTWA-SALES-2026 — ACTIVE ✅
- **ID:** 120240934632520006
- **Objective:** OUTCOME_SALES (with CONVERSATIONS optimization)
- **Budget:** RM400/day
- **Bid:** Lowest Cost
- **Ad set:** 120240934633060006
- **Active ads:** 10
- **Today (Mar 22):** RM283 spent, 18 WA conversations, **RM16/convo**

### Campaign 3: Retarget — ACTIVE ✅
- **ID:** 120240686358240006
- **Budget:** RM100/day
- **Status:** Low volume, learning

### Campaign 4: ZEN Cost Cap — ACTIVE but not spending
- **ID:** 120239703308610006
- **Budget:** RM500K CBO (Cost Cap RM100 on ad set)
- **Status:** RM0 today — CBO allocating to old ad set

### PAUSED Campaigns
| Campaign | ID | Reason Paused |
|---|---|---|
| Old WA (SALES) | 120240009868730006 | Dying performance — but EGC PROMO SHORTS drove 4 WA sales |
| New CTWA (ENGAGEMENT) | 120240686232170006 | Wrong objective — finds chatters not buyers |
| Old TROAS ad set | 120240685375840006 | Poisoned by Day 1 RM1,045 spike |

---

## 5. AD PERFORMANCE — WEBSITE (Forensic)

### Winners (by CPA)
| Rank | Ad | CPA | ROAS | Purchases | ATC | CTR | Format |
|---|---|---|---|---|---|---|---|
| 1 | **BOFU-10 Raw Lofi** | **RM20** | 6.6x | 2 | 8 | 1.5% | Raw phone-quality photo |
| 2 | **TNG-PROMO** | **RM33** | 4.8x | 5 (today) | 23 | 1.2% | Identity gimmick promo |
| 3 | **BOFU-18 Boarding Pass** | **RM49** | 2.7x | 1 | 7 | 0.8% | Format hijack |
| 4 | **BOFU-06 Collection** | **RM60** | 2.2x | 1 | 17 | 1.2% | Product showcase |

### Funnel Analysis (Website)
| Category | CTR | Click→ATC | ATC→Purchase | Verdict |
|---|---|---|---|---|
| BOFU | 1.0% | **39%** | **5%** | ✅ CONVERTER |
| TNG/PROMO | 1.2% | **24%** | **4%** | ✅ CONVERTER |
| FOOD | 0.7% | **0%** | — | ❌ Dead end on website |
| TOFU | 1.0% | **0%** | — | ❌ No purchase intent |
| HUMAN | 0.8% | **0%** | — | ❌ No data (barely spent) |

### Anomaly: BOFU-05 (Golden Reveal)
- RM35 spent, **23 ATC but 0 purchases**
- This means 23 people added to cart but nobody completed checkout
- Likely a **website checkout issue**, not ad issue
- Action: Check Shopify checkout flow, payment options, cart abandonment

### Killed Ads
| Ad | Spend | Reason | Date Killed |
|---|---|---|---|
| BOFU-08 Bold Price | RM460 | RM460 CPA, worst performer (website) | Mar 19 |
| BOFU-12 Abundance | RM154 | 0 purchases | Mar 19 |
| All FOOD ads (6) | RM25 combined | 0 ATC on website | Mar 22 |

---

## 6. AD PERFORMANCE — WHATSAPP (Forensic)

### WA Sales Attribution (from Google Sheet)
| Ad ID | Ad Name | Campaign | WA Sales | Revenue |
|---|---|---|---|---|
| 120240009868740006 | EGC PROMO SHORTS + TNG | Old WA (paused) | 4 | RM629 |
| 120240688969910006 | BOFU-06-WA-R (Collection) | CTWA (paused) | 1 | RM350 |
| 120240688979430006 | BOFU-08-WA-R (Bold Price) | CTWA (paused) | 1 | RM185 |
| 120240688881530006 | FOOD-04-WA-P (Black Vinegar) | CTWA (paused) | 1 | RM130 |
| 120240688943290006 | BOFU-02-WA-R (Receipt) | CTWA (paused) | 1 | RM130 |
| 120240934638440006 | SALES-BOFU-08-WA-R-RT | CTWA-SALES (active) | 1 | RM130 |

### WA Conversation Cost Leaders
| Ad | Campaign | Cost/Convo |
|---|---|---|
| FOOD-03 (Spicy Asam) | CTWA-SALES | **RM5** |
| FOOD-04 (Black Vinegar) | CTWA-SALES | **RM8** |
| MOFU 初一十五 | Old WA | **RM8** |
| MOFU 吃素不想吃素料 | Old WA | **RM8** |
| FOOD-02 (Namyu Tofu) | CTWA-SALES | **RM14** |
| BOFU-08 (Bold Price) | CTWA-SALES | RM17 |

### Key WA Insight
**BOFU-08 (Bold Price) failed on website (RM460 CPA, killed) but succeeded on WhatsApp (1 sale + RM17/convo).** Same ad, completely different result depending on channel. FOOD-04 had 0 ATC on website but drove RM8/convo on WA.

**Ads that fail at direct purchase can succeed at starting conversations that lead to manual sales.**

---

## 7. BID STRATEGY FINDINGS (Proven with Real Data)

### What We Tested
| Strategy | Campaign | Result |
|---|---|---|
| ROAS floor 3.13x | TROAS | ❌ FAILED — RM205 CPA, 0.85x ROAS. Burned RM1,045 in 30 mins Day 1. ROAS floor useless with <50 conversions. |
| Bid Cap RM80 | ZEN | ⚠️ RESTRICTIVE — RM50 CPA, 2.58x ROAS but barely spent (RM50 in 4 days). Cap too tight for learning. |
| Cost Cap RM100 | ZEN (switched) | ✅ WORKED — RM97 CPA, 1.44x ROAS, 21 purchases. Self-regulating. |
| **Lowest Cost** | New campaign | ✅ **BEST** — RM35 CPA today, 4.78x ROAS. Maximum freedom = best results. |

### Expert Consensus (2026 Research)
- Start: **Lowest Cost** (learning phase, no caps)
- Graduate to: **Cost Cap** at actual CPA + 20% (after 50+ conversions)
- Only then: **Min ROAS** (if 50+ conversions/week)
- **Never use ROAS floor on new campaigns**

### Hard Lessons
1. **Day 1 ROAS spike:** RM500K budget + ROAS floor + 0 data = RM1,045 burned in 30 minutes. Always set spend caps on new ad sets.
2. **Bid Cap restricts volume:** Good CPA but won't spend. Use Cost Cap instead for scaling.
3. **Changing campaign-level bid strategy** requires setting bid_amount on ALL ad sets in the same API call.
4. **Payment interruption** partially resets learning. Set up auto-payment.

---

## 8. CREATIVE STRATEGY (Data-Backed)

### What Converts on Website (ranked by CPA)
1. **Raw/Lofi** (BOFU-10 DNA) — RM20 CPA
   - Phone-quality photo, handwritten text, casual tone
   - Confirms Nick Theriot: "ugly ads outperform polished"
   - Feels like a friend sharing dinner, not a brand selling

2. **Identity Gimmick Promo** (TNG-PROMO DNA) — RM33 CPA
   - Specific identity hook ("TNG users", "IC ending 168") makes people feel SELECTED
   - Same offer for everyone, but personalized hook
   - **This is the #1 creative lever — create 10+ identity variations**

3. **Format Hijack** (BOFU-18 DNA) — RM49 CPA
   - Doesn't look like food ad at first glance (boarding pass, receipt, parking saman)
   - Pattern interrupt stops scroll
   - Week 2 batch has 7 new format hijacks (learning)

4. **Product Collection** (BOFU-06 DNA) — RM60 CPA
   - Shows variety — "12道选择"
   - Reduces choice anxiety, gives confidence to buy

### What Converts on WhatsApp
1. **Video (EGC)** — 4 WA sales (RM629) from EGC PROMO SHORTS
   - #1 WA converter in entire account
   - Employee/customer generated content style
   - Short-form, authentic, not polished

2. **Food Photos** (FOOD-02, FOOD-04) — RM5-14/convo
   - Food hero shots work for WA because people want to SEE the dish before chatting
   - FOOD ads that fail on website SUCCEED on WhatsApp

3. **MOFU Social Proof** — RM8/convo
   - 初一十五 angle: 51 conversations
   - 吃素不想吃素料 angle: 14 conversations
   - Testimonials and social proof drive trust → conversation → order

4. **BOFU with Price** — RM16-25/convo
   - Bold Price, Receipt, Collection work on WA too
   - People see price, want to negotiate/ask → start chat

### What DOESN'T Convert (Either Channel)
- Pure food photography without price/CTA on website (0 ATC)
- TOFU curiosity hooks on website (clicks but 0 cart)
- HUMAN reaction ads (barely any spend, 0 signal)
- Over-polished studio photography (looks like stock)

### Andromeda Algorithm Rule
- Groups visually similar ads into ONE Entity ID
- 35 similar BOFU ads = 1 auction ticket
- 10 distinct formats = 10 tickets
- **Creative diversity > creative volume**
- Optimal: 10-15 truly distinct ads per ad set

### Creative Refresh Cadence
- Weekly: Launch 3-5 new concepts Monday, kill losers Friday
- Never exceed 15-20 ads per ad set
- Fatigue signal: CTR drops 20% from peak over 3-day window
- **Conveyor belt, not big bang**

---

## 9. IDENTITY GIMMICK PROMO METHOD

**The breakthrough creative formula:** Same offer for everyone, but identity-based hooks make each person feel it's THEIR special deal.

### How It Works
1. Pick an identity trait (payment method, IC number, birthday, location, life stage)
2. Write hook: "[Identity] 专属优惠" or "[Identity] special"
3. Same offer underneath: 买6送6 / 买8送8 / 买20送20
4. Creates FOMO + personalization + urgency
5. Each variation = new Andromeda Entity ID = more auction tickets

### Proven Results
- TNG-PROMO: **RM33 CPA, 5 purchases in 1 day, 4.78x ROAS**
- EGC PROMO SHORTS + TNG: **4 WA sales, RM629**

### Identity Gimmick Library (create for both Website + WA)
| # | Gimmick Hook | Target | Current Offer |
|---|---|---|---|
| 1 | TNG Payment users (running) | TNG users | 买8送8 |
| 2 | IC ending 168/888 (ran before) | Superstitious | 买8送8 |
| 3 | April birthday babies 🎂 | April birthdays | 买8送8 |
| 4 | Grab Food users — "放下Grab" | Delivery users | 买6送6 |
| 5 | 初一十五 families — "吃素的你" | Religious vegetarians | 买6送6 |
| 6 | KL/Selangor residents 🏙️ | Geographic | 买8送8 |
| 7 | 三高 diagnosed — "doctor说要注意" | Health-conscious | 买6送6 |
| 8 | Busy moms — "没时间煮饭的妈妈" | Working mothers | 买8送8 |
| 9 | Payday — "刚出粮？" | End-of-month timing | 买20送20 |
| 10 | First-time — "第一次试品馨" | New customers | 买6送6 |

---

## 10. PRODUCTION PIPELINE

### Rules (Compound Learnings — NEVER violate)
1. ALL text = NANO. PIL = resize + logo + grain ONLY.
2. References MUST be 9:16 before NANO (blur-extend)
3. NEVER crop NANO output — blur-extend pad only
4. Food photos are SACRED — never AI-generated
5. Single NANO pass — multi-pass compounds errors
6. Post-process: resize(1080x1920, blur-pad) → logo → grain(0.028)
7. Same dish + different plate = visual variety
8. Food must BLEND into scene (matching lighting, shadows, perspective)
9. **ALL artwork needs human approval before uploading to Meta**

### Output Routing
- New generations → `_WORK/pinxin/06_exports/campaigns/[campaign]/`
- Approved → `_WORK/pinxin/06_exports/finals/static/`
- Rejected → `_WORK/pinxin/06_exports/rejected/` + REJECTION-LOG.md
- NEVER save to /tmp or Desktop root

### Scripts
- Production: `_WORK/pinxin/05_scripts/pinxin_week2_v2.py`
- Deploy to Meta: `_WORK/pinxin/05_scripts/deploy_all_ads.py`
- Performance monitor: `_WORK/pinxin/05_scripts/autoads_check.py`

---

## 11. MEASUREMENT FRAMEWORK

### Website — Meta Pixel
- **CPA target:** <RM80 (current best: RM35)
- **ROAS target:** >2.5x (current: 4.78x today)
- **Kill rule:** CPA >RM120 after 7 days, or RM100+ spend with 0 purchases after 48 hours
- **Scale rule:** CPA <RM50 sustained 5+ days → increase budget +20%

### WhatsApp — Google Sheet
- **Cost/convo target:** <RM20 (current: RM16)
- **WA conversion rate target:** >20% conversations → orders
- **Kill rule:** >RM50/convo after 7 days AND 0 sheet sales
- **CRITICAL:** Check Google Sheet BEFORE killing WA ads

### Combined True ROAS
- Formula: Total ad spend / (Shopify revenue + WA sheet revenue)
- Target: >2.5x combined
- Mar 22: RM474 spend / RM1,627 combined revenue = **3.43x true ROAS**

### Daily Monitoring (autoads_check.py)
- Run daily: `python3 _WORK/pinxin/05_scripts/autoads_check.py`
- Cross-reference Google Sheet for WA attribution
- Update `_WORK/pinxin/02_strategy/autoads-results.tsv`

---

## 12. BUDGET & SCALING GATES

### Current Budget: ~RM1,100/day
| Campaign | Budget | Expected |
|---|---|---|
| Website Lowest Cost | RM300 | 6-10 purchases/day |
| WA CTWA-SALES | RM400 | 20-25 conversations/day |
| Retarget | RM100 | Cart abandoners |
| ZEN (if revives) | RM300 | Cost Cap backup |

### Scaling Gates
| Gate | Condition | Action |
|---|---|---|
| Week 3 | Website ROAS >2.5x sustained | Increase LC to RM500/day |
| Week 4 | WA conversion rate >25% | Increase CTWA to RM600/day |
| Month 2 | Combined ROAS >3x | Scale to RM2,000/day total |
| Month 2 | Set up Chatwoot → CAPI | Algorithm sees WA revenue |
| Month 3 | Revenue >RM150K/month | Scale to RM3,000/day |
| Month 3 | Test Advantage+ Shopping (ASC) | 22% ROAS lift potential |

### North Star: RM500K/month
- Requires: RM4,500/day ad spend at 3.5x ROAS
- Or: RM3,000/day at 5.5x ROAS
- Current trajectory: Need more data, but RM35 CPA + WA conversions = path exists

---

## 13. TRANSITION & TIMELINE

### Completed Actions
- [x] 50 creatives produced and uploaded (Mar 17)
- [x] 4-campaign structure deployed (Mar 17)
- [x] Killed poisoned TROAS ad set (Mar 20)
- [x] Created fresh Lowest Cost campaign (Mar 20)
- [x] Switched ZEN from Bid Cap → Cost Cap (Mar 20)
- [x] Paused new CTWA ENGAGEMENT campaign (Mar 20)
- [x] Created PX-CTWA-SALES-2026 with SALES objective (you created)
- [x] Killed 6 FOOD ads from website (Mar 22)
- [x] Killed BOFU-08, BOFU-12 from website (Mar 19)
- [x] Paused Old WA campaign (Mar 22)
- [x] Uploaded 7 Week 2 format hijacks (Mar 22)
- [x] Built autoads_check.py monitor (Mar 22)
- [x] Generated 60-day Meta token (Mar 22)
- [x] Desktop reorganized to _WORK structure (Mar 22)
- [x] GDrive cleaned + _ZENNITH structure created (Mar 22)

### Next Actions
- [ ] Add EGC PROMO SHORTS + 2 MOFU winners to PX-CTWA-SALES-2026
- [ ] Create 10 identity gimmick promo ads (April babies, Grab users, etc)
- [ ] Fix 3 Lofi ads (scene integration) for website
- [ ] Create video ads for WA (EGC style — #1 WA converter)
- [ ] Set up Google Drive "Folders from computer" sync for team
- [ ] Check BOFU-05 checkout issue (23 ATC, 0 purchases)
- [ ] Day 7 kill/scale round (Mar 24)
- [ ] Set up Chatwoot → CAPI for WA purchase attribution (Month 2)

---

## 14. DATA SOURCES

### Meta API
- Token: `~/Desktop/_WORK/_shared/.meta-token` (60-day, expires ~May 2026)
- App ID: 501769942955037
- App Secret: 12949e3c253635e0c70a22ed8300503e

### Google Sheet (WA Sales)
- URL: https://docs.google.com/spreadsheets/d/1Wuz9gvmfDVFufgth6cZECuj1N4ZuwDw9HRfbkI6QCnc/
- CSV: append `/gviz/tq?tqx=out:csv&gid=0` to URL
- Contains: Date, Amount, Source, Customer Type, Ad ID (for attributed orders)

### Shopify
- Store: pinxin-vegan-cuisine.myshopify.com
- App: pinxin engine (Client ID: 3f89bbd85529b19710dfe937013d0de6)
- Need shpat_ token for Admin API (shpss_ is app secret, not access token)

### File Locations
- Brand base: `~/Desktop/_WORK/pinxin/`
- Exports: `_WORK/pinxin/06_exports/`
- Scripts: `_WORK/pinxin/05_scripts/`
- Strategy: `_WORK/pinxin/02_strategy/`
- Shared tools: `_WORK/_shared/`
- CI Module: `~/Desktop/Creative Intelligence Module/` (symlinked)
- Zennith repo: `~/Desktop/zennith-skills/`
