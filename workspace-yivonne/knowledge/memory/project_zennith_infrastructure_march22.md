---
name: Zennith Infrastructure — Desktop, GDrive, Repo, Monitoring
description: Desktop reorganized to _WORK, GDrive cleaned, Zennith repo syncing, Telegram reporting live. The operating system for all brands.
type: project
---

## Desktop Structure (cleaned 2026-03-22)
```
~/Desktop/
├── _WORK/                  ← ALL brand work
│   ├── pinxin/             ← 8 numbered folders (00-07)
│   ├── mirra/
│   ├── bloom-bare/
│   ├── jade-oracle/
│   ├── serein/
│   ├── _shared/            ← CI Module, video-compiler, fonts, autoads
│   └── _inactive/          ← dead brands
├── _PERSONAL/              ← banking, invoices, tax
├── _ARCHIVE/               ← old stuff
├── Creative Intelligence Module/  ← symlinked into _shared
├── zennith-skills/         ← git repo (team sync)
└── YIVONNE/
```

## Brand Skeleton (every brand identical)
00_brand-guide/ → 01_assets/ → 02_strategy/ → 03_research/ → 04_references/ → 05_scripts/ → 06_exports/{finals,campaigns,rejected,archive} → 07_working/
Scaffold: `BRAND-SKELETON.md` in _WORK/_shared/

## Output Routing
All outputs → `_WORK/[brand]/06_exports/campaigns/[name]/`
Approved → `finals/` | Rejected → `rejected/` + REJECTION-LOG.md
NEVER: /tmp, Desktop root, random folders

## Google Drive (love@huemankind.world)
- Cleaned: 3,844 loose files sorted into _ZENNITH/_archive/
- Structure: _ZENNITH/{pinxin,mirra,bloom-bare,jade-oracle,serein}
- Existing Pinxin/Mirra/Knowledge Base folders kept (symlinked)
- 687 Google Docs/Sheets at root need manual cleanup via drive.google.com

## Zennith Skills Repo (github.com/jennwoei316/zennith-skills)
- Team: Jenn (iMac), Tricia (MacBook), Yivonne (MacBook)
- Pushed: Meta Ads intelligence, campaign status, brand skeleton, identity-gimmick-promo skill
- Daily: git pull → work → git push

## Telegram Reporting
- Bot: @ZennithAdsBot (token: [REDACTED — set TG_BOT_TOKEN env var])
- Chat: 5056806774 (@yivonnehooi)
- Schedule: 12am, 10am, 3pm, 8pm, 10pm (crontab)
- Reports: Meta Ads + Shopify + Google Sheet WA sales for Pinxin + Mirra
- Script: _WORK/_shared/creative-intelligence/autoads/autoads_report.py

## GDrive Sync (TODO)
- Need Jenn to set up "Folders from my computer" for team-wide access
- Guide: zennith-skills/workspace/knowledge/GDRIVE-SHARED-DRIVE-SETUP.md
