# Jade Oracle — Weekly Content Calendar

> Production schedule for @the_jade_oracle Instagram.
> Each day has a content type, format recommendation, and hook pattern.
> Auto-research loop optimizes within each type; this calendar provides structure.

## Content Calendar Philosophy

Jade's feed tells a story across the week:
- **Early week** = teach and prove (build trust)
- **Mid week** = show and connect (build relationship)
- **Late week** = feel and engage (build community)
- **Weekend** = rest and reflect (build loyalty)

Every post follows the same production pipeline:
1. Generate via `jade-content-pipeline.yaml` (auto-research inner loop)
2. Quality-multiply via `fast-iterate` (3 rounds, score > 8/10)
3. Pass `QUALITY-GATE.md` checklist (6 gates)
4. Schedule via Later/Buffer or manual post

---

## Monday — Educational

**Content type:** QMDJ explainer, BaZi basics, Five Elements, how readings work
**Goal:** Position Jade as a credible authority. Build "I learned something" response.
**Recommended format:** Carousel (5-7 slides) or Reel with text overlays
**Hook patterns that work:**
- Curiosity-with-number: "You have 8 palaces in your chart. Most people ignore #4."
- Myth-busting: "BaZi is NOT the same as your horoscope. Here's why."
- Framework reveal: "The 5 elements explain why some weeks feel heavy."

**Caption structure:**
```
Hook (1 line — stop the scroll)
↓
Context (2-3 lines — why this matters to YOU)
↓
Teaching (3-5 lines — the actual insight, use simple language)
↓
Application (2 lines — how to use this in your life THIS WEEK)
↓
CTA: "Save this for later" or "Want your own chart? Link in bio"
```

**Visual direction:**
- Jade at her reading table with props (tarot cards, jade stones, tea)
- Text-overlay slides: Cormorant Garamond headings, Jost body, cream background
- Diagrams/charts: hand-drawn style on cream paper, jade green ink
- Lighting: warm natural window light

**Performance benchmark:** Saves > 500, Comments > 30
**Auto-research config:** `CONTENT_TYPE=educational bash auto-loop.sh jade-content-pipeline.yaml`

---

## Tuesday — Social Proof

**Content type:** Testimonial, review highlight, client transformation story
**Goal:** Reduce buying friction. Answer "does this actually work?"
**Recommended format:** Story-style carousel or screenshot collage with context
**Hook patterns that work:**
- Transformation: "She almost didn't book the reading. 3 months later..."
- Direct quote: "'I've never felt so understood by a reading' — Sarah, 34"
- Result-led: "One reading changed how she made her biggest career decision"

**Caption structure:**
```
Hook (the transformation or quote)
↓
Context (who this person was before the reading — relatable pain)
↓
Turning point (what the reading revealed)
↓
Result (where they are now — specific, not vague)
↓
CTA: "Your reading is waiting. $1 to start — link in bio"
```

**Visual direction:**
- Screenshot of real DM/review (with permission, name blurred or first name only)
- Jade smiling warmly — "this is what I live for" expression
- Before/after energy: muted/uncertain → warm/clear
- Subtle jade green highlight on the key quote

**Performance benchmark:** DMs > 10, Link clicks > 50
**Auto-research config:** `CONTENT_TYPE=social_proof bash auto-loop.sh jade-content-pipeline.yaml`

**Guidelines:**
- NEVER fabricate testimonials — use real feedback or clearly mark as composite
- Always get permission before sharing DMs
- Anonymize unless client explicitly consents to name use
- Focus on emotional transformation, not supernatural claims

---

## Wednesday — Lifestyle

**Content type:** Jade's day, behind the scenes, reading setup, tea ritual, personal moment
**Goal:** Build parasocial intimacy. Make followers feel like they KNOW Jade.
**Recommended format:** Photo series (3 images) or casual Reel (30-60 seconds)
**Hook patterns that work:**
- Personal reveal: "My morning starts before the sun — here's why"
- Behind-scenes: "This is where every reading happens (and yes, tea is mandatory)"
- Relatable: "Some days the cards are quiet. Today was one of those days."

**Caption structure:**
```
Hook (personal, warm, slightly vulnerable)
↓
Scene-setting (paint a sensory picture — what you see, hear, smell)
↓
Reflection (a small insight or realization from the moment)
↓
Connection (invite the reader into their own version of this moment)
↓
CTA: soft — "What's your morning ritual?" or no CTA at all
```

**Visual direction:**
- Natural, unposed feel — Jade in her space
- Wardrobe: oatmeal cardigan, cream linen, sage green — casual warmth
- Props: ceramic mug, reading nook, plants, natural light, candles
- Photo style: iPhone-feeling warmth, not over-produced
- Lighting: golden hour or soft overcast morning light

**Performance benchmark:** Comments > 50, Shares > 20 (personal content gets shared)
**Auto-research config:** `CONTENT_TYPE=lifestyle bash auto-loop.sh jade-content-pipeline.yaml`

---

## Thursday — Reading Demo

**Content type:** Mini reading, oracle card pull, weekly energy snapshot, live interpretation
**Goal:** Show the PRODUCT in action. Let viewers experience a micro-reading.
**Recommended format:** Reel (45-90 seconds) — highest engagement format
**Hook patterns that work:**
- Suspense: "I pulled three cards for this week. The middle one made me pause."
- Direct demo: "Let me read the energy for the next 7 days — right now."
- Personal: "Today's QMDJ chart has something unusual in the Life Palace."

**Caption structure:**
```
Hook (suspense or direct — promise a reveal)
↓
The reading (summarize 2-3 key insights, use natural Jade voice)
↓
Interpretation (what this means for the viewer's life THIS week)
↓
Invitation (this was a general reading — your personal one goes deeper)
↓
CTA: "$1 intro reading — I'll look at YOUR chart. Link in bio."
```

**Visual direction:**
- REEL: Jade's hands shuffling/pulling cards, jade pendant visible, warm overhead
- Cut to: Jade interpreting, looking at camera with warm knowing expression
- Text overlays: card names, key phrases, element symbols
- Background: reading table setup, sage linen, candles lit, tea steam
- Music: lo-fi or ambient instrumental (no lyrics, no trending audio)

**Performance benchmark:** Saves > 800, Shares > 40, Link clicks > 80
**Auto-research config:** `CONTENT_TYPE=reading_demo bash auto-loop.sh jade-content-pipeline.yaml`

**Video production notes:**
- Use Remotion pipeline at `/tmp/video-compiler/` for text overlays
- Face-lock reference: v22 in `~/Desktop/gaia-projects/jade-oracle-site/images/jade/v15-v22/`
- Keep total under 90 seconds — Instagram rewards completion rate
- First 3 seconds MUST hook — no intro logos, no "hey guys"

---

## Friday — Emotional / Relatable

**Content type:** Pain point to solution, relatable spiritual struggle, "you're not alone"
**Goal:** Viral reach. Emotional content gets shared the most.
**Recommended format:** Text overlay on lifestyle photo or emotional Reel
**Hook patterns that work:**
- Vulnerability: "Nobody tells you that your 30s feel like starting over"
- Universal truth: "You're not lost. You're in between who you were and who you're becoming."
- Counter-narrative: "Stop asking the universe for signs. Start asking better questions."

**Caption structure:**
```
Hook (hit the nerve — one line that makes them stop scrolling)
↓
Expansion (2-3 lines deepening the emotional truth)
↓
The shift (where ancient wisdom meets modern reality)
↓
Hope (not toxic positivity — genuine, grounded reassurance)
↓
CTA: "Send this to someone who needs it" or "Save this for your hard days"
```

**Visual direction:**
- Jade in a contemplative moment — looking out a window, holding tea, soft focus
- Text overlay: powerful hook in Cormorant Garamond, cream on dark background
- Color mood: warm muted tones, burgundy + cream dominant
- No props, no busy backgrounds — let the words breathe
- Lighting: moody golden hour, single light source

**Performance benchmark:** Shares > 100, Comments > 80 (this is the viral day)
**Auto-research config:** `CONTENT_TYPE=emotional bash auto-loop.sh jade-content-pipeline.yaml`

---

## Saturday — Community

**Content type:** Q&A, polls, "which element are you?", engagement prompts, quiz
**Goal:** Boost comments and saves. Train the algorithm with high engagement.
**Recommended format:** Carousel quiz or Stories poll series + feed recap
**Hook patterns that work:**
- Quiz: "Your birth month reveals your dominant element. Find yours."
- Q&A: "You asked, Jade answers: your top 5 questions about QMDJ"
- This-or-that: "Wood energy or Fire energy? (Your answer says a lot about you)"

**Caption structure:**
```
Hook (interactive prompt — make them DO something)
↓
Context (why this is fun AND meaningful)
↓
The prompt (clear instruction: "Comment your birth month" or "Save and screenshot")
↓
Jade's take (her personal answer — models the engagement)
↓
CTA: "Drop your [answer] in the comments — I'll reply to the first 20"
```

**Visual direction:**
- Bright, clean, graphic-style slides — jade green + cream + gold
- Large readable text — optimized for Story resharing
- Jade's face in at least one slide (humanizes the quiz)
- Element symbols, zodiac glyphs, or simple icons as visual anchors
- Grid-friendly: first slide works as both Story and feed thumbnail

**Performance benchmark:** Comments > 100, Story reshares > 30
**Auto-research config:** `CONTENT_TYPE=community bash auto-loop.sh jade-content-pipeline.yaml`

---

## Sunday — Spiritual

**Content type:** Weekly oracle message, meditation prompt, gratitude, gentle affirmation
**Goal:** End the week with warmth. Build the ritual of "Sunday = Jade's message."
**Recommended format:** Single image with text overlay or gentle voice-note Reel
**Hook patterns that work:**
- Oracle message: "This week's message from the Jade Oracle: 'Rest is not retreat.'"
- Meditation: "Close your eyes. Take one breath. This week is already complete."
- Gratitude: "Three things the universe showed me this week."

**Caption structure:**
```
The message (no hook needed — Sunday is slow. Lead with beauty.)
↓
Expansion (gentle, poetic — not teaching, not selling, just being)
↓
Invitation (join the stillness — "light a candle and sit with this")
↓
Blessing ("May your week ahead be..." — Jade's signature sign-off)
↓
CTA: none or very soft — "Save this as your weekly intention"
```

**Visual direction:**
- Minimalist: jade stone on cream linen, single candle, soft focus
- Or: Jade in meditation, eyes closed, warm light, jade pendant catching light
- Color: cream dominant, sage + gold accents — most muted day of the week
- Typography: Cormorant Garamond only — elegant, spacious, centered
- Mood: temple quietness, morning tea steam, gratitude

**Performance benchmark:** Saves > 600 (this is the most-saved day), Shares > 40
**Auto-research config:** `CONTENT_TYPE=spiritual bash auto-loop.sh jade-content-pipeline.yaml`

---

## Posting Schedule

| Day | Time (MYT) | Time (EST) | Time (PST) | Content Type |
|-----|-----------|-----------|-----------|--------------|
| Mon | 8:00 AM | 8:00 PM (Sun) | 5:00 PM (Sun) | Educational |
| Tue | 7:30 AM | 7:30 PM (Mon) | 4:30 PM (Mon) | Social Proof |
| Wed | 8:00 AM | 8:00 PM (Tue) | 5:00 PM (Tue) | Lifestyle |
| Thu | 7:00 AM | 7:00 PM (Wed) | 4:00 PM (Wed) | Reading Demo |
| Fri | 8:30 AM | 8:30 PM (Thu) | 5:30 PM (Thu) | Emotional |
| Sat | 9:00 AM | 9:00 PM (Fri) | 6:00 PM (Fri) | Community |
| Sun | 10:00 AM | 10:00 PM (Sat) | 7:00 PM (Sat) | Spiritual |

**Why these times?** 7-9am MYT catches evening scroll in US/EU (double timezone hit).
Weekend times are slightly later — audience is more relaxed, scrolling later.

## Stories Strategy (Daily)

In addition to the feed post, publish 3-5 Stories daily:
1. **Teaser** (1 hr before feed post): "New post coming... here's a sneak peek"
2. **Behind-scenes** (spontaneous): Raw moment from Jade's day
3. **Engagement** (afternoon MYT): Poll, question box, or quiz
4. **Reshare** (evening MYT): Reshare the feed post with "in case you missed it"
5. **Night thought** (10pm MYT): Short reflective text — builds the "Jade is always here" feeling

## Monthly Themes (Rotate Quarterly)

| Month | Theme | Focus |
|-------|-------|-------|
| Month 1 | "Know Your Chart" | BaZi basics, element discovery, self-awareness |
| Month 2 | "Timing Is Everything" | QMDJ timing, decision windows, strategic action |
| Month 3 | "Inner Oracle" | Intuition development, meditation, personal power |

## KPIs to Track

| Metric | Weekly Target | Monthly Target |
|--------|--------------|----------------|
| Engagement rate | > 5% | > 5.5% |
| Follower growth | > 200/week | > 1,000/month |
| Saves per post | > 300 avg | > 400 avg |
| DMs per day | > 5 | > 150/month |
| $1 reading conversions from IG | > 10/week | > 50/month |
| Email list signups from IG | > 20/week | > 100/month |

---

*This calendar is a living document. Auto-research learnings update the hook patterns,
format recommendations, and benchmark targets as real performance data accumulates.*

*Last updated: 2026-03-22*
*Config: `~/.openclaw/skills/auto-research/configs/jade-content-pipeline.yaml`*
*Feedback loop: `~/.openclaw/skills/auto-research/configs/jade-instagram-loop.yaml`*
