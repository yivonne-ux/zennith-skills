---
name: ai-voiceover
description: AI voice generation for video ads, social content, and brand audio. Multi-language (EN/BM/ZH), brand-matched voice profiles, and integration with VideoForge for final mix.
agents: [dreami, taoz]
version: 1.0.0
---

# AI Voiceover

Generate natural-sounding voiceovers for video ads and content using AI TTS (Text-to-Speech) APIs. No recording studio needed. Supports English (EN), Bahasa Malaysia (BM), and Mandarin Chinese (ZH) with brand-matched voice profiles across all 14 Zennith brands.

## Who Uses This

- **Dreami (Creative Director)** — writes voiceover scripts, selects voice tone/mood, triggers generation as part of ad creative pipeline
- **Taoz (CTO/Builder)** — builds and maintains the TTS pipeline, manages voice profiles, integrates with VideoForge

---

## 2. Voice Engine Options

| Engine | Quality | Languages | Cost | Cloning | Best For |
|--------|---------|-----------|------|---------|----------|
| ElevenLabs | Excellent | EN, multilingual (29 langs) | $5-22/mo | Yes (Instant + Professional) | Premium ads, brand voice, hero content |
| Google Cloud TTS | Very Good | EN, BM (ms-MY), ZH (cmn-CN) | ~$4/1M chars (Standard), ~$16/1M chars (WaveNet) | No | Bulk content, BM/ZH quality, multilingual |
| OpenAI TTS | Very Good | EN, multilingual | $15/1M chars (tts-1), $30/1M chars (tts-1-hd) | No | Quick drafts, natural English |
| Edge TTS | Good | EN, BM, ZH (50+ langs) | Free | No | Prototyping, high volume, zero-cost drafts |
| Coqui/XTTS | Good | Multilingual (16 langs) | Free (local, requires GPU) | Yes (voice cloning from 6s sample) | Custom voices, privacy-sensitive, offline |

### Recommendations

- **Hero content / paid ads**: ElevenLabs — best naturalness, emotion control, voice cloning for consistent brand voice
- **Bulk / draft content**: Edge TTS — free, fast, good enough for internal reviews and drafts
- **BM / ZH quality**: Google Cloud TTS WaveNet — best Malay and Mandarin voices available
- **Quick English drafts**: OpenAI TTS — simple API, natural output, fast turnaround
- **Privacy / offline**: Coqui XTTS — runs locally, no data leaves the machine

---

## 3. Voice Profile System

### Brand Voice Matching

Each brand gets a voice profile stored at `~/.openclaw/brands/{brand}/voice-profile.json`. This file defines the TTS engine, voice ID, style descriptors, pacing, and emphasis words for each language.

#### Profile Schema

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

### Voice Profiles for All 14 Brands

#### F&B Brands — Warm, Appetizing, Energetic

| Brand | EN Voice | BM Voice | ZH Voice | Tone | Pace |
|-------|----------|----------|----------|------|------|
| **mirra** (weight management meal subscription) | ElevenLabs: warm young female | Google: ms-MY-Wavenet-A | Google: cmn-CN-Wavenet-A | Conversational, motivating, friendly | Medium |
| **pinxin-vegan** | ElevenLabs: bold confident female, Malaysian accent | Google: ms-MY-Wavenet-A | Google: cmn-CN-Wavenet-C | Bold, confident, flavour-obsessed, Malaysian-proud | Medium |
| **wholey-wonder** | ElevenLabs: bright young female | Google: ms-MY-Wavenet-C | Google: cmn-CN-Wavenet-A | Playful, energetic, wholesome | Medium-fast |
| **gaia-eats** | ElevenLabs: friendly mid-female | Google: ms-MY-Wavenet-A | Google: cmn-CN-Wavenet-D | Appetizing, inviting, warm | Medium |
| **rasaya** | ElevenLabs: rich warm female | Google: ms-MY-Wavenet-D | Google: cmn-CN-Wavenet-C | Elegant, luxurious, soothing | Slow-medium |

#### Wellness Brands — Calm, Trustworthy, Professional

| Brand | EN Voice | BM Voice | ZH Voice | Tone | Pace |
|-------|----------|----------|----------|------|------|
| **dr-stan** | ElevenLabs: authoritative mid-male | Google: ms-MY-Wavenet-B | Google: cmn-CN-Wavenet-B | Professional, trustworthy, knowledgeable | Medium-slow |
| **serein** | ElevenLabs: gentle soft female | Google: ms-MY-Wavenet-A | Google: cmn-CN-Wavenet-A | Serene, calming, mindful | Slow |
| **gaia-supplements** | ElevenLabs: clear confident female | Google: ms-MY-Wavenet-C | Google: cmn-CN-Wavenet-D | Clean, science-backed, reassuring | Medium |

#### Creative Brands — Modern, Artistic, Confident

| Brand | EN Voice | BM Voice | ZH Voice | Tone | Pace |
|-------|----------|----------|----------|------|------|
| **gaia-print** | ElevenLabs: creative young male | Google: ms-MY-Wavenet-B | Google: cmn-CN-Wavenet-B | Artistic, contemporary, bold | Medium-fast |
| **iris** | ElevenLabs: stylish confident female | Google: ms-MY-Wavenet-C | Google: cmn-CN-Wavenet-A | Visionary, sleek, creative | Medium |

#### Tech/Meta Brands — Clear, Articulate, Authoritative

| Brand | EN Voice | BM Voice | ZH Voice | Tone | Pace |
|-------|----------|----------|----------|------|------|
| **gaia-os** | ElevenLabs: clear articulate male | Google: ms-MY-Wavenet-B | Google: cmn-CN-Wavenet-B | Technical, authoritative, precise | Medium |
| **gaia-learn** | ElevenLabs: warm teacher female | Google: ms-MY-Wavenet-A | Google: cmn-CN-Wavenet-A | Encouraging, patient, clear | Medium-slow |
| **gaia-recipes** | ElevenLabs: friendly instructional female | Google: ms-MY-Wavenet-A | Google: cmn-CN-Wavenet-C | Instructional, cheerful, step-by-step | Medium |

#### Character Brands — Mystical, Wise, Character-Consistent

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

---

## 4. Script Writing SOP

### Golden Rules for AI Voiceover Scripts

1. **Sentence length**: 8-15 words per sentence for natural pacing. Shorter = punchier (ads). Longer = storytelling.
2. **Punctuation controls pacing**:
   - Comma `,` = short pause (~0.3s)
   - Period `.` = medium pause (~0.6s)
   - Ellipsis `...` = dramatic pause (~1.0s)
   - Em dash `—` = abrupt break
   - Exclamation `!` = energy boost
3. **CAPS for emphasis**: "This is NOT your average bento" — TTS engines stress capitalized words.
4. **Numbers**: Write out numbers under 10. Use digits for prices: "RM15.90" not "fifteen ringgit ninety sen."
5. **Pronunciation guides**: Add inline guides for names the engine might mispronounce.

### SSML Markup Reference

SSML (Speech Synthesis Markup Language) gives fine-grained control over TTS output. Supported by Google Cloud TTS and ElevenLabs.

```xml
<!-- Basic SSML wrapper -->
<speak>
  <!-- Pause: insert explicit break -->
  Welcome to Mirra. <break time="500ms"/> Your weight management meals, delivered fresh daily.

  <!-- Emphasis: stress a word -->
  This is <emphasis level="strong">not</emphasis> your average meal prep.

  <!-- Prosody: control rate, pitch, volume -->
  <prosody rate="slow" pitch="+2st">Take a moment. Breathe.</prosody>
  <prosody rate="fast" volume="loud">Order now and save 20%!</prosody>

  <!-- Say-as: control number/date reading -->
  Only <say-as interpret-as="currency" language="ms-MY">RM15.90</say-as> per bento.
  Available from <say-as interpret-as="date" format="dm">15 March</say-as>.

  <!-- Phoneme: force pronunciation -->
  <phoneme alphabet="ipa" ph="ˈmɪərɑː">Mirra</phoneme> weight management meals are here.

  <!-- Sub: substitution for abbreviations -->
  Order via <sub alias="WhatsApp">WA</sub> today.

  <!-- Audio: insert sound effect (Google Cloud TTS) -->
  <audio src="https://example.com/ding.mp3">notification sound</audio>
</speak>
```

### Pronunciation Guide for Common Brand Terms

| Term | Pronunciation | IPA | Engine Note |
|------|--------------|-----|-------------|
| Mirra | MEER-rah | ˈmɪərɑː | ElevenLabs handles well; add phoneme for Google |
| Pinxin | PIN-shin | ˈpɪnʃɪn | Must override — engines default to "pin-kshin" |
| Rasaya | rah-SAH-yah | rɑːˈsɑːjɑː | Stress on second syllable |
| Serein | seh-RAIN | sɛˈɹeɪn | French origin, engines often miss |
| Wholey Wonder | HOLE-ee WUN-der | ˈhoʊli ˈwʌndɚ | Natural, no override needed |
| Gaia | GUY-uh | ˈɡaɪ.ə | Engines handle correctly |
| Jade Oracle | JAYD OR-uh-kul | dʒeɪd ˈɒɹəkəl | Natural, no override needed |
| Dr. Stan | Doctor Stan | — | Use `<sub alias="Doctor Stan">Dr. Stan</sub>` |
| Bento | BEN-toh | ˈbɛntoʊ | Natural in most engines |
| Nasi lemak | NAH-see leh-MAHK | ˈnɑːsi ləˈmɑːk | Google BM handles natively; add phoneme for EN engines |
| Rendang | ren-DAHNG | ɹɛnˈdɑːŋ | Google BM handles natively |

### Ad Script Structure

```
┌────────────────────────────────┐
│ HOOK (0-3s)                    │  1-2 sentences. Grab attention.
│ "Tired of boring meal prep?"   │  Question, bold claim, or surprise.
├────────────────────────────────┤
│ PROBLEM (3-8s)                 │  2-3 sentences. Relatable pain point.
│ "You want healthy food, but    │
│  cooking takes forever..."     │
├────────────────────────────────┤
│ SOLUTION (8-13s)               │  2-3 sentences. Introduce the brand.
│ "Mirra delivers calorie-       │
│  controlled meals to your door.│
│  Balanced, delicious, READY."  │
├────────────────────────────────┤
│ CTA (13-16s)                   │  1-2 sentences. Clear action.
│ "Order now on WhatsApp.        │
│  First bento 20% off."         │
└────────────────────────────────┘
```

### Pinxin Vegan Voice Profile

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

### Sample Voiceover Scripts by Brand

#### pinxin-vegan — Bold Vegan Nasi Lemak Ad (15s)

```
HOOK:    "Think vegan food is boring? Think again."
PROBLEM: "Same old salads. Same bland tofu. Where's the FLAVOUR?"
SOLUTION:"Pinxin Vegan nasi lemak — coconut rice, crispy tempeh rendang,
          and sambal that HITS. Bold flavours. Zero compromise.
          100% plant-based. 100% Malaysian."
CTA:     "Order now on GrabFood. Bold flavours, delivered."
```

#### pinxin-vegan — Rendang Bowl Promo BM Manglish (15s)

```
HOOK:    "Korang, rendang vegan dah balik!"
PROBLEM: "Nak makan sedap tapi nak jaga kesihatan? Susah kan."
SOLUTION:"Pinxin Rendang Bowl — jackfruit rendang yang smoky gila,
          nasi kelapa, ulam segar. Plant-based tapi rasa macam
          mak masak. Serious."
CTA:     "Grab kat Shopee sekarang. Rasa power, zero compromise!"
```

#### wholey-wonder — Energetic Acai Bowl Ad (15s)

```
HOOK:    "Start your morning with a Wholey Wonder acai bowl."
PROBLEM: "Smoothie bowls that are all sugar? No thanks."
SOLUTION:"Wholey Wonder bowls are loaded with real fruit, granola, and superfoods.
          Wholesome. Delicious. Made fresh in KL."
CTA:     "Order your Wholey Wonder bowl now on WhatsApp."
```

#### gaia-eats — Delivery Marketplace Promo (15s)

```
HOOK:    "Healthy food, delivered to your door. That's Gaia Eats."
PROBLEM: "Finding clean, plant-forward meals shouldn't be this hard."
SOLUTION:"Gaia Eats brings together the best vegan and wellness kitchens
          in one marketplace. Browse, order, done."
CTA:     "Download Gaia Eats and get free delivery on your first order."
```

#### dr-stan — Supplement Health Tip (15s)

```
HOOK:    "Your body deserves better. Dr. Stan knows."
PROBLEM: "Low energy, brain fog, tired all the time..."
SOLUTION:"Dr. Stan's plant-based supplements are formulated by real nutritionists.
          Clean ingredients. Science-backed. No fillers."
CTA:     "Shop Dr. Stan supplements today. Your future self will thank you."
```

---

## 5. Workflow SOP

```
INPUT:  Script text + brand name + language + [optional: video file to sync to]
        ↓
STEP 1: Load brand voice profile
        → Read ~/.openclaw/brands/{brand}/voice-profile.json
        → If missing, use default voice for brand category (F&B/wellness/creative/tech/character)
        ↓
STEP 2: Select engine based on language and quality needs
        → Hero content? → ElevenLabs
        → BM or ZH? → Google Cloud TTS WaveNet
        → Draft? → Edge TTS
        → Override with --engine flag if specified
        ↓
STEP 3: Pre-process script
        → Inject SSML markup for pauses, emphasis, pronunciation
        → Apply pronunciation overrides from voice profile
        → Validate script length vs target duration
        → Estimate: ~150 words/min (EN), ~130 words/min (BM), ~160 chars/min (ZH)
        ↓
STEP 4: Generate voiceover audio
        → Call selected TTS engine API
        → Save raw audio to ~/.openclaw/workspace/data/audio/{brand}/
        → Filename: {brand}_{lang}_{timestamp}.mp3
        ↓
STEP 5: Post-process audio
        → Normalize volume to -16 LUFS (broadcast standard)
        → Trim silence from start/end (threshold: -40dB)
        → Apply gentle compression if needed (ratio 2:1, threshold -20dB)
        → Command: ffmpeg -i raw.mp3 -af "loudnorm=I=-16:TP=-1.5:LRA=11,silenceremove=1:0:-40dB" output.mp3
        ↓
STEP 6: If video provided → sync audio to video timing
        → Calculate video duration, check voiceover fits
        → If voiceover is longer: flag for script trimming OR speed up 1.1x max
        → If voiceover is shorter: pad with silence or let video breathe
        → Hand off to VideoForge for final mix
        ↓
STEP 7: Quality check
        → Pace: natural, not robotic?
        → Clarity: all words intelligible?
        → Brand match: tone matches brand DNA?
        → Technical: no artifacts, pops, or clipping?
        → Duration: fits target length?
        ↓
STEP 8: Export
        → Audio-only: .mp3 (320kbps) + .wav (48kHz/16bit) to data/audio/{brand}/
        → Video mix: pass to VideoForge → bash scripts/video-forge.sh music --track vo.mp3 --duck --video input.mp4
        → Metadata: save generation params to {output}.json sidecar

OUTPUT: .mp3/.wav audio file at ~/.openclaw/workspace/data/audio/{brand}/
        Optionally: mixed video via VideoForge at data/videos/{brand}/
```

### Engine-Specific API Calls

#### ElevenLabs

```bash
# Generate voiceover via ElevenLabs API
curl -X POST "https://api.elevenlabs.io/v1/text-to-speech/{voice_id}" \
  -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Your weight management meals, delivered fresh. Order now on WhatsApp.",
    "model_id": "eleven_multilingual_v2",
    "voice_settings": {
      "stability": 0.5,
      "similarity_boost": 0.8,
      "style": 0.3,
      "use_speaker_boost": true
    }
  }' \
  --output voiceover.mp3
```

#### Google Cloud TTS

```bash
# Generate voiceover via Google Cloud TTS (with SSML)
curl -X POST "https://texttospeech.googleapis.com/v1/text:synthesize" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "ssml": "<speak>Makanan pengurusan berat badan anda, dihantar segar. <break time=\"300ms\"/> Pesan sekarang.</speak>"
    },
    "voice": {
      "languageCode": "ms-MY",
      "name": "ms-MY-Wavenet-A",
      "ssmlGender": "FEMALE"
    },
    "audioConfig": {
      "audioEncoding": "MP3",
      "speakingRate": 1.0,
      "pitch": 0,
      "sampleRateHertz": 24000
    }
  }' | jq -r '.audioContent' | base64 --decode > voiceover_bm.mp3
```

#### OpenAI TTS

```bash
# Generate voiceover via OpenAI TTS
curl -X POST "https://api.openai.com/v1/audio/speech" \
  -H "Authorization: Bearer ${OPENAI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "tts-1-hd",
    "input": "Your weight management meals, delivered fresh. Order now.",
    "voice": "nova",
    "response_format": "mp3",
    "speed": 1.0
  }' \
  --output voiceover_draft.mp3
```

#### Edge TTS (Free)

```bash
# Generate voiceover via Edge TTS (free, no API key)
# Install: pip install edge-tts
edge-tts --text "Your weight management meals, delivered fresh." \
  --voice "en-US-JennyNeural" \
  --rate "+0%" \
  --pitch "+0Hz" \
  --write-media voiceover_draft.mp3 \
  --write-subtitles voiceover_draft.vtt

# Malay voice
edge-tts --text "Makanan pengurusan berat badan anda, dihantar segar." \
  --voice "ms-MY-YasminNeural" \
  --write-media voiceover_bm.mp3

# Mandarin voice
edge-tts --text "新鲜便当，送到你家门口。" \
  --voice "zh-CN-XiaoxiaoNeural" \
  --write-media voiceover_zh.mp3

# List all available voices
edge-tts --list-voices | grep -E "ms-MY|zh-CN|en-US"
```

#### Coqui XTTS (Local)

```python
# Generate voiceover via Coqui XTTS (local, GPU recommended)
from TTS.api import TTS

tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2", gpu=True)

# With voice cloning from a 6-second sample
tts.tts_to_file(
    text="Your weight management meals, delivered fresh.",
    speaker_wav="voice-sample.wav",  # 6s+ reference audio
    language="en",
    file_path="voiceover_cloned.wav"
)
```

---

## 6. CLI Usage

```bash
# ──────────────────────────────────────────
# GENERATE — Create voiceover from inline script
# ──────────────────────────────────────────
bash scripts/ai-voiceover.sh generate \
  --brand mirra \
  --lang en \
  --script "Your weight management meals, delivered fresh. Order now."

# Specify engine explicitly (overrides voice profile default)
bash scripts/ai-voiceover.sh generate \
  --brand mirra \
  --lang en \
  --engine elevenlabs \
  --script "Your weight management meals, delivered fresh."

# ──────────────────────────────────────────
# GENERATE — Pinxin Vegan bold nasi lemak ad
# ──────────────────────────────────────────
bash scripts/ai-voiceover.sh generate \
  --brand pinxin-vegan \
  --lang en \
  --script "Think vegan food is boring? Think again. Pinxin nasi lemak. Bold flavours. Zero compromise."

# ──────────────────────────────────────────
# GENERATE — From script file
# ──────────────────────────────────────────
bash scripts/ai-voiceover.sh generate \
  --brand pinxin-vegan \
  --lang bm \
  --script-file ~/.openclaw/workspace/data/scripts/pinxin-ad-bm.txt

# ──────────────────────────────────────────
# MIX — Generate voiceover and combine with video
# ──────────────────────────────────────────
bash scripts/ai-voiceover.sh mix \
  --brand mirra \
  --lang en \
  --script "Your weight management meals, delivered fresh. Order now on WhatsApp." \
  --video ~/.openclaw/workspace/data/videos/mirra/hero-video.mp4

# Mix with background music ducking
bash scripts/ai-voiceover.sh mix \
  --brand mirra \
  --lang en \
  --script-file ad-script.txt \
  --video hero-video.mp4 \
  --bgm ~/.openclaw/workspace/data/audio/music/upbeat-1.mp3

# ──────────────────────────────────────────
# BATCH — Generate all language variants at once
# ──────────────────────────────────────────
bash scripts/ai-voiceover.sh batch \
  --brand mirra \
  --script "Your weight management meals, delivered fresh." \
  --langs en,bm,zh

# Batch with translated script files (one per language)
bash scripts/ai-voiceover.sh batch \
  --brand mirra \
  --script-dir ~/.openclaw/workspace/data/scripts/mirra-campaign/ \
  --langs en,bm,zh

# ──────────────────────────────────────────
# PREVIEW — Quick draft with Edge TTS (free, instant)
# ──────────────────────────────────────────
bash scripts/ai-voiceover.sh preview \
  --script "Quick test of this voiceover script." \
  --lang en

# Preview in Malay
bash scripts/ai-voiceover.sh preview \
  --script "Makanan pengurusan berat badan untuk anda." \
  --lang bm

# ──────────────────────────────────────────
# CLONE — Create custom brand voice from audio sample
# ──────────────────────────────────────────
bash scripts/ai-voiceover.sh clone \
  --brand mirra \
  --sample ~/.openclaw/workspace/data/audio/samples/mirra-voice-sample.mp3 \
  --name "mirra-voice-1"

# Clone with ElevenLabs (requires Pro plan)
bash scripts/ai-voiceover.sh clone \
  --brand jade-oracle \
  --sample jade-oracle-voice.mp3 \
  --name "jade-oracle-mystical" \
  --engine elevenlabs

# ──────────────────────────────────────────
# LIST — Show available voices and profiles
# ──────────────────────────────────────────
bash scripts/ai-voiceover.sh list-voices --engine elevenlabs
bash scripts/ai-voiceover.sh list-voices --engine edge --lang bm
bash scripts/ai-voiceover.sh list-profiles               # Show all brand voice profiles

# ──────────────────────────────────────────
# ESTIMATE — Estimate duration from script text
# ──────────────────────────────────────────
bash scripts/ai-voiceover.sh estimate \
  --script "Your weight management meals, delivered fresh. Order now." \
  --lang en
# Output: ~3.2 seconds (8 words @ 150 wpm)
```

### Output Locations

| Type | Path |
|------|------|
| Raw audio | `~/.openclaw/workspace/data/audio/{brand}/{brand}_{lang}_{timestamp}.mp3` |
| Processed audio | `~/.openclaw/workspace/data/audio/{brand}/{brand}_{lang}_{timestamp}_final.mp3` |
| Mixed video | `~/.openclaw/workspace/data/videos/{brand}/{brand}_{lang}_{timestamp}_vo.mp4` |
| Subtitles (from VO) | `~/.openclaw/workspace/data/audio/{brand}/{brand}_{lang}_{timestamp}.vtt` |
| Generation metadata | `~/.openclaw/workspace/data/audio/{brand}/{brand}_{lang}_{timestamp}.json` |
| Voice clones | `~/.openclaw/workspace/data/audio/clones/{brand}/{name}/` |

---

## 7. Video Ad Script Templates

### Template 1: Product Launch (15s)

**EN:**
```
Fresh from Mirra. Our NEW teriyaki meal plan is here.
Grilled chicken, jasmine rice, pickled greens — calorie-controlled.
Your weight management goals, DELIVERED to your door.
Order now — first week 20% off.
```

**BM:**
```
Baru dari Mirra. Pelan makanan teriyaki BARU telah tiba.
Ayam panggang, nasi melati, jeruk sayur — kalori terkawal.
Matlamat pengurusan berat badan anda, DIHANTAR ke pintu rumah.
Pesan sekarang — minggu pertama diskaun 20%.
```

**ZH:**
```
Mirra新品上线。全新照烧体重管理餐来了。
烤鸡肉，茉莉香饭，腌渍蔬菜——卡路里精准控制。
体重管理目标，新鲜送到你家门口。
立即下单——首周八折优惠。
```

### Template 2: Testimonial Style (30s)

**EN:**
```
I used to spend hours meal prepping every Sunday.
Chopping, cooking, packing... it was exhausting.
Then a friend told me about {brand}.
Now I get fresh, balanced meals delivered to my door.
No cooking. No cleanup. Just REAL food that tastes amazing.
{brand} changed my week. It can change yours too.
Try it today — link in bio.
```

**BM:**
```
Dulu saya habiskan berjam-jam menyediakan makanan setiap Ahad.
Potong, masak, bungkus... memang penat.
Lepas tu kawan saya cerita pasal {brand}.
Sekarang saya dapat makanan segar dan seimbang dihantar ke rumah.
Tak perlu masak. Tak perlu kemas. Makanan SEBENAR yang sedap.
{brand} ubah minggu saya. Boleh ubah minggu anda juga.
Cuba hari ini — link di bio.
```

**ZH:**
```
以前每个周日我都要花好几个小时准备餐食。
切菜、烹饪、打包……真的很累。
后来朋友告诉我{brand}。
现在新鲜均衡的餐食直接送到家门口。
不用做饭，不用收拾，只有真正好吃的食物。
{brand}改变了我的一周。也能改变你的。
今天就试试——链接在简介里。
```

### Template 3: How-To (30s)

**EN:**
```
Ordering from {brand} is easy. Here's how.
Step one — browse our menu on WhatsApp.
Pick your bentos for the week. Mix and match flavours.
Step two — choose your delivery day.
We deliver fresh every Monday, Wednesday, and Friday.
Step three — enjoy. No cooking, no stress.
Just open and eat. It's THAT simple.
Start your first order today.
```

**BM:**
```
Pesan dari {brand} mudah sahaja. Begini caranya.
Langkah satu — lihat menu kami di WhatsApp.
Pilih bento anda untuk seminggu. Campur dan padan rasa.
Langkah dua — pilih hari penghantaran.
Kami hantar segar setiap Isnin, Rabu, dan Jumaat.
Langkah tiga — nikmati. Tak perlu masak, tak perlu risau.
Buka dan makan. SEMUDAH itu.
Mula pesanan pertama anda hari ini.
```

**ZH:**
```
从{brand}订餐非常简单，三步搞定。
第一步——在WhatsApp浏览我们的菜单。
选择一周的便当，随意搭配口味。
第二步——选择配送日期。
我们每周一、三、五新鲜配送。
第三步——享用。不用做饭，零压力。
打开就能吃，就是这么简单。
今天就开始下单吧。
```

### Template 4: Seasonal/Promo (15s)

**EN:**
```
This week ONLY. {brand} Raya Special.
Rendang bento with lemang and kuih.
Limited edition — selling out fast.
Grab yours before it's gone. Order now.
```

**BM:**
```
Minggu ini SAHAJA. {brand} Istimewa Raya.
Bento rendang dengan lemang dan kuih.
Edisi terhad — cepat habis.
Dapatkan sebelum kehabisan. Pesan sekarang.
```

**ZH:**
```
仅限本周。{brand}开斋节特别版。
仁当便当配竹筒饭和糕点。
限量供应——即将售罄。
赶快抢购，立即下单。
```

### Template 5: Brand Story (60s)

**EN:**
```
It started with a simple question.
Why is healthy food so... boring?
We believed it didn't have to be.
That good nutrition could also be delicious, beautiful, and convenient.
So we built {brand}.

Every bento is crafted with care.
Locally sourced ingredients. Balanced macros. Zero compromise on taste.
We're not just another meal delivery.
We're a movement — making wellness accessible to everyone.

From our kitchen to your table... this is {brand}.
Join thousands of Malaysians eating better, one bento at a time.
Try your first box today.
```

**BM:**
```
Bermula dengan satu soalan mudah.
Kenapa makanan sihat begitu... membosankan?
Kami percaya ia tak perlu begitu.
Nutrisi yang baik boleh juga sedap, cantik, dan mudah.
Maka kami bina {brand}.

Setiap bento dihasilkan dengan penuh kasih.
Bahan tempatan. Makro seimbang. Tiada kompromi pada rasa.
Kami bukan sekadar penghantaran makanan biasa.
Kami satu pergerakan — menjadikan kesihatan mampu milik semua.

Dari dapur kami ke meja anda... inilah {brand}.
Sertai ribuan rakyat Malaysia yang makan lebih baik, satu bento pada satu masa.
Cuba kotak pertama anda hari ini.
```

**ZH:**
```
一切始于一个简单的问题。
为什么健康食物总是那么……无趣？
我们相信不必如此。
好的营养也可以美味、精致、方便。
所以我们创建了{brand}。

每份便当都用心制作。
本地食材，均衡营养，绝不妥协口味。
我们不只是普通的餐食配送。
我们是一场运动——让健康触手可及。

从我们的厨房到你的餐桌……这就是{brand}。
加入数千位马来西亚人的行列，一份便当一份改变。
今天就试试你的第一份吧。
```

---

## 8. Integration with VideoForge

### Audio Ducking

When mixing voiceover into a video that has background music, VideoForge auto-ducks the music volume when voiceover plays:

```bash
# VideoForge handles the ducking automatically
bash scripts/video-forge.sh music \
  --track voiceover.mp3 \
  --duck \
  --video hero-video.mp4

# Manual ducking parameters (advanced)
# - Duck level: -18dB below original when VO active
# - Attack: 200ms (how fast music ducks)
# - Release: 500ms (how fast music returns)
# - Threshold: -30dB (VO signal level to trigger duck)
```

FFmpeg sidechain compression for audio ducking:
```bash
ffmpeg -i video.mp4 -i voiceover.mp3 -i bgm.mp3 \
  -filter_complex "[2:a]asplit=2[bgm1][bgm2]; \
    [1:a][bgm1]sidechaincompress=threshold=0.03:ratio=6:attack=200:release=500[ducked]; \
    [ducked][1:a]amix=inputs=2:weights=0.4 1.0[aout]" \
  -map 0:v -map "[aout]" -c:v copy -c:a aac -b:a 192k output.mp4
```

### Subtitle Generation from Voiceover

Since we already have the exact script text, subtitles are pre-synced — no Whisper transcription needed:

```bash
# Generate .srt from script with estimated timings
bash scripts/ai-voiceover.sh generate \
  --brand mirra --lang en \
  --script-file ad-script.txt \
  --subtitles  # Outputs .vtt alongside .mp3

# Feed subtitles into VideoForge caption
bash scripts/video-forge.sh caption \
  --style tiktok \
  --srt voiceover.srt \
  video_with_vo.mp4
```

### Multi-Language Video Variants

Same video, different voiceover tracks — one command per variant:

```bash
# Generate all 3 language variants for a video ad
for lang in en bm zh; do
  bash scripts/ai-voiceover.sh mix \
    --brand mirra \
    --lang "$lang" \
    --script-file "scripts/mirra-ad-${lang}.txt" \
    --video hero-video.mp4
done

# Output:
# data/videos/mirra/mirra_en_20260323_vo.mp4
# data/videos/mirra/mirra_bm_20260323_vo.mp4
# data/videos/mirra/mirra_zh_20260323_vo.mp4
```

### Pipeline Integration (Full Ad Production)

```
campaign-planner → Dreami writes script → campaign-translate (BM/ZH)
    ↓                                          ↓
ai-voiceover generate (EN)              ai-voiceover batch (BM, ZH)
    ↓                                          ↓
video-gen (generate visuals)            video-gen (same visuals)
    ↓                                          ↓
ai-voiceover mix (EN VO + video)        ai-voiceover mix (BM/ZH VO + video)
    ↓                                          ↓
video-forge (caption, brand, effects)   video-forge (caption, brand, effects)
    ↓                                          ↓
clip-factory (platform variants)        clip-factory (platform variants)
    ↓                                          ↓
Export: IG Reels, TikTok, FB Feed       Export: IG Reels, TikTok, FB Feed
```

---

## 9. Quality Checklist

Before marking a voiceover as production-ready, verify:

### Audio Quality
- [ ] No artifacts, pops, clicks, or digital distortion
- [ ] Consistent volume throughout (normalized to -16 LUFS)
- [ ] No unnatural silences or abrupt cuts
- [ ] Clean start and end (no cut-off words)

### Naturalness
- [ ] Pacing sounds natural, not robotic or rushed
- [ ] Appropriate pauses at commas and periods
- [ ] Emphasis on the right words (CAPS words stressed)
- [ ] Intonation rises on questions, falls on statements
- [ ] No uncanny valley effect — listener wouldn't immediately flag as AI

### Brand Consistency
- [ ] Voice matches brand personality (warm for F&B, calm for wellness, etc.)
- [ ] Tone matches content type (excited for launch, serene for wellness)
- [ ] All brand/product names pronounced correctly
- [ ] Malay/Chinese terms pronounced accurately

### Technical Fit
- [ ] Duration matches target (within 1 second tolerance)
- [ ] Audio syncs with video timing (if video mix)
- [ ] Background music properly ducked during voiceover
- [ ] Subtitle timing matches audio

### Compliance
- [ ] No copyrighted voice likeness used without license
- [ ] Voice clones used only for brand-owned voices
- [ ] Disclosure added if required by platform (some require AI voice labels)

---

## 10. Integration Map

### Feeds FROM (Input Sources)

| Skill | What It Provides |
|-------|-----------------|
| `campaign-planner` | Ad scripts and campaign briefs with copy |
| `campaign-translate` | Translated scripts (EN → BM, EN → ZH) |
| `ad-composer` | Ad copy ready for voiceover |
| `brand-voice-check` | Validates script matches brand DNA before voiceover |

### Feeds INTO (Output Consumers)

| Skill | What It Receives |
|-------|-----------------|
| `video-forge` | Audio files for mixing into video (ducking, assembly) |
| `video-gen` | Voice-first video generation (audio drives visual pacing) |
| `clip-factory` | Voiceover audio for platform-specific clip variants |

### External Dependencies

| Service | Purpose | Env Variable |
|---------|---------|-------------|
| ElevenLabs API | Premium TTS, voice cloning | `ELEVENLABS_API_KEY` |
| Google Cloud TTS | BM/ZH WaveNet voices | `GOOGLE_APPLICATION_CREDENTIALS` |
| OpenAI API | Quick TTS drafts | `OPENAI_API_KEY` |
| Edge TTS | Free TTS (no key needed) | — |
| FFmpeg | Audio post-processing, video mixing | Installed at `/opt/homebrew/bin/ffmpeg` or `/usr/local/bin/ffmpeg` |

### Environment Setup

```bash
# Required env vars (add to ~/.openclaw/.env or export in shell)
export ELEVENLABS_API_KEY="sk_..."          # ElevenLabs API key
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/gcloud-tts-key.json"
export OPENAI_API_KEY="sk-..."              # OpenAI API key (if using OpenAI TTS)

# Install Edge TTS (free, no key needed)
pip install edge-tts

# Install Coqui XTTS (optional, for local voice cloning)
pip install TTS

# Verify FFmpeg
ffmpeg -version
```
