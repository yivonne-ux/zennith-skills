# Auto-Research — Use Cases & Config Format

## Use Cases for Zennith OS

### 1. Ad Creative Optimization
- **Objective**: CTR or ROAS
- **Generate**: Ad headline + body copy variants
- **Evaluate**: Score against hook power, clarity, urgency, brand voice, CTA strength
- **Feedback**: Meta Ads API performance data (when available)
- **Config**: `configs/ad-creative.yaml`

### 2. Email Subject Lines
- **Objective**: Open rate
- **Generate**: Subject line variants
- **Evaluate**: Score against curiosity, urgency, personalization, length, spam-safety
- **Config**: `configs/email-subject.yaml`

### 3. Product Descriptions
- **Objective**: Conversion rate
- **Generate**: Product description variants
- **Evaluate**: Score against benefit clarity, SEO keywords, emotional trigger, social proof, scannability
- **Config**: `configs/product-description.yaml`

### 4. Content Thumbnails & Hooks
- **Objective**: Click-through or watch-time
- **Generate**: Hook/thumbnail copy variants
- **Evaluate**: Score against pattern interrupt, curiosity gap, specificity, emotion, promise
- **Feedback**: YouTube/TikTok analytics (when available)

### 5. Pricing Copy
- **Objective**: Revenue per visitor
- **Generate**: Pricing page copy variants
- **Evaluate**: Score against value framing, anchor pricing, urgency, objection handling, clarity

### 6. QMDJ Reading Quality
- **Objective**: User satisfaction
- **Generate**: Reading format/structure variants
- **Evaluate**: Score against accuracy, actionability, personalization, cultural sensitivity, clarity
- **Feedback**: User satisfaction ratings (when available)

## Config Format

```yaml
# Required
objective: "CTR"
task: "Write a Facebook ad headline for MIRRA plant-based bento"
template: |
  Healthy eating made easy. MIRRA plant-based bento — order now.

# Evaluation criteria (binary yes/no, like Karpathy's checkboxes)
criteria:
  - id: hook_power
    description: "Opens with a pattern interrupt or curiosity gap"
  - id: clarity
    description: "Main benefit is obvious within 3 seconds"
  - id: emotion
    description: "Triggers a specific emotion (curiosity, desire, fear of missing out)"
  - id: urgency
    description: "Creates time pressure or scarcity"
  - id: brand_voice
    description: "Matches MIRRA brand voice — warm, Malaysian, health-conscious"
  - id: cta_strength
    description: "Call to action is clear and compelling"

# Optional
max_iterations: 10
keep_threshold: null  # null = must beat current best
model: "claude-sonnet-4-6"
brand: "mirra"
output_dir: "~/.openclaw/workspace/data/auto-research/mirra-ad"

# Real-world feedback (optional — adds to LLM eval)
feedback_sources:
  - type: meta_api
    campaign_id: "123456"
    metric: "ctr"
  - type: shopify_api
    metric: "conversion_rate"
```

## Output Structure

```
output_dir/
  best.txt              — Current best variant (plain text)
  best_score.json       — Current best score breakdown
  learnings.json        — All experiments: scores, deltas, what worked/didn't
  variants/
    001.txt             — Variant 1
    001_score.json      — Variant 1 score
    002.txt             — Variant 2
    ...
  run_summary.json      — Final summary: iterations, improvements, best score
```

## Integration with Zennith OS

### Pub-Sub Events
- **Emits** `auto-research.variant.improved` when a better variant is found
- **Emits** `auto-research.run.complete` when the loop finishes
- **Listens** for `pipeline.content.needs-optimization` to auto-start loops

### Content Factory Integration
- Output feeds into content-tuner's winning patterns pipeline
- Best variants can be promoted to brand DNA via content-tuner

### Agent Usage
- **Dreami**: Ad creative and content hook optimization
- **Apollo**: Email subject lines and product description optimization
- **Hermes**: Pricing copy and ad performance optimization
- **Artemis**: Research-backed content quality optimization
