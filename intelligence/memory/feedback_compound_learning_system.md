---
name: Compound learning system — auto-enforce all production rules
description: CRITICAL PROCESS. Every production script MUST import and run preflight_check() before generation and audit_output() after. Rules live in code, not just memory files.
type: feedback
---

## The Problem (recurring)

Rules exist in memory files but scripts don't enforce them. Every new batch repeats the same mistakes:
- Dark backgrounds (rejected 3+ times)
- Bowl foods instead of bento boxes (rejected 4+ times)
- Headline-food mismatch
- Duplicate captions across ad sets
- No reference images used
- Wrong color palette
- Prompt text leaking into image
- Stretching from img.resize()

**Why:** Memory files are documentation. They inform ME but don't constrain the CODE. The script runs fine even when it violates every rule. There's no gate.

## The Fix — Enforced Intelligence

Every production script MUST follow this pattern:

```python
# Import intelligence engine
from intelligence.preflight import preflight_check
from intelligence.audit import audit_output
from intelligence.resize import fit_to_size
from intelligence.post_process import add_grain
from intelligence.brand_registry import get_brand, get_logo_path, get_grain_strength

# BEFORE generation — preflight gate
violations = preflight_check(variants, brand)
if violations:
    print("BLOCKED:")
    for v in violations:
        print(f"  {v}")
    sys.exit(1)  # DO NOT PROCEED

# AFTER generation — audit gate
result = audit_output(final_path, variant, brand)
if not result["passed"]:
    print(f"FAILED: {result['violations']}")
    # Move to rejected/, do not include in finals/
```

## What Preflight Catches (auto)
1. No reference image → BLOCKED
2. Bowl food in hero/grid → BLOCKED (bibimbap, congee, jawa_mee, burrito)
3. Headline mentions dish X but food photo is Y → BLOCKED
4. Dark/charcoal color mood for Mirra → BLOCKED
5. "dark background" in prompt for Mirra → BLOCKED
6. Duplicate captions across variants → BLOCKED
7. Food ratio below 50% → BLOCKED
8. Color mood overused (>40% same mood) → BLOCKED
9. Missing ANTI_RENDER or NO_LOGO in prompt → BLOCKED
10. Forbidden words in copy → BLOCKED
11. AI human requested in prompt → BLOCKED

## What Audit Catches (auto)
1. Wrong dimensions → FAIL
2. Stretched aspect ratio → FAIL
3. Dark background detected → FAIL (for Mirra)
4. Missing logo → WARNING
5. Missing grain → WARNING
6. Blank/corrupt image → FAIL
7. File too small → WARNING

## How to Apply
- When I write ANY production script, I MUST import preflight + audit
- I MUST run preflight BEFORE any API call
- I MUST run audit AFTER post-processing, BEFORE saving to finals/
- Failed audits go to rejected/ not finals/
- New rules discovered = update preflight.py and audit.py CODE, not just memory files
