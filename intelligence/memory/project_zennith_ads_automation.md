---
name: Zennith Automated Ads Monitoring System
description: Full automated ads system — reports, analyzer, forensic audit, intelligence sweep, offline conversions. All brands. Built March 24, 2026.
type: project
---

## ZENNITH ADS AUTOMATION — Complete System (March 24, 2026)

**Why:** Manual ads monitoring doesn't scale across brands. Built automated monitoring with human-approval action model.

### SCHEDULE (All times MYT)

| Time | Script | What | Location |
|------|--------|------|----------|
| 12:00 AM | `autoads_report.py` | Numbers → Telegram | crontab |
| 12:03 AM | Intelligence Sweep | Web research → Meta updates → Telegram | Claude remote agent `trig_01HyX4sTCWDyK3ChTipDTXNv` |
| 10:00 AM | `autoads_report.py` + `autoads_analyzer.py` | Numbers + kill/scale/creative recs → Telegram | crontab |
| 3:00 PM | `autoads_report.py` | Numbers → Telegram | crontab |
| 8:00 PM | `autoads_report.py` | Numbers → Telegram | crontab |
| 10:00 PM | `autoads_report.py` + `autoads_analyzer.py` | Numbers + kill/scale/creative recs → Telegram | crontab |
| 11:37 PM | `offline_conversions.py` | Mirra WA sales → Meta CAPI | crontab |
| 11:40 PM | `offline_conversions_pinxin.py` | Pinxin WA sales → Meta CAPI | crontab |
| Sunday 12AM | `autoads_forensic.py` | Weekly deep audit + creative brief → Telegram | crontab |

### FILES

```
_WORK/_shared/
├── .meta-token                              # Meta API token (60-day, all scripts)
├── .shopify-token-pinxin                    # Shopify auto-refresh
├── intelligence/
│   └── META-ADS-INTELLIGENCE-2026-Q1.md     # Master knowledge base (v22.0 API)
├── references/mood-photography/             # Mood refs (shared all brands)
└── creative-intelligence/autoads/
    ├── autoads_report.py                    # 5x daily reports (v22.0 API)
    ├── autoads_analyzer.py                  # 2x daily analysis (kill/scale/creative)
    ├── autoads_forensic.py                  # Weekly deep audit
    ├── shopify_helper.py                    # Shopify integration
    └── audits/                              # Weekly audit archives

_WORK/apex-meta/scripts/
├── offline_conversions.py                   # Mirra CAPI upload (v22.0)
├── offline_conversions_pinxin.py            # Pinxin CAPI upload (v22.0)
├── activate_sbb_midnight.py                # SBB activation
└── upload_sbb_videos.py                    # Video upload
```

### BRAND CONFIG (in analyzer + forensic)
Both brands configured with campaign IDs, kill/scale thresholds, WA sheet URLs. Add new brands by adding to `BRANDS` dict.

### API VERSION
All scripts updated from v21.0 → v22.0 (March 24). v25.0 has breaking attribution changes — stay on v22.0 until tested.

### REQUIREMENTS
- macOS cron needs **Full Disk Access** for `/usr/sbin/cron` (granted March 24)
- Meta token: 60-day, path `~/_WORK/_shared/.meta-token`
- Telegram bot: `8734667533` → chat `5056806774`
- Claude remote agent: `trig_01HyX4sTCWDyK3ChTipDTXNv` (manage at claude.ai/code/scheduled)

### OFFLINE CONVERSIONS STATUS
- Mirra: 41 events uploaded, 2 matched by Meta (4.9% match rate, improving over 48hrs)
- Pinxin: 25 events uploaded, pending match
- Both upload last 7 days of WA sales from Google Sheets → Meta CAPI as Purchase events

### KEY INTELLIGENCE FINDINGS (March 24 research)
- Andromeda = creative-first (entity IDs, not audience targeting)
- Malaysia CPM $3.42 (83% cheaper than US)
- Food & Bev = 2.02% CVR (highest industry)
- Only 5% of ads win → need volume (50-70/week)
- API v25.0 removes 7d/28d view-through attribution
- ASC/AAC full deprecation May 19, 2026
- WhatsApp per-message pricing (July 2025), CTWA 72hr free window
- Threads ads live in MY/SG (400M MAU)
