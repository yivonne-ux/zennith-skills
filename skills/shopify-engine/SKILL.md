---
name: shopify-engine
description: Unified Shopify CLI. Theme push/pull via Shopify CLI + admin operations via Chrome CDP. Just setup store URL and go.
version: 1.0.0
agents: [taoz, main]
evolves: true
---

# Shopify Engine — Unified Shopify CLI

## Quick Start
```bash
# 1. Setup store
bash ~/.openclaw/skills/shopify-engine/scripts/shopify.sh setup 7qz8cj-uu.myshopify.com

# 2. Theme operations (uses Shopify CLI)
bash ~/.openclaw/skills/shopify-engine/scripts/shopify.sh theme-push
bash ~/.openclaw/skills/shopify-engine/scripts/shopify.sh theme-pull

# 3. Admin operations (uses Chrome CDP — start browser first)
bash ~/.openclaw/skills/auth-browser/scripts/browser.sh start
bash ~/.openclaw/skills/shopify-engine/scripts/shopify.sh products
bash ~/.openclaw/skills/shopify-engine/scripts/shopify.sh product-create "New Product" "29.00"
```

## Commands

| Command | Method | What |
|---------|--------|------|
| `setup <store>` | — | Save store URL |
| `status` | Both | Show store info |
| `theme-push` | Shopify CLI | Push theme to live |
| `theme-pull` | Shopify CLI | Pull current theme |
| `theme-list` | Shopify CLI | List themes |
| `products` | Chrome CDP | List all products |
| `product-create <title> <price>` | Chrome CDP | Create product |
| `product-delete <id>` | Chrome CDP | Delete product |
| `product-rename <id> <name>` | Chrome CDP | Rename product |
| `browser-start` | — | Launch Chrome CDP |
| `browser-check` | — | Check CDP status |

## Requirements
- **Theme ops:** Shopify CLI authenticated (`shopify auth login`)
- **Admin ops:** Chrome CDP running + logged into Shopify admin
- **Browser:** auth-browser skill (companion)
