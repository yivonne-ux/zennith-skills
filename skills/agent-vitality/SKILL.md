---
name: agent-vitality
agents:
  - taoz
  - main
---

# Agent Vitality — Hive Self-Evolution System

_Each agent is a living cell. It reflects, learns, evolves, and synchronizes with the organism._

## Purpose

Makes every GAIA agent a self-improving organism:
- **Membrane** (SOUL.md) — identity that evolves with experience
- **Nucleus** (RAG memory) — accumulated knowledge and learnings
- **Metabolism** (pulse cycle) — periodic self-improvement
- **Cell division** (cross-pollination) — learnings spread to the team

## Scripts

### `pulse.sh` — Agent Self-Improvement Pulse
Individual agent heartbeat. Runs every 3 hours per agent (staggered).

```bash
bash pulse.sh <agent_name>
```

4-step cycle:
1. **REFLECT** — Read my recent work (room entries, dispatch results)
2. **LEARN** — Extract learnings → store in RAG memory
3. **EVOLVE** — Update my SOUL.md "Living Learnings" section
4. **SYNC** — Read team's recent learnings → adopt if relevant

### `evolve.sh` — SOUL Evolution Engine
Updates an agent's SOUL.md with new learnings.

```bash
bash evolve.sh <agent_name>
```

- Reads agent's recent RAG memory entries (type: learning)
- Appends new insights to SOUL.md "Living Learnings" section
- Caps learnings at 20 (oldest get archived to RAG memory)
- Never modifies core identity sections

### `cross-pollinate.sh` — Team Learning Spread
Spreads relevant learnings across the team.

```bash
bash cross-pollinate.sh
```

- Reads all agents' recent learnings from RAG memory
- Classifies relevance: visual → dreami, copy → dreami, strategy → main, research → scout, etc.
- Posts relevant cross-team learnings to the appropriate room
- Prevents duplicate notifications

## Architecture

```
Single Cell (Agent):
┌─────────────────────────┐
│  SOUL.md (membrane)     │ ← evolves with experience
│  ┌───────────────────┐  │
│  │ RAG Memory        │  │ ← accumulated knowledge
│  │ (learnings,       │  │
│  │  decisions,       │  │
│  │  insights)        │  │
│  └───────────────────┘  │
│  Pulse: REFLECT →       │ ← metabolism
│    LEARN → EVOLVE →     │
│    SYNC                 │
└─────────┬───────────────┘
          │ cross-pollinate
          ▼
┌─────────────────────────┐
│  ORGANISM (Team)        │
│  Shared rooms, seed     │
│  bank, winning patterns │
│  Vision alignment       │
└─────────────────────────┘
```

## Schedule

Agents pulse every 3 hours, staggered by 25 minutes:
- `:00` — Scout (research/ops — learns from research)
- `:25` — Zenni/main (strategy — learns from data)
- `:50` — Dreami (creative director — learns from reviews)
- `+1h :15` — Dreami (creative + marketing — learns from content and visuals)
- `+1h :40` — Taoz (CTO — learns from builds)
- `+2h :05` — Scout (ops — learns from monitoring)
- `+2h :30` — Dreami (commerce — learns from sales)

Cross-pollination runs once daily at 11pm MYT.
