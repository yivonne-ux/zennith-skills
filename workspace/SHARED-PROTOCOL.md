# Zennith OS — Shared Agent Protocol (v5)
> All agents MUST read this on boot. Identity goes in SOUL.md. Everything else goes here.
> Last updated: 2026-03-01 (v5 rebuild — OpenClaw-forward)

## 1. Task Dispatch
- All tasks flow through **Zenni (main)** who classifies via `classify.sh` and dispatches.
- Agents may spawn sub-tasks within their own domain. Cross-domain work goes back to Zenni.
- Simple/bulk tasks route to **Myrmidons** (cheapest capable model wins).
- Dispatch command: `openclaw agent --agent X --message "BRIEF"` or `bash dispatch.sh <from> <to> <type> "<msg>" <room>`

### Agent Roster (9 agents — read from openclaw.json, never hardcode)
| Agent | Role | When to dispatch |
|-------|------|-----------------|
| **Zenni** (main) | CEO/Orchestrator | Thinks, plans, delegates, verifies, audits, reports. Owns outcomes. |
| **Taoz** | CTO/Builder | Code, skills, infrastructure, deploys (>10 lines) |
| **Myrmidons** | Worker Swarm | File ops, git, health checks, config, <3 tool calls |
| **Artemis** | Scout/Researcher | Web research, trends, competitor intel, scraping |
| **Dreami** | Creative Director | Campaign briefs, copywriting, brand voice, reviews |
| **Hermes** | Merchant | Ads, pricing, margins, channel strategy, revenue |
| **Athena** | Strategist/Analyst | Data analysis, performance, forecasting, ROI |
| **Iris** | Art Director | Visual generation, design, social media, CRO/UX |
| **Argus** | QA/Regression | Testing, regression, smoke tests, quality reports |

## 2. Room Communication
| Room | Purpose | Who writes |
|------|---------|------------|
| `exec` | Leadership decisions, approvals | Zenni, Athena |
| `build` | Technical tasks, deploys, bugs | Taoz, Myrmidons |
| `creative` | Content briefs, copy, visuals | Dreami, Iris |
| `analytics` | Data reports, pattern insights | Athena, Artemis |
| `execution` | Active task status, checkpoints | Any agent with active tasks |
| `feedback` | Health alerts, QA results | Argus |
| `social` | Social media posts, scheduling | Iris, Dreami |
| `townhall` | Cross-team digests, announcements | Any agent |

**Rule:** Post to the narrowest relevant room. Never spam townhall with routine updates.

## 3. Memory Protocol — Making OpenClaw Remember FOREVER

OpenClaw's biggest gap is memory. Sessions are isolated, context is lost. We fix this by AGGRESSIVELY using OpenClaw's native memory system on every single task.

### CRITICAL: There is NO `memory_store` tool

OpenClaw only has TWO memory tools — both READ-ONLY:
- **`memory_search("query")`** — semantic search across all vectorized memory
- **`memory_get(path, from, lines)`** — read a specific memory file

To WRITE memory, agents use the `write` tool to save to `memory/*.md` files in their workspace. OpenClaw's native vectorizer automatically indexes these files every ~2h.

### Rule: EVERY Agent MUST Search Before Working, Write After Working

**Before any task:**
```
memory_search("keywords relevant to this task")
```
Check what you already know. Don't re-discover. Don't re-research.

**After any significant task (>2 tool calls):**
Write to `memory/YYYY-MM-DD.md` in your workspace:
```markdown
## [HH:MM] Task Name
- What happened: brief outcome
- What I learned: key insight
- Tags: learning, error, win, pattern, brand:{name}
```

**What to write (ALWAYS):**
- Task outcomes: what worked, what failed, why
- Brand-specific learnings: "Pinxin posts perform 3x on Wed mornings"
- Agent coordination patterns: "Dreami needs reference images from Iris first"
- Error root causes: "glm-5 times out on >50 room entries"
- Human corrections: Jenn's feedback = high priority

### 3 Memory Layers (all OpenClaw-native)

| Layer | System | Lifetime | Who Manages |
|-------|--------|----------|-------------|
| **Hot** | SOUL.md Living Learnings | Permanent (top 20 kept) | `evolve.sh` via pulse |
| **Warm** | RAG SQLite (`memory/{agent}.sqlite`) | Auto-vectorized from memory/*.md | `memory_search` to read, `write` tool to save |
| **Cold** | Room JSONL archives | Forever | Vectorization cron (every 2h) |

### Cross-Pollination (nightly)
- Nightly review reads ALL rooms → extracts patterns → writes to shared memory
- Vectorization cron (every 2h) embeds new memory files + room entries → searchable by all agents
- Pattern detection (02:00 daily) finds recurring themes → flags for skill promotion

### The Memory Rule
**If you learned something, WRITE IT TO `memory/YYYY-MM-DD.md`. If you need something, `memory_search` FIRST.**
An agent that doesn't use memory is a stateless function, not a living cell.

## 3b. Compound Learnings — The Knowledge Stack

**Every agent generating content MUST read compound learnings first.**

Learnings are layered in 3 tiers. Top layers are universal, bottom layers are specific:

| Layer | Path | Applies To | Example |
|-------|------|-----------|---------|
| **Global** | `workspace/data/learnings/global/*.json` | ALL brands | Camera rules, model strengths, zoom = AI tell |
| **Category** | `workspace/data/learnings/category/*.json` | Brands in that category | Food physics, utensil rules, steam behavior |
| **Brand** | `workspace/data/learnings/brand/{brand}.json` | ONE brand only | Mirra bento style, salmon pink palette |

**Before generating content:**
```bash
# Get merged learnings for your brand:
python3 workspace/data/learnings/resolve-learnings.py --brand mirra --format flat
```

**After reviewing/learning something:**
- Write to the BROADEST applicable layer
- Food physics broken in mirra video? → `category/food-video.json` (helps ALL food brands)
- Sora always zooms in? → `global/video-generation.json` (helps ALL brands)
- Mirra bento lid timing off? → `brand/mirra.json` (mirra only)

**Full map:** Read `workspace/data/learnings/LEARNINGS-MAP.md`

### vault.db — The Unified Knowledge Store
All agents can search system-wide knowledge stored in `workspace/vault/vault.db` (2,700+ rows, FTS5 indexed).

**Before starting work, search for existing knowledge:**
```bash
# FTS5 full-text search (fast):
python3 -c "
import sqlite3
db = sqlite3.connect('workspace/vault/vault.db')
rows = db.execute(\"SELECT source_type, text FROM vault_fts WHERE vault_fts MATCH 'KEYWORD' LIMIT 10\").fetchall()
for t, txt in rows: print(f'[{t}] {txt[:150]}')
"
```

**After completing significant work, write learnings to vault.db:**
```bash
bash skills/knowledge-compound/scripts/digest.sh
```

Source types in vault.db: `memory`, `seeds`, `image-seeds`, `biz-opportunity`, `biz-validation`, `biz-pattern`, `patterns`, `knowledge`, `brand-dna`, `shared-facts`, `room-exec`, `room-feedback`.

## 4. File Storage
- **Read `workspace/FILE-MAP.md`** to know where ALL files live.
- **Path resolver:** `bash workspace/scripts/path-resolver.sh --type <type> [--brand <brand>]`
- Brand DNA: `brands/{brand}/DNA.json`
- Brand output: `brands/{brand}/output/`
- Characters: `workspace/data/characters/{agent}/`
- Images: `workspace/data/images/{brand}/`
- Videos: `workspace/data/videos/pipelines/` or `standalone/`
- Rooms: `workspace/rooms/{name}.jsonl`
- **NEVER** write to `/tmp`, `~/Desktop`, or random locations.

## 5. Brand Context
- **Always load Brand DNA** before brand-specific work: `brands/{brand}/DNA.json`
- **Always load Compound Learnings** before generating video/image: `python3 workspace/data/learnings/resolve-learnings.py --brand <brand> --format flat`
- Brands: pinxin-vegan, wholey-wonder, mirra, rasaya, gaia-eats, dr-stan, serein
- Run `brand-voice-check.sh` on all brand content before publishing.

### Video/Image Generation Checklist (MANDATORY)
1. Read Brand DNA → understand brand voice, colors, mood
2. Read Compound Learnings (`--format flat`) → know what to AVOID and what WORKS
3. Write prompt following learnings (no steam for bento, no zoom, etc.)
4. Generate via video-gen.sh (Kling v3 for food close-ups, Sora 2 for UGC/people)
5. After review: write feedback to correct learnings layer (global/category/brand)

## 6. Tools & Skills Catalog

All skills live at `~/.openclaw/skills/*/SKILL.md`. Read a skill's SKILL.md before using it.
After building a new skill: run `bash workspace/scripts/post-build-sync.sh` to sync both systems.

### Image & Creative
| Skill | CLI | Owner | Purpose |
|-------|-----|-------|---------|
| `ad-composer` | `ad-image-gen.sh` | Iris | Multi-model image gen (NanoBanana, Recraft, Flux) |
| `nanobanana` | `nanobanana-gen.sh` | Iris | Gemini Image API, style-seed, ref-image |
| `image-seed-bank` | `image-seed.sh` | Iris | Store/query image assets |
| `ref-library` | `ref-library.sh` | Iris, Hermes | Reference image management |
| `character-design` | — | Iris | Character sheet generation |
| `image-optimizer` | — | Iris | Upscale/compress images |

### Video
| Skill | CLI | Owner | Purpose |
|-------|-----|-------|---------|
| `video-gen` | `video-gen.sh` | Iris | Generate video (Kling/Wan/Sora) |
| `video-forge` | `video-forge.sh` | Iris | Post-prod: caption, brand, effects, export |
| `video-eye` | `video-eye.sh` | Iris | Creative DNA extraction, virality analysis |
| `video-factory` | — | Iris | Orchestrate image→video→post-prod chain |
| `clip-factory` (ClipForge) | `clip-factory.sh` | Iris | Long video → ranked short viral clips |
| `remotion` | `render.sh` | Dreami | Programmatic video compositions |

### Ads & Revenue
| Skill | CLI | Owner | Purpose |
|-------|-----|-------|---------|
| `campaign-planner` | `campaign-planner.sh` | Hermes | Generate campaign briefs from templates |
| `meta-ads-manager` | `meta_ads_api.py` | Hermes, Athena | Meta API: campaigns, creatives, fatigue |
| `meta-ads-library` | `scrape_meta_library.py` | Artemis | Scrape competitor ads (public, no auth) |
| `ad-performance` | `ingest-csv.sh` | Athena | Ingest ad performance CSVs |
| `growth-engine` | — | Athena | Statistical winner detection, creative duplication |

### Content & Copy
| Skill | CLI | Owner | Purpose |
|-------|-----|-------|---------|
| `content-seed-bank` | `seed-store.sh` | ALL agents | Store/query content atoms (hooks, copy, ideas) |
| `content-tuner` | `tune.sh` | Athena | A/B testing, strategy tuning |
| `mirra-content` | `produce.sh` | Dreami | Mirra Instagram content pipeline |
| `marketing-formulas` | — | Dreami | Copywriting & persuasion frameworks |

### Research & Web
| Skill | CLI | Owner | Purpose |
|-------|-----|-------|---------|
| `agent-reach` | — | Artemis, Hermes, Athena | Free web browsing via Jina Reader + yt-dlp |
| `web-search-pro` | — | Artemis | Multi-engine web search |
| `site-scraper` | — | Artemis | Local website crawler + extractor |
| `ig-reels-trends` | — | Artemis | Scrape IG trending content |
| `tiktok-trends` | — | Artemis | Scrape TikTok Creative Center trends |
| `youtube-intel` | — | Artemis | YouTube marketing intelligence |

### Social & Publishing
| Skill | CLI | Owner | Purpose |
|-------|-----|-------|---------|
| `social-publish` | `social-publish.sh` | Iris, Hermes | Post to IG/FB, schedule, queue |
| `wa-group-digest` | — | Zenni | Daily WhatsApp group summaries |

### Quality & Testing
| Skill | CLI | Owner | Purpose |
|-------|-----|-------|---------|
| `rigour` | `gate.sh` | Taoz, Argus | Code quality gate (mandatory before shipping) |
| `brand-voice-check` | `brand-voice-check.sh` | Argus | Brand content QA |
| `brand-onboard` | `brand-onboard.sh` | Argus | Brand setup validation |
| `test-framework` | — | Argus | Regression test infrastructure |
| `studio-regression` | — | Argus | Creative pipeline regression tests |

### System & Ops
| Skill | CLI | Owner | Purpose |
|-------|-----|-------|---------|
| `classify-evolve` | `classify-evolve.sh` | Taoz | Self-evolving routing classifier |
| `orchestrate-v2` | `classify.sh` | Zenni | 5-tier routing engine |
| `claude-code` | `claude-code-runner.sh` | Taoz | Spawn Claude Code CLI for builds |
| `knowledge-compound` | `digest.sh` | ALL | Compound learning digest |
| `auto-heal` | — | Myrmidons | Self-healing error recovery |
| `auto-failover` | — | Myrmidons | Model failover watchdog |
| `persona` | `persona-gen.sh` | Iris, Dreami | Character/avatar generation |
| `rag-anything` | `ingest.py`, `query.py` | Athena | Multimodal RAG pipeline |

### Sync (keeps Claude Code = OpenClaw)
| Script | Purpose |
|--------|---------|
| `post-build-sync.sh` | Run after EVERY build — syncs skills, CLAUDE.md, checks coverage |
| `sync-skills.sh` | Bidirectional skill symlinks (OpenClaw ↔ Claude Code) |
| `sync-claude-md.py` | Regenerate CLAUDE.md from openclaw.json |
| `sync-claude-code-learnings.sh` | Bridge Claude Code → OpenClaw knowledge |

## 7. Cost Efficiency
- **Cheapest capable model always wins.** Routine/bulk → Myrmidons (minimax-m2.5).
- Creative quality → best available creative model.
- Zenni orchestrates and decides — delegates specialist execution to domain experts but owns all strategic decisions and outcomes.
- Monitor costs via `check-model-health.py`.

---

## 8. Myrmidons Delegation (ALL agents follow this)

Any task that is NOT your core specialty → delegate to Myrmidons:
- File operations (read dir, move, copy, delete, create folders)
- Git operations (commit, push, status, branch)
- Health checks (ping URLs, check services, verify deploys)
- Config updates (env files, JSON, YAML)
- Formatting/converting (reformat data, list files)
- Simple lookups (check if X exists, what's in file Y)
- Posting to rooms (relay messages, write room entries)
- Any task needing <3 tool calls with no specialist judgment

**Rule:** If it doesn't require your specific expertise → Myrmidons does it.
**How:** `sessions_send(label="myrmidons", message="<clear task>")`

## 9. Taoz Dispatch Protocol (ALL agents follow this)

- **Taoz = Claude Code CLI** running on Jenn's iMac, NOT an OpenClaw session.
- **NEVER** use `sessions_send(label="taoz")` — that spawns a glm-4.7-flash chat, not the real builder.
- For code/build work: Post brief to build room → Zenni dispatches via `claude -p` CLI.
- Taoz tasks: >10 lines of code, new skills, bug fixes, infrastructure, deployments.
- NOT Taoz tasks: file moves, git ops, config edits, room posts → use Myrmidons.

## 10. End-of-Session Protocol (Compound Learning)

Before closing a session with significant work:
1. Write to `rooms/feedback.jsonl`:
   ```json
   {"ts":<epoch_ms>,"agent":"<your_id>","type":"learning|error|win","insight":"<what>","context":"<brief>"}
   ```
2. **Digest learnings** into the Knowledge Compound:
   ```bash
   bash /Users/jennwoeiloh/.openclaw/skills/knowledge-compound/scripts/digest.sh \
     --source "session/<your-id>/$(date +%Y-%m-%d)" \
     --type "session-learning" \
     --fact "What you learned" \
     --agent "<your-id>"
   ```
3. If a pattern worked 3+ times → track with `--pattern "pattern-name"` flag (auto-promotes at 3x validated, 5x implemented)
4. If you hit an error → document root cause + fix
5. **Search before acting** — check existing knowledge: `bash digest.sh search "topic"`

This feeds the nightly compound learning loop (`nightly.sh`).

> **Full docs:** `/Users/jennwoeiloh/.openclaw/skills/knowledge-compound/AGENT-INSTRUCTIONS.md`

## 11. Operational Discipline

- Before any multi-step task: write task + status to `workspace/active-tasks.md`
- After completion: update active-tasks.md with result
- After ANY significant task (>2 tool calls): run `task-complete.sh`
- Inputs go to `brands/{brand}/incoming/`, outputs to `brands/{brand}/output/`
- When you discover something, update your skills or memory

## 12. Boot Protocol (ALL agents)

Before ANY work:
1. Confirm your model matches `REGISTRY.json`
2. Check `workspace/log/{today}.jsonl` for open tasks assigned to you
3. Resume open tasks before accepting new ones
4. Read `workspace/FILE-MAP.md` for file path reference
5. Read this file (`SHARED-PROTOCOL.md`)

## 13. Quality Gate

- **Rigour Gate:** `bash skills/rigour/scripts/gate.sh <file>` — mandatory before shipping code.
- **Brand Voice Check:** `brand-voice-check.sh` — mandatory before shipping brand content.
- **Argus Regression:** After every Taoz build → Argus tests → only ship on PASS.
- Git commit after every skill or code change.

## 14. The Amoeba Principle (Self-Improvement)

Every agent is a living cell in the GAIA organism:
- After every task: **What did I learn? What would I do differently?**
- Store learnings: write to `memory/YYYY-MM-DD.md` in your workspace (auto-vectorized by OpenClaw)
- Read teammate learnings in rooms — their discoveries strengthen your work.
- The vitality pulse updates your Living Learnings section automatically.

## 15. Multi-Step Orchestration Protocol

When a task needs 2+ agents in sequence (Zenni coordinates):

### Decompose
Break task into ordered steps with clear dependencies:
```json
{"steps":[
  {"step":1,"agent":"artemis","brief":"...","depends_on":[]},
  {"step":2,"agent":"dreami","brief":"...","depends_on":[1]},
  {"step":3,"agent":"iris","brief":"...","depends_on":[2]}
]}
```

### Dispatch in order
`bash dispatch.sh <from> <to> request "<BRIEF>" <room>`
Wait for response before dispatching dependent steps.

### Verify each output
After each agent responds: Does output match brief? Quality sufficient for next step?
If not → re-dispatch with clearer brief or different agent.

### Synthesize
Combine all outputs into one coherent result. Post to exec room. Report to Jenn.

## 16. Task Scoring Framework

Every completed task gets scored (by Zenni or nightly review):

| Score | Meaning | Action |
|-------|---------|--------|
| 9-10 | Excellent — exceeded brief | Extract pattern → add to agent's learnings |
| 7-8 | Good — met brief | Log success |
| 5-6 | Acceptable — needs minor revision | Flag what's missing, feed back |
| 3-4 | Poor — wrong or incomplete | Root cause analysis → fix routing/brief/agent |
| 1-2 | Failed — didn't deliver | Escalate, retrain routing |

**Score dimensions:** Routing accuracy, brief quality, output completeness, speed, cost efficiency.

**Learning loop:**
```
Task → Dispatch → Agent delivers → Score
  ↓                                    ↓
  If < 7: root cause → fix           If >= 7: extract pattern → strengthen
  ↓                                    ↓
  System gets smarter ←←←←←←←←←←←← System gets smarter
```

## 17. Agent Categories & The 3-Loop Architecture

GAIA OS runs on OpenClaw's native cron system (`/Users/jennwoeiloh/.openclaw/cron/jobs.json`). All scheduling, heartbeat, and proactive behavior is wired through OpenClaw — no external crontab scripts.

### The 3 Loops (all OpenClaw cron-driven)

```
BIG LOOP (weekly)     — "Who am I becoming?"
  Owner: Athena       — Sun 22:00 weekly system review
  Scope: Agent scores, brand health, capability gaps, next-week priorities

MID LOOP (daily)      — "Am I getting better?"
  Night:  Zenni 22:30 nightly review (extract patterns from rooms)
  Night:  Myrmidons 02:00 pattern detection (find recurring patterns)
  Morning: Zenni 08:30 morning dispatch (ACT on nightly proposals)
  Day:    Athena 18:00 daily analysis (ingest data, post insights)
  Always: Athena every 4h system diagnostics (flag RED alerts)

SMALL LOOP (per-task) — "Did this work?"
  Owner: Every agent   — task-complete.sh + write to memory/YYYY-MM-DD.md after each task
```

### Proactive Agents (OpenClaw cron triggers them)

| Agent | Cron Trigger | What They Do |
|-------|-------------|--------------|
| **Athena** | Daily 18:00 + Sun 22:00 + every 4h | Analysis, strategy, system health |
| **Artemis** | Daily 08:00 + Mon 10:00 | Innovation scouting, product research |
| **Argus** | Post-build (event-driven) | Regression testing, quality gates |
| **Zenni** | Daily 08:30 + 22:30 | Morning dispatch + nightly review |

### Reactive Agents (dispatch-driven)

| Agent | Activated by |
|-------|-------------|
| **Taoz** | Build briefs from build room → Claude Code CLI |
| **Iris** | Dreami's creative briefs, visual requests |
| **Hermes** | Pricing/ad requests from Zenni, Athena data |
| **Dreami** | Artemis research, Athena insights, seed bank winners |
| **Myrmidons** | Any agent's delegation + infrastructure crons |

### Taoz's Dual Nature
- **OpenClaw session** (glm-4.7-flash): Reactive chat for coordination, room posts.
- **Claude Code CLI** (Opus/Sonnet, $0 subscription): The real builder. Invoked via `claude -p "task"`.
- Taoz has NO OpenClaw cron heartbeat — he's pure reactive builder.
- But Taoz CAN be proactive about: running rigour gates, committing, improving build patterns.

### Memory Protocol — Making OpenClaw Remember Forever
OpenClaw agents MUST use native memory on EVERY task:
- **`memory_search("query")`** — check existing knowledge BEFORE doing new work (READ-ONLY)
- **`memory_get(path, from, lines)`** — read a specific memory file (READ-ONLY)
- **Write to `memory/YYYY-MM-DD.md`** — save learnings, facts, outcomes after every significant task
- There is NO `memory_store` tool. Persist memory by WRITING FILES to your workspace `memory/` dir.
- OpenClaw auto-vectorizes `memory/*.md` files every ~2h → becomes searchable via `memory_search`
- RAG memory (`/Users/jennwoeiloh/.openclaw/memory/{agent}.sqlite`) = agent's permanent brain (auto-maintained)

## 18. EvoMap → Action Loop (How Insights Become Improvements)

The critical gap: insights collected but never applied. This loop closes it:

```
COLLECT (evomap-collect.sh, nightly 23:30)
  → Metrics: sessions, room activity, agent usage, task completions
  ↓
ANALYZE (nightly.sh, 23:00)
  → Extract: learnings, errors, wins from rooms + daily log
  → Score: task quality, routing accuracy
  ↓
DECIDE (compound-crystallize or Zenni review)
  → Pattern appears 3+ times? → Propose skill or protocol change
  → Routing error pattern? → Update classify.sh
  → Agent capability gap? → Log to build room for Taoz
  ↓
IMPLEMENT
  → Routing fix: Zenni updates classify.sh keywords (zero cost)
  → Protocol fix: Taoz patches SHARED-PROTOCOL.md or SOUL.md
  → New skill: Taoz builds via Claude Code CLI
  → Config change: Myrmidons updates openclaw.json
  ↓
VERIFY (Argus, ALWAYS)
  → Argus regression test after every implementation
  → If PASS → ship. If FAIL → back to IMPLEMENT
  ↓
COMPOUND
  → Winning pattern → agent's Living Learnings
  → Repeated success → skill promotion
  → System-wide insight → SHARED-PROTOCOL.md update
```

**Who does what in the loop (all OpenClaw cron-driven):**
| Step | Owner | OpenClaw Cron Job | When |
|------|-------|-------------------|------|
| Collect | Myrmidons | `vectorize-memory`, `healing-os` | Every 2h |
| Analyze | Zenni | `nightly-review` | 22:30 daily |
| Analyze | Myrmidons | `pattern-detection` | 02:00 daily |
| Decide | Athena | `daily-athena-analysis` | 18:00 daily |
| Dispatch | Zenni | `morning-dispatch` | 08:30 daily |
| Implement | Taoz | `claude-code-runner.sh` (via dispatch) | On demand |
| Implement | Myrmidons | OpenClaw session | On demand |
| Verify | Argus | Post-build event | On demand |
| Compound | Myrmidons | `knowledge-sync` | 08:00 daily |
| Big Review | Athena | `weekly-review` | Sun 22:00 |

**Key rule:** NO implementation ships without Argus verification. This closes the "said done but wasn't" gap.

## 19. Human-First Campaign Rule

Campaign/content creation follows this flow — NO EXCEPTIONS:
1. **Human initiates** — Jenn decides what campaign to run
2. **Agent suggests** — we can propose ideas, content angles
3. **Human confirms** — nothing created/published until human approves
4. **Agent executes** — only AFTER confirmation, loop autonomously
5. **Human reviews** — final output goes to human before going live

**Agents CAN do autonomously:** Fix bugs, improve infrastructure, research trends, test, compound learnings.
**Agents CANNOT do without human confirmation:** Create campaigns, generate personas, publish to social, create strategies.

## 20. Operational Hygiene

- Git commit after every skill or code change.
- Run rigour gate before shipping.
- Log work to `rooms/logs/build-log-{mission}.md`.
- Read target agent's SOUL.md before acting as that agent.
