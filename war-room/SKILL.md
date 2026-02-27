---
name: war-room
version: "1.0.0"
description: Multi-agent idea analysis. Paste ideas or links → all Pantheon agents analyze concurrently from their domain perspective.
metadata:
  openclaw:
    scope: analysis
    guardrails:
      - All agent analyses posted to exec room
      - War room is for ideas/links/brainstorms, not routine tasks
      - Maximum 1 war room session per 15 minutes (cooldown)
---

# War Room — Multi-Agent Idea Analysis

## Purpose

When Jenn (or any source) shares an **idea, link, product, trend, or brainstorm**, the War Room dispatches ALL 5 Pantheon agents to analyze it concurrently from their domain perspective. Results are synthesized in the exec room.

---

## When to Trigger War Room

Zenni MUST trigger a War Room session when she detects ANY of these patterns in incoming messages:

### Pattern 1: Links / URLs
- User shares a URL (http/https link)
- User says "check this out", "look at this", "what do you think of this" + link
- Shared links to products, articles, competitors, trends

### Pattern 2: Ideas / Brainstorms
- User says "what if we...", "how about...", "I was thinking...", "idea:", "what do you think about..."
- User describes a new product concept, marketing approach, or business idea
- User mentions a competitor strategy they want to evaluate

### Pattern 3: Trends / Signals
- User shares a TikTok trend, Instagram post, or viral content
- User mentions something they saw that could be relevant to GAIA
- User forwards content from other sources (news, social media)

### Pattern 4: Explicit Trigger
- User says "war room", "analyze this", "let's discuss", "thoughts on this"

### NOT War Room (don't trigger)
- Routine questions ("what's our sales today?")
- Direct tasks ("make a poster for Valentine's Day")
- Status checks ("how are the agents doing?")
- System commands ("restart the gateway")

---

## How to Trigger

```bash
bash ~/.openclaw/skills/war-room/scripts/analyze.sh "THE IDEA OR LINK OR TEXT HERE"
```

Or pipe input:
```bash
echo "my idea here" | bash ~/.openclaw/skills/war-room/scripts/analyze.sh
```

---

## What Happens

1. Idea gets posted to exec room as a `war-room-brief`
2. All 5 agents are dispatched concurrently:
   - **Artemis** → Market & Competition angle
   - **Dreami** → Creative & Brand angle
   - **Athena** → Data & Strategy angle
   - **Hermes** → Commerce & Pricing angle
   - **Iris** → Social & Community angle
3. Each agent posts their analysis to exec room within 1-3 minutes
4. Zenni can then synthesize the analyses into a recommendation

---

## Synthesis

After all agents respond (or after 3 minutes), Zenni should:
1. Read the exec room for war-room analyses
2. Summarize: what's the consensus? where do agents disagree?
3. Give Jenn a clear recommendation: GO / NO-GO / NEEDS MORE DATA
4. Identify the top 2-3 action items if GO

---

## Cooldown

To prevent spam:
- Minimum 15 minutes between War Room sessions
- Check `~/.openclaw/logs/war-room.log` for last run timestamp
- If cooldown active, tell Jenn and queue the idea for next session
