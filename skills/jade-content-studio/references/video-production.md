## 9. Video Production

### 9.1 Talking Head Video (Lip Sync)

| Tool | Quality | Cost | Best For |
|------|---------|------|----------|
| **HeyGen** | Excellent | $0.50-0.99/min | Production quality |
| **Hedra Character 3** | Excellent lip sync | $8-24/mo | Volume production |
| **LivePortrait** (open source) | Very high | $0 (GPU needed) | Budget/volume |
| **MuseTalk** (open source) | Real-time 30fps | $0 | Real-time needs |

### 9.2 B-Roll & Scene Generation

| Tool | Best For | Cost |
|------|----------|------|
| **Kling 3.0** with `elements` | Face-locked video, UGC-style | ~$0.30/5s |
| **Wan 2.6** | Cinematic, moody B-roll | ~$0.20/5s |
| **Sora 2** | Hero content, highest quality | ~$1.00/5s |

### 9.3 Video Production Rules (From Production)

- **Kling 3.0**: Use `frontal_image_url` + `reference_image_urls` for face lock (NOT `image_url`)
- **Sora**: Avoid for feminine/body content (moderation blocks frequently)
- **Sora**: Always download in poll loop — URLs expire in 1 hour
- **fal.ai**: Check balance before batch runs
- **Post-production**: Use `video-forge.sh` (FFmpeg + WhisperX) for captions, cuts, music

### 9.4 Voice Clone

- **ElevenLabs** for best quality ($5/mo)
- **Fish Audio** for budget ($9.99/mo, 200 min)
- Voice personality: warm, slightly husky, measured pace, mystical but not breathy
- Slight East Asian lilt, English fluent
- Test phrases: "Your birth year reveals...", "The stars have aligned...", "Welcome to your reading..."

### 9.5 Video Assembly Pipeline

```
Script → Voice (Fish Audio / ElevenLabs)
       → Talking Head (HeyGen / Hedra with locked face ref)
       → B-Roll (Kling 3.0 with face elements)
       → Edit (video-forge.sh: merge, captions, music, transitions)
       → QA (face consistency, lip sync, brand voice)
       → Export (9:16, platform-optimized)
```
