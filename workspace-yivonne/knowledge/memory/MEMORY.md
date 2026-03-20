# Claude Code Memory — Multi-Brand Design Workflow

---

## BLOOM & BARE (active)
Working dir: `/Users/yi-vonnehooi/Desktop/BRANDS/Bloom & Bare/`
Brand DNA: `brand-guide/brand-DNA.md` | Style ref: `assets/brand-style-reference.md`
Exports: `exports/` | Rejects: `exports/rejected-v1/`

### Brand summary
Family play space, Bukit Jalil KL. Sensory creative play, workshops, birthday parties.
IG: @bloomandbareplay | Parent co: Sprout Wise S/B
Palette: 6 mascot colors (yellow #F0D637 / blue #9DD5DB / green #7DC591 / coral #F09B8B / lavender #B8A0C8 / orange #E88A3A) + cream bg #F5F0E8 + black text #1A1A1A
Fonts: DX Lactos (display) + Mabry Pro (Regular/Medium/Bold/Black) — ALL font files in `assets/fonts/`. Need Noto Sans SC for CJK.
6 mascots: Sunny(star), Cloudy(cloud), Sprout(leaf), Heartie(heart), Petal(flower), Tangy(orange blob)
Logo: `assets/logos/` (8 variants × 4 sizes, transparent PNGs)
Mascots: `assets/mascots/` (6 chars × 4 sizes, transparent PNGs)
Output: 1080×1350 (IG feed), 1080×1920 (stories)
Tone: warm, playful, intentional, parent-friendly, bilingual EN/CN
Past work: 221+ social posts across 6 months (Sept 2025 — Feb 2026)

### Strategy & Research docs
- `strategy/DESIGN-INTELLIGENCE-MASTER.md` — MASTER INDEX: unified playbook linking all research
- `strategy/BULK-PRODUCTION-PLAYBOOK.md` — reverse-engineering, 8 templates (T1-T8), tool stack
- `strategy/DESIGN-PRODUCTION-GUIDE.md` — professional workflows, typography, color, layout (999 lines)
- `strategy/PIXEL-CRAFT-GUIDE.md` — execution techniques with specific numbers (676 lines)
- `strategy/DESIGN-TRENDS-RESEARCH-2026.md` — 2026 trends, children's brand design (887 lines)
- `strategy/PROGRAMMATIC-DESIGN-GUIDE.md` — Python/Pillow/Cairo advanced techniques (1982 lines)
- `research/AI-MODEL-GUIDE.md` — 11 AI models, decision matrix, pricing (634 lines)
- `research/WORLD-CLASS-DESIGN-FIRMS-RESEARCH.md` — 15 firm profiles, roles, design intelligence (1014 lines)
- `research/DESIGN-RESOURCES.md` — inspiration, typography, photo, color sites (~500 lines)

### 8 content archetypes
T1=schedule, T2=quote/values, T3=event poster, T4=promo, T5=photo story, T6=announcement, T7=educational, T8=hiring

### v1 rejection learnings (CRITICAL — never repeat)
1. **FLUX Kontext destroys text** — garbles dense copy after 1 pass, gibberish after 2+
2. **FLUX hallucinated wrong brand** — injected "MarketplaceAtAvalonPark" from training data
3. **Multi-pass AI compounds errors** — each pass garbles more, never self-corrects
4. **AI cannot draw brand mascots/logos accurately** — always composite real PNGs
5. **Architecture for v2**: Python renders ALL text + layout + logos + mascots. AI only for bg textures/decorative non-text zones. Single-pass max. OCR validate after any AI pass.
6. Full rejection log: `exports/rejected-v1/REJECTION-LOG.md`

### Production pipeline v5 — Reference Adaptation (current)
**Architecture**: Reference image in → deep analysis → brand mapping → Pillow reconstruction
- `bloom_analyze.py` — CV + Claude Vision analysis engine (layout spec JSON)
- `bloom_adapt.py` — brand mapping + reconstruction (3 layout types: hero_character, type_dominant, split)
- `bloom_core.py` — rendering primitives (unchanged)
- `bloom_templates.py` — v4 Pinterest-DNA templates (8 templates, bold colors, massive mascots)
- Strategy doc: `strategy/REFERENCE-ADAPTATION-PIPELINE.md`
- Research: `research/reference-based-design-adaptation-research.md`
- **Key insight**: Claude Vision for semantic understanding + OpenCV for spatial precision = hybrid analysis
- **AI models for mood layer**: FLUX.2 Flex (best text+HEX control), FLUX Canny Pro (layout preservation)
- **Python renders ALL**: text, logos, mascots, badges. AI only for bg texture/mood layer (single-pass).
- Post-process: paper texture 0.02, grain 0.014-0.018, always last.
- v1-v3 templates REJECTED by user. v4 = Pinterest DNA (bold colors, massive mascots 400-900px, 100-180pt DX Lactos)
- Pinterest refs in `references/` and `references/6Q/` (~40 images)

---

## MIRRA.EATS
### Full workflow doc
`/Users/yi-vonnehooi/Desktop/mirra-workflow/WORKFLOW.md` — architecture, all learnings, template registry, model guide, prompt patterns. Read this first for any new session.

### Project
Working dir: `/Users/yi-vonnehooi/Desktop/mirra-workflow`
Refs dir: `/Users/yi-vonnehooi/Desktop/mirra-pinterest-refs/`
Food library: `.../Knowledge Base/.../Mirra Knowledge Base/Variety Dishes Mirra/` (14 dishes — ONLY source for food photos)

## Content production — all categories DONE except cat09
All cats (02-08) complete. cat09 (emoji-scene) built but not run. cn-ads-v4 done (24 variants).
Full pipeline/filter/audit details in WORKFLOW.md — read that file, not MEMORY.md.

## Mirra brand
- Palette: blush (248,190,205), dusty rose (235,170,185), crimson (172,55,75), cream (255,245,238)
- Voice: girlboss, unapologetic, no exclamation marks, viral/sendable
- Output: 1080×1350 PNG (static), 1080×1920 (stories/reels)

## LIVE Campaigns (2026-03-16)
- [project_mirra_live_campaigns_march16.md](project_mirra_live_campaigns_march16.md) — **LIVE NOW.** EN + CN campaigns, 6 ad sets, 118 ads (84 static + 34 video), RM1,500/day, all IDs inside.
- **RETARGET campaign deployed:** MIRRA-RETARGET-EN-MAR26 (120242895523710787) — 3 ad sets (HOT/WARM/COOL), 18 ads, RM50/day, PAUSED for review.
- [project_mirra_lead_attribution_mar16.md](project_mirra_lead_attribution_mar16.md) — Day 1 leads: 3/6 from our campaign (BOFU-B02, TOFU-S10, BX09 converting).

---

## PINXIN VEGAN CUISINE (active)
Working dir: `/Users/yi-vonnehooi/Desktop/BRANDS/Pinxin Vegan/`
Brand DNA: `brand-guide/brand-DNA.md`
GDrive: `GoogleDrive-love@huemankind.world/My Drive/Pinxin/`
Notion DB: `eb9453da6779419ca72728a83131dbb5`
North Star: RM60K → RM500K/month. Marketing perfection. Million views.
Products: 18 frozen dishes + 4 paste jars + 4 chilli sauces + satay sticks
Palette: PX Green #1C372A + PX Gold #D0AA7F + burgundy + browns
Visual DNA: "Quiet Luxury Malaysian-Chinese Dining"
Platforms: IG, TikTok, XHS, FB (MY + SG). CN primary, EN secondary.
- [project_pinxin_brand.md](project_pinxin_brand.md) — Full brand project context
- [feedback_pinxin_v1_rejection.md](feedback_pinxin_v1_rejection.md) — v1: not world-class, logo wrong
- [feedback_pinxin_v2_too_minimal.md](feedback_pinxin_v2_too_minimal.md) — v2: too museum, lacks food
- [feedback_pinxin_v21_audit.md](feedback_pinxin_v21_audit.md) — v2.1: 8 issues (contrast, grain, variety, human)
- [feedback_pinxin_v3_fake_photos.md](feedback_pinxin_v3_fake_photos.md) — v3: over-processed = fake. Logo+grain ONLY.
- [feedback_pinxin_v4_logo_safezone.md](feedback_pinxin_v4_logo_safezone.md) — v4: logo = emblem or logotype only. Meta 9:16 safe zone.
- [feedback_pinxin_v6_fundamental_problem.md](feedback_pinxin_v6_fundamental_problem.md) — **KEY INSIGHT: reference = output structure. Need FORMAT-SPECIFIC references.**
- [feedback_pinxin_frozen_only.md](feedback_pinxin_frozen_only.md) — Frozen dishes only, no paste/chilli/noodle
- [feedback_pinxin_brand_constant_design_variable.md](feedback_pinxin_brand_constant_design_variable.md) — Brand constant, design variable
- [feedback_pinxin_logo_placement_actual.md](feedback_pinxin_logo_placement_actual.md) — Logo: emblem top-right (social) or wordmark top-center (BOFU)
- [project_pinxin_campaign_live_march19.md](project_pinxin_campaign_live_march19.md) — **LIVE CAMPAIGN.** All IDs, budgets, kill/scale rules, 3-day results, Raya strategy, transition timeline, Shopify/GSheet access.

---

## JADE ORACLE (new)
Working dir: `/Users/yi-vonnehooi/Desktop/BRANDS/Jade Oracle/`
Brand DNA: `brand-guide/JADE-ORACLE-BRAND-DNA.md`
AI oracle character IP. Luxury spiritual brand. Face-locked "Jade" character.
- [project_jade_oracle_brand.md](project_jade_oracle_brand.md) — **FULL PROJECT.** Character, palette, typography, logo, content strategy, monetization, tech pipeline, competitive forensics.

---

### Pinxin strategy docs (Desktop)
- `strategy/CONTENT-TAXONOMY.md` — 10 categories, ACCA funnel, 4 pipelines, grid strategy, 45/month volume
- `strategy/COPY-DOCTRINE.md` — 6 headline formulas, 6 personas, benefit hierarchy, CTA patterns, hashtag banks
- `strategy/PRODUCTION-INTELLIGENCE.md` — 7-layer prompt architecture, 9 DNA blocks, 22 ad types, post-processing chain, diversity system. Proven from cn-ads-v4 + v4_campaign + v16.

---

## CREATIVE INTELLIGENCE (universal — applies to ALL brands)
- **[creative-intelligence-design-system.md](creative-intelligence-design-system.md)** — **DESIGN SYSTEM.** Complete grid-aesthetic NANO production. IG grid planning (BOLD|PHOTO|CLEAN row rhythm), 9 prompt DNA blocks, 8 design categories, character variety, anti-patterns, post-processing, new-brand onboarding. Proven v16 18/18.
- **[creative-intelligence-godmode.md](creative-intelligence-godmode.md)** — **READ FIRST.** Universal creative production OS. Edit-first technique, 8 DNA qualities, prompting patterns, reference classification, post-processing rules. Brand-agnostic.
- **[creative-intelligence-meta-ads-engine.md](creative-intelligence-meta-ads-engine.md)** — **META ADS ENGINE.** Account audit (API), 10-point diagnosis, 4-campaign architecture, 3-3-3 testing, kill/scale criteria, language segmentation, retargeting 3-tier, budget gates, CTWA/CAPI attribution, naming convention, restructure playbook. Brand-agnostic.
- [reference-scraping-criteria.md](reference-scraping-criteria.md) — 7 quality filters for scraping/auditing reference ads. Scoring system, sources, instant-reject rules.

## CREATIVE INTELLIGENCE MODULE (Mirra project)
- [creative-intelligence-module.md](creative-intelligence-module.md) — Mirra project overview, pipeline architecture, AI model matrix
- [march-campaign-v3-learnings.md](march-campaign-v3-learnings.md) — v3 campaign: 30 variants, BETTER OUTPUTS DNA, god mode edit-first, logo rules
- [v2-template-learnings.md](v2-template-learnings.md) — v2/v8 template system, NANO edit architecture, design principles

### Feedback memories (design production)
- [feedback_zero_ai_food.md](feedback_zero_ai_food.md) — ZERO AI food. Sacred real photos only.
- [feedback_no_burnt_filter.md](feedback_no_burnt_filter.md) — No color grade on NANO. Logo + grain ONLY.
- [feedback_copywriting_direction.md](feedback_copywriting_direction.md) — Low cal, lose weight. NOT plant-based lead.
- [feedback_mirra_plant_based.md](feedback_mirra_plant_based.md) — Mirra IS plant-based but NEVER write "chicken/beef/meat."
- [feedback_no_pil_text.md](feedback_no_pil_text.md) — ALL text = NANO. PIL = resize + logo + grain ONLY.
- [feedback_nano_anti_patterns.md](feedback_nano_anti_patterns.md) — 14 NANO failure modes (AI humans, small type, prompt leak, etc).
- [feedback_cn_ads_nano_prompting.md](feedback_cn_ads_nano_prompting.md) — CN ads: 7-layer prompt, anti-render, brand name leak.
- [feedback_no_leann_kol.md](feedback_no_leann_kol.md) — NO LEANN KOL. Not allowed.
- Logo: [feedback_logo_smart_placement_v2.md](feedback_logo_smart_placement_v2.md) + [feedback_logo_autocrop.md](feedback_logo_autocrop.md) + [feedback_logo_smaller.md](feedback_logo_smaller.md)
- Other: google_drive_desktop, reference_quality, typography_designer_grade, typography_dominance, nano_food_limitation, ai_humans_never, nano_illustration_obsession, nano_typography_luxury, no_raw_png, no_xy_pixel_artifacts, brand_constant_design_variable

### Video production
- [feedback_video_steal_like_artist.md](feedback_video_steal_like_artist.md) — **CRITICAL.** 1:1 reference = frame-by-frame copy. Same poses, angles, timing, momentum. Change person/food/brand only. Never try to be creative with structure. V1-V3 failures documented.
- [feedback_video_production_v1_v6_learnings.md](feedback_video_production_v1_v6_learnings.md) — **COMPLETE V1-V6 JOURNEY.** Model routing (Sora for diversity, Kling for face lock), ultra-precision prompting specs, character sheet approach, assembly pipeline, typography gaps, cost tracking ($34 total). Read before any video production.
- [feedback_video_sora_reverse_creative_process.md](feedback_video_sora_reverse_creative_process.md) — **BREAKTHROUGH.** Design FOR Sora's strengths (impossible camera, macro, atmosphere), not against. Edit food photos to editorial level BEFORE i2v. Three moods: high-hook creative / girlboss story / food vibes. Brand constant, format variable.
- [project_video_production_system.md](project_video_production_system.md) — **FULL STATE March 16.** Pipeline at ~/Desktop/video-compiler/, 9 research docs, V1-V7 + Sora Masterpiece + Calculator produced, $45 API spent, all learnings, next session priorities.
- [feedback_video_system_not_solo.md](feedback_video_system_not_solo.md) — **KITCHEN SYSTEM.** Video = team of stations (Brief→Script→ArtDir→Prompt→Gen→Edit→Grade→Type→Sound→QC). Critical gaps: script, typography, sound, editorial rhythm. Full DNA at VIDEO-PRODUCTION-DNA.md.
- [feedback_video_craft_rules.md](feedback_video_craft_rules.md) — **READ FIRST FOR ALL VIDEO.** Hard rules: NANO only (never FLUX), ultra-detail prompts, script FIRST, Veo 3 i2v cracked, 9 models working, 6 craft gaps to close. Complete operating system.
- [project_video_mastery_state_mar17.md](project_video_mastery_state_mar17.md) — Full session state. All tools, research, models, costs, priorities.
- [project_video_production_mar19.md](project_video_production_mar19.md) — **ACTIVE SESSION Mar 19.** Scene-by-scene vlog production. Scene 02 first-attempt pass. Auto-QC + Gemini verification pipeline working.
- [feedback_vlog_production_v5_regression.md](feedback_vlog_production_v5_regression.md) — **19 FAILURES from Lost5kg.** Pipeline bugs (stale clips, double text), camera rules, food sourcing (NEVER AI food), setting consistency, typography (outline stroke), process (script FIRST). Pre-flight QC checklist.

### Output organization
- [feedback_output_organization.md](feedback_output_organization.md) — **ALWAYS FOLLOW.** Universal folder structure for all brands. Never dump in /tmp/. finals/ + scripts/ + rejected/ pattern.

### Feedback memories (Meta API + ads)
- [feedback_meta_ads_production_rules.md](feedback_meta_ads_production_rules.md) — RM800K rules: lo-fi > polished, 0.5s message, 10+ concepts, kill criteria.
- [feedback_meta_api_hard_lessons.md](feedback_meta_api_hard_lessons.md) — **CRITICAL.** Copy wipe bug, rate limiting, token expiry, post ID failures. Never repeat.
- [feedback_creative_reasoning_engine.md](feedback_creative_reasoning_engine.md) — **HOW concepts are born.** 5-step chain: persona behavior → format hijack → collision → hook check → diversity. Universal.

### Project memories
- [project_mirra_march_campaign_strategy.md](project_mirra_march_campaign_strategy.md) — **ACTIVE CAMPAIGN PLAN.** 3-campaign structure (SCALE/TEST/RETARGET), budget gates, video+static ABO testing, act_830110298602617. Scale RM143K→RM250K.
- [project_cn_ads_v4_campaign.md](project_cn_ads_v4_campaign.md) — CN ads v4: 24 variants locked, 4 fix rounds, NANO pipeline, 5 personas, 6 directions.
- [project_mirra_meta_ads_business.md](project_mirra_meta_ads_business.md) — 30+ ads/day, ROAS 4-5x target, KL/Selangor bento subscription, plant-based hidden, 50+ menu, nutritionist designed.
- [project_mirra_north_star.md](project_mirra_north_star.md) — **NORTH STAR: RM800K/month.** ~1,404 meals/day, ~2,105 active subscribers, RM160-200K/month ad spend at 4-5x ROAS. Every ad must SELL.
- [reference_meta_ads_intelligence.md](reference_meta_ads_intelligence.md) — **16 research docs**: master intelligence (14 sections), ROAS playbook, meal subscription, DTC brands, psychology, competitive, viral hooks, account architecture, bidding, pixel/CAPI, flexible ads, + 5 Malaysian market docs. Quick-recall cheat sheet inside.
- [creative-intelligence-meta-2026-algorithm.md](creative-intelligence-meta-2026-algorithm.md) — **2026 META DEEP RESEARCH.** Andromeda engine, Entity ID, 20% budget rule, CAPI requirement, Advantage+, creative-first paradigm, Raya strategy. Full docs at META-ADS-INTELLIGENCE-2026.md + 3 research files.
- [project_malaysian_market_intelligence.md](project_malaysian_market_intelligence.md) — Malaysian market data: CPC 75% cheaper than US, XHS 2.5M users, WhatsApp 45-60% CTR, Simplified Chinese + code-switch, health claims regulated, payday billing, seasonal calendar, customer avatar "Michelle".
- [project_launch_campaign_plan.md](project_launch_campaign_plan.md) — 12-week launch plan. 3 concepts × 3 hooks × 3 formats = 27 ads. CTWA primary. Budget RM150→RM2,500/day with gates. Need: mirra_carousel_batch.py, copy doc, Respond.io, Billplz.
- [reference_deep_research_march2026.md](reference_deep_research_march2026.md) — **4 new research docs (March 14)**: global meal subscription ads, CTWA psychology, food ad creative intelligence, SEA F&B benchmarks. AG1 $100M template, Trifecta 13.2x ROAS, screenshot ads 42% more effective, carousel CPA -30-50%.
- [project_mirra_creative_mastery.md](project_mirra_creative_mastery.md) — **CREATIVE MASTERY from 700+ Notion entries.** 12 EN + 12 CN personas, ACCA funnel architecture, winning concepts (Sales Boom Boom = 12-month winner), 13 raw ad types, 30+ KOL engine, 130+ template library, kill/live patterns. Full doc: `MIRRA-CREATIVE-MASTERY.md`
- [reference_mirra_pricing_march2026.md](reference_mirra_pricing_march2026.md) — **Current pricing (March 2026).** Solo Glow/Bestie Tone Up/Fit Fam × 10/20/40 meals. RM17.75-24/meal. Free delivery 10km OUG. Special gift at 20+. GDrive + local copy saved.
- [reference_mirra_sales_gdrive.md](reference_mirra_sales_gdrive.md) — **Sales record.** GDrive path + Sheet ID + CSV export command. Daily orders, revenue, channel, new/repeat.

- [feedback_video_craft_v4_learnings.md](feedback_video_craft_v4_learnings.md) — **V4 SESSION.** Ohneis prompt DNA, Ana forensic, font liberation, ASMR gaps, art+message. Apply to ALL video.
- [creative-intelligence-video-art-direction-mastery.md](creative-intelligence-video-art-direction-mastery.md) — **VIDEO MASTERY. READ FIRST.** Complete art direction system: ohneis foundations, cinematography, 8-point shot grammar, emotional-beat-to-camera mapping, audio design, prompt engineering, production pipeline, session learnings. Replaces feedback_video_craft_v4_learnings.
- [creative-intelligence-vlog-production-system.md](creative-intelligence-vlog-production-system.md) — **VLOG SYSTEM.** Proven end-to-end pipeline. Reference-first workflow, character/mood anchoring, Kling PRO, FFmpeg post-prod, technical bugs. Apply to ANY brand.
- [creative-intelligence-production-continuity-system.md](creative-intelligence-production-continuity-system.md) — **CONTINUITY SYSTEM.** 4-agent pre-generation workflow (Director/Art Director/Wardrobe/QC). Scene spec sheets. Outfit consistency. Reference intelligence. Apply to ALL video production.
- [feedback_video_generation_hard_lessons.md](feedback_video_generation_hard_lessons.md) — **33 HARD LESSONS.** Every failure pattern from 15+ hours of video generation. NANO behavior, prompt engineering, character consistency, setting copy, food shots, technical bugs, process rules. READ BEFORE generating.
- [creative-intelligence-reference-mastery.md](creative-intelligence-reference-mastery.md) — **REFERENCE MASTERY.** Rating system (5 dimensions), taxonomy, curation process, forensic analysis framework, matching engine, sourcing strategy. References = 50% of output.
- [creative-intelligence-reference-mastery.md](creative-intelligence-reference-mastery.md) — **REFERENCE MASTERY.** Rating system, taxonomy, curation, forensic analysis, matching engine. References = 50% of output.
- [creative-intelligence-tool-stack.md](creative-intelligence-tool-stack.md) — **TOOL STACK.** Every tool installed: fal.ai models, local Python tools, APIs, infrastructure. When to use what. Problem → tool mapping.
