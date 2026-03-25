# ACCA Flow Gap Analysis
> Comparing ACCA-FLOWS.md spec vs actual Chatwoot bot behavior
> Analysis date: 2026-03-22
> Methodology: Pulled resolved bot conversations from Chatwoot API for each brand inbox

---

## Executive Summary

All 3 brands have **working n8n flows** that handle basic bot responses, but none implement the full 22-step ACCA framework. The current flows are **order-taking tools**, not **sales conversion engines**. The gap is substantial:

| Brand | ACCA Steps Implemented | Steps Missing | Coverage |
|-------|----------------------|---------------|----------|
| Pinxin MY | ~3 of 22 | 19 steps | 14% |
| MIRRA | ~4 of 22 | 18 steps | 18% |
| Rasaya | ~7 of 22 | 15 steps | 32% |

**Critical finding**: No brand has ANY voice messages in their bot flow. Zero of the 15 planned voice messages (5 per brand) exist. This is the single biggest gap since voice messages are the core differentiator of the Eldervive 22-step template.

---

## PINXIN MY (Inbox 85042)

### Steps That Exist

| Step | ACCA Phase | Description | Status |
|------|-----------|-------------|--------|
| 9 | Conviction | Pricing with promotion | Exists but format differs from spec (emoji-heavy blast vs structured text) |
| 22 (partial) | Action | Order form + payment collection | Address template exists, payment info exists |
| - | - | Menu item list for dish selection | Exists (numbered list of 18+ dishes) -- not in ACCA spec but useful |

### Steps That Are Missing

| Step | ACCA Phase | Description | Priority |
|------|-----------|-------------|----------|
| 1 | Awareness | Product hero image | HIGH -- first impression, sets brand tone |
| 2 | Awareness | CS persona intro + problem qualifier | HIGH -- establishes relationship + captures pain point |
| 3 | Comprehension | Key features / USPs | HIGH -- no value proposition communicated |
| 4 | Comprehension | Safety / suitability | MEDIUM |
| 5 | Comprehension | Results timeline | MEDIUM |
| 6 | Comprehension | Engagement checkpoint | HIGH -- no pause-and-listen, just blasts pricing |
| 7 | Comprehension | Trust badges / certifications | MEDIUM |
| 8 | Comprehension | How to prepare (video + text) | MEDIUM |
| 10 | Conviction | Voice message 1 (EN recommendation) | HIGH -- voice messages are the core differentiator |
| 11 | Conviction | Voice message 2 (CN taste reassurance) | HIGH |
| 12 | Conviction | Ingredients detail image | MEDIUM |
| 13 | Conviction | Voice message 3 (EN social proof) | HIGH |
| 14 | Conviction | Voice message 4 (CN urgency) | MEDIUM |
| 15 | Conviction | Speed-freeze education image | LOW |
| 16 | Conviction | Voice message 5 (CN personal touch) | MEDIUM |
| 17-19 | Action | Customer review images (x3) | HIGH -- no social proof images at all |
| 20 | Action | Expert endorsement | MEDIUM |
| 21 | Action | Certificate image | LOW |

### Steps That Need Improvement

| Step | Issue | Fix Needed |
|------|-------|-----------|
| 9 | Pricing blast uses excessive emojis and "Sent via API" tag visible | Rewrite copy to match ACCA spec format. Remove API tag. |
| 9 | Still references "新年配套" (CNY bundle) despite CNY being over | Update to current promotion, remove seasonal references |
| 22 | No structured CTA buttons -- goes straight to menu list | Add WhatsApp button message before dish selection |

### Images That Need to Be Created
1. `hero-pinxin-signature-dishes.jpg` -- Product hero flat-lay (Step 1)
2. `pinxin-ingredients-infographic.jpg` -- Ingredients detail (Step 12)
3. `pinxin-speed-freeze-comparison.jpg` -- Speed-freeze education (Step 15)
4. `pinxin-review-family.jpg` -- Customer testimonial card (Step 17)
5. `pinxin-review-office.jpg` -- Customer testimonial card (Step 18)
6. `pinxin-review-health.jpg` -- Customer testimonial card (Step 19)
7. `pinxin-expert-endorsement.jpg` -- Expert endorsement card (Step 20)
8. `pinxin-certificates.jpg` -- Certificate compilation (Step 21)

### Voice Messages That Need to Be Recorded
1. `wei-lin-en-recommendation.ogg` -- 30-45s (Step 10)
2. `wei-lin-cn-taste-reassurance.ogg` -- 30-45s (Step 11)
3. `wei-lin-en-social-proof.ogg` -- 20-30s (Step 13)
4. `wei-lin-cn-urgency.ogg` -- 20-30s (Step 14)
5. `wei-lin-cn-personal-touch.ogg` -- 15-20s (Step 16)

### Copy That Needs to Be Rewritten
- Step 9: Pricing blast needs restructuring from emoji-heavy format to clean ACCA format
- Step 9: Remove CNY seasonal reference, update to current promotion
- Step 22: CTA needs WhatsApp button structure instead of immediate menu dump
- All Steps 1-8, 10-21: Brand new copy needed (see ACCA-FLOWS.md Sections 3)

---

## MIRRA (Inbox 82477)

### Steps That Exist

| Step | ACCA Phase | Description | Status |
|------|-----------|-------------|--------|
| 7 (partial) | Comprehension | Menu PDF sent | Exists -- monthly menu PDF is sent via bot |
| 8 (partial) | Comprehension | Order policy + how it works | Partial -- order cut-off times and delivery rules exist |
| 9 (partial) | Conviction | Pricing | Exists in abbreviated format ("1pax 10meals RM279.80") |
| 22 (partial) | Action | Order collection | Address + delivery date collection exists via manual CS |

### Steps That Are Missing

| Step | ACCA Phase | Description | Priority |
|------|-----------|-------------|----------|
| 1 | Awareness | Product hero image | HIGH |
| 2 | Awareness | CS persona intro + problem qualifier | HIGH |
| 3 | Comprehension | Key features / USPs | HIGH |
| 4 | Comprehension | Safety / suitability | MEDIUM |
| 5 | Comprehension | Results timeline | MEDIUM |
| 6 | Comprehension | Engagement checkpoint | HIGH |
| 10 | Conviction | Voice message 1 (EN recommendation) | HIGH |
| 11 | Conviction | Voice message 2 (CN taste reassurance) | HIGH |
| 12 | Conviction | Nutrition detail image | MEDIUM |
| 13 | Conviction | Voice message 3 (EN social proof) | HIGH |
| 14 | Conviction | Voice message 4 (CN delivery info) | MEDIUM |
| 15 | Conviction | This vs That comparison image | MEDIUM |
| 16 | Conviction | Voice message 5 (CN closing warmth) | MEDIUM |
| 17-19 | Action | Customer review images (x3) | HIGH |
| 20 | Action | Expert endorsement | MEDIUM |
| 21 | Action | Certificate image | LOW |

### Steps That Need Improvement

| Step | Issue | Fix Needed |
|------|-------|-----------|
| 7 | Menu PDF sent without trust badges | Add trust badge text message alongside PDF |
| 8 | Order policy is sent as first message -- too transactional | Move to later in flow; lead with hero image + persona first |
| 9 | Pricing in abbreviated format ("1pax 10meals RM279.80") | Restructure into full pricing grid showing per-meal value |
| 22 | Order handling is mostly manual human CS | Automate with WhatsApp List message for plan selection |

### Images That Need to Be Created
1. `mirra-hero-bento-topview.jpg` -- Top-view bento, pink/cream, badges (Step 1)
2. `mirra-macro-breakdown.jpg` -- Nutrition infographic (Step 12)
3. `mirra-comparison-whatsapp.jpg` -- Adapt existing comparison images for WhatsApp (Step 15)
4. `mirra-review-beforeafter.jpg` -- Adapt existing before/after into testimonial cards (Step 17)
5. `mirra-review-office.jpg` -- Office lunch testimonial card (Step 18)
6. `mirra-kol-review.jpg` -- KOL review card (Step 19)
7. `mirra-expert-endorsement.jpg` -- Nutritionist + Miss Universe badge (Step 20)
8. `mirra-certificates.jpg` -- Certificate compilation (Step 21)

### Voice Messages That Need to Be Recorded
1. `jia-li-en-recommendation.ogg` -- 30-40s (Step 10)
2. `jia-li-cn-taste-reassurance.ogg` -- 30-40s (Step 11)
3. `jia-li-en-social-proof.ogg` -- 25-30s (Step 13)
4. `jia-li-cn-delivery-info.ogg` -- 20-25s (Step 14)
5. `jia-li-cn-closing-warmth.ogg` -- 15-20s (Step 16)

### Copy That Needs to Be Rewritten
- Steps 7-8: Order policy needs to move from "first message" position to Step 7-8 position
- Step 9: Pricing needs expansion from one-line to full grid with per-meal breakdown
- Steps 1-6, 10-21: Brand new copy needed (see ACCA-FLOWS.md Section 4)

### Existing Assets Available for Adaptation
- 300+ MIRRA brand images (social, product, comparison, lifestyle, hero, beforeafter, testimonial, persona, urgency, sales-boom)
- 17 KOL contacts for endorsement content
- Comparison images already created (mamak vs MIRRA style)
- Before/after customer images exist

---

## RASAYA (Inbox 74152)

### Steps That Exist

| Step | ACCA Phase | Description | Status |
|------|-----------|-------------|--------|
| 7 (partial) | Comprehension | Menu PDF | Exists -- monthly menu PDF sent |
| 8 (partial) | Comprehension | Subscription package info | Partial -- plan details sent but not in structured format |
| 9 (partial) | Conviction | Pricing + free delivery promo | Exists -- RM279.80/RM558.40 pricing with postcode check |
| 13 (partial) | Conviction | Social proof text | Partial -- 3 customer testimonial quotes sent as text |
| 17-19 (partial) | Action | Customer images | Partial -- 3 images sent via API but not ACCA-structured testimonial cards |
| 22 (partial) | Action | Order form + payment | Address collection + CIMB payment info exists |
| - | - | Video testimonial | Exists -- 1 video sent via API (not in ACCA spec as standalone step) |

### Steps That Are Missing

| Step | ACCA Phase | Description | Priority |
|------|-----------|-------------|----------|
| 1 | Awareness | Product hero image | HIGH |
| 2 | Awareness | Health problem qualifier | HIGH -- Rasaya's personalization depends on this |
| 3 | Comprehension | Personalized features by health concern | HIGH -- core differentiator |
| 4 | Comprehension | Safety / suitability | HIGH -- important for health product |
| 5 | Comprehension | Results timeline with case study | HIGH |
| 6 | Comprehension | Engagement checkpoint | MEDIUM |
| 10 | Conviction | Voice message 1 (recommendation) | HIGH |
| 11 | Conviction | Voice message 2 (CN health story) | HIGH |
| 12 | Conviction | Nutritional breakdown image | MEDIUM |
| 14 | Conviction | Voice message 4 (CN urgency) | MEDIUM |
| 15 | Conviction | Blood test before/after image | HIGH -- strongest evidence for Rasaya |
| 16 | Conviction | Voice message 5 (CN closing warmth) | MEDIUM |
| 20 | Action | Expert endorsement | HIGH -- nutritionist team credibility |
| 21 | Action | Certificate image | LOW |

### Steps That Need Improvement

| Step | Issue | Fix Needed |
|------|-------|-----------|
| 13 | Testimonial quotes sent first (before product explanation) | Move to Step 13 position; lead with hero + qualifier |
| 17-19 | Generic images, not structured testimonial cards | Redesign as branded ACCA testimonial cards with specific data |
| 9 | Pricing mixed with delivery promo in one long message | Separate into clean pricing text + separate delivery promo |
| 8 | "Subscription Package" framing is confusing | Restructure as "How It Works" with clear 4-step process |
| All | ACCA order is inverted -- sends proof before explaining product | Reorder entire flow to follow A1->C1->C2->A2 sequence |
| - | Error message visible: "Couldn't receive a message from WhatsApp" retry failures | Fix n8n error handling -- suppress error messages from customer view |

### Images That Need to Be Created
1. `rasaya-hero-heritage-meal.jpg` -- Heritage meal hero shot (Step 1)
2. `rasaya-nutritional-breakdown.jpg` -- GI/macro infographic (Step 12)
3. `rasaya-bloodtest-comparison.jpg` -- Before/after blood test visualization (Step 15)
4. `rasaya-review-bloodtest.jpg` -- Branded blood test testimonial card (Step 17)
5. `rasaya-review-family.jpg` -- Family health journey card (Step 18)
6. `rasaya-review-doctor.jpg` -- Doctor recommendation card (Step 19)
7. `rasaya-expert-endorsement.jpg` -- Nutritionist team credentials (Step 20)
8. `rasaya-certificates.jpg` -- Certificate compilation (Step 21)

### Voice Messages That Need to Be Recorded
1. `mei-ling-recommendation.ogg` -- 30-40s (Step 10)
2. `mei-ling-cn-health-story.ogg` -- 30-40s (Step 11)
3. `mei-ling-social-proof.ogg` -- 25-30s (Step 13)
4. `mei-ling-cn-urgency.ogg` -- 20-25s (Step 14)
5. `mei-ling-cn-closing-warmth.ogg` -- 15-20s (Step 16)

### Copy That Needs to Be Rewritten
- Steps 13/17-19: Existing testimonial content is usable but needs restructuring
- Step 9: Pricing needs clean formatting
- Step 8: "Subscription Package" text needs rewrite as "How It Works"
- Steps 1-7, 10-12, 14-16, 20-21: Brand new copy needed (see ACCA-FLOWS.md Section 5)
- Error handling: n8n flow must suppress retry failure messages

### Note: No Image Directory
- `/Users/jennwoeiloh/.openclaw/workspace/data/images/rasaya/` does NOT exist
- All 8 images must be created from scratch
- Consider using NanoBanana with Rasaya brand DNA (warm amber, heritage kitchen, earthy tones)

---

## CROSS-BRAND GAPS

### Structural Issues (All 3 Brands)

| Issue | Impact | Fix |
|-------|--------|-----|
| No ACCA stage tracking in Chatwoot | Cannot measure funnel progression | Implement `acca_step` custom attribute + stage labels |
| No pause-and-listen checkpoints | Bot dumps all messages without waiting for engagement | Add BTN checkpoints at Steps 2, 6, 9, 16 with wait logic |
| No language detection | Flows are CN-only or mixed | Implement language detection per ACCA-FLOWS.md spec |
| No FAQ routing | Questions go to human CS instead of bot FAQ layer | Build FAQ layer per Section 13 of ACCA doc |
| No frustration detection | Angry customers stay in bot loop | Implement frustration scoring per Section 14 |
| No follow-up sequences | Cart abandonment has no recovery flow | Build FU-CART-1/2/3 sequences per Section 12 |
| No post-purchase sequence | No feedback, review request, or reorder nudge | Build FU-POST-1/2/3/4 sequences per Section 12 |
| "Sent via API" tag visible in messages | Looks unprofessional, breaks immersion | Fix n8n template to suppress API attribution |
| No WhatsApp Business API templates registered | Follow-up messages outside 24h window will fail | Register templates per Section 15B naming convention |

### Total Asset Creation Required

| Asset Type | Pinxin MY | MIRRA | Rasaya | Total |
|-----------|-----------|-------|--------|-------|
| Images (new) | 8 | 6+2 adapt | 8 | 24 |
| Voice messages | 5 | 5 | 5 | 15 |
| Videos | 1 | 0 | 0 | 1 |
| Text copy blocks (new/rewrite) | 19 | 18 | 15 | 52 |

### Priority Ranking for Implementation

**Phase 1 -- Quick Wins (Week 1)**
1. Fix "Sent via API" tag across all brands
2. Add hero image (Step 1) to all 3 brands
3. Add CS persona intro + problem qualifier (Step 2) to all 3 brands
4. Restructure pricing messages (Step 9) to clean ACCA format
5. Add CTA buttons to Step 22

**Phase 2 -- Core Flow (Week 2-3)**
6. Create and add USP messaging (Step 3) for all brands
7. Create and add engagement checkpoints (Step 6) with wait logic
8. Record and add at least 2 voice messages per brand (Steps 10, 11)
9. Create comparison/infographic images (Steps 12, 15)
10. Build FAQ layer for top 5 questions per brand

**Phase 3 -- Full ACCA (Week 4-5)**
11. Complete all remaining voice messages (Steps 13, 14, 16)
12. Create all customer review/testimonial cards (Steps 17-19)
13. Create expert endorsement + certificate images (Steps 20-21)
14. Add results timeline (Step 5) and safety/suitability (Step 4)
15. Add trust badges (Step 7) and how-it-works (Step 8)

**Phase 4 -- Automation (Week 6+)**
16. Build cart abandonment follow-up sequences (FU-CART-1/2/3)
17. Build post-purchase follow-up sequences (FU-POST-1/2/3/4)
18. Implement ACCA stage tracking in Chatwoot labels
19. Implement frustration detection + handoff rules
20. Register WhatsApp Business API templates for outbound messages
21. Implement language detection logic
22. Connect auto-research metrics for continuous optimization

---

## APPENDIX: Chatwoot Label Analysis

### Labels Found Across Conversations

| Label | Meaning | Pinxin | Mirra | Rasaya |
|-------|---------|--------|-------|--------|
| `bot` | Bot handled conversation | Common | Common | Common |
| `paid` | Customer completed payment | Common | Common | Common |
| `approached_customer` | Bot initiated outreach | Common | Common | Common |
| `new_user` | First-time customer | Present | Present | Present |
| `human_in_need` | Required human handoff | Rare | Present | Present |
| `handoff_cases` | Escalated to human | Rare | Present | Present |
| `follow_up_px_my` | Pinxin MY follow-up | Rare | N/A | N/A |
| `pre_ordering` | In ordering process | Rare | N/A | N/A |
| `post_ordering` | After order placed | Rare | N/A | N/A |

### Missing Labels (from ACCA spec Section 15A)
- `acca:awareness` / `acca:comprehension` / `acca:conviction` / `acca:action`
- `brand:{brand_name}`
- `lang:{cn|en|ms}`
- `pain_point:{category}`
- `fu:cart-1` / `fu:cart-2` / `fu:cart-3`
- `status:converted` / `status:abandoned` / `status:handoff`
