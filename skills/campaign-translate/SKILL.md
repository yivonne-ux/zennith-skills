---
name: campaign-translate
description: Multilingual campaign adaptation engine. Translates ad copy, captions, video subtitles, and marketing assets across EN/BM/ZH while preserving brand voice, cultural nuance, and conversion intent.
agents: [dreami, taoz]
version: 1.0.0
triggers: translate, transcreate, multilingual, BM translation, ZH translation, Bahasa Malaysia, Chinese translation, campaign translate, adapt copy, localize, subtitle translate, multilingual campaign
anti-triggers: brand design, logo, image generation, code, deploy, build, video generation, ads audit
outcome: Campaign assets transcreated into target languages (EN/BM/ZH) with brand voice preserved, cultural nuance adapted, and conversion intent maintained
---

# Campaign Translate -- Multilingual Transcreation Engine

**Owner:** Dreami (transcreation), Taoz (tooling/automation)
**Scope:** All 14 brands, 3 core languages (EN, BM, ZH)
**Cost:** LLM-based transcreation per asset; batch mode available

---

## 1. Overview

This is NOT translation. This is **transcreation** -- adapting entire campaigns to feel native in each target language while preserving what actually matters for conversion.

**What transcreation preserves:** brand voice/tone, conversion intent, cultural appropriateness, SEO keywords per language, character limits per platform.

**What transcreation changes:** wordplay/puns/idioms (recreated, never literally translated), proof points, tone register, hashtags (researched per language).

---

## 2. Translation Workflow SOP

```
INPUT: Source content (any language) + brand name + target languages + content type + platform
STEP 1: DETECT SOURCE LANGUAGE
  - Auto-detect or accept explicit --from flag
  - Identify register: formal, casual, Manglish
STEP 2: LOAD BRAND DNA
  - cat ~/.openclaw/brands/{brand}/DNA.json | jq '.voice'
  - Load references/brand-voice-mapping.md for language-specific voice rules
STEP 3: CLASSIFY CONTENT TYPE
  - ad-copy | caption | subtitle | email | product-desc | whatsapp | general
  - Load references/content-type-sops.md for type-specific transcreation rules
  - Load references/language-matrix.md for char expansion and cultural nuances
STEP 4: TRANSCREATE (per target language)
  a. Adapt for cultural context (NOT direct translate)
  b. Apply brand voice filter from Step 2
  c. Check character limits (BM: 1.1-1.3x expansion, ZH: 0.5-0.7x contraction)
  d. Cultural appropriateness review (halal sensitivity, calendar alignment)
  e. SEO keyword integration (language-specific, not translated)
  - Load references/cta-dictionary.md for proven CTA translations
STEP 5: QUALITY REVIEW -- Back-Translation
  - Back-translate each output to source language
  - Verify meaning preservation (not word preservation)
  - Flag any meaning drift > 15%
STEP 6: BRAND VOICE CHECK
  - bash brand-voice-check.sh --brand {brand} --input {output_file}
  - Must PASS before proceeding
  - Load references/quality-gates.md for full gate details
STEP 7: EXPORT
  - Output all variants in structured format
  - File naming: {asset_name}_{lang}.{ext}
  - Load references/translation-examples-and-output.md for output structure
OUTPUT: Campaign assets in all target languages, QA-verified
```

### Quick-Translate Flow (for single assets)
```
INPUT -> detect lang -> load DNA -> transcreate -> export
```
Skip Steps 5-6 for informal/internal content. Always run full flow for published content.

---

## 3. Supported Languages

| Code | Language | Avg Char Expansion vs EN | Primary Use |
|------|----------|--------------------------|-------------|
| EN | English | 1.0x (baseline) | Urban professionals, general market |
| BM | Bahasa Malaysia | 1.1-1.3x (longer) | Malay-majority audience, formal/gov channels |
| ZH | Chinese (Simplified) | 0.5-0.7x (shorter) | Chinese Malaysian audience, WeChat/XHS crossover |

For full language details, Manglish rules, code-switching strategy, and cultural calendar: Load `references/language-matrix.md`

---

## 4. Reference Files

| Reference File | Contents | Load During |
|---|---|---|
| `references/language-matrix.md` | Language details, char expansion, Manglish rules, code-switching, halal sensitivity, cultural calendar | Step 3-4 |
| `references/content-type-sops.md` | Translation SOPs by type: ad headlines, body copy, hashtags, captions, subtitles, email/EDM, product descriptions, WhatsApp messages | Step 3-4 |
| `references/brand-voice-mapping.md` | Voice loading protocol + brand voice mapping (tone, register, signature phrases, personality, avoid) for MIRRA, Pinxin, Wholey Wonder, Rasaya, GAIA Eats, Dr Stan, Serein | Step 2 |
| `references/cta-dictionary.md` | 45 proven CTAs in EN/BM/ZH: e-commerce, engagement, community, transactional, Manglish casual | Step 4 |
| `references/quality-gates.md` | 5 quality gates: back-translation, brand voice check, cultural sensitivity, character count, platform compatibility | Step 5-6 |
| `references/cli-reference.md` | Full CLI usage examples + flags reference table | CLI usage |
| `references/integration-and-pitfalls.md` | Upstream/downstream skill integration, data flow diagram, translation anti-patterns, untranslatable Malaysian terms | Planning |
| `references/brand-translation-matrix.md` | All 14 brands: primary languages, translation priority, content focus, tone register | Planning |
| `references/translation-examples-and-output.md` | Full brand-specific examples (Wholey Wonder, Dr Stan, Serein), output directory structure, file naming, metadata headers | Step 7 + reference |

---

## 5. Quick CLI Usage

```bash
# Translate ad copy
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh copy \
  --brand mirra --input "Try our new bento!" --to bm,zh

# Translate with Manglish register
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh copy \
  --brand pinxin-vegan --input "Our rendang bowl is back!" --to bm --tone manglish

# Translate SRT subtitles (auto-adjusts timing)
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh subtitle \
  --brand gaia-eats --input video.srt --to bm,zh

# Translate email template
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh email \
  --brand mirra --input weekly-menu-edm.html --to bm,zh

# Batch translate all pending content
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh batch \
  --brand mirra --since 7d
```

For full CLI reference and all flags: Load `references/cli-reference.md`

---

## 6. Key Rules

1. **NEVER direct-translate headlines** -- transcreate with new puns/wordplay in target language
2. **NEVER translate hashtags** -- research trending equivalents per language
3. **NEVER translate Malaysian food names** -- nasi lemak, rendang, satay stay as-is in all languages
4. **ALWAYS load brand DNA** before translating: `cat ~/.openclaw/brands/{brand}/DNA.json | jq '.voice'`
5. **ALWAYS run brand-voice-check.sh** before publishing translated content
6. **Budget 1.3x space** for BM text in design layouts
7. **Match brand register** -- Manglish for casual brands (Pinxin), formal BM for heritage (Rasaya), no Manglish for authority (Dr Stan)
