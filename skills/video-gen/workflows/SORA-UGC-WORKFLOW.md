# Sora 2 UGC Video Creation Workflow
> GAIA CORP-OS — Complete pipeline from concept to publish
> Built: 2026-02-28 | Owner: Taoz | Model: Sora 2 (OpenAI)

## Quick Start

```bash
# Full pipeline: concept → image → video → post-prod → export
bash video-gen.sh sora-ugc \
  --brand pinxin-vegan \
  --concept "founder making smoothie bowl in kitchen" \
  --style ugc-casual \
  --duration 8 \
  --aspect-ratio 9:16
```

## The 7-Step Pipeline

```
1. BRIEF        → Extract concept, brand, tone, CTA
2. REVERSE      → Analyze reference (image/video) for visual DNA
3. SMART PROMPT → Build Sora-optimized prompt with brand injection
4. GENERATE     → Sora 2 text-to-video or image-to-video
5. POST-PROD    → Captions, music duck, grain, brand overlay
6. QA           → Brand voice check + visual audit
7. EXPORT       → Multi-platform (9:16 Reels, 16:9 YouTube, 1:1 Feed)
```

---

## Step 1: BRIEF (Placeholders)

Every UGC video starts with a brief. These are the **space holders** (variables):

| Placeholder | Example | Source |
|-------------|---------|--------|
| `{{BRAND}}` | pinxin-vegan | Brand slug from `brands/{brand}/DNA.json` |
| `{{PRODUCT}}` | Signature Smoothie Bowl | Product name |
| `{{CONCEPT}}` | Founder making smoothie in kitchen | Creative concept |
| `{{HOOK}}` | "I can't believe this is vegan" | First 3s hook text |
| `{{CTA}}` | "Link in bio" | Call to action |
| `{{TONE}}` | casual, authentic, warm | From DNA.json `voice.tone` |
| `{{COLORS}}` | #8fbc8f, #d4a437 | From DNA.json `visual.colors` |
| `{{MOTION_STYLE}}` | handheld, slow zoom, rack focus | From DNA.json `visual.motion` |
| `{{FUNNEL_STAGE}}` | TOFU / MOFU / BOFU | Determines urgency level |
| `{{ASPECT_RATIO}}` | 9:16 | Platform target |
| `{{DURATION}}` | 4 / 8 / 12 | Sora accepts 4, 8, or 12 seconds only |
| `{{TALENT}}` | Agent character / real person / hands-only | Who appears |
| `{{LOCATION}}` | kitchen / café / outdoor market | Setting |
| `{{STYLE_SEED}}` | seed-12345 | From style_seeds table in library.db |

**Brief template:**
```
Create a {{DURATION}}s UGC-style video for {{BRAND}}.
Product: {{PRODUCT}}
Concept: {{CONCEPT}}
Hook: "{{HOOK}}"
Setting: {{LOCATION}}
Talent: {{TALENT}}
Tone: {{TONE}}
CTA: {{CTA}}
Funnel: {{FUNNEL_STAGE}}
```

---

## Step 2: REVERSE PROMPT (Reference Analysis)

**When to use:** When you have a reference image/video you want to match.

```bash
# From video reference
bash video-gen.sh reverse-prompt /path/to/reference-video.mp4

# From image reference (uses Gemini Vision)
bash video-gen.sh reverse-prompt /path/to/reference-image.png
```

**What it extracts:**
- Camera movement (handheld/tripod/drone/slider)
- Lighting (natural/studio/golden hour/low key)
- Color palette (warm/cool/desaturated/vibrant)
- Composition (rule of thirds/centered/dutch angle)
- Pacing (cuts per second, hold duration)
- Subject interaction (talking to camera/doing activity/POV)
- Text overlays (style, font, placement)

**Output:** A detailed visual DNA description that feeds into Step 3.

**For Iris integration:**
```bash
# Iris (qwen3-vl) can do deeper visual analysis
bash dispatch.sh taoz iris request "Analyze this reference video and extract visual DNA: camera, lighting, color, composition, pacing, mood. File: /path/to/ref.mp4"
```

---

## Step 3: SMART PROMPT (Sora-Optimized)

The `enhance_prompt()` function in video-gen.sh already does brand injection. For UGC, we layer Sora-specific prompt engineering on top.

> **Source:** OpenAI Cookbook Sora 2 Prompting Guide + GAIA battle-tested patterns.
> Think of prompts as **creative briefs for a cinematographer** — concrete visuals, not abstract concepts.

### Core Principle: API Params vs Prompt Content

Sora's API handles `model`, `size`, `duration` — your prompt should focus on **what's in the frame**:
- Scene description (subject, setting, props)
- Cinematography cues (camera, movement, depth of field)
- Lighting & color
- Subject action & emotion
- Sound/dialogue (optional, Sora interprets mood from this)

### 3 Prompt Templates

#### Template 1: Simple Scene + Action (most UGC)
```
[SETTING] + [SUBJECT] + [ACTION] + [LIGHTING] + [CAMERA]
```
```
{{CAMERA}} shot of {{TALENT}} {{ACTION}} in a {{LOCATION}}.
{{LIGHTING}}, {{COLORS}} color palette.
{{MOTION_STYLE}} camera movement.
Style: {{STYLE}} UGC, authentic, {{TONE}}.
```

**Example:**
```
Handheld close-up shot of a young woman smiling while assembling a colorful smoothie bowl in a bright modern kitchen.
Soft natural daylight from large windows, warm sage green (#8fbc8f) and gold (#d4a437) tones.
Gentle handheld sway with slow push-in.
Style: casual UGC, authentic, warm and inviting.
```

#### Template 2: Dialogue / Sound Scene
```
[SETTING] + [SUBJECT] + [ACTION] + [LIGHTING] + [CAMERA] + [DIALOGUE/SOUND]
```
```
{{CAMERA}} shot of {{TALENT}} {{ACTION}} in a {{LOCATION}}.
{{LIGHTING}}, {{COLORS}} color palette.
{{MOTION_STYLE}} camera movement.
{{TALENT}} says: "{{HOOK}}"
Ambient sounds: {{AMBIENT}} (e.g., kitchen clatter, cafe murmur, birds).
Style: {{STYLE}} UGC, authentic, {{TONE}}.
```

**Example:**
```
Medium handheld shot of a young woman in a bright kitchen, looking at camera while holding a smoothie bowl.
Soft natural morning light from large windows, warm sage and gold tones.
Gentle handheld sway. She looks up, smiles, and says: "I can't believe this is vegan."
Ambient: gentle kitchen sounds, spoon clinking.
Style: casual UGC, authentic, warm.
```

#### Template 3: Professional / Controlled Aesthetics
```
[LENS/FORMAT] + [SETTING] + [SUBJECT] + [ACTION] + [LIGHTING] + [CAMERA] + [COLOR GRADE]
```
```
Shot on {{LENS}} {{FORMAT}}. {{CAMERA}} of {{TALENT}} {{ACTION}} in {{LOCATION}}.
{{LIGHTING}}. {{MOTION_STYLE}} camera movement.
Color palette: {{COLOR_GRADE}} (e.g., "Kodak Portra 400 tones", "desaturated teal and orange").
Shallow depth of field, {{BOKEH_STYLE}}.
Style: {{STYLE}}, {{TONE}}.
```

**Example:**
```
Shot on 35mm Kodak Portra 400. Close-up tracking shot of hands arranging acai toppings on a smoothie bowl.
Soft golden hour light from a side window, warm highlights and gentle shadows.
Slow dolly push-in, shallow depth of field with creamy bokeh on background herbs.
Color palette: warm sage green and muted gold, slightly lifted blacks.
Style: premium UGC, editorial but approachable.
```

### Cinematography Vocabulary (Sora responds to these)

| Category | Options Sora Understands |
|----------|-------------------------|
| **Camera** | handheld, tripod, Steadicam, gimbal, drone, crane, dolly |
| **Movement** | pan, tilt, push-in, pull-back, tracking, orbit, static, rack focus |
| **Shot size** | extreme close-up, close-up, medium, wide, establishing, POV, over-shoulder |
| **Lens** | wide-angle, telephoto, macro, 35mm, 50mm, anamorphic |
| **Film stock** | Kodak Portra 400, Fuji Velvia, CineStill 800T, Kodachrome |
| **Depth of field** | shallow (bokeh), deep focus, rack focus, tilt-shift |
| **Lighting** | natural daylight, golden hour, blue hour, overhead, side-lit, backlit, low-key, high-key |

### Sora-Specific Tips

**DO:**
- Describe camera movement explicitly (Sora respects this well)
- Mention "UGC" or "user-generated" for authentic feel
- Specify lighting direction ("from left", "overhead", "behind subject")
- Use film stock names for look (e.g., "Kodak Portra 400 warmth")
- One scene per prompt — keep it focused
- Use image input as visual anchor for consistency across clips

**DON'T:**
- Use abstract concepts ("love", "freedom") — Sora needs concrete visuals
- Request text overlays in prompt — add in post-prod
- Mix multiple scenes in one prompt — one scene per generation
- Cram too many actions — less is more for coherence

**Duration guide:**
- 4s = single action (pour, look up, smile)
- 8s = action + reaction (make bowl → present to camera)
- 12s = mini story (enter kitchen → prepare → reveal)

### Iteration Strategy

When refining, **change one element at a time**:
1. Lock the scene description, vary only camera movement
2. Lock camera, vary lighting
3. Lock lighting, vary action/pacing
4. Use `--image` with a keyframe to anchor visual style across takes

### Smart Prompt Enhancement

```bash
# video-gen.sh already enhances with brand DNA:
# enhance_prompt() reads DNA.json → appends motion style, colors, tone

# For deeper enhancement, use Dreami:
bash dispatch.sh taoz dreami request "Write a Sora 2 video prompt for: {{CONCEPT}}. Brand: {{BRAND}}. Style: UGC casual. Duration: {{DURATION}}s. Use Template 1/2/3 from SORA-UGC-WORKFLOW. Include camera movement, lens, lighting, and mood. Output ONLY the prompt, nothing else."
```

### Prompt Bank (Ready-to-Use Examples)

#### Food/Product UGC
```
Handheld close-up of hands drizzling honey over a vibrant acai bowl on a marble counter. Soft morning light from a window to the left, warm golden tones. Gentle camera sway, shallow depth of field. Style: casual UGC, appetizing, warm.
```

#### Lifestyle/Wellness
```
Medium tracking shot of a woman walking through a sunlit farmers market, picking up fresh produce and smiling. Natural golden hour backlight, warm earth tones. Steadicam follow, slight lens flare. Style: authentic UGC, wholesome, inviting.
```

#### Behind-the-Scenes / Founder
```
Handheld medium shot of a founder in a commercial kitchen, carefully plating a dish. Overhead fluorescent mixed with warm side light. Gentle push-in as they step back to admire the plate. Shot on 35mm, shallow focus. Style: raw UGC, passionate, real.
```

#### Product Reveal
```
Static close-up of a product package on a wooden table, soft diffused daylight. A hand enters frame, picks it up, turns it to show the label. Rack focus from background herbs to product. Style: clean UGC, minimal, trustworthy.
```

---

## Step 4: GENERATE (Sora 2)

### Text-to-Video
```bash
bash video-gen.sh sora generate \
  --prompt "Handheld shot of woman making smoothie bowl in bright kitchen, natural light, warm sage tones, UGC authentic casual" \
  --duration 8 \
  --aspect-ratio 9:16 \
  --brand pinxin-vegan
```

### Image-to-Video (with reference)
```bash
bash video-gen.sh sora generate \
  --prompt "Gentle handheld movement, woman looks up and smiles, soft natural light" \
  --image /path/to/keyframe.png \
  --duration 8 \
  --aspect-ratio 9:16 \
  --brand pinxin-vegan
```

### Cost
- ~$0.50 per generation
- Typical UGC: 3 scenes × $0.50 = $1.50 per video
- With retakes: budget $3-5 per final video

### Sora Constraints
| Parameter | Options |
|-----------|---------|
| Duration | 4, 8, or 12 seconds ONLY |
| Size | 1280x720, 720x1280, 720x720 |
| Model | `sora-2` |
| Image input | Must match exact output dimensions (auto-resized by video-gen.sh) |

---

## Step 5: POST-PROD (VideoForge + Remotion)

### Quick Post-Production
```bash
# Full produce pipeline: captions + brand overlay + music + grain
bash video-forge.sh produce sora-output.mp4 \
  --type ugc \
  --brand pinxin-vegan \
  --track /path/to/music.mp3 \
  --duck \
  --grain light \
  --caption
```

### Multi-Clip Assembly
```bash
# Assemble 3 Sora clips into one video
bash video-forge.sh assemble clip1.mp4 clip2.mp4 clip3.mp4 \
  --transition fade \
  --output assembled.mp4

# Then produce
bash video-forge.sh produce assembled.mp4 --type ugc --brand pinxin-vegan
```

### Remotion Overlays (optional)
```bash
# Animated name card / brand intro
bash ~/.openclaw/skills/remotion/scripts/render.sh \
  --composition BrandIntro \
  --brand pinxin-vegan \
  --output brand-intro.mp4

# TikTok-style captions
bash ~/.openclaw/skills/remotion/scripts/render.sh \
  --composition AnimatedCaptions \
  --video sora-output.mp4 \
  --output captioned.mp4
```

---

## Step 6: QA (Brand Voice Check)

```bash
# Brand voice check on the script/copy
bash ~/.openclaw/skills/brand-voice-check/scripts/brand-voice-check.sh \
  --brand pinxin-vegan \
  --text "Hook: I can't believe this is vegan. CTA: Link in bio for 15% off"

# Visual audit via Iris
bash dispatch.sh taoz iris request "QA this UGC video for brand consistency. Check: colors match DNA.json, no off-brand elements, text legible, CTA visible. File: /path/to/final.mp4"
```

---

## Step 7: EXPORT (Multi-Platform)

```bash
# Export for all platforms at once
bash video-forge.sh export final.mp4 \
  --platforms "reels,tiktok,youtube,story" \
  --brand pinxin-vegan
```

| Platform | Aspect | Duration | Spec |
|----------|--------|----------|------|
| Reels/TikTok | 9:16 | 8-30s | 1080x1920, <4GB |
| YouTube Short | 9:16 | <60s | 1080x1920 |
| YouTube | 16:9 | any | 1920x1080 |
| Feed Post | 1:1 | <60s | 1080x1080 |
| Story | 9:16 | <15s | 1080x1920 |

---

## Full Pipeline Command

```bash
# One-command full pipeline (NanoBanana → Sora → VideoForge)
bash video-gen.sh pipeline \
  --prompt "Young woman making colorful smoothie bowl in bright kitchen, UGC casual authentic" \
  --provider sora \
  --brand pinxin-vegan \
  --scenes 3 \
  --duration 8 \
  --aspect-ratio 9:16
```

This runs: NanoBanana (scene images) → Sora (image-to-video per scene) → VideoForge (assemble + produce)

---

## Dispatch Examples (via Zennith)

### Simple UGC
```
Jenn: "make a ugc video of someone making pinxin smoothie bowl"
  → Zenni → Zennith
  → Zennith dispatches Dreami: "write Sora prompt for smoothie bowl UGC, brand pinxin-vegan"
  → Zennith dispatches Taoz: "run video-gen.sh sora generate with Dreami's prompt"
  → Zennith dispatches Taoz: "run video-forge.sh produce on the output"
  → Approval queue → Jenn reviews
```

### With Reference
```
Jenn: "make video like this [sends reference video]"
  → Zenni → Zennith
  → Zennith dispatches Iris: "reverse-prompt this reference video"
  → Zennith dispatches Dreami: "write Sora prompt matching Iris's visual DNA analysis"
  → Zennith dispatches Taoz: "run video-gen.sh sora generate"
  → Post-prod → QA → Export
```

### Batch UGC (Multiple Products)
```
Jenn: "make 5 UGC videos for all pinxin products"
  → Zennith plans 5 concepts → dispatches each as parallel pipeline
  → Each: Dreami prompt → Sora generate → VideoForge → QA
  → Batch approval
```

---

## Integration Points

| Tool | When Used | Command |
|------|-----------|---------|
| `video-gen.sh sora generate` | Step 4 — video creation | Core generation |
| `video-gen.sh reverse-prompt` | Step 2 — reference analysis | Gemini Vision |
| `video-gen.sh pipeline` | Full auto — all steps | End-to-end |
| `video-forge.sh produce` | Step 5 — post-production | Captions/music/grain |
| `video-forge.sh export` | Step 7 — multi-platform | Format conversion |
| `nanobanana-gen.sh` | Step 4 — scene images | For image-to-video input |
| `brand-voice-check.sh` | Step 6 — QA | Brand consistency |
| `render.sh` | Step 5 — motion graphics | Remotion overlays |
| `dispatch.sh` | Orchestration | Agent-to-agent routing |
| `Dreami` | Steps 1,3 — script/prompt | Creative writing |
| `Iris` | Steps 2,6 — visual analysis | Reverse-prompt, QA |
