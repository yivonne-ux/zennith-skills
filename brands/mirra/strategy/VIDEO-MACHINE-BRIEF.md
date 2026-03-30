# MIRRA VIDEO MACHINE BRIEF
## For the Claude Code that builds video ads

> This brief covers EVERYTHING we've built on the statics side — campaign architecture, brand rules, copy direction, what's live, what's working. Your job is to build video ads that slot into this machine. We're NOT telling you what to make — we're showing you what exists so you can run.

---

## 1. NORTH STAR

**RM800K/month revenue.** ~1,404 meals/day, ~2,105 active subscribers. RM160-200K/month ad spend at 4-5x ROAS. Every ad must SELL. Not entertain, not educate — sell.

Current: scaling from RM143K → RM250K. SalesBoomBoom is the 12-month winning creative (RM 4.64-5.33/conversion).

---

## 2. THE BUSINESS

**Mirra Eats** — plant-based low-calorie bento delivery in KL/Selangor.
- 50+ dishes, nutritionist-designed, every meal under 600 calories
- Japanese, Western, Chinese, Thai cuisine variety
- From RM19/meal, free delivery within 10km of OUG
- Pricing: Solo Glow / Bestie Tone Up / Fit Fam × 10/20/40 meals (RM17.75-24/meal)
- Target: Malaysian Chinese women, 18-65, KL/Selangor
- CTA: WhatsApp message (CTWA) → `60193837832`
- IG: @mirra.eats

**CRITICAL BRAND RULES:**
- Mirra IS plant-based but **NEVER write "chicken", "beef", "meat"** — the food is plant-based mimicking these dishes
- Copy leads with **low calorie, lose weight, convenience** — NOT "plant-based" (that's a turnoff for the market)
- ZERO AI-generated food. Only real food photos from the Mirra food library
- NO Leann KOL — not allowed

---

## 3. CAMPAIGN ARCHITECTURE (LIVE)

```
MIRRA-TEST-EN-MAR26 (ACTIVE) — EN prospecting
├── TOFU-EN-STATIC    (16 ads, RM200/day)
├── MOFU-EN-STATIC    (10 ads, RM200/day)
├── BOFU-EN-STATIC    (16 ads, RM250/day)
├── EN-MIX            (30 ads — 8 statics + 22 videos, RM350/day)
└── EN-CAROUSEL       (3 ads, RM80/day)

MIRRA-TEST-CN-MAR26 (ACTIVE) — CN prospecting
├── CN-STATIC         (28 ads, RM250/day)
├── CN-MIX            (18 ads — 6 statics + 12 videos, RM250/day)
├── CN-TOFU-STATIC    (24 ads, RM20/day)  ← just activated
└── CN-CAROUSEL       (3 ads, RM15/day)   ← just activated

MIRRA-RETARGET-EN-MAR26 (ACTIVE) — EN retarget
├── RT-HOT   (6 ads, RM15/day) — Sent Messages 365d audience
├── RT-WARM  (6 ads, RM20/day) — Ad Engagers 365d audience
└── RT-COOL  (6 ads, RM15/day) — IG/FB Engaged 365d audience

MIRRA-RETARGET-CN-MAR26 (ACTIVE) — CN retarget
├── CN-RT-HOT   (4 ads, RM10/day)
├── CN-RT-WARM  (4 ads, RM15/day)
└── CN-RT-COOL  (4 ads, RM10/day)
```

**ABO (Ad Set Budget Optimization)** — each ad set controls its own budget. NOT CBO.

**Targeting:**
- EN ad sets: No locale filter, geo KL/Selangor only, female, 18-65
- CN ad sets: Locale [20, 21, 22] (Simplified Chinese + Traditional Chinese HK/TW), geo KL/Selangor, female, 18-65
- Retarget: Custom audiences with waterfall exclusions (HOT excludes nothing except buyers, WARM excludes HOT, COOL excludes HOT+WARM)
- All: Advantage+ audience ON (except CN retarget), optimization = CONVERSATIONS, destination = WHATSAPP

---

## 4. WHAT STATICS EXIST (your videos complement these)

### EN Statics — 45 total across TOFU/MOFU/BOFU

**TOFU (16 ads) — Scroll-stoppers, no selling:**
| Ad Name | Creative Direction | Headline |
|---------|-------------------|----------|
| S01-Notes-JeansDontFit | iPhone notes screenshot — "jeans don't fit" confession | jeans don't fit. again. |
| S02-GoogleSearch-HowToLose | Fake Google search results for weight loss | how to lose 5kg without starving |
| S03-Scale-MorningDread | Bathroom scale screenshot — morning dread moment | the number you didn't want to see |
| S04-BoldQuote-StopStartingMonday | Massive bold type quote | stop starting every Monday |
| S05-StickyNotes-DeskConfession | Desktop sticky notes — secret food shame | i ate 2 nasi lemak today |
| S06-GroupChat-BestieIntervention | WhatsApp group chat — friends talking about food | bestie intervention needed |
| S07-InstaDM-ColleagueAsked | Instagram DM screenshot — colleague asks about lunch | your colleague asked... |
| S08-Poll-LunchStruggle | Instagram poll — lunch struggle results | 87% said they eat the same thing |
| S09-LoadingBar-DropASize | Loading bar UI — "dropping a size" progress | progress: dropping a size |
| S10-Checklist-QuitList | Checklist — things to quit | your quit list for 2026 |
| S11-Receipt-CalorieAudit | Receipt format — calorie audit of GrabFood | your calorie audit this week |
| S12-SwipeChoice-FoodTinder | Tinder-style food swipe interface | swipe right on better lunch |
| S13-WeightTracker-GraphDown | Weight tracking app graph going down | the graph going the right way |
| S14-BoldType-NothingFits | Massive type — nothing fits | nothing fits and it's only march |
| S15-Horoscope-LunchProphecy | Horoscope format — lunch prophecy | your lunch horoscope today |
| S16-NotifStack-NewLife | Notification stack — life changing notifications | notifications from your future self |

**Copy direction:** Girlboss. Unapologetic. No exclamation marks. Viral/sendable. She screenshots and sends to her bestie.

**Primary text (shared across TOFU):**
> still eating the same sad lunch? let's fix that
>
> 50+ low-cal meals. different every day.
> nutritionist-designed. under 600 cal each.
> japanese. western. chinese. thai.
> delivered free to your office.
>
> from RM19. cheaper than grabfood.
>
> text us on whatsapp: 'hi i want to see the menu'

**Headline:** low-cal bento that doesn't taste like diet food
**Description:** 50+ dishes. different daily. from RM19. free delivery.

**MOFU (10 ads) — Food-forward, menu showcase:**
| Ad Name | Direction |
|---------|-----------|
| F01-Hero-PadThai | Editorial food hero — single dish beauty shot |
| F02-Hero-Bibimbap | Editorial food hero |
| F03-Hero-GreenCurry | Editorial food hero |
| F04-Hero-KatsuCurry | Editorial food hero |
| F05-Hero-NasiLemak | Editorial food hero |
| F06-UGC-AmazingTestimonial | UGC testimonial screenshot |
| F08-Grid-6Dishes | 6-dish grid showing variety |
| F09-Grid-4Calories | 4-dish grid with calorie counts |
| F10-Grid-MonToFri | Mon-Fri menu grid |
| S19-Transformation-OfficeOutfit | Before/after outfit transformation |

**BOFU (16 ads) — Direct response, pricing, CTA:**
| Ad Name | Direction |
|---------|-----------|
| B01-PriceSplit-GrabVsMirra | Price comparison — Grab vs Mirra |
| B02-HeroCTA-JustSwitchLunch | Direct hero CTA |
| B03-Testimonial-JustMyLunch | Customer testimonial |
| B04-WeeklyMenu-CalendarDeal | Weekly menu calendar |
| B05-ObjKiller-NotSadFood | Objection killer — "not sad diet food" |
| BX01-Flowchart | "What's for lunch" flowchart |
| BX02-PriceMeme | Price meme — Grab vs Mirra |
| BX03-GroupOrder | Group order savings |
| BX04-FreeDelivery | Free delivery coverage map |
| BX05-Scarcity | Limited slots urgency |
| BX06-ZoomIn | What's inside the box |
| BX07-WhatsApp | WhatsApp conversation mock |
| BX08-iMessage | iMessage friend recommendation |
| BX09-SalesBoom | Subscribe + sales boom |
| BX10-Notes | Personal results notes |
| S20-FinalCTA | Final CTA — just switch lunch |

### EN Carousels — 3 sets × 5 cards
1. **CAR01-WeeklyMenu** — Mon-Fri menu showcase with CTA
2. **CAR02-GrabVsMirra** — Price/variety/health comparison
3. **CAR03-4WeeksIn** — 4-week transformation journey

### EN Retarget — 18 ads across HOT/WARM/COOL
**Mechanical UI concept** — disguised as familiar phone interfaces:

| Tier | Ad | UI Concept |
|------|----|----|
| HOT | RT01 | Lock screen notification |
| HOT | RT14 | Desk contrast (GrabFood bag vs bento) |
| HOT | RT15 | Just the price — minimal RM19 |
| HOT | RT16 | "Yours" — personalized box |
| HOT | RT17 | Meal box beauty shot |
| HOT | RT18 | Editorial beauty shot |
| WARM | RT02 | Abandoned cart |
| WARM | RT03 | Bank statement — spending audit |
| WARM | RT04 | Calendar reminder |
| WARM | RT05 | Spotify wrapped — food edition |
| WARM | RT06 | App store reviews |
| WARM | RT01 | Lock screen (duplicate tier placement) |
| COOL | RT07 | Poll results |
| COOL | RT08 | Order confirmation |
| COOL | RT09 | Netflix continue watching → food version |
| COOL | RT10 | Package tracking |
| COOL | RT11 | Screen time report |
| COOL | RT12 | Boarding pass — journey ticket |

**EN retarget copy by tier:**
- HOT: "you looked. you wanted it. just try it already." — direct, confident, assumes intent
- WARM: "still thinking about better lunches? we saved your spot." — re-engagement, new menu angle
- COOL: "lunchtime doesn't have to be this boring." — fresh awareness, mamak comparison angle

---

### CN Statics — 80 total across multiple batches

**CN-STATIC (28 ads) — Original CN campaign batch:**
Same creative directions as EN but culturally localized. Headlines in Simplified Chinese with Manglish code-switching ("lah", "leh").

| Ad | Direction | Chinese Headline |
|----|-----------|-----------------|
| CN01 | Notes — jeans tight | 裤子又紧了 |
| CN02 | Google search | 怎么瘦5kg 不用饿肚子 |
| CN03 | Bold quote | 别再说下周一开始了 |
| CN04 | Poll | 午餐调查结果 |
| CN05 | Food Tinder swipe | 左滑右滑 选午餐 |
| CN06 | Horoscope | 你的午餐运势 |
| CN07 | Mon-Fri grid | 一周菜单 |
| CN08 | Group chat | 闺蜜群在讨论 |
| CN09 | DM — colleague | 同事问你午餐 |
| CN10 | Loading bar — drop size | 掉尺码进度条 |
| CN11 | Receipt — calorie audit | 你这周的卡路里账单 |
| CN12 | Food hero — Pad Thai | (food beauty shot) |
| CN13 | Food hero — Nasi Lemak | (food beauty shot) |
| CN14 | Grid — 4 calories | (calorie grid) |
| CN15 | Flowchart | 今天吃什么 |
| CN16 | Price split — Grab vs Mirra | 外卖 vs 低卡便当 |
| CN17 | Free delivery | 免费配送区域 |
| CN18 | Scarcity — limited slots | 限量名额 |
| CN19 | Objection killer | 这不是减肥餐 |
| CN20 | Friend recommendation | 朋友推荐 |
| CN21 | Food hero — BBQ Pita | (food beauty shot) |
| CN22 | Food hero — Green Curry | (food beauty shot) |
| CN23 | Food hero — Bulgogi | (food beauty shot) |
| CN24 | Grid — 6 dishes | (variety grid) |
| CN25 | Grid — 4 variety | (variety grid) |
| CN26 | Bold — dropped size | 掉了一个size |
| CN27 | Bold — eat well slim | 吃好也能瘦 |
| CN28 | Journey — 4 weeks | 四周旅程 |

**CN-TOFU-STATIC (24 ads) — v4 batch, deeper creative directions:**

Each variant has a specific persona and emotional state:

| Variant | Direction | Persona | Headline | Pain Point |
|---------|-----------|---------|----------|------------|
| V01-EditorialHero | editorial hero | 美容控 (beauty-conscious) | 吃得漂亮 | Food = skin = body |
| V02-MinimalEditorial | moody editorial | 加班OL (overtime office lady) | 不将就 | Exhausted, eats whatever's closest |
| V03-VarietyCascade | cascading variety | 午餐困难户 (can't choose) | 不重复 | Decision fatigue |
| V04-WarmLifestyle | lifestyle photo | 忙碌妈妈 (working mom) | 你也值得好好吃一顿 | Takes care of everyone except herself |
| V05-SocialProof | floating reviews | 精打细算 (budget-smart) | (testimonial bubbles) | Needs proof before buying |
| V06-BoldSplit | split composition | 午餐困难户 | 选择困难？ | Choice paralysis |
| V07-NewspaperConcept | newspaper layout | 加班OL | 头条：她终于不吃mamak了 | Stuck in lunch rut |
| V08-CNYBoldType | CNY bold type | 新年焦虑族 | (seasonal) | Post-CNY guilt |
| V09-FloatingReviews | review cards | 精打细算 | (review cards) | Skeptical researcher |
| V10-MassiveTypeHero | massive typography | 健身小白 (gym newbie) | 低卡 (MASSIVE) | Gym but eating wrong |
| V11-BoldFoodHero | bold food hero | 加班OL | (food forward) | Eats delivery junk |
| V12-ComboProduct | product combo | 忙碌妈妈 | (combo showcase) | Time-poor |
| V13-MenuCascade | menu cascade | 午餐困难户 | (daily menu) | What to eat every day |
| V14-FlatLayVariety | flat lay grid | 美食博主wannabe | (variety flat lay) | Wants IG-worthy food |
| V15-UGCMirrorSelfie | UGC selfie | 健身小白 | (transformation) | Wants to show progress |
| V16-GlowUpGrid | glow up grid | 美容控 | (glow up journey) | Wants visible results |
| V17-AirdropConcept | Airdrop-style | 忙碌妈妈 | (tech-native concept) | Impulse decision maker |
| V18-TransformationSplit | before/after | 健身小白 | (transformation) | Wants proof of results |
| V19-UsVsThem | comparison | 精打细算 | (us vs them) | Price-sensitive |
| V20-NewspaperHands | newspaper holding | 加班OL | (headline concept) | News junkie angle |
| V21-NarrativeFlyer | narrative flyer | 忙碌妈妈 | (story format) | Needs emotional hook |
| V22-PersonHoldingProduct | person + product | 美容控 | (lifestyle) | Aspirational |
| V23-FourPanelEmotion | 4-panel emotion | 午餐困难户 | (comic/emotion strip) | Relatable daily struggle |
| V24-NarrativeNostalgia | nostalgic narrative | 精打细算 | (nostalgia hook) | Missing home cooking |

**CN TOFU Copy (shared across CN-TOFU-STATIC):**
> 还在吃油腻外卖？换个选择 lah 💕
>
> ✨ 50+ 低卡料理 每天不一样
> ✨ 营养师配餐 每餐低于600卡
> ✨ 日式 · 西式 · 中式 · 泰式
> ✨ 免费送到你的office
>
> 从 RM19 起 · 比GrabFood还便宜
>
> text us on whatsapp: 'hi 我要看菜单'

**Headline:** 低卡便当 好吃到不像减肥餐
**Description:** 50+料理 每天不同 从RM19起 免费配送

### CN Carousels — 3 sets × 5 cards
1. **CAR01-CN-WeeklyMenu** — Cover + Mon椰浆饭 + Tue Pad Thai + Wed咖喱 + ThuFri 50+道菜
2. **CAR02-CN-GrabVsMirra** — Cover + Price省RM420 + Variety菜色对比 + Health营养对比 + CTA换一个选择
3. **CAR03-CN-4WeeksIn** — Cover + Week1好吃 + Week2裤子松了 + Week3皮肤好了 + Week4瘦了2kg

### CN Retarget — 12 ads, culturally localized UI concepts
Adapted from EN retarget but using Malaysian Chinese apps:

| Tier | Ad | UI Concept | CN Localization |
|------|----|----|-----|
| HOT | CNRT01 | WeChat lock screen | WeChat instead of iMessage |
| HOT | CNRT02 | Shopee cart | Shopee instead of Amazon |
| HOT | CNRT03 | Bank statement | Malaysian Chinese banking UI |
| HOT | CNRT04 | Calendar reminder | Chinese calendar app |
| WARM | CNRT05 | XHS reviews | 小红书 instead of Instagram |
| WARM | CNRT06 | Poll results | Chinese poll interface |
| WARM | CNRT07 | Order confirmation | Chinese e-commerce |
| WARM | CNRT08 | Grab tracking | GrabFood delivery tracking |
| COOL | CNRT09 | Package tracking | Chinese package tracking |
| COOL | CNRT10 | Screen time | Chinese screen time report |
| COOL | CNRT11 | Still thinking | Bold food-forward retarget |
| COOL | CNRT12 | Beauty shot | Editorial food photography |

**CN Retarget Copy by Tier:**
- HOT: 你之前看了我们的便当...还没试？😉 | HL: 你上次看了没订 这次别错过
- WARM: 嘿 还记得我们吗？💕 新菜单了 更好吃 更多选择 | HL: 新菜单来了 比之前更好吃
- COOL: 午餐还在吃mamak？试试这个 lah 🍱 | HL: 低卡便当 每天不一样

---

## 5. VIDEOS ALREADY IN THE SYSTEM

These videos are already live in EN-MIX and CN-MIX ad sets:

### EN Videos (22 in EN-MIX):
- VID-Sales-BoomBoom-EN — SalesBoomBoom (12-month winner, best performer)
- VID-SalesBoomBoom-Apr30, V2-May26 — SalesBoomBoom variants
- VID-NewMom-SalesBoomBoom-v3 — SalesBoomBoom for moms
- VID-Mom-65to50-v1, v2 — Mom weight loss journey
- VID-Bye-Bye-spare-tayar — "Bye bye spare tire" hook
- VID-Bye-bye-stubborn-inches — Stubborn inches hook
- VID-DropASize-V1 — Drop a size hook
- VID-KOL-Chris-v2, Sunny-V3, evelynsmem-v3, Veggieeats-V2 — KOL/influencer videos
- VID-OL-6Xkg-to-5Xkg — Office lady weight loss
- VID-OL-TiredGrabLunches — Tired of Grab lunches
- VID-OL-Foodie-WeightGoals — Foodie with weight goals
- VID-L-to-S-LightLunch — Size L to S journey
- VID-M3A-NewMums, M3B-NewMums, M3D-OfficeGirls — persona-specific videos
- VID-ZiQian-V2 — ZiQian testimonial

### CN Videos (12 in CN-MIX):
- VID-SalesBoomBoom-Chi-Warm-V3 — SalesBoomBoom Chinese version
- VID-CN-BakKwa吃多了 — Post-CNY overeating
- VID-CN-10餐低卡便当 — 10 meals low-cal
- VID-CN-10餐减回CNY — 10 meals to undo CNY
- VID-CN-午餐换成这个 — Switch your lunch to this
- VID-CN-不用挨饿 — Don't need to starve
- VID-CN-SizeM变L — Size M became L
- VID-CN-新年后腰围 — Post-CNY waistline
- VID-CN-节后身体清仓 — Post-holiday body clearance
- VID-CN-15天吃多14天修 — 15 days eating, 14 days fix
- VID-CN-2周Reset — 2-week reset
- VID-CN-CNY多了3kg — Gained 3kg during CNY

---

## 6. BRAND DNA — DESIGN SYSTEM

### Visual
- **Palette:** Warm salmon (hero), dusty rose, soft coral, warm blush + cream/pale linen for surfaces
- **Two-tone depth:** Colored WALL (salmon/rose) meeting cream SURFACE (table/counter) — magazine-set look
- **Forbidden:** Pure white, clinical, cold blue, neon, dark brown, heavy orange, corporate
- **Photography:** 85mm f/1.4 compression, warm directional light from upper-left, shallow DOF
- **Props:** Gold chopsticks, blush linen, ceramic, herb sprigs, pink glass
- **Vibe:** "Bon Appetit meets Glossier" — premium but approachable

### Voice
- Girlboss. Unapologetic. Confident. Warm. Never preachy.
- No exclamation marks (except strategic emoji use)
- Manglish code-switching for CN: "lah", "leh", mixing English + Chinese naturally
- She sees the ad and thinks "this brand gets me"
- Copy talks like her bestie, not a brand

### 5 CN Personas
1. **美容控** (Beauty-conscious) — Food = skincare. Won't eat crap.
2. **加班OL** (Overtime office lady) — Exhausted. Eats whatever's closest. Deserves better.
3. **午餐困难户** (Lunch decision sufferer) — "What to eat?" every day. Decision paralysis.
4. **忙碌妈妈** (Working mom) — Takes care of everyone except herself.
5. **精打细算** (Budget-smart) — Needs proof and value before spending.

### Kill Criteria
- RM 17-25/conversion = kill zone. Pause immediately.
- SalesBoomBoom benchmark: RM 4.64-5.33/conversion
- If no conversions after RM 50 spend → kill
- If CPA > 3x account average → kill

---

## 7. TECHNICAL SETUP

### Meta API
- Ad Account: `act_830110298602617`
- Page ID: `318283048041590`
- IG User ID: `17841467066982906`
- WhatsApp: `60193837832`
- API version: v21.0
- CTA: `{"type": "WHATSAPP_MESSAGE", "value": {"app_destination": "WHATSAPP"}}`
- Chat builder: Full VISUAL_EDITOR v2 format required (not minimal)

### EN Chat Builder
```json
{
  "type": "VISUAL_EDITOR", "version": 2,
  "landing_screen_type": "welcome_message", "media_type": "text",
  "text_format": {
    "customer_action_type": "autofill_message",
    "message": {
      "autofill_message": {"content": "Hi, I want to see the menu!"},
      "text": "Hey babe! Welcome to Mirra 🌸"
    }
  }
}
```

### CN Chat Builder
```json
{
  "type": "VISUAL_EDITOR", "version": 2,
  "landing_screen_type": "welcome_message", "media_type": "text",
  "text_format": {
    "customer_action_type": "autofill_message",
    "message": {
      "autofill_message": {"content": "我想看菜单和套餐！"},
      "text": "你好！欢迎来到 Mirra 🌸"
    }
  }
}
```

### Deploy Pattern (curl, not Python urllib)
- Image upload: `curl -F "filename=@path" -F "access_token=TOKEN" .../adimages`
- Creative creation: `curl --data-urlencode` for all fields (Chinese chars break urllib)
- The `.env` file at `~/Desktop/mirra-workflow/.env` has the current META_ACCESS_TOKEN (expires frequently, always check)

---

## 8. VIDEO PRODUCTION LEARNINGS (FROM V1-V7)

### Model Routing
- **Sora** — best for: diversity of characters, surreal camera moves, macro food textures, atmospheric mood, impossible camera angles
- **Kling** — best for: face-lock consistency across shots, character sheets, specific person recreation
- Both cost ~$0.50-1.00 per generation

### The Breakthrough: Design FOR Sora
**Old approach (failed V1-V6):** Reference video → force AI to replicate human UGC → fight character consistency → mediocre

**New approach (Sora Masterpiece):** What does Sora do BEST → design creative AROUND that → mix with real food library footage → brand with typography

**What Sora actually excels at:**
- Surreal/dreamlike continuous camera movements through impossible spaces
- Cinematic macro: food textures at microscopic detail, steam particles, liquid physics
- Atmospheric mood: golden light, volumetric shafts, particle dust, lens flares
- One continuous impossible camera move (crane through wall into kitchen into plate)
- Slow-motion beauty at levels no phone captures
- Environmental storytelling WITHOUT humans

### Reference = Output Structure
**1:1 reference = frame-by-frame copy.** Same poses, angles, timing, momentum. Change person/food/brand only. Never try to be creative with structure.

### Three Video Moods
1. **High-hook creative** — impossible camera, surreal beauty, scroll-stop
2. **Girlboss story** — persona journey, relatable, "that's me"
3. **Food vibes** — macro, steam, texture, appetite trigger

### Post-Processing
- Typography: Remotion (programmatic video text overlay)
- Assembly: FFmpeg for cuts, transitions
- Brand constant, format variable

---

## 9. WHAT THE GAP IS

We have 145+ static ads and ~34 videos live. The statics cover:
- Every TOFU/MOFU/BOFU angle
- Mechanical UI retarget concepts
- Carousels for weekly menu, comparison, transformation
- 5 persona-targeted creative directions

**What's missing in video:**
- Fresh UGC-style content (the old videos are mostly pre-March 2026)
- "What I eat in a day" format
- Food showcase reels (macro, steam, plating)
- SalesBoomBoom-style hooks in new creative wrapping
- Persona-specific video stories (美容控, 忙碌妈妈, etc.)
- Retarget video concepts
- Carousel-equivalent video content (transformation journey, comparison)

**Your videos should:**
- Slot into EN-MIX and CN-MIX ad sets (or new video-specific ad sets)
- Use the same WhatsApp CTA (`60193837832`)
- Match the brand DNA (salmon/cream, warm, premium-but-approachable)
- Have CN versions use Manglish code-switching
- Follow the ACCA funnel logic (match the creative to the funnel stage)

---

## 10. FILE LOCATIONS

```
~/Desktop/mirra-workflow/
├── .env                          — API keys (META_ACCESS_TOKEN here)
├── WORKFLOW.md                   — full pipeline architecture
├── cn-deploy/                    — all deploy scripts
│   ├── deploy_cn_final.py        — working CN deploy (curl-based)
│   ├── fix_wa_link.py            — WA link fix script
│   └── activate_adsets.py        — activation script
├── cn-ads-v4/finals/             — 24 CN TOFU statics (V01-V24)
├── cn-campaign-v1/finals/        — 28 CN statics (CN01-CN28)
├── cn-retarget-v1/finals/        — 12 CN retarget ads
├── cn-carousel-v1/finals/        — 15 CN carousel cards
├── retarget-v1/finals/           — 18 EN retarget ads
├── march-ads-v1/finals/          — 16 EN statics batch 1
├── march-ads-v4/finals/          — 17 EN statics batch 2
├── bofu-expansion-v1/finals/     — 10 BOFU expansion ads
├── food-forward-v1/finals/       — 10 food hero ads

Food library (SACRED — only source for food photos):
~/Library/CloudStorage/GoogleDrive-.../Mirra Knowledge Base/Variety Dishes Mirra/
  — 14 dishes: Bibimbap, Green Curry, Katsu Curry, Pad Thai, Nasi Lemak,
    Fusilli, Taiwanese Braised, Teriyaki Burrito, etc.

Video production system:
~/Desktop/video-compiler/          — video assembly pipeline
```

---

## 11. GOLDEN RULES

1. **ZERO AI food.** Only real photos from the food library. Sacred.
2. **ALL text = NANO or video typography tool.** PIL = resize + logo + grain ONLY.
3. **No "plant-based" in copy.** Lead with low cal, lose weight, convenience.
4. **No chicken/beef/meat words.** The food IS plant-based mimicking these.
5. **No Leann KOL.**
6. **Logo: real PNG overlay in post-production.** Never let AI generate logos.
7. **Grain: 0.016-0.018 strength.** Always last step.
8. **Every ad must SELL.** Not entertain, not educate. RM800K north star.
9. **Reference = output structure.** Copy the format 1:1. Only change content.
10. **Brand constant, design variable.** Salmon/cream palette always. Layout can be anything.

---

*Brief generated March 17, 2026. For the video machine that builds Mirra's next wave of ads.*
