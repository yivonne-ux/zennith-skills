# GrabFood Listing Optimizer — Deep Research & Business Plan

> Joel's GrabFood listing optimization service, mapped out for scale.
> Research date: 2026-03-23

---

## 1. The 3 Stores Joel Improved

| # | Store Name | GrabFood ID | Location |
|---|-----------|-------------|----------|
| 1 | Uncle Chua's Prawn Noodle 泉记虾面 | `1-C4KGTGJDCBW3TA` | Medan Putra Business Centre [Non-Halal] |
| 2 | Asia Curry 烧腊面饭粥馆 | `1-C7MCT32HRLDXT2` | Ara Damansara [Non-Halal] |
| 3 | Jom Noodle 大骨熬·猪肉粉 | `1-C7TYMFKXJ65UL2` | Bandar Pinggiran Subang [Non-Halal] |

**Common pattern**: All are Chinese hawker-style food stalls in the KL/PJ/Subang area. Non-halal. Specialty noodle/rice shops. These are exactly the underserved segment — small hawker stalls that don't have marketing budgets but live or die on GrabFood orders.

**Direct links (web):**
- https://food.grab.com/my/en/restaurant/online-delivery/1-C4KGTGJDCBW3TA
- https://food.grab.com/my/en/restaurant/online-delivery/1-C7MCT32HRLDXT2
- https://food.grab.com/my/en/restaurant/online-delivery/1-C7TYMFKXJ65UL2

---

## 2. What Joel Does (Current Service)

### The Problem
Most hawker stalls on GrabFood have:
- **Terrible photos**: Dark, blurry, taken on old phones, bad angles, messy backgrounds
- **No descriptions**: Just the dish name, no selling copy
- **No structure**: Menu items dumped in random order, no categories
- **No emojis/visual hooks**: Plain text that gets lost in the scroll
- **No promotions**: Missing free delivery, bundle deals, new customer offers

### Joel's Current Workflow

```
Step 1: FoodShot AI ($15-99/mo)
├── Upload original phone photo
├── AI transforms: fixes angle, plate presentation, food styling
├── Generates professional-looking base image
└── Output: Clean bowl/plate with correct 角度 (angle)

Step 2: ChatGPT Image Editing
├── Change background to white (clean, professional)
├── Warm up food colors → 暖色 (warm tones)
├── Goal: 提高食欲感 (increase appetite appeal)
└── Output: Warm, appetizing food on white background

Step 3: Phone Post-Processing
├── Open in phone gallery
├── Increase exposure to max (+10)
├── Makes food pop, bright and inviting
└── Output: Final hero image ready for GrabFood
```

**Total time per image**: ~3-5 minutes
**Cost per image**: ~RM 0.50-2.00 (FoodShot credit cost)

---

## 3. The Data — Why This Works

### Photo Impact on Orders (Industry Research)

| Metric | Improvement | Source |
|--------|------------|--------|
| Total food orders | **+35%** | Snappr study |
| Menu conversion rate | **+25%** | Limetray study |
| Online orders | **+30%** | Grubhub data |
| Delivery app conversion | **+35%** | FoodShot.ai claims |
| Click-through rate | **+30%** | General food delivery data |

### Key Consumer Behavior
- Viewing photos is **1.44x more important** than reading descriptions
- Photos are **1.38x more important** than reading reviews
- "The majority of online orders go to restaurants using more photos" — Deliveroo study
- Stores below **4.0 stars** experience **50% visibility drop** on GrabFood

### GrabFood Specific
- Professional photos + detailed descriptions = measurably higher clicks and conversions
- Restaurants with **full photo coverage** get higher visibility in the algorithm
- Stores can see up to **9x sales increase** from promotions alone
- Malaysian hawker stalls on GrabFood increased sales by **65%** after optimization

---

## 4. FoodShot.ai — The Core Tool

### What It Is
AI food photography platform. Upload a phone pic → get studio-quality output in seconds.

### Pricing

| Plan | Monthly | Annual | Credits/mo | Per Image |
|------|---------|--------|-----------|-----------|
| Free | $0 | $0 | 3 | Free (watermarked) |
| Starter | $15 | $9 | 25 | ~$0.36-0.60 |
| Business | $45 | $27 | 100 | ~$0.27-0.45 |
| Scale | $99 | $59 | 250 | ~$0.24-0.40 |
| Enterprise | Custom | Custom | Custom | API access |

### Key Features
- 100+ curated photography styles (Delivery, Menu, Fine Dining)
- **Builder Mode**: Combine background + plate style + food
- **Poster Mode**: Marketing-ready templates
- Prompt editing: "add sauce", "change lighting", "swap plates"
- 4K resolution output
- Batch processing (5 simultaneous on Scale plan)
- Custom reference styles for brand consistency
- iOS + Android apps available
- **4.5/5 stars** from 43 reviews

### Limitation Joel Works Around
FoodShot creates the base but doesn't perfect the colors for appetite appeal — that's why he adds the ChatGPT white background + warm color step + phone exposure boost.

---

## 5. GrabFood Merchant Ecosystem

### What Merchants Can Edit (via GrabMerchant Portal)
- ✅ Store name & description
- ✅ Menu items (names, prices, descriptions)
- ✅ Menu item photos
- ✅ Categories and organization
- ✅ Store hours
- ✅ Promotions and campaigns
- ✅ Staff access & permissions
- ✅ GrabAds (paid advertising)

### GrabFood Photo Specs
| Spec | Requirement |
|------|------------|
| Menu item size | **800 x 800 px** (square) or **1200 x 800 px** (3:2) |
| Store banner | **1200 x 400 px** (wide) |
| Format | JPEG or PNG |
| Max file size | **6 MB** |
| Store front | Must show permanent signboard + brand logo |
| Angle | Top-down (flatlay) or 45-degree |
| Background | Clean, uncluttered; solid colors or simple surfaces |
| Composition | Food fills 60-80% of frame |
| Rules | No text overlays, watermarks, logos, or stock photos |

### GrabFood Ranking Algorithm Factors
1. **Merchant rating** — 4.5+ stars is the sweet spot
2. **Order acceptance rate** — declining/cancelling tanks ranking
3. **Preparation time accuracy** — faster than estimated = boost
4. **Click-through rate (CTR)** — driven by store photo + item photos
5. **Conversion rate** — % of visitors who order (menu quality, pricing)
6. **Recency of activity** — consistently-open stores rank higher
7. **Promo participation** — promotions give algorithmic boost
8. **GrabAds spend** — paid placement guarantees visibility
9. **Cancellation rate** — must stay below 2% (hard threshold)

### GrabFood API (Developer Access)
Grab has a **full API** with SDKs in Python, Java, Go:

**Menu Management:**
- `PUT /partner/v1/menu` — Update menu records
- `PUT /partner/v1/batch/menu` — Batch update menu
- `POST /partner/v1/merchant/menu/notification` — Notify menu changes

**Store Management:**
- `GET /partner/v1/merchants/{merchantID}/store/status`
- `PUT /partner/v1/merchants/{merchantID}/store/opening-hours`
- `PUT /partner/v1/merchant/pause`

**Campaigns:**
- `POST /partner/v1/campaigns` — Create campaign
- `PUT /partner/v1/campaigns/{campaign_id}` — Update campaign
- `GET /partner/v1/campaigns` — List campaigns

**Orders & Analytics:**
- `GET /partner/v1/orders` — List orders
- Order accept/reject/cancel/mark-ready endpoints

**Auth**: OAuth2 at `https://api.grab.com`, API base at `https://partner-api.grab.com/grabfood`

> **This is huge.** The API means we can potentially automate menu updates, photo uploads, campaign creation, and performance tracking programmatically.

### API Reality Check
- The API is primarily aimed at **POS system integrations** and middleware providers, not individual merchants
- Requires **partner onboarding** through Grab's partner team (not self-serve)
- **No public API for uploading photos** — must be done through merchant portal
- **No public API for creating/managing promotions** or GrabAds
- **No analytics API** — dashboard data only via merchant portal
- **Fallback strategy**: Browser automation (Playwright on GrabMerchant portal) for photo uploads and listing edits

### Existing POS Integrations in Malaysia
- **StoreHub** — most popular MY POS, syncs menu + receives orders
- **Slurp!** — MY-based POS
- **EasyEat** — tablet POS with GrabFood integration
- **klikit** — multi-platform aggregator (GrabFood + ShopeeFood + Foodpanda)
- **Deliverect** — global middleware
- **FoodMarketHub** — MY-based multi-delivery management

### GrabFood Analytics (Merchant Portal)
- Sales dashboard: daily/weekly/monthly revenue, order count, AOV
- Item performance: top sellers, revenue per item
- Customer ratings & reviews (individual + aggregate)
- Operational metrics: acceptance rate, cancellation rate, avg prep time
- Promo performance: orders driven, cost vs incremental revenue
- Peak hours heatmap
- **Limitation**: 90-day rolling history, no CSV export in all markets

---

## 6. GrabFood Listing Optimization Playbook

### The Full Optimization Stack (What Joel Should Offer)

#### A. Photos (Joel's current strength)
1. **Hero/Banner image** — The store's cover photo (1200x800+)
2. **Every menu item** — Individual dish photos (800x800)
3. **Style consistency** — Same background, lighting, angle across all items
4. **Warm color grading** — 暖色系 to trigger appetite
5. **White/clean backgrounds** — Stand out in the GrabFood scroll
6. **Seasonal updates** — Refresh photos quarterly

#### B. Store Profile
1. **Optimized store name**: Include keywords + Chinese characters
   - ❌ `Uncle Chua's Prawn Noodle`
   - ✅ `Uncle Chua's Prawn Noodle 泉记虾面 🍜 Medan Putra`
2. **Description** (under 150 chars): USP + cuisine type + certification
   - ✅ `🔥 50年老字号虾面！Fresh prawns daily. Famous thick broth 🍤 Non-Halal`
3. **Categories**: 1-3 food categories + sub-tags

#### C. Menu Structure
1. **"🔥 Best Sellers" category** at the top (4-8 items)
2. **Clear categories**: Noodles 🍜 | Rice 🍚 | Sides 🥟 | Drinks 🧋
3. **5-8 categories max** (avoid overwhelming)
4. **4-8 items per category**
5. **Remove underperformers** quarterly

#### D. Menu Item Copywriting
Each item needs:
- **Emoji prefix** for visual scanning
- **Bilingual name** (English + Chinese)
- **Appetite-triggering description** (50-80 chars)
- **Tags**: Bestseller, Spicy 🌶️, Chef's Pick ⭐

Example:
```
🍜 Signature Prawn Noodle 招牌虾面
Thick aromatic broth simmered 8 hours, fresh tiger prawns, springy noodles
RM 12.90
🏆 BESTSELLER
```

#### E. Pricing Strategy
- Research competitor prices on GrabFood app
- Account for 25-30% GrabFood commission
- Round to nearest RM 0.50
- Create **value bundles** (RM 15-25 range) — 40% higher conversion
- "Deals & Bundles 🎁" category

#### F. Promotions & Campaigns
- New customer discounts (20-30% off, capped at RM 5)
- Off-peak promotions (2-5 PM)
- Free delivery campaigns (often co-funded by Grab)
- Bundle deals
- Target 3x return on discount spend

#### G. Review Management
- Respond to ALL negative reviews within 24 hours
- Thank positive reviewers
- Include thank-you notes/stickers in packaging → reduces negative reviews by 25%
- Maintain **4.5+ star rating** (below 4.0 = 50% visibility drop)

---

## 7. Business Story & Positioning

### The Story

> **"Your food is amazing. Your GrabFood listing doesn't show it."**
>
> 90% of hawker stalls on GrabFood are leaving money on the table. Dark photos, no descriptions, messy menus. Customers scroll past in 0.3 seconds.
>
> Joel transforms GrabFood listings from amateur to professional — the same food, 10x better presentation. AI-powered food photography + strategic menu optimization + conversion-focused copywriting.
>
> **The result**: Stores see 25-65% more orders within the first month. No new recipes needed. No new ingredients. Just making what you already have look irresistible.

### Target Market
- **Primary**: Chinese hawker stalls in KL/PJ/Subang/Klang Valley
- **Secondary**: Any non-chain restaurant on GrabFood Malaysia
- **Expansion**: ShopeeFood, Foodpanda (same photos, same optimization)
- **Sweet spot**: Stalls doing RM 3,000-15,000/month on GrabFood that could be doing 2-3x more

### Why Hawker Stalls?
1. They can't afford professional photographers (RM 300-500 per shoot)
2. They don't know GrabFood optimization
3. They're busy cooking, no time for marketing
4. They're price-sensitive but ROI-positive — even RM 200 spent returns RM 1,000+ in orders
5. Word-of-mouth is insane in the hawker community — 1 success story = 10 referrals

---

## 8. Pricing Packages

### Package Structure

| Package | Price (RM) | What's Included | Best For |
|---------|-----------|-----------------|----------|
| **📸 Quick Glow-Up** | RM 299 | 15 menu item photos + store banner + basic descriptions | New stalls, budget-conscious |
| **🔥 Full Makeover** | RM 599 | 30 menu item photos + store banner + full menu restructure + emoji copywriting + category optimization | Most popular — serious stalls |
| **🚀 Growth Engine** | RM 999/mo | Everything in Full Makeover + monthly photo updates + promotion strategy + performance tracking + A/B testing | High-volume stalls wanting ongoing growth |
| **🏪 Multi-Platform** | RM 1,499 | Full Makeover for GrabFood + Foodpanda + ShopeeFood | Stalls on multiple platforms |

### Add-Ons

| Add-On | Price (RM) |
|--------|-----------|
| Extra 10 menu photos | RM 99 |
| Video menu item (15s loop) | RM 49/item |
| Monthly performance report | RM 99/mo |
| Promotion campaign setup | RM 149/campaign |
| Review response templates (20 templates) | RM 79 |
| Multi-language descriptions (BM/CN/EN) | RM 149 |

### ROI Calculator (Sales Pitch Tool)

```
Current monthly GrabFood revenue:     RM 5,000
Conservative order increase (+25%):    RM 1,250/mo extra
Cost of Full Makeover:                 RM 599 (one-time)
Payback period:                        < 2 weeks
12-month extra revenue:                RM 15,000
ROI:                                   25x
```

---

## 9. The Automation Vision — GrabFood Optimizer Bot

### Phase 1: Telegram Bot (MVP)
A Telegram bot that hawker stall owners can use to:

```
/start → Onboard new store
/photo → Upload food photo → AI enhances → Returns optimized image
/menu  → Input menu items → AI generates descriptions + emojis
/audit → Paste GrabFood link → Bot audits listing, gives score + recommendations
/track → Weekly performance summary (if API connected)
```

### Phase 2: Full Pipeline (Headless Browser Architecture)

**Why browser-only**: GrabFood API requires partner registration, doesn't support photo uploads, and has no promo/analytics endpoints. Headless browser on `merchant.grab.com` is the only way to do everything.

```
┌──────────────────────────────────────────────────────┐
│            GRAB LISTING OPTIMIZER (v2)               │
│            100% Headless Browser Architecture         │
│                                                      │
│  📥 INPUT (via Telegram)                             │
│  ├── Food photos (phone camera)                      │
│  ├── Menu items + prices                             │
│  ├── GrabMerchant login credentials                  │
│  └── Store preferences (language, style)             │
│                                                      │
│  🤖 AI PIPELINE                                     │
│  ├── FoodShot AI → Base enhancement                  │
│  ├── Gemini/GPT → White bg + warm colors             │
│  ├── Python PIL → Auto exposure boost                │
│  ├── LLM → Bilingual descriptions + emojis           │
│  ├── LLM → Menu structure optimization               │
│  └── LLM → Promotion strategy                        │
│                                                      │
│  🌐 HEADLESS BROWSER ENGINE (Playwright)             │
│  ├── Login to merchant.grab.com (stored session)     │
│  ├── SCRAPE current listing state                    │
│  │   ├── All menu items, photos, descriptions        │
│  │   ├── Categories & structure                      │
│  │   ├── Current prices                              │
│  │   ├── Ratings & reviews                           │
│  │   └── Screenshot before state                     │
│  ├── UPLOAD optimized photos                         │
│  │   ├── Navigate to Menu Editor                     │
│  │   ├── Click each item → upload photo              │
│  │   ├── Wait for upload confirmation                │
│  │   └── Handle 800x800 resize if needed             │
│  ├── EDIT menu copy                                  │
│  │   ├── Update item names (bilingual + emoji)       │
│  │   ├── Update descriptions                         │
│  │   ├── Reorder categories                          │
│  │   └── Save changes                                │
│  ├── SET UP promotions                               │
│  │   ├── Navigate to Promotions section              │
│  │   ├── Create new customer discount                │
│  │   ├── Set up bundle deals                         │
│  │   └── Schedule off-peak promos                    │
│  ├── TRACK performance                               │
│  │   ├── Scrape Sales Dashboard                      │
│  │   ├── Extract order count, revenue, AOV           │
│  │   ├── Scrape ratings & new reviews                │
│  │   ├── Screenshot after state                      │
│  │   └── Store in local DB for trending              │
│  └── AUDIT competitor listings                       │
│      ├── Scrape food.grab.com consumer pages          │
│      ├── Compare photos, prices, ratings              │
│      └── Generate competitive analysis                │
│                                                      │
│  📊 REPORTING                                        │
│  ├── Before/after screenshots                        │
│  ├── Weekly order volume delta                       │
│  ├── Revenue change %                                │
│  ├── Rating trend                                    │
│  └── Sent to owner via Telegram                      │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### Phase 3: Self-Improving Loop
- Track which photo styles convert best → feed back into generation
- Track which descriptions get more orders → compound winning patterns
- A/B test menu structures across stores → find universal winners
- Build a "hawker food photo dataset" from all clients → train custom model

### Tech Stack

| Component | Tool | Cost |
|-----------|------|------|
| **Browser engine** | **Playwright (Python)** | **Free** |
| Session management | Playwright persistent contexts | Free |
| Photo enhancement | FoodShot AI (Scale plan) | $99/mo (250 credits) |
| Background/color fix | Gemini Image API (NanoBanana) | ~$0.02/image |
| Exposure boost | Python PIL/Pillow | Free |
| Menu copywriting | Claude/GPT API | ~$0.01/item |
| Telegram bot | python-telegram-bot | Free |
| Consumer page scraping | Playwright (food.grab.com) | Free |
| Merchant portal automation | Playwright (merchant.grab.com) | Free |
| Performance tracking | SQLite | Free |
| Hosting | VPS with Chromium (2 CPU, 4GB RAM) | ~RM 80/mo |

**Total infrastructure cost**: ~RM 550/mo for unlimited stores

### Headless Browser Implementation Notes

**Login & Session Management:**
1. Each merchant provides GrabMerchant credentials (email + password)
2. Playwright uses persistent browser contexts to store cookies/sessions
3. Sessions stored per-merchant in `~/.grab-sessions/{merchant_id}/`
4. Auto-re-login if session expires (GrabMerchant sessions last ~7 days)
5. Handle OTP/2FA if Grab requires it (forward OTP request to merchant via Telegram)

**Key Pages to Automate:**
| Page | URL Pattern | Actions |
|------|------------|---------|
| Login | `merchant.grab.com/portal/sign-in` | Email + password + OTP |
| Dashboard | `merchant.grab.com/portal/dashboard` | Scrape revenue, orders, rating |
| Menu Editor | `merchant.grab.com/portal/food-menu` | Edit items, upload photos, reorder |
| Promotions | `merchant.grab.com/portal/promotions` | Create/edit promos |
| Reviews | `merchant.grab.com/portal/reviews` | Read & respond to reviews |
| Analytics | `merchant.grab.com/portal/analytics` | Scrape performance data |

**Anti-Detection Strategy:**
- Use `playwright-stealth` to avoid bot detection
- Randomize delays between actions (1-3 seconds)
- Use residential proxy if needed (but Grab is lenient on merchant portal)
- Human-like mouse movements for clicks
- One browser context per merchant (isolated sessions)

**Error Handling:**
- Screenshot on every error for debugging
- Retry failed uploads up to 3 times
- Alert merchant via Telegram if login fails
- Queue failed operations for retry next cycle

**Consumer Page Scraping (food.grab.com):**
- GrabFood consumer pages are JS-rendered → headless browser required
- Scrape competitor listings for price/photo comparison
- Scrape own listing to verify changes went live
- Extract ratings, reviews, menu structure
- Run weekly audit scans

---

## 10. Competitive Landscape

### Direct Competitors (none found in MY)
There is **no known GrabFood listing optimization agency in Malaysia**. This is a blue ocean.

### Adjacent Services
| Service | What They Do | Gap |
|---------|-------------|-----|
| The Grab Method™ | Courses/guides on GrabFood | Info only, no done-for-you service |
| klikit | Multi-platform order management | Tech tool, no creative optimization |
| MenuPhotoAI | AI food photo generator | Photo only, no full listing optimization |
| FoodShot AI | AI food photo tool | Tool only, no service layer |
| Professional food photographers | Manual photo shoots | RM 300-500+, no digital optimization |

### Joel's Moat
1. **Full-stack**: Photos + copy + structure + promotions (nobody else does all 4)
2. **AI-powered**: 10x cheaper and faster than traditional photography
3. **Hawker-native**: Speaks the language, understands the culture
4. **Data-driven**: Track results, prove ROI
5. **Scalable**: AI pipeline means 1 person can serve 50+ stores/month

---

## 11. Growth Roadmap

### Month 1-2: Prove It
- Optimize 5-10 stores manually (Joel's current workflow)
- Document before/after with screenshots + order data
- Build case studies with real numbers
- Price: RM 299-599 per store

### Month 3-4: Systemize
- Build Telegram bot MVP (/photo, /menu, /audit)
- Standardize the workflow
- Create onboarding flow for new stores
- Start charging RM 599-999

### Month 5-6: Scale
- Integrate GrabFood API (or browser automation)
- Add Foodpanda + ShopeeFood support
- Hire 1-2 people for client management
- Target: 30-50 stores/month

### Month 7-12: Compound
- Launch Growth Engine (monthly subscription)
- Build performance tracking dashboard
- A/B test across stores
- Expand to other Malaysian cities (Penang, JB, Ipoh)
- Target: 100+ active stores, RM 50k+/month revenue

---

## Sources

- [FoodShot AI](https://foodshot.ai/) — AI food photography platform
- [Snappr: Food photos increase orders by 35%](https://www.snappr.com/enterprise-blog/high-quality-food-photos-can-increase-orders-on-restaurant-delivery-apps-by-35)
- [klikit: Optimize GrabFood Listings](https://klikit.io/en/resources/guides/optimize-grabfood-listings-singapore)
- [Unilever: GrabFood Delivery Tips](https://www.unileverfoodsolutions.com.my/en/chef-inspiration/food-delivery/improving-food-delivery/grabfood-top-food-delivery-tips.html)
- [GrabMerchant Portal](https://merchant.grab.com/en-my)
- [Grab Developer Portal](https://developer.grab.com/)
- [GrabFood API Python SDK](https://github.com/grab/grabfood-api-sdk-python)
- [GrabFood Photo Specs (Sapaad)](https://kb.sapaad.com/help/what-are-the-recommended-specs-for-menu-item-images-in-grabfood-connect)
- [The Grab Method](https://thegrabmethod.com/grabfood-mistakes-restaurants/)
- [FoodShot AI Reviews (G2)](https://www.g2.com/products/foodshot-ai/reviews)
- [GrabFood Fees Guide](https://blog.menuviel.com/grabfood-fees-and-commissions-for-restaurants/)
