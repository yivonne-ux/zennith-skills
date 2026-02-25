---
name: seasonal-marketing-os
version: "1.0.0"
description: "Automated seasonal marketing calendar and campaign playbooks for Malaysian market. CNY, Hari Raya, Deepavali, 11.11, all e-commerce dates, food holidays. Pre-built campaign briefs per season."
---

# Seasonal Marketing Operating System

## Purpose
Never miss a season. Auto-generate campaign briefs 4 weeks before each event. Track what worked last year. Compound seasonal intelligence.

## 2026 Master Calendar

### Q1: New Beginnings
| Date | Event | Priority | Campaign Type | Budget Weight |
|---|---|---|---|---|
| Jan 1 | New Year | Medium | New Year New You | 1x |
| Jan 14 | Ponggal/Thaipusam | Low | Community content | 0.5x |
| Jan ~29 | CNY | **HIGH** | 🧧 Gift hampers, family feast | 3x |
| Feb 2 | 2.2 Sale | Medium | Flash deals | 1.5x |
| Feb 14 | Valentine's | Medium | Couple bundles | 1x |
| Feb ~28 | Ramadan starts | **HIGH** | 🌙 Iftar packs, suhoor meals | 3x |

### Q2: Festive Peak
| Date | Event | Priority | Campaign Type | Budget Weight |
|---|---|---|---|---|
| Mar 3 | 3.3 Sale | Medium | Flash deals | 1.5x |
| Mar ~30 | Hari Raya Aidilfitri | **HIGH** | 🕌 Raya hampers, open house | 3x |
| Apr 4 | 4.4 Sale | Low | Flash deals | 1x |
| May ~12 | Mother's Day | Medium | Gift bundles, tribute | 1.5x |
| May 5 | 5.5 Sale | Medium | Mid-year push | 1.5x |
| May 12 | Wesak | Low | Vegan awareness | 0.5x |

### Q3: Building
| Date | Event | Priority | Campaign Type | Budget Weight |
|---|---|---|---|---|
| Jun 6 | 6.6 Mid-Year | Medium | Clearance + new launch | 2x |
| Jun 15 | Father's Day | Low | Gift bundles | 1x |
| Jul 7 | 7.7 Sale | Medium | Flash deals | 1.5x |
| Aug 8 | 8.8 Sale | Medium | Flash deals | 1.5x |
| Aug 31 | Merdeka | **HIGH** | 🇲🇾 Malaysian pride, local food | 2x |

### Q4: Mega Season
| Date | Event | Priority | Campaign Type | Budget Weight |
|---|---|---|---|---|
| Sep 9 | 9.9 Sale | **HIGH** | Start mega season | 2x |
| Sep 16 | Malaysia Day | Medium | Unity content | 1x |
| Oct ~20 | Deepavali | Medium | Festival of lights bundles | 1.5x |
| Oct 10 | 10.10 Sale | **HIGH** | Mega sale | 2.5x |
| Nov 1 | World Vegan Day | Medium | Brand awareness push | 1.5x |
| Nov 11 | 11.11 Singles Day | **CRITICAL** | 🔥 Biggest sale of year | 5x |
| Nov ~28 | Black Friday | **HIGH** | International sale | 3x |
| Dec 1 | Cyber Monday | Medium | Extension of BF | 2x |
| Dec 12 | 12.12 Sale | **HIGH** | Year-end mega | 3x |
| Dec 25 | Christmas | Medium | Gift sets, year wrap | 1.5x |
| Dec 31 | Year End | Low | Review content, gratitude | 0.5x |

### Food & Wellness Calendar
| Date | Event | Content Opportunity |
|---|---|---|
| Jan 1-31 | Veganuary | Plant-based awareness campaign |
| Mar 20 | World Meatless Day | Challenge content |
| Apr 7 | World Health Day | Health benefits content |
| Apr 22 | Earth Day | Sustainability story |
| Jun 5 | World Environment Day | Eco-friendly packaging story |
| Jun 21 | International Yoga Day | Wellness + food content |
| Aug 10 | World Lion Day | Animal welfare content |
| Oct 1 | World Vegetarian Day | Veggie celebration |
| Oct 16 | World Food Day | Food security, nutrition |
| Nov 1 | World Vegan Day | MAJOR — full campaign |

## Campaign Brief Template (Auto-Generated 4 Weeks Before)

```yaml
campaign_name: "[Event] 2026 — [Brand]"
event: "[event name]"
date: "[event date]"
brands: ["gaia-eats", "pinxin", "etc"]
duration: "4 weeks (tease → build → launch → extend)"
budget: "RM [X] (based on budget weight)"

objectives:
  primary: "[awareness/consideration/conversion]"
  target_roas: "[X]x"
  target_revenue: "RM [X]"

audience:
  primary: "[segment]"
  secondary: "[segment]"
  retarget: "[past purchasers, website visitors]"

creative_requirements:
  tofu: "[X] pieces — [types]"
  mofu: "[X] pieces — [types]"
  bofu: "[X] pieces — [types]"
  formats: ["image 1:1", "video 9:16", "carousel"]

offers:
  hero_offer: "[main promotion]"
  upsell: "[bundle/subscription offer]"
  early_bird: "[pre-launch incentive]"

channels:
  paid: ["Meta Ads", "TikTok Ads"]
  organic: ["IG", "TikTok", "FB", "Email", "WhatsApp"]
  marketplace: ["Shopee", "Lazada"]

timeline:
  week_1_tease: "[content plan]"
  week_2_build: "[content plan]"
  week_3_launch: "[content plan]"
  week_4_extend: "[content plan]"

historical:
  last_year_revenue: null
  last_year_roas: null
  last_year_top_creative: null
  lessons_learned: []
```

## Seasonal Compound Learning

After every campaign:
```
1. Performance data → seed bank (tagged with season)
2. Winning creatives → archive with seasonal tag
3. Lessons learned → seasonal-marketing-os historical data
4. Next year: Auto-load last year's data into brief
5. Year over year: Track seasonal revenue growth
```

### Learning Storage
```
~/.openclaw/workspace/data/seasonal/
  ├── 2026/
  │   ├── cny-2026-results.yaml
  │   ├── ramadan-2026-results.yaml
  │   ├── 1111-2026-results.yaml
  │   └── ...
  └── patterns/
      ├── cny-patterns.yaml      # What works for CNY across years
      ├── ramadan-patterns.yaml   # What works for Ramadan
      └── mega-sale-patterns.yaml # What works for 11.11/12.12
```

## Cron Jobs
```bash
# Monthly: Generate next month's campaign briefs
0 9 1 * * bash seasonal-brief-generator.sh $(date +%Y-%m)

# Weekly: Check upcoming events (2-week lookahead)
0 9 * * 1 bash seasonal-check.sh --lookahead 14

# Post-campaign: Auto-generate results report
# (triggered by campaign end date)
```

## CHANGELOG
### v1.0.0 (2026-02-20)
- Full 2026 Malaysian marketing calendar, campaign brief template, compound learning system
