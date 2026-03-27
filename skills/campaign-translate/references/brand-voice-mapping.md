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
