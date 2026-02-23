# Agent Vitality — Amoeba Self-Evolution System

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
- Classifies relevance: visual → artee, copy → apollo, strategy → athena, etc.
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
- `:00` — Artemis (scout — learns from research)
- `:25` — Athena (analyst — learns from data)
- `:50` — Dreami (creative director — learns from reviews)
- `+1h :15` — Apollo (copywriter — learns from content)
- `+1h :40` — Artee (art director — learns from visuals)
- `+2h :05` — Iris (social — learns from engagement)
- `+2h :30` — Hermes (commerce — learns from sales)

Cross-pollination runs once daily at 11pm MYT.
