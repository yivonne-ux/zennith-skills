# Voice Profiles for All 14 Brands

## Brand Voice Matching

Each brand gets a voice profile stored at `~/.openclaw/brands/{brand}/voice-profile.json`. This file defines the TTS engine, voice ID, style descriptors, pacing, and emphasis words for each language.

### Profile Schema

```json
{
  "brand": "mirra",
  "voice_en": {
    "engine": "elevenlabs",
    "voice_id": "pNInz6obpgDQGcFmaJgB",
    "style": "warm, friendly, young female",
    "stability": 0.5,
    "similarity_boost": 0.8
  },
  "voice_bm": {
    "engine": "google",
    "voice_id": "ms-MY-Wavenet-A",
    "style": "casual, approachable"
  },
  "voice_zh": {
    "engine": "google",
    "voice_id": "cmn-CN-Wavenet-A",
    "style": "energetic, modern"
  },
  "pace": "medium",
  "tone": "conversational",
  "emphasis_words": ["weight management", "calorie-controlled", "fresh", "delivered"],
  "pronunciation_overrides": {
    "Mirra": "MEER-rah",
    "Pinxin": "PIN-shin"
  }
}
```

### F&B Brands — Warm, Appetizing, Energetic

| Brand | EN Voice | BM Voice | ZH Voice | Tone | Pace |
|-------|----------|----------|----------|------|------|
| **mirra** (weight management meal subscription) | ElevenLabs: warm young female | Google: ms-MY-Wavenet-A | Google: cmn-CN-Wavenet-A | Conversational, motivating, friendly | Medium |
| **pinxin-vegan** | ElevenLabs: bold confident female, Malaysian accent | Google: ms-MY-Wavenet-A | Google: cmn-CN-Wavenet-C | Bold, confident, flavour-obsessed, Malaysian-proud | Medium |
| **wholey-wonder** | ElevenLabs: bright young female | Google: ms-MY-Wavenet-C | Google: cmn-CN-Wavenet-A | Playful, energetic, wholesome | Medium-fast |
| **gaia-eats** | ElevenLabs: friendly mid-female | Google: ms-MY-Wavenet-A | Google: cmn-CN-Wavenet-D | Appetizing, inviting, warm | Medium |
| **rasaya** | ElevenLabs: rich warm female | Google: ms-MY-Wavenet-D | Google: cmn-CN-Wavenet-C | Elegant, luxurious, soothing | Slow-medium |

### Wellness Brands — Calm, Trustworthy, Professional

| Brand | EN Voice | BM Voice | ZH Voice | Tone | Pace |
|-------|----------|----------|----------|------|------|
| **dr-stan** | ElevenLabs: authoritative mid-male | Google: ms-MY-Wavenet-B | Google: cmn-CN-Wavenet-B | Professional, trustworthy, knowledgeable | Medium-slow |
| **serein** | ElevenLabs: gentle soft female | Google: ms-MY-Wavenet-A | Google: cmn-CN-Wavenet-A | Serene, calming, mindful | Slow |
| **gaia-supplements** | ElevenLabs: clear confident female | Google: ms-MY-Wavenet-C | Google: cmn-CN-Wavenet-D | Clean, science-backed, reassuring | Medium |

### Creative Brands — Modern, Artistic, Confident

| Brand | EN Voice | BM Voice | ZH Voice | Tone | Pace |
|-------|----------|----------|----------|------|------|
| **gaia-print** | ElevenLabs: creative young male | Google: ms-MY-Wavenet-B | Google: cmn-CN-Wavenet-B | Artistic, contemporary, bold | Medium-fast |
| **iris** | ElevenLabs: stylish confident female | Google: ms-MY-Wavenet-C | Google: cmn-CN-Wavenet-A | Visionary, sleek, creative | Medium |

### Tech/Meta Brands — Clear, Articulate, Authoritative

| Brand | EN Voice | BM Voice | ZH Voice | Tone | Pace |
|-------|----------|----------|----------|------|------|
| **gaia-os** | ElevenLabs: clear articulate male | Google: ms-MY-Wavenet-B | Google: cmn-CN-Wavenet-B | Technical, authoritative, precise | Medium |
| **gaia-learn** | ElevenLabs: warm teacher female | Google: ms-MY-Wavenet-A | Google: cmn-CN-Wavenet-A | Encouraging, patient, clear | Medium-slow |
| **gaia-recipes** | ElevenLabs: friendly instructional female | Google: ms-MY-Wavenet-A | Google: cmn-CN-Wavenet-C | Instructional, cheerful, step-by-step | Medium |

### Character Brands — Mystical, Wise, Character-Consistent

| Brand | EN Voice | BM Voice | ZH Voice | Tone | Pace |
|-------|----------|----------|----------|------|------|
| **jade-oracle** | ElevenLabs: mystical wise female (custom clone) | Google: ms-MY-Wavenet-D | Google: cmn-CN-Wavenet-A | Ancient wisdom, enigmatic, poetic | Slow, deliberate |

### Voice Selection Decision Tree

```
Is this hero/paid ad content?
├── YES → Use ElevenLabs (best quality)
│   └── Does brand have a cloned voice?
│       ├── YES → Use cloned voice for consistency
│       └── NO → Use recommended stock voice from profile
└── NO → Is this a draft or internal review?
    ├── YES → Use Edge TTS (free, fast)
    └── NO → What language?
        ├── EN → OpenAI TTS or ElevenLabs
        ├── BM → Google Cloud TTS WaveNet (best Malay quality)
        └── ZH → Google Cloud TTS WaveNet (best Mandarin quality)
```

### Pinxin Vegan Voice Profile (Example)

```json
{
  "brand": "pinxin-vegan",
  "voice_en": {
    "engine": "elevenlabs",
    "voice_id": "pNInz6obpgDQGcFmaJgB",
    "style": "bold, confident, Malaysian-accented female",
    "stability": 0.45,
    "similarity_boost": 0.75
  },
  "voice_bm": {
    "engine": "google",
    "voice_id": "ms-MY-Wavenet-A",
    "style": "bold casual Manglish energy"
  },
  "voice_zh": {
    "engine": "google",
    "voice_id": "cmn-CN-Wavenet-C",
    "style": "direct, flavour-forward, street-smart"
  },
  "pace": "medium",
  "tone": "bold-confident",
  "emphasis_words": ["bold", "flavour", "plant-based", "Malaysian", "zero compromise", "vegan"],
  "pronunciation_overrides": {
    "Pinxin": "PIN-shin",
    "nasi lemak": "NAH-see leh-MAHK",
    "rendang": "ren-DAHNG",
    "char kway teow": "char KWAY tee-OW",
    "sambal": "SAHM-bahl"
  }
}
```
