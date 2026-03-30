# PINXIN META ADS — FINAL DEPLOYMENT DOC
> Ready to execute. All data confirmed. All creatives ready.

---

## ACCOUNT DETAILS
- Ad Account: act_138893238421035 (Pinxin Vegan Malaysia)
- Pixel: 961906233966610 (malaysia Pin Xin's Pixel)
- CAPI: ✅ CONFIRMED ACTIVE (browser + server events firing 1:1)
- Currency: MYR
- Timezone: Asia/Kuala_Lumpur

## TRACKING STATUS
- Website (Shopify): Pixel ✅ + CAPI ✅ → full tracking
- WhatsApp: Manual orders → NO pixel → use ENGAGEMENT objective

---

## 4-CAMPAIGN STRUCTURE

### Campaign 1: CBO-FrozenMY-CN-Broad-Website -Troas (EXISTING)
- Objective: SALES (Purchase)
- Pixel: 961906233966610
- Budget: RM500,000/day (uncapped)
- Bid: Minimum ROAS 2.5x (Phase 1) → 3.0x (Phase 2)

**CLEAN UP existing ad sets:**
- KILL: New Sales Ad (RM1,686 CPA), 手机尾数168, END OF CNY, all expired CNY ads
- KEEP: 元宵 IMAGE 1 Copy (RM69 CPA), 元宵 IMAGE 1 Copy 2 (RM75), 初一十五不能将就 (RM79), top EGC shorts

**ADD new ad set: "PX-NEW-2026Q1-tROAS"**
- Targeting: Broad, CN language (Simplified+Traditional), 28-55, KL+Selangor+Penang+JB 40km
- Detailed targeting: EMPTY (Advantage+ Detailed Targeting ON)
- Placements: Advantage+ (all)
- Optimization: Purchase
- 25 creatives: ALL BOFU (01-19) + FOOD (05,06,07,08,09,10)

### Campaign 2: CBO-FrozenMY-CN-Broad-Website -zen (EXISTING)
- Objective: SALES (Purchase)
- Pixel: 961906233966610
- Budget: RM500,000/day (uncapped)
- Bid: Bid Cap RM80/purchase

**CLEAN UP:** Same as Campaign 1
**ADD new ad set: "PX-NEW-2026Q1-BidCap"**
- Same targeting, same 25 creatives as Campaign 1
- Tests bid strategy (tROAS vs BidCap) with identical creative

### Campaign 3: PX-CBO-CTWA-WhatsApp-2026 (NEW)
- Objective: ENGAGEMENT (Conversations)
- Budget: RM600/day
- Bid: Lowest Cost (no cap)

**Ad Set A: PX-CTWA-Prospecting (RM400/day)**
- Targeting: Broad, CN language, 28-55, West MY
- Optimization: Conversations
- Exclusion: WA converters 30d, website purchasers 30d
- 25 creatives: ALL TOFU (01-05) + ALL MOFU (01-12) + FOOD (01,02,03,04) + ALL HUMAN (01-05)

**Ad Set B: PX-CTWA-Retarget-WA (RM200/day)**
- Audience: WA conversation started 30d, NOT purchased
- Frequency cap: 2/week
- 10 creatives: BOFU-01,02,05,06,08,09,14,15,17,19

**OLD CAMPAIGN: CBO-FrozenMY-CN-WhatsApp – OLD**
- Day 1: Reduce to RM120/day
- Day 4: Reduce to RM60/day
- Day 7: PAUSE

### Campaign 4: PX-CBO-Retarget-Purchase (NEW)
- Objective: SALES (Purchase)
- Pixel: 961906233966610
- Budget: RM200/day
- Bid: Cost Cap RM60/purchase

**Ad Set A: PX-RT-CartAbandon-14d (RM80/day)**
- Audience: Add to cart 14d, NOT purchased
- 5 creatives: BOFU-01 Calculator, BOFU-09 Shopping Cart, BOFU-08 Bold Price, BOFU-05 Golden Reveal, BOFU-19 Diary

**Ad Set B: PX-RT-WebVisit-7d (RM60/day)**
- Audience: Website visitors 7d, NOT purchased, NOT cart
- 5 creatives: FOOD-09 Variety, FOOD-07 Abundance, BOFU-06 Collection, BOFU-02 Receipt, BOFU-14 Voice Memo

**Ad Set C: PX-RT-WANonConvert-30d (RM60/day)**
- Audience: WA conversation 30d, NOT purchased (website)
- 5 creatives: BOFU-17 Bank Statement, BOFU-04 Restaurant Menu, BOFU-16 Fridge, FOOD-08 Packaging Reveal, BOFU-10 Raw Lofi

**ALL retarget ad sets exclude: Purchasers last 30 days**

---

## 50 CREATIVES — Location & Copy

Images: `/exports/CAMPAIGN-READY/` (50 PNG files)
Copy: `/strategy/CAMPAIGN-COPY-ALL-50.md` (matched headline + primary text per ad)

## PRICING IN ALL ADS
- 买6送6 / 买8送8 / 买20送20
- 一盒从RM12++
- Product name: 品馨懒人包 (not 冷冻餐)
- WhatsApp CTA on all BOFU

## TARGETING (all prospecting ad sets)
- Location: KL, Selangor, Penang, JB (40km radius)
- Age: 28-55
- Gender: All
- Language: Chinese (Simplified) + Chinese (Traditional)
- Detailed Targeting: EMPTY
- Advantage+ Detailed Targeting: ON
- Advantage+ Placements: ON

## KILL / SCALE RULES
| When | Kill if... | Scale if... |
|---|---|---|
| 48 hours | CTR < 0.5% | — |
| 7 days | Zero purchases after RM100 spend | — |
| 14 days | CPA > RM120 (website) | CPA < RM69 → +20% budget |
| 14 days | Cost/WA > RM15 | Cost/WA < RM8 → scale |
| 21 days | Frequency > 3.0 | ROAS > 3x sustained → +20% every 48h |

## BID PROGRESSION
| Phase | t-ROAS floor | Bid Cap | WA | Retarget |
|---|---|---|---|---|
| Week 1-2 | 2.0x (learning) | RM90 | Lowest Cost | Cost Cap RM60 |
| Week 3-4 | 2.5x | RM80 | Lowest Cost | Cost Cap RM50 |
| Month 2 | 3.0x | RM70 | Lowest Cost | Cost Cap RM40 |

## 7-DAY TRANSITION
| Day | Old campaigns | New campaigns |
|---|---|---|
| Day 0 | Kill 8 losers | Upload 50 creatives + copy |
| Day 1 | Reduce old WA 50% | Launch 4 campaigns |
| Day 4 | Reduce old WA 25% | Monitor learning |
| Day 7 | Pause old WA. Keep website winners only. | Should exit learning |
| Day 14 | Compare new vs old. Kill old if new wins. | Kill bottom 50% new ads |
| Day 21 | Full transition | Scale winners |

## IMMEDIATE CHECKLIST
☐ Top up ad account (currently RM304)
☐ Kill 8 losing ads in existing campaigns
☐ Upload 50 images to Meta Ads Manager
☐ Add copy (headline + primary text) per ad
☐ Create new ad set in Troas campaign (25 BOFU+FOOD ads)
☐ Create new ad set in zen campaign (same 25 ads)
☐ Create new CTWA campaign (2 ad sets, 25+10 ads)
☐ Create new Retarget campaign (3 ad sets, 5+5+5 ads)
☐ Set up custom audiences (cart abandon, web visit, WA conversation)
☐ Reduce old WA campaign to RM120/day
☐ Launch
☐ Day 3 review: kill CTR < 0.5%
☐ Day 7 review: pause old WA
☐ Day 14 review: kill bottom 50%, scale winners
