# Platform Requirements, Engine APIs & Integration

## Voice Engine Options

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

## Engine-Specific API Calls

### ElevenLabs

```bash
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

### Google Cloud TTS

```bash
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

### OpenAI TTS

```bash
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

### Edge TTS (Free)

```bash
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

### Coqui XTTS (Local)

```python
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

## Sample Voiceover Scripts by Brand

### pinxin-vegan — Bold Vegan Nasi Lemak Ad (15s)

```
HOOK:    "Think vegan food is boring? Think again."
PROBLEM: "Same old salads. Same bland tofu. Where's the FLAVOUR?"
SOLUTION:"Pinxin Vegan nasi lemak — coconut rice, crispy tempeh rendang,
          and sambal that HITS. Bold flavours. Zero compromise.
          100% plant-based. 100% Malaysian."
CTA:     "Order now on GrabFood. Bold flavours, delivered."
```

### pinxin-vegan — Rendang Bowl Promo BM Manglish (15s)

```
HOOK:    "Korang, rendang vegan dah balik!"
PROBLEM: "Nak makan sedap tapi nak jaga kesihatan? Susah kan."
SOLUTION:"Pinxin Rendang Bowl — jackfruit rendang yang smoky gila,
          nasi kelapa, ulam segar. Plant-based tapi rasa macam
          mak masak. Serious."
CTA:     "Grab kat Shopee sekarang. Rasa power, zero compromise!"
```

### wholey-wonder — Energetic Acai Bowl Ad (15s)

```
HOOK:    "Start your morning with a Wholey Wonder acai bowl."
PROBLEM: "Smoothie bowls that are all sugar? No thanks."
SOLUTION:"Wholey Wonder bowls are loaded with real fruit, granola, and superfoods.
          Wholesome. Delicious. Made fresh in KL."
CTA:     "Order your Wholey Wonder bowl now on WhatsApp."
```

### gaia-eats — Delivery Marketplace Promo (15s)

```
HOOK:    "Healthy food, delivered to your door. That's Gaia Eats."
PROBLEM: "Finding clean, plant-forward meals shouldn't be this hard."
SOLUTION:"Gaia Eats brings together the best vegan and wellness kitchens
          in one marketplace. Browse, order, done."
CTA:     "Download Gaia Eats and get free delivery on your first order."
```

### dr-stan — Supplement Health Tip (15s)

```
HOOK:    "Your body deserves better. Dr. Stan knows."
PROBLEM: "Low energy, brain fog, tired all the time..."
SOLUTION:"Dr. Stan's plant-based supplements are formulated by real nutritionists.
          Clean ingredients. Science-backed. No fillers."
CTA:     "Shop Dr. Stan supplements today. Your future self will thank you."
```

## Video Ad Script Templates

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

## VideoForge Integration

### Audio Ducking

When mixing voiceover into a video that has background music, VideoForge auto-ducks the music volume when voiceover plays:

```bash
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

```bash
bash scripts/ai-voiceover.sh generate \
  --brand mirra --lang en \
  --script-file ad-script.txt \
  --subtitles  # Outputs .vtt alongside .mp3

bash scripts/video-forge.sh caption \
  --style tiktok \
  --srt voiceover.srt \
  video_with_vo.mp4
```

### Multi-Language Video Variants

```bash
for lang in en bm zh; do
  bash scripts/ai-voiceover.sh mix \
    --brand mirra \
    --lang "$lang" \
    --script-file "scripts/mirra-ad-${lang}.txt" \
    --video hero-video.mp4
done
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

## Quality Checklist

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

## Integration Map

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
export ELEVENLABS_API_KEY="sk_..."
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/gcloud-tts-key.json"
export OPENAI_API_KEY="sk-..."

pip install edge-tts
pip install TTS  # Optional, for Coqui XTTS local voice cloning
ffmpeg -version
```
