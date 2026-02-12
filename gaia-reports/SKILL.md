---
name: gaia-reports
description: Smooth workflow for Gaia daily/4-hour sales reporting using Google Sheets + NotebookLM, with templates and a repeatable runbook.
---

# gaia-reports

This skill standardizes Jenn’s reporting workflow:
- pull daily sales from 1+ Google Sheets
- summarize/translate key notes from NotebookLM
- produce a concise report format for WhatsApp groups

## Inputs you provide once
- Google Sheet URLs (sales sources)
- Target WhatsApp group(s) for posting
- Date convention (e.g., DD/MM/YYYY vs YYYY-MM-DD)
- KPI definitions (what counts as “sales”: paid? delivered? nett?)

## Requirements (Google)
To read Sheets automatically, OpenClaw needs a working Google OAuth token.
- You log in once via the OpenClaw browser flow.
- The OAuth app must allow your Google account (Test Users if app is in testing).

## Workflow

### A) One-time setup checklist
1) Confirm which sheets are the sources of truth (IDs + tabs).
2) Fix Google OAuth access (add account to Test Users / or use the correct Google account).
3) Confirm posting cadence (every 4 hours) + where to post.

### B) Daily run (manual or scheduled)
1) Pull sales for date D (sum + breakdown).
2) Create short “what changed” bullets.
3) Post to the selected group.

## Report format (default)
- Date
- Total sales (RM)
- #orders (if available)
- Top channel/campaign notes (optional)
- Ops notes / risks
- Next action (1–3 bullets)

## NotebookLM usage prompts
- "Summarize the key updates relevant to today’s sales and operations in 8 bullets."
- "Extract customer objections + best replies as short WhatsApp-ready lines."

## Notes
- Pinterest automation is best-effort; Google Sheets is reliable once OAuth is fixed.
- Always ask Jenn before posting to external parties; posting to agreed internal groups is ok once configured.
