# Skill Router — Brand Routing Examples

## Brand Coverage — All 14 Brands

| Brand | Example Task | Routed Skill | Confidence |
|-------|-------------|--------------|------------|
| **pinxin-vegan** | "pinxin-vegan weekly menu carousel for IG" | content-repurpose | 0.92 |
| **pinxin-vegan** | "pinxin-vegan CNY promo campaign" | campaign-planner | 0.88 |
| **wholey-wonder** | "wholey-wonder new smoothie product shots" | product-studio | 0.94 |
| **wholey-wonder** | "wholey-wonder recipe reel for TikTok" | video-compiler | 0.87 |
| **mirra** | "mirra bento subscription pack shots" | product-studio | 0.95 |
| **mirra** | "mirra meal plan content for FB & IG" | content-repurpose | 0.90 |
| **rasaya** | "rasaya herbal tea Shopee listing photos" | product-studio | 0.93 |
| **rasaya** | "rasaya wellness campaign BM + EN" | campaign-translate | 0.91 |
| **gaia-eats** | "gaia-eats food delivery GrabFood listing" | grabfood-enhance | 0.96 |
| **gaia-eats** | "gaia-eats hawker stall promo video" | video-compiler | 0.85 |
| **dr-stan** | "dr-stan supplement explainer ad" | ad-composer | 0.89 |
| **dr-stan** | "dr-stan health tips content calendar" | content-supply-chain | 0.86 |
| **serein** | "serein wellness retreat brand shoot" | brand-studio | 0.91 |
| **serein** | "serein mindfulness campaign copy EN/BM" | campaign-translate | 0.90 |
| **jade-oracle** | "jade-oracle AI tarot feature launch video" | video-gen | 0.88 |
| **jade-oracle** | "jade-oracle app store screenshots" | product-studio | 0.84 |
| **iris** | "iris visual QA audit for social posts" | brand-studio | 0.90 |
| **iris** | "iris supplement packaging mockup" | creative-studio | 0.86 |
| **gaia-os** | "gaia-os system architecture explainer" | content-supply-chain | 0.82 |
| **gaia-os** | "gaia-os launch announcement campaign" | campaign-planner | 0.87 |
| **gaia-learn** | "gaia-learn course promo reel" | video-compiler | 0.86 |
| **gaia-learn** | "gaia-learn educational carousel" | content-repurpose | 0.89 |
| **gaia-print** | "gaia-print packaging label design" | creative-studio | 0.93 |
| **gaia-print** | "gaia-print brand guidelines refresh" | brand-studio | 0.91 |
| **gaia-recipes** | "gaia-recipes recipe card video" | video-compiler | 0.88 |
| **gaia-recipes** | "gaia-recipes cookbook page layout" | creative-studio | 0.85 |
| **gaia-supplements** | "gaia-supplements product comparison ad" | ad-composer | 0.90 |
| **gaia-supplements** | "gaia-supplements Shopee listing optimise" | product-studio | 0.92 |

## F&B Brand Routing — Deep Examples

The 7 core F&B/wellness brands have specialised routing rules because food content has unique needs
(food photography, GrabFood listings, halal compliance, BM/EN/ZH multilingual).

### pinxin-vegan
- "pinxin-vegan new set lunch menu photos" -> product-studio (0.94) — food photography with styling
- "pinxin-vegan weekly social content batch" -> content-supply-chain (0.91) — scheduled content pipeline
- "pinxin-vegan GrabFood listing update" -> grabfood-enhance (0.96) — GrabFood photo + description optimisation

### mirra (weight management meal subscription)
- mirra routes to **product-studio** for bento pack shots and meal photography
- mirra routes to **content-repurpose** for platform variants (IG carousel, FB post, WhatsApp status)
- mirra routes to **campaign-translate** for EN/BM/ZH multilingual meal plan promotions
- "mirra weekly bento lineup shoot" -> product-studio (0.95)
- "mirra weight loss testimonial video" -> video-compiler (0.88)

### wholey-wonder
- "wholey-wonder smoothie bowl hero shot" -> product-studio (0.95) — food photography
- "wholey-wonder juice cleanse campaign" -> campaign-planner (0.89) — multi-channel campaign
- "wholey-wonder new flavour launch reel" -> video-compiler (0.87) — short-form video

### rasaya
- "rasaya herbal blend product page" -> product-studio (0.93) — e-commerce product shots
- "rasaya traditional remedy explainer" -> content-supply-chain (0.85) — educational content
- "rasaya Raya promo campaign BM" -> campaign-translate (0.92) — festive campaign in Bahasa

### gaia-eats
- "gaia-eats hawker stall GrabFood optimisation" -> grabfood-enhance (0.97) — listing enhancement
- "gaia-eats food delivery promo video" -> video-compiler (0.86) — delivery promo content
- "gaia-eats new menu item photography" -> product-studio (0.94) — food photography

### dr-stan
- "dr-stan collagen supplement ad for Meta" -> ad-composer (0.91) — paid ad creative
- "dr-stan health tip carousel" -> content-repurpose (0.88) — multi-platform content
- "dr-stan ingredient explainer video" -> video-gen (0.84) — educational video

### serein
- "serein wellness tea brand campaign" -> campaign-planner (0.90) — brand awareness campaign
- "serein mindful morning routine reel" -> video-compiler (0.87) — lifestyle content
- "serein calming ritual product shots" -> product-studio (0.93) — product photography

## Malaysian Market Routing

Malaysian market tasks have specialised routing rules:

- **Shopee listing tasks** -> product-studio (Shopee-optimised product photography and listing copy)
- **GrabFood optimisation** -> grabfood-enhance (food photo enhancement + listing description)
- **Manglish content** -> campaign-translate with `--tone manglish` (code-switching EN/BM casual tone)
- **Festive campaigns** (CNY, Raya, Deepavali) -> campaign-planner with `--market MY`
- **BM/EN/ZH multilingual** -> campaign-translate (transcreation, not literal translation)
