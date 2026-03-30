# Pinxin Vegan — Copy Doctrine

> Production playbook for all copywriting. Every headline, caption, and ad must follow these rules.
> **Production-proven**: Copy voice patterns from v4_campaign (22 ads, "sales sifu" voice), cn-ads-v4 (24 CN ads, persona-driven headlines), march_campaign_v3 (5 pillars × 6 ACCA stages = 30 variants).
> **Key learning from cn-ads-v4**: Every variant needs unique `entity_hypothesis` + `sara_mindstate` (emotional journey). Never reuse testimonials across variants. Chinese headlines must be crafted per persona, not translated from English.

---

## VOICE IDENTITY

### Who We Sound Like
A **Malaysian Chinese aunty who's secretly sophisticated**. She talks like your family — warm, direct, a little dramatic — but her taste is impeccable. She doesn't lecture about veganism. She makes you hungry first, then you discover it's plant-based.

### Voice Rules
1. **Food-first, vegan-second** — Lead with taste, texture, cravings. Never lead with "plant-based" or "vegan"
2. **Family language** — "阿嬷的味道", "全家人爱吃", "三代人的选择". Multi-generational is the default
3. **Specific numbers always** — "慢熬3-4小时", "50%低钠", "15分钟上桌", "RM13+/盒". Never vague claims
4. **No preaching** — Never "save the planet", "animal cruelty", "go vegan". We SELL FOOD, not ideology
5. **Penang pride** — Heritage is a weapon. "槟城古早味", "正宗娘惹", CNN #7, Tatler Top 10
6. **Bilingual but separate** — CN and EN are different executions, not translations. CN is warmer, more family. EN is benefit-forward
7. **Confidence, not desperation** — Never "please try us". Always "11,000户槟城家庭的选择"

### Tone by Funnel Stage (ACCA from march_campaign_v3)
| Stage | Tone | Energy | sara_mindstate pattern |
|-------|------|--------|----------------------|
| Awareness | Storytelling, cultural, emotional | Warm, inviting | curiosity → recognition → belonging |
| Comprehension | Educational, benefit-driven, proof | Confident, specific | skepticism → understanding → trust |
| Conviction | Urgent, price-anchored, social proof | Direct, no-nonsense | hesitation → confidence → decision |
| Action | CTA-heavy, CTWA, WhatsApp | Commanding, simple | intent → friction-free → satisfaction |

### Entity Hypothesis (from cn-ads-v4 — required for every ad variant)
Every ad must define WHO this person is and WHAT emotional journey they take:
```
entity_hypothesis: "time-starved mother seeking family meal solution"
sara_mindstate: "guilt → relief → pride"
```
This prevents generic ads. Forces persona-specificity at the prompt level.

---

## HEADLINE FORMULAS

### Chinese Headlines (Primary)

**Formula 1: Challenge + Solution**
```
[Pain point]？品馨帮你搞定！
Examples:
- 忙到没时间煮饭？15分钟品馨帮你搞定！
- 三高不敢乱吃？品馨50%低钠盐安心吃！
- 初一十五不知道煮什么？品馨12道菜任你选！
```

**Formula 2: Specific Number + Benefit**
```
[Number] + [Specific benefit]
Examples:
- 慢熬3-4小时，比肉还好吃
- 50%低钠盐，阿公安心吃
- 15分钟上桌，忙妈妈的救星
- 12道菜，一个冰箱搞定一周
- RM13+一盒，全家人吃好料
```

**Formula 3: Cultural Hook**
```
[Cultural reference] + [Product relevance]
Examples:
- 南洋古早味，品馨帮你留住
- 阿嬷的味道，不用自己煮
- 三代人都爱吃的仁当
- 初一十五，品馨素食积德
```

**Formula 4: Testimonial/Proof**
```
[Authority] + [Specific claim]
Examples:
- Tatler Asia评选：全马最好吃叻沙Top 10，唯一植物基
- 11,000户槟城家庭的选择
- "比非素还好吃" — 新海峡时报
- 全马第一家植物基冷冻餐
```

**Formula 5: Comparison/Subversion**
```
[Expectation] vs [Reality]
Examples:
- 以为是肉？其实是猴头菇！
- 不是假肉，是真菌菇
- 看起来像妈妈煮的，其实15分钟搞定
- 零胆固醇，味道满分
```

**Formula 6: Urgency/BOFU**
```
[Offer] + [Constraint]
Examples:
- 买14盒送6盒，限时优惠！
- 免运费！西马RM250以上
- 新年团购价，最低RM13+/盒
- 今天下单，明天到！
```

### English Headlines

**Formula 1: Benefit-Forward**
```
Examples:
- 15 Minutes to an Authentic Penang Dinner
- 50% Lower Sodium. 100% Penang Flavor.
- No Mock Meat. Just Real Mushroom Magic.
- The Only Plant-Based Laksa on Tatler Asia's Top 10
```

**Formula 2: Subversion**
```
Examples:
- Can't Tell It's Vegan? That's the Point.
- Your Grandmother's Rendang. Without the Cholesterol.
- 3-4 Hours of Slow-Cooking. 15 Minutes for You.
```

**Formula 3: Direct-Response**
```
Examples:
- From RM13+ Per Meal. Free Delivery Above RM250.
- 12 Dishes. 1 Freezer. Dinner Sorted.
- Buy 14, Get 6 Free. Limited Time.
```

---

## BENEFIT HIERARCHY (Always Use This Order)

### Tier 1: Taste & Authenticity (LEAD WITH THIS)
- 慢熬3-4小时 / Slow-cooked 3-4 hours
- 正宗槟城味 / Authentic Penang flavor
- 比非素还好吃 / Tastes better than non-vegan
- 猴头菇比肉还嫩 / Lion's Mane tenderer than meat
- 阿嬷的古早味 / Grandmother's heritage taste

### Tier 2: Health & Safety
- 50%低钠湖盐 / 50% lower sodium Lake Salt
- 有机原蔗糖 / Organic unrefined cane sugar
- 零胆固醇 / Zero cholesterol
- 无味精 / No MSG
- 无蒜无葱 / Allium-free (pure vegetarian safe)
- 无麸质假肉 / No gluten-based mock meats
- 三高友好 / 3-highs friendly

### Tier 3: Convenience
- 15分钟上桌 / 15 minutes to table
- 解冻即食 / Defrost and eat
- 不用切不用煮 / No chopping, no cooking
- 12道菜选择 / 12 dish choices
- 1年保质期 / 1-year shelf life

### Tier 4: Social Proof
- Tatler Asia Top 10 叻沙
- CNN全球美食#7
- 11,000+槟城家庭
- 全马第一植物基冷冻餐
- 新海峡时报认证

### Tier 5: Price/Value (BOFU only)
- RM13+/盒 starting price
- 买14送6 bundle deal
- 免运费 free delivery thresholds
- 团购优惠 group buy discounts

---

## COPY BY CATEGORY

### CAT-01: Heritage Story
```
CN: Emotional, storytelling. 100-150 chars.
"品，是对味道的坚持。馨，是创办人Audrey的名字。8年前的一个厨房，
一个母亲的爱，慢熬出全马第一家植物基冷冻餐。"

EN: Brand story, editorial. 80-120 words.
"Pin means quality of taste. Xin means delectable aroma — and it's our
founder Audrey's name. What started in a Georgetown kitchen 8 years ago
is now Malaysia's first plant-based frozen meal brand."
```

### CAT-02: Dish Hero
```
CN: Dish name (massive) + 1 benefit + 1 USP. 50-80 chars.
"南洋古早仁当猴头菇
慢熬3-4小时 | 零胆固醇 | 15分钟上桌"

EN: Dish name + hero benefit. 30-50 words.
"Rendang Hericium Mushroom
Slow-cooked 3-4 hours. Zero cholesterol.
Tenderer than meat — and you'll never guess it's plant-based."
```

### CAT-03: Benefit/USP
```
CN: Specific number + benefit + proof. 60-100 chars.
"为什么品馨用50%低钠湖盐？
因为阿公的血压，比口味更重要。
含钾+镁，护心更安心。"

EN: Benefit headline + 3 bullets. 60-80 words.
"50% Lower Sodium. Still Full Flavor.
• Lake Salt Light with potassium & magnesium
• Organic unrefined cane sugar — no bleached white sugar
• Zero MSG, zero artificial additives
Your family's health isn't a compromise."
```

### CAT-06: Promo
```
CN: Price + offer + urgency. 40-60 chars.
"年终大促！买14盒送6盒！
一盒最低RM13+ | 免运费西马RM250以上
限时优惠，手慢无！"

EN: Offer + price anchor + CTA. 30-50 words.
"Buy 14, Get 6 Free.
From RM13+ per meal. Free delivery above RM250.
20 meals in your freezer = dinner sorted for 2 weeks."
```

### CAT-09: Raw Ad
```
CN: Ultra-direct. 20-40 chars.
"RM17.75/餐
正宗槟城味 | 15分钟上桌
👉 WhatsApp下单"

EN: Price-first. 15-30 words.
"RM17.75 per meal.
Real Penang flavor. Ready in 15 minutes.
Free delivery West Malaysia above RM250.
Order on WhatsApp →"
```

### CAT-10: XHS Native
```
CN: Diary-style, first-person, emoji-friendly. 80-120 chars.
"打工人的15分钟素食晚餐 🍱
今天开了品馨的经典咖喱猴头菇
说真的，比外面卖的还好吃 😭
而且零胆固醇！瘦身期也能吃！
#素食便当 #打工人的晚餐 #品馨蔬食"
```

---

## WORDS WE USE vs WORDS WE DON'T

### Always Use ✓
| CN | EN |
|----|-----|
| 古早味 | Heritage flavor |
| 慢熬 | Slow-cooked |
| 猴头菇 | Hericium / Lion's Mane |
| 全家人 | The whole family |
| 阿嬷的味道 | Grandmother's taste |
| 正宗槟城 | Authentic Penang |
| 安心吃 | Eat with confidence |
| 好料 | Good stuff (MY slang) |

### Never Use ✗
| Avoid | Why | Replace With |
|-------|-----|-------------|
| 素肉 / mock meat | We don't use mock meat — it's a key USP | 猴头菇 / real mushroom |
| Plant-based (as lead) | Food-first, label-second | Lead with dish name |
| Save animals / go vegan | We don't preach | (omit entirely) |
| Healthy (vague) | Too generic | 50%低钠 / zero cholesterol (specific) |
| Organic (alone) | Must specify what | 有机原蔗糖 organic cane sugar |
| Cheap / affordable | We're premium | 值得 / worth it / RM13+ |
| Try us / please | Desperate energy | 11,000户家庭的选择 |
| ! (exclamation marks) | Overused, cheap feel | Period or no punctuation |

---

## CTA PATTERNS

### WhatsApp/CTWA (Primary conversion)
```
CN: "WhatsApp下单 →", "点击订购", "立即购买"
EN: "Order on WhatsApp →", "Shop now", "Get yours"
```

### Website
```
CN: "浏览全部菜单 →", "查看详情"
EN: "Browse all dishes →", "See the full menu"
```

### Engagement
```
CN: "你最想试哪道？", "Tag一个爱吃辣的朋友", "收藏这个食谱"
EN: "Which dish would you try first?", "Save for dinner inspo"
```

---

## PERSONA-SPECIFIC COPY ANGLES

### Persona 1: 忙妈妈 (Busy Mum) — PRIMARY
**Pain**: No time to cook, guilty about feeding family processed food
**Hook**: "15分钟上桌，孩子以为妈妈亲手煮的"
**USPs to lead**: Convenience (15 min) → Taste (slow-cooked) → Health (no MSG)

### Persona 2: 三高阿公 (3-Highs Uncle/Grandpa)
**Pain**: Health restrictions, boring diet, misses traditional flavors
**Hook**: "50%低钠盐，阿公安心吃古早味"
**USPs to lead**: Health (low sodium) → Taste (heritage) → Allium-free

### Persona 3: 素食信仰者 (Religious/Festival Vegetarian)
**Pain**: Hard to find tasty allium-free options for 初一十五
**Hook**: "初一十五不知道煮什么？品馨帮你准备好了"
**USPs to lead**: Allium-free → Variety (12 dishes) → Taste

### Persona 4: 打工人 (Office Worker)
**Pain**: Too tired to cook after work, eating unhealthy
**Hook**: "下班后15分钟，正宗槟城味端上桌"
**USPs to lead**: Convenience → Taste → Health (zero cholesterol)

### Persona 5: 健康养生族 (Health-Conscious)
**Pain**: Wants clean eating without sacrificing flavor
**Hook**: "零胆固醇、零味精，但味道满分"
**USPs to lead**: Health (all claims) → Taste → Ingredients (hericium)

### Persona 6: 新加坡华人 (Singapore Chinese) — EXPANSION
**Pain**: Misses Penang food, can't find authentic vegan options
**Hook**: "想念槟城味？品馨直送新加坡"
**USPs to lead**: Penang authenticity → Delivery → Taste

---

## HASHTAG BANKS

### CN (XHS + IG)
```
Core: #品馨蔬食 #植物基 #素食 #槟城美食
Dish: #猴头菇 #仁当 #叻沙 #咖喱 #巴生肉骨茶
Lifestyle: #素食便当 #打工人的晚餐 #15分钟晚餐 #健康饮食
Cultural: #初一十五 #吃素 #南洋古早味 #娘惹美食
```

### EN (IG + FB)
```
Core: #PinxinVegan #PlantBased #VeganMalaysia #PenangFood
Dish: #HericiumMushroom #Rendang #AsamLaksa #VeganBKT
Lifestyle: #MealPrep #QuickDinner #HealthyEating #VeganMeals
Cultural: #MalaysianFood #NyonyaFood #HeritageRecipe
```
