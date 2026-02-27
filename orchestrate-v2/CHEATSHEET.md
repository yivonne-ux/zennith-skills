# Orchestrate v2 — Zenni's Cheatsheet

> Print this. Paste it at the top of every session context if needed.

---

## ONE-LINER DECISION

```
Task = simple/lookup/git/file?  →  MYRMIDONS
Task = code/build?              →  TAOZ
Task = research/web?            →  ARTEMIS
Task = copy/creative?           →  DREAMI
Task = visual/social/image?     →  IRIS
Task = strategy/analysis?       →  ATHENA
Task = ads/pricing/revenue?     →  HERMES
Unsure?                         →  run classify.sh
```

---

## HARD RULES (never break these)

| Rule | What happens if you break it |
|------|------------------------------|
| >3 tool calls = DELEGATE | Zenni burns expensive tokens on cheap work |
| Simple task = Myrmidons | Zenni costs 100-500x more than needed |
| Zenni never does specialist work | Domain quality suffers, specialists idle |
| Every dispatch = logged | Blind spots, dropped balls, no compounding |

---

## COMMANDS

```bash
# Classify a task → which agent
bash ~/.openclaw/skills/orchestrate-v2/scripts/classify.sh "your task"

# Dispatch to agent
bash ~/.openclaw/skills/orchestrate-v2/scripts/dispatch.sh \
  "<agent>" "<task>" "<label>" [thinking] [timeout]

# Track active tasks  
bash ~/.openclaw/skills/orchestrate-v2/scripts/track.sh list

# Mark task done
bash ~/.openclaw/skills/orchestrate-v2/scripts/track.sh done "<label>" success "result"

# Agent stats
bash ~/.openclaw/skills/orchestrate-v2/scripts/track.sh stats
```

---

## AGENT MODELS & COST

| Agent | Model | $/M in | $/M out |
|-------|-------|--------|---------|
| Myrmidons | minimax-m2.5 | $0.14 | $0.14 |
| Artemis | kimi-k2.5 | FREE | FREE |
| Dreami | kimi-k2.5 | FREE | FREE |
| Iris | qwen3-vl-235b | ~$0.40 | ~$1.60 |
| Taoz | glm-4.7-flash | $0.06 | $0.40 |
| Athena | glm-5 | $0.80 | $2.56 |
| Hermes | glm-5 | $0.80 | $2.56 |
| Zenni | glm-4.7-flash | $0.06 | $0.40 |

**Zenni is now on glm-4.7-flash (v4). Routing is dirt cheap.**

---

## DISPATCH LOOP

```
1. classify.sh "task"          → who
2. dispatch.sh agent task label → spawn
3. [wait for auto-announce]    → subagent reports back
4. verify result               → meets criteria?
5. track.sh done label success → log outcome
6. report to Jenn              → done
```
