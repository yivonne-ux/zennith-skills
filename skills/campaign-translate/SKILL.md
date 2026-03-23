---
name: campaign-translate
description: Multilingual campaign adaptation engine. Translates ad copy, captions, video subtitles, and marketing assets across EN/BM/ZH while preserving brand voice, cultural nuance, and conversion intent.
agents: [dreami, taoz]
version: 1.0.0
---

# Campaign Translate — Multilingual Transcreation Engine

**Owner:** Dreami (transcreation), Taoz (tooling/automation)
**Scope:** All 14 brands, 3 core languages (EN, BM, ZH)
**Cost:** LLM-based transcreation per asset; batch mode available

---

## 1. Overview

This is NOT translation. This is **transcreation** — adapting entire campaigns to feel native in each target language while preserving what actually matters for conversion.

Every campaign asset that leaves the system must be adapted, not translated. Direct translation kills conversion. "Meals delivered fresh to your door" becomes "Makanan segar sampai ke pintu rumah anda" in formal BM, but for a casual brand like Pinxin it becomes "Fresh gila, terus sampai depan rumah!" — same intent, completely different execution.

**What transcreation preserves:**
- Brand voice and tone (loaded from `~/.openclaw/brands/{brand}/DNA.json`)
- Conversion intent (CTA click-through rates differ by language)
- Cultural appropriateness (Malaysian market has unique sensitivities)
- SEO keywords per language (direct translations rank poorly)
- Character limits per platform (ZH is shorter, BM is longer than EN)

**What transcreation changes:**
- Wordplay, puns, idioms (recreated, never literally translated)
- Proof points (localized for cultural relevance)
- Tone register (formal/casual shifts per language norms)
- Hashtags (researched per language, never direct-translated)

---

## 2. Language Matrix

### Supported Languages

| Code | Language | Script | Direction | Avg Char Expansion vs EN | Primary Use |
|------|----------|--------|-----------|--------------------------|-------------|
| EN | English | Latin | LTR | 1.0x (baseline) | Urban professionals, general market |
| BM | Bahasa Malaysia | Latin | LTR | 1.1-1.3x (longer) | Malay-majority audience, formal/gov channels |
| ZH | Chinese (Simplified) | CJK | LTR | 0.5-0.7x (shorter) | Chinese Malaysian audience, WeChat/XHS crossover |

### Character Expansion Impact on Design

```
EN: "Shop our new collection"          → 25 chars
BM: "Jelajahi koleksi terbaru kami"     → 31 chars (+24%)
ZH: "探索我们的新系列"                    → 8 chars  (-68%)
```

Designers must account for expansion/contraction when setting text boxes, button widths, and subtitle timing.

### Malaysian Market Nuances

**Manglish (Casual BM/EN Mix)**
Extremely common in social media. Malaysian audiences code-switch naturally between BM and EN, often mid-sentence. This is NOT broken English — it is a legitimate register that signals authenticity and relatability.

Examples:
- "So sedap lah this bento!" (casual food review)
- "Confirm worth it, serious!" (product endorsement)
- "Wah, this one really power lah" (genuine excitement)
- "Jom try, you won't regret one" (casual CTA)

**When to use Manglish:** Casual social media (IG Stories, Reels comments, TikTok), community engagement, brands with casual voice (Pinxin, MIRRA, Wholey Wonder).

**When NOT to use Manglish:** Official health claims, government submissions, formal EDMs, Dr Stan content, legal copy, Shopee product descriptions (SEO needs clean BM/EN).

**Formal BM**
Required for: health claims, government-adjacent content, official brand communications, press releases, Rasaya (heritage brand voice).

- Pure BM with no English loan words where possible
- Proper bahasa baku grammar
- Respectful address forms (anda, tuan/puan)

**Chinese Variants**
Primary target is Simplified Chinese, but Malaysian Chinese audiences have unique characteristics:
- Mix of Simplified and Traditional recognition (educated in Simplified, exposed to Traditional via HK/TW media)
- Certain food terms use local variants (e.g., "rojak" stays as rojak, not translated)
- Cantonese/Hokkien food terms widely understood and add authenticity
- WeChat and Xiaohongshu (XHS) conventions apply for cross-border content

**Code-Switching Strategy**
Some campaigns deliberately mix languages for maximum reach. This is intentional, not lazy:

| Strategy | Example | Use Case |
|----------|---------|----------|
| EN base + BM keywords | "Try our nasi lemak weight management bento — calorie-controlled!" | MIRRA urban audience |
| BM base + EN tech terms | "Download app kami untuk order senang" | Pinxin WhatsApp |
| EN + ZH hashtags | "New weekly plan drop #体重管理 #MIRRAweightmanagement" | Cross-audience IG |
| Full Manglish | "Eh this one damn nice lah, must try!" | Community engagement |

**Halal Sensitivity**
- "Halal" in EN/BM: straightforward, use freely for certified products
- "Halal" in ZH: use "清真" (qingzhen) — widely understood in MY Chinese community
- NEVER translate halal certification details — keep official cert language as-is
- Pork/alcohol references: handle with extreme care in multilingual campaigns
- When in doubt, lead with plant-based/vegan positioning (avoids halal ambiguity entirely)

**Cultural Calendar Priorities by Language**

| Event | EN Priority | BM Priority | ZH Priority |
|-------|-------------|-------------|-------------|
| Hari Raya Aidilfitri | Medium | HIGH | Low |
| Chinese New Year | Medium | Low | HIGH |
| Deepavali | Medium | Low | Low |
| Merdeka / Malaysia Day | HIGH | HIGH | HIGH |
| Christmas | Medium | Low | Medium |
| Mid-Autumn Festival | Low | Low | HIGH |
| Ramadan | Medium | HIGH | Low |
| Thaipusam | Low | Low | Low |

---

## 3. Content Types & Translation SOPs

### A. Ad Copy (Meta, Google, TikTok)

**Headlines — The Hardest Part**
Headlines carry the most conversion weight and are the hardest to transcreate. Rules:
1. Preserve the emotional trigger (curiosity, urgency, desire, fear of missing out)
2. Adapt wordplay — puns almost never translate, create new ones
3. Respect character limits (Google: 30 chars headline, Meta: 40 chars primary)
4. Test multiple variants — provide 3 options per language minimum

**Example: MIRRA weight management meal subscription campaign headline**

| Language | Option A | Option B | Option C |
|----------|----------|----------|----------|
| EN | "Weight management that tastes like home" | "Calorie-controlled. Malaysian flavours. Weekly plans." | "500 cal. Full flavour. Your weight goals, sorted." |
| BM | "Pengurusan berat yang rasa macam masakan rumah" | "Kalori terkawal. Rasa Malaysia. Pelan mingguan." | "500 kal. Penuh rasa. Matlamat berat badan, selesai." |
| BM (Manglish) | "Manage weight tapi rasa sedap gila!" | "Calorie counted tapi sedap macam mak masak" | "500 kal je. Weekly plan siap. Rasa? Power habis." |
| ZH | "体重管理也能这么好吃" | "卡路里控制 马来西亚风味 每周计划" | "500卡 满满风味 你的体重目标 搞定" |

**Example: Pinxin Vegan — bold plant-based Malaysian food campaign headline**

| Language | Option A | Option B | Option C |
|----------|----------|----------|----------|
| EN | "Bold flavours, zero compromise" | "Vegan nasi lemak that slaps" | "Plant-based. Malaysian-made. No apologies." |
| BM | "Rasa power, zero compromise" | "Nasi lemak vegan yang memang best" | "Berasaskan tumbuhan. Buatan Malaysia. Tanpa kompromi." |
| BM (Manglish) | "Rasa bold gila, zero compromise!" | "Nasi lemak vegan ni confirm sedap!" | "Plant-based tapi rasa macam hawker. Serious." |
| ZH | "大胆风味，零妥协" | "素食椰浆饭，一口上瘾" | "植物基 马来西亚制造 绝不妥协" |

**Body Copy**
- Maintain benefit hierarchy (lead benefit stays the lead)
- Adapt proof points for local relevance
- Preserve urgency mechanics (limited time, scarcity)
- Keep price/offer details identical (numbers don't translate)
- Social proof: localize ("10,000 Malaysians" not "10,000 customers")

**Hashtags — NEVER Direct Translate**
Research trending equivalents. Build a hashtag bank per language per brand.

| EN | BM | ZH |
|----|----|----|
| #HealthyEating | #MakanSihat | #健康饮食 |
| #PlantBased | #BerasaskanTumbuhan | #植物性饮食 |
| #MealPrep | #SediakanMakanan | #备餐 |
| #VeganMalaysia | #VeganMalaysia | #马来西亚素食 |
| #CleanEating | #MakanBersih | #清洁饮食 |
| #FoodPorn | #GambarMakanan | #美食摄影 |
| #SupportLocal | #SokongLokal | #支持本地 |
| #GlutenFree | #BebasGluten | #无麸质 |
| #DailyBento | #BentoHarian | #每日便当 |
| #WholeFoods | #MakananPenuh | #全食物 |

### B. Social Media Captions

**Platform-Aware Limits**

| Platform | EN Max | BM Max | ZH Max | Notes |
|----------|--------|--------|--------|-------|
| IG Feed | 2,200 chars | 2,200 chars | 2,200 chars | First 125 chars critical (preview cutoff) |
| IG Reels | 2,200 chars | 2,200 chars | 2,200 chars | Shorter is better — 50-100 chars ideal |
| FB Post | 63,206 chars | 63,206 chars | 63,206 chars | First 2 lines critical for engagement |
| TikTok | 2,200 chars | 2,200 chars | 2,200 chars | Keep under 150 for readability |
| Twitter/X | 280 chars | 280 chars | 280 chars (140 CJK = 280 byte) | ZH gets more meaning per tweet |

**Caption Transcreation Rules:**
1. Hook line adapts to language norms (BM questions work well: "Tau tak...?", ZH uses "你知道吗...")
2. Emoji usage: keep similar across languages in MY market (Malaysians use emojis equally across all 3 languages)
3. Hashtag block: language-specific (see hashtag bank above)
4. CTA: use proven CTAs from the CTA Dictionary (Section 7)
5. Mentions/tags: preserve all @ mentions — these are language-neutral
6. Line breaks: adjust for readability per script (CJK needs fewer line breaks)

**Example: Pinxin Vegan IG caption**

EN:
```
Bold flavours. Zero compromise. That's the Pinxin way. 🌱🔥

Our new Rendang Jackfruit Bowl hits different — smoky, rich, and 100% plant-based. Your taste buds won't believe it's vegan.

Available now on Shopee + free delivery KL/PJ!

#PinxinVegan #PlantBased #VeganMalaysia #MalaysianFood #Rendang
```

BM (Manglish):
```
Rasa bold. Zero compromise. Itulah cara Pinxin. 🌱🔥

Rendang Nangka Bowl baru kami memang lain macam — smoky, pekat, 100% berasaskan tumbuhan. Confirm lidah anda tak percaya ini vegan.

Available sekarang kat Shopee + penghantaran percuma KL/PJ!

#PinxinVegan #MakanSihat #VeganMalaysia #MakananMalaysia #Rendang
```

ZH:
```
大胆风味 零妥协 这就是Pinxin的态度 🌱🔥

全新仁当菠萝蜜碗 — 烟熏浓郁 百分百植物基 你的味蕾不敢相信这是素食

Shopee现已上架 吉隆坡/八打灵免运费！

#Pinxin素食 #植物性饮食 #马来西亚素食 #马来西亚美食 #仁当
```

### C. Video Subtitles / Captions

**SRT File Translation**
- Translate the text content of each subtitle block
- Adjust timing for character expansion (BM) or contraction (ZH):
  - BM: extend display duration by 10-20% (more chars to read)
  - ZH: can reduce display duration by 15-25% (fewer chars, faster scan)
- Minimum display time: 1.5s regardless of language
- Maximum 2 lines per subtitle, max 42 chars per line (EN/BM), 16 chars per line (ZH)

**ASS/SSA Styling**
- Font size may need adjustment for CJK (recommend 2px larger for readability)
- CJK fonts: use Noto Sans SC or Source Han Sans for consistency
- Latin fonts: follow brand typography from DNA.json

**Integration with VideoForge**
```bash
# Translate existing SRT
bash scripts/campaign-translate.sh subtitle --brand mirra --input video.srt --to bm,zh

# Output: video_bm.srt, video_zh.srt (timing-adjusted)
# Then pass to video-forge for burn-in:
bash ~/.openclaw/skills/video-forge/scripts/video-forge.sh caption --input video.mp4 --srt video_bm.srt --style mirra
```

### D. Email / EDM

**Subject Lines (Highest Impact)**
Subject lines determine open rates. Transcreation rules:
1. Preserve curiosity/urgency trigger
2. Keep under 50 chars (60 max) — mobile preview cutoff
3. Personalization tokens stay as-is: `{{first_name}}` is language-neutral
4. Preview text (preheader) also needs transcreation — it's the second hook

**Example: MIRRA weight management weekly plan EDM**

| Element | EN | BM | ZH |
|---------|----|----|-----|
| Subject | "This week's calorie-controlled plan is 🔥 (every meal under 500 cal)" | "Pelan kalori terkawal minggu ini 🔥 (setiap hidangan bawah 500 kal)" | "本周卡路里控制计划🔥（每餐低于500卡）" |
| Preview | "Nasi lemak bento is back — calorie-counted, weight-management approved" | "Bento nasi lemak kembali — kalori dikira, sesuai untuk pengurusan berat" | "椰浆饭便当回归啦——卡路里已算好，体重管理首选" |
| CTA button | "See This Week's Plan" | "Lihat Pelan Minggu Ini" | "查看本周计划" |

**Legal Footers**
- Unsubscribe text: must be legally compliant in each language
- EN: "Unsubscribe from this list"
- BM: "Nyahlanggan daripada senarai ini"
- ZH: "取消订阅此列表"
- Privacy policy links: maintain same URL (page should be multilingual)

### E. Product Descriptions (Shopee / E-Commerce)

**SEO Keyword Strategy**
Direct translation of keywords is an SEO disaster. Each language needs independent keyword research.

| EN Keyword | Search Vol | BM Keyword | Search Vol | ZH Keyword | Search Vol |
|------------|-----------|------------|-----------|------------|-----------|
| vegan meal delivery KL | High | penghantaran makanan vegan KL | Medium | 吉隆坡素食外卖 | Medium |
| healthy bento box | High | bento sihat | Medium | 健康便当 | High |
| plant-based Malaysian food | Medium | makanan berasaskan tumbuhan Malaysia | Low | 马来西亚植物基食品 | Medium |
| meal prep delivery | High | penghantaran sediakan makanan | Low | 备餐配送 | Medium |
| calorie counted meals | Medium | makanan kira kalori | Low | 卡路里计算餐 | Medium |

**Bullet Point Adaptation**
- Lead with the most compelling benefit per market
- BM market: emphasize "sedap" (delicious), value, family-friendly
- ZH market: emphasize health benefits, quality ingredients, convenience
- EN market: emphasize lifestyle, convenience, nutritional data
- Specifications (weight, cal count, ingredients) stay as numbers — universal

**Example: MIRRA Shopee listing title (weight management meal subscription)**

| Language | Title |
|----------|-------|
| EN | "MIRRA Weight Management Bento - 500cal Calorie-Controlled Meal - Weekly Plans - Free Delivery KL/PJ" |
| BM | "MIRRA Bento Pengurusan Berat - 500kal Hidangan Kalori Terkawal - Pelan Mingguan - Penghantaran Percuma KL/PJ" |
| ZH | "MIRRA体重管理便当 - 500卡卡路里控制餐 - 每周计划 - 吉隆坡/八打灵免运费" |

**Example: Pinxin Vegan Shopee listing title (vegan Malaysian food)**

| Language | Title |
|----------|-------|
| EN | "Pinxin Vegan Nasi Lemak Set - 100% Plant-Based - Bold Malaysian Flavours - Free Delivery KL/PJ" |
| BM | "Pinxin Vegan Set Nasi Lemak - 100% Berasaskan Tumbuhan - Rasa Malaysia Bold - Penghantaran Percuma KL/PJ" |
| ZH | "Pinxin素食椰浆饭套餐 - 100%植物基 - 大胆马来西亚风味 - 吉隆坡/八打灵免运费" |

**Example: Pinxin Vegan GrabFood listing description**

| Language | Description |
|----------|-------------|
| EN | "Bold vegan nasi lemak — coconut rice, crispy tempeh rendang, house sambal, and all the fixings. Plant-based, flavour-obsessed, proudly Malaysian." |
| BM | "Nasi lemak vegan yang bold — nasi kelapa, rendang tempeh rangup, sambal buatan sendiri. Berasaskan tumbuhan, rasa power, bangga Malaysia." |
| ZH | "大胆素食椰浆饭 — 椰香饭、脆天贝仁当、自制叁巴。植物基，风味至上，骄傲的马来西亚味道。" |

### F. WhatsApp Messages

**Conversational Tone is Key**
WhatsApp is personal. Translations must feel like a friend messaging, not a brand broadcasting.

**Button Text Translation**

| EN | BM | ZH |
|----|----|----|
| Order Now | Pesan Sekarang | 立即下单 |
| View Menu | Lihat Menu | 查看菜单 |
| Track Order | Jejak Pesanan | 追踪订单 |
| Talk to Us | Hubungi Kami | 联系我们 |
| Get Help | Dapatkan Bantuan | 获取帮助 |
| See Offers | Lihat Tawaran | 查看优惠 |

**Quick Reply Translations**

| EN | BM | ZH |
|----|----|----|
| Yes, I'm interested | Ya, saya berminat | 是的，我有兴趣 |
| Tell me more | Beritahu saya lebih lanjut | 告诉我更多 |
| Not now, thanks | Tidak sekarang, terima kasih | 暂时不了，谢谢 |
| What's the price? | Berapa harganya? | 多少钱？ |
| When can I get it? | Bila boleh dapat? | 什么时候能收到？ |

**Broadcast Message Adaptation**

Example: Pinxin Vegan promo blast

EN:
```
Hey {{name}}! 👋 Big news — our Rendang Bowl is BACK and it's only RM12.90 this week.

🌱 100% plant-based
🔥 Bold Malaysian flavours
📦 Free delivery KL/PJ

Grab yours before it sells out again! 👇
[Order Now]
```

BM (Manglish casual):
```
Hey {{name}}! 👋 Berita besar — Rendang Bowl kami dah BALIK dan harga RM12.90 je minggu ni.

🌱 100% berasaskan tumbuhan
🔥 Rasa Malaysian yang bold
📦 Penghantaran percuma KL/PJ

Cepat grab sebelum habis lagi! 👇
[Pesan Sekarang]
```

ZH:
```
嗨 {{name}}！👋 好消息 — 我们的仁当碗回来啦 本周只需 RM12.90

🌱 百分百植物基
🔥 大胆马来西亚风味
📦 吉隆坡/八打灵免运费

手快有手慢无！👇
[立即下单]
```

---

## 4. Brand Voice Preservation

### Voice Loading Protocol

Every transcreation task MUST begin by loading the brand's DNA:

```bash
# Load brand voice data
cat ~/.openclaw/brands/{brand}/DNA.json | jq '.voice'
```

Extract: `tone`, `language_mix`, `formality`, `personality`, `avoid`.

### Brand Voice Mapping — Core F&B Brands

Each brand's voice manifests differently across languages. This table defines how.

#### MIRRA — Weight management meal subscription — "Manage your weight, love every bite"

| Attribute | EN | BM | ZH |
|-----------|----|----|-----|
| Tone | Warm, empowering, results-driven | Mesra, memberi kuasa, berfokuskan hasil | 温暖、赋能、注重成效 |
| Register | Casual-confident | Casual-mesra (light Manglish OK) | 轻松自信 |
| Signature phrases | "Manage your weight, love every bite" | "Kawal berat badan, nikmati setiap suapan" | "管理体重，享受每一口" |
| Personality | Like a supportive friend who makes weight management feel easy and delicious | Macam kawan yang buat pengurusan berat badan rasa mudah dan sedap | 像一个让体重管理变得轻松美味的好闺蜜 |
| Avoid | Diet-shaming, clinical, cold, preachy | Terlalu formal, saintifik, diet-shaming | 冷冰冰、说教式、减肥羞辱 |

#### Pinxin Vegan — "Bold flavours, zero compromise"

| Attribute | EN | BM | ZH |
|-----------|----|----|-----|
| Tone | Bold, unapologetic, flavour-first | Berani, tak minta maaf, rasa utama | 大胆、不妥协、风味至上 |
| Register | Casual-confident, street-smart | Manglish heavy, like a hawker stall vibe | 轻松直接，街头智慧感 |
| Signature phrases | "Bold flavours, zero compromise" | "Rasa power, zero compromise" | "大胆风味，零妥协" |
| Personality | The cool friend who proves vegan is badass | Kawan cool yang buktikan vegan memang best | 那个证明素食也能很酷的朋友 |
| Avoid | Preachy, apologetic about plant-based | Menggurui, minta maaf pasal plant-based | 说教、为植物基食品道歉 |

#### Wholey Wonder — "Fuel your wonder"

| Attribute | EN | BM | ZH |
|-----------|----|----|-----|
| Tone | Energetic, optimistic, uplifting | Bersemangat, optimis, memberi inspirasi | 充满活力、乐观、振奋人心 |
| Register | Casual-upbeat, morning energy | Casual ceria, tenaga pagi | 轻松活泼，早晨活力感 |
| Signature phrases | "Fuel your wonder" | "Isi tenaga keajaiban anda" | "为你的奇迹加油" |
| Personality | Your hype-woman wellness bestie | BFF yang selalu support wellness anda | 永远为你加油的健康闺蜜 |
| Avoid | Gym-bro, aggressive, clinical | Agresif, terlalu saintifik | 健身狂热、侵略性、冷冰冰 |

#### Rasaya — "Warisan rasa, penawar semulajadi"

| Attribute | EN | BM | ZH |
|-----------|----|----|-----|
| Tone | Heritage-proud, warm, wise | Berbangga warisan, mesra, bijak | 传承自豪、温暖、睿智 |
| Register | Warm-familiar, respectful | Bahasa baku, penuh hormat, mesra | 温馨亲切、尊重传统 |
| Signature phrases | "Heritage remedies for modern life" | "Warisan rasa, penawar semulajadi" | "传统良方，现代生活" |
| Personality | Your wise nenek sharing kitchen secrets | Nenek bijak yang kongsi rahsia dapur | 智慧的奶奶分享厨房秘方 |
| Avoid | Trendy wellness buzzwords, clinical | Bahasa moden yang terlepas dari tradisi | 时髦的保健术语、脱离传统 |

#### GAIA Eats — "Plant-based food, Malaysian soul"

| Attribute | EN | BM | ZH |
|-----------|----|----|-----|
| Tone | Warm, authentic, community-focused | Mesra, tulen, berfokuskan komuniti | 温暖、真实、社区导向 |
| Register | Casual-friendly, like a kopitiam chat | Casual mesra, macam borak kat kopitiam | 轻松友好，像茶餐厅聊天 |
| Signature phrases | "Plant-based food, Malaysian soul" | "Makanan berasaskan tumbuhan, jiwa Malaysia" | "植物基食品，马来西亚灵魂" |
| Personality | The passionate foodie who happens to be plant-based | Foodie tegar yang kebetulan plant-based | 一个碰巧吃植物基的美食狂热者 |
| Avoid | Preachy, corporate, condescending | Menggurui, korporat, sombong | 说教、冷冰冰的商业感 |

#### Dr Stan — "Science you can trust, health you can feel"

| Attribute | EN | BM | ZH |
|-----------|----|----|-----|
| Tone | Authoritative, trustworthy, evidence-based | Berwibawa, boleh dipercayai, berasaskan bukti | 权威、可信赖、循证 |
| Register | Professional-approachable, no jargon overload | Profesional tapi mesra, elak jargon | 专业但平易近人 |
| Signature phrases | "Science you can trust" | "Sains yang anda boleh percaya" | "值得信赖的科学" |
| Personality | Your knowledgeable doctor friend at dinner | Doktor kawan yang share ilmu masa makan | 晚餐时分享知识的医生朋友 |
| Avoid | Miracle cure language, pseudoscience | Bahasa ubat ajaib, pseudosains | 神奇疗效语言、伪科学 |

#### Serein — "Be still, be whole"

| Attribute | EN | BM | ZH |
|-----------|----|----|-----|
| Tone | Tranquil, mindful, softly luxurious | Tenang, penuh kesedaran, mewah lembut | 宁静、正念、柔和奢华 |
| Register | Gentle-elevated, unhurried | Lembut, tidak tergesa-gesa, halus | 温柔高雅、不急不躁 |
| Signature phrases | "Be still, be whole" | "Berdiam, berseutuh" | "静心，完整" |
| Personality | A calm friend who creates peace around them | Kawan tenang yang bawa ketenangan | 身边带来平静的朋友 |
| Avoid | Loud, urgent, FOMO, pushy | Bising, mendesak, takut ketinggalan | 喧嚣、催促、制造焦虑 |

---

## 5. Translation Workflow SOP

### Full Workflow

```
INPUT: Source content (any language) + brand name + target languages + content type + platform
                                    |
                                    v
STEP 1: DETECT SOURCE LANGUAGE
  - Auto-detect or accept explicit --from flag
  - Identify register: formal, casual, Manglish
  - Flag any code-switching in source
                                    |
                                    v
STEP 2: LOAD BRAND DNA
  - cat ~/.openclaw/brands/{brand}/DNA.json | jq '.voice'
  - Extract: tone, language_mix, formality, personality, avoid list
  - Map to target language voice (see Brand Voice Mapping, Section 4)
                                    |
                                    v
STEP 3: CLASSIFY CONTENT TYPE
  - ad-copy | caption | subtitle | email | product-desc | whatsapp | general
  - Each type has different transcreation rules (Section 3)
  - Identify platform constraints (char limits, formatting)
                                    |
                                    v
STEP 4: TRANSCREATE (per target language)
  a. Transcreate — adapt for cultural context (NOT direct translate)
     - Wordplay/puns: create new ones in target language
     - Idioms: find cultural equivalents
     - Proof points: localize for relevance
  b. Apply brand voice filter
     - Match tone, register, personality from Step 2
     - Verify language_mix ratio matches DNA spec
  c. Check character limits for target platform
     - Apply expansion/contraction factors
     - Truncate or rewrite if over limit
  d. Cultural appropriateness review
     - Halal sensitivity check
     - Cultural calendar alignment
     - Code-switching appropriateness for brand
  e. SEO keyword integration (if applicable)
     - Use language-specific keywords, not translated keywords
     - Check Shopee/Google search volume per language
                                    |
                                    v
STEP 5: QUALITY REVIEW — Back-Translation
  - Back-translate each output to source language
  - Verify meaning preservation (not word preservation)
  - Check emotional tone consistency
  - Flag any meaning drift > 15%
                                    |
                                    v
STEP 6: BRAND VOICE CHECK
  - bash ~/.openclaw/skills/brand-voice-check/scripts/brand-voice-check.sh --brand {brand} --input {output_file}
  - Must PASS before proceeding
  - If FAIL: identify which voice attribute drifted, re-transcreate
                                    |
                                    v
STEP 7: EXPORT
  - Output all variants in structured format
  - File naming: {asset_name}_{lang}.{ext}
  - Include metadata: source language, brand, content type, platform, timestamp
  - Log to build log

OUTPUT: Campaign assets in all target languages, QA-verified
```

### Quick-Translate Flow (for single assets)

```
INPUT → detect lang → load DNA → transcreate → export
```

Skip Steps 5-6 for informal/internal content. Always run full flow for published content.

---

## 6. CLI Usage

```bash
# ─── SINGLE ASSET TRANSLATION ───

# Translate a campaign brief document
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh translate \
  --brand mirra \
  --input campaign-en.md \
  --to bm,zh

# Translate inline ad copy text
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh copy \
  --brand pinxin-vegan \
  --input "Healthy meals delivered to your door" \
  --to bm,zh

# Translate with specific tone override
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh copy \
  --brand mirra \
  --input "Try our new bento!" \
  --to bm \
  --tone casual

# Translate with Manglish register
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh copy \
  --brand pinxin-vegan \
  --input "Our rendang bowl is back!" \
  --to bm \
  --tone manglish

# ─── VIDEO SUBTITLES ───

# Translate SRT file (auto-adjusts timing)
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh subtitle \
  --brand gaia-eats \
  --input video.srt \
  --to bm,zh

# Translate ASS/SSA file (preserves styling, adjusts fonts for CJK)
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh subtitle \
  --brand mirra \
  --input video.ass \
  --to zh \
  --font "Noto Sans SC"

# ─── EMAIL / EDM ───

# Translate email template
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh email \
  --brand mirra \
  --input weekly-menu-edm.html \
  --to bm,zh

# Subject line only (for A/B testing)
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh subject \
  --brand mirra \
  --input "This week's menu is fire 🔥" \
  --to bm,zh \
  --variants 3

# ─── BATCH OPERATIONS ───

# Batch translate all pending content for a brand
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh batch \
  --brand mirra \
  --since 7d

# Batch translate across multiple brands
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh batch \
  --brands mirra,pinxin-vegan,gaia-eats \
  --since 3d

# ─── UTILITY ───

# Detect language of content
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh detect \
  --input "Makanan sihat sampai ke pintu anda"

# Validate existing translations against brand voice
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh validate \
  --brand mirra \
  --input translations/

# Generate CTA dictionary for a brand
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh cta-dict \
  --brand mirra

# Dry run (preview what would be translated)
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh translate \
  --brand mirra \
  --input campaign-en.md \
  --to bm,zh \
  --dry-run
```

### CLI Flags Reference

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--brand` | Yes | — | Brand name (loads DNA.json) |
| `--input` | Yes | — | Input file path or inline text (quoted) |
| `--to` | Yes | — | Target languages, comma-separated (en, bm, zh) |
| `--from` | No | auto-detect | Source language override |
| `--tone` | No | from DNA.json | Tone override: formal, casual, manglish |
| `--platform` | No | general | Target platform: ig, fb, tiktok, shopee, edm, whatsapp |
| `--variants` | No | 1 | Number of translation variants per language |
| `--since` | No | — | For batch: time window (1d, 7d, 30d) |
| `--dry-run` | No | false | Preview only, no output files |
| `--font` | No | brand default | CJK font override for subtitle files |
| `--output` | No | same dir as input | Output directory |

---

## 7. CTA Dictionary

Comprehensive call-to-action translations for the Malaysian market. Use these proven CTAs instead of ad-hoc translations.

### E-Commerce CTAs

| # | EN | BM | ZH | Context |
|---|----|----|-----|---------|
| 1 | Shop Now | Beli Sekarang | 立即购买 | General purchase |
| 2 | Add to Cart | Masukkan ke Troli | 加入购物车 | Product page |
| 3 | Buy Now | Beli Sekarang | 立即购买 | Urgent purchase |
| 4 | Get Yours | Dapatkan Milik Anda | 立即拥有 | Exclusive/limited feel |
| 5 | Grab the Deal | Rebut Tawaran | 抢购优惠 | Promotional |
| 6 | Claim Your Offer | Tebus Tawaran Anda | 领取优惠 | Coupon/discount |
| 7 | Free Delivery | Penghantaran Percuma | 免运费 | Shipping incentive |
| 8 | Limited Time Only | Masa Terhad | 限时优惠 | Urgency |
| 9 | While Stocks Last | Sementara Stok Masih Ada | 售完即止 | Scarcity |
| 10 | Save Now | Jimat Sekarang | 立即省钱 | Discount emphasis |

### Engagement CTAs

| # | EN | BM | ZH | Context |
|---|----|----|-----|---------|
| 11 | Learn More | Ketahui Lebih Lanjut | 了解更多 | Information seeking |
| 12 | See More | Lihat Lagi | 查看更多 | Content continuation |
| 13 | Watch Now | Tonton Sekarang | 立即观看 | Video content |
| 14 | Read More | Baca Lagi | 阅读更多 | Blog/article |
| 15 | Discover | Terokai | 探索 | Brand discovery |
| 16 | Try It Free | Cuba Percuma | 免费试用 | Trial offer |
| 17 | Get Started | Mula Sekarang | 立即开始 | Onboarding |
| 18 | Join Now | Sertai Sekarang | 立即加入 | Membership/community |
| 19 | Subscribe | Langgan | 订阅 | Newsletter/recurring |
| 20 | Download Now | Muat Turun Sekarang | 立即下载 | App/resource |

### Community & Social CTAs

| # | EN | BM | ZH | Context |
|---|----|----|-----|---------|
| 21 | Share with Friends | Kongsi dengan Rakan | 分享给朋友 | Social sharing |
| 22 | Tag a Friend | Tag Kawan Anda | 标记你的朋友 | Social engagement |
| 23 | Comment Below | Komen di Bawah | 在下方留言 | Engagement bait |
| 24 | Follow Us | Ikuti Kami | 关注我们 | Social follow |
| 25 | Save for Later | Simpan untuk Nanti | 稍后再看 | Bookmark |
| 26 | Swipe Up | Swipe ke Atas | 向上滑动 | IG Stories |
| 27 | Link in Bio | Pautan di Bio | 链接在简介 | IG traffic driver |
| 28 | DM Us | DM Kami | 私信我们 | Direct conversation |
| 29 | Drop a 🔥 if You Agree | Letak 🔥 kalau Setuju | 同意的话留个🔥 | Engagement bait |
| 30 | Tell Us Your Favourite | Beritahu Kami Kegemaran Anda | 告诉我们你的最爱 | UGC prompt |

### Transactional CTAs

| # | EN | BM | ZH | Context |
|---|----|----|-----|---------|
| 31 | Order Now | Pesan Sekarang | 立即下单 | Food/delivery |
| 32 | Book Now | Tempah Sekarang | 立即预订 | Services/events |
| 33 | Reserve Your Spot | Tempah Tempat Anda | 预留名额 | Limited capacity |
| 34 | Contact Us | Hubungi Kami | 联系我们 | General inquiry |
| 35 | WhatsApp Us | WhatsApp Kami | WhatsApp我们 | MY-preferred channel |
| 36 | Get a Quote | Dapatkan Sebut Harga | 获取报价 | B2B/services |
| 37 | Sign Up Now | Daftar Sekarang | 立即注册 | Account creation |
| 38 | Pre-Order Now | Pra-Tempah Sekarang | 立即预购 | Launch campaigns |

### Manglish CTAs (Casual Social Only)

| # | EN Base | Manglish Version | Context |
|---|---------|-----------------|---------|
| 39 | Shop Now | Jom beli! | Casual purchase |
| 40 | Try It | Jom try lah! | Casual trial |
| 41 | Check It Out | Eh check this out! | Casual discovery |
| 42 | Don't Miss Out | Jangan miss out lah! | Casual urgency |
| 43 | Grab It | Cepat grab! | Casual scarcity |
| 44 | So Good | Sedap gila, must try! | Food endorsement |
| 45 | Order Now | Jom order sekarang! | Food delivery |

---

## 8. Quality Gates

Every translated campaign asset must pass these gates before publishing.

### Gate 1: Back-Translation Check
- Translate output BACK to source language
- Compare meaning (not words) with original
- **Pass:** Core meaning and emotional intent preserved
- **Fail:** Meaning drift, lost nuance, or wrong emotional tone
- **Action on fail:** Re-transcreate the drifted sections

### Gate 2: Brand Voice Check
```bash
bash ~/.openclaw/skills/brand-voice-check/scripts/brand-voice-check.sh \
  --brand {brand} \
  --input {translated_file} \
  --language {target_lang}
```
- **Pass:** Voice score >= 80%
- **Fail:** Voice attributes misaligned
- **Action on fail:** Identify which attributes drifted, adjust register/tone

### Gate 3: Cultural Sensitivity Review
Checklist:
- [ ] No accidental halal/haram implications
- [ ] No culturally inappropriate imagery references in text
- [ ] Holiday/festival references appropriate for target language audience
- [ ] No political sensitivity (Malaysian context)
- [ ] Honorifics and address forms correct (BM: anda/kamu/awak register)
- [ ] No direct translation of idioms that change meaning cross-culturally
- [ ] Food terminology checked (some dishes have different names in different languages)

### Gate 4: Character Count Verification
```
For each output:
  - Count characters
  - Compare against platform limit for content type
  - Flag any overflow (>95% of limit = warning, >100% = fail)
  - BM outputs: verify expansion within expected 1.1-1.3x range
  - ZH outputs: verify contraction within expected 0.5-0.7x range
```

### Gate 5: Platform Compatibility
- [ ] Hashtags are language-appropriate and trending (not direct-translated)
- [ ] Emoji render correctly across platforms
- [ ] CJK text doesn't break layout in design files
- [ ] SRT/ASS timing verified for subtitle files
- [ ] WhatsApp button text within character limits (20 chars max)
- [ ] Email subject line under 50 chars per language
- [ ] Shopee title under 120 chars per language

### Gate Summary Matrix

| Gate | Automated? | Blocking? | Tool |
|------|-----------|-----------|------|
| Back-Translation | Semi (LLM-assisted) | Yes for ads, No for social | campaign-translate.sh validate |
| Brand Voice | Yes | Yes | brand-voice-check.sh |
| Cultural Sensitivity | Manual | Yes for all | Checklist review |
| Character Count | Yes | Yes | campaign-translate.sh validate |
| Platform Compatibility | Semi | Yes for paid, No for organic | campaign-translate.sh validate |

---

## 9. Integration

### Upstream (Feeds FROM)

| Skill | What It Provides | How |
|-------|-----------------|-----|
| `content-supply-chain` | Campaign briefs, content calendar | Translated at CREATE stage |
| `campaign-planner` | Campaign strategy with target languages | Specifies which languages per campaign |
| `meta-ads-creative` | Ad copy in source language | Triggers translation for ad variants |
| `ad-composer` | Image assets with text overlays | Text layers need per-language variants |
| `video-gen` / `video-forge` | Video with subtitles | SRT/ASS files for translation |
| `content-ideation-workflow` | Content ideas in source language | Ideas adapted per language |

### Downstream (Feeds INTO)

| Skill | What It Receives | How |
|-------|-----------------|-----|
| `content-repurpose` | Translated content for platform variants | Each language version gets platform-adapted |
| `social-publish` | Platform-ready multilingual posts | Published with correct language targeting |
| `meta-ads-manager` | Translated ad variants for A/B testing | Language-targeted ad sets |
| `acca-engine` | Translated WhatsApp flows | ACCA messages in user's preferred language |
| `video-forge` | Translated SRT files | Burned into video as subtitles |
| `shopify-cdp` | Translated product descriptions | Synced to multilingual Shopify store |

### Tools Used

| Tool | Purpose |
|------|---------|
| `brand-voice-check.sh` | Validates brand voice compliance post-translation |
| Brand `DNA.json` | Source of truth for voice, tone, personality per brand |
| `nanobanana-gen.sh` | Regenerate image assets with translated text overlays |
| `video-forge.sh` | Burn translated subtitles into video |
| `seed-store.sh` | Store successful translations as seed content |

### Data Flow Diagram

```
campaign-planner ──→ campaign brief (EN) ──→ campaign-translate ──→ brief_bm.md + brief_zh.md
                                                    |
meta-ads-creative ──→ ad copy (EN) ────────→ campaign-translate ──→ ad_bm.txt + ad_zh.txt
                                                    |
video-forge ──────→ video.srt (EN) ────────→ campaign-translate ──→ video_bm.srt + video_zh.srt
                                                    |
                                                    v
                                          brand-voice-check.sh
                                                    |
                                                    v
                                    ┌───────────────┼───────────────┐
                                    v               v               v
                              social-publish   meta-ads-manager   acca-engine
                              (multilingual)   (language A/B)     (user lang pref)
```

---

## 10. Appendix: Common Pitfalls

### Translation Anti-Patterns

| Anti-Pattern | Why It Fails | Do This Instead |
|-------------|-------------|-----------------|
| Direct-translate headlines | Wordplay/puns don't survive | Transcreate: new pun in target language |
| Google Translate for CTAs | Generic, no brand voice | Use CTA Dictionary (Section 7) |
| Same hashtags across languages | Zero discoverability | Research per-language trending tags |
| Translate "free delivery" literally to ZH | Nobody searches that way | Use "免运费" or "包邮" (platform-dependent) |
| Formal BM for casual brand | Sounds like a government notice | Match brand register — use Manglish if DNA says casual |
| Ignore char expansion for BM | Text overflows design | Budget 1.3x space for BM text boxes |
| Copy EN email subject to BM | Open rates tank | Transcreate subject lines independently |
| Translate food names | "Nasi lemak" is "nasi lemak" everywhere | Keep iconic Malaysian food names untranslated |
| Same urgency tactics across languages | Cultural response differs | BM: community ("jom sama-sama"), ZH: scarcity ("限量"), EN: FOMO |

### Untranslatable Terms (Keep As-Is)

These Malaysian terms should NEVER be translated regardless of target language:

| Term | Why |
|------|-----|
| Nasi lemak | Iconic — universally recognized |
| Rendang | Cultural dish name |
| Satay | Universal food term |
| Roti canai | No equivalent |
| Teh tarik | Cultural drink name |
| Kopitiam | Cultural institution |
| Pasar malam | Night market — keep in BM even in ZH/EN |
| Mamak | Restaurant type — culturally specific |
| Kuih | Traditional snack category |
| Jamu | Traditional remedy — keep for Rasaya |
| Bento | Already borrowed into all 3 languages (from Japanese) |
| Halal | Religious certification — universal |
| Hari Raya | Festival name — keep as-is |
| Ang pow / Ang pao | Red packet — keep local term |

---

## 11. Brand Translation Matrix

All 14 brands with their translation priorities, primary languages, and content focus.

| Brand | Primary Languages | Translation Priority | Content Focus | Tone Register |
|-------|-------------------|---------------------|---------------|---------------|
| pinxin-vegan | EN, BM, ZH | HIGH | Ad copy, social, WhatsApp, Shopee | Casual-bold, Manglish OK |
| mirra | EN, BM, ZH | HIGH | Weight management meal subscription: ad copy, EDM, weekly plan promos, Shopee | Warm-empowering, results-driven, light Manglish |
| wholey-wonder | EN, BM, ZH | HIGH | Social, wellness content, product descriptions | Upbeat-energetic, casual |
| gaia-eats | EN, BM, ZH | HIGH | Social, community content, Shopee | Casual-friendly, kopitiam vibe |
| dr-stan | EN, BM, ZH | HIGH | Health content, articles, product claims, EDM | Professional-approachable, no Manglish |
| rasaya | EN, BM, ZH | HIGH | Heritage content, product descriptions, social | Warm-traditional, formal BM |
| serein | EN, BM, ZH | HIGH | Wellness content, social, EDM, product copy | Gentle-elevated, unhurried |
| jade-oracle | EN, ZH | MEDIUM | Spiritual/oracle content, social | Mystical-wise, contemplative |
| iris | EN, BM, ZH | MEDIUM | Visual content, photography, social | Creative-expressive, artistic |
| gaia-os | EN | LOW | Technical docs, system content | Professional-clear, minimal translation |
| gaia-learn | EN, BM, ZH | MEDIUM | Educational content, course material, social | Friendly-instructive, accessible |
| gaia-print | EN, BM, ZH | MEDIUM | Print collateral, packaging, labels | Brand-specific per asset |
| gaia-recipes | EN, BM, ZH | HIGH | Recipe content, food descriptions, social | Warm-inviting, food-lover tone |
| gaia-supplements | EN, BM, ZH | MEDIUM | Health claims, product labels, Shopee listings | Evidence-based, regulatory-aware |
| dr-stan | EN, BM, ZH | HIGH | Health education, supplement descriptions, social | Authoritative yet warm |
| wholey-wonder | EN, BM, ZH | HIGH | Juice/smoothie descriptions, wellness tips, social | Energetic, optimistic, playful |
| serein | EN, BM, ZH | HIGH | Mindfulness content, self-care tips, product copy | Tranquil, poetic, softly luxurious |

**Notes:**
- All F&B/wellness brands (pinxin-vegan, wholey-wonder, mirra, rasaya, gaia-eats, dr-stan, serein) are HIGH priority for translation — these are customer-facing with multilingual Malaysian audiences.
- jade-oracle and iris have MEDIUM priority — jade-oracle skews EN/ZH (spiritual content), iris is visual-heavy with less text.
- gaia-os is LOW priority — primarily technical/system documentation in EN.
- gaia-learn, gaia-print, gaia-supplements have MEDIUM priority — translated on-demand per campaign.
- gaia-recipes is HIGH priority — food content resonates across all language segments.
- Always load `~/.openclaw/brands/{brand}/DNA.json` before translating for ANY brand.

---

## 12. Brand-Specific Translation Examples

### Wholey Wonder — Juice & Smoothie Campaigns

Wholey Wonder targets health-conscious urbanites with an energetic, uplifting voice. Translations must preserve the "hype-woman wellness bestie" personality.

**Example 1: Wholey Wonder — New Smoothie Launch (Ad Copy)**

| Language | Headline | Body |
|----------|----------|------|
| EN | "Your morning just got a glow-up" | "Meet the NEW Green Goddess Smoothie — spinach, banana, spirulina, and a whole lot of wonder. 500ml of pure fuel for your best day yet." |
| BM | "Pagi anda baru je naik level" | "Jom kenali Smoothie Green Goddess BARU — bayam, pisang, spirulina, dan penuh keajaiban. 500ml tenaga tulen untuk hari terbaik anda." |
| BM (Manglish) | "Pagi anda confirm level up!" | "Cuba Smoothie Green Goddess BARU — bayam, pisang, spirulina, memang power. 500ml pure fuel untuk hari yang best gila." |
| ZH | "你的早晨全面升级" | "全新绿色女神奶昔 — 菠菜、香蕉、螺旋藻，满满奇迹能量。500ml纯净燃料，开启最棒的一天。" |

**Example 2: Wholey Wonder — Weekly Wellness Tip (Social Caption)**

EN:
```
Hydration check! 💧 Did you know spinach has 91% water content?

That's why our Green Goddess Smoothie doesn't just taste amazing — it hydrates you from the inside out.

Fuel your wonder, one sip at a time. 🌿

#WholeyWonder #FuelYourWonder #GreenSmoothie #WellnessMalaysia
```

BM (Manglish):
```
Hydration check! 💧 Tau tak bayam ada 91% kandungan air?

Sebab tu Smoothie Green Goddess kami bukan setakat sedap — dia hydrate dari dalam.

Isi tenaga keajaiban anda, satu teguk pada satu masa. 🌿

#WholeyWonder #FuelYourWonder #SmoothieSihat #KesihatanMalaysia
```

ZH:
```
补水时间！💧 你知道菠菜含91%的水分吗？

这就是为什么我们的绿色女神奶昔不仅好喝 — 更能从内而外补水。

为你的奇迹加油，一口一口来。🌿

#WholeyWonder #为你的奇迹加油 #绿色奶昔 #马来西亚健康
```

### Dr Stan — Health Education & Supplement Campaigns

Dr Stan requires an authoritative yet approachable voice. Translations must maintain evidence-based credibility while staying warm and accessible. NEVER use Manglish for Dr Stan — keep BM formal and professional.

**Example 1: Dr Stan — Supplement Launch (Ad Copy)**

| Language | Headline | Body |
|----------|----------|------|
| EN | "Your gut called. It wants backup." | "NEW Dr Stan Probiotic+ — 10 billion CFU, 8 clinically-studied strains. Science you can trust, health you can feel." |
| BM | "Usus anda perlukan sokongan." | "BARU Dr Stan Probiotic+ — 10 bilion CFU, 8 strain yang dikaji secara klinikal. Sains yang anda boleh percaya, kesihatan yang anda boleh rasai." |
| ZH | "你的肠道需要增援。" | "全新 Dr Stan Probiotic+ — 100亿CFU，8种经临床研究的菌株。值得信赖的科学，看得见的健康。" |

**Example 2: Dr Stan — Health Education Post (Social Caption)**

EN:
```
Did you know? 70% of your immune system lives in your gut.

That's not a wellness trend — it's peer-reviewed science. Your gut microbiome influences everything from immunity to mood to sleep quality.

Dr Stan Probiotic+ was formulated with 8 clinically-studied strains to support your gut's natural ecosystem. No miracle claims — just evidence-based nutrition.

Science you can trust. 🔬

#DrStan #ScienceYouCanTrust #GutHealth #Probiotics #EvidenceBased
```

BM:
```
Tahukah anda? 70% sistem imun anda terletak di usus.

Ini bukan trend kesihatan — ia adalah sains yang telah dikaji rakan sebaya. Mikrobiom usus anda mempengaruhi segala-galanya daripada imuniti hingga mood dan kualiti tidur.

Dr Stan Probiotic+ diformulasi dengan 8 strain yang dikaji secara klinikal untuk menyokong ekosistem semulajadi usus anda. Tiada dakwaan ajaib — hanya nutrisi berasaskan bukti.

Sains yang anda boleh percaya. 🔬

#DrStan #SainsYangBolehDipercaya #KesihatanUsus #Probiotik #BerasaskanBukti
```

ZH:
```
你知道吗？70%的免疫系统位于你的肠道。

这不是健康潮流 — 这是经同行评审的科学。你的肠道微生物组影响着从免疫力到情绪再到睡眠质量的一切。

Dr Stan Probiotic+ 采用8种经临床研究的菌株配方，支持肠道的天然生态系统。没有奇迹声明 — 只有循证营养。

值得信赖的科学。🔬

#DrStan #值得信赖的科学 #肠道健康 #益生菌 #循证
```

### Serein — Mindfulness & Self-Care Campaigns

Serein embodies tranquillity and mindful luxury. Translations must feel unhurried, gentle, and softly poetic. NEVER use Manglish or urgent/FOMO language for Serein — the brand voice is the antithesis of urgency.

**Example 1: Serein — New Product Drop (Ad Copy)**

| Language | Headline | Body |
|----------|----------|------|
| EN | "Slow down. You deserve this moment." | "Serein Botanical Body Oil — chamomile, lavender, and jojoba, cold-pressed to preserve what nature intended. A ritual, not a routine." |
| BM | "Perlahan. Anda layak untuk momen ini." | "Serein Botanical Body Oil — chamomile, lavender, dan jojoba, ditekan sejuk untuk mengekalkan apa yang alam cipta. Satu ritual, bukan rutin." |
| ZH | "慢下来。你值得这一刻。" | "Serein植物身体精油 — 洋甘菊、薰衣草和荷荷巴，冷压保留大自然的馈赠。一种仪式，而非例行公事。" |

**Example 2: Serein — Evening Ritual Post (Social Caption)**

EN:
```
The world is loud. Your evenings don't have to be.

Light the candle. Warm the oil between your palms. Breathe.

This is not self-care as a checklist. This is self-care as a homecoming.

Be still. Be whole. 🕯️

#Serein #BeStillBeWhole #SlowLiving #MindfulMoments #SelfCareRitual
```

BM:
```
Dunia ini bising. Petang anda tidak perlu begitu.

Nyalakan lilin. Panaskan minyak di tapak tangan. Bernafas.

Ini bukan penjagaan diri sebagai senarai semak. Ini penjagaan diri sebagai pulang ke rumah.

Berdiam. Berseutuh. 🕯️

#Serein #BerdiamBerseutuh #HidupPerlahan #MomenPenuhKesedaran #RitualPenjagaanDiri
```

ZH:
```
世界很喧嚣。你的夜晚不必如此。

点燃蜡烛。在掌心温热精油。呼吸。

这不是清单式的自我关爱。这是回归内心的自我关爱。

静心。完整。🕯️

#Serein #静心完整 #慢生活 #正念时刻 #自我关爱仪式
```

---

## 13. Output Structure

### Canonical Output Paths

All translation outputs MUST be saved to canonical paths. This ensures other skills and automation pipelines can locate translated assets reliably.

```
~/.openclaw/workspace/data/translations/{brand}/
```

### Directory Structure

```
~/.openclaw/workspace/data/translations/
├── pinxin-vegan/
│   ├── ad-copy/
│   │   ├── rendang-bowl-campaign_bm.txt
│   │   ├── rendang-bowl-campaign_zh.txt
│   │   └── ...
│   ├── captions/
│   ├── subtitles/
│   ├── email/
│   ├── product-desc/
│   └── whatsapp/
├── mirra/
│   ├── ad-copy/
│   ├── captions/
│   ├── subtitles/
│   ├── email/
│   ├── product-desc/
│   └── whatsapp/
├── wholey-wonder/
│   ├── ad-copy/
│   ├── captions/
│   ├── subtitles/
│   ├── email/
│   ├── product-desc/
│   └── whatsapp/
├── dr-stan/
│   ├── ad-copy/
│   ├── captions/
│   ├── email/
│   ├── product-desc/
│   └── whatsapp/
├── serein/
│   ├── ad-copy/
│   ├── captions/
│   ├── email/
│   ├── product-desc/
│   └── whatsapp/
├── rasaya/
├── gaia-eats/
├── gaia-learn/
├── gaia-os/
├── gaia-print/
├── gaia-recipes/
├── gaia-supplements/
├── iris/
└── jade-oracle/
```

### File Naming Convention

```
{asset-name}_{lang}.{ext}
```

Examples:
- `weekly-menu-edm_bm.html`
- `rendang-bowl-ad_zh.txt`
- `product-launch-video_bm.srt`
- `smoothie-range-shopee_zh.md`

### Metadata Header (included in every output file)

```yaml
---
source_lang: en
target_lang: bm
brand: wholey-wonder
content_type: ad-copy
platform: meta
translated_at: 2026-03-23T10:00:00+08:00
translator: dreami
qa_status: pending
---
```

### Output Path Resolution

Use the path resolver to get the correct output path:

```bash
bash workspace/scripts/path-resolver.sh --type translations --brand {brand}
# Returns: ~/.openclaw/workspace/data/translations/{brand}/
```

Or construct directly:

```bash
OUTPUT_DIR="$HOME/.openclaw/workspace/data/translations/${BRAND}/${CONTENT_TYPE}"
mkdir -p "$OUTPUT_DIR"
```
