---
name: townhall-core
description: Interpretation + coordination helpers for GAIA Townhall (CORP-OS). Provides: townhall.digest, townhall.where-to-file, townhall.state-of-business.
metadata:
  openclaw:
    scope: interpretation-only
    guardrails:
      - Recommend only; do not execute changes, send messages, or modify external systems.
      - Do not create/edit CORP-OS artifacts unless explicitly asked; this skill outputs guidance/templates only.
---

# Townhall Core (GAIA)

This skill package defines three lightweight “functions” the assistant can perform during Townhall.

**Operating mode:** interpretation + coordination only.
- You may *summarize, classify, map to loops, propose next actions, and suggest filing locations*.
- You may *not* execute interventions (no launching/pausing campaigns, no changing pricing, no sending customer comms, no operational changes).

Canonical CORP-OS loops:
- **Health** (always-on drift/anomaly containment)
- **Priority** (re-rank focus based on impact/urgency/capacity)
- **Execution** (unblock throughput; reduce WIP; tighten SOP)
- **Strategy** (slow, signal-based narrative/pivot)

Canonical governance:
- **Severity:** S1 (critical), S2 (material), S3 (minor), none
- **Decision ownership:** AI-led vs Human-verified vs Human-owned
- **Autonomy levels:** L0 Observe, L1 Recommend, L2 Execute w/ guardrails, L3 Execute + learn

Artifacts/folders (logical):
- `signals/` `incidents/` `playbooks/` `learning-log/` `ideas/`

---

## Skill 1 — townhall.digest

**Input:** freeform idea / update / signal

**Output format (strict):**
1) **Classify:** one of `idea | signal | decision | risk`
2) **Map to Loop:** one of `Health | Priority | Execution | Strategy`
3) **Digest:** max 5 bullets
4) **Recommended next action (recommend-only):** 1–3 options, include:
   - who (role/DRI)
   - what
   - expected metric/impact
   - whether it likely needs human verification

**Classification rules (default):**
- **signal:** contains measurable change, anomaly, drift, threshold crossing, “what changed”
- **risk:** forward-looking downside, constraint breach, uncertainty with potential impact
- **decision:** explicit choice made/needed; tradeoffs; approval gate implied
- **idea:** proposal, suggestion, concept without evidence yet

**Loop mapping heuristics:**
- Health: metric drift, refunds/chargebacks, conversion drops, ops issues
- Priority: resource reallocation, stack reordering, “what should we do next”
- Execution: blockers, handoffs, cycle time, SOP gaps, unclear ownership
- Strategy: persistent trends, positioning, major channel shifts, long-horizon bets

**Template:**
- Classify: …
- Loop: …
- Digest:
  - …
  - …
  - …
- Next action (recommend-only):
  1) … (Owner: … | Verification: yes/no)
  2) …

---

## Skill 2 — townhall.where-to-file

**Input:** message or document

**Output:**
- **Folder:** `signals | incidents | playbooks | learning-log | ideas`
- **Filename suggestion:** kebab-case, include date if applicable
- **Action:** `NEW` or `UPDATE`
- **If UPDATE:** name the likely target object to update (best guess)

**Filing rules:**
- If it’s an observed/measured change with thresholds → `signals/` (or `incidents/` if severity S1–S3 is implied)
- If it’s a response plan / intervention steps → `playbooks/`
- If it’s a resolved incident lesson / what worked → `learning-log/`
- If it’s a concept not yet tied to evidence → `ideas/`

**Filename conventions:**
- Signals: `sig-<metric>-<scope>-v1.md`
- Incidents: `inc-YYYY-MM-DD-<short-title>.md`
- Playbooks: `pbk-<condition>-v1.md`
- Learning log: `lrng-YYYY-MM-DD-<tag>.md`
- Ideas: `idea-YYYY-MM-DD-<topic>.md`

---

## Skill 3 — townhall.state-of-business

**Trigger:** manual (`/sob`) or when something materially changes.

**Output format (strict):**
1) **What changed:** 1–5 bullets (facts only)
2) **Severity:** `S1 | S2 | S3 | none` (+ confidence: high/med/low)
3) **Needs human attention:** list items requiring a human decision/approval gate
4) **Safe to ignore:** noise, low-confidence drift, or items already contained

**Material change definition (default):**
- Any S1/S2 Health event
- Sustained drift (>=3 days) on a core driver
- Refund/chargeback risk uptick
- Any guardrail breach (cash/margin/compliance/reputation)

**Tone:** concise, decision-oriented, no “meeting language.”

---

---

## Skill 4 — townhall.verify-completion

**Input:** A task completion message from any agent (includes task description + claimed proof)

**Output format (strict):**
1) **Task type:** one of `code | api | content | scraping | deployment | analytics`
2) **Proof check:** for each required proof element (per `verify-task` skill), mark:
   - `PRESENT` — proof provided and specific
   - `MISSING` — required proof not provided
   - `VAGUE` — proof provided but not specific enough (e.g., "it works" without output)
3) **Data source check:** Are numbers backed by real sources (Google Sheets, Klaviyo, live scrape)?
   - `REAL` — source cited and verifiable
   - `UNCITED` — number stated without source
   - `SEED` — appears to be hardcoded/fabricated data
4) **Verdict:** `VERIFIED` | `INSUFFICIENT` | `REJECTED`
5) **If not verified:** specific list of what is missing or needs to be re-done
6) **Action:**
   - If `VERIFIED` → post confirmation to the room, log learning to feedback room
   - If `INSUFFICIENT` → re-open task with specific feedback, post to feedback room
   - If `REJECTED` → re-open task, escalate to Zenni, post failure to feedback room

**Verification rules:**
- "Done" without proof → always `REJECTED`
- Proof that says "it works" without output/data → `INSUFFICIENT`
- Numbers without data source citation → `INSUFFICIENT`
- Successful test output with exit code → `VERIFIED` (for code tasks)
- HTTP 200 response body → `VERIFIED` (for API tasks)

**Integration:**
- Every verification result is logged to `~/.openclaw/workspace/rooms/feedback.jsonl`
- Failed verifications create a learning-log entry at `~/.openclaw/workspace/corp-os/learning-log/`
- Patterns of verification failures feed into the nightly review

---

## Guardrails reminder
- Recommend only (for skills 1-3). Skill 4 (verify-completion) may post verification results to rooms and feedback log.
- If the user asks for execution, respond with: what you recommend + which approval gate would apply + what info is needed to proceed.
