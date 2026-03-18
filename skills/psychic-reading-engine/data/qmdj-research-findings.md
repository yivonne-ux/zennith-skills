# QMDJ Deep Research Findings
> Compiled: 2026-03-17 | Source: Web research across Chinese + English sources

## Chart Types Hierarchy

年吉不如月吉，月吉不如日吉，日吉不如时吉
"Yearly fortune < Monthly < Daily < **Hourly** (时盘 is king)"

| Chart | Chinese | Cycle | Use |
|-------|---------|-------|-----|
| **时盘 (Hourly)** | 最验 (most accurate) | 2-hour periods, 12/day | Daily content, specific questions |
| 日盘 (Daily) | Uses different 9 stars | 1/day, 120 configs | Simpler daily forecast |
| 月盘 (Monthly) | 5-year = 1 yuan | Monthly forecast | Long-term planning |
| 年盘 (Yearly) | 60-year cycle | Macro fortune | National/geopolitical |
| **终身盘 (Lifetime)** | Birth-based | Entire life | PAID PRODUCT ($97-497) |

## Our Technical Decisions (CONFIRMED CORRECT)

| Decision | Our Choice | Status |
|----------|-----------|--------|
| Plate method | 转盘 (Rotating) | CORRECT — mainstream standard |
| Calendar method | 拆补法 (Split-Patch) | CORRECT — industry standard |
| Solar terms | PyEphem astronomical | CORRECT — real sun position |
| Time system | Standard timezone | OK for content, add true solar for paid |

## Gaps to Fix in qmdj-calc.py

1. **True solar time**: Add longitude input → compute offset for paid readings
2. **终身盘 mode**: Map life into 8x15-year periods across 8 palaces
3. **Cross-validate**: Check against rebu.net.cn and qimen.live for 50 dates

## Validation Tools

| Tool | URL | Method |
|------|-----|--------|
| **热卜排盘** | rebu.net.cn | 拆补/置闰/茅山 all supported |
| **qimen.live** | qimen.live (Kevin Foong) | 拆补法, longitude correction |
| **qimen.guru** | qimen.guru | Modern calculator |
| **kinqimen** | GitHub (Python, MIT) | Open source, JSON output |
| **QiAdvisor** | qiadvisor.ai | Free calculator |

## Most Engaging Content Elements for TikTok

1. **八门 (Eight Doors)** — most intuitive. "Death Door sits South — avoid!" Creates urgency
2. **三奇 (Three Marvels)** — 乙丙丁 in good positions = "lucky day" content
3. **Love readings** — #1 topic on Douyin. "Will my crush text back?"
4. **Career/Money** — #2 topic. "Is today good for signing contracts?"
5. **格局 (Special Formations)** — 龙回首, 虎猖狂 = viral hooks
6. **吉时 (Lucky Hours)** — "Best 2 hours today to decide" — shareable
7. **Mystique factor** — QMDJ's high barrier = "premium mysticism" positioning

## Content Format

- **Daily 30-60s**: Today's QMDJ energy + visual chart + 3 key points (best door, worst door, lucky hour)
- **Weekly deep-dive**: Most interesting 格局 of the week
- **Birth year series**: "Born in [year]? Your destiny palace is..." (drives comments)
- **Interactive**: "Comment your birth hour → I'll tell your destiny door"

## Key Insight
"门槛足够高、话术足够陌生的奇门遁甲，确实更能满足人们在玄学方面'消费升级'的需求"
(QMDJ's high barrier and unfamiliar terms satisfy the demand for "premium mysticism")
→ This is our moat. Tarot/zodiac is saturated. QMDJ is premium positioning.
