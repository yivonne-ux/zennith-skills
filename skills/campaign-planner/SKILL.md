---
name: campaign-planner
description: Campaign brief generation engine for GAIA CORP-OS ad factory. Generates structured ad campaign briefs from Tricia's template taxonomy + strategic directions.
agents:
  - dreami
---

# campaign-planner

Campaign brief generation engine for GAIA CORP-OS ad factory.

## Purpose
Generate structured ad campaign briefs from Tricia's template taxonomy + strategic directions. Outputs JSON briefs that flow through the creative pipeline: Brief -> Copy (Dreami) -> Visual (Iris) -> QA (Argus) -> Publish (Hermes).

## Owner
- **Hermes** — campaign structure, budget allocation, A/B test design
- **Dreami** — fills copy into briefs (headlines, subcopy, USP points)
- **Iris** — generates visuals from brief descriptions

## Commands

```bash
# Generate campaign variants
campaign-planner.sh create \
  --brand mirra \
  --direction en-1 \
  --template-type M2 \
  --variants 5 \
  --week 10

# List available directions
campaign-planner.sh directions --brand mirra [--lang en|cn]

# Generate full campaign (all template types for a direction)
campaign-planner.sh full-campaign \
  --brand mirra \
  --direction en-1 \
  --mofu-sets "M1,M2,M3,M4,M5" \
  --bofu-sets "B1,B2,B4"

# List tracked campaigns
campaign-planner.sh list --brand mirra [--status brief]
```

## Data Flow
1. Reads: `brands/{brand}/templates/templates.json` + `brands/{brand}/campaigns/directions.json`
2. Outputs: JSON to stdout + appends to `workspace/data/campaign-tracker.jsonl`
3. Posts summary to `rooms/exec.jsonl`

## Template Types
- **MOFU**: M1 (Faces/KOL), M2 (Product/Benefit), M3 (Group/Album), M4 (VS/BeforeAfter), M5 (Testimonial)
- **BOFU**: B1 (Sales Boom), B2 (Last Call), B3 (Raw), B4 (Prices/COD)

## Budget Rules (from Tricia)
- MOFU: RM25-40 per ad set
- BOFU: RM30-50 per ad set
- Kill switch: ROAS < 1.0x for 24h = pause

## Drip Sequences & Pre-Mortem

The following features are implemented in `campaign-planner.sh`:

```bash
# Pre-mortem risk analysis
campaign-planner.sh pre-mortem --brand mirra --campaign "CNY Bundle" --budget 500 --launch-date 2026-03-15

# Drip sequence templates (welcome, abandoned-cart, re-engagement, post-purchase)
campaign-planner.sh drip --brand mirra --sequence welcome --channel email
campaign-planner.sh drip --brand mirra --sequence abandoned-cart --channel whatsapp
```

### Drip Sequence Design

### Email Drip Templates

| Sequence | Emails | Span | Flow |
|----------|--------|------|------|
| **Welcome series** | 5 | 14 days | Welcome → Value → Social proof → Offer → Urgency |
| **Abandoned cart** | 3 | 3 days | Reminder → Incentive → Last chance |
| **Re-engagement** | 3 | 7 days | Miss you → What's new → Win-back offer |
| **Post-purchase** | 4 | 30 days | Thank you → How-to → Review request → Upsell |

### Multi-Channel Orchestration

```
Day 0:  Email (welcome) + WhatsApp (hi!)
Day 1:  SMS (reminder) if email not opened
Day 3:  Email (value content)
Day 5:  WhatsApp (social proof)
Day 7:  Email (offer) + retargeting ad activated
Day 14: Final email (urgency) + SMS if high-value lead
```

### Trigger Rules

- **Open** → advance to next stage
- **No open after 48h** → switch channel
- **Click** → tag as "engaged", fast-track to offer
- **Unsubscribe** → remove from all sequences, add to suppression
- **Purchase** → move to post-purchase sequence
- **Auto-terminate** → after 3 consecutive no-opens

### Integration with GAIA Tools

- **Klaviyo** for email automation (see `klaviyo` skill)
- **WhatsApp** via `wacli` for messaging
- **Meta Ads** for retargeting triggers
- **Content** from `content-seed-bank` for drip content

### Pre-Mortem Analysis

Run this BEFORE launching any campaign. The question: **"It's 30 days from now and this campaign failed. Why?"**

```bash
campaign-planner.sh pre-mortem --brand mirra --campaign "Spring Sale" --budget 1000 --launch-date 2026-04-01
```

Outputs a structured markdown file with Tigers/Paper Tigers/Elephants risk categories and a sign-off checklist. Saved to `~/.openclaw/workspace/data/campaigns/{brand}/`.

### Risk Categories

| Category | Definition | Action Required |
|----------|-----------|-----------------|
| **Tigers** | High probability + High impact | MUST mitigate before launch — no exceptions |
| **Paper Tigers** | High probability + Low impact | Monitor during campaign, have quick fixes ready |
| **Elephants** | Low probability + High impact | Have contingency plan documented, don't delay launch |
| **Kittens** | Low probability + Low impact | Accept the risk, ignore |

### Pre-Mortem Template
```
CAMPAIGN: _______________
BRAND: _______________
LAUNCH DATE: _______________
BUDGET: RM _______________

"This campaign launched 30 days ago and failed. Here's why:"

TIGERS (must fix before launch):
1. [ ] _______________
   Mitigation: _______________
2. [ ] _______________
   Mitigation: _______________

PAPER TIGERS (monitor closely):
1. [ ] _______________
   Quick fix: _______________
2. [ ] _______________
   Quick fix: _______________

ELEPHANTS (contingency ready):
1. [ ] _______________
   Contingency: _______________
2. [ ] _______________
   Contingency: _______________

SIGN-OFF: All Tigers mitigated? [ ] YES → proceed to launch
```

### Common Campaign Failure Modes
| Failure | Category | Prevention |
|---------|----------|-----------|
| Creative fatigue within first week | Tiger | Have 5+ variants ready at launch |
| Wrong audience targeting | Tiger | Validate with small budget test first |
| Landing page broken on mobile | Tiger | QA on 3+ devices before launch |
| Budget burns too fast | Paper Tiger | Set daily caps, monitor first 24h |
| Competitor launches same week | Elephant | Have differentiation messaging ready |
| Platform policy rejection | Tiger | Review ad policies checklist pre-submit |
| Low stock / fulfillment delay | Tiger | Confirm inventory before launch |
| Negative comments / PR issue | Elephant | Prepare response templates |
| Seasonal timing miss | Paper Tiger | Cross-check with campaign calendar |

## Dependencies
- python3, templates.json, directions.json, DNA.json
