---
name: Mirra Meta Ads — Compounding Ledger (SINGLE SOURCE OF TRUTH)
description: "CRITICAL. Every ads session MUST read this FIRST and update it LAST. Contains: current state, all campaign IDs, budget, what changed when, why, what worked, what failed, sales context. NEVER start fresh analysis — always build on this."
type: project
---

## RULE: Read this file FIRST. Update it LAST. Every session.

---

## CURRENT STATE (Last updated: 2026-03-23 session 2)

### Account: act_830110298602617
- Page: 318283048041590
- WhatsApp: 60193838732
- Sales Sheet: `1mNP3AAySkP8xzCIbyznm3sqFtFZatSca6wLVnu35Vs0`
- Sales Sheet URL: https://docs.google.com/spreadsheets/d/1mNP3AAySkP8xzCIbyznm3sqFtFZatSca6wLVnu35Vs0/edit?gid=1350293783
- Apex Meta seeded: YES (scripts/seed_mirra.py)

### Budget constraint
- **MAX RM1,200/day** until ROAS recovers (user directive 2026-03-23)
- Current actual spend: ~RM695/day (Mar 23)
- User: "lets go back to spending RM1200 max, and until ROAs is healthy"

### Sales context (CRITICAL — ads ≠ sales)
- Daily revenue CRASHED: RM9,171 (Mar 8) → RM926 (Mar 23)
- Attribution gap: only 8.4% of March orders track to ad ID
- 13 attributed sales (RM5,621.50) from 11 unique ads in March 17-23
- Top revenue ad: SBB-Chi-Warm-V3 (3 sales, RM1,465.50) — CN video
- ZiQian-V2 has 3 attributed sales (RM993.50) despite higher convo cost

---

## ACTIVE CAMPAIGNS (FRESH DATA: 2026-03-23 evening)

### MASSIVE CPA IMPROVEMENT SINCE LAST CHECK
- Last session (early Mar 23): SALES-EN was RM5.24/convo
- **NOW: SALES-EN is RM1.49/convo** — S19, BX07, BX08 unpaused and CRUSHING IT
- This is a 3.5x improvement in cost efficiency

### 1. MIRRA-SALES-EN-MAR26 (CBO) — STAR CAMPAIGN
- **ID:** 120243085821340787
- **Set budget:** RM350/day | **7d spend:** RM860 | **578 convos | RM1.49/convo**
- **15 ads active, ranked by CPA:**

| Rank | Ad | CPA | Spend | Convos | Type | Status |
|------|-----|-----|-------|--------|------|--------|
| 1 | M3A-NewMums | RM0.17 | RM2.43 | 14 | Video | SCALE |
| 2 | S19-Transformation | RM0.97 | RM298 | 308 | Static | STAR — 53% of all convos |
| 3 | F10-Grid-MonToFri | RM1.52 | RM9.14 | 6 | Static | Needs volume |
| 4 | BX07-WhatsApp-WorthIt | RM1.67 | RM121 | 72 | Static | PROVEN WINNER |
| 5 | BX08-iMessage-FriendReco | RM1.90 | RM80 | 42 | Static | PROVEN WINNER |
| 6 | SBB-EN-Video | RM1.99 | RM90 | 45 | Video | GOOD |
| 7 | M3D-OfficeGirls | RM2.02 | RM10 | 5 | Video | Needs volume |
| 8 | OL-Foodie | RM2.29 | RM59 | 26 | Video | GOOD |
| 9 | ZiQian-V2 | RM2.53 | RM131 | 52 | Video | GOOD + 3 sales |
| 10 | KOL-Chris-v2 | RM4.25 | RM13 | 3 | Video | OK |
| 11 | KOL-Sunny-V3 | RM6.67 | RM20 | 3 | Video | BORDERLINE |
| 12 | S10-Checklist | RM10.86 | RM11 | 1 | Static | KILL |
| 13 | M3B-NewMums | RM12.04 | RM12 | 1 | Video | UNDERPERFORMING |
| 14 | S15-Horoscope | NO CONV | RM0.40 | 0 | Static | KILL |
| 15 | S01-Notes | NO CONV | RM2.98 | 0 | Static | KILL |

**KEY INSIGHT: S19-Transformation alone drove 308/578 convos (53%) at RM0.97/convo. This is the account's #1 creative asset by far.**

### 2. Scalling-Mirra SUPER WIN (CBO) — IMPROVED BUT STILL SECONDARY
- **ID:** 120235573169200787
- **Budget:** RM190/day | **7d spend:** RM434 | **159 convos | RM2.73/convo**
- Better than last session (was RM12.41) but still 83% more expensive than SALES-EN
- ZiQian V2 Copy: RM354 spent, 122 convos (RM2.90/convo) — eating 82% of budget
- KOL-Leann: RM50, 28 convos (RM1.78) — but LEANN IS FORBIDDEN (memory rule)
- SBB-EN: RM21, 9 convos (RM2.29) — decent

### 3. MIRRA-RETARGET-EN-MAR26 (ABO)
- **Budget:** RM50/day | **7d:** RM304, 133 convos, RM2.29/convo
- WARM (RT03-bank-statement): RM116, 77 convos, RM1.51/convo — EXCELLENT
- HOT (RT17-meal-box): RM58, 28 convos, RM2.08 — GOOD
- COOL (RT08-order-confirm): RM46, 4 convos, RM11.57 — KILL
- Several ads with zero convos spending money — need cleanup

### 4. MIRRA-RETARGET-CN-MAR26 (ABO)
- **Budget:** RM35/day | **7d:** RM210, 93 convos, RM2.26/convo
- HOT (CNRT02-shopee-cart): RM50, 39 convos, RM1.28 — EXCELLENT
- WARM (CNRT08-grab-tracking): RM74, 32 convos, RM2.31 — GOOD
- COOL: RM52, 18 convos, RM2.79 — actually not bad anymore

### Budget summary (FRESH)
| Campaign | Set Budget | 7d Spend | 7d Convos | CPA | Notes |
|---|---|---|---|---|---|
| SALES-EN | RM350/day | RM860 | 578 | RM1.49 | SCALE THIS |
| SUPER WIN | RM190/day | RM434 | 159 | RM2.73 | Decision needed |
| RETARGET-EN | RM50/day | RM304 | 133 | RM2.29 | Cleanup needed |
| RETARGET-CN | RM35/day | RM210 | 93 | RM2.26 | Good |
| **TOTAL** | **RM625/day** | **RM1,808** | **963** | **RM1.88** | **CPA improved 3.5x vs last** |

---

## DAILY SPEND TREND (21 days)

| Date | Spend | Convos | Cost/Convo | Notes |
|------|-------|--------|------------|-------|
| Mar 9 | RM1,528 | 218 | RM7.01 | |
| Mar 10 | RM1,725 | 232 | RM7.44 | |
| Mar 11 | RM1,514 | 199 | RM7.61 | |
| Mar 12 | RM1,386 | 166 | RM8.35 | Worst CPA |
| Mar 13 | RM1,053 | 154 | RM6.84 | |
| Mar 14 | RM1,353 | 201 | RM6.73 | |
| Mar 15 | RM919 | 137 | RM6.71 | Weekend |
| Mar 16 | RM1,902 | 737 | RM2.58 | New campaigns + SALES-EN |
| Mar 17 | RM1,631 | 640 | RM2.55 | |
| Mar 18 | RM1,690 | 995 | RM1.70 | Strong |
| Mar 19 | RM1,488 | 959 | RM1.55 | **Best CPA** |
| Mar 20 | RM966 | 667 | RM1.45 | **Best efficiency** |
| Mar 21 | RM1,787 | 867 | RM2.06 | Forensic kills |
| Mar 22 | RM829 | 554 | RM1.50 | Post-kill |
| Mar 23 | RM695* | 463* | RM1.50* | *partial day |

**PATTERN: CPA improved MASSIVELY Mar 16+ (RM7→RM1.50). But DAILY SPEND dropped 60% (RM1,900→RM695). Getting more efficient but reaching fewer people. Need to SCALE spend while maintaining this CPA.**

---

## HISTORICAL DECISIONS LOG

### 2026-03-23 Session 2: Fresh data + Apex Meta build
- SALES-EN performing 3.5x better than last check (RM5.24→RM1.49/convo)
- S19-Transformation is the #1 creative: 308 convos at RM0.97
- S19, BX07, BX08 now UNPAUSED and performing excellently
- SUPER WIN improved (RM12.41→RM2.73) but still 83% more expensive than SALES-EN
- Built Apex Meta platform (full codebase), created seed script
- Retargets performing well across both languages
- User wants immediate strategy to boost sales ASAP

### 2026-03-23 Session 1: SBB video analysis + structure audit
- Tricia delivered 11 new SBB video ads
- Pulled full account structure: SUPER WIN bloated
- Built compounding intelligence system (this ledger)
- Ad attribution analysis: 11 ads drove 13 sales (RM5,621.50)
- User: "go back to RM1,200 max" + "sales dropped"

### 2026-03-22: Logo fix + diet-v2 script
- 11 diet-v2 statics + 10 diet-bento-v1 + 10 sales-v3 generated
- Positioning: "We're diet bento, not convenient lunch bento"

### 2026-03-21: Creative forensic + kill lists
- EN: 60→36 ads, CN: 50→13 ads
- Launched SALES-EN-MAR26 (CBO, RM350/day)
- Launched RETARGET-EN + RETARGET-CN

### 2026-03-16: Campaign launch
- Launched TEST-EN + TEST-CN (ABO), 118 ads, RM1,500/day

---

## PROVEN WINNERS (UPDATED with fresh 7d data)

| Ad | Format | CPA (7d) | Convos (7d) | Revenue Attribution | Status |
|----|--------|----------|-------------|---------------------|--------|
| S19-Transformation | Static | **RM0.97** | **308** | — | **#1 CREATIVE** |
| M3A-NewMums | Video | RM0.17 | 14 | — | Scale (low volume) |
| F10-Grid-MonToFri | Static | RM1.52 | 6 | — | Needs volume |
| BX07-WhatsApp-WorthIt | Static | RM1.67 | 72 | RM898 (1 sale) | PROVEN SELLER |
| BX08-iMessage-FriendReco | Static | RM1.90 | 42 | — | PROVEN |
| SBB-EN-Video | Video | RM1.99 | 45 | — | GOOD |
| ZiQian-V2 | Video | RM2.53 | 52 | RM993 (3 sales) | PROVEN SELLER |
| SBB-Chi-Warm-V3 | Video CN | — | — | RM1,465 (3 sales) | **#1 REVENUE AD** |

## KILL LIST (proven bad — never re-test)
- S10-Checklist (RM10.86/convo), S15-Horoscope (zero), S01-Notes (zero)
- KOL-Leann (FORBIDDEN by user)
- M3B-NewMums in current form (RM12.04/convo — was good before, now bad)

---

## PENDING CREATIVES (not yet deployed)
1. **diet-v2 statics** (11 variants) — in `06_exports/finals/static/diet-v2/`
2. **SBB videos** (11 from Tricia) — in GDrive `batch-2026-03/`
3. **diet-bento-v1 statics** (10 variants) — re-generated with logo fix
4. **sales-v3 statics** (10 variants) — re-generated with logo fix

## NEXT SESSION CHECKLIST
- [ ] Read this file FIRST
- [ ] Pull daily spend + campaign performance
- [ ] Compare CPA to this session's baseline (RM1.49 for SALES-EN)
- [ ] Check if new creatives were deployed
- [ ] Check sales sheet for revenue trend
- [ ] Update this file LAST
