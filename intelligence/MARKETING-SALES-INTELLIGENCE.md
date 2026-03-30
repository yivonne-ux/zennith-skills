# Marketing & Sales Intelligence — Master Architecture
## Version 0.3 | 2026-03-30 | Autoresearch Cycle 1 + Zennith Audit Complete

---

## SYSTEM PHILOSOPHY

Adapted from Karpathy's autoresearch pattern:
- **program.md** = this document (human edits the strategy)
- **Agents** = autonomous research + execution (AI runs experiments)
- **Compound loop** = every session reads previous state, runs, measures, updates
- **Self-improving** = failures become rules, successes become patterns

```
┌─────────────────────────────────────────────────────────────────┐
│                    MARKETING & SALES INTELLIGENCE               │
│                     (The Mastermind System)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │  CREATIVE     │    │  MARKETING   │    │    SALES     │      │
│  │ INTELLIGENCE  │    │ INTELLIGENCE │    │ INTELLIGENCE │      │
│  │ (exists)      │◄──►│ (NEW)        │◄──►│ (NEW)        │      │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘      │
│         │                   │                   │               │
│         ▼                   ▼                   ▼               │
│  ┌──────────────────────────────────────────────────────┐      │
│  │              APEX META ENGINE                         │      │
│  │         (Meta Ads API + CAPI + Automation)            │      │
│  └──────────────────────────────────────────────────────┘      │
│         │                   │                   │               │
│         ▼                   ▼                   ▼               │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │  BRAND A      │    │  BRAND B     │    │  BRAND C     │      │
│  │  (Pinxin)     │    │  (Mirra)     │    │  (DotDot)    │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                                 │
│  ┌──────────────────────────────────────────────────────┐      │
│  │           COMPOUND LEARNING LEDGER                    │      │
│  │    (Every mistake → rule. Every win → pattern.)       │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## THREE INTELLIGENCE DOMAINS

### 1. CREATIVE INTELLIGENCE (EXISTS — `creative-intelligence-social-production-engine.md`)
**What it does:** Produces visual content (social posts, ad creatives, video)
**Engine:** NANO + PIL + Claude Vision + Post-Processing
**Inputs:** References, brand DNA, viral formats, food photos
**Outputs:** Production-ready 4:5 / 9:16 images, captions, carousels
**Self-improving via:** 12-layer audit gate, yes/no per image, compound learnings per brand

### 2. MARKETING INTELLIGENCE (NEW)
**What it does:** Decides WHAT to create, WHERE to spend, WHEN to scale/kill, WHO to target
**Engine:** Meta Graph API + Analyzer + Forensic Audit + Research
**Inputs:** Campaign data, market signals, competitive intel, attribution data
**Outputs:** Creative briefs, budget decisions, campaign architecture, kill/scale actions
**Self-improving via:** ROAS tracking, CPA trends, win/loss patterns, attribution matching

### 3. SALES INTELLIGENCE (NEW)
**What it does:** Tracks revenue, attributes sales to ads, optimizes conversion path
**Engine:** CAPI + Google Sheets + Shopify + WhatsApp
**Inputs:** Orders, customer data, conversation logs, payment data
**Outputs:** Attribution reports, LTV analysis, cohort insights, revenue forecasts
**Self-improving via:** Match rate improvement, conversion funnel analysis, customer segmentation

---

## MARKETING INTELLIGENCE — DETAILED ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│                    MARKETING INTELLIGENCE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  LAYER 1: SENSE (Data Collection)                               │
│  ├─ Meta Insights API (5x/day)     → Campaign performance       │
│  ├─ Google Sheets (daily)          → WA order data               │
│  ├─ Shopify API (daily)            → Website order data          │
│  ├─ FB Ad Library (weekly)         → Competitor monitoring       │
│  ├─ Social scraping (as needed)    → Viral format detection      │
│  └─ CAPI Events Manager           → Match rate & attribution    │
│                                                                 │
│  LAYER 2: ANALYZE (Intelligence Processing)                     │
│  ├─ Autoads Report      → Aggregate metrics, Telegram alerts    │
│  ├─ Autoads Analyzer    → Kill/scale/fatigue rules engine       │
│  ├─ Autoads Forensic    → Weekly deep audit + creative briefs   │
│  ├─ Sheet Attribution   → Ad-to-sale matching                   │
│  ├─ Autoscale Checker   → 3-day ROAS threshold gates            │
│  └─ Market Research     → CPM/CPC benchmarks, seasonal trends   │
│                                                                 │
│  LAYER 3: DECIDE (Strategy & Action)                            │
│  ├─ Campaign Architecture    → 4-campaign structure decisions    │
│  ├─ Budget Allocation        → Channel split (Web vs WA)        │
│  ├─ Creative Brief Generator → What to produce next             │
│  ├─ Kill/Scale Engine        → Which ads live/die               │
│  └─ Testing Calendar         → When to launch/review/scale      │
│                                                                 │
│  LAYER 4: ACT (Execution)                                       │
│  ├─ Budget Scripts     → Midnight cron scaling                  │
│  ├─ Ad Activation      → Batch activate/pause ads               │
│  ├─ Creative Upload    → Deploy new ads to Meta                 │
│  ├─ CAPI Upload        → Nightly offline conversion push        │
│  └─ Social Publisher   → Cron-based IG/FB posting               │
│                                                                 │
│  LAYER 5: LEARN (Compound Loop)                                 │
│  ├─ Win/Loss Ledger    → Every ad's lifetime result             │
│  ├─ Creative DNA Map   → What visual/copy patterns win          │
│  ├─ Rule Evolution     → Hard rules updated from failures       │
│  ├─ Pattern Library    → Proven patterns from successes         │
│  └─ Brand Memory       → Per-brand compounding knowledge        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## SALES INTELLIGENCE — DETAILED ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│                      SALES INTELLIGENCE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  LAYER 1: CAPTURE                                               │
│  ├─ WhatsApp conversations    → Lead capture + qualification    │
│  ├─ Shopify orders            → Website conversion tracking     │
│  ├─ Google Sheet entries      → Manual WA order logging         │
│  ├─ Meta pixel events         → Page view / ATC / Purchase      │
│  └─ CAPI events               → Server-side purchase events     │
│                                                                 │
│  LAYER 2: ATTRIBUTE                                             │
│  ├─ ctwa_clid matching        → WA click → specific ad          │
│  ├─ UTM parameter tracking    → Web click → specific ad         │
│  ├─ Phone hash matching       → Offline sale → Meta user        │
│  ├─ Ad ID column (Sheet)      → Manual attribution              │
│  └─ Language-level proxy      → EN vs CN efficiency             │
│                                                                 │
│  LAYER 3: MEASURE                                               │
│  ├─ True ROAS                 → Revenue / Ad Spend (blended)    │
│  ├─ CPA by channel            → Website vs WA vs Retarget       │
│  ├─ Customer LTV              → Repeat purchase rate + AOV      │
│  ├─ LTV:CAC ratio             → Unit economics health           │
│  └─ Cohort retention          → Monthly retention curves        │
│                                                                 │
│  LAYER 4: OPTIMIZE                                              │
│  ├─ Conversion path analysis  → Where customers drop off        │
│  ├─ Price sensitivity         → Promo vs full-price response    │
│  ├─ Channel optimization      → Which channel for which segment │
│  ├─ Timing optimization       → Best day/time for conversions   │
│  └─ Creative-to-sale mapping  → Which creative DNA drives sales │
│                                                                 │
│  LAYER 5: FORECAST                                              │
│  ├─ Revenue projection        → Based on spend + ROAS trends    │
│  ├─ Budget recommendation     → Optimal daily spend per brand   │
│  ├─ Inventory planning        → Demand forecasting from ads     │
│  └─ Seasonal adjustment       → Festival/payday/promo calendar  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## APEX META ENGINE — THE EXECUTION LAYER

```
┌─────────────────────────────────────────────────────────────────┐
│                       APEX META ENGINE                           │
│              (Meta Ads API Automation Platform)                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  CORE APIS                                                      │
│  ├─ Meta Graph API v22.0       → Read/write campaigns, ads      │
│  ├─ Meta Conversions API       → Server-side event tracking      │
│  ├─ Meta Ad Library API        → Competitor ad monitoring        │
│  └─ Telegram Bot API           → Alerts & approvals              │
│                                                                 │
│  AUTOMATION SCRIPTS (cron-driven)                               │
│  ├─ autoads_report.py          → 5x/day performance dashboard   │
│  ├─ autoads_analyzer.py        → 2x/day kill/scale/fatigue      │
│  ├─ autoads_forensic.py        → Weekly deep audit              │
│  ├─ autoads_sheet_attribution  → Daily ad-to-sale matching       │
│  ├─ autoads_autoscale.py       → Nightly ROAS threshold check   │
│  ├─ offline_conversions*.py    → Nightly CAPI upload per brand  │
│  └─ scale_*.py / budget_*.py   → One-time midnight executions   │
│                                                                 │
│  SAFETY GATES                                                   │
│  ├─ 20% max budget change per 48h                               │
│  ├─ Human approval for kills                                    │
│  ├─ DRY_RUN flag for all writes                                 │
│  ├─ Midnight-only execution for budget changes                  │
│  ├─ One change at a time (no stacking)                          │
│  └─ Telegram confirmation before irreversible actions           │
│                                                                 │
│  DATA STORES                                                    │
│  ├─ Google Sheets              → Order tracking (source of truth)│
│  ├─ autoscale_state.json       → Last change timestamps          │
│  ├─ Compound learning ledger   → Per-brand win/loss history      │
│  ├─ Memory files (.md)         → Hard rules + proven patterns    │
│  └─ Cron logs                  → Execution audit trail           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## THE COMPOUND LEARNING LOOP (Autoresearch Pattern)

```
    ┌──────────────────────────────────────────────┐
    │            EVERY SESSION STARTS HERE          │
    │                                              │
    │  1. READ brand compound ledger               │
    │  2. READ last forensic report                │
    │  3. READ hard rules + proven patterns         │
    │  4. CHECK what changed since last session     │
    │                                              │
    └──────────────────┬───────────────────────────┘
                       │
                       ▼
    ┌──────────────────────────────────────────────┐
    │            SENSE (collect fresh data)         │
    │                                              │
    │  • Pull Meta insights                        │
    │  • Pull order data from Sheets               │
    │  • Check creative pipeline status             │
    │  • Check what's scheduled vs what posted      │
    │                                              │
    └──────────────────┬───────────────────────────┘
                       │
                       ▼
    ┌──────────────────────────────────────────────┐
    │            ANALYZE (find signals)             │
    │                                              │
    │  • Which ads are winning/dying?              │
    │  • Is ROAS improving or declining?           │
    │  • Any creative fatigue (frequency > 3)?     │
    │  • Attribution match rate improving?          │
    │  • Budget utilization efficiency?             │
    │                                              │
    └──────────────────┬───────────────────────────┘
                       │
                       ▼
    ┌──────────────────────────────────────────────┐
    │            DECIDE (propose actions)           │
    │                                              │
    │  • Kill these ads (with evidence)            │
    │  • Scale these campaigns (with gates)        │
    │  • Produce these creatives (brief)           │
    │  • Shift budget (with rationale)             │
    │  • Deploy these creatives (with approval)    │
    │                                              │
    └──────────────────┬───────────────────────────┘
                       │
                       ▼
    ┌──────────────────────────────────────────────┐
    │            ACT (execute with safety)          │
    │                                              │
    │  • Human approves actions                    │
    │  • Midnight cron executes budget changes     │
    │  • Creative pipeline produces new ads        │
    │  • CAPI uploads overnight                    │
    │                                              │
    └──────────────────┬───────────────────────────┘
                       │
                       ▼
    ┌──────────────────────────────────────────────┐
    │            LEARN (update the system)          │
    │                                              │
    │  • Update compound ledger with results       │
    │  • New failure → new hard rule               │
    │  • New success → new proven pattern          │
    │  • Update brand memory                       │
    │  • Generate next session's starting context  │
    │                                              │
    └──────────────────┬───────────────────────────┘
                       │
                       └──────► NEXT SESSION
```

---

## HARD RULES (52 rules, extracted from all experience)

### Campaign Structure
1. NEVER start fresh — read compound ledger FIRST
2. NEVER use SALES objective without CAPI
3. NEVER use ROAS floor on new campaigns (burned RM1,045 in 30 min)
4. NEVER set high budgets without spend caps on new ad sets
5. STOP constant changes — each resets learning phase (need 50 conversions in 7 days)
6. 20% max budget increase per 48 hours
7. Wait 48h between budget changes
8. 10-15 ads per ad set (Andromeda optimal, 50 hard limit including paused)
9. DELETE confirmed losers (don't just pause) — but careful with name matching
10. CTWA ads MUST use WHATSAPP_MESSAGE CTA and wa.me link
11. WA campaign must use SALES objective (not ENGAGEMENT)
12. Human approval REQUIRED before ANY creative upload to Meta
13. Never suggest new campaigns without checking existing health
14. Always know total daily spend across all campaigns
15. Bid strategy: Lowest Cost → Cost Cap → Min ROAS (only with 50+ conv/week)

### Creative Production
16. Creative = 75-90% of ad performance
17. Lo-fi/ugly ads outperform studio by +72% ROAS
18. ONE message in 0.5 seconds — every ad
19. Specific number always visible (RM19, 500 cal, 50+)
20. First-person copy ("my RM19 lunch" not "your lunch")
21. Real food ONLY — never AI-generated food or packaging
22. Per-meal pricing always ("RM19/meal" never "RM570/month")
23. Never lead with plant-based
24. Never use exclamation marks
25. PAS framework for cold audiences (first 125 chars = the ad)
26. 10+ genuinely distinct concepts per campaign, refresh every 2 weeks
27. <40% visual similarity between ads (Andromeda Entity ID)
28. ALL text = NANO. PIL = resize + logo + save ONLY
29. Image 1 DOMINATES NANO art style — never pass non-brand image
30. Set aspect_ratio="4:5" in every NANO call
31. Never generate at 9:16 — generate 4:5 first, blur-extend
32. NANO resolution = "4K" always

### Attribution & Measurement
33. Conversations are NOT sales (97% don't convert)
34. NEVER kill WA ads based on Meta pixel alone — check Google Sheet
35. Conservative kills only when no attribution
36. Never kill based on single metric — need CPA + volume + funnel role + language
37. CAPI is non-negotiable (pixel misses 60%+ conversions)
38. Without CAPI: optimize for Cost/WA message > CTR > CPC > Frequency

### Meta API Safety
39. Copy wipe bug — always pass copy explicitly (never read-back)
40. Rate limiting — sleep(0.5) between calls, cooldown after heavy ops
41. Tokens expire fast — handle gracefully
42. page_welcome_message MUST be string (json.dumps), not raw dict
43. Test with 1-2 ads before batch operations
44. Auto-payment prevents learning reset from payment failures

### Social Media (distinct from ads)
45. Social ≠ ads — never mix approaches
46. Content ratio: 60% relatable, 40% brand-adjacent
47. DM sends > likes for algorithm reach in 2026
48. Post frequency: 2-3/day, rotate illustration → food → carousel
49. Eyes = #1 art style indicator for character consistency

### Malaysia-Specific
50. Bilingual EN+CN code-switch = +27% CTR
51. LEGAL: "burns fat" / "reduces obesity" = RM10K fine or 2 years jail
52. Malaysia CPM 75% cheaper than US — aggressive testing is economically viable

---

## PROVEN PATTERNS (24 patterns)

1. 4-campaign architecture: TEST (ABO 15%) → SCALE (CBO 50-60%) → ASC (25%) → RETARGET (10%)
2. 3-3-3 testing: 3 concepts × 3 hooks × 3 formats = 27 ads per cycle
3. Lowest Cost > Cost Cap > Bid Cap > ROAS floor
4. Horizontal scaling > vertical scaling (more formats, not more budget)
5. Identity gimmick = best Pinxin formula (TNG-PROMO RM33 CPA, 4.78x ROAS)
6. Fake UI format = #1 Mirra formula (Notes, iMessage, WhatsApp screenshot)
7. Testing cadence: Launch Mon+Thu, Review Wed+Sat, Scale Fri
8. Dual-channel insight: same ad can fail website, succeed on WA
9. S19-Transformation = Mirra's #1 (308 convos, RM0.97/c, 53% of all conversations)
10. Real person telling real story (video) WORKS. Generic/abstract FAILS.
11. Format priority: Carousel (4.2x ROAS) > Short Reels > Static 4:5 > Text-led UGC
12. Weekly creative mix: 3-4 lo-fi + 2-3 editorial + 2-3 carousel + 1-2 video
13. CTWA = 5x lower CPA than website conversion ads (45-60% CTR on WA button)
14. 40+ format archetypes for Andromeda diversity
15. Authority carousel dark+bold = KING format (173K likes, 233K saves)
16. Reply to EVERY ad comment = +22% conversion lift
17. Budget scaling gates: TEST → SCALE (2x) → ACCELERATE (3-5x) → FULL THROTTLE
18. 3-tier retarget: HOT (1-7d, 50%) → WARM (8-30d, 30%) → COLD (31-90d, 20%)
19. Language-level ROAS as best attribution proxy without full tracking
20. EN consistently outperforms CN for Mirra (91% of orders, 93% of revenue)
21. CAPI offline upload improves Meta's optimization signal over time
22. Zero competition in MY frozen vegan Meta ads — blue ocean
23. Viral wisdom content scrape → classify → lock → generate → audit
24. Bash wrappers for cron (macOS blocks Python Desktop access)

---

## DOCUMENTED FAILURES (14 failures → 14 lessons)

1. ROAS floor + no data = RM1,045 burned in 30 min → Rule: never ROAS floor on new campaigns
2. ENGAGEMENT objective for WA = RM380/convo vs RM10 on SALES → Rule: always SALES objective
3. Constant changes = perpetual learning phase → Rule: set up once, leave 14 days
4. Opening new campaigns while existing dying → Rule: fix existing first
5. Budget confusion (spend vs revenue) → Rule: always clarify denominator
6. Data visualizations in ads = RM83/convo → Never use abstract data viz
7. PIL text overlay for design = always bad → NANO handles all text
8. NANO-generated faces = rejected 3x → Never use AI faces for trust/proof
9. GaussianBlur(30) destroys references → Moderate blur only
10. Multi-dish NANO prompts = generic food → Single hero dish only
11. Same image + different copy ≠ different Entity ID → Need unique artwork
12. macOS cron + CommandLineTools python = silent failures → Use bash wrappers
13. launchd Desktop access = Operation not permitted → Wrapper scripts
14. Graph API v21.0 returning container ID as published → Upgrade to v22.0

---

## RESEARCH FINDINGS (Autoresearch Cycle 1 — 2026-03-30)

### URGENT: Advantage+ API Migration (Deadline May 19, 2026)
- Graph API v25.0 deprecates legacy ASC/AAC campaign APIs
- Phase 3 (May 19): Updates to existing campaigns BLOCKED across ALL versions
- **Action:** Audit autoads scripts. Migrate to unified Advantage+ campaign API.
- Source: Meta Developer Release Notes Feb 2026

### HIGH-LEVERAGE: meta-ads-mcp (Open Source MCP Server)
- GitHub: `pipeboard-co/meta-ads-mcp`
- Gives Claude Code LIVE access to Meta Marketing API — 25 tools, 6 areas
- Verified: 3-person agency scaled 8 → 20 accounts without hiring
- 90% reduction in operational work, 15% ROAS increase (Anthropic case study)
- **Action:** Install and connect to our Business Manager accounts

### HIGH-LEVERAGE: meta-ads-kit (Open Source AI Ad Manager)
- GitHub: `TheMattBerman/meta-ads-kit`
- Modular: Monitor → Detect fatigue → Shift budget → Generate copy → Upload → Repeat
- Built on OpenClaw + social-cli, zero cost beyond ad spend
- Skills: meta-ads, ad-creative-monitor, budget-optimizer, ad-copy-generator, pixel-capi

### Andromeda Entity ID — Creative Diversity > Volume
- 50 similar ads = 1 Entity ID = 1 auction ticket
- Must vary on 2+ dimensions simultaneously: FORMAT × PERSONA × ENVIRONMENT × BENEFIT
- 1-3 ad sets per campaign (not 5-10), 10-20 unique creatives per ad set
- Creative fatigue now 2-4 weeks (faster than before)
- Brands following these practices: +20-35% ROAS

### CTWA Attribution — The Missing Link
- Capture `ctwa_clid` from webhook referral object when user starts WA convo from ad
- Send with purchase event via CAPI: `action_source: "business_messaging"`, `messaging_channel: "whatsapp"`
- This closes the 91.6% attribution gap (only 8.4% of orders currently tracked)
- Upload within 48h for best match rates (delays >2 days = -25% match rate)

### Offline Conversions API is DEAD (May 2025)
- All offline tracking now flows through standard Conversions API
- Dual tracking (Pixel + CAPI) = +19% additional purchase attribution
- 7-day view and 28-day view windows REMOVED Jan 12, 2026

### Incrementality Testing
- Meta Incremental Attribution: separates ad-driven from organic conversions
- Requires 200K+ audience, 10% holdback, 3-4 weeks
- DIY alternative: geo-split test (exclude one state, compare sales)
- Advertisers using it: +20% improvement in incremental conversions

### Creative Testing — AI-Powered (2025-2026)
- Meta's "AdLlama" LLM: +6.7% CTR across 640K ad versions
- AI predicts creative success at 90% accuracy (vs 52% human judgment)
- Lo-fi/UGC = 42% of top-spending ads
- Short video: 15-30s, hook in 3s, one message, clear CTA
- 9 in 10 consumers say UGC shapes purchases most

### Full-Funnel Under Andromeda
- Budget split: 20-30% TOFU, 20-30% MOFU, 40-50% BOFU
- TOFU spend directly improves BOFU performance (Andromeda evaluates behavior over time)
- Full funnel = +45% higher ROI than single-stage
- KPIs: TOFU (CPM, reach) → MOFU (engagement, LPV) → BOFU (CPA, ROAS)

### Scaling Rules That Work
1. **Kill:** CPA > threshold after 2x target CPA spend → pause ad
2. **Scale:** ROAS > target for 3+ consecutive days → +20% budget (cap every 3-4 days)
3. **Fatigue:** Frequency > 3 AND CTR drop 15% over 7 days → -30% spend + alert
- 82% of FB advertisers use Advantage+ automation (2025)

### Malaysian/SEA Market (Updated)
- CTWA campaigns = 3x higher conversion vs landing pages in WA-dominant markets
- Volvo Malaysia: 600% ROI from WhatsApp Business
- CTWA: +46% customer messages at -32% lower costs
- SEA social commerce: $47.6B in 2025 → $186.5B by 2030 (31.4% CAGR)
- 85% SEA shoppers use AI tools for purchase decisions
- 68% prefer local payment (FPX, TnG, GrabPay)

### Tools Comparison for Our Scale
| Tool | Approach | Cost | Fit |
|------|----------|------|-----|
| meta-ads-mcp + Claude Code | MCP live API access | Free | **BEST** — already using Claude |
| meta-ads-kit | Modular AI ad manager | Free | **HIGH** — complements our autoads |
| AdAmigo.ai | Fully autonomous AI | $99/mo | MEDIUM — if we want hands-off |
| Metabase | Self-hosted BI dashboard | Free | HIGH — cross-brand reporting |
| Airbyte | Data pipeline (Meta → warehouse) | Free tier | MEDIUM — for data infra |

---

## CURRENT GAPS (updated with research findings)

1. **~~Full ad-to-sale attribution~~** → SOLUTION: Implement `ctwa_clid` capture in WA webhook + CAPI upload
2. **Statistical significance testing** — No confidence intervals on ROAS/CPA
3. **~~Automated creative brief generation~~** → PARTIAL: meta-ads-kit has ad-copy-generator skill
4. **ASC/AAC migration** → DEADLINE May 19, 2026. Must migrate autoads scripts.
5. **Multi-brand campaign config** — Hardcoded campaign IDs per brand
6. **Rollback mechanism** — No budget change history/undo
7. **~~Competitive monitoring~~** → SOLUTION: FB Ad Library API + meta-ads-mcp
8. **Threads ads** — Live in MY/SG, untested. 400M MAU.
9. **NEW: MCP integration** — Install meta-ads-mcp for live Claude Code → Meta access
10. **NEW: Incrementality testing** — Set up geo-split test for Mirra (highest spend)

---

## BRAND PROFILES

### Mirra.eats
- **Account:** act_830110298602617
- **Daily budget:** RM2,580 (EN 85%, CN 15%)
- **7D ROAS:** 4.9x (trending up)
- **Top creative:** S19-Transformation (RM0.97/c)
- **Formula:** Fake UI + first-person + real food
- **Customer:** Michelle, 27-33, KL/PJ, M40-T20
- **Revenue Mar 2026:** RM139,905

### Pinxin Vegan Cuisine
- **Account:** act_961906233966610
- **Daily budget:** RM860 (Website RM550, CTWA RM250, RT RM60)
- **Website ROAS:** 2.8x (tracked)
- **Top creative:** TNG-PROMO (RM33 CPA, 4.78x ROAS)
- **Formula:** Identity gimmick + unique artwork per hook
- **Revenue Mar 2026:** RM73,934

### DotDot (Research Phase)
- **Status:** Creative-only, no ads live
- **Market:** HK, German collagen supplement
- **Channel:** XHS + Meta (planned)

---

## NEXT STEPS (Research Cycle 1)

Autonomous research agents are currently searching for:
1. Meta Ads API automation best practices 2025-2026
2. Creative testing frameworks at scale
3. ACCA funnel architecture
4. Attribution & measurement post-privacy
5. Growth scaling systems
6. Open source marketing tools
7. Malaysian/SEA market benchmarks
8. Sales intelligence & CRM systems
9. Conversion optimization D2C
10. Competitive intelligence automation

Results will be integrated into this document, filling the GAPS section and enhancing the PROVEN PATTERNS with world-class findings.

---

## ZENNITH SKILLS REPOSITORY (Master Repo)

**Location:** `/Users/yi-vonnehooi/Desktop/zennith-skills/`
**Type:** Multi-agent AI OS + Skills library (46+ commits, active)

### Key Directories
```
zennith-skills/
├── brands/              (14 brand directories — Mirra, Pinxin, Jade Oracle, DotDot, etc.)
├── skills/              (62+ AI automation skills — reusable across brands)
├── projects/            (apex-meta, mirra-menu-pipeline)
├── workspace-yivonne/   (Jenn's personal — 134 memory files, 7,730 lines)
│   └── knowledge/memory/  ← COMPOUND LEARNING DATABASE
├── workspace/research/  (Auto-research outputs)
└── workspace/knowledge/ (Product research, 70 products scored, 49+ suppliers)
```

### Jenn's Memory (134 Files — Complete Knowledge Base)
- 12 creative intelligence system files
- 85+ feedback/learnings files (every mistake documented)
- 20+ project state snapshots
- 10+ reference files (external system pointers)
- Major compounds: `mirra-dna.md` (22KB), `march-campaign-v3-learnings.md` (10.2KB)

### Brand Strategy Docs (Total ~70 files across brands)
- **Mirra:** 25 strategy files (ROAS playbook, campaign architecture, creative mastery, CAPI guide)
- **Pinxin:** 27 strategy files (master strategy, dual-channel, identity gimmick, 50 copy variations)
- **DotDot:** 8 strategy files (XHS research, character design, content taxonomy)
- **Bloom & Bare:** 10 strategy files (design intelligence, audience map, production playbook)

### Shared Intelligence (Cross-Brand)
- `META-ADS-INTELLIGENCE-2026-Q1.md` — Algorithm changes, API timeline, attribution
- `SOCIAL-MEDIA-MASTER-STRATEGY-2026.md` — Complete social strategy all brands
- `META-ADS-ROAS-PLAYBOOK-2026.md` — Tactical 4-5x+ ROAS guide

### OpenClaw Gateway (Multi-Agent System)
- 4 AI agents managing daily ops (Factory system)
- 62+ reusable skills
- WhatsApp, Telegram integrations
- Session management (500 max, 7-day pruning)
- Separate from Claude Code (Builder system) — both are part of Zennith

### Security Note
- `.meta-token` and `.shopify-token-pinxin` exist in repo root
- Should be rotated and moved to env-only storage

---

## FILE MAP

```
zennith-skills/                            ← MASTER REPO (all brands, skills, agents)
├── brands/                                ← 14 brand directories
├── skills/                                ← 62+ reusable skills
├── workspace-yivonne/knowledge/memory/    ← 134 compound learning files
└── projects/                              ← apex-meta, mirra-menu-pipeline

_WORK/_shared/creative-intelligence/
├── MARKETING-SALES-INTELLIGENCE.md    ← THIS FILE (master spec)
├── autoads/
│   ├── autoads_report.py              ← 5x/day performance
│   ├── autoads_analyzer.py            ← 2x/day kill/scale
│   ├── autoads_forensic.py            ← Weekly deep audit
│   ├── autoads_sheet_attribution.py   ← Daily ad-to-sale match
│   ├── autoads_autoscale.py           ← Nightly ROAS check
│   └── autoscale_state.json           ← Scale state tracking
├── social-production-engine.md        ← Creative Intelligence (exists)
└── social-media-production.md         ← Social Production (exists)

_WORK/apex-meta/
├── scripts/
│   ├── offline_conversions.py         ← Mirra CAPI upload
│   ├── offline_conversions_pinxin.py  ← Pinxin CAPI upload
│   ├── scale_*.py                     ← Budget scaling scripts
│   └── budget_shift_*.py             ← Channel rebalancing
└── backend/                           ← Reference architecture (not live)

~/.claude/projects/*/memory/
├── feedback_meta_ads_*.md             ← Hard rules from experience
├── project_*_campaign_state_*.md      ← Brand campaign snapshots
└── creative-intelligence-*.md         ← System documentation
```

---

---

## SALES INTELLIGENCE RESEARCH (Cycle 1 — 2026-03-30)

### WhatsApp Sales Pipeline (AI-Driven)
- Pipeline stages: Lead New → Qualified Lead → Proposal → Negotiation → Customer
- AI agent asks qualifying Qs (budget, intent, timeline, authority), scores, routes high-intent to human
- Sales reps spend 60% less time on admin with AI qualification
- Key metric shift: CPSC (Cost Per Started Conversation) replaces CPC
- Auto-handoff when AI detects frustration or complexity → human with full context

### WhatsApp Flows — In-Chat Commerce
- In-chat checkout: +35% conversion rate, -23% cart abandonment
- Abandoned cart recovery: 18-25% conversion within 30 minutes
- Full funnel in-chat: browse → ask → negotiate → purchase → pay (no app switching)
- Food ordering: menu images, photos, location maps, payment links all in-chat
- **Action:** Evaluate WhatsApp Flows for Mirra (current: manual WA → Google Sheet)

### RFM Segmentation (Free, Immediate Impact)
- Recency × Frequency × Monetary analysis using existing Google Sheet order data
- Food delivery: 65.2% repeat purchase intent (highest of any category)
- Segment customers: Champions, Loyal, At Risk, Lost
- Run targeted WA campaigns per segment (Champions get VIP offers, At Risk get win-back)
- **Action:** Build RFM analysis script from existing Mirra + Pinxin order sheets

### Customer LTV & Retention
- Mirra unit economics: AOV RM19, CAC RM50-80, LTV:CAC 9.1x, payback ~12 days
- Month 1 ROAS 0.3-0.8x is NORMAL for subscription/repeat models
- Cohort analysis: track monthly retention curves per acquisition channel
- Food delivery repeat rate: 65.2% intent, actual varies by brand quality

### Conversion Optimization
- WhatsApp: 45-60% CTR on WA button vs 1-3% for website
- Landing page conversion: ~2% average
- WhatsApp conversion: varies but structurally 5-10x higher engagement
- AI chatbot + human handoff = optimal for food delivery

### Competitive Intelligence
- FB Ad Library API: free, searchable by keyword/advertiser/country
- Zero competition in MY frozen vegan Meta ads (confirmed March 2026)
- Monitor: format types, copy angles, offer structures, creative volume
- **Action:** Weekly Ad Library scan for [brand] + [category] keywords

---

## PRIORITY ACTIONS (Ranked by Impact × Urgency)

### This Week
1. **Install meta-ads-mcp** — free MCP server, gives Claude live Meta API access
2. **Implement ctwa_clid capture** — closes 91.6% WhatsApp attribution gap
3. **Build RFM segmentation script** — free, uses existing order data

### Next 2 Weeks
4. **Migrate Advantage+ API** — deadline May 19, 2026
5. **Restructure campaigns for Andromeda** — 1-3 ad sets, 10-20 diverse creatives each
6. **Set up 3 automation rules** — Kill (CPA), Scale (ROAS), Fatigue (frequency)

### Next Month
7. **Deploy meta-ads-kit** — automated monitoring + fatigue detection
8. **Evaluate WhatsApp Flows** — in-chat checkout for Mirra
9. **Run geo-split incrementality test** — Mirra (highest spend)
10. **Set up Metabase dashboard** — cross-brand performance reporting

---

*This document self-improves. Every session reads it, every session updates it.*
*Failures become rules. Successes become patterns. Gaps become research targets.*
*Research Cycle 1: 2026-03-30 (50+ web queries, 2 autonomous agents, 7 research areas)*
