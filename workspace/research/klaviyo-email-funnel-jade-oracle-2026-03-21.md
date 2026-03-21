# Jade Oracle -- Klaviyo Email & SMS Marketing Funnel
## Complete Flow Architecture for jadeoracle.co

**Date:** 2026-03-21
**Brand:** Jade Oracle (Qi Men Dun Jia psychic readings)
**Platform:** Shopify + Klaviyo + SMS
**Store URL:** jadeoracle.co

---

## Table of Contents

1. [Product Ladder Reference](#product-ladder)
2. [Signup Incentive Strategy](#signup-incentive)
3. [Flow 1: Welcome Series](#flow-1-welcome-series)
4. [Flow 2: Abandoned Cart Recovery](#flow-2-abandoned-cart-recovery)
5. [Flow 3: Post-Purchase Upsell](#flow-3-post-purchase-upsell)
6. [Flow 4: Win-Back (Lapsed Customers)](#flow-4-win-back)
7. [Flow 5: Browse Abandonment](#flow-5-browse-abandonment)
8. [SMS Integration Strategy](#sms-integration)
9. [Segmentation Strategy](#segmentation-strategy)
10. [Design System](#design-system)
11. [Implementation Checklist](#implementation-checklist)

---

## Product Ladder

| Product | Price | SKU | Delivery |
|---------|-------|-----|----------|
| Quick Insight Reading | $1 | JO-QUICK-001 | Telegram, 24h |
| Love & Relationship Reading | $29 | JO-LOVE-001 | PDF, 24h |
| Full Destiny Reading | $49 | JO-DESTINY-001 | PDF + voice note, 48h |
| VIP Mentorship (3 months) | $497 | JO-VIP-001 | Ongoing |

---

## Signup Incentive Strategy

### Primary Offer: "Free Mini Birth Chart Preview + 15% Off"

**What the subscriber receives:**
- A personalized mini birth chart snapshot (auto-generated or templated based on birth date/time input at signup)
- Discount code `JADE15` valid for 7 days on any reading
- Entry into the "Jade's Inner Circle" email list

**Why this works:**
- The birth chart preview delivers immediate, personalized value (spiritual brands see 40-60% higher opt-in rates with personalized lead magnets vs. generic discounts)
- Requiring birth date/time at signup creates a micro-commitment and provides data for future personalization
- The 7-day expiry creates natural urgency without feeling pushy

### Signup Form Design

**Exit-intent popup (desktop):**
- Headline: "The stars have something to tell you"
- Subhead: "Enter your birth details for a free mini chart preview + 15% off your first reading"
- Fields: Name, Email, Birth Date, Birth Time (optional), Birth City (optional)
- CTA: "Reveal My Chart"
- Visual: Dark background (#0a0a0a), gold (#c9a84c) accents, Jade portrait in corner

**Mobile slide-up:**
- Same copy, simplified to: Name, Email, Birth Date
- CTA: "Show Me"

**Embedded newsletter (footer):**
- "Get weekly celestial insights from Jade"
- Fields: Email only
- CTA: "Join the Circle"

**Klaviyo list:** `jade-inner-circle`
**Klaviyo tag on signup:** `lead-source:popup`, `lead-source:footer`, `lead-source:landing-page`

---

## Flow 1: Welcome Series

**Trigger:** Added to list `jade-inner-circle` (email captured via popup, footer, or landing page)
**Goal:** Educate, build trust, convert to first purchase (Quick Insight $1)
**Filter:** Exclude anyone who has already placed an order

---

### Email 1: Immediate -- "Your Birth Chart Preview Is Here"

**Subject line options (A/B test):**
- A: "Your stars are speaking, {{first_name|default:'beautiful soul'}}"
- B: "I pulled your birth chart -- here's what I see"

**Preview text:** "A glimpse into what the cosmos mapped for you at birth..."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> I'm Jade, and I'm so glad you found your way here. The universe doesn't do accidents.
>
> You entered this world on {{birth_date}} -- and the celestial map at that moment tells a powerful story.
>
> **Here's your Mini Birth Chart Preview:**
>
> [DYNAMIC BLOCK: Mini chart image/summary based on birth date]
>
> Your dominant element is [X]. This means you naturally carry [trait] energy -- which explains why you've always felt [relatable insight].
>
> But this is just a glimpse. The full picture -- your career timing, love compatibility, health constitution, and wealth pathways -- lives in the complete Qi Men Dun Jia destiny chart.
>
> As a welcome gift, here's 15% off any reading:
>
> **Code: JADE15** (expires in 7 days)
>
> The easiest way to start? Our $1 Quick Insight Reading -- one burning question, answered through 4,000 years of astronomical wisdom.
>
> With light,
> Jade

**CTA button:** "Ask Your First Question -- $1" -> `https://jadeoracle.co/products/quick-insight-reading?discount=JADE15`

**Design notes:**
- Dark background (#0a0a0a), gold heading text (#c9a84c)
- Jade portrait (warm, approachable) in email header
- Mini chart visual (stylized, not raw data)
- Gold divider lines between sections
- Font: elegant serif for headings, clean sans-serif for body

---

### Email 2: Day 1 -- "What Is QMDJ? (The Emperor's Secret)"

**Subject line options (A/B test):**
- A: "The divination system Chinese emperors kept secret for centuries"
- B: "Why Western astrology only tells you 10% of the story"

**Preview text:** "Qi Men Dun Jia isn't astrology. It's astronomical calculation..."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> You've probably seen your Western zodiac sign a thousand times. Maybe you've read your Chinese zodiac too.
>
> But I want to share something most people in the West have never heard of -- and once you understand it, you'll never look at "horoscopes" the same way again.
>
> **Qi Men Dun Jia (QMDJ)** -- literally "Mysterious Gates Escaping Technique" -- is a 4,000-year-old Chinese metaphysical system that was classified as a state secret for centuries. Only emperors and their top military strategists were allowed to use it.
>
> Why? Because it works.
>
> **How QMDJ differs from Western astrology:**
>
> | | Western Astrology | QMDJ |
> |--|---|---|
> | Based on | Sun sign (12 types) | Full astronomical data at birth |
> | Precision | General personality traits | Specific timing + life mapping |
> | Action-oriented | "You're a Scorpio" | "Move on this opportunity in March" |
> | Predictive power | Vague weekly horoscopes | Precise windows for career, love, health |
>
> QMDJ doesn't put you in a box. It maps the exact energetic landscape of your life -- and tells you WHEN to act for maximum alignment.
>
> That's what I do. I read your chart. I find the timing. I translate 4,000 years of wisdom into guidance you can use TODAY.
>
> Ready to experience it?
>
> With light,
> Jade

**CTA button:** "Get Your Quick Insight -- Just $1" -> `https://jadeoracle.co/products/quick-insight-reading?discount=JADE15`

**Design notes:**
- Include a simple, elegant infographic comparing Western astrology vs. QMDJ
- Background: dark with subtle celestial pattern
- Gold accent on comparison table borders

---

### Email 3: Day 3 -- "Sarah's Story (She Almost Didn't Ask)"

**Subject line options (A/B test):**
- A: "She almost didn't get the reading. Then this happened."
- B: "Sarah K. asked one question -- it changed everything"

**Preview text:** "\"I was skeptical. Then Jade told me something no one could have known...\""

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> I want to share something personal today.
>
> Sarah K. signed up for a $1 Quick Insight Reading three months ago. She almost didn't do it. "I've been burned by psychics before," she told me.
>
> Her question was simple: "Should I take this new job offer?"
>
> When I pulled her QMDJ chart, something jumped out immediately. The timing was wrong. Not the job itself -- but the WHEN. Her chart showed a major energy shift coming in 6 weeks that would completely change the negotiation dynamics.
>
> I told her: "Wait. Don't say yes yet. In 6 weeks, you'll have leverage you can't see right now."
>
> She waited.
>
> Six weeks later, the company came back with a counter-offer -- 40% higher than the original. A second company also reached out. She had options she never imagined.
>
> Here's what Sarah said:
>
> > *"I was skeptical about all of this. But Jade didn't give me vague advice -- she gave me a DATE. And she was right. I've never experienced anything like QMDJ. It's not woo-woo. It's precision."*
> > -- Sarah K., San Francisco
>
> Sarah went on to get the Full Destiny Reading. Then the Love Reading. She's now one of my VIP mentorship clients.
>
> It all started with one $1 question.
>
> What's YOUR question?
>
> With light,
> Jade

**CTA button:** "Ask Your Question -- $1" -> `https://jadeoracle.co/products/quick-insight-reading?discount=JADE15`

**Design notes:**
- Pull quote styled with gold left border and italic text
- Sarah's testimonial in a card-style block with subtle glow
- Star rating visual (5 stars, gold)

---

### Email 4: Day 5 -- "Your Chart Alignment Window Is Closing"

**Subject line options (A/B test):**
- A: "{{first_name}}, your alignment window closes in 48 hours"
- B: "The cosmic timing I see for you right now won't last"

**Preview text:** "There's a window in your chart this week. After that, the energy shifts..."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> I don't say this to create false urgency. If you've been reading my emails, you know I'm not that kind of reader.
>
> But I need to be honest with you.
>
> The celestial configuration right now -- specifically the alignment of the [current relevant QMDJ reference, e.g., "Kai Men (Open Gate)"] -- creates an unusually clear window for new beginnings and first readings.
>
> In QMDJ, timing isn't everything. It's the ONLY thing.
>
> You can ask the same question on a different day and get a completely different energetic landscape. That's because QMDJ isn't about your personality. It's about the MOMENT.
>
> Right now, the moment is favorable for:
> - Asking questions about career direction
> - Exploring relationship compatibility
> - Understanding health patterns
> - Finding clarity on decisions you've been putting off
>
> Your 15% discount code (JADE15) expires in 48 hours.
>
> And more importantly -- this alignment window shifts soon.
>
> If you've been curious, now is the time.
>
> With light,
> Jade

**CTA button:** "Get My Reading Before the Window Closes" -> `https://jadeoracle.co/products/quick-insight-reading?discount=JADE15`

**Design notes:**
- Subtle countdown timer graphic (not a live countdown -- just a visual cue)
- Celestial/constellation background element
- Slightly more urgent tone in design (gold CTA button with glow effect)

---

### Email 5: Day 7 -- "What Are You Afraid to Know?"

**Subject line options (A/B test):**
- A: "What are you afraid to know, {{first_name}}?"
- B: "Last chance: JADE15 expires tonight"

**Preview text:** "Sometimes the thing holding us back isn't doubt. It's knowing we'll have to act."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> This is my last email about your welcome gift. After today, the JADE15 code expires.
>
> But I want to leave you with something more important than a discount.
>
> In my years as a QMDJ practitioner, I've noticed something. The people who hesitate longest before getting a reading aren't the skeptics. Skeptics either try it or they don't.
>
> The ones who hesitate? They already feel the truth. They KNOW something is shifting. They're not afraid the reading will be wrong.
>
> They're afraid it will be right.
>
> Because if the reading confirms what they already sense -- about the relationship, the career, the decision they've been avoiding -- then they'll have to do something about it.
>
> I understand that fear. I've felt it myself.
>
> But here's what I've learned: the universe doesn't give you information you're not ready to handle. If you're here, reading this email, you're ready.
>
> **$1. One question. One answer from the cosmos.**
>
> Your code JADE15 (15% off) expires at midnight tonight. But honestly? The $1 Quick Insight doesn't even need a discount. It's already the most accessible entry point I offer.
>
> This is really about whether you're ready to ask.
>
> I think you are.
>
> With light and always in your corner,
> Jade
>
> P.S. If the Quick Insight isn't enough and you want the full picture, you can go straight to the Full Destiny Reading ($49). JADE15 works on everything.

**CTA button (primary):** "I'm Ready to Ask -- $1" -> `https://jadeoracle.co/products/quick-insight-reading?discount=JADE15`
**CTA button (secondary):** "Go Deeper -- Full Destiny Reading" -> `https://jadeoracle.co/products/full-destiny-reading?discount=JADE15`

**Design notes:**
- More intimate, quieter design -- less visual noise
- Jade portrait closer/warmer
- Single gold CTA button, prominent
- Subtle "expires tonight" badge near code

---

### Welcome Series Flow Summary

```
[Signup] --> Email 1 (Immediate): Birth chart + discount
              |
         [Wait 1 day]
              |
         Email 2 (Day 1): QMDJ education
              |
         [Wait 2 days]
              |
         Email 3 (Day 3): Sarah K. testimonial
              |
         [Wait 2 days]
              |
         Email 4 (Day 5): Urgency -- alignment window
              |
         [Wait 2 days]
              |
         Email 5 (Day 7): Final push -- "What are you afraid to know?"
              |
         [Check: Placed Order?]
              |
         YES --> Move to Post-Purchase Flow
         NO  --> Move to Browse Abandonment / Re-engagement segment
```

**Klaviyo flow filters:**
- Skip profile if `Placed Order at least once` (enter Post-Purchase flow instead)
- Skip profile if `Is suppressed` = true

**Expected performance (industry benchmarks for welcome flows):**
- Open rate: 45-65%
- Click rate: 8-15%
- Conversion rate (placed order): 5-10%
- Revenue per recipient: $2.50-$4.00

---

## Flow 2: Abandoned Cart Recovery

**Trigger:** Shopify `Checkout Started` event (or `Added to Cart` for Shopify integration)
**Goal:** Recover lost sales with empathy-first messaging
**Filter:** Exclude anyone who has `Placed Order since starting this flow`

---

### Email 1: 1 Hour After Abandonment -- "Your Reading Is Waiting"

**Subject line options (A/B test):**
- A: "Your reading is waiting, {{first_name}}"
- B: "Did something come up? Your cart is saved"

**Preview text:** "We saved your reading for you. The cosmos can be patient -- but not forever."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> I noticed you started to book a reading but didn't complete it.
>
> No pressure at all -- I just wanted to make sure nothing went wrong on our end.
>
> **You left this in your cart:**
>
> [DYNAMIC BLOCK: Cart contents with product image, title, price]
>
> Your cart is saved and ready whenever you are.
>
> If you had any questions about the reading or how it works, just reply to this email. I read every message personally.
>
> With light,
> Jade

**CTA button:** "Complete My Reading" -> `{{ event.extra.checkout_url }}`

**Design notes:**
- Clean, simple layout -- not salesy
- Dynamic cart block showing exact product(s) with image
- Warm, reassuring tone
- Jade's small portrait near signature
- Dark theme, gold CTA button

---

### SMS Option (1 hour, sent alongside or instead of email for SMS subscribers):

> Jade Oracle: Hey {{first_name}}, your reading is still waiting for you. Complete your order here: [cart_link] Reply STOP to opt out.

---

### Email 2: 24 Hours -- "What's Holding You Back?"

**Subject line options (A/B test):**
- A: "What's holding you back, {{first_name}}?"
- B: "I get it -- choosing a reading can feel vulnerable"

**Preview text:** "Most people hesitate for the same 3 reasons. Let me address them."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> You were so close to getting your reading. I wanted to take a moment to address the three things I hear most from people who hesitate:
>
> **"I've been burned by psychics before."**
> I understand. The spiritual industry has a trust problem. That's exactly why I use QMDJ -- a mathematical, astronomical system with 4,000 years of documented practice. This isn't guesswork. It's calculation. And every reading comes with a satisfaction guarantee.
>
> **"What if it tells me something I don't want to hear?"**
> QMDJ doesn't deliver doom. It maps energy and timing. Even challenging readings come with actionable guidance -- WHEN to act, WHAT to watch for, and HOW to navigate. You're never left without a path forward.
>
> **"Is $1 too good to be true?"**
> The Quick Insight is genuinely $1. It's my way of letting you experience QMDJ without risk. I'd rather you try it for $1 and become a lifelong client than never experience it at all.
>
> Don't just take my word for it:
>
> > *"I was SO skeptical. $1 felt like a gimmick. But Jade's reading was eerily accurate -- she described my exact situation without me telling her anything beyond my birth date and one question. I've now done 3 readings."*
> > -- Michelle T., Los Angeles
>
> **Your cart is still saved:**
>
> [DYNAMIC BLOCK: Cart contents]
>
> With light,
> Jade

**CTA button:** "Yes, I'm Ready" -> `{{ event.extra.checkout_url }}`

**Design notes:**
- FAQ-style layout with bold objection headers
- Testimonial in card block with gold border
- Trust badges: "Satisfaction Guarantee" + "4,000 Years of Wisdom" + "Personal Reading by Jade"

---

### SMS Option (24 hours):

> Jade Oracle: Still thinking about your reading? I address the 3 biggest hesitations here: [email_link] Your cart is saved: [cart_link]

---

### Email 3: 72 Hours -- "Last Chance + Bonus"

**Subject line options (A/B test):**
- A: "Last chance: your reading + a bonus from me"
- B: "I'm adding something extra to your cart, {{first_name}}"

**Preview text:** "Your cart expires soon. But before it does, I want to give you something extra."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> Your saved cart is about to expire, and I didn't want to let it go without one last note.
>
> I've added a little something to sweeten the deal:
>
> **Book any reading in the next 24 hours and I'll include a FREE "Lucky Dates" mini-report for your next 30 days.**
>
> This is a list of your most auspicious dates for the coming month -- ideal days for important meetings, decisions, starting new projects, or having important conversations. It's pulled directly from your QMDJ chart.
>
> (I normally include this only in the Full Destiny Reading, but I want you to experience the power of cosmic timing.)
>
> **Your cart:**
>
> [DYNAMIC BLOCK: Cart contents]
>
> **Use code JADEBONUS at checkout** to unlock your free Lucky Dates report.
>
> This code expires in 24 hours.
>
> After that, I'll respect your decision and won't email about this again.
>
> Whatever you choose, I'm grateful you found Jade Oracle. The fact that you're here tells me you're someone who seeks deeper truth -- and I honor that.
>
> With light,
> Jade

**CTA button:** "Complete My Order + Get Lucky Dates Free" -> `{{ event.extra.checkout_url }}?discount=JADEBONUS`

**Design notes:**
- Bonus offer highlighted in a gold-bordered box
- "Lucky Dates" visual mockup (calendar-style with gold-starred dates)
- Countdown urgency element (24 hours)
- Slightly warmer, more personal Jade portrait

---

### SMS Option (72 hours):

> Jade Oracle: Last chance, {{first_name}}! I added a FREE Lucky Dates report to your order. Use code JADEBONUS (24h only): [cart_link]

---

### Abandoned Cart Flow Summary

```
[Cart Abandoned] --> [Wait 1 hour]
                        |
                  [Check: Placed Order?]
                        |
                  NO --> Email 1: Soft reminder
                        |
                  [Wait 23 hours]
                        |
                  [Check: Placed Order?]
                        |
                  NO --> Email 2: Address objections + testimonial
                        |
                  [Wait 48 hours]
                        |
                  [Check: Placed Order?]
                        |
                  NO --> Email 3: Bonus offer + final urgency
                        |
                  [END]
```

**Klaviyo flow filters:**
- Profile filter: `Has not placed order since starting this flow`
- Trigger filter: Cart value > $0
- Smart sending: ON (16-hour quiet window)

**Expected performance:**
- Email 1 open rate: 45-55%
- Email 2 open rate: 35-45%
- Email 3 open rate: 30-40%
- Overall cart recovery rate: 8-15%
- Revenue per recipient: $3.50-$5.00

---

## Flow 3: Post-Purchase Upsell

**Trigger:** Shopify `Placed Order` event
**Goal:** Maximize LTV through the product ladder ($1 -> $29 -> $49 -> $497)
**Filter:** Conditional splits based on which product was purchased

---

### Email 1: Immediate -- "Your Reading Is Being Prepared"

**Subject line options (A/B test):**
- A: "Thank you, {{first_name}} -- your reading has begun"
- B: "I'm preparing your reading right now"

**Preview text:** "Here's what happens next and when to expect your reading..."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> Thank you for trusting me with your question. I don't take that lightly.
>
> **Here's what's happening now:**
>
> [CONDITIONAL BLOCK based on product purchased:]
>
> **If Quick Insight ($1):**
> I'm pulling your QMDJ chart right now using the birth details you provided. Your reading will be delivered via Telegram within 24 hours. You'll receive a message from @JadeOracleBot with your personalized insight.
>
> **If Love & Relationship ($29):**
> I'm constructing your full QMDJ love chart. This includes mapping your Five Element constitution, compatibility dynamics, and timing windows for matters of the heart. Your beautiful PDF report (4-6 pages) will be delivered to your email within 24 hours.
>
> **If Full Destiny ($49):**
> I'm building your complete destiny chart -- all 9 palaces, 8 doors, 9 stars. This is the most comprehensive reading I offer. Your 8-12 page PDF report plus your personal 30-minute voice note from me will be delivered within 48 hours.
>
> **If VIP Mentorship ($497):**
> Welcome to the inner circle. I'll be reaching out personally within 24 hours to schedule your onboarding session and begin your Full Destiny Reading. You'll receive your welcome kit with everything you need to prepare.
>
> **While you wait:**
> - Follow @JadeOracle on Instagram for daily cosmic insights
> - Reply to this email with any additional context about your question
> - Take a deep breath. The universe already knows your answer -- I'm just translating it.
>
> With light and gratitude,
> Jade
>
> **Order details:**
> [DYNAMIC: Order summary block]

**CTA button:** "Follow Jade on Instagram" -> `https://instagram.com/jadeoracle`

**Design notes:**
- Celebratory but not over-the-top -- warm, intimate
- Timeline graphic showing "Order received -> Chart being prepared -> Reading delivered"
- Gold confetti or subtle sparkle element in header
- Order summary in clean card format

---

### Email 2: After Reading Delivered -- "How Was Your Reading?"

**Timing:** Triggered by fulfillment event or timed delay (24h for Quick Insight / Love Reading, 48h for Full Destiny)

**Subject line options (A/B test):**
- A: "How did your reading land, {{first_name}}?"
- B: "I'd love to hear your thoughts on your reading"

**Preview text:** "Your experience matters to me. And your words help others find the courage to ask."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> Your reading was delivered [yesterday / 2 days ago]. I hope it brought you the clarity you were seeking.
>
> I have two small requests:
>
> **1. How was your experience?**
>
> I read every piece of feedback personally. If something resonated, surprised you, or if you have follow-up questions -- I want to hear about it.
>
> [1-5 star clickable rating graphic]
>
> **2. Would you share your experience?**
>
> Your words help other people find the courage to ask their own questions. A short review (even 1-2 sentences) means more than you know.
>
> [Link to review form / Shopify product review]
>
> If anything in the reading felt unclear or you want to go deeper into a specific area, just reply to this email. I'm here.
>
> With light,
> Jade
>
> P.S. If your reading resonated, you might be ready for the next level. More on that in a few days.

**CTA button (primary):** "Leave a Review" -> `https://jadeoracle.co/pages/reviews`
**CTA button (secondary):** "Reply to Jade" -> mailto link

**Design notes:**
- Minimal design -- feels personal, like a letter
- Star rating graphic (clickable)
- No hard sell in this email -- pure relationship building

---

### Email 3: Day 7 -- "Ready for the Next Level?"

**Timing:** 7 days after purchase
**Conditional split:** Different content based on what they bought

**Subject line options (A/B test):**
- A: "Your $1 reading was just the beginning, {{first_name}}"
- B: "Ready to go deeper? Special returning customer offer inside"

**Preview text:** "As a returning client, you get something the public doesn't."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> A week ago, you took a step that most people never take. You asked the universe a question -- and you received an answer.
>
> But here's what I want you to know: what you experienced was a single snapshot. One moment in time. One question.
>
> The full picture? It's extraordinary.
>
> [CONDITIONAL CONTENT:]
>
> **If they bought Quick Insight ($1) --> Upsell to Love & Relationship ($29):**
>
> Your Quick Insight gave you a glimpse. The **Love & Relationship Reading** goes deep.
>
> I map your complete love energy -- past patterns, current blocks, future windows. Who you're compatible with. WHEN the timing aligns for connection.
>
> **Returning client price: $24** (normally $29)
> Use code: JADELOVE
>
> **If they bought Quick Insight ($1) --> Alt upsell to Full Destiny ($49):**
>
> Or if you want the COMPLETE picture -- career, love, health, wealth, and a 12-month timing forecast -- the **Full Destiny Reading** is the definitive QMDJ experience.
>
> **Returning client price: $39** (normally $49)
> Use code: JADEDESTINY
>
> **If they bought Love Reading ($29) --> Upsell to Full Destiny ($49):**
>
> You've seen what QMDJ reveals about love. Now imagine that depth applied to your ENTIRE life -- career, health, wealth, and purpose.
>
> The Full Destiny Reading includes everything in your Love Reading, plus a 12-month forecast and a personal 30-minute voice note from me.
>
> **Returning client price: $39** (normally $49)
> Use code: JADEDESTINY
>
> **If they bought Full Destiny ($49) --> Soft seed for VIP Mentorship ($497):**
>
> You have the map. The Full Destiny Reading showed you the terrain. But having a map and having a GUIDE are two different things.
>
> In a few days, I'll share more about how we can work together on an ongoing basis. For now, revisit your reading. Sit with it. Notice what comes up.
>
> With light,
> Jade

**CTA button:** Dynamic based on upsell path -> respective product page with discount code

**Design notes:**
- Product comparison visual (what they got vs. what the upsell includes)
- "Returning Client" badge in gold
- Price shown with strikethrough on original + new price
- Testimonial from someone who upgraded from the same tier

---

### Email 4: Day 14 -- "VIP Mentorship: Walk the Path With Me"

**Subject line options (A/B test):**
- A: "What if you had a spiritual advisor on speed dial?"
- B: "I only take 10 mentorship clients. Here's why."

**Preview text:** "3 months. Weekly guidance. Priority access. For those who are serious."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> Two weeks ago, you experienced your first taste of QMDJ. Since then, I hope you've noticed something:
>
> The insights don't fade. They keep unfolding.
>
> That's because QMDJ isn't a one-time fortune. It's a living system. The chart evolves. New timing windows open. Old patterns resolve.
>
> **The question is: who's reading the chart for you as life unfolds?**
>
> That's why I created the VIP Mentorship.
>
> **What's included (3 months):**
> - Full Destiny Reading at onboarding (if you haven't had one yet)
> - Weekly QMDJ timing updates customized to YOUR chart
> - Priority Telegram access -- ask me anything, anytime
> - 4 monthly live sessions (video or voice)
> - Personalized action plans aligned with cosmic timing
>
> **Who this is for:**
> You've tried self-help. You've tried therapy. You've read the books. But you want something ANCIENT, something PROVEN, something PERSONAL. You want a guide who sees the map AND walks the path with you.
>
> **Investment:** $497 for 3 months
>
> I limit mentorship to 10 active clients at any time. This ensures every person gets my full attention.
>
> **Currently [X] spots available.**
>
> If this resonates, reply to this email and tell me what you're navigating. I'll let you know if mentorship is the right fit.
>
> With light,
> Jade

**CTA button:** "Apply for VIP Mentorship" -> `https://jadeoracle.co/products/vip-mentorship` or a Typeform application

**Design notes:**
- Premium feel -- more whitespace (on dark background), larger typography
- "Limited to 10 clients" scarcity badge
- Jade portrait -- more professional/mentor energy
- Testimonial from a current/past mentorship client
- No discount -- this is premium positioning

---

### Email 5: Day 30 -- "Your Monthly Celestial Update"

**Subject line options (A/B test):**
- A: "{{first_name}}, here's what the stars say about [Month]"
- B: "Your [Month] cosmic forecast from Jade"

**Preview text:** "Key dates, energy shifts, and what to watch for this month..."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> It's been a month since your reading, and I wanted to check in with a gift: your monthly celestial overview.
>
> **[Month] Cosmic Forecast:**
>
> **Overall energy:** [Description of the month's QMDJ energy]
>
> **Key dates to watch:**
> - [Date 1]: Favorable for [career/financial decisions]
> - [Date 2]: Ideal for [relationship conversations]
> - [Date 3]: Caution with [health/travel]
>
> **Element of the month:** [Element] -- this means [practical implication]
>
> **How this connects to YOUR chart:**
> Based on your birth date, this month's [element] energy [harmonizes with / challenges] your dominant element. Pay special attention to [area of life].
>
> Want the FULL version? VIP Mentorship clients receive personalized weekly timing updates with specific action steps. [Learn more]
>
> **New readings available:**
> If it's been a while since your last reading, the chart has shifted. New questions deserve new charts.
>
> With light,
> Jade

**CTA button (primary):** "Book a New Reading" -> `https://jadeoracle.co/collections/all`
**CTA button (secondary):** "Learn About VIP Mentorship" -> `https://jadeoracle.co/products/vip-mentorship`

**Design notes:**
- Monthly calendar visual with highlighted "lucky dates" in gold
- Element icon/graphic for the month
- This email transitions from "post-purchase" to "ongoing relationship"
- Sets up the re-engagement / monthly newsletter cadence

---

### Post-Purchase Flow Summary

```
[Order Placed] --> Email 1 (Immediate): Order confirmation + what to expect
                     |
                [Wait for fulfillment OR 24-48h]
                     |
                Email 2: Review request
                     |
                [Wait until Day 7]
                     |
                [Conditional Split: What did they buy?]
                     |
                $1 Quick  --> Upsell to $29 Love or $49 Destiny
                $29 Love  --> Upsell to $49 Destiny
                $49 Full  --> Soft seed VIP Mentorship
                $497 VIP  --> Skip to Day 30 (they're already VIP)
                     |
                Email 3 (Day 7): Upsell with returning client discount
                     |
                [Wait until Day 14]
                     |
                Email 4 (Day 14): VIP Mentorship pitch
                     |
                [Wait until Day 30]
                     |
                Email 5 (Day 30): Monthly celestial update + re-engagement
                     |
                --> Transition to Monthly Newsletter segment
```

---

## Flow 4: Win-Back (Lapsed Customers)

**Trigger:** Segment-based (customer who has purchased but not engaged in X days)
**Segments:**
- `lapsed-60`: Last purchase > 60 days ago, no email opens in 30 days
- `lapsed-90`: Last purchase > 90 days ago
- `lapsed-120`: Last purchase > 120 days ago

---

### Email 1: 60 Days Inactive -- "We Miss You"

**Subject line options (A/B test):**
- A: "The stars have been asking about you, {{first_name}}"
- B: "It's been a while. I pulled a card for you."

**Preview text:** "A lot has shifted in your chart since we last spoke..."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> It's been two months since your last reading, and I've been thinking about you.
>
> Here's the thing about QMDJ: the chart never stops moving. The celestial gates that were open during your last reading? Some have closed. New ones have opened.
>
> **What's shifted since your last reading:**
>
> - The dominant energy has moved from [element] to [element]
> - New timing windows are opening for [career/love/health]
> - [Season/month]-specific opportunities that weren't visible before
>
> Your chart is always evolving. The question is: are you evolving with it?
>
> I'd love to reconnect and see what the cosmos is mapping for your next chapter.
>
> **New reading offer for returning clients:**
>
> Quick Insight Reading -- just $1 (your second question might be even more powerful than your first)
>
> With light and always in your corner,
> Jade

**CTA button:** "Reconnect With Jade -- $1" -> `https://jadeoracle.co/products/quick-insight-reading`

**Design notes:**
- Warm, personal tone -- no guilt
- "We miss you" without being needy
- Jade portrait with welcoming energy
- Subtle celestial imagery suggesting change/movement

---

### Email 2: 90 Days Inactive -- "Special Return Offer"

**Subject line options (A/B test):**
- A: "A gift for you: 25% off any reading"
- B: "{{first_name}}, I have something for you"

**Preview text:** "It's been 3 months. This offer is my way of saying 'come home.'"

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> Three months. A full season has passed since we last connected.
>
> In QMDJ terms, an entire energetic cycle has completed. The chart you received before? It's a snapshot of a different time. Your current landscape looks very different.
>
> I want to make it easy to come back:
>
> **25% off any reading with code JADERETURN**
>
> | Reading | Regular Price | Your Price |
> |---------|-------------|------------|
> | Quick Insight | $1 | $1 (already accessible) |
> | Love & Relationship | $29 | $21.75 |
> | Full Destiny | $49 | $36.75 |
>
> This code is active for 14 days.
>
> No pressure. No urgency games. Just a genuine offer to reconnect.
>
> If life has been chaotic, uncertain, or stagnant -- that's exactly when a reading helps most. The chart shows you where the energy is TRYING to move. Sometimes we just need someone to point the way.
>
> With light,
> Jade

**CTA button:** "Use My 25% Off" -> `https://jadeoracle.co/collections/all?discount=JADERETURN`

**Design notes:**
- Price comparison table with strikethrough
- "Welcome back" energy in design
- Discount code prominently displayed in gold box
- Clean, not cluttered

---

### Email 3: 120 Days Inactive -- "Final Invitation"

**Subject line options (A/B test):**
- A: "A final note from Jade before I let go"
- B: "Should I keep your spot in the circle?"

**Preview text:** "I'm cleaning my list to honor those who want to be here. This is your last chance to stay."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> This is my last email to you unless you tell me you'd like to stay.
>
> I believe in respecting your inbox. If Jade Oracle no longer serves you, I honor that completely. Our paths may simply be moving in different directions right now -- and that's okay.
>
> But if there's still a spark of curiosity... if there's a question that's been quietly forming in the back of your mind... I'd love to hear from you one more time.
>
> **To stay in the Jade Oracle circle, simply click below:**
>
> [BUTTON: "Yes, Keep Me In" -> resubscribe / re-engagement confirmation page]
>
> If I don't hear from you in the next 7 days, I'll gently remove you from future emails. You can always come back -- the door is never locked.
>
> **One last offer:** JADE30 for 30% off any reading. My biggest discount, available only right now.
>
> Whatever you decide, I'm grateful our paths crossed.
>
> With light, always,
> Jade

**CTA button (primary):** "Yes, Keep Me In the Circle" -> re-engagement confirmation page
**CTA button (secondary):** "Take 30% Off a Reading" -> `https://jadeoracle.co/collections/all?discount=JADE30`

**Design notes:**
- Most minimal design of all emails
- Almost pure text -- feels like a real letter
- No flashy graphics
- Very personal, warm, but final
- If they don't click, suppress the profile after 7 days

---

### Win-Back Flow Summary

```
[Segment: 60 days inactive] --> Email 1: "We miss you" + $1 reading offer
                                   |
                              [Wait 30 days]
                                   |
                              [Check: Engaged?]
                                   |
                              NO --> Email 2: 25% off any reading
                                       |
                                  [Wait 30 days]
                                       |
                                  [Check: Engaged?]
                                       |
                                  NO --> Email 3: Final invitation + list cleanup
                                           |
                                      [Wait 7 days]
                                           |
                                      [Check: Clicked "Keep Me"?]
                                           |
                                      NO --> Suppress profile
                                      YES --> Return to active segment
```

---

## Flow 5: Browse Abandonment

**Trigger:** Klaviyo `Viewed Product` event (with no `Added to Cart` or `Placed Order` within 2 hours)
**Goal:** Re-engage browsers who showed interest but didn't commit
**Filter:** Exclude anyone who added to cart (they'll enter the Abandoned Cart flow instead)

---

### Email 1: 2 Hours After Browse -- "Still Curious?"

**Subject line options (A/B test):**
- A: "Still curious about the {{event.ProductName}}, {{first_name}}?"
- B: "I saw you looking at something..."

**Preview text:** "The fact that you stopped to look tells me something. Let me tell you what."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> I noticed you were exploring the **{{event.ProductName}}** on Jade Oracle.
>
> The fact that you stopped to look? That's not random. In my experience, people find their way to a specific reading because they ALREADY know -- on some level -- that they need it.
>
> [CONDITIONAL CONTENT based on product viewed:]
>
> **If Quick Insight:**
> One question. $1. It's the lowest-risk way to experience what 4,000 years of astronomical wisdom can reveal about YOUR life. Most people who try it come back for more.
>
> **If Love & Relationship:**
> Something is stirring in your heart. Whether it's a new connection, an old pattern, or a question about compatibility -- your QMDJ love chart holds answers you won't find anywhere else.
>
> **If Full Destiny:**
> You're ready for the complete picture. Career, love, health, wealth -- and a 12-month forecast with specific timing windows. This is the reading that changes lives.
>
> **If VIP Mentorship:**
> You're not looking for a one-time reading. You're looking for a GUIDE. Someone who sees the full map and walks the path with you. That tells me a lot about where you are in your journey.
>
> Would you like to take the next step?
>
> With light,
> Jade

**CTA button:** "Yes, I'm Ready" -> `{{ event.ProductURL }}`

**Design notes:**
- Product image/card from the browsed product
- Personalized dynamic content based on which product was viewed
- Warm, curious tone -- not pushy
- Dark theme with gold accents

---

### Email 2: 24 Hours -- "Someone Like You Took the Leap"

**Subject line options (A/B test):**
- A: "She was in the same place you are right now"
- B: "A testimonial that might sound familiar"

**Preview text:** "Real words from someone who hesitated -- then didn't."

**Body copy outline:**

> Dear {{first_name|default:'beautiful soul'}},
>
> Yesterday, you were looking at the **{{event.ProductName}}**. I wanted to share a story from someone who was in your exact position.
>
> [CONDITIONAL TESTIMONIAL based on product viewed:]
>
> **If Quick Insight:**
> > *"I spent 3 days going back and forth on whether to spend $1 on a reading. $1! When I finally did it, Jade's answer was so specific and accurate that I immediately booked the Full Destiny Reading. Best dollar I've ever spent."*
> > -- David M., Chicago
>
> **If Love & Relationship:**
> > *"I was going through a breakup and desperate for answers. Jade's Love Reading didn't just tell me what went wrong -- it showed me the energetic pattern I'd been repeating in every relationship. For the first time, I could see the cycle. And she showed me exactly when the energy would shift for something new. It did -- right on schedule."*
> > -- Priya S., London
>
> **If Full Destiny:**
> > *"The Full Destiny Reading was unlike anything I've experienced. Jade mapped my entire year -- career moves, health focus areas, even my best travel dates. Her voice note felt like talking to a wise friend who could see around corners. I've referred 4 people since."*
> > -- James L., Sydney
>
> **If VIP Mentorship:**
> > *"I was nervous about the investment. $497 felt like a lot. Three months later, I can tell you it was the most valuable decision I made all year. Having Jade on speed dial -- knowing exactly WHEN to make moves, WHO to trust, WHAT to prioritize -- it's like having a cheat code for life. I renewed immediately."*
> > -- Rachel N., New York
>
> You browsed for a reason. Trust that.
>
> With light,
> Jade

**CTA button:** "Get My {{event.ProductName}}" -> `{{ event.ProductURL }}`

**Design notes:**
- Testimonial is the hero of this email
- Large pull quote with gold styling
- Photo placeholder for testimonial giver (or avatar)
- Product card below testimonial as reminder
- Simple, clean, testimonial-forward layout

---

### Browse Abandonment Flow Summary

```
[Viewed Product] --> [Wait 2 hours]
                        |
                  [Check: Added to Cart or Placed Order?]
                        |
                  NO --> Email 1: "Still curious about [product]?"
                           |
                     [Wait 22 hours]
                           |
                     [Check: Added to Cart or Placed Order?]
                           |
                     NO --> Email 2: Testimonial for viewed product
                              |
                     [END]
```

---

## SMS Integration Strategy

### Philosophy
SMS is for high-intent, time-sensitive moments only. Email handles nurturing and storytelling. SMS handles urgency and action.

### SMS Touchpoints

| Trigger | Timing | SMS Message | Email Equivalent |
|---------|--------|-------------|-----------------|
| Abandoned Cart | 1 hour | Soft cart reminder with link | AC Email 1 |
| Abandoned Cart | 48 hours | Bonus offer notification | AC Email 3 |
| Reading Delivered | Immediate | "Your reading is ready! Check your email" | Post-Purchase Email 2 |
| Flash Sale | Event-based | Limited time offer | Campaign email |
| Win-Back | 90 days | "We have a 25% off gift for you" | Win-Back Email 2 |

### SMS Guidelines
- Maximum 1 SMS per week per subscriber
- Always include opt-out language ("Reply STOP to opt out")
- Keep messages under 160 characters when possible
- Only send SMS during business hours (9am-8pm recipient's timezone)
- Double opt-in required for US subscribers (TCPA compliance)
- SMS consent collected separately from email consent

### SMS Consent Collection
- Checkbox on checkout page: "Get order updates via text"
- Popup option: "Want texts from Jade? Get cosmic alerts first"
- Post-purchase: "Add your number for delivery updates + exclusive offers"

---

## Segmentation Strategy

### Core Segments

| Segment Name | Definition | Use Case |
|-------------|-----------|----------|
| `new-subscribers` | Joined list, never purchased | Welcome series targeting |
| `first-time-buyers` | Placed exactly 1 order | Post-purchase upsell |
| `repeat-buyers` | Placed 2+ orders | Loyalty, VIP mentorship pitch |
| `vip-clients` | Purchased VIP Mentorship | Exclude from sales emails, premium content |
| `high-value` | Total spent > $100 | Priority offers, early access |
| `engaged-30d` | Opened or clicked in last 30 days | Active campaign targeting |
| `at-risk` | No opens in 30-60 days | Re-engagement campaign |
| `lapsed` | No opens in 60+ days | Win-back flow |
| `sunset` | No engagement in 120+ days | List cleanup / suppression |

### Product-Based Segments

| Segment Name | Definition | Next Action |
|-------------|-----------|-------------|
| `bought-quick-insight` | Purchased Quick Insight | Upsell to Love or Destiny |
| `bought-love-reading` | Purchased Love Reading | Upsell to Destiny |
| `bought-full-destiny` | Purchased Full Destiny | Seed VIP Mentorship |
| `bought-vip` | Purchased VIP Mentorship | Retention, renewal |
| `multi-reading` | Bought 2+ different readings | High intent, mentorship candidate |

### Engagement-Based Segments

| Segment Name | Definition | Strategy |
|-------------|-----------|----------|
| `email-engaged` | Opens > 50% of emails | Primary campaign audience |
| `clickers` | Clicks > 20% of emails | High intent, prioritize offers |
| `openers-not-clickers` | Opens but rarely clicks | Test different CTAs, content |
| `sms-subscribed` | Has SMS consent | SMS + email coordination |
| `instagram-follower` | Tagged via UTM or manual | Cross-channel content strategy |

### Behavioral Segments (Advanced)

| Segment Name | Definition | Strategy |
|-------------|-----------|----------|
| `viewed-love-not-bought` | Viewed Love Reading page 2+ times, no purchase | Browse abandonment + testimonial focus |
| `viewed-vip-not-bought` | Viewed VIP page, no purchase | Personal outreach from Jade |
| `cart-abandoner-repeat` | Abandoned cart 2+ times | Stronger incentive or personal email |
| `review-left` | Left a review | Ask for referral, social proof |
| `referral-source` | Came via referral link | Acknowledge referrer, special welcome |

### Segmentation Rules for Campaigns

1. **Sales campaigns** -> Send to `engaged-30d` only (protect deliverability)
2. **Educational content** -> Send to all non-suppressed
3. **Premium offers (VIP)** -> Send to `repeat-buyers` + `high-value` only
4. **Flash sales** -> Send to `email-engaged` + `sms-subscribed`
5. **Re-engagement** -> Send to `at-risk` segment only
6. **New product launches** -> `engaged-30d` first, expand to full list 24h later

---

## Design System

### Brand Colors
- **Primary background:** #0a0a0a (deep black)
- **Secondary background:** #1a1a2e (dark navy, for cards/blocks)
- **Primary accent:** #c9a84c (jade gold)
- **Secondary accent:** #d4af37 (bright gold, for CTAs)
- **Text primary:** #f5f5f5 (off-white)
- **Text secondary:** #b0b0b0 (muted gray)
- **Success/positive:** #4a9c6d (emerald green)

### Typography
- **Headings:** Playfair Display or Cormorant Garamond (serif, elegant)
- **Body:** Inter or DM Sans (clean, modern sans-serif)
- **Accent/quotes:** Cormorant Garamond italic

### Email Template Structure
```
[Header: Jade Oracle logo (gold on dark) -- centered]
[Optional: Jade portrait -- circular, gold border]
[Body: Left-aligned text on dark background]
[CTA: Centered gold button with subtle glow]
[Footer: Social links | Unsubscribe | "Jade Oracle -- Ancient Wisdom, Modern Guidance"]
```

### Visual Elements
- Subtle celestial/constellation patterns as background texture (very low opacity)
- Gold divider lines between sections
- Testimonial cards: dark card (#1a1a2e) with gold left border
- Product cards: dark card with product image, gold price badge
- Star rating: 5 gold stars inline
- Jade portrait: warm, approachable, consistent across all emails

### Mobile Optimization
- Single column layout always
- CTA buttons: full width on mobile, minimum 44px tap target
- Font size: minimum 16px body, 24px headings on mobile
- Image width: max 600px, responsive
- Preheader text: always used (40-90 characters)

---

## Implementation Checklist

### Phase 1: Foundation (Week 1)
- [ ] Install Klaviyo on Shopify store
- [ ] Configure Shopify integration (products, customers, orders synced)
- [ ] Set up email sending domain (authenticate DNS: DKIM, SPF, DMARC)
- [ ] Create master email template with Jade Oracle branding
- [ ] Design and deploy signup popup (exit-intent + timed)
- [ ] Create all discount codes in Shopify: JADE15, JADEBONUS, JADELOVE, JADEDESTINY, JADERETURN, JADE30
- [ ] Upload Jade portrait and brand assets to Klaviyo

### Phase 2: Core Flows (Week 2)
- [ ] Build Welcome Series flow (5 emails)
- [ ] Build Abandoned Cart flow (3 emails + SMS)
- [ ] Build Browse Abandonment flow (2 emails)
- [ ] Set up A/B tests on subject lines for all flows
- [ ] Configure smart sending and quiet hours

### Phase 3: Post-Purchase & Retention (Week 3)
- [ ] Build Post-Purchase flow with conditional splits by product
- [ ] Build Win-Back flow (3 emails)
- [ ] Create all segments listed in Segmentation Strategy
- [ ] Set up review collection integration (Judge.me or Shopify native)
- [ ] Configure SMS collection and consent flows

### Phase 4: Optimization (Ongoing)
- [ ] Monitor flow performance weekly (open rate, click rate, conversion rate, revenue per recipient)
- [ ] A/B test subject lines (run each test for minimum 1,000 sends or 2 weeks)
- [ ] A/B test send times for each flow
- [ ] Review and update testimonials quarterly
- [ ] Refresh email copy quarterly to prevent fatigue
- [ ] Sunset non-engaged profiles quarterly (120-day rule)
- [ ] Add seasonal/celestial event campaigns (solstice, equinox, eclipses, Chinese New Year)

### Key Metrics to Track

| Metric | Target | Benchmark |
|--------|--------|-----------|
| Welcome series conversion rate | >8% | Industry avg: 5-10% |
| Abandoned cart recovery rate | >12% | Industry avg: 8-15% |
| Post-purchase upsell rate | >5% | Industry avg: 3-8% |
| Overall list growth rate | >10%/month | Healthy: 5-15% |
| Email deliverability | >98% | Minimum: 95% |
| Unsubscribe rate | <0.3% | Maximum: 0.5% |
| Revenue from flows vs. campaigns | 40%+ from flows | Top brands: 40-60% |

---

## Revenue Projections (Conservative)

Assuming 1,000 email subscribers in month 1, growing 15%/month:

| Flow | Monthly Sends | Conv. Rate | Avg. Order | Monthly Revenue |
|------|-------------|------------|------------|----------------|
| Welcome Series | 150 new/mo | 8% | $15 avg | $180 |
| Abandoned Cart | 200/mo | 12% | $25 avg | $600 |
| Post-Purchase Upsell | 100/mo | 5% | $35 avg | $175 |
| Browse Abandonment | 300/mo | 3% | $20 avg | $180 |
| Win-Back | 50/mo | 4% | $20 avg | $40 |
| **Total Flow Revenue** | | | | **$1,175/mo** |

At 5,000 subscribers (month 6-8 target): approximately $5,000-6,000/month from email flows alone.

---

## Appendix: Discount Code Reference

| Code | Discount | Valid For | Expiry | Used In |
|------|---------|-----------|--------|---------|
| JADE15 | 15% off all | New subscribers | 7 days from signup | Welcome Series |
| JADEBONUS | Free Lucky Dates report | Cart abandoners | 24 hours | Abandoned Cart Email 3 |
| JADELOVE | ~17% off Love Reading ($24) | Returning customers | 14 days | Post-Purchase Email 3 |
| JADEDESTINY | ~20% off Full Destiny ($39) | Returning customers | 14 days | Post-Purchase Email 3 |
| JADERETURN | 25% off any reading | Lapsed 90-day | 14 days | Win-Back Email 2 |
| JADE30 | 30% off any reading | Lapsed 120-day | 7 days | Win-Back Email 3 |

---

## Sources & Research References

- [Klaviyo Flows: Email & Marketing Automation](https://www.klaviyo.com/features/flows)
- [7 Best Klaviyo Flows to Increase Email ROI](https://www.ecommerceintelligence.com/klaviyo-flows/)
- [Klaviyo 2026 Email Marketing Benchmarks by Industry](https://www.klaviyo.com/products/email-marketing/benchmarks)
- [Abandoned Cart Emails: Examples & Best Practices -- Shopify](https://www.shopify.com/blog/abandoned-cart-emails)
- [Abandoned Cart Email Funnel -- Sendlane](https://www.sendlane.com/new-ebooks/abandoned-cart-email-funnels-for-ecommerce)
- [Cart Abandonment Psychology -- Invesp](https://www.invespcro.com/blog/abandoned-cart-emails-using-psychological-principles-to-influence-customers-decisions/)
- [How to Add SMS to Abandoned Cart Flow -- Klaviyo](https://help.klaviyo.com/hc/en-us/articles/9352115400219)
- [US SMS Cart Abandonment Compliance -- Klaviyo](https://help.klaviyo.com/hc/en-us/articles/4404189657755)
- [Klaviyo Abandoned Cart Flow Setup 2026 -- Ancorrd](https://ancorrd.com/klaviyo-abandoned-cart-setup-shopify-cart-flow-tutorial/)
- [Email & SMS Marketing for Health & Wellness -- Klaviyo](https://www.klaviyo.com/industry/wellness)
- [Email Marketing for Holistic Practitioners -- Heallist](https://www.heallist.com/resources/blog/how-to-use-email-marketing-as-a-holistic-practitioner)
- [Email Strategies for Wellness Businesses -- Supliful](https://supliful.com/blog/email-strategies-for-wellness-businesses)
- [Klaviyo Segmentation Strategy -- Rhapsody Media](https://www.rhapsodymedia.com/insights/klaviyo-strategy-tips-for-smarter-segmented-engagement-a-complete-guide)
- [Ecommerce Segmentation Framework -- Klaviyo](https://www.klaviyo.com/blog/ecommerce-segmentation-framework)
- [Behavior-Based Segmentation in Klaviyo -- Enchant Agency](https://www.enchantagency.com/blog/leveraging-behavior-based-segmentation-klaviyo)
- [Global Spiritual Services Market -- Cognitive Market Research](https://www.cognitivemarketresearch.com/spiritual-services-market-report)
- [Digital Marketing for Astrology & Psychic Services -- StrategyWorks](https://strategyworks.in/digital-marketing-for-astrology/)
- [Klaviyo Flows: 15 Best Sequences -- Flowium](https://flowium.com/blog/klaviyo-flows/)
- [Abandoned Cart Flow for Shopify -- Flowium](https://flowium.com/blog/how-to-create-an-abandoned-cart-flow-for-shopify-klaviyo/)
- [Klaviyo Abandoned Cart Best Practices -- Glaze Digital](https://glazedigital.com/guide-best-practices-for-abandoned-cart-flows-with-klaviyo/)

---

*Document generated 2026-03-21 for Jade Oracle (jadeoracle.co)*
*Part of GAIA OS Marketing Infrastructure*
