---
name: offer-builder
description: "When the user wants to build a signature offer, productize a service, create an offer page, or says 'offer builder', 'build my offer', 'signature offer', 'productize', 'what should I sell'."
agents:
  - scout
  - dreami
---

# Offer Builder — Signature Offer Creation Pipeline

7-step pipeline for building signature offers, based on @rosspower's "Productize Yourself" prompts framework. Takes a brand or individual from raw intellectual property to a high-converting landing page.

## When to Use

- Building a signature offer for a GAIA brand or external client
- Productizing a service, skill, or body of knowledge
- Creating an offer page or sales funnel
- Answering "what should I sell?" or "how do I package my expertise?"
- Launching a new revenue stream from existing IP

## Procedure

Run steps sequentially. Each step builds on the previous. Save all outputs to `~/.openclaw/workspace/data/offers/{brand-or-name}/`.

---

### Step 1 — IP Magic Question (Scout)

Excavate the user's intellectual property using Daniel Priestley's IP framework.

> **Product vs Service Fork**: If the offer is for a physical product (D2C, e-commerce), adapt IP questions: replace "what do people ask YOUR advice on" with "what problem does this product solve better than alternatives". Adjust Step 6 format options to include: Physical product bundle, Subscription box, Starter kit, Discovery set. Adjust Step 7 landing page template for e-commerce conventions (product gallery, ingredient list, shipping info, Shopify add-to-cart).

Ask these questions (adapt to context):

1. **What do people constantly ask your advice on?** Even casually — at parties, in DMs, at work.
2. **What do you know that most people in your industry don't?** Insider knowledge, shortcuts, frameworks.
3. **What have you built, created, or systematized?** Processes, templates, systems, SOPs.
4. **What transformation have you personally gone through?** Before/after that others want.
5. **What could you talk about for 30 minutes with zero preparation?** The thing you never shut up about.

**Output**: IP Profile document — list of 5-10 IP assets ranked by monetization potential.

**Agent**: Scout researches the market around each IP asset. Look for existing demand signals (Reddit, Quora, X, Google Trends).

---

### Step 2 — ICP Builder (Scout)

Identify ONE vivid ideal client. Not a demographic — a person.

Build the ICP card:

| Field | Description |
|-------|-------------|
| Name | Give them a real name (e.g., "Sarah") |
| Age | Specific age, not a range |
| Situation | What is happening in their life RIGHT NOW |
| Frustration | The thing keeping them up at 2am |
| Failed Attempts | What they've already tried that didn't work |
| Secret Desire | What they want but won't say out loud |
| Trigger Event | What makes them finally search for a solution TODAY |
| Where They Hang Out | Specific platforms, communities, subreddits, groups |
| Budget Reality | What they can actually spend (not what you wish they'd spend) |

**Key rule**: If your ICP could be anyone, it's no one. Make it so specific it feels uncomfortable.

**Agent**: Scout validates this ICP against real communities — check if these people actually exist and are actually spending money on solutions.

---

### Step 3 — 99 Problems (Scout + Dreami)

Generate 99 problems your ICP faces, organized across 5 categories:

| Category | Count | Description | Example |
|----------|-------|-------------|---------|
| **Surface** | ~20 | Obvious, stated problems | "I don't know what to post on social media" |
| **Hidden** | ~20 | Problems they feel but can't articulate | "I'm copying competitors because I have no original voice" |
| **Systemic** | ~20 | Root causes behind the symptoms | "No positioning strategy means every piece of content is a guess" |
| **Emotional** | ~20 | How it makes them FEEL | "I feel like a fraud every time I hit publish" |
| **Social** | ~19 | How others perceive them because of it | "My peers think I'm not serious about my business" |

**Agent roles**:
- Scout: Research real complaints from forums, reviews, Reddit, X, YouTube comments
- Dreami: Expand into emotional and social dimensions, craft vivid language

**Output**: Numbered list of 99 problems saved to `99-problems.md`.

---

### Step 4 — MoSCoW Prioritisation

Sort the 99 problems into MoSCoW categories:

| Priority | Meaning | Criteria |
|----------|---------|----------|
| **Must Have** | Non-negotiable — offer fails without solving these | ICP would NOT buy if these aren't addressed |
| **Should Have** | Important differentiators | Makes your offer significantly better than alternatives |
| **Could Have** | Nice-to-have bonuses | Adds perceived value but not essential |
| **Won't Have** | Explicitly excluded (for now) | Out of scope — save for upsells or V2 |

**Rules**:
- Must Have should be 5-8 problems maximum (focus)
- Won't Have is strategic — it defines your boundaries
- Every Must Have needs a clear deliverable that solves it

**Output**: MoSCoW matrix saved to `moscow.md`.

---

### Step 5 — Competitor Deep Dive (Scout)

Map the competitive landscape across 4 dimensions:

#### A. Direct Competitors
Who sells a similar offer to a similar audience?

| Competitor | Offer | Price | Strengths | Weaknesses | Gap You Can Fill |
|-----------|-------|-------|-----------|------------|-----------------|
| ... | ... | ... | ... | ... | ... |

#### B. Indirect Alternatives
Different solution to the same problem (e.g., hiring a consultant, buying a course, using a free tool).

#### C. DIY Option
What happens if the ICP tries to solve this themselves? List the real costs: time, mistakes, opportunity cost, stress.

#### D. "Do Nothing" Option
What happens if the ICP does nothing? Paint the cost of inaction vividly — this becomes your urgency lever.

**Agent**: Scout scrapes competitor offers, pricing pages, and reviews. Use firecrawl or agent-reach for research.

**Output**: Competitive landscape document saved to `competitors.md`.

---

### Step 6 — Offer Builder (Dreami)

Construct the signature offer using this template:

```markdown
## [OFFER NAME]

**Who it's for**: [One sentence describing your ICP from Step 2]

**The problem**: [Core Must Have problem from Step 4]

**Before → After**:
| Before (Current State) | After (Desired State) |
|----------------------|---------------------|
| [Specific pain point] | [Specific outcome] |
| [Specific pain point] | [Specific outcome] |
| [Specific pain point] | [Specific outcome] |

**What's included**:
1. [Core deliverable that solves Must Have #1]
2. [Core deliverable that solves Must Have #2]
3. [Bonus that solves Should Have #1]
4. [Bonus that solves Should Have #2]

**Format**: [Live cohort / Self-paced / 1:1 / Hybrid / Productized service / SaaS]

**Duration**: [Timeline]

**Price**: [Specific number — not a range]

**Guarantee**: [Risk reversal — what happens if it doesn't work]
```

**Cold-Friendly Test**: Can a stranger who has never heard of you understand what this is, who it's for, and why they should care — in under 10 seconds? If not, simplify.

**Agent**: Dreami writes the offer copy. Run `brand-voice-check.sh` if this is for a GAIA brand.

**Output**: Offer document saved to `offer.md`.

---

### Step 6.5 — Compliance Check

Before building the landing page, verify regulatory compliance:

- **Health/wellness/supplements brands**: Verify all claims comply with Malaysian NPRA, KKM, and advertising regulations. No unsubstantiated health claims. Use "supports" not "cures". Check if MeSTI/halal certification is required.
- **F&B brands**: Verify nutritional claims are accurate.
- **Skincare brands**: Verify ingredient safety claims.

Flag any claims in the offer document (Step 6) that need softening or evidence. Revise offer copy before proceeding to the landing page.

**Output**: Compliance notes appended to `offer.md` or saved to `compliance-check.md`.

---

### Step 7 — Landing Page (Dreami)

Generate high-converting landing page copy with these sections:

#### Hero Section
- **Headline**: Speaks to the ICP's #1 desire (from Step 2 Secret Desire)
- **Subheadline**: Adds specificity — who, what, timeframe
- **CTA**: Clear, action-oriented button text

#### Problem Section
- Paint the "before" state using emotional language from Step 3
- 3-5 bullet points of pain (Surface + Emotional problems)
- End with: "Sound familiar?"

#### Solution Section
- Introduce the offer as the bridge from Before to After
- Use the Before/After table from Step 6

#### Benefits (Not Features)
- Reframe each deliverable as an outcome
- "You get X" → "You'll finally Y"

#### Social Proof
- Placeholder slots for testimonials, case studies, logos
- If new offer: use "As featured in" or credibility markers

#### Objection Handling
- Address top 3-5 objections the ICP will have
- Format: "But what if [objection]?" → "[Counter]"
- Common: "I don't have time", "I've tried this before", "It's too expensive", "Will this work for me?"

#### Pricing Section
- Anchor against the cost of the problem (from Step 5D — Do Nothing option)
- Stack the value: list everything included with individual values
- Show the total value vs. the actual price

#### Final CTA
- Urgency lever (scarcity, deadline, or bonus expiration)
- Repeat the CTA button
- One-line guarantee reminder

**Output**: Landing page copy saved to `landing-page.md`.

---

## Output Summary

At the end of the pipeline, the user has:

| Deliverable | File |
|-------------|------|
| IP Profile | `ip-profile.md` |
| ICP Card | `icp.md` |
| 99 Problems | `99-problems.md` |
| MoSCoW Matrix | `moscow.md` |
| Competitive Landscape | `competitors.md` |
| Signature Offer | `offer.md` |
| Landing Page Copy | `landing-page.md` |

All saved to `~/.openclaw/workspace/data/offers/{brand-or-name}/`.

## Related Skills

- `onboard-brand` — If the offer needs a new brand identity first
- `campaign-planner` — To plan the ad campaign that drives traffic to the offer
- `ads-landing` — To evaluate the landing page quality for paid traffic
- `shopify-engine` — If the offer needs a Shopify storefront
- `brand-voice-check.sh` — Mandatory for GAIA brand offers before publishing
