---
name: page-cro
description: When the user wants to optimize, improve, or increase conversions on any marketing page. Also use when the user says "CRO", "conversion rate optimization", "this page isn't converting", "improve conversions", "why isn't this page working", "my landing page sucks", "nobody's converting", "low conversion rate", "bounce rate is too high", "people leave without signing up", "people leave without ordering", or "this page needs work". Use this even if the user just shares a URL and asks for feedback. For ad-specific landing pages, see ads-landing.
agents:
  - scout
  - dreami
---

# Page CRO -- Conversion Rate Optimization for Marketing Pages

Conversion rate optimization expert for GAIA ecosystem brands (F&B, wellness, D2C, supplements, lifestyle). Analyzes any marketing page and delivers actionable recommendations to improve conversion rates.

## When to Use

- Homepage, landing page, pricing page, menu page, product page, or blog post needs more conversions
- Shopify store pages underperforming
- WhatsApp/link-in-bio landing pages not converting
- New brand page launch needs CRO review
- Bounce rate too high on any customer-facing page

## Before Starting

1. Load brand DNA: `~/.openclaw/brands/{brand}/DNA.json` -- adapt all recommendations to brand voice and audience
2. Identify the page type, primary conversion goal, and traffic source

## Initial Assessment

Gather before analyzing:

1. **Page Type**: Homepage, landing page, pricing, menu, product, collection, blog, link-in-bio, WhatsApp catalog
2. **Primary Conversion Goal**: Order (WhatsApp/Shopify), subscribe (meal plan/newsletter), book consultation, download menu, visit store, sign up
3. **Traffic Context**: Where are visitors coming from? (organic, paid Meta/Google, email, WhatsApp broadcast, Instagram bio link, walk-in QR)

---

## CRO Analysis Framework

### Step 0 — Access the Page

Before analyzing anything, fetch the actual page content so the analysis is grounded in real data, not assumptions:

```bash
bash ~/.openclaw/skills/agent-reach/scripts/web-read.sh "URL"
```

Read the returned content carefully. Identify the page structure, copy, CTAs, images, and any interactive elements. Then proceed with the 7-dimension analysis below.

---

Analyze the page across these 7 dimensions, in order of impact. **After each dimension, assign a score from 1 (critical issues) to 10 (excellent) with a one-line justification.**

### 1. Value Proposition Clarity (Highest Impact)

**Check for:**
- Can a visitor understand what this brand/product offers and why they should care within 5 seconds?
- Is the primary benefit clear, specific, and differentiated from competitors?
- Is it written in the customer's language, not industry jargon?

**Common issues in F&B/wellness:**
- Feature-focused ("plant-based ingredients") instead of benefit-focused ("feel lighter after every meal")
- Too vague ("healthy food") or too clever (sacrificing clarity for branding)
- Trying to say everything instead of the most compelling thing
- Not addressing the "why switch from my current option?" question
- **Stale or seasonal content** -- outdated promotions, expired menus, old dates, or seasonal messaging left up past its relevance window. This is one of the most common and damaging CRO issues (e.g., a CNY banner still live in March)

### 2. Headline Effectiveness

**Evaluate:**
- Does it communicate the core value proposition?
- Is it specific enough to be meaningful?
- Does it match the traffic source's messaging (ad copy, IG caption, WhatsApp blast)?

**Strong headline patterns for F&B/wellness:**
- Outcome-focused: "Lose weight without giving up flavor"
- Specificity: "5-day meal plans delivered to your door by 7am"
- Social proof: "Join 2,000+ Malaysians eating cleaner this month"
- Urgency: "This week's menu -- order by Wednesday 6pm"

### 3. CTA Placement, Copy, and Hierarchy

**Primary CTA assessment:**
- Is there one clear primary action?
- Is it visible without scrolling?
- Does the button/link communicate value, not just action?
  - Weak: "Submit", "Contact Us", "Learn More"
  - Strong: "Order This Week's Menu", "Start My Meal Plan", "Get Free Consultation", "WhatsApp to Order"

**CTA hierarchy:**
- Is there a logical primary vs. secondary CTA structure?
- Are CTAs repeated at key decision points (after menu showcase, after testimonials, after pricing)?
- For WhatsApp-first brands: is the WhatsApp CTA prominent and pre-filled with context?

### 4. Visual Hierarchy and Scannability

**Check:**
- Can someone scanning get the main message?
- Are food/product photos high quality and appetite-appealing?
- Is there enough white space?
- Do images support or distract from the conversion goal?
- Is the menu/product layout easy to browse on mobile?
- Does the page load fast on Malaysian mobile networks?

### 5. Trust Signals and Social Proof

**Types relevant to F&B/wellness:**
- Customer testimonials (specific results, attributed, with photos)
- Before/after transformations (weight management, skin, energy)
- Media mentions and press coverage
- Certifications (halal, organic, MeSTI, KKM)
- Review scores from Google/Shopee/GrabFood
- Order count or customer count ("10,000+ meals delivered")
- Chef/founder story and credentials

**Placement:** Near CTAs and after benefit claims

### 6. Objection Handling

**Common objections in F&B/wellness:**
- "Is it actually tasty?" -- taste proof, reviews, free trial
- "Is it halal/safe/certified?" -- certification badges prominently placed
- "Will it work for me?" -- persona matching ("for busy professionals", "for new moms")
- "Is it worth the price?" -- value comparison, cost-per-meal breakdown
- "What if I don't like it?" -- guarantee, easy cancellation, refund policy
- "Can I customize?" -- dietary options, allergies, preferences

**Address through:** FAQ sections, guarantees, comparison content, process transparency, ingredient lists

### 7. Friction Points

**Look for:**
- Too many steps to order (especially WhatsApp flows)
- Unclear pricing or hidden costs (delivery fees)
- No delivery area information
- Confusing menu navigation
- Required information that shouldn't be required
- Poor mobile experience (most Malaysian traffic is mobile-first)
- Slow load times on images
- No clear operating hours or cut-off times
- **Multilingual consistency** -- if the site serves EN/BM/ZH, check that all UI elements (buttons, labels, nav, footer, error messages) match the selected language. Mixed-language interfaces destroy trust

### Overall CRO Score

After completing all 7 dimensions, calculate the **Overall CRO Score** as the average of all 7 dimension scores (1-10). Present as: `Overall CRO Score: X.X / 10` with a summary table of all dimension scores.

---

## Output Format

Structure recommendations as:

### Quick Wins (Implement Now)
Easy changes with likely immediate impact. Prioritize copy changes, CTA improvements, and mobile fixes.

### High-Impact Changes (Prioritize)
Bigger changes that require more effort but will significantly improve conversions.

### Test Ideas
Hypotheses worth A/B testing rather than assuming. Include expected impact.

### Copy Alternatives
For key elements (headlines, CTAs, product descriptions), provide 2-3 alternatives with rationale.

---

## Page-Specific Frameworks

> See `references/page-frameworks.md` for Homepage, Product/Menu, Pricing, Collection, Blog, and WhatsApp landing page CRO checklists.

## Experiment Ideas, Task Questions & Related Skills

> See `references/experiments-and-questions.md` for experiment test ideas, task-specific intake questions, and related skills (ads-landing, ads-creative, seo-audit, growth, shopify-expert).
