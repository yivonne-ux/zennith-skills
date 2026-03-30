---
name: Social Media Production Intelligence
description: Universal social media content production system. Distinct from ads. Scraping, format adaptation, art style locking, character forensic, audit loop. ALL brands.
type: feedback
---

## SOCIAL MEDIA PRODUCTION INTELLIGENCE — UNIVERSAL (ALL BRANDS)

Social media ≠ ads. Social = organic reach, shareability, saves, DMs. Ads = paid, conversion-focused, ROAS.

---

### 1. CONTENT STRATEGY — SOCIAL MEDIA SPECIFIC

**Content ratio (proven):**
- 60% relatable life content (NOT product-focused)
- 40% brand/product-adjacent
- The brand connection is the CHARACTER, not the product
- Viral = shareability. Shareability = identity + humor + permission-giving

**Content pillars for any brand's social:**
- Relatable moments (audience sees themselves)
- Wisdom/healing (audience saves for bad days)
- Humor (audience DMs to friends)
- Cultural identity (audience tags community)
- Brand values (subtle, through character behavior — NOT through product shots)

**Post frequency:**
- 2/day = standard. 3/day = aggressive growth.
- Slot timing: Morning (11AM) + Afternoon (4PM) + Evening (8PM)
- Rotate: Illustration → Food/Product → Carousel/Educational per day

---

### 2. VIRAL FORMAT ADAPTATION SYSTEM

**The method:**
1. SCRAPE viral accounts in your niche (use x-reader, Instaloader, MediaCrawler)
2. AUDIT scraped refs — separate legit format posts from junk (selfies, ads, vlogs)
3. CLASSIFY into layout types (dual-panel, portrait, scene, action, contrast, dialogue)
4. LOCK brand character forensic (hair, eyes, clothing, age, expression — confirmed by human)
5. Use brand's OWN APPROVED ARTWORK as Image 1 (style anchor). NEVER scraped ref as Image 1.
6. Describe viral layout in PROMPT TEXT only. Image 1 = style, prompt = composition.
7. Generate → audit → fix → regenerate until eyes + style + character all pass
8. Each post uses a DIFFERENT layout type. Same template ×10 = template spam.

**Why:** This method was proven across Mirra (Korean webtoon girl) and Pinxin (warm Chinese mother). The inputs change per brand, but the pipeline is identical.

---

### 3. ART STYLE LOCKING

**Image 1 dominates NANO's art style.** This is the single most important rule.

| Image 1 input | Output style |
|---|---|
| Scraped viral post (ink wash) | Ink wash (WRONG — not your brand) |
| Brand's vector character sheet | Flat clipart (WEAK — too simple) |
| Brand's BEST approved output | Brand style (CORRECT — richest quality) |
| Pinterest concept art | Concept art (WRONG — not your brand) |

**Rules:**
- Always use brand's own APPROVED OUTPUT as Image 1 (not raw assets)
- Image 2 = character sheet or second approved output (reinforces consistency)
- Standard NANO call — don't add "resolution: 2K" unless original formula used it
- Adding "painterly", "editorial", "国潮" etc. CHANGES the style. Only use terms from the brand's original working prompt.
- If you find a working prompt+ref combo: LOCK IT. Don't "improve" it.

---

### 4. CHARACTER FORENSIC

**Get EVERY detail from the human. Never assume:**
- Hair: style (bun/bob/long), color, how it's worn
- Headwear: type (beret/headband/cap), color, position
- Face: age, glasses (yes/no), expression style
- Eyes: stylized (soft curves, closed) vs realistic (detailed iris/pupil)
- Clothing: apron, tee color, casual vs formal variants
- Body: proportions, build

**Character drift detection:**
- Eyes are the #1 indicator. If eyes change → entire character drifted.
- Age drift: character looking 20 instead of 40 = wrong.
- Check character against approved reference BEFORE showing to human.
- "Looks like a young girl" = FAIL. "Looks like the same mother" = PASS.

**Per-brand, not hardcoded:**
- Pinxin: bun hair, navy beret, ~40s, no glasses, stylized soft-curve eyes
- Mirra: Korean girl, 26yo, chunky hair, warm shadows, flat solid bg
- Each brand locks its own character spec. The AUDIT PROCESS is universal.

---

### 5. SCRAPING WORKFLOW

**Tools (Python version matters):**
- MediaCrawler: Python 3.10+ (use `uv venv --python 3.12`)
- XHS-Downloader: Python 3.10+
- x-reader: Python 3.10+ (best for XHS — supports browser session login)
- Instaloader: Python 3.9 OK for public profiles
- instagrapi: Python 3.10+ (union type syntax)
- browser_cookie3: extracts cookies from Chrome but may be incomplete

**XHS scraping:**
- x-reader login: `x-reader login xhs` → saves session to `~/.x-reader/sessions/xhs.json`
- Cover images from search results are MORE reliable than clicking into individual posts
- Account operators post mixed content — always audit scraped refs
- 150 files scraped → only 16 were legit format refs. 90% was junk.

**Quality gate:**
- Delete: selfies, lifestyle vlogs, food reviews, ads, unrelated content
- Keep: actual illustrated/formatted viral posts that match the format you're adapting
- Move verified refs to `_verified/` subfolder

---

### 6. DUAL-LAYER AUDIT

**Layer 1 — Programmatic (no AI needed):**
- Blank zone detection (Laplacian variance < 60 = padding artifact)
- Logo count (exactly 1 brand mark)
- Color vibrancy (saturation ≥ 18% = pass)

**Layer 2 — Vision (human or AI):**
- Eyes match brand spec (soft curves vs realistic — CHECK FIRST)
- Character age consistent (~40 not ~20)
- No brand text rendered in artwork (logo added in post-production only)
- Vegan/dietary compliance (if applicable)
- Layout matches intended format type
- Art style matches approved reference
- Production-ready (would you post this on the brand's official IG?)

**Audit order:** Eyes → Character age → Art style → Layout → Text → Food/dietary → Overall

---

### 7. FOLDER HYGIENE

- `viral-regen-v5/` = current production batch
- `_rejected/viral-v1-v4/` = all old iterations with version folders
- `_rejected/style-tests/` = calibration experiments
- `_rejected/old-charV/` = superseded character versions
- NEVER leave 90+ junk files alongside 12 production files
- Clean up IMMEDIATELY after new batch is approved

---

### 8. SCHEDULING

- Pending posts stored as JSON: `pending_posts.json` per week folder
- Cron publisher (`px_cron_publish.py`) runs every 10 min, checks timestamps
- Images uploaded to FAL cloud storage for Meta Graph API
- Each entry: `{post, publish_at, type, image_url/image_urls, caption}`
- Published posts removed from pending, logged to `published_log.json`

**When replacing posts:**
- Only replace posts of the SAME TYPE (illustration→illustration, not illustration→food)
- Keep food, carousel, promo posts in their original slots
- Upload replacement images to FAL before updating pending JSON
- Unscheduled posts saved for future curation — don't force-schedule everything

---

### 9. SOCIAL vs ADS — KEY DIFFERENCES

| Dimension | Social (organic) | Ads (paid) |
|---|---|---|
| Goal | Shareability, saves, DMs, follower growth | Conversions, ROAS, cost-per-action |
| Content | 60% life/relatable, 40% brand | 100% product/benefit-focused |
| Character | Personality-driven, lifestyle | Product hero, CTA-driven |
| Format | Illustration, comic, quote, scene | Before/after, UGC, comparison, testimonial |
| Copy | Emotional, tag-trigger, save-worthy | Benefit stack, urgency, price, CTA |
| Audience | Broad awareness + community | Targeted segments, lookalikes |
| Metric | Engagement rate, saves, DM sends | ROAS, CPA, CTR |
| Frequency | 2-3/day consistent | Campaign-based bursts |
| Art style | Brand character illustration | Can vary (photo, UGC, graphic) |

**NEVER mix approaches.** A viral wisdom post should NOT have a "买8送8" CTA. A conversion ad should NOT be a subtle illustration with no product.

**How to apply:** Read this before any social media production session for ANY brand. The method is universal — only character/style/content inputs change per brand.
