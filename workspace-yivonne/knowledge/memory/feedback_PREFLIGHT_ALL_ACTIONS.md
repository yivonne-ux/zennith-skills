---
name: PREFLIGHT — Run before ANY ads action recommendation
description: ABSOLUTE RULE. Before recommending ANY budget change, campaign change, kill, scale, or creative action — run this checklist FIRST. No exceptions. Human should NEVER need to correct a rule violation.
type: feedback
---

## PREFLIGHT CHECKLIST — Before ANY Ads Action

**Why this exists:** March 25, 2026 — recommended shifting RM120 to Website (33% increase) when the hard rule is max 20% per change. User had to correct me. This is unacceptable. The rule was in my own memory but I didn't check it before speaking.

**Root cause:** I KNOW the rules but don't ENFORCE them systematically before every recommendation. Knowledge without enforcement = useless.

### BEFORE RECOMMENDING ANY BUDGET CHANGE:
- [ ] Is the change ≤ 20% of current budget? (feedback_meta_budget_algorithm_rules.md)
- [ ] Has it been 48+ hours since last change to this campaign? (feedback_meta_ads_hard_rules_march22.md Rule 1)
- [ ] Will this be the ONLY change? (one change at a time)
- [ ] Schedule for midnight (avoid learning phase reset during active hours)

### BEFORE RECOMMENDING ANY AD KILL:
- [ ] Website ads: RM100+ spend AND 0 results? (autoads_analyzer.py rules)
- [ ] WA ads: check Google Sheet FIRST — never kill based on Meta pixel alone (Rule 4)
- [ ] Is this ad in multiple channels? Same ad can fail website but succeed WA.

### BEFORE RECOMMENDING ANY SCALE:
- [ ] Pinxin: 3-day ROAS > 2.3x? (user's rule)
- [ ] Mirra: 3-day blended ROAS > 3.0x? (user's rule)
- [ ] Budget increase ≤ 20%?
- [ ] 48+ hours since last change?
- [ ] Schedule for midnight?

### BEFORE RECOMMENDING ANY NEW CREATIVE:
- [ ] Reference fatigue check done?
- [ ] Food cutout variety check (max 1-2 per ad)?
- [ ] Mood reference assigned?
- [ ] Real pricing verified from website?
- [ ] Packaging from pkg-*.png (never AI)?

### BEFORE ANY CAMPAIGN STRUCTURE CHANGE:
- [ ] Each change resets learning (need 50 conversions in 7 days)
- [ ] Is this truly necessary or can we achieve the goal without restructuring?
- [ ] One change at a time, wait 3-4 days between changes

### THE META-RULE:
**If I'm about to recommend an action, I must mentally run this checklist BEFORE typing the recommendation. If any check fails, I must either adjust the recommendation to comply OR explicitly flag the violation with "⚠️ This exceeds the 20% rule because [reason] — your call."**

**NEVER let the human catch a rule violation. That means the system failed.**
