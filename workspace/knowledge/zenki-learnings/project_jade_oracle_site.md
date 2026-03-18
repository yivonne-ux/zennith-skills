---
name: Jade Oracle Site & Infrastructure
description: Jade Oracle marketing site, fly.io deployments, Shopify store setup status, Payhip integration, and all built project paths
type: project
---

## Jade Oracle — Full Project State (as of 2026-03-18)

### Live Deployments
- **jade-os.fly.dev** — Node.js backend: Telegram bot, QMDJ engine, reading pipeline (Singapore region)
- **jade-oracle-site.fly.dev** — Static marketing site (nginx, Singapore region, 2 machines auto-stop)

### Shopify Store (CONFIRMED)
- **Store URL**: `7qz8cj-uu.myshopify.com`
- **Custom domain**: `jadeoracle.co` (Cloudflare DNS)
- **Live theme**: "Jade Oracle CRO" (#144336650319)
- **Unpublished theme**: "Horizon" (#144120217679)
- **Status**: Password page (store not open to public yet)
- **Shopify CLI**: v3.92.1, AUTHENTICATED (can push themes, list, pull)
- **Account email**: penaghuatgroup@gmail.com
- **Goal**: Full CRO site on Shopify — products, checkout, theme matching index.html

### Local Project Paths

| Project | Path | Status |
|---------|------|--------|
| Marketing site | `~/Desktop/gaia-projects/jade-oracle-site/` | Built, deployed to fly.io |
| Payhip integration | `~/Desktop/gaia-projects/payhip-integration/` | Built, 4 endpoints tested |
| 数字能量学 engine | `~/Desktop/gaia-projects/number-engine/` | Built, 81 tests passing |
| Ling Xi site | `~/Desktop/gaia-projects/ling-xi-site/` | Built, 4 pages |
| Jade workspace (local) | `~/.openclaw/workspace-jade/` | Shopify webhook middleware |
| Jade images | `~/Desktop/gaia-projects/jade-oracle-site/images/jade/` | 49 images, 95MB, v15-v22 |

### Marketing Site Architecture (index.html)
- **Design system**: Cormorant (serif) + Jost (sans), #08080f bg, #c9a84c gold, #1E6B4E jade, #e8e0d4 cream
- **CRO layers**: Trust bar, 3-tier pricing ($1/$19/$39), price anchoring, curiosity gap (blurred preview), social proof toasts, sticky CTA bar, moon cycle countdown, scroll reveals
- **14 sections**: Trust bar → Nav → Hero (split with Jade image) → Stats bar → Pain points → Solution/Differentiators → Pricing cards → Curiosity gap → How it works → Testimonials → Jade bio (full-width) → Urgency countdown → Final CTA → Footer
- **G-Stack review score**: 82/100, all 12 priority fixes applied (mobile hero image, favicon, JSON-LD, countdown seconds, etc.)

### Payhip Products
| Product | Price | Payhip ID |
|---------|-------|-----------|
| Quick Insight (Love) | $1 | TBD |
| Career Reading | $1 | TBD |
| Business Reading | $5 | TBD |
| Monthly Subscription | $5 | TBD |
| Annual Subscription | $15 | TBD |
| Deep Life Reading | $29 | TBD |
| Compatibility Reading | $15 | TBD |

### Fly.io Backend (jade-os)
- Main server: `jade-telegram-bot.js` (48KB) on port 18789
- QMDJ engines: JS (57KB) + Python (55KB)
- Reading pipeline: birth-chart.py, tarot-engine.py, reading-synthesizer.py, generate_pdf.py, send-email-klaviyo.py
- Model: DeepSeek V3 (primary)
- Health: `{"service":"jade-oracle","version":3,"qmdj_engine":true,"interpretation_engine":true,"model":"deepseek/deepseek-chat-v3-0324"}`

### Shopify Migration Progress
1. Store confirmed: `7qz8cj-uu.myshopify.com` / `jadeoracle.co`
2. CLI authenticated: can push themes
3. Building complete Liquid theme matching CRO homepage (in progress)
4. Create products (pending)
5. Wire webhooks to jade-os.fly.dev (pending)
