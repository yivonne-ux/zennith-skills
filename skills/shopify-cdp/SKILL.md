---
name: shopify-cdp
description: Shopify admin automation via Pinchtab browser. Create/delete products, manage collections, configure store — all through real signed-in Chrome. No API token needed. Self-evolving.
version: 2.0.0
agents: [taoz, main]
evolves: true
last_patched: 2026-03-21
patch_log: patches/CHANGELOG.md
---

# Shopify CDP — Admin Automation via Pinchtab

## Why This Exists
Shopify CLI = theme only. Admin API = needs `shpat_` token. Getting token = manual UI clicks. This skill bypasses ALL of that — controls real Chrome via Pinchtab to do anything a human can do in Shopify admin.

## Stack
- **Pinchtab v0.8.4** — headless Chrome via HTTP API, ~100ms per command
- **NO Playwright** — Pinchtab is lighter, faster, uses accessibility refs (not CSS selectors)
- **Self-evolving** — patches go in `patches/`, learnings compound in `learnings.md`

## Store Details

| Key | Value |
|-----|-------|
| Store | `7qz8cj-uu.myshopify.com` |
| Admin | `https://admin.shopify.com/store/7qz8cj-uu` |
| Domain | `jadeoracle.co` |
| Account | `penanghuatgroup@gmail.com` |
| Client ID | Stored in `~/.openclaw/secrets/shopify-client-id` |
| Client Secret | Stored in `~/.openclaw/secrets/shopify-client-secret` |

## Quick Start

```bash
# 1. Start Pinchtab with your Chrome profile (already logged into Shopify)
BRIDGE_HEADLESS=false \
BRIDGE_PROFILE=~/.chrome-cdp \
pinchtab &

# 2. Navigate to Shopify admin
pinchtab nav "https://admin.shopify.com/store/7qz8cj-uu/products"

# 3. Snapshot to see what's there
pinchtab snap -i -c

# 4. Act on refs (click, type, etc.)
pinchtab click e5
```

## Login Flow (First Time Only)

```bash
# Launch headed so you can see and login
BRIDGE_HEADLESS=false \
BRIDGE_PROFILE=~/.chrome-cdp \
pinchtab &

# Navigate to Shopify login
pinchtab nav "https://admin.shopify.com/store/7qz8cj-uu"

# User logs in manually in the Chrome window
# Session persists in ~/.chrome-cdp/ for all future runs

# Verify logged in
pinchtab text | grep -i "products\|orders\|home"
```

## Operations

### List Products
```bash
pinchtab nav "https://admin.shopify.com/store/7qz8cj-uu/products"
sleep 5
pinchtab snap -i -c | grep -i "reading\|chart\|mentor"
```

### Create Product
```bash
pinchtab nav "https://admin.shopify.com/store/7qz8cj-uu/products/new"
sleep 5
pinchtab snap -i -c

# Find the title input ref, e.g. e12
pinchtab type e12 "Product Name"
sleep 1

# Find price input ref, e.g. e25
pinchtab type e25 "29.00"
sleep 1

# Find Save button ref, e.g. e40
pinchtab click e40
sleep 3
```

### Delete Product
```bash
pinchtab nav "https://admin.shopify.com/store/7qz8cj-uu/products/PRODUCT_ID"
sleep 4
pinchtab snap -i -c

# Find "More actions" button
pinchtab click e_MORE_ACTIONS_REF
sleep 1
pinchtab snap -i -c

# Find "Delete product" menu item
pinchtab click e_DELETE_REF
sleep 2
pinchtab snap -i -c

# Find confirm "Delete" button
pinchtab click e_CONFIRM_REF
sleep 3
```

### Remove Store Password
```bash
pinchtab nav "https://admin.shopify.com/store/7qz8cj-uu/online_store/preferences"
sleep 5
pinchtab snap -i -c

# Find password toggle, uncheck it
pinchtab click e_PASSWORD_CHECKBOX
sleep 1
pinchtab click e_SAVE_BUTTON
```

### Take Screenshot
```bash
pinchtab ss -o /tmp/shopify-state.jpg
```

## Scripts

### `scripts/shopify-products.sh` — Batch Product CRUD
```bash
bash ~/.openclaw/skills/shopify-cdp/scripts/shopify-products.sh list
bash ~/.openclaw/skills/shopify-cdp/scripts/shopify-products.sh create "Title" "29.00" "Description"
bash ~/.openclaw/skills/shopify-cdp/scripts/shopify-products.sh delete PRODUCT_ID
```

### `scripts/shopify-ensure-pinchtab.sh` — Start Pinchtab if not running
```bash
bash ~/.openclaw/skills/shopify-cdp/scripts/shopify-ensure-pinchtab.sh
```

## Current Products (2026-03-21)

| ID | Product | Price |
|----|---------|-------|
| 8531546636367 | Intro Psychic Reading | $1 |
| 8528728293455 | Love & Relationships Reading | $29 |
| 8528732422223 | Career & Purpose Reading | $47 |
| 8528737304655 | Full Destiny Chart | $97 |
| 8528742580303 | Monthly Mentorship with Jade | $497 |

## Gotchas (Learned the Hard Way)

1. **Shopify admin is a React SPA** — always `sleep 5-8` after navigation. Pinchtab `snap` too early = empty refs
2. **Refs change on page reload** — always re-snapshot after navigation or significant UI change
3. **Google OAuth on fresh profile** — Google won't trust headless Chrome. First login MUST be headed (`BRIDGE_HEADLESS=false`)
4. **`--user-data-dir` required** — Chrome rejects CDP on default profile dir. Use `~/.chrome-cdp/`
5. **Playwright is too heavy** — Pinchtab is 100x lighter, HTTP API not WebSocket, shell-native
6. **Product page takes 6-8s to fully render** — don't interact before then
7. **"More actions" dropdown** — refs inside dropdown only appear AFTER clicking the trigger button. Two-step: click trigger → snap → click menu item

## Self-Evolution

This skill is designed to **compound learnings**. After every Shopify session:

### How to Patch
```bash
# 1. Document what you learned
echo "## $(date +%Y-%m-%d) — What happened" >> ~/.openclaw/skills/shopify-cdp/learnings.md
echo "- Finding: ..." >> ~/.openclaw/skills/shopify-cdp/learnings.md
echo "- Fix: ..." >> ~/.openclaw/skills/shopify-cdp/learnings.md

# 2. If it's a reusable pattern, add to patches/
cat > ~/.openclaw/skills/shopify-cdp/patches/PATCH-001-name.md << 'EOF'
## Patch: Name
**Date:** YYYY-MM-DD
**Problem:** What broke
**Solution:** How to fix
**Apply to:** Which section of SKILL.md to update
EOF

# 3. Update SKILL.md with the fix
# 4. Bump version in frontmatter
# 5. Commit: git add skills/shopify-cdp/ && git commit -m "shopify-cdp patch: description"
```

### Learnings File
All session learnings go to `learnings.md` — raw, unfiltered. Periodically review and promote patterns to SKILL.md gotchas or scripts.

### Patch Format
Patches in `patches/` follow this structure:
- `PATCH-NNN-short-name.md` — description, problem, solution, where to apply
- `CHANGELOG.md` — version log

This lets any agent (Taoz, Zenni, Claude Code) apply patches independently.
