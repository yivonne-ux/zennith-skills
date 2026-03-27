# Shopify Admin — Token & API Skill

Reusable Shopify Admin API authentication and operations.

## Token Generation (CRITICAL)

Shopify custom apps use `grant_type=client_credentials`. **NEVER use OAuth redirect flow.**

```bash
curl -s -X POST "https://{STORE}.myshopify.com/admin/oauth/access_token" \
  -H "Content-Type: application/json" \
  -d '{"client_id":"{CLIENT_ID}","client_secret":"{CLIENT_SECRET}","grant_type":"client_credentials"}'
# Returns: {"access_token":"shpat_xxx","scope":"...","expires_in":86399}
```

Token expires every **24 hours**. Always refresh before API calls.

## Scripts

```bash
# Get token (refreshes if expired):
~/.claude/skills/shopify-admin/scripts/token.sh

# Test current token:
~/.claude/skills/shopify-admin/scripts/token.sh --test

# Force refresh:
~/.claude/skills/shopify-admin/scripts/token.sh --refresh

# API calls (auto-refreshes token):
~/.claude/skills/shopify-admin/scripts/api.sh GET products/count.json
~/.claude/skills/shopify-admin/scripts/api.sh POST products.json '{"product":{...}}'
~/.claude/skills/shopify-admin/scripts/api.sh PUT themes/123/assets.json '{"asset":{...}}'
```

## Config (shopify.config.json in project dir)

Set `SHOPIFY_CONFIG` env var to override config path. Default: `./shopify.config.json`

## Known Stores

| Store | Password | Plan |
|-------|----------|------|
| pinxin-test.myshopify.com | deeffu | Shopify Plus |

## Rules
- NEVER try OAuth redirect flow — fails with "redirect_uri must match app URL"
- NEVER ask user to manually create tokens — use client_credentials
- NEVER hardcode tokens — always use token.sh
- client_id + client_secret are permanent; token is ephemeral (24h)
