# HYBRID AI VIDEO PRODUCTION — Complete Technical Mastery Guide

> Deep research compiled March 2026. Covers hybrid pipelines, ComfyUI workflows, character consistency, prompt engineering systems, and scaled production.

---

## TABLE OF CONTENTS

1. [The Hybrid Pipeline (Real Footage + AI)](#topic-1-the-hybrid-pipeline)
2. [ComfyUI Node-Based Workflows for Video](#topic-2-comfyui-node-based-workflows)
3. [Character/Brand Consistency Techniques](#topic-3-characterbrand-consistency)
4. [Advanced Prompting Systems](#topic-4-advanced-prompting-systems)
5. [Production Pipeline at Scale](#topic-5-production-pipeline-at-scale)
6. [Model Comparison & Pricing Matrix](#appendix-a-model-comparison)
7. [Negative Prompt Master List](#appendix-b-negative-prompt-master-list)
8. [Prompt Library Templates](#appendix-c-prompt-library-templates)

---

## TOPIC 1: THE HYBRID PIPELINE

### 1.1 What "Hybrid" Means in 2026

Hybrid video production = real camera footage combined with AI-generated elements, composited and graded to look seamless. This is now the professional standard — pure AI generation is used for concepting, but delivery-grade brand videos use real footage as the foundation.

**The ratio in top-performing brand videos (2026):**
- 60-80% real footage (hero shots, product, human talent, environments)
- 20-40% AI-generated (background extensions, VFX elements, transitions, mood layers, impossible camera moves)

### 1.2 The Exact Workflow: Shoot to Deliver

```
PHASE 1: PRE-PRODUCTION
├── Script/storyboard with AI enhancement zones marked
├── Shot list: mark each shot as REAL / AI / HYBRID
├── Shoot "clean plates" for AI enhancement zones
└── Prepare reference images for AI consistency

PHASE 2: SHOOT (optimized for AI enhancement)
├── Camera: shoot 4K minimum (AI upscaling = last resort)
├── Bitrate: ≥50 Mbps for 1080p, ≥100 Mbps for 4K
├── Codec: H.265 or ProRes (preserve detail for AI processing)
├── Lighting: soft, even, WDR mode for mixed environments
├── Clean plates: locked-off tripod, no talent, for every AI-enhancement shot
├── Reference frames: capture environment lighting/color for AI matching
└── Markers: practical tracking markers if compositing AI elements

PHASE 3: AI PROCESSING
├── Denoise → Deblur → Color-correct → Stabilize → Upscale (sequential)
├── Generate AI elements using preprocessed reference frames
├── Match AI output to real footage (color, grain, motion blur)
└── Single-pass AI maximum (multi-pass compounds errors)

PHASE 4: COMPOSITE
├── Layer real footage + AI elements in DaVinci Resolve / After Effects
├── Color match using AI tools (Colourlab AI, DaVinci Neural Engine)
├── Add grain/texture to AI elements to match camera noise profile
├── Motion blur matching on AI elements
└── Edge refinement on composite boundaries

PHASE 5: GRADE & DELIVER
├── Unified color grade across all sources
├── Final grain pass (unifies the look)
├── QC review: check for AI artifacts, consistency breaks
└── Export per platform specs
```

### 1.3 The "Clean Plate + AI" Technique

The fundamental hybrid technique:

1. **Shoot the clean plate**: Lock camera on tripod. Record empty scene (no talent, no action) for 5-10 seconds. This gives AI a "canvas."
2. **Shoot the action plate**: Same camera position, talent performs action.
3. **AI generates elements on clean plate**: Background extensions, VFX, environmental effects.
4. **Composite action plate over AI-enhanced plate**: Using masks, rotoscoping, or AI matting.

**Camera settings for clean plates:**
- Tripod locked (zero movement)
- Manual exposure (no auto-adjustments between plates)
- Manual white balance
- Same focal length and aperture as action plate
- Shoot 10s minimum (gives temporal data for AI)

### 1.4 Shooting Footage SPECIFICALLY for AI Enhancement

**What to do:**
- Shoot at highest bitrate your workflow supports (bitrate > resolution for AI quality)
- Use soft, even lighting — AI handles clean data better than noisy data
- Leave negative space where AI elements will go
- Capture reference frames of lighting environment (chrome ball, gray card)
- Shoot at 24fps or 30fps (AI models trained primarily on these framerates)
- Record at least 2 stops overexposed for AI color work (preserve highlights)

**What to avoid:**
- Heavy in-camera LUTs (bake nothing; shoot flat/log profiles)
- Extreme compression (H.264 at low bitrate destroys AI enhancement potential)
- Shaky handheld in zones meant for AI compositing
- Mixed color temperature lighting (confuses AI color matching)
- Lens flares/bokeh in AI enhancement zones (AI cannot replicate these accurately)

### 1.5 Matching AI Elements to Real Footage

**Color matching:**
- DaVinci Resolve AI Neural Engine: auto-matches color grades between clips using ML
- Colourlab AI (OFX plugin for Resolve): auto-balance + AI color matching across scenes
- Manual: sample RGB values from real footage, apply as color overlay on AI elements

**Grain matching:**
- Sample noise profile from real footage (use Resolve's noise analysis)
- Apply matched grain to AI elements (AI output is typically too clean)
- Rule: grain amount on AI elements should be 110% of real footage grain (slightly more to compensate for the "too perfect" look)

**Motion matching:**
- Add motion blur to AI elements matching camera shutter angle (180-degree = standard)
- Match camera shake frequency if handheld
- AI elements should respect the same depth of field as real footage

**Lighting matching:**
- Beeble SwitchLight 3.0: reverse-engineers 2D footage into PBR render passes (normals, albedo, depth, specular, roughness, alpha). Processes multiple frames simultaneously for temporal stability. Integrates directly into Blender, Unreal Engine, Nuke.
- Used on Superman & Lois production for VFX relighting
- Runs locally on GPU (4K capable), no cloud dependency

### 1.6 Professional Hybrid Workflow Case Studies

**Production approach (CineD documented):**
1. Professional shoot with high-res cameras (Sony a7R V, Sony a1 II)
2. Create assets from real photographs
3. Animate and post-process in After Effects
4. Combine generated clips with live-action in post
5. Upscale AI generations to 4K
6. Final edit in DaVinci Resolve

**Runway Aleph approach:**
- Starts with filmed footage (not text prompts)
- AI edits real footage: camera angle changes, object removal, relighting
- Targeted at professional filmmakers who want AI as a tool, not a replacement

**GenVFX Pipeline (Groove Jones):**
- AI generates VFX elements (particles, environments, extensions)
- Composited with real footage plates
- ML-powered match-moving and tracking

---

## TOPIC 2: COMFYUI NODE-BASED WORKFLOWS FOR VIDEO

### 2.1 Why ComfyUI for Video Production

**ComfyUI vs alternatives (2026 verdict):**

| Feature | ComfyUI | A1111 | Forge | InvokeAI |
|---------|---------|-------|-------|----------|
| Video workflows | Best-in-class | Limited | Limited | Basic |
| Speed | 2x faster than A1111 | Baseline | 30-75% faster than A1111 | Similar to A1111 |
| Node-based control | Full | None (form UI) | None (form UI) | Partial |
| API integrations | Kling, Sora, Luma, Pika | None native | None native | None native |
| VRAM efficiency | Excellent | Good | Best | Good |
| Video model support | WAN 2.2, HunyuanVideo, AnimateDiff, LTX | AnimateDiff only | AnimateDiff only | Basic |
| Learning curve | Steep | Gentle | Gentle | Moderate |
| Production automation | Full (JSON workflows) | Limited | Limited | Moderate |

**Verdict:** ComfyUI is the only serious option for video production pipelines. Use Forge for quick single-image tests.

### 2.2 AnimateDiff + IP-Adapter Workflow

**Required models:**
- SD 1.5 checkpoint (base model)
- SD 1.5 VAE
- `v3_sd15_mm.ckpt` → `models/animatediff_models/`
- `ip-adapter_sd15.safetensors` → `models/ipadapter/`
- `clip-vit-h-b79k` → `models/clip_vision/`

**Core node chain:**
```
LoadCheckpoint → KSampler → VAE Decode → Video Combine
       ↑              ↑
AnimateDiff Loader   IP-Adapter
       ↑              ↑
Motion Model      Reference Image
```

**AnimateDiff Evolved key parameters:**

| Parameter | Default | Recommended | Notes |
|-----------|---------|-------------|-------|
| context_length | 16 | 16 | Frames per AnimateDiff run. Sweet spot = 16 |
| context_stride | 1 | 1 | Step size between windows. Lower = smoother, higher = faster |
| context_overlap | 4 | 4-6 | Overlap frames between runs. Higher = smoother transitions |
| closed_loop | false | true (for loops) | Connects last frame to first |

**Uniform Context Options node:** Required for videos longer than ~24 frames. Sets up sliding window approach — AnimateDiff processes frames 1-16, then 12-28 (with 4-frame overlap), etc.

**IP-Adapter settings for style/face transfer:**
- `weight`: 0.6-0.8 for style transfer, 0.8-1.0 for face consistency
- `noise`: 0.0-0.3 (lower = closer to reference, higher = more creative)
- Critical: weight and noise are the two most impactful parameters

### 2.3 AnimateDiff + ControlNet + IP-Adapter (Video-to-Video)

**Full pipeline for converting real video to styled animation:**

```
Source Video → Frame Extraction
                    ↓
         ControlNet Preprocessors
         ├── LineArt (style edges)
         ├── OpenPose (body/hand pose)
         ├── Depth (spatial relationships)
         └── Canny (hard edges)
                    ↓
         AnimateDiff + IP-Adapter + ControlNet
                    ↓
         Frame Assembly → Video Export
```

**ControlNet preprocessor nodes (ComfyUI-Art-Venture):**
- `AV_ControlNetPreprocessor` — unified node, auto-selects preprocessing
- Individual: `CannyEdgePreprocessor`, `LineArtPreprocessor`, `OpenposePreprocessor`, `MidasDepthPreprocessor`
- Apply BEFORE generation, not after

### 2.4 WAN 2.1/2.2 Video Generation (Native ComfyUI)

ComfyUI natively supports WAN 2.1/2.2. Access via: Workflows → Workflow Templates.

**WAN 2.1 Stand In LoRA — Character-Consistent Video:**

Complete node workflow (node IDs from reference):
```
1. LoadImage (#58) → ImageResizeKJv2 (#142) — load & standardize reference
2. MediaPipe-FaceMeshPreprocessor (#144) + BinaryPreprocessor (#151) — face mask
3. TransparentBGSession+ (#127) + ImageRemoveBackground+ (#128) — remove background
4. ImageCompositeMasked (#108) — composite subject on clean canvas (prevents color bleeding)
5. ImagePadKJ (#129) + ImageResizeKJv2 (#68) — align aspect ratio
6. WanVideoEncode (#104) — encode to latent
7. WanVideoModelLoader (#22) — loads WAN 2.1 14B base + Stand In LoRA
8. WanVideoEmptyEmbeds (#177) — establishes target shape for image embeddings
9. WanVideoAddStandInLatent (#102) — injects encoded reference latent (identity through time)
10. KSampler → VAE Decode → Video Export
```

**Key insight:** Stand In LoRA is a CVPR 2026 paper — lightweight, plug-and-play identity-preserving framework. Bakes identity into the model at load time.

### 2.5 ComfyUI + External APIs (Kling, Sora, Luma)

**Kling API in ComfyUI:**
- Custom node: `ComfyUI-KLingAI-API` (GitHub: KlingAIResearch)
- Use ComfyUI for preprocessing (ControlNet, face detection, compositing)
- Send processed frames to Kling API for video generation
- Receive results back in ComfyUI for post-processing

**Sora 2 in ComfyUI:**
- Node: "OpenAI Sora - Video" (available in nightly builds)
- V3 schema integration for ControlNet + Sora pipeline
- Preprocessing in ComfyUI → generation via Sora API → post-processing in ComfyUI

**Luma/Pika:**
- Similar API integration nodes available
- All follow same pattern: preprocess locally → generate via API → post-process locally

### 2.6 FreeU Integration

FreeU node improves generation quality with zero additional compute:
- Plugs between UNet and sampler
- Reduces artifacts, improves detail
- Parameters: `b1=1.1, b2=1.2, s1=0.9, s2=0.2` (SD 1.5 defaults)

---

## TOPIC 3: CHARACTER/BRAND CONSISTENCY TECHNIQUES

### 3.1 The 2026 Consistency Stack (Ranked)

| Rank | Technique | Face Similarity | Speed | VRAM | Nodes | Best For |
|------|-----------|----------------|-------|------|-------|----------|
| 1 | **LoRA + PuLID + ControlNet** | 95-98% | Slow | 12GB+ | 10-15 | Production (best quality) |
| 2 | **InstantID** | 82-86% | Medium | 8GB+ | 6-8 | Fast iteration |
| 3 | **ACE Plus + Redux** | 99% (img2img only) | Medium | 10GB+ | 8-12 | Portrait/background swaps |
| 4 | **IP-Adapter FaceID** | 75-80% | Fast (6-10s) | 6GB | 3-4 | Beginners, quick tests |
| 5 | **PuLID standalone** | 80-85% | Slow | 12GB+ | 8-12 | High fidelity + aesthetics |
| 6 | **Hyper LoRA** | 85-90% (front) | Medium | 8GB+ | 6-8 | Text-to-image flexibility |
| 7 | **WAN Stand In LoRA** | 90%+ (video) | Slow | 16GB+ | 10+ | Video identity lock |

### 3.2 The Professional Production Stack (Recommended)

For short-form ad production, use this combination:
```
Low-Strength LoRA (0.6) → general body shape
     +
PuLID Adapter (0.8) → lock facial features
     +
ControlNet OpenPose → force posture/pose
     =
Identical character every frame
```

This is what studios use for AI movies where the character looks identical in every frame.

### 3.3 IP-Adapter Face Consistency

**How it works:** Uses CLIP vision encoder to extract features from reference image, injects them into the diffusion process via cross-attention.

**Key parameters:**
- `weight`: 0.8-1.0 for face lock (lower = more prompt flexibility)
- `noise`: 0.0-0.1 for consistency (higher adds variation)
- `weight_type`: "linear" for faces, "ease in" for style transfer

**Limitations:**
- Cannot guarantee 100% consistency across extreme angle changes
- Struggles with occluded faces
- Best with front-facing or 3/4 view references

### 3.4 InstantID Deep Dive

**Architecture:** Built on InsightFace for face analysis + ControlNet for spatial control.

**Performance:** 82-86% facial recognition similarity. Best overall balance of quality, speed, and consistency.

**Key settings:**
- `ip_adapter_scale`: 0.75 (allows clothing/context to show while maintaining identity)
- Higher values lock face harder but reduce prompt flexibility
- Works with SDXL models

**Workflow (6-8 nodes):**
```
Reference Image → InsightFace Analysis → InstantID Adapter
                                              ↓
Prompt → SDXL Checkpoint → KSampler → VAE Decode → Output
                              ↑
                    ControlNet (optional pose control)
```

### 3.5 ACE Plus (Alibaba)

**Unique strength:** Uses Flux Fill model to reconstruct occluded objects during face swap — handles flowers, accessories, hair covering face.

**Best for:** Image-to-image swaps (not text-to-image).

**With Redux style anchoring:** Achieves 99% face consistency in portrait background swaps.

**Limitation:** Lighting/blending can be off — skin tones sometimes too pale/cold vs. InstantID's natural blending.

### 3.6 LoRA Training for Character Consistency

**Dataset requirements:**
- **Quantity:** 20-30 images (sweet spot: 23-28 for faces)
- **Fewer than 20:** insufficient angle coverage
- **More than 30:** confuses model with too much variation
- **Must include:** front face, 3/4 view, profile, looking up/down, different expressions, full body, upper body, close-up, different poses, lighting, backgrounds

**Training configuration (Kohya-ss, FLUX 2 Pro):**
```yaml
network_dim: 32          # Character LoRA default (8-16 too low, 64 overfits)
network_alpha: 16         # Half of network_dim
learning_rate: 1e-4       # Lower than some guides (2e-4 to 5e-4) but smoother results
lr_scheduler: "cosine_with_restarts"
lr_warmup_steps: 100
max_train_steps: 2000     # Sweet spot 1500-2500 (>3000 = rigid, can't do new poses)
train_batch_size: 1
resolution: 1024
mixed_precision: "bf16"
optimizer_type: "AdamW8bit"
```

**Captioning:**
- Manual captioning produces best quality
- Budget 10-15 minutes per image (30-45 min total for 20-image dataset)
- Include: character name trigger word, clothing description, pose, expression, lighting
- Example: `sks_character, woman with short brown hair, wearing blue blazer, standing, neutral expression, studio lighting, white background`

**Training time:** 1-3 hours on 12GB+ GPU
**Output:** 50-150MB LoRA file

**Inference weight:** 0.6-0.8 (too high = rigid/overfitted look)

### 3.7 Character Turnaround / Reference Sheet Technique

Create a multi-view reference sheet showing character from all angles:

**What to include:**
- Front view
- 3/4 view (both sides)
- Profile (both sides)
- Back view
- Consistent lighting across all views
- Same clothing, hairstyle, physical features

**Prompt for generating turnaround:**
```
Character design sheet with multiple views (Front, Side, and Back views),
consistent lighting across all views, [character description], white background,
model sheet, turnaround sheet, reference sheet
```

**Usage:** Feed turnaround as reference image to IP-Adapter/InstantID for any new generation. Dramatically improves consistency across different camera positions.

### 3.8 BRAND Consistency (Beyond Face)

Face lock is only part of brand consistency. Full brand consistency requires:

1. **Color palette lock:** Use ControlNet color/tile to enforce brand colors
2. **Environment consistency:** Generate brand-specific environments as LoRA or reference images
3. **Lighting profile:** Create lighting reference sheet (same as character turnaround but for lighting)
4. **Typography overlay:** ALWAYS render text via code (Pillow/After Effects), never AI
5. **Logo placement:** Always composite real PNG, never generate
6. **Grain/texture profile:** Same post-processing chain for every output
7. **Prompt prefix:** Standard brand descriptor that prepends every prompt

---

## TOPIC 4: ADVANCED PROMPTING SYSTEMS

### 4.1 The 6-Layer Cinematic Framework

Professional AI video studios use a structured framework:

```
LAYER 1: SHOT TYPE
  Wide shot | Medium shot | Close-up | Extreme close-up | Aerial | POV | Two-shot

LAYER 2: SUBJECT + ACTION
  [Subject description] + [one clear action per shot]
  "Woman in navy blazer takes four steps toward the window, pauses, looks back"

LAYER 3: SETTING / CONTEXT
  Environment + time of day + weather/atmosphere
  "Modern minimalist apartment, floor-to-ceiling windows, golden hour, city skyline"

LAYER 4: CAMERA MOVEMENT
  Static | Slow push-in | Dolly left | Tracking right | Crane descending
  Arc shot | Whip pan | Handheld | FPV

LAYER 5: LIGHTING / COMPOSITION
  Three-point | Natural window | Chiaroscuro | Golden hour | Studio
  Shallow depth of field | Deep focus | Macro | Wide-angle

LAYER 6: TECHNICAL / STYLE
  Film grain | 35mm | Anamorphic | Color palette | Aspect ratio
  Audio cues (Veo 3.1): footsteps, ambient sound, dialogue
```

**The master template:**
```
[Camera movement]: [Shot type] of [subject] [action] in [setting].
[Lighting]. [Lens/composition]. [Style modifiers]. [Audio cues if applicable].
```

### 4.2 Veo 3.1 Prompt Architecture (Google's Official Guide)

**5-part formula:** `[Cinematography] + [Subject] + [Action] + [Context] + [Style & Ambiance]`

**Audio-First mental model (critical for Veo 3.1):**
- Describe sounds FIRST: footsteps, doors, glass breaking, wind
- Veo creates more physically accurate video when audio is specified
- Use separate sentences for audio descriptions

**Example (production-grade):**
```
Slow dolly forward. Close-up of a barista's hands pouring steamed milk
into a ceramic cup, creating latte art. Warm morning light streams through
a window to the left. Shallow depth of field, 85mm lens. The sound of
milk steaming and gentle cafe ambience. Film grain, warm color palette.
```

### 4.3 Kling 2.6 Pro Prompt Architecture

**Key difference:** Motion comes from REFERENCE VIDEO, not prompt.

**Prompt focuses on:**
- Background details and environment
- Lighting conditions and color grading
- Atmospheric effects
- Context that helps blend character image + reference video motion

**Example:**
```
Cinematic lighting, warm sunset tones, shallow depth of field,
professional color grading. Urban rooftop setting with city skyline
in soft focus background. Gentle wind effect on clothing and hair.
```

**Motion reference rules:**
- Image Orientation: portrait animations with camera movement (max 10s)
- Video Orientation: full-body performances (max 30s)
- Character image = visual identity
- Reference video = choreography
- Prompt = context/atmosphere

### 4.4 Runway Gen-3/Gen-4 Prompt Structure

**Format:** `[camera movement]: [establishing scene]. [additional details].`

**Camera keywords:** low angle, high angle, overhead, FPV, handheld, wide angle, close up, macro
**Motion modifiers:** "dynamic" or "smooth" to refine movement quality

**Pro tip:** Repeat/reinforce key ideas in different sections to increase adherence.

### 4.5 Negative Prompt Master List

**Universal (always include):**
```
lowres, bad quality, worst quality, jpeg artifacts, compression artifacts,
noisy, grainy, blurry, out of focus, pixelated, oversmoothed, watermark,
signature, text, username, error
```

**Anatomical (always include for human subjects):**
```
distorted face, asymmetric eyes, strange mouth, disfigured, extra limbs,
missing fingers, elongated neck, deformed hands, extra digits, extra arms,
extra hands, fused fingers, malformed limbs, mutated hands, poorly drawn hands,
extra fingers, missing hands, bad hands, three hands, too many fingers,
missing fingers, bad feet
```

**Professional quality baseline:**
```
ugly, blurry, bad anatomy, bad hands, text, error, missing fingers,
extra digit, fewer digits, cropped, worst quality, low quality,
normal quality, jpeg artifacts, signature, watermark, username
```

**Video-specific:**
```
shaky, flickering, frame drops, distorted motion, temporal inconsistency,
jitter, strobing, morphing artifacts, face morphing between frames
```

### 4.6 Multi-Pass Prompting Strategy

```
PASS 1 — CONCEPT (cheap model, low resolution)
├── Purpose: validate composition, framing, action
├── Model: Hailuo (cheapest) or Kling Standard
├── Resolution: 720p
├── Generate 5-10 variants
└── Select best 2-3 compositions

PASS 2 — REFINEMENT (mid-tier model, medium resolution)
├── Purpose: refine selected concepts
├── Model: Kling Pro or Runway Gen-4
├── Resolution: 1080p
├── Apply character consistency (IP-Adapter/InstantID)
├── Test 3-5 prompt variations per concept
└── Select final direction

PASS 3 — FINAL (best model, full resolution)
├── Purpose: production-grade output
├── Model: Veo 3.1 or Runway Gen-4.5
├── Resolution: 4K (or native highest)
├── Full character lock (LoRA + PuLID + ControlNet)
├── Generate 3 variants of final
└── Select best, send to post-production
```

### 4.7 Prompt Library Organization System

```
prompt-library/
├── shot-types/
│   ├── wide-establishing.md
│   ├── medium-dialogue.md
│   ├── close-up-emotion.md
│   ├── extreme-close-up-detail.md
│   ├── aerial-overview.md
│   └── pov-immersive.md
├── camera-movements/
│   ├── static.md
│   ├── dolly-push-pull.md
│   ├── tracking-lateral.md
│   ├── crane-vertical.md
│   ├── arc-orbital.md
│   ├── whip-pan.md
│   ├── handheld.md
│   └── fpv-dynamic.md
├── lighting/
│   ├── natural-golden-hour.md
│   ├── natural-overcast-soft.md
│   ├── studio-three-point.md
│   ├── dramatic-chiaroscuro.md
│   ├── neon-nighttime.md
│   └── practical-source.md
├── moods/
│   ├── warm-inviting.md
│   ├── energetic-dynamic.md
│   ├── calm-meditative.md
│   ├── dramatic-tension.md
│   └── playful-fun.md
├── actions/
│   ├── walking.md
│   ├── talking-dialogue.md
│   ├── product-interaction.md
│   ├── cooking-food.md
│   ├── fitness-movement.md
│   └── unboxing-reveal.md
└── brand-prefixes/
    ├── mirra.md
    ├── pinxin.md
    └── bloom-and-bare.md
```

### 4.8 Prompt Testing Methodology

**The 5-10-1 rule:**
1. Write 5 prompt variations
2. Generate 10 outputs per variation (50 total)
3. Select 1 winner per variation
4. Compare 5 winners
5. Refine winning prompt, repeat

**Systematic A/B testing:**
- Change ONE variable at a time
- Track: which element changed, what improved/degraded
- Build personal database of effective prompt elements
- Document winners with screenshots + exact prompts

---

## TOPIC 5: PRODUCTION PIPELINE AT SCALE

### 5.1 The 20-50 Videos Per Week Pipeline

```
WEEKLY PIPELINE STRUCTURE

Monday: PLANNING (2 hours)
├── Review brand calendar / campaign briefs
├── Identify shot list from templates
├── Assign: REAL shoot vs AI-only vs HYBRID
└── Prepare prompt batches from library

Tuesday-Wednesday: GENERATION (batch processing)
├── ComfyUI batch workflows running overnight
├── API calls to Kling/Veo/Runway (parallel)
├── Real footage shoot (if scheduled)
└── Generate 3-5x target volume (expect 30-40% pass rate)

Thursday: QC + COMPOSITING
├── Quality audit pass (see 5.4 checklist)
├── Composite hybrid shots
├── Color grade + grain matching
└── Text/logo/CTA overlay (code-rendered)

Friday: FINAL + DELIVERY
├── Final QC review
├── Platform-specific exports (aspect ratios, codecs)
├── Upload + scheduling
└── Archive: prompts, references, outputs, metadata
```

### 5.2 Template Systems for Parametric Video

**Concept:** Define video "templates" as parameterized structures — swap content while keeping structure.

```python
# Example parametric video template
template = {
    "name": "product_hero_15s",
    "duration": 15,
    "shots": [
        {"type": "wide_establishing", "duration": 3, "source": "ai_generated"},
        {"type": "product_close_up", "duration": 4, "source": "real_footage"},
        {"type": "lifestyle_medium", "duration": 4, "source": "hybrid"},
        {"type": "cta_card", "duration": 2, "source": "code_rendered"},
        {"type": "logo_outro", "duration": 2, "source": "code_rendered"}
    ],
    "variables": {
        "product_name": str,
        "hero_image": path,
        "background_mood": ["warm", "cool", "energetic"],
        "cta_text": str,
        "brand_colors": list
    }
}
```

**Processing rules (Joyspace-style):**
- From one long-form video: extract 3x 60s clips, 5x 30s clips, 10x 15s clips
- Configure once, auto-apply to all uploads
- Themed recording sessions: 1 day shoot → all footage for 1 topic/pillar

### 5.3 Asset Management System

```
project-root/
├── 01-briefs/
│   └── {brand}/{campaign}/{date}-brief.md
├── 02-references/
│   ├── character-sheets/
│   ├── environment-refs/
│   ├── style-refs/
│   └── motion-refs/
├── 03-prompts/
│   ├── {date}-{shot}-v{n}.txt    (versioned prompts)
│   └── winners/                   (proven prompts)
├── 04-raw-footage/
│   ├── camera/                    (real footage)
│   └── ai-generated/             (raw AI output)
├── 05-work-in-progress/
│   ├── SH001/                     (per-shot folders)
│   │   ├── SH001_v001.mp4
│   │   ├── SH001_v002.mp4
│   │   └── SH001_prompt.txt
│   └── SH002/
├── 06-composited/
├── 07-graded/
├── 08-final/
│   ├── {platform}/               (ig-feed, ig-story, tiktok, etc.)
│   └── master/
└── 09-archive/
    ├── metadata.json             (searchable: topic, campaign, platform, performance)
    └── rejected/
```

**Shotbuddy (open-source version control for AI video):**
- Auto-renames assets to standardized `SHXXX` format
- Drag-and-drop version management
- Associates prompts with each shot thumbnail via "P" button
- Maintains `latest_images/` and `latest_videos/` folders automatically
- All historical versions preserved in `wip/` shot folders
- GitHub: `albozes/shotbuddy`

### 5.4 Quality Control Audit Checklist

```
PRE-DELIVERY QC CHECKLIST
========================

TECHNICAL QUALITY
[ ] Resolution matches target (1080x1350 / 1080x1920 / 4K)
[ ] No compression artifacts visible
[ ] No AI morphing/flickering between frames
[ ] Consistent frame rate (no dropped frames)
[ ] Audio sync (if applicable)
[ ] Color space correct for platform

BRAND CONSISTENCY
[ ] Logo: correct variant, correct placement, correct size
[ ] Colors: within brand palette tolerance
[ ] Typography: brand fonts only, code-rendered (not AI)
[ ] Tone: matches brand voice
[ ] No competitor brand names/logos visible
[ ] No AI hallucinated text/watermarks

CHARACTER/IDENTITY
[ ] Face consistency: same person throughout
[ ] Clothing consistency: no mid-shot wardrobe changes
[ ] Hand/finger count: correct (5 per hand)
[ ] Body proportions: natural, consistent
[ ] No uncanny valley facial expressions

COMPOSITING (hybrid shots)
[ ] Edge quality: no visible seams between real/AI
[ ] Grain match: AI elements match camera noise
[ ] Color match: unified grade across all sources
[ ] Motion blur match: consistent with camera settings
[ ] Lighting direction: consistent across all elements
[ ] Depth of field: AI elements respect focal plane

CONTENT/COMPLIANCE
[ ] All text factually correct
[ ] CTAs, URLs, phone numbers verified
[ ] No copyrighted content
[ ] No inappropriate/offensive content
[ ] Platform-specific compliance (Meta, TikTok rules)
```

### 5.5 Cost Optimization: Model Tier Strategy

| Stage | Model | Cost | Resolution | Use Case |
|-------|-------|------|------------|----------|
| **Concept** | Hailuo/MiniMax | ~$0.07/sec | 720p | Composition tests, 5-10 variants |
| **Concept** | Kling Standard | ~$0.10/sec | 720p-1080p | Motion/action tests |
| **Refinement** | Kling Pro | ~$0.20/sec | 1080p | Character + motion lock |
| **Refinement** | Runway Gen-4 | ~$0.30/sec | 1080p | Client flexibility, style control |
| **Final** | Veo 3.1 | ~$0.40/sec | 4K + audio | Hero shots, audio-sync |
| **Final** | Runway Gen-4.5 | ~$0.50/sec | 4K | Premium quality, client work |
| **Local** | WAN 2.2 (ComfyUI) | GPU cost only | 1080p | Unlimited iteration, privacy |
| **Local** | AnimateDiff (ComfyUI) | GPU cost only | 512-768p | Style transfer, experiments |

**Budget strategy for 50 videos/week:**
- 70% of generations at Concept tier ($$$)
- 20% at Refinement tier ($$$$)
- 10% at Final tier ($$$$$)
- Expected: ~$500-1,500/month depending on video length/volume

### 5.6 Version Control for Video Production

**The problem:** Traditional filmmaking = dozen takes per scene. AI generation = hundreds of variations per scene.

**Solutions:**
1. **Shotbuddy** (free, open-source): purpose-built for AI video version control
2. **DVC (Data Version Control)**: Git-like versioning for large media files
3. **Custom folder structure** (see 5.3): systematic naming + metadata JSON
4. **Project versioning**: maintain multiple branches of development, return to earlier iterations

**Naming convention:**
```
{project}_{shot}_{version}_{model}_{date}.mp4
mirra_SH001_v003_kling26_20260316.mp4
```

**Metadata per generation (store in JSON):**
```json
{
  "shot_id": "SH001",
  "version": 3,
  "model": "kling-2.6-pro",
  "prompt": "...",
  "negative_prompt": "...",
  "reference_image": "refs/character_sheet_v2.png",
  "motion_reference": "refs/walk_cycle_01.mp4",
  "parameters": {
    "seed": 42,
    "steps": 50,
    "cfg_scale": 7,
    "resolution": "1080x1920"
  },
  "timestamp": "2026-03-16T14:30:00",
  "status": "approved",
  "notes": "Best walk cycle, approved by client"
}
```

---

## APPENDIX A: MODEL COMPARISON (March 2026)

### Tier Rankings (Elo-based)

| Tier | Model | Elo | Key Strength |
|------|-------|-----|-------------|
| S | Runway Gen-4.5 | 1,247 | Overall quality leader |
| S | Google Veo 3.1 | 1,226 | Native audio, realism |
| S | Kling 3.0 | ~1,200 | Physics, complex motion |
| S | Sora 2 | ~1,200 | Long-form coherence |
| A | Runway Gen-4 | ~1,150 | Industry standard, API |
| A | Kling 2.6 Pro | ~1,130 | Motion control, cost |
| A | Seedance 2.0 | ~1,100 | Emerging quality |
| B | Hailuo/MiniMax 2.3 | ~1,050 | Value, multiple styles |
| B | HunyuanVideo | ~1,000 | Open-source, local |
| B | WAN 2.2 | ~1,000 | Open-source, character lock |
| B | LTX-2 | ~980 | NVIDIA optimized, fast |

### Pricing Comparison

| Model | Subscription | Per-Second Cost | Max Duration | Audio |
|-------|-------------|-----------------|--------------|-------|
| Hailuo | $4.99/mo | ~$0.07/sec | 10s | No |
| Kling 3.0 | $6.99/mo | ~$0.10/sec | 30s | No |
| Sora 2 | $20/mo | ~$0.25/sec | 20s | Yes |
| Runway Gen-4 | $15/mo | ~$0.30/sec | 16s | No |
| Veo 3.1 | Pay-as-go | ~$0.40/sec | 8s | Yes |

### Audio Generation (native)

4 major models now generate synchronized audio (dialogue, ambient, SFX):
- Veo 3.1 (best quality)
- Sora 2
- Hailuo (basic)
- Runway Gen-4 (post-process)

---

## APPENDIX B: NEGATIVE PROMPT MASTER LIST

### Tier 1: Always Include (every generation)
```
lowres, bad quality, worst quality, jpeg artifacts, blurry, watermark,
signature, text, error, deformed, disfigured, mutation, extra limbs
```

### Tier 2: Human Subjects
```
bad anatomy, bad hands, missing fingers, extra digit, fewer digits,
extra fingers, fused fingers, mutated hands, poorly drawn hands,
extra arms, extra hands, three hands, bad feet, elongated neck,
asymmetric eyes, strange mouth, distorted face, cross-eyed
```

### Tier 3: Video-Specific
```
flickering, frame drops, temporal inconsistency, morphing between frames,
jitter, strobing, face morphing, identity shift, costume change mid-shot,
unnatural motion, frozen frames, stuttering movement
```

### Tier 4: Professional Quality
```
amateur, stock photo, clipart, cartoon (unless intended), oversaturated,
undersaturated, flat lighting, harsh shadows, lens flare (unless intended),
chromatic aberration, vignette (unless intended), noise, film scratch
```

### Tier 5: Brand Safety
```
nsfw, violent, gore, offensive, competitor brand, wrong logo, misspelled text,
copyrighted character, celebrity likeness (unless licensed)
```

---

## APPENDIX C: PROMPT LIBRARY TEMPLATES

### Template: Product Hero Shot (15s)
```
Slow dolly forward. Medium close-up of [PRODUCT] on [SURFACE] in [SETTING].
[LIGHTING_TYPE] from [DIRECTION]. Shallow depth of field, 85mm lens.
[ATMOSPHERE]. Professional product photography style, [COLOR_PALETTE].
```

### Template: Lifestyle/Brand Video (30s)
```
[CAMERA_MOVEMENT]. [SHOT_TYPE] of [SUBJECT] [ACTION] in [SETTING].
[TIME_OF_DAY], [LIGHTING]. [LENS]. Warm, inviting atmosphere.
[BRAND_STYLE_MODIFIER]. Film grain, natural color palette.
```

### Template: Food/Cooking (15s)
```
Overhead tracking shot. Close-up of [HANDS/ACTION] [COOKING_ACTION]
with [INGREDIENTS]. Steam rising, warm kitchen lighting from left.
Macro lens details on textures. Sound of [COOKING_SOUND].
Rich, appetizing color grading, shallow depth of field.
```

### Template: Testimonial/UGC Style (30s)
```
Static camera, medium shot. [PERSON_DESCRIPTION] speaking directly to camera
in [CASUAL_SETTING]. Natural window light from right, slightly overexposed.
Handheld micro-movements for authenticity. iPhone-quality aesthetic,
no color grading, natural skin tones. Room tone and voice audio.
```

### Template: Energetic Promo (15s)
```
Quick cuts, dynamic camera. [SHOT_TYPE] of [SUBJECT] [HIGH_ENERGY_ACTION].
Whip pan transition to [NEXT_SCENE]. Dramatic lighting with [COLOR] accents.
Wide angle lens, deep depth of field. Pulsing music beat sync.
Bold, saturated color palette.
```

### Template: Calm/Wellness (30s)
```
Slow crane descending. Wide shot of [SERENE_SETTING] at [GOLDEN_HOUR/DAWN].
[SUBJECT] in [PEACEFUL_ACTION]. Soft natural lighting, no harsh shadows.
Long lens compression, dreamlike shallow focus. Gentle ambient sounds —
[NATURE_SOUND]. Desaturated, airy color palette with [ACCENT_COLOR].
```

---

## SOURCES

### Topic 1: Hybrid Pipeline
- [Hybrid Video Production – Ways to Make AI Part of Your Workflow | CineD](https://www.cined.com/hybrid-video-production-ways-to-make-ai-part-of-your-workflow/)
- [7 AI Video Trends in 2026 | Genra.ai](https://genra.ai/blog/ai-video-trends-2026-generation-to-agent-workflows)
- [Runway Aleph: AI Edits Real Footage | CineD](https://www.cined.com/runway-aleph-ai-edits-real-footage-with-camera-angles-object-removal-and-relighting/)
- [Top 10 AI Tools Transforming VFX Workflows in 2026 | ActionVFX](https://www.actionvfx.com/blog/top-10-ai-tools-for-vfx-workflows)
- [Beeble Studio | Production-Grade 4K AI Relighting](https://beeble.ai/beeble-studio)
- [Superman & Lois: Pushing limits with AI relighting | Beeble](https://beeble.ai/showcase/superman-lois-relighting-vfx)
- [GenVFX Pipeline Development | Groove Jones](https://www.groovejones.com/genvfx-pipeline-development)

### Topic 2: ComfyUI Workflows
- [ComfyUI AnimateDiff Guide | Civitai](https://civitai.com/articles/2379/guide-comfyui-animatediff-guideworkflows-including-prompt-scheduling-an-inner-reflections-guide)
- [ComfyUI AnimateDiff and IP-Adapter Workflow | RunComfy](https://www.runcomfy.com/comfyui-workflows/comfyui-animatediff-and-ipadapter-workflow-stable-diffusion-animation)
- [ComfyUI-AnimateDiff-Evolved | GitHub](https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved)
- [Wan2.1 Stand In ComfyUI Workflow | RunComfy](https://www.runcomfy.com/comfyui-workflows/wan2-1-stand-in-in-comfyui-character-consistent-video-workflow)
- [Wan2.2 Video Generation ComfyUI | Official Docs](https://docs.comfy.org/tutorials/video/wan/wan2_2)
- [ComfyUI-KLingAI-API | GitHub](https://github.com/KlingTeam/ComfyUI-KLingAI-API)
- [ComfyUI Animation Workflow Guide 2026 | Apatero](https://apatero.com/blog/comfyui-animation-workflow-video-generation-2026)
- [Stand-In: CVPR2026 Identity-Preserving Video Generation | GitHub](https://github.com/WeChatCV/Stand-In)
- [NVIDIA RTX Accelerates AI Video with LTX-2 and ComfyUI](https://blogs.nvidia.com/blog/rtx-ai-garage-ces-2026-open-models-video-generation/)

### Topic 3: Character Consistency
- [AI Face Swap Showdown: PuLID vs InstantID vs FaceID | MyAIForce](https://myaiforce.com/pulid-vs-instantid-vs-faceid/)
- [Comparing 4 Face Swap Techniques: Hyper LoRA, InstantID, PuLID, ACE Plus | MyAIForce](https://myaiforce.com/hyperlora-vs-instantid-vs-pulid-vs-ace-plus/)
- [FLUX 2 Pro LoRA Training: Character Consistency Guide 2026 | Apatero](https://apatero.com/blog/flux-2-pro-lora-training-character-consistency-2026)
- [Flux PuLID, InstantID, EcomID Compared | MyAIForce](https://myaiforce.com/flux-pulid-vs-ecomid-vs-instantid/)
- [100% Face Similarity: Ultimate Face Swap Workflow | Medium](https://medium.com/@wei_mao/100-face-similarity-the-ultimate-face-swap-workflow-better-than-any-pulid-instantid-b7fa2daa5659)
- [ACE Plus + Redux 99% Face Consistency | MyAIForce](https://myaiforce.com/ace-plus-redux-portrait-bg-swap/)
- [AI Consistent Character Generator Guide 2026 | Apatero](https://www.apatero.com/blog/ai-consistent-character-generator-multiple-images-2026)
- [Training a Character LoRA with Kohya_ss | Digital Zoom Studio](https://digitalzoomstudio.net/2026/03/training-a-character-lora-with-kohya_ss-automatic1111/)

### Topic 4: Prompting Systems
- [The Complete Guide to AI Video Prompt Engineering | Venice.ai](https://venice.ai/blog/the-complete-guide-to-ai-video-prompt-engineering)
- [Ultimate prompting guide for Veo 3.1 | Google Cloud](https://cloud.google.com/blog/products/ai-machine-learning/ultimate-prompting-guide-for-veo-3-1)
- [Gen-3 Alpha Prompting Guide | Runway](https://help.runwayml.com/hc/en-us/articles/30586818553107-Gen-3-Alpha-Prompting-Guide)
- [Kling 2.6 Pro Prompt Guide | fal.ai](https://fal.ai/learn/devs/kling-2-6-pro-prompt-guide)
- [Kling 2.6 Motion Control Prompt Guide | fal.ai](https://fal.ai/learn/devs/kling-video-2-6-motion-control-prompt-guide)
- [AI Video Prompt Guide | LTX Studio](https://ltx.studio/blog/ai-video-prompt-guide)
- [200+ Best Stable Diffusion Negative Prompts | Aitubo](https://aitubo.ai/blog/post/stable-diffusion-negative-prompts/)

### Topic 5: Production at Scale
- [How to Build an AI Video Production Pipeline 1000+ Clips Monthly | Joyspace](https://joyspace.ai/ai-video-production-pipeline-1000-clips-monthly-2026)
- [Shotbuddy: AI Video Version Control | GitHub](https://github.com/albozes/shotbuddy)
- [Shotbuddy Solves AI Video's Version Control Chaos | VP Land](https://www.vp-land.com/p/shotbuddy-solves-ai-video-s-version-control-chaos)
- [Best AI Video Workflow Guide & Tool Stack 2026 | LTX Studio](https://ltx.studio/blog/ai-video-workflow)
- [AI Video Generation Cost | LTX Studio](https://ltx.studio/blog/ai-video-generation-cost)
- [Best AI Video Editing Tech Stack for Agencies | Joyspace](https://joyspace.ai/ultimate-ai-video-editing-tech-stack-agencies)
- [Best AI Video Generators Ranked 2026 | AI Video Bootcamp](https://aivideobootcamp.com/blog/ai-video-generators-ranked-2026/)
- [Veo 3.1 vs Top AI Video Generators: 2026 Comparison | PXZ](https://pxz.ai/blog/veo-31-vs-top-ai-video-generators-2026)

### Model Comparison
- [The State of AI Video Generation Feb 2026 | Medium/Cliprise](https://medium.com/@cliprise/the-state-of-ai-video-generation-in-february-2026-every-major-model-analyzed-6dbfedbe3a5c)
- [Kling 2.0 vs Runway Gen-3 Comparison 2026 | WaveSpeedAI](https://wavespeed.ai/blog/posts/kling-vs-runway-gen3-comparison-2026/)
- [17 Best AI Video Generation Models Pricing & Benchmarks | AI Free Forever](https://aifreeforever.com/blog/best-ai-video-generation-models-pricing-benchmarks-api-access)
- [DaVinci Resolve AI Workflow | Envato Tuts+](https://photography.tutsplus.com/articles/davinci-resolve-ai--cms-109186)
- [Colourlab AI for DaVinci Resolve](https://colourlab.ai/colourlab-ai-for-davinci-resolve/)
