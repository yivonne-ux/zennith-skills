# AI Image Generation Model Guide for Professional Design Work
**Last updated: March 2026**

---

## QUICK DECISION MATRIX

| Design Task | Best Model | Runner-Up | AVOID |
|---|---|---|---|
| **Social media backgrounds/textures** | FLUX 2 Pro / Ideogram V3 | Midjourney V7 | SD (overkill setup) |
| **Typography-heavy designs** | Ideogram V3 (~95% accuracy) | GPT Image 1.5 | Midjourney (~40%), DALL-E 3 |
| **Photorealistic product shots** | FLUX 2 Max | GPT Image 1.5 | Ideogram (weak portraits) |
| **Artistic/stylized imagery** | Midjourney V7 | FLUX 2 Pro | Ideogram (utilitarian aesthetic) |
| **Photo manipulation/compositing** | FLUX 2 Kontext Max | Nano Banana Pro | Midjourney (no editing) |
| **Brand asset generation (icons, patterns)** | Recraft V3 (native SVG!) | Adobe Firefly | Any raster-only model |
| **Background removal/extension** | FLUX 2 (outpainting) | Adobe Firefly (Photoshop) | - |
| **Style transfer** | FLUX 2 Kontext / FLUX Redux | Midjourney --sref | SD + IP-Adapter |
| **Inpainting (remove/replace)** | FLUX 2 Klein / Kontext | SDXL + ControlNet | Midjourney (no inpainting) |
| **Upscaling and enhancement** | Magnific AI (creative) | Topaz Gigapixel (faithful) | Basic bicubic |
| **Vector/SVG for logos & icons** | Recraft V3 (ONLY real option) | Adobe Illustrator + Firefly | All other AI models |
| **Multi-image composition** | Nano Banana Pro (up to 14 refs) | FLUX 2 (up to 10 refs) | Single-image models |
| **Commercial-safe generation** | Adobe Firefly (indemnified) | Imagen 4 (SynthID) | SD (training data concerns) |
| **Bulk generation at scale** | Imagen 4 Fast ($0.02/img) | FLUX 2 Schnell ($0.015) | Midjourney (subscription only) |
| **Text in images (signs, labels)** | Ideogram V3 | GPT Image 1.5 | FLUX 1.x, SD, older MJ |

---

## MODEL-BY-MODEL DEEP DIVE

---

### 1. FLUX (Black Forest Labs)

**Current versions:** FLUX 2 Max / Pro / Dev / Schnell / Flex / Klein / Kontext Max
**Architecture:** 32B parameters (FLUX 2), up from 12B (FLUX 1)

#### Strengths
- **Photorealism king**: Skin texture, lighting imperfections, material physics — looks like DSLR photography
- **Unified generation + editing**: Same model does text-to-image AND instruction-based editing
- **Multi-reference**: Combine up to 10 reference images in a single generation
- **Inpainting/outpainting**: FLUX 2 Klein offers precision inpainting with clean edge fidelity on hair, fabric, glass
- **Style transfer**: FLUX Redux for image-to-image style translation; Kontext for instruction-based editing
- **Resolution**: Native 4MP output (up to 4096x4096)
- **Speed**: 30-50% faster than FLUX 1 despite 3x parameters
- **ControlNet ecosystem**: Canny, Depth, Pose conditioning all work natively

#### Text Rendering
- FLUX 2 Pro: ~60% accuracy on complex typography (first attempt)
- FLUX 2 Flex: Enhanced text rendering, best in the FLUX family for typography
- FLUX 1 Kontext: Improved over base FLUX 1 but still unreliable for dense copy
- **CRITICAL**: Multi-pass editing with Kontext degrades text — garbles after 2+ passes (confirmed in Bloom & Bare v1 rejection)

#### Editing Capabilities (Kontext)
- Instruction-based: "Change the shirt color to blue" — surgical edits
- Character consistency across edits
- Style transfer via reference image
- Inpainting without explicit masks (text instruction only)
- **Limitation**: Complex/long instructions can cause instruction-following failures
- **Limitation**: Multi-turn sessions accumulate artifacts

#### Model Variants & Pricing (API)
| Variant | Price/Image | Speed | Best For |
|---|---|---|---|
| FLUX 2 Max | ~$0.06 | Slowest | Final production renders |
| FLUX 2 Pro v1.1 | $0.055 | Medium | Hero shots, product photography |
| FLUX 2 Flex | ~$0.04 | Medium | Typography + general creative |
| FLUX 2 Dev | $0.025 | Fast | Prototyping, iteration |
| FLUX 2 Schnell | $0.015 | Fastest | Bulk generation, previews |
| FLUX 2 Klein | ~$0.02 | Fast | Inpainting, editing tasks |

#### Prompt Engineering
- Excels with photographic detail: lighting, camera angles, lens specs, material descriptions
- Specify exact composition: "shot from 45 degrees, soft window light, 85mm f/1.8"
- For editing: use surgical, specific instructions — not vague rewrites
- Single-pass edits only — never chain multiple Kontext passes

#### Known Failure Modes
1. Text garbles after multi-pass editing (CONFIRMED — Bloom & Bare v1)
2. Can hallucinate brand names from training data ("MarketplaceAtAvalonPark" incident)
3. Dense typography beyond ~60% reliability
4. Complex multi-element instructions may be partially ignored
5. Gradients work well with Kontext Max; NANO ruins gradients with grunge texture

---

### 2. Ideogram V3

**Developer:** Ideogram (founded by former Google Brain researchers)
**Release:** March 26, 2025

#### Strengths
- **Text rendering champion**: ~90-95% accuracy — industry leader by a wide margin
- **Design-oriented**: Built for posters, logos, packaging, marketing materials
- **Style reference**: Upload reference images to guide aesthetic of generations
- **Prompt alignment**: Highly faithful to complex, detailed prompts

#### Text Rendering
- 90-95% accuracy on text in images (vs ~40% Midjourney, ~60% FLUX 2 Pro)
- Handles multi-line text, different fonts, curved text, text on objects
- Best for: signs, posters, packaging, book covers, social media with text overlays
- Can render specific fonts when described (though not pixel-perfect brand fonts)

#### Weaknesses
- **Portrait work is weakest area**: Faces show unnatural skin textures, inconsistent proportions
- **Aesthetic ceiling**: More utilitarian look than Midjourney's artistic polish
- **Limited editing**: No instruction-based editing like FLUX Kontext
- **No inpainting**: Generate-only model

#### Pricing
- Free tier: usable (limited generations)
- Basic: $15/month (~300 images + 36 videos)
- Standard/Pro tiers available
- API: ~$0.03/image

#### Best Use in Production Pipeline
- Generate backgrounds/textures that include text elements
- Create poster layouts, social media templates with placeholder text
- One-time texture library generation (the "AI as texture library" pattern)
- **For Bloom & Bare specifically**: Ideal for generating background textures — confirmed in production pipeline

#### Prompt Engineering
- Be EXACT with text content: specify every word, capitalization, punctuation
- Describe text placement: "centered at the top in large bold serif font"
- Include style references: "in the style of a vintage concert poster"
- Specify colors with precision

---

### 3. Midjourney V7

**Release:** April 2025 (V7); June 2025 added video generation
**Access:** Discord bot + web interface (no public API as of March 2026)

#### Strengths
- **Aesthetic quality is unmatched**: Richness, depth, artistic coherence that competitors can't replicate
- **Style personalization**: Rate ~200 images to build a personal aesthetic profile
- **Natural imperfection modeling**: Subtle textures, softened edges, faint fingerprints on objects
- **Character consistency**: Major improvement in V7 for storytelling/branding
- **Fabric/material rendering**: "Individual threads in knits" level of detail
- **30-40% reduction in bad generations** vs V6

#### Text Rendering
- ~40% accuracy — still unreliable for production text
- Can handle simple, short text (1-3 words) reasonably well
- NOT suitable for typography-heavy designs

#### Weaknesses
- **No API access**: Discord/web only — cannot integrate into automated pipelines
- **No editing/inpainting**: Generate-only
- **No img2img composition**: Cannot use reference images for precise control
- **Subscription-only pricing**: No per-image API pricing
- **"Midjourney look"**: Everything tends toward a polished, painterly aesthetic — hard to get raw/unprocessed looks

#### Pricing
| Plan | Price | Fast GPU | Notes |
|---|---|---|---|
| Basic | $10/mo | ~200 min | |
| Standard | $30/mo | 15 hrs | Unlimited Relax mode |
| Pro | $60/mo | 30 hrs | Stealth Mode, HD video |
| Mega | $120/mo | 60 hrs | All features |

#### Prompt Engineering
- Responds to artistic direction and mood: "ethereal", "moody", "warm afternoon light"
- Style references via --sref parameter for consistency
- Less effective with technical specs (camera settings, exact dimensions)
- V7 personalization feature learns your taste over time

#### Best Use in Production Pipeline
- Concept exploration and mood boards
- Artistic/stylized imagery where photorealism isn't needed
- Character concept art
- NOT for automated production pipelines (no API)

---

### 4. GPT Image 1.5 (OpenAI — replaces DALL-E 3)

**Status:** DALL-E 3 deprecated May 12, 2026. GPT Image 1.5 is the replacement.
**Architecture:** Native multimodal — image generation happens inside the same LLM that processes text

#### Strengths
- **#1 on LMArena leaderboard** (Elo 1277, statistical tie with FLUX 2 Pro at 1265)
- **Near-perfect text rendering**: Massive improvement over DALL-E 3's garbled text
- **Instruction understanding**: Benefits from GPT's language comprehension
- **Editing capabilities**: Can modify existing images based on text instructions
- **4x faster** than predecessor
- **Integrated into ChatGPT**: Accessible to non-technical users

#### Weaknesses
- **Less photorealistic than FLUX 2** for product photography
- **Less artistic than Midjourney** for stylized content
- **OpenAI ecosystem lock-in**: Must use OpenAI API
- **Safety filters**: Aggressive content filtering can block legitimate creative work

#### Pricing
- GPT Image 1.5: $0.04/image (standard)
- GPT Image 1 Mini: $0.005/image (budget option)
- Batch API: 50% discount on bulk runs

#### Best Use in Production Pipeline
- Text-heavy designs where Ideogram isn't available
- Quick iteration via ChatGPT interface
- Editing tasks with strong language understanding
- Budget bulk generation via Mini variant

---

### 5. Recraft V3

**Unique value:** ONLY AI model that generates true vector SVG files
**Recognition:** #1 on Hugging Face Text-to-Image Leaderboard (Elo 1172, 72% win rate — pre-GPT Image 1.5)

#### Strengths
- **Native SVG output**: Mathematical vector objects, not pixel clusters — infinitely scalable
- **Logo generation**: Text-to-logo with proper vector paths
- **Icon generation**: Clean, production-ready icon sets
- **Brand consistency tools**: Upload brand assets, define hex colors, palette enforcement
- **Color control**: Precise hex code specification, eyedropper from reference images
- **Illustration styles**: Flat, line art, 3D, isometric — all in vector

#### Text Rendering
- Strong for logos and short text in designs
- Vector text paths are clean and editable in Illustrator

#### Weaknesses
- **Not for photography**: Raster photorealism is not the focus
- **Limited editing**: No inpainting/outpainting
- **Simpler compositions**: Less capable with complex multi-element scenes

#### Pricing
- Free tier available
- Pro plans for higher volume
- API available via Replicate and WaveSpeedAI

#### Best Use in Production Pipeline
- Logo concepts and iterations (then hand-refine in Illustrator)
- Icon sets for apps, websites, brand assets
- Seamless pattern/texture generation (vector, infinitely tileable)
- Brand illustration libraries
- **Saves 2-4 hours** of manual vectorization per project
- Clients include: Amazon, NVIDIA, Salesforce, Uber, Netflix, Ogilvy

---

### 6. Nano Banana Pro (fal.ai — Google Gemini 3 Pro Image)

**Platform:** fal.ai
**Architecture:** Based on Google's Gemini 3 Pro Image model

#### Strengths
- **Multi-image composition champion**: Up to 14 reference images in a single prompt
- **Role-based image assignment**: Face ref, pose guide, background, style template, lighting ref
- **Identity consistency**: Maintains identity for up to 5 different people simultaneously
- **Text rendering**: Advanced text rendering capability
- **Editing**: Natural language image editing without masks
- **4 variations**: Generates 4 options simultaneously

#### Multi-Image Capabilities (Critical for Production)
- Slots 1-6: High-fidelity processing, maximum influence on output
- Slots 7-14: Still contribute but with reduced precision
- Role assignment: `[wireframe, treated_food, logo_ref]` — each image serves a specific function
- **For Mirra workflow**: Pipeline B uses Nano for multi-image `[wireframe, treated_food(s)]`

#### Weaknesses
- **Gradient handling**: Can ruin gradients with grunge texture (confirmed in Mirra workflow)
- **5+ image compositions**: May need text_fix_prompt pass for exact text
- **Less photorealistic** than FLUX 2 for pure generation
- **Dependent on fal.ai platform**: No self-hosting option

#### Pricing
- $0.15 per edit (maskless editing)
- Generation pricing via fal.ai API

#### Prompt Engineering (Locked Patterns from Mirra)
- Pipeline B: SCALE LOCK → PART 1 anchor food ("Image 2 IS the food in [zone]. Do not generate AI food.") → PART 2 build around it
- Canvas safety: "All card text FULLY VISIBLE, nothing truncated at [edge]"
- Watermark erase: "Scan every corner and erase..."

---

### 7. Stable Diffusion XL / SD3

**Status:** Open-source ecosystem, self-hostable
**Architecture:** SDXL (base + refiner), SD3 (newer architecture)

#### Strengths
- **Maximum control**: ControlNet, LoRA training, custom checkpoints
- **Self-hosted**: No API costs, no content filters, full privacy
- **ControlNet ecosystem**: Canny, Depth, Pose, Tile, IP-Adapter — precise spatial guidance
- **Inpainting**: Surgical precision with mask support (external masks from Photoshop/GIMP)
- **Img2img**: Full control over denoising strength, conditioning
- **LoRA training**: Train custom styles/characters on your own data
- **Community models**: Thousands of fine-tuned checkpoints for specific aesthetics

#### Weaknesses
- **Setup complexity**: Requires technical knowledge, GPU hardware
- **Quality ceiling lower** than FLUX 2 / Midjourney V7 for out-of-box generation
- **Text rendering**: Poor without specialized techniques
- **Slower iteration** than API-based models for non-technical users
- **Hardware requirements**: SDXL needs 8GB+ VRAM; SD3 needs 12GB+

#### Pricing
- Free (self-hosted) + hardware costs
- Via API: Various providers (Replicate, fal.ai, etc.) at competitive rates

#### Best Use in Production Pipeline
- When you need maximum control over every aspect of generation
- Custom model training for brand-specific aesthetics
- Complex ControlNet workflows (pose + depth + style simultaneously)
- Self-hosted batch processing at scale (zero per-image cost)
- Inpainting with precise mask control
- NOT recommended for teams without ML engineering support

---

### 8. Adobe Firefly

**Status:** Integrated into Photoshop, Illustrator, Premiere Pro
**Commercial safety:** Trained exclusively on Adobe Stock, openly licensed, and public domain content

#### Strengths
- **Commercial indemnification**: Adobe assumes legal responsibility for IP challenges
- **Deep tool integration**: Generative Fill in Photoshop, Text to Vector in Illustrator
- **Firefly Foundry** (Oct 2025): Train custom models on your brand's IP catalog
- **Multi-model access**: Subscription includes Nano Banana Pro, FLUX 2, Runway video, ElevenLabs audio
- **Brand safety**: No risk of generating content derived from copyrighted training data
- **Design workflow native**: No context-switching — edit directly in Creative Suite

#### Weaknesses
- **Quality ceiling**: Below FLUX 2 / Midjourney for pure generation quality
- **Speed**: Slower than purpose-built API models
- **Subscription dependency**: Requires Adobe Creative Cloud
- **Less flexible**: Cannot fine-tune or customize underlying models (except Foundry for enterprise)

#### Pricing
- Included with Creative Cloud subscriptions
- Firefly standalone: ~$10/month (includes Runway video)
- Foundry: Enterprise pricing

#### Best Use in Production Pipeline
- Generative Fill for quick compositing in Photoshop
- Generative Expand for canvas extension
- Text to Vector in Illustrator for quick vector concepts
- When commercial safety / IP indemnification is required
- Enterprise brand consistency via Foundry custom models

---

### 9. Leonardo AI

**Key feature:** Custom model training + AI Canvas workspace

#### Strengths
- **Custom training**: Upload your images to train a private model matching your aesthetic
- **Elements feature**: Train on faces, styles, or objects for visual consistency
- **AI Canvas**: Infinite workspace for inpainting + outpainting
- **Character reference**: Maintains facial features across different poses
- **Community models**: Large library of fine-tuned models
- **Multi-model backend**: Uses Phoenix 1 + FLUX Kontext internally

#### Weaknesses
- **Jack of all trades**: Doesn't lead in any single category
- **Quality dependent on model choice**: Results vary significantly between base models
- **Platform-dependent**: Web interface primarily

#### Best Use in Production Pipeline
- Teams needing consistent character generation
- Rapid iteration with built-in editing tools
- When you want a unified platform (generate + edit + upscale)
- Good for designers who prefer GUI over API

---

### 10. Playground V3

**Architecture:** Integrates Llama3-8B LLM throughout the generation process

#### Strengths
- **Prompt understanding**: Handles longer, more detailed prompts than any other model
- **Precise color control**: Specify exact RGB values in prompts, faithfully applied
- **Typography**: 82% text-synthesis score — outperforms most models
- **Design principle understanding**: Understands composition, layout, cultural references
- **Img2img**: Auto-infers prompts from uploaded reference images

#### Weaknesses
- **Smaller ecosystem**: Less community support than FLUX or SD
- **Less photorealistic** than FLUX 2 for product shots
- **Limited editing tools**: No Kontext-style instruction editing

#### Best Use in Production Pipeline
- Design-first generation where color precision matters
- Layouts and compositions with specific design requirements
- When you need extreme prompt faithfulness

---

### 11. Google Imagen 4

**Variants:** Fast / Standard / Ultra
**Safety:** SynthID watermarking on all outputs

#### Strengths
- **Three-tier pricing**: Fast ($0.02), Standard ($0.04), Ultra ($0.06)
- **2K resolution output**: Both Imagen 4 and Ultra
- **Fine detail**: Intricate fabrics, water droplets, animal fur
- **Fast variant**: ~2.7 second latency — excellent for bulk/preview
- **Both photorealistic and abstract styles**

#### Weaknesses
- **Google Cloud ecosystem**: Vertex AI / Gemini API dependency
- **Less community tooling** than FLUX or SD ecosystem
- **Safety filters**: Can be restrictive for some creative use cases

#### Best Use in Production Pipeline
- High-volume generation at low cost (Fast variant)
- When SynthID watermarking is a requirement
- Google Cloud-native workflows

---

## DESIGN USE CASE PLAYBOOK

### Social Media Post Backgrounds/Textures
**Best approach:** "AI as texture library" pattern
1. Generate a library of 50-100 background textures using Ideogram V3 or FLUX 2 Pro
2. Store as reusable assets — regenerate rarely
3. Composite text, logos, mascots via Python/Pillow (never AI-generated)
4. Apply brand color correction in post-processing

**Why this works:** AI generates textures once, deterministic code handles everything that must be pixel-perfect (text, logos, layout). This is the Bloom & Bare locked pipeline.

### Typography-Heavy Designs (Posters, Ads)
**Best approach:** Hybrid — AI for visual elements, code for text
1. Use Ideogram V3 to generate the visual/illustrative portion
2. OR use FLUX 2 for photorealistic backgrounds
3. Overlay all text programmatically (Python/Pillow, Figma, Photoshop)
4. Never trust AI to render your exact brand fonts

**Alternative:** If text MUST be in the AI-generated image, Ideogram V3 is the only viable option (~95% accuracy). Always OCR-validate output.

### Photo Manipulation / Compositing
**Best approach:** FLUX 2 Kontext Max or Nano Banana Pro
1. FLUX Kontext: Single instruction-based edits (color change, element swap, style transfer)
2. Nano Banana Pro: Multi-image composition (combine food photo + wireframe + style ref)
3. **Rule:** Single-pass only. Never chain AI editing passes.
4. Post-process: color correction → compositing → grain (always last)

### Brand Asset Generation (Icons, Patterns, Illustrations)
**Best approach:** Recraft V3 for vectors, Midjourney for concepts
1. Recraft V3: Generate SVG icons, patterns, illustrations with brand color palette
2. Midjourney: Concept exploration and mood boarding
3. Hand-refine finals in Illustrator/Figma
4. **Never use AI-generated logos as final brand marks** (not copyrightable, not unique enough)

### Background Removal / Extension
**Best approach:** Dedicated tools + FLUX 2
1. Background removal: rembg (Python library), Adobe Photoshop (AI-powered), remove.bg
2. Background extension (outpainting): FLUX 2 Kontext or Adobe Generative Expand
3. For product photography extension: Claid.ai or FLUX 2

### Style Transfer (Applying Brand Visual Style)
**Best approach:** FLUX 2 Kontext + Redux
1. FLUX Redux: Image-to-image style translation
2. FLUX Kontext: "Apply the style of [reference image] to this image"
3. Midjourney --sref: Style reference parameter for consistent aesthetic
4. Leonardo Elements: Train on brand style for repeatable results

### Inpainting (Removing/Replacing Elements)
**Best approach:** FLUX 2 Klein or SDXL + ControlNet
1. FLUX 2 Klein: Unified inpainting — mask-aware, color-harmonized
2. SDXL: When you need pixel-level mask control (import from Photoshop)
3. Adobe Generative Fill: Quick fixes within Photoshop workflow
4. Nano Banana Pro: Maskless editing via text instruction

### Upscaling and Enhancement
| Need | Tool | Notes |
|---|---|---|
| Faithful enlargement (print) | Topaz Gigapixel / LetsEnhance | Preserves original detail |
| Creative upscaling (add detail) | Magnific AI | Invents plausible detail |
| Free/open-source | Upscayl (Real-ESRGAN) | Cross-platform, local |
| Batch processing | ON1 Resize AI | Up to 10x enlargement |

### Vector/SVG Generation
**Only real option:** Recraft V3
- All other AI models output raster images only
- Recraft V3 outputs native SVG with clean mathematical paths
- For logos: Use as starting point, refine in Illustrator
- For icons: Often production-ready from Recraft directly

---

## WHEN NOT TO USE AI (HARD RULES)

1. **Final brand logos**: Not copyrightable, not unique, can't be trademarked. AI for brainstorming only.
2. **Exact brand typography**: AI cannot render your specific font files. Always composite programmatically.
3. **Brand mascots/characters** that must be pixel-perfect: Always composite real PNGs (Bloom & Bare rule).
4. **Dense text copy**: Even Ideogram fails ~5-10% of the time. Any text that must be 100% correct should be rendered by code.
5. **Multi-pass AI editing**: Each pass compounds errors. Single-pass maximum, then deterministic post-processing.
6. **Legal/regulated content**: Unless using Adobe Firefly (indemnified), IP risk exists.

---

## PRODUCTION PIPELINE ARCHITECTURE (PROVEN)

### The "AI as Texture Library" Pattern (Bloom & Bare)
```
STEP 1: AI generates background textures (one-time, reusable library)
         → Ideogram V3 or FLUX 2 Pro
         → Store in assets/textures/

STEP 2: Python renders EVERYTHING else deterministically
         → Text (exact fonts: DX Lactos, Mabry Pro)
         → Layout (precise positioning)
         → Logos (composite real PNGs)
         → Mascots (composite real PNGs)
         → Badges, pills, decorative elements

STEP 3: Post-processing (always this order)
         → Light grain (0.014-0.018)
         → Color correction if needed
         → Export final PNG
```

### The "AI for Iteration, Human for Refinement" Pattern
```
STEP 1: AI generates multiple concepts/variations
         → Midjourney for artistic exploration
         → FLUX 2 for photorealistic options
         → Ideogram for text-integrated designs

STEP 2: Human selects best direction

STEP 3: Deterministic refinement
         → Exact brand colors applied
         → Typography replaced with brand fonts
         → Logo/mascot composited from real assets
         → Layout adjusted to exact specs

STEP 4: Post-processing pipeline
         → AI generation → color correction → compositing → grain → final
```

### The Multi-Model Chain (Mirra workflow)
```
Pipeline A (text/surface swap, no food):
  NANO or FLUX → single pass → fit_45 → mirra_filter → stamp_logo → grain

Pipeline B (food as input):
  Treat food photo → NANO multi-image [wireframe + food] → fit_45 → filter → logo → grain

Pipeline B_two_pass:
  Treat food → FLUX surface → NANO multi-image [FLUX result + foods] → post-process

Pipeline C (food as background):
  NANO multi-image [wireframe + treated_bg] → post-process
```

---

## COST OPTIMIZATION GUIDE

### Per-Image API Pricing (March 2026)
| Model | Price | Quality Tier |
|---|---|---|
| GPT Image 1 Mini | $0.005 | Budget preview |
| FLUX 2 Schnell | $0.015 | Fast iteration |
| Imagen 4 Fast | $0.02 | Quick + decent |
| FLUX 2 Dev | $0.025 | Open-weight prototyping |
| Ideogram V3 | $0.03 | Best text rendering |
| Imagen 4 Standard | $0.04 | Balanced |
| GPT Image 1.5 | $0.04 | Top-tier general |
| FLUX 2 Flex | ~$0.04 | Typography focus |
| FLUX 2 Pro v1.1 | $0.055 | Hero production shots |
| FLUX 2 Max | ~$0.06 | Maximum quality |
| Imagen 4 Ultra | $0.06 | Maximum detail |

### Cost-Saving Strategies
1. **Batch APIs**: OpenAI and Google offer 50% discount on bulk runs (5,000 images = $100-135)
2. **Tiered approach**: Schnell/Fast for previews → Pro/Standard for finals
3. **Texture library pattern**: Generate once, reuse forever — amortizes AI cost to near-zero
4. **Self-hosted SD**: Zero per-image cost after hardware investment
5. **Midjourney Relax mode**: Unlimited generations on Standard+ plans (slower queue)

---

## LEADERBOARD RANKINGS (March 2026)

### LMArena Text-to-Image Elo
1. GPT Image 1.5 — 1277
2. FLUX 2 Pro v1.1 — 1265 (within margin of error of #1)
3. Imagen 4 Ultra — (top tier)
4. Recraft V3 — 1172 (Hugging Face benchmark)
5. FLUX 1.1 Pro — 1143
6. Midjourney V6.1 — 1093
7. DALL-E 3 HD — 984 (deprecated)

### Text Rendering Accuracy
1. Ideogram V3 — ~95%
2. GPT Image 1.5 — ~90%+
3. Playground V3 — 82%
4. FLUX 2 Flex — ~70%+
5. FLUX 2 Pro — ~60%
6. Midjourney V7 — ~40%
7. DALL-E 3 — Frequent errors (deprecated)
8. SD/SDXL — Poor without specialized training

---

## FILTER / POST-PROCESSING BY CONTENT TYPE (From Mirra Learnings)

These rules are battle-tested and transferable to any brand:

| Content Type | Filter Approach | Grain | Sparkle/Effects |
|---|---|---|---|
| Real photography | Full pipeline (S-curve + shadow + warm + clarity + vignette) | 0.030 | Heavy (22-45) |
| Film/animation stills | Gentle S-curve, light touch | 0.022-0.032 | Light (8-14) |
| UI/interface screenshots | Light touch only (8.6% overlay, 6% desat, NO sparkle) | 0.014 | None |
| Props/graphic text | Even lighter than UI | 0.014 | None |
| Typographic quotes | Shadow-protected (lighter S-curve) | 0.022 | Minimal (3-5) |

**Universal rule:** Grain is ALWAYS the last step in post-processing. Never apply grain before compositing or color correction.

---

## KEY TAKEAWAYS FOR BLOOM & BARE

1. **Current pipeline is correct**: Python renders all text/logos/mascots, AI only for background textures
2. **Ideogram V3** remains the best choice for texture generation (text-safe, design-oriented)
3. **Never use FLUX for text-heavy passes** — confirmed failure mode
4. **Never multi-pass AI editing** — compounds errors exponentially
5. **Recraft V3** could be valuable for generating vector decorative elements (blobs, swooshes) as SVG
6. **FLUX 2 Kontext** could be useful for one-shot style transfer on photography if needed
7. **Cost is near-zero** with the texture library pattern — generate once, reuse across 221+ posts
