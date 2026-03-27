---
name: ai-voiceover
description: |
  TRIGGER: "voiceover", "voice generation", "TTS", "text-to-speech", "narration", "audio for video", "voice for ad"
  ANTI-TRIGGER: voice cloning ethics questions, singing/music generation, speech-to-text transcription
  OUTCOME: Brand-matched AI voiceover audio file (.mp3/.wav) ready for video mixing or standalone use
metadata:
  openclaw:
    scope: audio-production
agents: [dreami, taoz]
version: 1.1.0
---

# AI Voiceover

Generate natural-sounding voiceovers for video ads and content using AI TTS APIs. Supports English (EN), Bahasa Malaysia (BM), and Mandarin Chinese (ZH) with brand-matched voice profiles across all 14 Zennith brands.

**Agents:** Dreami (scripts, voice tone, triggers generation) | Taoz (pipeline, voice profiles, VideoForge integration)

---

## Workflow SOP

```
INPUT:  Script text + brand name + language + [optional: video file to sync to]

STEP 1: Load brand voice profile
        → Read ~/.openclaw/brands/{brand}/voice-profile.json
        → Load references/voice-profiles.md for brand voice tables and selection tree
        → If missing, use default voice for brand category (F&B/wellness/creative/tech/character)

STEP 2: Select engine based on language and quality needs
        → Hero content? → ElevenLabs
        → BM or ZH? → Google Cloud TTS WaveNet
        → Draft? → Edge TTS (free)
        → Override with --engine flag if specified
        → Load references/platform-requirements.md for engine API details

STEP 3: Pre-process script
        → Load references/language-specs.md for SSML markup, pronunciation guides, script structure
        → Inject SSML markup for pauses, emphasis, pronunciation
        → Apply pronunciation overrides from voice profile
        → Validate script length vs target duration
        → Estimate: ~150 words/min (EN), ~130 words/min (BM), ~160 chars/min (ZH)

STEP 4: Generate voiceover audio
        → Call selected TTS engine API
        → Save raw audio to ~/.openclaw/workspace/data/audio/{brand}/
        → Filename: {brand}_{lang}_{timestamp}.mp3

STEP 5: Post-process audio
        → Normalize volume to -16 LUFS (broadcast standard)
        → Trim silence from start/end (threshold: -40dB)
        → Apply gentle compression if needed (ratio 2:1, threshold -20dB)
        → ffmpeg -i raw.mp3 -af "loudnorm=I=-16:TP=-1.5:LRA=11,silenceremove=1:0:-40dB" output.mp3

STEP 6: If video provided → sync audio to video timing
        → Calculate video duration, check voiceover fits
        → If too long: flag for script trimming OR speed up 1.1x max
        → If too short: pad with silence or let video breathe
        → Hand off to VideoForge for final mix

STEP 7: Quality check
        → Pace: natural, not robotic?
        → Clarity: all words intelligible?
        → Brand match: tone matches brand DNA?
        → Technical: no artifacts, pops, or clipping?
        → Duration: fits target length?

STEP 8: Export
        → Audio-only: .mp3 (320kbps) + .wav (48kHz/16bit) to data/audio/{brand}/
        → Video mix: pass to VideoForge → bash scripts/video-forge.sh music --track vo.mp3 --duck --video input.mp4
        → Metadata: save generation params to {output}.json sidecar

OUTPUT: .mp3/.wav audio file at ~/.openclaw/workspace/data/audio/{brand}/
        Optionally: mixed video via VideoForge at data/videos/{brand}/
```

---

## CLI Usage

```bash
# Generate voiceover from inline script
bash scripts/ai-voiceover.sh generate \
  --brand mirra --lang en \
  --script "Your weight management meals, delivered fresh. Order now."

# Specify engine explicitly
bash scripts/ai-voiceover.sh generate \
  --brand mirra --lang en --engine elevenlabs \
  --script "Your weight management meals, delivered fresh."

# Generate from script file
bash scripts/ai-voiceover.sh generate \
  --brand pinxin-vegan --lang bm \
  --script-file ~/.openclaw/workspace/data/scripts/pinxin-ad-bm.txt

# Mix voiceover with video
bash scripts/ai-voiceover.sh mix \
  --brand mirra --lang en \
  --script "Your weight management meals, delivered fresh." \
  --video ~/.openclaw/workspace/data/videos/mirra/hero-video.mp4

# Mix with background music ducking
bash scripts/ai-voiceover.sh mix \
  --brand mirra --lang en \
  --script-file ad-script.txt --video hero-video.mp4 \
  --bgm ~/.openclaw/workspace/data/audio/music/upbeat-1.mp3

# Batch — all language variants at once
bash scripts/ai-voiceover.sh batch \
  --brand mirra --script "Your weight management meals, delivered fresh." \
  --langs en,bm,zh

# Preview — quick draft with Edge TTS (free)
bash scripts/ai-voiceover.sh preview --script "Quick test." --lang en

# Clone — create custom brand voice from audio sample
bash scripts/ai-voiceover.sh clone \
  --brand mirra --sample voice-sample.mp3 --name "mirra-voice-1"

# List available voices and profiles
bash scripts/ai-voiceover.sh list-voices --engine elevenlabs
bash scripts/ai-voiceover.sh list-profiles

# Estimate duration from script
bash scripts/ai-voiceover.sh estimate --script "Your weight management meals." --lang en
```

---

## Output Locations

| Type | Path |
|------|------|
| Raw audio | `~/.openclaw/workspace/data/audio/{brand}/{brand}_{lang}_{timestamp}.mp3` |
| Processed audio | `~/.openclaw/workspace/data/audio/{brand}/{brand}_{lang}_{timestamp}_final.mp3` |
| Mixed video | `~/.openclaw/workspace/data/videos/{brand}/{brand}_{lang}_{timestamp}_vo.mp4` |
| Subtitles | `~/.openclaw/workspace/data/audio/{brand}/{brand}_{lang}_{timestamp}.vtt` |
| Metadata | `~/.openclaw/workspace/data/audio/{brand}/{brand}_{lang}_{timestamp}.json` |
| Voice clones | `~/.openclaw/workspace/data/audio/clones/{brand}/{name}/` |

---

## References (loaded on demand)

| File | Content | Load During |
|------|---------|-------------|
| `references/voice-profiles.md` | Voice profiles for all 14 brands, selection decision tree, example profiles | Step 1 |
| `references/language-specs.md` | Script writing rules, SSML markup, pronunciation guide, ad script structure | Step 3 |
| `references/platform-requirements.md` | Engine comparison, API calls, sample scripts, templates, VideoForge integration, quality checklist, dependencies | Steps 2, 4, 6, 7 |
