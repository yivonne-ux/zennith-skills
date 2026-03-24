# autoads — Autonomous Ad Research System
> Inspired by karpathy/autoresearch. Same loop: experiment → measure → keep/discard → repeat.
> But for Meta Ads instead of ML models.

## The Loop

```
LOOP DAILY:
1. PULL DATA — Meta API (spend, CPA, ROAS, CTR, ATC, purchases) + Google Sheet (WA sales)
2. ANALYZE — compare each ad against kill/keep thresholds
3. KILL — pause ads that meet kill criteria
4. LEARN — extract WHY winners work (visual pattern, copy pattern, format)
5. GENERATE — create 3-5 new concepts based on winner DNA
6. UPLOAD — push new ads to Meta via API
7. LOG — record results in results.tsv
8. WAIT 48 HOURS — let new ads exit learning
9. REPEAT
```

## What We Measure (the "val_bpb" equivalent)

Primary metric: **CPA (Cost Per Acquisition)**
Secondary: ROAS, CTR, ATC rate, Click→Purchase rate

## Kill/Keep Rules

```
KILL if (after 48+ hours):
  - spend > RM100 AND purchases == 0
  - CTR < 0.3% (after 1000+ impressions)
  - CPA > 2x campaign average

KEEP if:
  - CPA < campaign average
  - ROAS > 2x
  - ATC rate > 10% (strong intent signal even without purchase yet)

SCALE if (after 7+ days):
  - CPA < 0.5x campaign average AND 3+ purchases
  - Consistent ROAS > 3x over 5+ days
```

## Generation Rules (the "train.py" equivalent)

When generating new ads, use DNA from winners:

```
WINNER DNA EXTRACTION:
1. Visual format — what does it LOOK like? (raw lofi, format hijack, product showcase)
2. Copy pattern — what's the HEADLINE formula? (number-driven, question, statement)
3. Emotional trigger — what FEELING does it create? (urgency, FOMO, curiosity, hunger)
4. Price position — WHERE and HOW is price shown?
5. CTA type — what ACTION does it ask? (WhatsApp, website, learn more)

VARIATION RULES:
- Same format + different dish = variation (BOFU-10 lofi with rendang → lofi with BKT)
- Same dish + different format = new concept (rendang as lofi → rendang as receipt)
- Same format + different copy angle = A/B test (lofi + urgency → lofi + social proof)
- NEVER repeat exact same visual + copy combo
```

## Constraints

```
- Max 15-20 ads per ad set (Andromeda optimal)
- Kill BEFORE adding (maintain count)
- 3-5 new concepts per cycle (not 20)
- Post-process: resize(9:16, blur-pad) → logo → grain(0.028) ONLY
- References MUST be 9:16 before NANO
- Food photos are SACRED (never AI-generated)
- PIL = resize + logo + grain ONLY (no text rendering)
```

## Data Sources

```python
# Meta API
TOKEN = open(Path.home() / "Desktop/_WORK/_shared/.meta-token").read().strip()
ACC = "act_138893238421035"

# Google Sheet (WA sales)
SHEET = "https://docs.google.com/spreadsheets/d/1Wuz9gvmfDVFufgth6cZECuj1N4ZuwDw9HRfbkI6QCnc/gviz/tq?tqx=out:csv&gid=0"

# Brand paths
BRAND_BASE = Path.home() / "Desktop/_WORK/pinxin"
FINALS = BRAND_BASE / "06_exports/finals/static"
CAMPAIGNS = BRAND_BASE / "06_exports/campaigns"
REJECTED = BRAND_BASE / "06_exports/rejected"
SCRIPTS = BRAND_BASE / "05_scripts"
```

## Results Log

Track in `_WORK/pinxin/02_strategy/autoads-results.tsv`:

```
date	ad_name	spend	purchases	cpa	roas	atc	ctr	status	notes
2026-03-22	PX-BOFU-10-LC	41	2	20	3.2x	8	1.5%	keep	raw lofi format — best CPA
2026-03-22	PX-TNG-PROMO-LC	163	5	33	4.78x	19	1.0%	scale	promotion urgency — today's star
2026-03-22	PX-BOFU-18-LC	49	1	49	2.6x	7	0.8%	keep	boarding pass format hijack
2026-03-22	PX-BOFU-05-LC	35	0	—	—	23	1.1%	watch	23 ATC but 0 purchases — checkout issue?
2026-03-22	PX-FOOD-09-LC	5	0	—	—	0	0.0%	kill	food hero = 0 engagement
```

## How to Run

```bash
# Daily check (manual trigger or cron)
cd ~/Desktop/_WORK/pinxin
python3 05_scripts/autoads_check.py

# Output:
# 1. Performance table
# 2. Kill list (with reasons)
# 3. Winner DNA analysis
# 4. Generation brief for next 3-5 concepts
# 5. Updated results.tsv
```

## Never Stop

Like autoresearch: once the loop begins, it runs until manually stopped.
Each cycle is 48 hours (not 5 minutes like ML training).
Over 30 days = 15 cycles = potentially 75 new concepts tested.
The ad set should converge toward optimal CPA over time as losers are killed
and winner variations are reinforced.
