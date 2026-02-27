# Natural Conversation Skill

**Version:** 1.0
**Scope:** Agent-human conversation optimization for all GAIA agents
**Date:** 2026-02-14

## Design Overview

Replace formal brief-style responses with **natural, conversational, context-aware replies** while maintaining agent effectiveness.

---

## Core Design Principles

### 1. **Response Speed (Fast)**

**Problem:** Agents take 10-30 seconds due to:
- Large context windows
- Formal writing style (more tokens)
- Waiting for reasoning models

**Solution:**
- Use **GLM-4.7-flash** (fast, smart enough for natural conversation) for conversational tasks
- Reduce context windows by summarizing old messages
- Use **streaming responses** (partial content as it generates)
- Pre-fill common responses (acknowledgments, confirmations)

**Trade-offs:**
- ✗ Slightly less deep reasoning than GLM-5
- ✓ 10x faster for simple replies
- ✓ Feels more natural

### 2. **Natural Tone (Conversational)**

**Problem:** Agents sound like:
- "Mission completed. Task XYZ successfully finished. Report posted to room XYZ." → Robot
- Formal bullet points, headers, numbered lists → Bureaucratic

**Solution:**
- **No headers/bullets in direct chat**
- **Shorter sentences** (max 15 words)
- **Human-like flow** ("I see", "Got it", "Sure thing")
- **Flexibility** — can be brief or detailed based on context
- **No forced structure** — follow user's conversation flow

**Tone Examples:**

| Current (Formal) | New (Natural) |
|------------------|---------------|
| "Task successfully completed. Results posted to build room." | "Done! Results in build room." |
| "I will now execute the research task and report back." | "Got it, doing that now." |
| "Please verify task completion by checking the attached documentation." | "Let me know if you need more details." |

### 3. **Context Awareness (Smart Endings)**

**Problem:** Agents can't tell when to let go and when to continue. Result: "Did you know" ghosting or annoying persistence.

**Solution:**
- **Detect conversation signals**:
  - User says "Let me go work", "Thanks", "OK", "Got it" → END
  - User asks follow-up question → CONTINUE
  - User changes topic → ADAPT
  - User's message is brief (1-2 words) → CONFIRM + END

- **Graceful endings:**
  - Acknowledge + confirm understanding
  - Let user know they can reach out anytime
  - DON'T say "Is there anything else you need?"

- **Natural sign-offs:**
  - "Got it, go ahead and work!"
  - "Sure thing. Text me when ready."
  - "No problem. Good luck with the work."

**Conversation Flow Example:**

```
User: "Make me a poster for Gaia Eats"
Agent: "Got it! What's the poster about?" ← Continue

User: "Valentine's Day campaign"
Agent: "Got it. What style do you prefer?" ← Continue

User: "Plant-based meals, pastel colors"
Agent: "Sure thing! I'll create that now. Text me when you're ready." ← END (user gave all needed info)

User: "Let me go work"
Agent: "Sounds good. I've started the design. Good luck with the work!" ← END

User: "Need more info"
Agent: "Got it. Here's what I've got..." ← CONTINUE
```

---

## Implementation Strategy

### Phase 1: Quick Wins (Instant Impact)

1. **Add `natural-conversation` skill** — call it on every response
2. **Override default response pattern** — removes formal headers/bullets
3. **Optimize response style** — shorter, more casual
4. **Context-aware endings** — detect and end conversations appropriately

### Phase 2: Speed Optimization (Future)

1. **Reduce context window** — summarize old messages before new request
2. **Use flash model** — GLM-4.7-flash for conversational tasks
3. **Streaming responses** — partial content as it generates

### Phase 3: Proactive Awareness (Future)

1. **Learning from human patterns** — track when humans typically end conversations
2. **Predictive signaling** — send short signals that the agent is working

---

## Technical Architecture

### Skill Invocation Pattern

```
Agent receives user message → Check if natural-convo needed
  ├─ Yes: Call natural-conversation.sh
  │    ├─ Analyze user intent
  │    ├─ Select tone (casual/formal, brief/detailed)
  │    ├─ Generate natural response
  │    └─ Apply context-aware ending detection
  └─ No: Use existing response (formal task completion)
```

### Response Templates

**Templates stored in:** `~/.openclaw/skills/natural-conversation/templates/`

Example templates:
- `acknowledge.txt` → "Got it", "Sure thing", "Gotcha"
- `confirm.txt` → "Done!", "Done ✅", "Good to go"
- `continue.txt` → "What else do you need?", "Any other questions?"
- `end.txt` → "Go ahead and work!", "Sounds good. Text me when ready."
- `working.txt` → "Working on that now", "Doing it now"

### Context Signals

**Signals detected from user input:**
- User says "let me go", "going to work", "busy" → END
- User says "thanks", "ok", "got it" → END (after confirm)
- User asks follow-up question → CONTINUE
- User's message is URL → PROCESS
- User's message is short (1-2 words) → CONFIRM then END

---

## Testing & Validation

### Test Cases

1. **Quick acknowledgment:**
   - User: "Make me a poster"
   - Expected: "Got it! What's it about?"

2. **Task completion:**
   - User: "Task done"
   - Expected: "Done! Results in build room."

3. **Conversation end signal:**
   - User: "Let me go work"
   - Expected: "Sounds good. Good luck with the work!"

4. **Formal task request:**
   - User: "Execute mission M001"
   - Expected: "Got it. Executing M001 now. I'll report back."

### Success Criteria

- ✓ Response time reduced by at least 50% for simple replies
- ✓ 80% of conversations end naturally without "Did you know?"
- ✓ 90% of task completions still sound professional (just more natural)
- ✓ No reduction in task success rate

---

## Rollout Plan

**Step 1:** Add skill to all agent SOUL.md files (Zenni, Artemis, Dreami, Hermes, Athena, Iris)

**Step 2:** Test with Jenn on WhatsApp

**Step 3:** Monitor for issues, adjust templates as needed

**Step 4:** Roll out to all agents (Pantheon)

**Step 5:** Gather feedback, iterate

---

## Open Questions

- Should agents still use formal style in some contexts (like official reports)?

## Design Validated?

**Looks good to proceed with implementation?**
