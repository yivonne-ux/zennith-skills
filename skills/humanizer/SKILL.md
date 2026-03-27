---
name: humanizer
description: >
  Quality gate that detects and removes AI writing patterns from any text output.
  Scans for filler phrases, corporate speak, generic structures, and predictable
  patterns. Rewrites flagged sections to sound natural and human. Run BEFORE
  publishing any content.
metadata:
  clawdbot:
    emoji: "\U0001F9F9"
    agents: [dreami]
    triggers:
      - "humanize this"
      - "check for AI slop"
      - "make it sound human"
      - "remove AI patterns"
      - "humanizer"
      - "quality gate"
---

# Humanizer -- AI Slop Detection Gate

**Purpose:** Catch and kill AI writing patterns before they reach the audience.
Every piece of content passes through this gate before publishing. No exceptions.

---

## AI Slop Pattern Library

### Category 1 -- Filler Phrases (kill on sight)
- "In today's fast-paced world"
- "In today's digital age"
- "It's worth noting that"
- "It's important to note that"
- "Let's dive in" / "Let's explore"
- "In conclusion" / "To summarize" / "In summary"
- "Without further ado"
- "Look no further"
- "At the end of the day"
- "Whether you're a X or a Y"
- "Are you ready to"

### Category 2 -- Corporate Buzzwords (flag and replace)
- "leverage" (use: use, apply, tap into)
- "utilize" (use: use)
- "facilitate" (use: help, enable, make possible)
- "robust" (use: strong, solid, reliable)
- "seamless" (use: smooth, easy, effortless)
- "elevate" (use: improve, raise, strengthen)
- "holistic" (use: complete, full, whole)
- "synergy" (use: teamwork, combination, partnership)
- "empower" (use: help, enable, give)
- "innovative" (use: new, fresh, original)
- "cutting-edge" (use: modern, latest, advanced)
- "game-changer" (use: breakthrough, shift, turning point)

### Category 3 -- Structural Slop (flag and restructure)
- Every paragraph starting with a transition word ("Furthermore", "Moreover", "Additionally")
- Listicle format when narrative/prose would be more natural
- Predictable 3-part structure (intro hook, body, CTA) with no variation
- Generic social proof ("many people", "experts agree", "studies show" without citation)
- "Take your X to the next level"
- Numbered lists where flowing text reads better

### Category 4 -- Excessive Patterns (flag if overused)
- Adverbs: "incredibly", "extremely", "absolutely", "literally", "actually"
- Em dashes used more than twice per paragraph
- Exclamation marks more than one per section
- Rhetorical questions used as paragraph openers more than once

---

## Procedure

### Step 1 -- Scan for Patterns

Read the input text line by line. Flag each match:

```
LINE 3: "In today's fast-paced world" — Category 1 (filler phrase, kill)
LINE 7: "leverage" — Category 2 (buzzword, replace with "use")
LINE 12: paragraph starts with "Furthermore" — Category 3 (transition opener)
```

### Step 2 -- Check Brand Voice (if brand specified)

Load `~/.openclaw/brands/{brand}/DNA.json` and compare:
- Does the tone match? (casual brand using formal language = flag)
- Does the vocabulary fit? (wellness brand using tech jargon = flag)
- Does the structure match brand style? (short-form brand with long paragraphs = flag)

### Step 3 -- Score and Report

```
HUMANIZER REPORT
Total issues found: 7
  Category 1 (filler phrases):    2
  Category 2 (corporate speak):   3
  Category 3 (structural slop):   1
  Category 4 (excessive patterns): 1
Brand voice alignment: 6/10 (if brand specified)
```

### Step 4 -- Rewrite Flagged Sections

For each flagged line, rewrite to sound natural:
- Remove filler phrases entirely (the sentence is stronger without them)
- Replace buzzwords with plain language equivalents
- Restructure listicles into prose where appropriate
- Vary paragraph openings — kill the transition word habit
- Cut adverb clutter — if the verb is strong, the adverb is dead weight

### Step 5 -- Return Results

Output three sections:
1. **Flagged issues** — line-by-line report of what was caught
2. **Rewritten version** — the full cleaned text
3. **Diff summary** — what changed and why

---

## Rules

- This gate runs BEFORE `brand-voice-check.sh`, not after
- Never add slop while removing slop — rewritten text must pass its own scan
- If the original text has zero flags, say so and pass it through unchanged
- Brand voice check is optional — only runs if `--brand` is specified
- Do not over-correct: some "AI patterns" are just good writing. Flag only clear slop
- Preserve the author's intent and meaning — only change HOW it's said, not WHAT
- When in doubt, shorter is better. Cut before you add.
