
## 15. Integration Map

### Skills This Uses
| Skill | Purpose |
|-------|---------|
| `nanobanana` | Image generation (Gemini Image API) — primary tool for all image gen |
| `character-lock` | Face consistency protocol (60% rule, anchor phrase) |
| `character-body-pairing` | Vibe matching system for wardrobe pairings |
| `ig-character-gen` | IG-specific generation rules and scene library |
| `ai-influencer` | Video pipeline (lip sync, B-roll, editing) |
| `video-gen` | Video generation (Kling 3.0 / Wan 2.6 / Sora 2) |
| `video-forge` | Post-production (FFmpeg + WhisperX) |
| `fast-iterate` | Copy/caption scoring (must score >= 8/10) |
| `auto-research` | Hook optimization and competitor intelligence |
| `brand-voice-check` | Mandatory before publishing any brand content |

### Skills This Feeds Into
| Skill | What Flows |
|-------|-----------|
| `content-repurpose` | IG content → TikTok, YT Shorts, Pinterest, Twitter |
| `campaign-translate` | EN content → ZH for Chinese diaspora audience |
| `ai-voiceover` | Reading scripts → narrated audio for video readings |
| `ads-meta` / `ads-tiktok` | Ad creatives and hooks for paid campaigns |

### Brand DNA
Always load before any Jade work: `~/.openclaw/brands/jade-oracle/DNA.json`

---

## 16. Agent Responsibilities

| Agent | Role in Pipeline |
|-------|-----------------|
| **Dreami** | Creative director — scripts, brand voice, ad copy, image prompt crafting, visual QA |
| **Taoz** | Builder — tool integration, API connections, pipeline automation, face lock engineering |
| **Iris** | Art director — visual QA, style consistency, character audit, brand palette enforcement |
| **Scout** | Research — competitor analysis, trend tracking, hashtag research, analytics |
| **Zenni** | Strategy — scheduling, monetization, content calendar, funnel optimization |

---

## 17. Cost Model

### Per-Image Cost
- NanoBanana (Gemini API): ~$0.01-0.03 per image
- Batch of 7 (weekly IG): ~$0.07-0.21

### Per-Video Cost

| Path | Tools | Cost/Video |
|------|-------|-----------|
| **Budget** | NanoBanana + LivePortrait + video-forge.sh | ~$0.30 |
| **Standard** | NanoBanana + Hedra + Kling B-roll | ~$5-10 |
| **Premium** | NanoBanana + HeyGen + Kling + Sora B-roll | ~$15-50 |

### Monthly Operating Cost (at scale)

| Item | Cost |
|------|------|
| Voice (Fish Audio) | $9.99/mo |
| Lip Sync (HeyGen/Hedra) | $24-99/mo |
| B-Roll (Kling via fal.ai) | ~$30/mo |
| VPS (Fly.dev) | $5/mo |
| Shopify | $39/mo |
| **Total** | **~$108-183/mo** |

### Break-Even
- At $1/reading: need 183 readings/month
- At 10K followers + 2% conversion = 200 readings/month
- **Target: 10K followers by month 3-6**

