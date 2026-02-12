---
name: credential-resolver
version: "1.0.0"
description: Auth barrier resolution protocol. Teaches agents how to systematically break through login walls, expired tokens, rate limits, and missing credentials.
metadata:
  openclaw:
    scope: protocol
    guardrails:
      - Never brute-force or bypass security measures
      - Never store credentials in code or git
      - Always try public endpoints before authenticated ones
      - Document every attempt in feedback room
      - Ask Jenn for help when all strategies fail
---

# Credential Resolver — Auth Barrier Protocol

## Purpose

When agents hit auth barriers (login walls, expired tokens, rate limits, CAPTCHAs), they don't give up. They follow this resolution protocol systematically, trying every available approach before escalating.

**Principle:** Try public first. Use existing credentials second. Ask Jenn last. Never fabricate data.

---

## Resolution Strategy (In Order)

### 1. Check Existing Credentials
Before doing anything else, check what's already available:

```
~/.openclaw/secrets/
  ├── meta-marketing.env    → Meta Ads API (NOT YET CONFIGURED)
  ├── klaviyo.env            → Klaviyo API key
  ├── klaviyo.key            → Klaviyo private key backup
  ├── maton.env              → Maton OAuth gateway
  ├── maton.key              → Maton API key
  ├── shopify-oauth.env      → Shopify OAuth (generic)
  ├── shopify-pinxin.env     → Shopify Pinxin store
  ├── shopify-sg.env         → Shopify Singapore
  ├── moonshot.env           → Kimi API
  ├── openrouter.env         → Qwen3 API
  ├── gemini.env             → Google Gemini
  ├── dashscope.env          → DashScope (Alibaba)
  ├── brave.env              → Brave browser
  └── openai.env             → OpenAI (DEPRECATED)

~/.openclaw/workspace/ops/auth/
  ├── meta_capi_token.txt    → Meta Conversions API token
  ├── n8n.storageState.json  → n8n browser session
  ├── chatwoot.storageState.json → Chatwoot browser session
  └── dashboard.env          → Dashboard credentials
```

### 2. Try Public Endpoints First
Many platforms have public data that doesn't need auth:

| Platform | Public Access | What's Available |
|----------|--------------|------------------|
| Meta Ad Library | YES | All active ads, creative text, advertiser names |
| TikTok Creative Center | YES | Trending hashtags, sounds, top ads, keywords |
| YouTube | YES | Search results, video metadata, public comments |
| Instagram (public) | PARTIAL | Public profiles, hashtag pages (may hit login wall) |
| Shopee | YES | Product search, listings, reviews, seller pages |
| Lazada | YES | Product search, listings, reviews |
| Google Trends | YES | Search trends, related queries |

**Rule:** Always try public access before authenticated access. If public data is sufficient for the task, don't use credentials.

### 3. Use OAuth Gateways
For platforms with OAuth:

| Platform | Gateway | How to Use |
|----------|---------|------------|
| Klaviyo | Maton OAuth | `GET https://gateway.maton.ai/klaviyo/api/...` with MATON_API_KEY |
| Shopify | OAuth server | `node ~/.openclaw/workspace/ops/shopify/oauth_server.mjs` |

**Verify before claiming "connected":** Always probe the API endpoint first. Don't assert connectivity based on having a key — test it.

### 4. Reuse Playwright Browser Sessions
Stored browser sessions can bypass login for web scraping:

```python
# Load stored session
context = browser.new_context(
    storage_state="~/.openclaw/workspace/ops/auth/n8n.storageState.json"
)
```

**Available sessions:** n8n, Chatwoot
**Note:** Sessions expire. If a stored session doesn't work, log the failure and try other strategies.

### 5. Request Human Help (Jenn)
When all automated strategies fail:

1. Post to feedback room with structured request:
```json
{
  "ts": "<timestamp>",
  "agent": "<agent>",
  "room": "feedback",
  "type": "credential-request",
  "msg": "Need credentials for [PLATFORM].\n\nWhat I tried:\n1. [strategy 1] → [result]\n2. [strategy 2] → [result]\n\nWhat I need from Jenn:\n- [specific action, e.g., 'Log into Meta Business Suite, go to Settings > System Users, generate a token with ads_management permission']\n\nOnce provided, save to: ~/.openclaw/secrets/[filename].env"
}
```

2. Also post to townhall for Zenni to track
3. Include exact instructions so Jenn can do it quickly

### 6. Document the Gap
If the platform truly can't be accessed:

1. File to `~/.openclaw/workspace/corp-os/gaps/`
2. Include: what was tried, what's needed, estimated impact
3. Mark as `credential` type gap
4. The nightly review will track unresolved credential gaps

---

## Credential Registry

### Active (Working)

| Service | Status | Location | Method |
|---------|--------|----------|--------|
| Klaviyo (EDM) | ACTIVE | Maton OAuth | `GET https://gateway.maton.ai/klaviyo/...` |
| Meta CAPI | ACTIVE | `ops/auth/meta_capi_token.txt` | Direct token |
| Shopify (3 stores) | ACTIVE | `secrets/shopify-*.env` | OAuth |
| n8n | SESSION | `ops/auth/n8n.storageState.json` | Browser state |
| Chatwoot | SESSION | `ops/auth/chatwoot.storageState.json` | Browser state |

### Not Yet Configured

| Service | Needed For | Setup Instructions |
|---------|-----------|-------------------|
| Meta Marketing API | Ad management, performance analysis | See `meta-ads-manager` skill setup guide |
| Google Sheets API | Sales data automation | Create service account at console.cloud.google.com |
| TikTok Seller Center | Shop management, order data | Login at seller.tiktokshop.com |
| Shopee Seller API | Order data, listing management | Apply at open.shopee.com |
| Instagram Graph API | Page insights, story analytics | Via Meta Business Suite (same token as Marketing API) |

### Public (No Auth Needed)

| Service | What's Available |
|---------|------------------|
| Meta Ad Library | Competitor ads (scraper built) |
| TikTok Creative Center | Trends, sounds, top ads (scraper built) |
| YouTube | Search, video metadata (scraper built) |
| Shopee (public) | Product listings, reviews (scraper built) |
| Google Trends | Search trends (via site-scraper) |

---

## Error Handling Patterns

### Rate Limited
```
Symptom: HTTP 429, "Too Many Requests"
Action: Wait 60s, then retry with exponential backoff (60s, 120s, 240s)
Max retries: 3
If still failing: Log to feedback room, try again in 1 hour via cron
```

### Token Expired
```
Symptom: HTTP 401, "Invalid access token"
Action: Check if refresh token exists. If yes, refresh. If no, file credential-request.
For Maton: Check connection status at https://ctrl.maton.ai/connections
```

### Login Wall
```
Symptom: Page redirects to login form
Action:
1. Check for stored Playwright session
2. If no session, try the direct URL (some pages work without login)
3. If login required, file credential-request for Jenn to create browser session
```

### CAPTCHA
```
Symptom: CAPTCHA challenge blocking scraper
Action:
1. Reduce scraping frequency
2. Add random delays (2-5s between requests)
3. If persistent, file gap — may need residential proxy or manual session
Never: Auto-solve CAPTCHAs with third-party services
```

---

## Agent Protocol

When any agent encounters an auth barrier:

1. **Don't panic.** Check this skill for the resolution strategy.
2. **Try strategies 1-4** in order (check creds → public → OAuth → browser session)
3. **Log every attempt** to feedback room with what was tried and what happened
4. **If all fail** → strategy 5 (request Jenn's help) with clear, actionable instructions
5. **Never fabricate data.** Say "I couldn't access X because Y" — honesty over completeness.
6. **Never retry silently.** Every failure is visible in the feedback room.

## CHANGELOG

### v1.0.0 (2026-02-12)
- Initial creation: resolution protocol, credential registry, error handling patterns
