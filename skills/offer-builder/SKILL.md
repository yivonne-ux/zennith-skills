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

> Load `references/step-details.md` for full templates, interview questions, ICP card fields, 99 Problems categories, MoSCoW matrix, competitor analysis dimensions, offer template, compliance checks, and landing page section specifications.

### Step 1 — IP Magic Question (Scout)
Excavate the user's IP using Daniel Priestley's framework — 5 questions about advice, insider knowledge, systems, transformations, and passions. Output: IP Profile with 5-10 assets ranked by monetization potential.

### Step 2 — ICP Builder (Scout)
Build ONE vivid ideal client card — name, age, situation, frustration, failed attempts, secret desire, trigger event, hangout spots, budget. Make it uncomfortably specific.

### Step 3 — 99 Problems (Scout + Dreami)
Generate 99 problems across 5 categories: Surface (~20), Hidden (~20), Systemic (~20), Emotional (~20), Social (~19). Scout researches real complaints; Dreami expands emotional dimensions.

### Step 4 — MoSCoW Prioritisation
Sort 99 problems into Must Have (5-8 max), Should Have, Could Have, Won't Have. Every Must Have needs a clear deliverable.

### Step 5 — Competitor Deep Dive (Scout)
Map competitive landscape: Direct competitors (table), Indirect alternatives, DIY option (real costs), "Do Nothing" option (urgency lever).

### Step 6 — Offer Builder (Dreami)
Construct the signature offer: who it's for, the problem, before/after table, what's included, format, duration, price (specific number), guarantee. Apply Cold-Friendly Test.

### Step 6.5 — Compliance Check
Verify regulatory compliance for health/wellness/F&B brands (Malaysian NPRA, KKM, MeSTI/halal). Flag claims that need softening.

### Step 7 — Landing Page (Dreami)
Generate high-converting copy: Hero (headline + CTA), Problem (paint the pain), Solution (before/after bridge), Benefits (outcomes not features), Social Proof, Objection Handling, Pricing (anchor + stack), Final CTA.

## Output Summary

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
