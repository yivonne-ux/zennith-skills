---
name: ai-influencer
description: AI Influencer Factory — end-to-end pipeline for creating, producing, and scaling AI character content across TikTok, Reels, Shorts. Face consistency, voice cloning, lip sync, auto-posting.
version: 2.0.0
agents: [dreami, scout, taoz, main]
---

# AI Influencer Factory — Zennith OS

## Mission
Build and scale AI influencer characters that produce viral short-form video content. First target: **Jade Oracle** (spiritual/QMDJ), then duplicate the pattern for any brand.

## The 10-Stage Production Pipeline

### Stage 1: CHARACTER DESIGN (Face Lock)
**Goal**: Create a consistent character face that looks identical across ALL content.

**Tools (by priority)**:
| Tool | Method | Cost | Best For |
|------|--------|------|----------|
| **Higgsfield Soul ID** | Upload 20+ photos → trains face model in 5min | $29/mo Pro | Best consistency, built-in video |
| **Flux + LoRA** | Train custom LoRA on SDXL/Flux | $0 (local) | Full control, open source |
| **IP-Adapter + Flux** | Reference image → identity preservation | $0 (local) | Quick, no training needed |
| **NanoBanana (Gemini)** | Our existing tool + style seeds | $0 | Already integrated |
| **APOB AI** | Face-lock for long-term branding | Free tier | Good free option |

**Process**:
1. Generate "Master" reference image (front-facing, high-res, clean lighting)
2. Lock face using Soul ID or LoRA training (20+ variations)
3. Generate body reference (outfit, style, setting)
4. Create face-ref library: 5 angles × 3 expressions × 2 lighting = 30 refs
5. Store in `workspace/data/characters/{character}/face-refs/`

### Stage 2: VOICE CREATION (Clone or Generate)
**Tools**:
| Tool | Method | Cost | Quality |
|------|--------|------|---------|
| **ElevenLabs** | Voice cloning from 30s sample | $5/mo starter | Best quality |
| **Hedra Voice Clone** | Record 3 lines → clone | Included in plan | Good, integrated |
| **OpenAI TTS** | Text-to-speech (no clone) | API pricing | Fast, decent |
| **Bark (open source)** | Local TTS with emotion | $0 | Good for prototyping |
| **XTTS v2 (Coqui)** | Open source voice cloning | $0 | Best free option |

**Process**:
1. Define voice personality (warm, mystical, authoritative, etc.)
2. Record or generate 30-60s sample audio
3. Clone voice → save voice ID
4. Generate test phrases → QA for naturalness
5. Store voice config in character profile

### Stage 3: SCRIPT WRITING (Hooks + Story)
**Formula (Seena Rez / Psychic Samira pattern)**:
1. **Hook** (0-3s): Pattern interrupt, question, bold claim
2. **Pain point** (3-8s): "You're stuck because..."
3. **Tease** (8-15s): "What if I told you..."
4. **Value** (15-45s): Actual insight/reading/tip
5. **CTA** (45-60s): "Comment your birth year" / "Link in bio"

**Tools**:
- Claude/GPT for script generation
- Dreami agent for brand-voice scripts
- Template library per content type (reading, tip, story, testimonial)

### Stage 4: TALKING HEAD VIDEO (Lip Sync)
**Tools (ranked by quality)**:
| Tool | Input | Quality | Cost | Speed |
|------|-------|---------|------|-------|
| **HeyGen** | Photo + script | Excellent | $0.50-0.99/min | Fast |
| **Hedra Character 3** | Image + audio | Excellent lip sync | $8-24/mo | Fast |
| **Higgsfield** | Soul ID + script | Good + face consistent | $29/mo | Medium |
| **D-ID** | Photo + text/audio | Good | $5.90/mo | Fast |
| **LivePortrait** (open) | Image + driver | Very high | $0 | GPU needed |
| **SadTalker** (open) | Image + audio | High | $0 | Moderate |
| **Wav2Lip** (open) | Video + audio | High lip sync | $0 | Fast |
| **MuseTalk** (open) | Face + audio | Real-time 30fps | $0 | Very fast |

**Decision**:
- Production quality → HeyGen or Hedra ($)
- Budget/volume → LivePortrait or SadTalker (free, local)
- Real-time → MuseTalk (free, 30fps)

### Stage 5: B-ROLL & SCENE GENERATION
**Tools**:
| Tool | Best For | Cost |
|------|----------|------|
| **Kling 3.0** | UGC-style, natural motion | ~$0.30/5s |
| **Wan 2.6** | Cinematic, moody | ~$0.20/5s |
| **Sora 2** | Hero content, highest quality | ~$1.00/5s |
| **Veo 3.1** | Photorealistic scenes | Via Higgsfield |
| **Our video-gen.sh** | Already integrated | Varies |

### Stage 6: VIDEO EDITING & POST-PRODUCTION
**Tools**:
- **video-forge.sh** (our existing tool): FFmpeg + WhisperX
- **Captions AI**: Auto-subtitles, eye-contact correction, dubbing
- **CapCut**: Templates, effects, transitions
- Auto-add: captions, music, transitions, hooks overlay

### Stage 7: BRAND VOICE CHECK
- Run `brand-voice-check.sh` on all copy
- Verify character stays in persona
- Check for off-brand language

### Stage 8: QUALITY REVIEW
- Spawn QA worker: `spawn-worker.sh qa "Review video for [brand]"`
- Check: face consistency, lip sync quality, audio clarity, CTA presence
- Auto-audit via `visual-audit.py`

### Stage 9: SCHEDULING & POSTING
**Tools**:
| Platform | Tool | Method |
|----------|------|--------|
| TikTok | TikTok Business API | Scheduled posts |
| Instagram | Meta Graph API | Reels scheduling |
| YouTube | YouTube Data API | Shorts upload |
| Cross-platform | Publer / Buffer | Multi-platform scheduling |
| Higgsfield Earn | Built-in posting | Direct to IG for earnings |

### Stage 10: ANALYTICS & OPTIMIZATION
- Track: views, likes, comments, shares, saves, watch time
- A/B test: hooks, CTAs, video styles, posting times
- Feed winners back into script templates
- Compound learnings → vault.db

## Cost Analysis (per video)

### Budget Path ($0-5/video)
- Face: Flux + LoRA (free)
- Voice: XTTS v2 or Bark (free)
- Lip sync: SadTalker or MuseTalk (free)
- B-roll: Kling via our video-gen.sh ($0.30)
- Editing: video-forge.sh (free)
- **Total: ~$0.30/video**

### Pro Path ($5-15/video)
- Face: Higgsfield Soul ID ($29/mo ÷ ~30 videos)
- Voice: ElevenLabs ($5/mo)
- Lip sync: HeyGen ($0.50/min)
- B-roll: Kling 3.0 ($0.30/5s × 3 clips)
- **Total: ~$5-10/video**

### Premium Path ($15-50/video)
- All Pro tools + Sora 2 for hero content
- Professional voice acting + clone
- Multi-language dubbing via HeyGen
- **Total: ~$15-50/video**

## API Integration Points

> See `references/api-integrations.md` for the full API table (HeyGen, Hedra, Higgsfield, D-ID, ElevenLabs, Kling, LivePortrait, SadTalker, MuseTalk).

## Open Source Stack (Full $0 Pipeline)

```
Character Face → Flux + IP-Adapter (local)
Voice Clone → XTTS v2 / Coqui (local)
Script → Claude Code CLI (free via subscription)
Lip Sync → LivePortrait or MuseTalk (local)
B-Roll → Wan 2.6 via video-gen.sh
Editing → video-forge.sh (FFmpeg)
Captions → WhisperX (local)
Posting → Platform APIs (free tier)
```

## Jade Oracle Application

| Element | Choice | Why |
|---------|--------|-----|
| Face | Existing jade face-refs + Soul ID training | Already have 30+ refs |
| Voice | Warm, mystical female voice clone | Matches QMDJ oracle persona |
| Script formula | Hook + birth year + QMDJ insight + CTA | Proven by Psychic Samira |
| Video style | Talking head + mystical B-roll + captions | TikTok spiritual niche |
| Posting | 3x/day TikTok + 1x/day Reels + 1x/day Shorts | Volume = discovery |
| Monetization | $1 intro reading → $97 full → $497 mentorship | Samira's exact funnel |

## File Paths
- Skill: `~/.openclaw/skills/ai-influencer/`
- Character data: `~/.openclaw/workspace/data/characters/`
- Video output: `~/.openclaw/workspace/data/videos/`
- Face refs: `~/.openclaw/workspace/data/characters/{char}/face-refs/`
- Voice profiles: `~/.openclaw/workspace/data/characters/{char}/voice/`
- Script templates: `~/.openclaw/skills/ai-influencer/data/templates/`

## Who Does What

| Agent | Role in Pipeline |
|-------|-----------------|
| **Dreami** | Scripts, creative direction, brand voice, ad copy |
| **Scout** | Research trends, competitor analysis, analytics |
| **Taoz** | Build/integrate tools, API connections, automation |
| **Zenni** | Strategy, scheduling, monetization, oversight |
