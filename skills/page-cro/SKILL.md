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

Analyze the page across these 7 dimensions, in order of impact:

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

### Homepage / Brand Landing Page
- Clear positioning for cold visitors (from Meta ads, Google, or IG bio)
- Quick path to most common conversion (order, subscribe, consult)
- Handle both "ready to buy" and "still researching" visitors

### Product / Menu Page
- Appetite appeal through photography and description
- Clear pricing with no surprises
- Easy add-to-cart or order flow
- Dietary/allergen info visible without extra clicks

### Pricing / Subscription Page
- Clear plan comparison (if multiple tiers)
- Recommended plan highlighted
- Per-meal or per-day cost breakdown
- Address "which plan is right for me?" anxiety
- Commitment flexibility (weekly vs. monthly)

### Collection / Category Page
- Filter by dietary need, price range, or occasion
- Quick-view or add-to-cart without leaving page
- Bestseller or "most popular" indicators

### Blog / Content Page
- Contextual CTAs matching content topic
- Inline CTAs at natural stopping points
- Recipe-to-product connection (if applicable)

### WhatsApp Landing Page
- Pre-filled WhatsApp message with context
- Minimal friction between landing and messaging
- Clear expectation of response time

---

## Experiment Ideas

When recommending experiments, consider tests for:
- Hero section (headline, hero image, CTA)
- Social proof placement and format
- Pricing presentation (per-meal vs. total, with/without comparison)
- Menu layout (grid vs. list, with/without filters)
- Trust signals (certifications, reviews, founder story)
- Mobile UX (sticky CTA, bottom navigation, swipe galleries)

---

## Task-Specific Questions

1. What is the brand and page URL?
2. What is the current conversion rate and goal?
3. Where is traffic coming from? (Meta ads, Google, WhatsApp, IG bio, organic)
4. What does the order/signup flow look like after this page?
5. Do you have heatmaps, session recordings, or analytics data?
6. What have you already tried?
7. What is the primary market? (Malaysia, Singapore, regional)

---

## Related Skills

- **ads-landing**: For landing pages specifically tied to paid ad campaigns
- **ads-creative**: For ad creative quality audit
- **seo-audit**: For organic search optimization
- **growth**: For combined SEO + CRO + SMO growth strategy
- **shopify-expert**: For Shopify theme and conversion optimization
