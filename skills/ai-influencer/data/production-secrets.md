# AI Influencer Production Secrets
> Extracted from 9 YouTube tutorials + web research, March 2026

## Critical Production Tips

### Face Consistency (ranked by reliability)
1. **FluxGym LoRA training** — highest fidelity, 15-30 ref images, 1-3h training, portable .safetensors file
2. **OpenArt Character 2.0** — one ref image → Identity Lock, easiest setup
3. **Higgsfield Soul ID** — 20+ photos, 5min train, locked to their platform (4.5x markup vs direct)
4. **Kling Director Memory / Elements 3.0** — reference image library across shots
5. **FaceFusion** — post-process face swap to maintain consistency across poses

### Voice Cloning (ElevenLabs optimal settings)
- **Stability**: 45% (more expressive)
- **Similarity**: 90% (stay close to original)
- **Speech Enhancement**: 80%
- Record 30-60s clean sample, quiet room, natural pace

### Lip Sync Secrets
- Base video MUST have negative prompt: **"should not be talking"**
- Use **close-up headshot framing** for best lip sync accuracy
- AI movements are slower than natural — **speed up 1.2-1.5x** in post
- Hedra beats Runway and Kling in lip sync accuracy tests
- Kling native lip sync works best when combined with their own video gen

### Video Generation Tips
- 10s clip = ~5 min production time
- 1-minute video = ~30 min total pipeline
- Higgsfield zero-prompting = ~5 min for basic clip
- **Never use Higgsfield as wrapper** — it's 4.5x markup over direct Kling access
- Use Kling directly ($0.30/5s) or Wan via our video-gen.sh

### Content Formula (Psychic Samira Pattern)
```
0-3s:  HOOK (pattern interrupt, question, bold claim)
       "Your birth year reveals something nobody told you"
3-8s:  PAIN POINT ("You've been feeling stuck because...")
8-15s: TEASE ("What if I told you the stars aligned for you today")
15-45s: VALUE (actual QMDJ insight, reading, tip)
45-60s: CTA ("Comment your birth year" / "Link in bio for full reading")
```

### Posting Strategy
- **3x/day TikTok** (algorithm rewards volume)
- **1x/day IG Reels** (longer shelf life)
- **1x/day YT Shorts** (search discovery)
- Best times: 7-9am, 12-2pm, 7-10pm (target timezone)
- First 48h engagement determines viral potential

### Cost Optimization
| Direct Tool | Cost | vs Higgsfield Wrapper |
|------------|------|----------------------|
| Kling 3.0 direct | ~$0.30/5s | $1.35/5s via Higgsfield (4.5x) |
| Fish Audio voice | $9.99/mo | ElevenLabs $330/mo (33x) |
| Fabric lip sync | $0.15/sec | HeyGen $0.50/min (similar) |
| FluxGym LoRA | $2-5 one-time | Soul ID $29/mo ongoing |

### Pipeline Speed (from script to posted)
- **Budget (open source)**: ~2h per 60s video
- **Pro (paid APIs)**: ~30min per 60s video
- **Factory (automated)**: ~10min per 60s video (with automation scripts)

### Warnings
- Higgsfield has **scam/fraud allegations** documented on GitHub — vet before committing
- Lip sync is STILL the weakest link across ALL pipelines (2026)
- 89% of marketers say they won't work with virtual influencers — use for OWNED brands only
- AI-generated content must be disclosed per FTC/platform rules in some jurisdictions
