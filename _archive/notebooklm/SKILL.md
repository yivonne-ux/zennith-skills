---
name: notebooklm
description: Use Google NotebookLM via browser (summaries, study guides, Q&A, content extraction) and turn outputs into actionable checklists and briefs.
---

# notebooklm

This skill guides using **Google NotebookLM** through OpenClaw's browser automation.

## When to use
- User shares a NotebookLM link (notebooklm.google.com)
- Need: summarize sources, extract key points, draft scripts/briefs, build Q&A, create checklists, produce structured notes.

## Requirements
- Access to the NotebookLM notebook (user must share link with permission).
- A logged-in Google session in the browser.

## Browser profile rules
- If the user mentions Chrome extension / Browser Relay / “attach tab”: use `browser` tool with `profile="chrome"` (requires user to attach the tab).
- Otherwise default to `profile="openclaw"` and sign in if needed.

## Workflow (recommended)
1) Open the shared NotebookLM link.
2) Confirm the notebook loads and sources are visible.
3) Ask for the goal (or infer from context):
   - Summary (short / detailed)
   - Action checklist
   - Script / copywriting
   - FAQ / objections handling
   - Meeting brief / decision memo
4) Use NotebookLM chat prompts (copy/paste):

### Prompts
**A) Executive summary**
"Give me a 10-bullet executive summary of the sources. Group by themes. Include any numbers/dates."

**B) Action checklist**
"Turn the sources into an actionable checklist for {goal}. Output: (1) steps, (2) owners, (3) deadlines placeholders, (4) risks." 

**C) Copywriting / scripts**
"Write 3 hook variations (discount vs concierge). Keep Malaysian Chinese tone, natural, not robotic."

**D) FAQ**
"List top 15 customer objections and suggested replies, grounded in the sources."

**E) Extract quotes**
"Pull exact quotes + where they appear (source name/page)."

## Output formatting
- Always return: TL;DR + structured bullets + next actions.
- If the user wants to save to Notion/Drive, ask where and under what naming convention.

## Safety / privacy
- Don’t paste sensitive data into public docs.
- Only use notebooks the user has shared.
