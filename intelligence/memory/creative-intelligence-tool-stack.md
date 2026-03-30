---
name: Video production tool stack — complete inventory March 2026
description: Every tool installed and available for video production. What each does, when to use it, API endpoints. Includes fal.ai models, local tools, and planned additions.
type: reference
---

## INSTALLED & VERIFIED

### Image Generation (fal.ai)
| Model | Endpoint | Use case | Cost |
|-------|----------|----------|------|
| NANO Banana Pro | `fal-ai/nano-banana-pro` | Image generation from text | $0.08/img |
| NANO Banana Pro Edit | `fal-ai/nano-banana-pro/edit` | Image edit with reference(s) | $0.15/img |
| FLUX Pro Kontext | `fal-ai/flux-pro/kontext` | Context-aware image edit | ~$0.05/img |
| FLUX Pro Kontext Max | `fal-ai/flux-pro/kontext/max` | Best context edit (highest quality) | ~$0.10/img |

### Video Generation (fal.ai + Google)
| Model | Endpoint | Use case | Cost |
|-------|----------|----------|------|
| Kling 3.0 Standard | `fal-ai/kling-video/v3/standard/image-to-video` | I2V — outputs SQUARE | $0.05/5s |
| Kling 3.0 Pro | `fal-ai/kling-video/v3/pro/image-to-video` | I2V — native 9:16, highest quality | $0.33/5s |
| Veo 3.0 | `veo-3.0-generate-001` (google-genai) | I2V — cinematic, 8s, 720x1280 | ~$0.05/8s |

### Post-Processing (fal.ai)
| Model | Endpoint | Use case |
|-------|----------|----------|
| Real-ESRGAN | `fal-ai/esrgan` | Image upscaling (2x-4x) |
| Video Upscaler | `fal-ai/video-upscaler` | Video upscaling (AI per-frame) |
| BiRefNet v2 | `fal-ai/birefnet/v2` | Background removal (best for hair/edges) |
| Face Swap | `fal-ai/face-swap` | Swap face between images |

### Analysis (Google)
| Model | Use case |
|-------|----------|
| Gemini 2.0 Flash | Vision analysis, scoring, forensic, QC audit |
| Gemini Vision | Multi-image comparison, reference categorization |

### Local Tools (Python)
| Tool | Version | Use case |
|------|---------|----------|
| FFmpeg | 6.0 | Video processing, concat, grain, color grade, encoding |
| Pillow | — | Image manipulation, resize, logo stamp, grain |
| OpenCV | 4.13.0 | Face detection, scene analysis, video frame extraction |
| librosa | 0.11.0 | BPM detection, beat-sync, audio analysis |
| pydub | — | Audio mixing, SFX layering, volume control, fade |
| Whisper | — | Auto-transcription, subtitle generation |
| Playwright | — | Browser automation, scraping, screenshots |
| yt-dlp | — | Video download (TikTok, IG, YouTube) |
| instaloader | 4.15 | Instagram scraping |
| pyktok | — | TikTok scraping |
| Remotion | 4.x | React-based video composition, typography, animation |

### Infrastructure
| Tool | Use case |
|------|----------|
| gstack /browse | Headless Chromium with cookie auth (IG/XHS scraping) |
| npx serve | Local file server for Remotion |
| Bun | Runtime for gstack |

## WHEN TO USE WHAT

### Character consistency problem?
→ **Face Swap** (`fal-ai/face-swap`): Generate scene with any face → swap to character lock
→ Better than trying to prompt NANO for same face every time

### Background copying from reference?
→ **BiRefNet** (`fal-ai/birefnet/v2`): Remove reference background → composite character onto OUR setting
→ Or: generate with FLUX Kontext Max which has better context separation

### 720p video quality?
→ **Video Upscaler** (`fal-ai/video-upscaler`): AI upscale every Kling output
→ Or: **Real-ESRGAN** (`fal-ai/esrgan`) for image upscaling before I2V

### Better image editing than NANO?
→ **FLUX Kontext Max** (`fal-ai/flux-pro/kontext/max`): Better at keeping angle while changing outfit/person/background
→ Try this INSTEAD of NANO edit when NANO copies too much from reference

### Auto-captions needed?
→ **Whisper**: Transcribe audio → generate subtitle file → burn into video

### Face verification in QC?
→ **OpenCV**: `cv2.CascadeClassifier` for face detection, verify face exists and is consistent

## PLANNED / FUTURE
- ComfyUI/RunningHub workflows — chain models for higher quality
- Custom Mirra 3D LUT — replace FFmpeg colorbalance
- Suno BGM generation — custom brand-matched music
- ElevenLabs voiceover — needs billing fix
- Character LoRA training — perfect consistency without face swap
