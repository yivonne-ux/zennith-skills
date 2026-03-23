---
name: social-publish
description: Social media publishing pipeline for GAIA brands. Posts images, carousels, reels to Instagram via Meta Graph API. Token management, scheduling, health checks.
agents: [taoz, zenni]
version: 1.0.0
---

# Social Publish — Instagram Publishing Pipeline

Automated posting to Instagram via Meta Graph API for GAIA brands (starting with Jade Oracle).

## Architecture

```
Content (images/captions) → Meta Graph API → Instagram
Token Manager → validates/refreshes tokens → ~/.openclaw/secrets/meta-marketing.env
Health Check → monitors token validity, posting success, rate limits
```

## Scripts

| Script | Purpose |
|--------|---------|
| `jade-auto-post.sh` | Main posting script called by jade-daily-dispatch.sh evening cycle |
| `meta-token-manager.sh` | Token validation, refresh, exchange (short-lived → long-lived) |
| `ig-publish.py` | Core Instagram Graph API publisher (image, carousel, reel) |
| `jade-ig-health-check.sh` | Monitors token validity, posting history, loop health |

## Token Flow

1. **Get short-lived token**: via `meta-ig-setup.py` (browser-use, manual login)
2. **Exchange for long-lived**: via `meta-token-manager.sh exchange` (60-day token)
3. **Validate daily**: via `meta-token-manager.sh validate` (checks expiry, permissions)
4. **Auto-refresh**: via `meta-token-manager.sh refresh` (before expiry)

## Instagram Graph API Flow (Single Image)

1. POST image to container: `POST /{ig-user-id}/media` with `image_url` + `caption`
2. Wait for container processing
3. Publish container: `POST /{ig-user-id}/media_publish` with `creation_id`

## Secrets Required

File: `~/.openclaw/secrets/meta-marketing.env`

```
META_ACCESS_TOKEN=EAA...
META_APP_ID=1647272119493183
META_APP_SECRET=<from Meta Developer Console>
IG_USER_ID=<from /me/accounts → ig_id>
IG_PAGE_ID=<Facebook Page ID linked to IG>
```

## Usage

```bash
# Post today's best content to Instagram
bash jade-auto-post.sh 2026-03-21

# Validate token
bash meta-token-manager.sh validate

# Exchange short-lived → long-lived token
bash meta-token-manager.sh exchange

# Health check
bash jade-ig-health-check.sh
```
