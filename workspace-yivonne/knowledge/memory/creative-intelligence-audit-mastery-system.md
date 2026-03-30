---
name: Audit Mastery System — World-Class Creative Production QA (v1.0)
description: SUPERSKILL. Self-evolving audit system covering EVERY dimension at EVERY pipeline stage. Brand-agnostic core + brand DNA overlay. Compounds with every user yes/no. Built from 200+ posts, 10+ rounds, 6 brands + world-class research.
type: feedback
---

# AUDIT MASTERY SYSTEM — WORLD-CLASS CREATIVE QA (v1.0)
**Self-evolving. Brand-agnostic. Forensic-grade.**
**Built from:** 200+ posts, 148 compound learnings, 6 brands, 10+ production rounds
**Architecture:** Autoresearch-style compound learning — every use makes it sharper

---

## ARCHITECTURE

```
┌─────────────────────────────────────────────────┐
│              AUDIT MASTERY SYSTEM                │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │ STAGE    │  │ DOMAIN   │  │ COMPOUND     │  │
│  │ AUDITS   │  │ AUDITS   │  │ LEARNING     │  │
│  │ (9 gates)│  │ (14 dims)│  │ LOOP         │  │
│  └──────────┘  └──────────┘  └──────────────┘  │
│       │              │              │           │
│       ▼              ▼              ▼           │
│  Every pipeline   Forensic per   Every yes/no  │
│  stage has a      domain at any  crystallizes   │
│  quality gate     depth needed   into rules     │
│                                                 │
│  ┌──────────────────────────────────────────┐   │
│  │         BRAND DNA OVERLAY                │   │
│  │  Pluggable per-brand audit thresholds,   │   │
│  │  palette checks, style gates, compliance │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

---

## PART 1: STAGE AUDITS — Gate at Every Pipeline Step

No step can be skipped. Each gate must pass before proceeding to the next stage.

### GATE 0: PRE-PRODUCTION AUDIT
**When:** Before generating anything
**Checks:**
- [ ] Content calendar exists with category mix, funnel ratios, persona rotation
- [ ] All references scraped, quality-gated, classified (FORMAT/AESTHETIC/CONTENT/FOOD)
- [ ] Copyright pre-screen passed (no Disney/Pixar/Bratz/movie stills in ref library)
- [ ] Safety pre-screen passed (no weapons/violence/nudity in ref library)
- [ ] Color mood planned across batch — no 3+ consecutive same dominant color
- [ ] Quote log checked — zero reuse across batches
- [ ] Brand config loaded — palette, voice, compliance gates verified
- [ ] Aspect ratio confirmed in all API call templates
- [ ] Food photos enhanced (PIL editorial: brightness +12%, color +8%, contrast +5%, sharpness +15%)
**Fail action:** Do NOT proceed to production. Fix the gap first.

### GATE 1: SCRAPE QUALITY AUDIT
**When:** After scraping references, before classification
**Checks:**
- [ ] Source diversity — not all from same 5 IG accounts; minimum 8+ distinct sources
- [ ] Resolution gate — min 600×600, portrait-friendly aspect
- [ ] File size gate — min 20KB (rejects thumbnails)
- [ ] Perceptual hash dedup — no near-identical refs in batch
- [ ] Freshness — dated content removed (2024-era memes in 2026 = stale)
- [ ] Quantity — scraped 10× what's needed (10% survival rate after filtering)
- [ ] No branded watermarks, stock photo watermarks, or social UI elements
**Fail action:** Scrape more from different sources.

### GATE 2: REFERENCE CLASSIFICATION AUDIT
**When:** After classifying each ref by purpose
**Checks:**
- [ ] Every ref classified as exactly ONE primary type: FORMAT / AESTHETIC / CONTENT / FOOD
- [ ] FORMAT refs: layout described in TEXT only, never passed as Image 1
- [ ] AESTHETIC refs: passed as Image 1 — verified to match brand DNA palette/mood
- [ ] CONTENT refs: text extracted, attributed to source (handle + platform)
- [ ] FOOD refs: verified from brand's sacred food library, enhanced before use
- [ ] No luxe food refs (jewel toast, pearl pizza) assigned as AESTHETIC for food posts
- [ ] Ref-to-post mapping complete — every post has unique ref, no sharing
**Fail action:** Reclassify. If ref doesn't fit any type cleanly, discard.

### GATE 3: PROMPT ASSEMBLY AUDIT
**When:** After assembling 7-layer prompt, before API call
**Checks:**
- [ ] Layer 1 SAFETY present (ANTI_RENDER + NO_BRAND_LEAK + MARGIN)
- [ ] Layer 2 REFERENCE present ("Edit this image" or generation instruction)
- [ ] Layer 3 BRAND DNA present (palette keywords, atmosphere from brand config)
- [ ] Layer 4 CAMPAIGN/CATEGORY present (persona, funnel stage)
- [ ] Layer 5 COPY present (exact viral quote in quotes, attributed)
- [ ] Layer 6 TYPOGRAPHY present (font DNA, size guidance)
- [ ] Layer 7 OUTPUT present (aspect_ratio set, safe zones if ads)
- [ ] NO poison words: sparkle dust, glitter, candlelit, bokeh, dreamy, atmospheric, rose gold (in food prompts)
- [ ] NO hex codes, pixel values, font names in prompt body
- [ ] NO English text that could leak into output (description language only)
- [ ] NO word "logo" in prompt
- [ ] Vegan/dietary gate at END of prompt
- [ ] Food signature markers included if food post
- [ ] Prompt length check — not over 3 lines of dense Chinese
- [ ] **COMPOSITING FEASIBILITY CHECK (v1.2):** If prompt asks NANO to place sacred food into a lifestyle scene (desk, table, hands, kitchen) → REQUIRES a REAL reference photo showing that exact composition. If no real ref exists → DO NOT ATTEMPT. Use type-driven layout instead.
- [ ] **CONTENT ACCURACY CHECK (v1.2):** Every calorie number verified from actual brand data. Every quote traced to viral source with handle. Every food item in generated scenes screened for vegan compliance.
- [ ] **WORD-BY-WORD PROOFREAD (v1.2):** Read every word in text-heavy prompts. Check for typos, wrong words, grammatical errors BEFORE sending to NANO.
- [ ] **MIRRA COPY CHECK (v1.2):** Never say "plant-based" prominently. Use: "diet bento", "low cal", "<500kcal", "clean eating", "100% natural" instead.
**Fail action:** Fix prompt before calling API.

### GATE 4: GENERATION OUTPUT AUDIT (the main 14-dimension audit — see Part 2)
**When:** After NANO returns image, before post-processing
**Checks:** Full 14-dimension domain audit (see Part 2 below)
**Fail action:** Regenerate with fixed prompt. Max 3 attempts before escalation.

### GATE 5: POST-PROCESSING AUDIT
**When:** After PIL resize + logo + save
**Checks:**
- [ ] PIL did ONLY resize + logo + save — no color grading, no grain, no filters
- [ ] Logo placed in cleanest zone, not overlapping text
- [ ] Logo correct B/W for background luminance
- [ ] Single logo only — no double logo (NANO text + PIL logo)
- [ ] Final dimensions correct (1080×1350 for feed, 1080×1920 for stories)
- [ ] No quality degradation from compression (PNG, not lossy)
- [ ] File saved to correct output directory
**Fail action:** Re-run post-processing with fix.

### GATE 6: BATCH COHERENCE AUDIT
**When:** After all posts in batch are generated, before presenting
**Checks:**
- [ ] Grid rhythm maintained (BOLD → PHOTO → CLEAN row pattern)
- [ ] Color variety across batch — no 3+ consecutive same dominant
- [ ] Format variety — no 2 posts with same format-concept pair
- [ ] Persona rotation — not all posts aimed at same persona
- [ ] No two posts look like "same template different text"
- [ ] Feed scroll test — viewing all posts in sequence feels DIVERSE
- [ ] Category coverage — ACCA funnel ratios met
**Fail action:** Swap/regen the offending posts for variety.

### GATE 7: USER REVIEW AUDIT
**When:** Presenting batch to user
**Required presentation per post:**
- [ ] Post image visible
- [ ] 14-dimension score table
- [ ] Source viral ref attributed (handle + platform + engagement if known)
- [ ] Any flags noted (copyright risk, borderline, minor issues)
- [ ] Comparison to proven posts from same brand if available
**Fail action:** User rejects → compound learn → regenerate.

### GATE 8: COMPOUND LEARNING AUDIT
**When:** After every user yes/no decision
**Checks:**
- [ ] Decision logged (post ID, yes/no, reason, which dimension failed)
- [ ] New rule extracted if novel failure (not already in rule database)
- [ ] Existing rule strengthened if repeated failure (increase confidence)
- [ ] Brand-specific vs universal classification applied
- [ ] Memory file updated (or new memory created if novel pattern)
- [ ] Audit skill version incremented if new dimension discovered
**Fail action:** Never skip logging. Every decision = data.

---

## PART 2: DOMAIN AUDITS — 14 Forensic Dimensions

Each dimension can be invoked independently at any depth. Score 0 (fail) or 1 (pass).
Dimensions marked (!) are CRITICAL — instant reject if failed regardless of total.

### DIM 1: TYPOGRAPHY AUDIT (!)
**Forensic checklist:**
- [ ] **Hierarchy:** Clear primary/secondary/tertiary text levels. Reader's eye follows intended order
- [ ] **Size:** Type-driven posts = 50-60%+ canvas height. Body text readable at phone scale
- [ ] **Rendering:** No garbled characters, no NANO artifacts, no half-rendered glyphs
- [ ] **Kerning/Tracking:** No awkward letter spacing. Wide tracking for luxury, tight for editorial
- [ ] **Font feel:** Matches brand DNA — editorial serif (Playfair/Canela energy) not decorative script
- [ ] **CN/TC rendering:** Chinese/Traditional Chinese characters fully formed, no broken strokes
- [ ] **Contrast:** Text readable against background. WCAG AA minimum (4.5:1 for body, 3:1 for large)
- [ ] **No orphans/widows:** No single-word lines dangling at end of text block
- [ ] **Alignment:** Consistent — left, center, or right. No mixed alignment without design reason
- [ ] **Margin safety:** All text 10%+ from all edges. Logo zone clear

### DIM 2: PHOTOGRAPHY AUDIT (!)
**Forensic checklist:**
- [ ] **Authenticity:** All food = real photography, never AI-generated
- [ ] **Sacred preservation:** Brand product photos placed EXACTLY — same container, plating, colors
- [ ] **Editorial quality:** Brightness, warmth, sharpness enhanced (not raw/dull)
- [ ] **Naturalness:** Enhancement still looks natural, not over-saturated or HDR-fake
- [ ] **White balance:** Correct color temperature — no blue/green color casts on food
- [ ] **Sharpness:** Food textures crisp and detailed, not soft/blurry
- [ ] **Composition:** Subject placed intentionally — rule of thirds, diagonal, or centered
- [ ] **Focus:** Main subject in focus, intentional depth-of-field if any
- [ ] **Angle match:** Top-view food in flat-lay scenes, side-view in editorial table scenes
- [ ] **Signature markers:** Brand-specific food markers visible (petai beans, purple eggplant, etc.)
- [ ] **BLEND/COMPOSITE QUALITY (v1.2):** If food is placed into a scene, does it look NATURALLY INTEGRATED or PASTED ON? Check: shadow direction matches scene, lighting matches, edge blending is seamless, scale is realistic. If food looks like a sticker on a background → INSTANT REJECT
- [ ] **DISTORTION CHECK (v1.2):** Has NANO warped/distorted the sacred food photo? Check for: stretched textures, unnatural colors, plasticky look, melted edges, impossible food shapes. If ANY food distortion detected → INSTANT REJECT
- [ ] **LIFESTYLE FEASIBILITY (v1.2):** If the design requires lifestyle context (hands, kitchen, desk, table) — was a REAL reference photo used? If NANO imagined the lifestyle scene → the food WILL look pasted/distorted. Reject and use type-driven layout instead
- [ ] **WHITE BLOWOUT CHECK (v1.3):** Has editorial enhancement blown out whites? Bento container, rice, and light-colored foods must retain texture and detail — not become white blobs. If highlights clip above 245 on >5% of pixels → reduce brightness. White = detail, not flat white.
- [ ] **CONTAINER VARIETY (v1.3):** In multi-food layouts (quiz, list, grid), food photos must have VISUAL VARIETY in container shapes — not all rectangular bentos. Mix: round bowls, rectangular bentos, wraps, poke bowls. Same container 3× = boring.

### DIM 3: COLOR AUDIT (!)
**Forensic checklist:**
- [ ] **Brand palette match:** Primary, accent, background colors from brand config
- [ ] **Tonal depth:** Multi-layer — shadows/midtones/highlights each different tone (not flat overlay)
- [ ] **Temperature:** Matches brand warmth type (Mirra=candlelit, Pinxin=quiet-luxury cool, DotDot=clinical-warm)
- [ ] **No off-brand colors:** No green/sage for Mirra, no neon for Pinxin, etc.
- [ ] **Contrast ratio:** Foreground pops from background (squint test)
- [ ] **Feed variety:** Not 3+ consecutive same dominant color in batch
- [ ] **Grain quality:** Organic film grain, not digital noise artifacts
- [ ] **No color casts:** No unintentional yellow, blue, or green shifts
- [ ] **Mood match:** Color mood matches emotional intent of the post

### DIM 4: LAYOUT/COMPOSITION AUDIT
**Forensic checklist:**
- [ ] **Grid compliance:** Content organized on intentional grid (not randomly placed)
- [ ] **Visual weight balance:** No lopsided compositions — weight distributed intentionally
- [ ] **Negative space:** Breathing room around key elements — not cramped
- [ ] **Reading flow:** Eye moves through content in intended order (Z-pattern, F-pattern, or centered)
- [ ] **Panel consistency:** Multi-panel posts have even dividers, consistent panel sizes
- [ ] **Logo zone:** Clear space reserved for logo placement — no clutter in logo area
- [ ] **Safe zones:** For ads: text outside Meta overlay zones (top 14%, bottom 20%)
- [ ] **Aspect ratio:** Correct for target (4:5 feed, 9:16 stories, 1:1 square)

### DIM 5: ART STYLE AUDIT
**Forensic checklist:**
- [ ] **Style lock:** Illustration matches brand's locked style (Korean webtoon for Mirra, heritage-luxury for Pinxin)
- [ ] **Eyes check:** Character eyes match brand style (soft curves = correct, realistic iris/pupil = wrong for illustration brands)
- [ ] **Character consistency:** Same character style across panels in multi-panel posts
- [ ] **Face rendering:** Fully rendered faces — no blank/featureless faces
- [ ] **No style bleed:** Image 1 style doesn't bleed into non-style elements (bling on food, etc.)
- [ ] **NOT Disney/Pixar/chibi:** Unless brand specifically uses that style
- [ ] **Atmosphere match:** Background treatment matches brand DNA (sparkle for Mirra, muted earth for Pinxin)

### DIM 6: REFERENCE INTEGRITY AUDIT (!)
**Forensic checklist:**
- [ ] **Traced to source:** Every post traces to a SPECIFIC viral post with proven engagement
- [ ] **Not passthrough:** Output is TRANSFORMED to brand palette, not ref with text swapped
- [ ] **No residual UI:** No carousel indicators, play buttons, other app UI from ref
- [ ] **No residual text:** No other brand names on props, signs, or labels from ref
- [ ] **No residual watermarks:** No stock photo watermarks or creator signatures
- [ ] **Unique ref:** This post's ref not reused from any other post in batch
- [ ] **Copyright clear:** No recognizable IP (movie characters, cartoon characters, TV stills)

### DIM 7: LOGO AUDIT
**Forensic checklist:**
- [ ] **Single logo rule:** Either PIL logo OR NANO brand text. NEVER both
- [ ] **Zone placement:** Logo in cleanest zone, away from text and busy areas
- [ ] **Size correct:** Within brand spec (typically 80-120px wide)
- [ ] **B/W correct:** Black logo on light bg, white logo on dark bg
- [ ] **Opacity correct:** Typically 85-95% (visible but not overpowering)
- [ ] **No overlap:** Logo doesn't overlap any rendered text or key visual elements
- [ ] **Auto-crop applied:** Transparent padding cropped before resize

### DIM 8: EFFECTS/TEXTURE AUDIT
**Forensic checklist:**
- [ ] **Texture present:** Not flat/clinical — has film grain, paper texture, or atmospheric depth
- [ ] **Effects match brand:** Mirra=sparkle/glitter, Pinxin=paper/textile, DotDot=clean/accessible
- [ ] **No PIL effects:** All effects from AI pass, not PIL post-processing
- [ ] **Grain quality:** Organic film grain, not digital noise
- [ ] **No burned filter:** No heavy color grade overlays that destroy detail
- [ ] **Light leaks/bokeh:** If present, they feel natural not obviously overlaid

### DIM 9: VIRAL/CONTENT AUDIT
**Forensic checklist:**
- [ ] **DM test:** Would someone send this to 5 friends? If no → fail
- [ ] **Currency:** Concept is trending NOW (2026), not stale (2024-era)
- [ ] **Hook:** Specific, sharp hook — not generic "eat well" or "you deserve this"
- [ ] **Purpose:** Every post delivers: humor, education, emotion, or identity claim
- [ ] **Copy source:** Quote COPIED from proven viral post with attribution. Never imagined.
- [ ] **No generic empowerment:** "Hot girl walk", "standing on business" without specific viral trace = fail
- [ ] **Value:** Post gives viewer something — a laugh, a fact, a feeling
- [ ] **FOOD POSTS NEED VIRAL TOO (v1.2):** Lifestyle photo alone is NOT enough. Every food post needs a viral hook, viral quote, or viral fact. "this is the one." = imagined = FAIL. Must have provenance.
- [ ] **DATA ACCURACY (v1.2):** Every calorie number, nutrition claim, or comparison MUST be verified from actual brand data. Never invent "760 cal for 2 bentos" without checking. Wrong data = misinformation = INSTANT REJECT
- [ ] **QUOTE-PRODUCT RELEVANCE (v1.3):** The viral quote MUST be contextually relevant to the dish shown. An aioli joke on a nasi lemak bento = semantic disconnect. If the quote has zero connection to the actual food product → FAIL even if the quote is funny on its own.
- [ ] **VISUAL STORY LOGIC (v1.3):** If the format implies a PROGRESSION (timestamp, before/after, save-for-later), the visuals must SHOW that progression. Two identical full bentos ≠ "I ate it all in 4 minutes." Need: full → empty, or full → half-eaten, or single → gone.

### DIM 10: BRAND COMPLIANCE AUDIT (!)
**Forensic checklist:**
- [ ] **Dietary compliance:** No non-vegan food visible (for vegan brands)
- [ ] **Pricing compliance:** No pricing/CTAs in organic (for brands that separate organic/ads)
- [ ] **Health claims compliance:** No medical claims (especially DotDot elderly supplement)
- [ ] **Copyright compliance:** No recognizable IP, movie stills, copyrighted characters
- [ ] **Safety compliance:** No weapons, violence, nudity, drugs, offensive gestures
- [ ] **Voice compliance:** Tone matches brand voice (girlboss for Mirra, quiet luxury for Pinxin)
- [ ] **Palette compliance:** No off-brand colors (green for Mirra, neon for Pinxin)
- [ ] **Language compliance:** Correct primary/secondary language split

### DIM 11: CROP & EDGE SAFETY AUDIT
**Forensic checklist:**
- [ ] **Edge margins:** All text 10%+ from all four edges
- [ ] **Post-crop check:** After resize, scan edges for truncated text
- [ ] **Label safety:** Labels on food photos fully visible, not truncated
- [ ] **Title safety:** Title text at top fully visible, not cut off
- [ ] **Bottom safety:** Bottom text visible above logo zone
- [ ] **Aspect ratio set:** Verified aspect_ratio was set in NANO API call (not post-crop)

### DIM 12: SEMANTIC MATCH AUDIT (!)
**Forensic checklist:**
- [ ] **Image-copy alignment:** Visual content matches text meaning
- [ ] **Food-name match:** If text says "nasi lemak", image shows nasi lemak (not pad thai)
- [ ] **Emotion match:** If text is humorous, image feels humorous (not sad/serious)
- [ ] **Narrative logic:** Multi-panel comics have consistent story progression
- [ ] **Label accuracy:** Each label/pointer points to the CORRECT item in the image

### DIM 13: PIPELINE COMPLIANCE AUDIT
**Forensic checklist:**
- [ ] **No steps skipped:** All 9 pipeline stages executed in order
- [ ] **Single NANO pass:** No multi-pass (compounds errors)
- [ ] **PIL only for resize+logo+save:** No PIL color grading, grain, warmth, filters
- [ ] **aspect_ratio set in API call:** Not relying on post-crop
- [ ] **Food enhanced before NANO:** PIL editorial enhancement applied before upload
- [ ] **Max 3 regen rounds:** Escalate to human after 3 failed attempts
- [ ] **Output saved to correct path:** `_WORK/[brand]/06_exports/`

### DIM 14: ACCESSIBILITY AUDIT
**Forensic checklist:**
- [ ] **Text contrast:** WCAG AA minimum (4.5:1 body, 3:1 large text)
- [ ] **Font size:** Readable at mobile scale (minimum 14pt equivalent)
- [ ] **Color blindness safe:** Key information not conveyed by color alone
- [ ] **Elderly accessibility:** For DotDot: min 48pt text, max 3-4 elements per image
- [ ] **Alt-text ready:** Image content describable for screen readers

---

## PART 3: COMPOUND LEARNING LOOP

### How the Skill Gets Sharper

```
USER REVIEWS POST
       │
       ▼
  YES or NO?
       │
       ├── YES → Log: post_id, all 14 dimension scores, viral source, brand
       │         → Strengthen: rules that predicted this success
       │         → Pattern: what made this work? New "always do" candidate?
       │
       └── NO  → Log: post_id, which dimension(s) failed, user's reason
                → Extract: new rule from the failure
                → Classify: universal or brand-specific?
                → Update: audit dimension checklist with new check
                → Increment: skill version
                → Save: to memory file with Why + How to Apply
```

### Memory Structure for Compound Learning

Each user decision gets logged to: `audit-learning-log.jsonl`
```json
{
  "timestamp": "2026-03-30T10:30:00Z",
  "brand": "mirra",
  "post_id": "B2-04",
  "decision": "NO",
  "dimensions_failed": ["DIM6:reference_integrity"],
  "user_reason": "not traced to specific viral post",
  "new_rule": "Every illustration must trace to a SPECIFIC viral post with proven engagement",
  "rule_scope": "universal",
  "rule_category": "reference_integrity",
  "confidence": 1.0
}
```

### Rule Crystallization

After 3+ occurrences of the same pattern:
1. Rule graduates from "observed" to "confirmed"
2. Gets added to the audit dimension's checklist permanently
3. Gets written to memory file with full context
4. Audit skill version incremented

### Self-Research Loop (Karpathy Autoresearch Pattern)

Adapted from github.com/karpathy/autoresearch — 3 primitives:

| Autoresearch Primitive | Creative Audit Equivalent |
|---|---|
| Editable asset (`train.py`) | NANO prompt template + reference selection + PIL params |
| Scalar metric (`val_bpb`) | Composite Creative Quality Score (CQS) 0-100 |
| Time-boxed cycle (5 min) | One generate-audit cycle per variant |
| `results.tsv` | `audit-learning-log.jsonl` per brand |
| `program.md` | Brand-specific memory files |

**The Loop:**
```
1. Load brand rules from memory files
2. Select references, build prompt
3. Generate variant (NANO single pass)
4. Auto-audit all 14 dimensions → composite CQS score
5. If CQS > threshold → KEEP, log success
6. If CQS < threshold → DISCARD, log failure reason + which dimensions failed
7. Analyze failure patterns → update prompt template
8. NEVER STOP. Keep improving until human interrupts or batch complete
```

**What makes it compound (3 simultaneous improvements):**
1. **Prompt templates improve** — fragments correlated with high CQS get reinforced
2. **Reference library gets curated** — high-scoring refs weighted higher for future selection
3. **Audit rules sharpen** — new checks discovered from failure patterns get added permanently

**Cross-brand transfer:** Insights from one brand's audit (e.g., "compositions with >30% negative space score higher for food photography") transfer to all brands automatically via universal rules.

**Periodically (every 10 batches or on user request):**
1. **Scan:** Review all compound learning logs for patterns
2. **Research:** WebSearch for latest creative QA practices, AI art detection, design audit tools
3. **Synthesize:** Compare external best practices against current rules
4. **Upgrade:** Add new checks discovered from research
5. **Log:** Record what was learned, version the skill

### Industry Benchmarks (from research)

**System1/IPA Compound Creativity Study** (4,000+ ads, 56 brands, 5 years):
- Most consistent brands: +27% more Very Large Brand Effects
- Creative Consistency Score (CCS) across 13 features in 3 dimensions
- Validates our compounding approach — brands that maintain territory outperform restarters

**CreativeX Creative Quality Score** (Heineken, Nestle, Mondelez):
- 10% CQS increase = 2% CPM decrease across all channels
- AI-powered models recognize guideline adherence per asset
- Real-time monitoring at scale

**Netflix Artwork Personalization:**
- Contextual bandits (not simple A/B) for online learning
- 30% CTR increase from personalized artwork
- 200+ experiments annually, insights feed back to creative team

**Kantar LINK+** (260,000 ads tested):
- Testing early in creative development increases effectiveness by up to 12%
- Validates our pre-production audit gate (Gate 0)

### Future: Automated Scoring Tools

When ready to add ML-based scoring:

| Need | Tool | Notes |
|---|---|---|
| Aesthetic score | `idealo/image-quality-assessment` (NIMA) | Pre-trained MobileNet, 2 models (aesthetic + technical), 2.2K GitHub stars |
| Multi-dim aesthetic | `rsinema/aesthetic-scorer` | 7 sub-scores: composition, lighting, color, DoF, content, quality, overall |
| Brand similarity | CLIP embeddings (`openai/clip-vit-large-patch14`) | Compare generated vs approved brand exemplars via embedding distance |
| Color compliance | `colorthief` Python | Extract dominant palette, compare against brand config allowed colors |
| Aesthetic predictor | `christophschuhmann/improved-aesthetic-predictor` | CLIP+MLP, trained on 2.37B images from LAION-5B |

These tools would add programmatic scoring layers ON TOP of the existing visual audit. The human eye remains the final gate — ML scores inform, not decide.

### World-Class Studio Practices (from research)

**Pentagram** — Strategy-to-execution traceability. Every brand decision must be provable in real-world execution. The translation test: if a brand principle can't manifest in design, it's not real.

**ManyPixels** — 100-point industrialized QA across 3 categories:
1. Customer Requirements (brief compliance, color, logo, branding)
2. Acceptance Criteria (grammar, typography, alignment)
3. Performance Criteria (deadlines, naming, folder structure)
Dedicated QC managers embedded in every project.

**Oatly/Liquid Death** — Character-driven consistency replaces rigid brand compliance. "What would the brand DO?" as the creative filter. Tests dozens of concepts cheaply on social before investing bigger. Low cost per test = high creative risk tolerance.

**ProImage-Bench** — Decomposes image correctness into 6,076 criteria and 44,131 binary checks. Iterative refinement: feeding failed checks back into editing model boosts scores from 0.653 to 0.865. This validates our re-run loop architecture.

**brand.yml** (posit-dev/brand-yml) — Machine-readable brand spec in YAML: logos, colors, fonts, typographic choices. The missing piece: automated tools can validate against a structured brand spec.

### Photography Audit Best Practices (from research)

**Set-Level Consistency** — "Top silent killer in catalogs." Compare all images as a group for: color temperature, shadow direction, margin spacing, scale, horizon, skin tones, product hue. Our Gate 6 (Batch Coherence) addresses this.

**Inspection Protocol:**
- 100% zoom on high-risk areas: hair/fur, glass, thin edges, jewelry, typography, gradients, shadows
- Bulk: 10-20 seconds per image first pass
- Hero images: 2-5 minutes per image
- Tools: histogram, eyedropper sampling, grid view comparisons

**Food Photography Specific:**
- White balance correction FIRST — everything else looks wrong if WB is off
- Hero item isolated with tack-sharp focus
- 45-degree angle light for depth
- 90-degree camera angle (parallel to surface) for flatlay
- Frequency separation for texture preservation

### Typography Audit Best Practices (from research)

**Spacing chain:** Leading (1.2-1.5× font size) → Tracking (adjust evenly before kerning) → Kerning (if spending too much time, typeface is poor quality)

**Text flow:** Widows (single word alone at bottom) and orphans (single word at top of column) = unprofessional in commercial publishing.

**Rag quality:** Good rag = small in-and-out increments. Bad rag = distracting white space shapes.

**Line length:** 40-60 characters for accessibility/readability.

### Automated Quality Scoring (IQA-PyTorch)

No-reference image quality metrics that need NO ground truth:

| Metric | Method | Speed | Best For |
|---|---|---|---|
| BRISQUE | Natural scene statistics | Very fast | General quality gate |
| NIQE | Deviation from natural images | Fast | "Does this look natural?" |
| MUSIQ | Multi-scale transformer | Medium | Arbitrary resolution |
| TOPIQ | Attention-based | Medium | Focuses on salient regions |

Install: `github.com/chaofengc/IQA-PyTorch` — GPU-accelerated, auto-downloads datasets.

### AI Artifact Detection (2026 state)

**Still reliable detection points:**
- Eyes: misaligned pupils, unnatural glossiness, empty gaze
- Perfect symmetry: real faces have minor asymmetries
- Texture uniformity: AI lacks authentic imperfection
- Spatial/semantic errors: impossible perspectives, physics violations
- Background consistency: repeated patterns, blending artifacts

**No longer reliable (major models fixed these):**
- Hands (Midjourney v6+, DALL-E 3 now correct)
- Text rendering (current models produce near-flawless typography)

---

## PART 4: BRAND DNA OVERLAY

The audit system is brand-agnostic. Brand-specific checks are loaded from brand config:

```yaml
# Brand audit overlay — loaded per brand
audit_overlay:
  color:
    allowed_bg: ["blush", "cream", "dusty rose", "peach"]
    forbidden_bg: ["green", "sage", "nature", "neon"]
    warmth_type: "candlelit, not sunlit"
  art_style:
    locked: "Korean semi-realistic (warmcorner.ai / gunelisa)"
    forbidden: ["Disney", "Pixar", "chibi", "anime"]
  food:
    sacred_library: "01_assets/photos/food-library/"
    dietary: "plant-based vegan — no meat, fish, eggs, dairy"
    enhancement: {brightness: 1.12, color: 1.08, contrast: 1.05, sharpness: 1.15}
  compliance:
    no_pricing_in_organic: true
    no_ctas_in_organic: true
    no_health_claims_in_organic: true
  voice:
    tone: "unapologetic, first-person, no exclamation marks"
    target: "women 25-32, girlboss queen energy"
  atmosphere:
    keywords: ["sparkle glamour", "warm candlelit glow"]
    poison_words: ["green", "sage", "bright and airy", "clinical"]
```

---

## SCORING & DECISION MATRIX

| Total Score | (!) Fails | Action |
|-------------|-----------|--------|
| 14/14 | 0 | Ship immediately |
| 13/14 | 0 | Ship (note minor issue for learning) |
| 12/14 | 0 | Ship only if fails are non-critical |
| 11/14 | 0 | Borderline — regenerate unless all fails are cosmetic |
| <11/14 | 0 | Regenerate. Log all failure reasons |
| Any score | 1+ (!) | Instant reject. Regenerate regardless of total |

**Critical (!) dimensions — instant reject if failed:**
- DIM 1: Typography (text garbled/unreadable)
- DIM 2: Photography (food modified/AI-generated)
- DIM 3: Color (completely off-brand palette)
- DIM 6: Reference Integrity (not traced, passthrough, copyright)
- DIM 10: Brand Compliance (dietary violation, inappropriate content)
- DIM 12: Semantic Match (image contradicts copy)

---

## VERSION LOG
- v1.0 (2026-03-30): Initial build. 9 stage gates + 14 domain dimensions + compound learning loop. Built from 200+ posts, 148 rules, 6 brands.
- v1.1 (2026-03-30): Incorporated autoresearch findings. Karpathy Loop, System1/IPA compound creativity, CreativeX CQS, Netflix contextual bandits, NIMA/CLIP aesthetic scoring tools. Cross-brand transfer mechanism.
- v1.2 (2026-03-30): Incorporated world-class studio research. Pentagram, ManyPixels, ProImage-Bench, IQA-PyTorch, brand.yml, AI artifact detection. 40+ research sources.
- v1.4 (2026-03-30): Added from food v12 user feedback: DIM 9 quote-product relevance check (aioli joke on nasi lemak = disconnect), DIM 9 visual story logic (timestamp format needs progression not 2 identical photos), DIM 2 white blowout check (film enhancement must not clip highlights), DIM 2 container variety in multi-food layouts. 4 new checks total.
- v1.3 (2026-03-30): **CRITICAL UPDATE from food v11 production.** 7/11 food posts failed user audit. 3 new failure modes discovered: (A) NANO compositing destroys sacred food when placing into lifestyle scenes — food looks PASTED/DISTORTED without real reference photos. (B) Content accuracy errors — unverified calories, imagined quotes, non-vegan food in NANO-generated quiz items. (C) Typography typos in text-heavy posts. Added: DIM 2 blend/composite/distortion checks, DIM 9 food-viral + data accuracy checks, Gate 3 compositing feasibility + content accuracy + word-by-word proofread + Mirra copy checks. KEY LEARNING: type-driven food designs (PASTA., KATSU!, GOOD STUFF., 500 CAL.) work reliably; lifestyle compositing (hands, desk, table spread) does NOT work without real reference photography.
