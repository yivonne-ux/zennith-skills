---
name: persona
description: AI avatar/influencer generation pipeline. Creates consistent virtual characters with persistent profiles, animates them via Kling I2V, generates speech via ElevenLabs, and produces full UGC-style content. Used by Daedalus (Art Director) and Calliope (Creative Director).
---

# Persona — AI Avatar & Influencer Pipeline

Create, animate, voice, and produce content starring AI virtual influencers. Each persona is a persistent character with locked visual traits, a brand affiliation, and optional voice clone. The pipeline unifies NanoBanana (character images), Kling AI (I2V animation), and ElevenLabs (TTS/voice cloning) into a single CLI.

## Commands

### Create a Persona
```bash
bash scripts/persona-gen.sh create \
  --name "Maya" \
  --brand gaia-eats \
  --age 28 \
  --gender female \
  --ethnicity malay \
  --style casual \
  --vibe friendly
```

Creates a character sheet via NanoBanana Pro and saves a persistent profile to `personas/Maya.json`.

### Animate a Persona
```bash
bash scripts/persona-gen.sh animate \
  --persona Maya \
  --scene "cooking vegan rendang in bright kitchen" \
  --duration 5 \
  --ratio 9:16
```

Generates an I2V video via Kling AI using the persona's reference image and full character description.

### Generate Voice
```bash
bash scripts/persona-gen.sh voice \
  --persona Maya \
  --text "Hey guys! So I just discovered this amazing vegan rendang paste..." \
  --voice-id <elevenlabs_voice_id>
```

Generates speech audio via ElevenLabs TTS API. Optionally clone a voice with `--clone --sample <audio_file>`.

### Full Production Pipeline
```bash
bash scripts/persona-gen.sh produce \
  --persona Maya \
  --script path/to/script.txt \
  --type ugc \
  --brand gaia-eats
```

Reads a multi-scene script file, generates voice + video for each scene, assembles the final cut.

#### Script Format
```
SCENE: Maya in bright kitchen, holding GAIA rendang paste box, smiling at camera
VOICE: Hey guys! So I just discovered this amazing vegan rendang paste from GAIA Eats...
DURATION: 5
TYPE: ugc

SCENE: Close-up of Maya opening the paste packet, pouring into pan
VOICE: The texture is so rich, and it smells incredible...
DURATION: 5
TYPE: aroll
```

### Generate a Selfie (NEW)
```bash
bash scripts/persona-gen.sh selfie Maya "cooking rendang in a cozy kitchen" --mood cozy --brand gaia-eats
```

Places the character in a scene while maintaining exact character consistency (locked facial features, wardrobe — only the scene changes). Uses NanoBanana Pro for best quality. Loads Brand DNA mood preset for lighting, atmosphere, props, color grade.

Output: `~/.openclaw/skills/persona/selfies/{name}/selfie-{timestamp}.png`

### Post to WhatsApp/Social (NEW)
```bash
# Post to Jenn's DM
bash scripts/persona-gen.sh post Maya "Masak rendang hari ni!" --image /path/to/selfie.png

# Post to a WhatsApp group
bash scripts/persona-gen.sh post Maya "Weekend vibes" --image /path/to/selfie.png --to "120363391028988812@g.us"
```

Posts an image + caption via `openclaw message send` (with `openclaw agent --deliver` fallback). Logs to post-log.jsonl.

### List All Personas
```bash
bash scripts/persona-gen.sh list
```

### Show Persona Details
```bash
bash scripts/persona-gen.sh show Maya
```

## Integration Points

| Tool | Used For | Script |
|------|----------|--------|
| NanoBanana Pro | Character sheet generation | `~/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh` |
| Kling AI 3.0 | Image-to-video animation | `~/.openclaw/skills/art-director/scripts/kling-video.sh` |
| ElevenLabs | Text-to-speech, voice cloning | Direct API calls (ELEVENLABS_API_KEY) |
| Brand DNA | Visual style + voice tone | `~/.openclaw/brands/{brand}/DNA.json` |

## Data

- Persona profiles: `~/.openclaw/skills/persona/personas/{name}.json`
- Generated videos: `~/.openclaw/workspace/data/videos/{brand}/`
- Generated audio: `~/.openclaw/workspace/data/audio/{brand}/`
- Character images: `~/.openclaw/workspace/data/characters/{brand}/`
- Logs: `~/.openclaw/logs/persona.log`

## API Keys Required

- `GEMINI_API_KEY` — NanoBanana character generation
- `ELEVENLABS_API_KEY` — Voice synthesis and cloning
- Kling credentials in `~/.openclaw/workspace/ops/.kling-env`

## Used By

- **Iris (Social Voice)** — lifestyle selfies, social posting, influencer content
- **Daedalus (Art Director)** — visual generation, character consistency, animation
- **Calliope (Creative Director)** — campaign personas, brand ambassadors, UGC content planning

## Notes

- macOS Bash 3.2 compatible (no declare -A, no timeout, no ${var,,})
- Character consistency: full description is injected into every prompt
- Kling I2V is async: script polls for completion (up to 15 min)
- Persona profiles persist across sessions as JSON files
- Brand DNA is loaded for visual style enrichment on every generation
- Selfie logs: `~/.openclaw/skills/persona/selfies/{name}/selfie-log.jsonl`
- Post logs: `~/.openclaw/skills/persona/selfies/{name}/post-log.jsonl`
- Mood presets: `~/.openclaw/brands/{brand}/moods/{mood}.json`
