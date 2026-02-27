---
name: meta-ads-manager
version: "1.0.0"
description: Meta Marketing API integration for campaign management, creative upload, and performance analysis. Credential-ready — will activate once API token is configured.
metadata:
  openclaw:
    scope: marketing-api
    guardrails:
      - All write actions require Zenni governance approval
      - Ad creation = DRAFT ONLY, never auto-publish
      - Budget changes require Jenn's explicit approval
      - Never delete campaigns without confirmation
      - Credentials stored in ~/.openclaw/secrets/meta-marketing.env
---

# Meta Ads Manager — Marketing API Integration

## Purpose

Full Meta Marketing API integration for GAIA's performance marketing engine. Builds on existing `meta_capi_sender.py` (purchase events). Adds campaign management, creative upload, and performance analysis.

**Status: CREDENTIAL-READY** — skill is built and tested. Activate by configuring `~/.openclaw/secrets/meta-marketing.env`.

## Setup (For Jenn)

### Step 1: Create Meta System User Token
1. Go to business.facebook.com → Business Settings → System Users
2. Create a System User (or use existing)
3. Generate a token with these permissions:
   - `ads_management` — create/edit ads
   - `ads_read` — read campaign performance
   - `pages_read_engagement` — page insights
   - `business_management` — account access
4. Copy the token

### Step 2: Configure Credentials
Create `~/.openclaw/secrets/meta-marketing.env`:
```
META_ACCESS_TOKEN=your_token_here
META_AD_ACCOUNT_ID=act_123456789
META_PIXEL_ID=123456789
META_PAGE_ID=123456789
META_BUSINESS_ID=123456789
```

### Step 3: Test Connection
```bash
python3 ~/.openclaw/skills/meta-ads-manager/scripts/meta_ads_api.py --check-auth
```

## Capabilities

### Read Operations (No approval needed)
- Campaign performance (ROAS, CPA, CPM, CTR, spend)
- Ad set breakdowns (by age, gender, placement, device)
- Creative performance (which creatives convert best)
- Audience insights (custom audience sizes, lookalike estimates)
- Account-level metrics (daily spend, account status)

### Write Operations (Zenni approval required)
- Upload ad creatives (images/video)
- Create ad drafts (NOT auto-publish — paused by default)
- Duplicate winning ad sets
- Adjust budgets (requires Jenn approval for changes > RM 500)

### Analysis Operations
- Creative fatigue detection (CTR declining over 3+ days)
- Winning creative patterns (what hooks/formats/CTAs convert)
- Budget allocation recommendations (shift spend to winners)
- Audience overlap analysis (reduce wasted spend)

## Usage

```bash
# Check authentication status
python3 meta_ads_api.py --check-auth

# Get campaign performance (last 7 days)
python3 meta_ads_api.py --campaigns --days 7

# Get top performing creatives
python3 meta_ads_api.py --top-creatives --days 30 --limit 10

# Upload creative (draft only)
python3 meta_ads_api.py --upload-creative --image /path/to/image.jpg --name "CNY Bundle Hero"

# Creative fatigue check
python3 meta_ads_api.py --fatigue-check --days 14
```

## Governance Gates

| Action | Approval | Why |
|--------|----------|-----|
| Read performance data | None | Information only |
| Upload creative (draft) | Zenni | Keeps creative quality controlled |
| Create ad (paused) | Zenni | New spend requires review |
| Activate ad | Jenn | Real money starts flowing |
| Change budget | Jenn (if > RM 500) | Budget allocation is executive decision |
| Pause/delete campaign | Zenni | May affect revenue |

## Agent Assignment

- **Hermes ⚡** — campaign management, budget optimization, offer testing
- **Athena 🦉** — performance analysis, ROAS tracking, fatigue detection
- **Dreami 🎭** — creative upload, A/B variant management
- **Zenni 👑** — governance approval for all write operations

## Integration with Existing Tools

- **meta_capi_sender.py** — sends purchase events (already working)
- **meta-ads-library** — scrapes competitor ads for creative inspiration
- **content-intel** — provides ad creative templates and specs
- **art-director** — validates creative against brand guidelines

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial creation: Meta Marketing API client, credential-ready, governance gates defined
