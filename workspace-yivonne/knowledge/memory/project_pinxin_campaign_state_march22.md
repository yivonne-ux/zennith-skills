---
name: Pinxin Campaign State March 22 — CURRENT
description: Full campaign state after all changes. Campaign IDs, bid strategies, what's active/paused, WA attribution findings, dual-channel strategy, autoads monitoring. READ THIS FIRST for any Pinxin ads work.
type: project
---

## Campaign Architecture (as of 2026-03-22)

### ACTIVE Campaigns
| Campaign | ID | Bid | Budget | Ads |
|---|---|---|---|---|
| PX-Website-LowestCost-Test | 120240872763100006 | Lowest Cost | RM300/day | 14 active |
| PX-CTWA-SALES-2026 | 120240934632520006 | Lowest Cost (SALES obj, CONVERSATIONS opt) | RM400/day | 13 active |
| Retarget | 120240686358240006 | Cost Cap RM60 | RM100/day | Low volume |
| ZEN (Cost Cap) | 120239703308610006 | Cost Cap RM100 | CBO | Not spending |
| TROAS (old winners only) | 120239867144580006 | ROAS floor | CBO | Old winners |

### PAUSED Campaigns
| Campaign | ID | Why |
|---|---|---|
| New CTWA (ENGAGEMENT) | 120240686232170006 | Wrong objective — finds chatters not buyers |
| Old WA (SALES) | 120240009868730006 | Dying — but EGC PROMO SHORTS drove 5 WA sales |
| Old TROAS ad set | 120240685375840006 | Poisoned by Day 1 RM1,045 spike |

### Website Ad Set (120240872766570006) — 14 active ads
Winners: TNG-PROMO (RM33 CPA), BOFU-10 Lofi (RM20), BOFU-18 Boarding Pass (RM28), BOFU-06 Collection (RM60), BOFU-02 Receipt (RM34), BOFU-05 (23 ATC), BOFU-03
+ 7 Week 2 format hijacks (learning)
+ 5 identity gimmick ads (PAUSED — awaiting approval, need NEW artwork)
KILLED: All FOOD, TOFU, HUMAN (0 ATC on website), BOFU-08, BOFU-12

### WA Ad Set (120240934633060006) — 13 active ads
FOOD-02, FOOD-03, FOOD-04, TOFU-01, TOFU-04, BOFU-02/05/06/08/14 + EGC PROMO SHORTS + MOFU初一十五 + MOFU吃素不想吃素料

## Dual-Channel Insight
- **Website**: BOFU promo/urgency + format hijack + raw lofi CONVERT. FOOD/TOFU don't.
- **WhatsApp**: FOOD photos + MOFU social proof + video (EGC) + BOFU retarget CONVERT.
- **Same ad can fail on website but succeed on WA** (BOFU-08: RM460 CPA website, 2 WA sales)
- **NEVER kill WA ads based on Meta pixel alone — check Google Sheet first**

## Best Performance Day: March 22
- Shopify: 12 orders = RM2,088
- WA Sheet: 6 orders = RM999
- Total: 18 orders = RM3,087
- Ad spend: RM789
- TRUE ROAS: 3.9x

## Key Decisions & Learnings
1. Lowest Cost > Cost Cap > Bid Cap > ROAS floor (proven with real data)
2. ROAS floor USELESS with <50 conversions — burned RM1,045 in 30 mins
3. Identity gimmick promos = breakthrough formula (TNG-PROMO RM33 CPA)
4. Same offer, different identity hooks = more Andromeda Entity IDs
5. STOP CONSTANT CHANGES — each change resets learning. Set up once, leave 14 days.
6. Week 2 format hijacks just launched — need 48 hours before judging
7. 5 gimmick ads created with TNG image (wrong) — need NEW unique artwork per hook
8. Human approval REQUIRED before any upload to Meta

## Monitoring
- autoads_report.py → Telegram @ZennithAdsBot every day at 12am, 10am, 3pm, 8pm, 10pm
- Shopify auto-refreshes token via client_credentials
- Meta token: 60-day (expires ~May 2026)
- Google Sheets: Pinxin WA + Mirra WA

## Tokens & Access
- Meta: ~/Desktop/_WORK/_shared/.meta-token (60-day)
- Shopify: auto-refreshes via shopify_helper.py (Client ID + Secret)
- Telegram: @ZennithAdsBot, Chat ID 5056806774

## Files
- Master strategy: _WORK/pinxin/02_strategy/PINXIN-MASTER-STRATEGY-2026-Q1.md
- Dual channel: _WORK/pinxin/02_strategy/DUAL-CHANNEL-STRATEGY-2026.md
- Autoads: _WORK/_shared/creative-intelligence/autoads/
- Brand skeleton: _WORK/_shared/OUTPUT-ROUTING-RULES.md
