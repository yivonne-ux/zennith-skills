# Learnings — character-lock

## 2026-03-28 — PATTERN
**What happened:** Built character-lock skill to fix Jade consistency drift
**What worked:** Validation catches "editorial" in Jade prompts, negated "no illustration" passes correctly
**What failed:** Initial never-list check had false positives — "no illustration" contains "illustration"
**Pattern:** Never-list validation must check for negated context (no/not/never prefix). Use regex: (?:no|not|never)\s+{word} to skip negated matches.

## 2026-03-28 — PATTERN
**What happened:** Jade character spec scattered across 10+ locations
**What worked:** Standardized schema (character-spec.schema.json) with ONE canonical location per brand
**What failed:** Multiple conflicting specs caused drift — jade-spec-v2.json vs character-bible.md vs face-lock-protocol.md
**Pattern:** ONE spec.json per character, ONE canonical location (~/.openclaw/brands/{brand}/characters/{name}/spec.json). All other docs reference this file.
