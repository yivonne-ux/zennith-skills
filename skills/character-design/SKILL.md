---
name: character-design
agents:
  - dreami
---

# Character Design Skill (Compounding)
> Source: Sirio's workflows (2 videos) + GAIA OS practice
> Last updated: 2026-02-25
> Learnings: see learnings.jsonl in this directory

## Purpose
Create consistent, realistic AI characters for campaigns, branding, and storytelling.
This skill COMPOUNDS — every creation adds to learnings.jsonl → nightly review → skill update.

## The Golden Rules
1. **Consistency + Realism = Money** — inconsistent characters break illusion, realistic skin sells
2. **Reference FIRST, Generate SECOND** — never start without mood board / reference images
3. **Think like a Director** — pre-visualize, cast, design before pressing generate
4. **Source image quality = everything** — spend 80% of time getting the base right, 20% on variations
5. **Skin enhancement is the secret weapon** — do it ONCE on source, it propagates to all variations

## Workflow: Character Creation (Professional)

### Step 1: Research & Mood Board
- Collect 5-10 reference images (face, body, attire, vibe)
- Sources: Cosmos.so, Pinterest, Are.na, Instagram
- Screenshot the mood board grid
- Store in: `brands/{brand}/characters/{name}/references/`

### Step 2: Prompt Generation (Reverse Prompt)
- Upload mood board screenshot to GPT/Claude
- Ask: "Describe this character as if photographed in a professional studio with white background"
- The prompt should include: complexion details, eye color/shape, hair, facial structure, skin texture, age
- **Critical:** Studio white background, portrait framing, high-fidelity detail
- Store prompt in: `brands/{brand}/characters/{name}/prompt.md`

### Step 3: Base Image Generation (Multi-Model Compare)
Generate with the SAME prompt on 3 models, compare, pick best:

| Model | Strength | Weakness | Best For |
|-------|----------|----------|----------|
| **SeaDreams 3.0** (dreamina.capcut.com) | Consistent 4-image output, 2K res, free 50/day | Sometimes too perfect | Default first choice |
| **Midjourney v7** | High quality, raw mode | Less consistent, less realistic skin | Editorial/fashion |
| **Reeve v1** (preview.reeve.art) | Unique characters, editorial feel | Poor prompt adherence | Unique/editorial looks |
| **Kora Pro** (Enhancor) | Hyper-realistic | Needs API | When API is available |
| **NanoBanana Pro** (Gemini) | Character consistency via image editing | Needs source image first | Variations after source |

Settings:
- Aspect ratio: **3:4** (portrait standard)
- Resolution: **2K** when available
- Model: **Raw mode** on Midjourney
- Generate 4 options per model → pick best from each → final compare

### Step 4: Skin Enhancement (CRITICAL)
- Tool: **Enhancor AI** (enhancer.ai) — Skin Texture Fix
- Settings: Standard mode, Skin texture adjuster: **0.38**, Skin realism level: **1.9**
- Rules:
  - Portrait must be CLOSE-UP (not full body)
  - Face must be in focus, not blurry
  - Keep all areas default (don't toggle exclusions)
  - Higher values = more extreme realism
- **Do this ONCE on base image** — all future generations inherit this skin quality
- Before/after comparison shows subtle but game-changing difference

### Step 5: Consistent Variations (Midjourney Omni Reference)
- Upload enhanced base image to **Midjourney Omni Reference** tab
- Set strength: **300**
- Prompt: "Dutch angle, 28mm flash portrait, [SCENARIO], white studio photography"
- For different emotions: add "smiling" / "laughing" / "angry" / "tongue out"
- For style mimicry: add **Style Reference** image (e.g., photo of someone in desired pose)
- For multi-pose grid: "4x4 grid portrait photography, diagonal side profile, front view, [emotions]"

### Step 6: Character Sheet (4 angles)
- Use NanoBanana Pro with enhanced source image
- Prompt: "Give me four different views of this character"
- Store: `brands/{brand}/characters/{name}/sheet/`

### Step 7: Scene Variations (Campaign Content)
- Use NanoBanana Pro or Midjourney with source image
- Prompt: "[character] + [scenario]" — selfie cooking, holiday beach, professional headshot
- Virtual try-on: [character] + [clothing photo]
- Brand campaign: [character] + [brand visual language]

### Step 8: Lip Sync / Animation (Optional)
1. **Veo 3.1** — best quality, generates voice from text
2. **Enhancor V2 Lip Sync** — upload custom audio
3. **ElevenLabs** — voice cloning for consistent character voice

## Tools We Have (in Creative Studio)

| Tool | API/Access | Status |
|------|-----------|--------|
| NanoBanana Pro (Gemini) | Google API | ✅ Active |
| Enhancor V3 (Skin Fix) | enhancer.ai | ⬜ Need API key |
| Midjourney | Discord/API | ⬜ Need access |
| SeaDreams 3.0 | dreamina.capcut.com | ⬜ Free, web-based |
| Reeve v1 | preview.reeve.art | ⬜ Free, web-based |
| ElevenLabs | API | ⬜ Need key |
| Recraft V4 Pro | API | ✅ In Studio |

## Prompt Templates

### Base Portrait (Studio)
```
A portrait of a [ETHNICITY] [GENDER] in a professional studio photography setup 
with flash lighting and a white backdrop. High realism, 4K, shallow depth of field. 
[SKIN_DESC]: [complexion], visible pores, [imperfections]. 
[FACE_DESC]: [chin], [cheekbones], [nose], [lips]. 
[EYE_DESC]: [color], [shape], [expression]. 
[HAIR_DESC]: [color], [length], [style], [texture]. 
Age approximately [AGE]. Natural makeup, [CLOTHING_DESC].
```

### Consistent Variation (Midjourney)
```
Dutch angle, 28mm flash portrait, [SCENE_DESC], white studio photography
--sref [STYLE_REF_URL] --cref [CHARACTER_REF_URL] --sw 300
```

### Character Sheet
```
Four different views of this character: front view, 3/4 left, 3/4 right, profile. 
Same lighting, same outfit, white background, portrait photography.
```

## Automated Correction Loop (Notion-Driven)

### How It Works
1. Jenn reviews character in Notion Creative Review
2. Marks Status = "Needs Revision" + writes Feedback
3. Cron polls every 20 min (`character-correction.sh poll`)
4. Script parses feedback → maps to correction type
5. Regenerates via NanoBanana with updated prompt/refs
6. Uploads to Drive + registers new Notion page
7. Original page marked back to "Pending Review"
8. Learning logged to `learnings.jsonl`

### Correction Types (auto-detected from feedback text)
- `face_change` — face/skin/eyes/hair keywords
- `body_change` — body/proportions/ratio keywords
- `headgear_change` — helmet/visor/crown/sphere keywords
- `costume_change` — suit/outfit/bodysuit keywords
- `realism_fix` — cartoon/CG/3D/render keywords → adds photorealism anchors
- `material_fix` — chrome/gold/matte/metallic keywords
- `pose_change` — pose/angle/position keywords

### Commands
```bash
# Check what needs revision
character-correction.sh status

# Poll + auto-correct (or --dry-run to preview)
character-correction.sh poll [--dry-run]

# View correction history
character-correction.sh history [agent]

# Dispatch to agent for manual handling
character-correction.sh dispatch zenni|taoz|dreami

# Test feedback parsing
character-correction.sh parse "feedback text"
```

### Dispatch to Agents
- `dispatch zenni` — Zenni routes correction to appropriate agent
- `dispatch taoz` — Taoz verifies pipeline works correctly
- `dispatch dreami` — Dreami does visual QA on the feedback

## Feedback & Learning

### After every character creation:
```bash
# Log the result
echo '{"date":"'$(date -Iseconds)'","character":"NAME","model":"MODEL","rating":"1-10","feedback":"NOTES","prompt":"PROMPT_USED"}' >> ~/.openclaw/skills/character-design/learnings.jsonl
```

### What to capture:
- Which model produced the best base? (track per ethnicity/style)
- Did skin enhancement improve it? By how much?
- What prompt tweaks made the biggest difference?
- User feedback on the final result
- Time spent vs quality achieved

### Compound cycle:
1. Create character → log result
2. Nightly: review learnings.jsonl → extract patterns
3. Update this SKILL.md with new findings
4. Update prompt templates with improvements
5. Git commit with learning message

## Anti-Patterns
- ❌ Generating without references
- ❌ Using full-body shots for skin enhancement (must be close-up portrait)
- ❌ Skipping skin enhancement ("it looks fine" — it doesn't, enhance it)
- ❌ Not comparing across models (always compare 2-3)
- ❌ Forgetting to save the base image (this is your anchor for all future work)
- ❌ Changing the base image after creating variations (consistency lost)
