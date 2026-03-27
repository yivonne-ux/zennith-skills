---
name: jade-content-studio
description: Unified AI character content pipeline for Jade Oracle. Character creation, face lock, body pairing, IG content generation, ad hooks, quality gates, and growth engine — all proven workflows from 5 months of production experience.
agents: [dreami, taoz]
version: 1.0.0
triggers: jade content, jade oracle, jade ig, jade post, jade ad, jade character, jade face lock, jade video, oracle content, psychic content, QMDJ content, jade reading
anti-triggers: translate, brand design, product studio, shopify, code deploy, campaign translate
outcome: Production-ready Jade Oracle content (IG posts, ads, videos) with face-locked character consistency, brand voice compliance, and quality gate pass
---

# Jade Content Studio -- The Definitive Jade Oracle Content Playbook

> Consolidated from: character-design, character-lock, character-body-pairing, ig-character-gen, ai-influencer
> Production-tested: 2026-03-09 to 2026-03-23 (15+ iterations, 8 body pairings scored 6-9/10, 3 confirmed IG images)
> This is the SINGLE SOURCE OF TRUTH for all Jade Oracle character content.

---

## 1. Overview

Jade Oracle is an AI psychic reading platform powered by Qi Men Dun Jia (QMDJ) -- 1,080 gates, far beyond generic tarot (78 cards). The brand face is **Jade** -- a Korean woman, early 30s, with a jade pendant necklace. Warm, wise, approachable, effortlessly attractive. Lives in a Western city (NYC/LA/Melbourne).

**Business model:** FREE content (TikTok/IG) -> $1 intro reading (Shopify) -> $29-97 full reading -> $497 mentorship

**Face lock status:** LOCKED (v7 approved, 2026-03-13). Primary ref: `lock-08-v6-body-front.png`.

---

## 2. End-to-End Workflow SOP

```
INPUT: Content brief (pillar + day) OR ad hook + platform
STEP 1: Load Jade character specs
        Load references/character-bible.md for full Jade specs
STEP 2: Select face refs (slots 1-5) and body ref (slot 6)
        Load references/face-lock-protocol.md for 60% rule and ref array
        Load references/body-fashion-pairing.md for vibe matching
STEP 3: Compose prompt with anchor phrase + scene description
        Load references/ig-content-pipeline.md for prompt formula + scene library
        Load references/prompt-templates-and-cross-brand.md for copy-paste templates
STEP 4: Generate image via NanoBanana (Flash for full-body, Pro for portrait)
STEP 5: Run 6-gate quality check
        Load references/quality-gates.md for all 6 checks
STEP 6: If PASS -> export to canonical path + register in visual-registry
STEP 7: Generate caption using brand voice + fast-iterate scoring
OUTPUT: Production-ready image + caption + metadata for publishing
```

---

## 3. Jade Quick Reference

| Attribute | Value |
|-----------|-------|
| **Name** | Jade Lin |
| **Ethnicity** | Korean |
| **Age** | 31 |
| **Hair** | Dark brown, long, soft curtain bangs |
| **Eyes** | Warm brown |
| **Signature** | Jade teardrop pendant necklace (ALWAYS present) |
| **Expression** | Calm knowing smile |
| **Makeup** | Minimal -- tinted moisturizer, lip tint, light mascara |
| **Style** | Photorealistic iPhone quality, NOT editorial/CG |
| **Settings** | Western city ONLY (NYC/LA/Melbourne) |
| **Lighting** | Warm natural: golden hour, candlelight, morning sun |

For full character bible (wardrobe, pairings, colors, avoid list): Load `references/character-bible.md`

---

## 4. Critical Rules

1. **Face refs >= 60%** of total reference slots (below this, face drifts)
2. **Jade pendant necklace MUST be visible** in every image
3. **PHOTOREALISTIC** -- iPhone/mirrorless quality, NOT editorial, NOT CG
4. **Western city settings ONLY** -- NYC/LA/Melbourne lifestyle
5. **No illustration, no cartoon, no CG** -- end every prompt with this
6. **No cosmic/celestial/galaxy** -- no purple palette, no crystal balls, no gothic
7. **Flash for full-body**, Pro for close-up portraits
8. **One clear activity per image** -- not multiple
9. **Always run 6-gate quality check** before publishing
10. **Always run brand-voice-check.sh** on captions before publishing

---

## 5. Reference Files

| Reference File | Contents | Load During |
|---|---|---|
| `references/character-bible.md` | Full Jade specs, hair styles, wardrobe, wardrobe-setting pairings (scored), brand visual rules, color palette, AVOID list | Step 1 |
| `references/face-lock-protocol.md` | 60% rule, 7-slot ref array pattern, prompt ref labeling, anchor phrases, model selection rules, 7 known gotchas (all from production failures), anti-drift rules | Step 2 |
| `references/body-fashion-pairing.md` | Vibe classification system (5 vibes), cardinal rule (MATCH VIBES), Jade's vibe, lens guide by shot type, fashion language that works, production results log | Step 2-3 |
| `references/ig-content-pipeline.md` | 7-pillar content calendar, IG image generation rules, prompt formula, 20 proven scene library, 3 confirmed IG images (reverse-engineered) | Step 3 |
| `references/quality-gates.md` | 6 checks: face consistency, anti-pattern scan, brand voice, physical realism, copy quality, platform specs | Step 5 |
| `references/ad-hooks.md` | 5 winning hooks (scored), 7 hook engineering rules, hook templates (comparison, pattern interrupt, oddly specific number, birth year), script formula | Ad creation |
| `references/funnel-matrix.md` | TOFU/MOFU/BOFU/Retention content matrix with CTAs, price points, Jade outfits, content ratio | Strategy |
| `references/video-production.md` | Talking head tools (HeyGen, Hedra, LivePortrait), B-roll tools (Kling, Wan, Sora), production rules, voice clone, video assembly pipeline | Video |
| `references/competitor-intel.md` | Psychic Samira analysis, Jade's differentiators table, other competitors, intelligence gathering | Strategy |
| `references/growth-engine.md` | Monthly targets, posting strategy/times, engagement strategy, hashtag strategy, content repurpose flow | Growth |
| `references/character-evolution.md` | Phase timeline (Seraphina -> Luna v1-v5 -> Jade), 7 key lessons from the journey, Luna v3 secondary character | History |
| `references/cli-reference.md` | Full CLI: ig-post, weekly, ad, quality-gate, face-check, body-pair, video, batch, NanoBanana direct commands | CLI usage |
| `references/file-locations.md` | Canonical paths: character data, face refs, brand DNA, generated content, video output, skill location | File lookup |
| `references/integration-and-costs.md` | Skills used/fed into, agent responsibilities, per-image/per-video cost model, monthly operating cost, break-even | Planning |
| `references/prompt-templates-and-cross-brand.md` | 5 copy-paste prompt templates (IG lifestyle, face-locked, ad creative, spiritual scene, character sheet), cross-brand adaptation guide, Malaysian market context | Step 3 + adaptation |

---

## 6. Quick CLI Usage

```bash
# Generate Jade IG content for a specific day
bash scripts/jade-content-studio.sh ig-post --day monday --pillar educational

# Generate a specific scene
bash scripts/jade-content-studio.sh ig-post \
  --scene "Farmers market, white wrap blouse, jeans, holding wildflowers, laughing"

# Generate weekly content batch (7 posts)
bash scripts/jade-content-studio.sh weekly --brand jade-oracle

# Generate ad creative with specific hook
bash scripts/jade-content-studio.sh ad \
  --hook "Your tarot reader can't do math" --platform tiktok

# Run quality gate on generated image
bash scripts/jade-content-studio.sh quality-gate --image /path/to/image.png

# Full video pipeline
bash scripts/jade-content-studio.sh video \
  --topic "birth year 1988 reading" --platform tiktok
```

For full CLI reference: Load `references/cli-reference.md`

---

## 7. Key File Locations

```
~/.openclaw/workspace/data/characters/jade-oracle/jade/face-refs/   # Locked face refs
~/.openclaw/workspace/data/characters/jade-oracle/jade/jade-spec-v2.json  # Full spec (CANONICAL)
~/.openclaw/brands/jade-oracle/DNA.json                              # Brand DNA
~/.openclaw/workspace/data/images/jade-oracle/                       # Generated content
~/.openclaw/workspace/data/videos/jade-oracle/                       # Video output
```

For full file tree: Load `references/file-locations.md`

---

*Consolidated: 2026-03-23 from 5 months of production experience across 5 skills.*
*Character locked: 2026-03-13. Brand face: Jade (Korean, early 30s, jade pendant).*
*Source skills: character-design, character-lock, character-body-pairing, ig-character-gen, ai-influencer.*
