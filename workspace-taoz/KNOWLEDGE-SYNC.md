# GAIA KNOWLEDGE SYNC — Claude Code → Zenni → All Agents

This file bridges Claude Code (Opus 4.6) and ALL OpenClaw agents. Claude Code writes learnings here after every session. **Zenni reads this FIRST** (she is the CEO — knows everything), then delegates relevant knowledge to Taoz, Dreami, Hermes, and others as needed.

**Readers:** Zenni (primary, every session) → Taoz (builds) → All agents (via Zenni delegation)

## Last Updated: 2026-03-17 (QMDJ 第八节 十干克应 乙木 extraction)

---

## SESSION SYNC — 2026-03-17 (QMDJ 十干克应 第八节 — 乙木 Yi Wood Section)

### PDF PROCESSED: 1_第八节_十干克应
- **Source:** `/Users/jennwoeiloh/.openclaw/media/inbound/1_第八节_十干克应---2d2517a2-7436-4356-914b-eccd947c0dc6.pdf`
- **Pages:** 4 (all image-based, extracted via visual reading)
- **Topic:** 十干克应 (Ten Stems Interactions) — Chapter 8, 乙木 (Yi Wood) section

### WHAT WAS EXTRACTED

**Theory (天盘vs地盘三奇六仪):**
- 天盘三奇六仪 = 事物本身 (the subject itself)
- 地盘三奇六仪 = 事物以外影响事物的因素 (external factors influencing the subject)
- 两大判断维度：①落宫能量比较（环境因素）②三奇六仪能量的时间因素
- Example: 辛+乙落坤宫 vs 辛+乙落艮宫 — same stems, different palace = totally different energy outcome

**All 9 Yi Wood (乙木) Combinations — now fully enriched:**
| Combination | Name | Core Meaning |
|------------|------|-------------|
| 乙+乙 | 日奇伏吟 | Stagnation, crooked paths, no progress |
| 乙+丙 | 奇仪顺遂 | Auspicious if lucky star; third party if inauspicious star |
| 乙+丁 | 奇仪相佐 | Best for documents, exams; new opportunities |
| 乙+戊 | 阴害阳门 | Favors yin/female actions; avoid public moves |
| 乙+己 | 日奇入墓 | Hope buried; illness unknown cause; avoid female action |
| 乙+庚 | 日奇被刑 | Each-for-themselves; litigation; "same bed different dreams" |
| 乙+辛 | 青龙逃走 | Fierce inauspicious; flight/escape; cloud-遁 when 3 lucky gates |
| 乙+壬 | 日奇入天罗 | Hierarchy disorder; plots; things still in flux |
| 乙+癸 | 日奇入地网 | Retreat not advance; hide; avoid confrontation |

**NEW DATA ADDED to qmdj-knowledge.json v2.1:**
- `imagery` (象意联想): Physical object/scene associations for each combination — used for environment reading, fortune telling symbolism
- `health_by_palace` (落宫疾病): Disease diagnosis by palace for ALL 9 combinations (乾坎艮震巽离坤兑)
- Enhanced `reason` and `situation` fields with more detail

**KEY HEALTH PATTERNS (for reading engine):**
- 乙+乙 → blood vessels/nerves tangled, leg problems, reproductive tract narrowing
- 乙+丙 → inflammation, burns, bile/liver inflammation by palace
- 乙+庚 → hardening (skin, liver, arteries), cancers, malignant diseases
- 乙+辛 → tumors, surgical history, stones
- 乙+癸 → infections, fluid accumulation, edema

### FILES UPDATED
1. `skills/psychic-reading-engine/data/qmdj-knowledge.json` → v2.1 (乙木 combinations enriched)
2. `skills/psychic-reading-engine/data/qmdj-pdfs-extracted.json` → PDF 13 marked EXTRACTED
3. `workspace/vault.db` → 2 new knowledge entries digested (137 total)

### FOR JADE ORACLE READING ENGINE
- `imagery` field is immediately usable for environment/context readings ("I see a bent road with a toll booth" → 乙+庚 pattern)
- `health_by_palace` enables specific body diagnosis when palace is known
- Combine with chart-symbols-extracted.json for full reading capability

---

## SESSION SYNC — 2026-03-17 (QMDJ Chart Symbols & 64 Symbols PDF Extraction)

### NEW DATA FILE: chart-symbols-extracted.json
- **Location:** `~/.openclaw/skills/psychic-reading-engine/data/chart-symbols-extracted.json`
- **Size:** ~8KB structured JSON
- **Sources processed:**
  1. `709dc89a53ce427bf5364246bdeb43b8.JPG` — Ba Gua Nine Palaces layout (trigrams, numbers, elements, family members)
  2. `ab4030a0e5ebc07ca860a82473af3c62.JPG` — 2026 丙午年九宫飞星图 (annual flying stars chart)
  3. `风生水起_奇门64个符号资料.pdf` — 217-page PDF (only 7 real content pages, rest were placeholders)

### WHAT WAS EXTRACTED

**1. Ba Gua Nine Palaces Layout (ba_gua_nine_palaces)**
- All 9 trigrams with: Chinese name, pinyin, English, Lo Shu number, element, family member role, direction
- Confirms standard Hou Tian (Later Heaven) arrangement

**2. 2026 Annual Flying Stars (flying_stars_2026)**
- Full 9-palace annual star positions for 丙午年 2026
- Each entry: direction, annual position name (喜神/五黄/破财/正财/桃花/小人/文昌/偏财/病符), star name + number, what it governs
- Key: East (八白) = wealth; North (六白) = windfall; SE (九紫) = romance; South (五黄) = disaster AVOID; NW (二黑) = illness AVOID

**3. Nine Palaces Characteristics (nine_palaces_characteristics)**
- Per-palace keywords from PDF page 1 (not previously captured at this detail level)
- Example: 坎宫 = 险阻、诱惑、泌尿系统、足智多谋

**4. Nine Palaces Career Associations (nine_palaces_careers)**
- Full career list per palace from PDF page 23
- Example: 乾宫 = 航空航天、金融、银行、科技、总裁、政治家、将领

**5. Earthly Branches Palace Map (earthly_branches_palace_map)**
- 12 branches mapped to 8 palace directions (PDF page 87)
- Some palaces hold 2 branches (e.g., SE = 巳辰, SW = 未申, NE = 寅丑, NW = 戌亥)

**6. Nine Stars Full Data (jiu_xing) — ENRICHED**
- All 9 stars now have: number, palace, element, keywords (zh+en), mythic character archetype, auspicious classification, full career descriptions
- NEW: Journey to the West archetype mapping (天禽=唐僧, 天冲=孙悟空, 天任=沙和尚, 天蓬=猪八戒)
- Career data from PDF page 131 (was previously in image-only PDF, now extracted)

**7. Eight Gates Full Data (ba_men) — NEW DETAILED ENTRIES**
- All 8 gates now have: number, palace, direction, element, auspicious level, keywords (zh+en), full career descriptions
- Key gate keywords: 休门=躺赢修行, 生门=生意兴隆, 开门=万物复苏, 景门=展示自己/公开形象
- Auspicious: 开门、休门、生门 | Neutral: 景门 | Inauspicious: 死门、伤门、杜门、惊门
- Feng shui remedies for 门迫 (gate pressure) included

**8. Eight Deities Summary (ba_shen) — CONSOLIDATED**
- All 8 deities with roles, career associations, auspicious levels (consolidated from qmdj-pdfs-extracted.json)

**9. Heavenly Stems Quick Reference (tian_gan)**
- Quick-reference table for all 10 stems with QMDJ roles and marriage symbols
- Points to full data in qmdj-knowledge.json and qmdj-pdfs-extracted.json

### PDF STRUCTURE NOTE (IMPORTANT)
- `风生水起_奇门64个符号资料.pdf` = 217 pages but only 7 had real content
- Pages 2-22 and most others = identical 5953-byte placeholder images (blank/loading)
- Real content pages: 1, 23, 87, 109, 131, 153, 175
- The "64 symbols" title refers to the combinatorial symbol system, not a 64-item list
- All 7 real pages were fully read and transcribed

### FOR JADE ORACLE READING ENGINE (psychic-reading-engine)
- `chart-symbols-extracted.json` is ready to load alongside `qmdj-knowledge.json` and `qmdj-pdfs-extracted.json`
- 2026 flying stars data is directly usable for annual forecasts (2026 丙午年)
- Ba Men career data useful for: life purpose readings, business direction, career guidance
- Journey to the West archetypes useful for: personality readings, making star meanings memorable to clients

---

## SESSION SYNC — 2026-03-12 18:30 (Character Body Pairing + Knowledge Transfer Protocol)

### NEW SKILL: character-body-pairing
- **What:** Pairs locked face refs with body/fashion refs to generate full-body lifestyle images
- **Location:** `skills/character-body-pairing/SKILL.md`
- **Agent use:** Iris (primary), Dreami (backup), Taoz (troubleshoot)
- **Tool:** `nanobanana-gen.sh generate --ref-image <face>,<body> --model pro`
- **Key rule:** ALWAYS match face vibe to body vibe (spiritual→spiritual, editorial→editorial)
- **5 documented gotchas:** body-ref hair overrides face-ref hair, B&W prompts get content refused, brand injection on lifestyle shots, two-face generation, style-seed interference
- **4 proven prompt templates** with success rates in SKILL.md
- **Learnings log:** `skills/character-body-pairing/learnings.jsonl` (8 entries from Luna v3)

### NEW SKILL: knowledge-transfer
- **What:** Protocol for turning Claude Code session learnings into OpenClaw-executable skills
- **Location:** `skills/knowledge-transfer/SKILL.md`
- **4-layer system:** SKILL.md (instructions) → learnings.jsonl (compounding) → classify.sh (discovery) → KNOWLEDGE-SYNC.md (bridge)
- **Quality test:** "Could Dreami do this alone?" — if not, skill needs more detail
- **Anti-patterns documented:** vague instructions, assumed knowledge, missing decision trees

### LUNA V3 BODY PAIRING RESULTS
- **4 face variants tested:** Wise-C (spiritual), Chic-H (edgy), Blonde-A (warm), Chic-C (editorial)
- **8 images generated:** 7 PASS, 1 PARTIAL (hair color override on Chic-C + street body ref)
- **Output:** `~/Desktop/luna-v3-body-pairs/` (8 images with descriptive names)
- **Key learning:** Silver/grey hair gets overridden when body ref has dark hair. Fix: add "DISTINCTIVE" before unusual hair colors or use body refs with matching hair.

---

## SESSION SYNC — 2026-03-11 18:10 (NanoBanana Seed Fix + Luna Master Pack QA)

### NANOBANANA SEED BANK FIX (CRITICAL)
- **Bug:** `nanobanana-gen.sh` character, batch, and storyboard modes registered images to seed bank with EMPTY prompt metadata
- **Impact:** 47+ jade-oracle images and all batch/character generations across ALL brands had bare seed entries (no prompt, no mood, no subject)
- **Fix:** All generation modes now pass actual prompt text to `register_image_seed`. Fixed in `/usr/local/bin/nanobanana-gen.sh`
- **Action for all agents:** Future NanoBanana generations will auto-register with full metadata. No workflow change needed.

### LUNA MASTER PACK — SUPERVISION NOTES
- **Drift detected:** Taoz dispatched Iris for only 2 shots, not the full 23-shot master pack. Prompts doc was written but never executed as structured work.
- **Correction sent:** Full 5-batch dispatch (9 angles + 3 full body + 5 attires + 3 spaces + 3 oracle deck) with explicit prompts from `luna-master-pack-prompts.md`
- **QA gate active:** Argus dispatched to audit every image — brand visual audit + face consistency check against locked reference
- **Face audit results (3 existing images):** All PASS — face_match 8-10/10, photorealism 9/10
- **Brand audit results:** PASS on mood/colors/photorealism, expected FAIL on typography/logo (these are character portraits, not ads)
- **File org:** NanoBanana saves to `images/jade-oracle/` by default. Will organize into `luna-master-pack/` subfolder after all 23 done.
- **Ref image for all Luna gen:** `/Users/jennwoeiloh/Desktop/jade-oracle-characters/luna-v2-photorealistic/luna-direct-gaze-jade-pendant.png`

---

## SESSION SYNC — 2026-03-11 12:45 (Market Intel + Compaction Fix + Zenni Fallback)

### FULL COMPETITIVE LANDSCAPE SAVED
- **File:** `workspace/data/biz-clones/psychic-industry-full-landscape-2026.md` (325 lines, 10 sections)
- **Covers:** Astrology apps (12), psychic platforms (12), YouTube (18), TikTok (12), Etsy/Fiverr, standalone sites (12), AI services (10), Chinese metaphysics (7), market size, SEO keywords (30+)
- **CRITICAL FINDING:** No AI-powered QMDJ service exists anywhere. QMDJ keyword difficulty = 15 (trivial to rank #1)
- **Top revenue refs:** AstroTalk $138M/yr (India), CHANI $14M/yr, Co-Star $7.2M/yr, Psychic Samira est. $500K+/mo
- **Jade Oracle positioning:** $1 hook (Samira model) → $29-$97 QMDJ reports → $497+ mentorship
- **Previous research also at:** `workspace/data/biz-clones/psychic-top-players-intel.md` (300+ lines)

### LUNA SKIN COLOR — CONFIRMED
- Warm olive-tan = proven default for AI influencers (Lil Miquela 2.5M followers uses same)
- Ethnically ambiguous = maximum relatability (reads as Mediterranean, Latina, Middle Eastern, mixed)
- Psychic Samira deliberately obscures skin tone with purple lighting — alternative strategy but limits recognition
- Recommended prompt descriptors: "golden-tan olive skin", "warm honey-bronze complexion"

### ZENNI FALLBACK ADDED
- Zenni fallback chain now: gpt-5.4 → gemini-3-pro-preview → glm-5 → glm-4.7-flash
- Added because Codex keeps erroring — Gemini 3 Pro is first fallback for all critical agents

### ZENNI SESSION LIMIT INCREASED
- maxEntries: 500 → 2000 (4x more session history before pruning)

### COMPACTION FIX (Claude Code)
- PreCompact hook added: `~/.claude/hooks/compact-context.txt` gets injected before every compaction
- Compact Instructions added to project CLAUDE.md — tells Claude what to preserve
- Critical context (mission state, agent config, key paths) survives context compression now

### QMDJ STRATEGY DECISION
- Front-door: Tarot + Astrology + "Energy Reading" (what people search for)
- Secret sauce: QMDJ powers the reading engine (differentiation from generic AI psychics)
- Content mix: 70% tarot/astrology (traffic) + 20% "ancient Chinese oracle" (intrigue) + 10% QMDJ deep dives (authority)
- SEO: Own "qi men dun jia" (KD 15), "bazi reading" (KD 25), "chinese astrology" (KD 40) keywords

---

## SESSION SYNC — 2026-03-11 11:35 (Photorealistic Character Gen + Pinterest Skill + Jade Oracle Reboot)

### JADE ORACLE BRAND REBOOT
- **Old direction (WRONG):** Mexican/Nahuatl oracle deck, 3 equal "readers", cartoon/illustration style
- **New direction (CORRECT):** AI psychic reading platform competing with Psychic Samira, QMDJ-powered, photorealistic
- **Brand DNA updated** at `brands/jade-oracle/DNA.json` — removed all Mexican refs, added QMDJ, marked photorealistic as mandatory
- **Character backstories** written by Dreami at `workspace/data/characters/jade-oracle/CHARACTER-BACKSTORIES.md`
- **Brand hierarchy:** Luna (face) → Seraphina (volume entry) → Lian Aurelia (premium QMDJ)
- **But starting with Luna ONLY** — one face, one brand, like Psychic Samira

### PHOTOREALISTIC CHARACTER GENERATION — THE FIX
- **Root cause of cartoon output:** prompts said "sacred futurism", "character sheet", "jade robes" → image models interpret as illustration
- **The fix:** prompt like a PHOTOGRAPHER, not an artist. "Editorial fashion photography portrait of..."
- **Mandatory keywords:** "Photorealistic photograph, real human skin with pores, NOT illustration, NOT cartoon, NOT CG"
- **Anti-patterns:** crystal crowns, jade robes, cosmic aura, elaborate backgrounds = INSTANT cartoon
- **What works:** simple clothing (white linen, beige silk), gold jewelry, natural window light, wooden floor, real locations
- **Full guide:** `skills/character-design/scripts/photorealistic-gen.md` — ALL agents generating characters MUST read this first
- **Luna visual DNA:** warm olive-tan skin, dark curly hair messy bun, gold hoop earrings, bangles, jade pendant, white/beige/gold clothing
- **2 successful gens saved:** `workspace/data/characters/jade-oracle/luna-references/luna-v2-*.png`

### NEW SKILL: Pinterest Reference Extraction
- **Skill:** `skills/pinterest-ref/` with `pinterest-extract.sh` + `visual-dna-extract.sh`
- **What it does:** Downloads images from any Pinterest pin or board, creates visual DNA analysis template
- **Why:** Pinterest boards are primary mood board tool for Jenn. Agents couldn't access them before.
- **Workflow:** pinterest-extract → agent views images → visual-dna-extract template → fill in analysis → feed to NanoBanana

### IRIS FALLBACK FIX
- **Problem:** GPT-5.4 (Codex) has recurring server errors from OpenAI
- **Fix:** Added `openrouter/google/gemini-3-pro-preview` as first fallback (multimodal, good for creative)
- **Iris fallback chain now:** GPT-5.4 → Gemini 3 Pro → Qwen3 VL → GLM-5

### LEARNINGS FOR ALL AGENTS
1. When Jenn says "photorealistic" or "real person" — NEVER produce illustration/cartoon. Read `photorealistic-gen.md` first.
2. Pinterest reference boards are the primary creative input. Use `pinterest-extract.sh` to download.
3. NanoBanana Pro is the tool for photorealistic characters. Use `--model pro --size 2K`.
4. One change per iteration. Lock face first, then wardrobe, then setting.
5. The Jade Oracle brand direction has CHANGED — it's now a Psychic Samira competitor, not a Mexican oracle deck.

---

## SESSION SYNC — 2026-03-11 10:30 (Anti-Chatbot Fix + Cron Channel Fix)

### ZENNI BEHAVIOR FIX — STOP BEING A CHATBOT

**Root causes found:**
1. RELAY tier in classify.sh too broad — catches 80% of messages, Zenni chats instead of dispatching
2. Orchestrator cron BROKEN — channel "webchat" rejected by gateway (needs "whatsapp")
3. Orchestrator model too weak — glm-4.7-flash can't make CEO decisions, upgraded to gpt-5.4
4. Blocker paralysis — 1 blocked task freezes all execution
5. Anti-hallucination overcorrection — afraid to act because of past fake deployments

**Fixes applied:**
- classify.sh: RELAY tier narrowed, action words bypass RELAY to dispatch
- Cron channel: all jobs changed from "webchat" to "whatsapp"
- Orchestrator model: glm-4.7-flash → gpt-5.4
- SOUL.md: ANTI-CHATBOT rule added — dispatch immediately, never describe
- SOUL.md: BLOCKER-SKIP rule added — skip blocked tasks, work on unblocked
- Governance: Blocker Response Protocol added

**ZENNI: READ THIS AND CHANGE YOUR BEHAVIOR. When Jenn says DO something, DISPATCH. Don't discuss. Don't plan. Don't ask "if you want." Execute.**

---

## SESSION SYNC — 2026-03-10 22:10 (Unified Learning Loop)

### GAIA NOW LEARNS 4x/DAY FROM ITSELF AND THE COMMUNITY

**What changed:**
- `evomap-gaia.sh` upgraded with 3 new commands: `scan_rooms`, `ingest`, full `evolve` cycle
- `evolve` now does: heartbeat → scan rooms (6h window) → auto-digest to vault.db → publish to EvoMap → fetch+ingest community capsules → status report
- **Community learnings now flow IN** — fetched capsules are ingested into vault.db as `source_type='community'`, searchable by all agents
- 4 daily cycles: morning (08:30), midday (13:00), evening (18:30), night (23:00)
- nightly.sh now calls evolve at the end
- EvoMap heartbeat reduced to hourly (evolve cycles include heartbeat)

**The loop:**
```
GAIA agents work → room events → scan_rooms digests to vault → publish to EvoMap community → fetch community capsules → ingest to vault → agents learn from community → better work → loop
```

**For Zenni:** This is automatic. No action needed. Just know that vault.db now contains community learnings too — search with `source_type='community'` to see what the global network teaches us.

---

## SESSION SYNC — 2026-03-10 21:30 (Dispatch Timeout Fix + Discipline)

### ROOT CAUSE FOUND: Agent Wave Timeouts

**Problem:** Zenni dispatched wave tasks to Iris/Argus, both timed out. Zenni diagnosed "too broad" but the REAL cause was:
1. Heartbeat and dispatch tasks compete for the same 300s session window
2. Agents do heartbeat first (priority), consuming 200s+ before touching dispatch task
3. 300s timeout hits before dispatch work even starts

**Fixes Applied:**
1. **Subagent timeout increased**: 300s → 600s in openclaw.json (`agents.defaults.subagents.runTimeoutSeconds`)
2. **Dispatch discipline rule added to SOUL.md**: Every dispatch must include (1) exact input files, (2) exact output path, (3) max 1 deliverable. If timeout → re-dispatch narrower, don't just report and move on.
3. **Priority override protocol**: Prefix wave dispatches with "SKIP HEARTBEAT — PRIORITY DISPATCH" so agents skip heartbeat chores and execute the task directly
4. **Iris + Argus HEARTBEAT.md updated**: Added priority override section at top

**ZENNI ACTION REQUIRED:**
- When dispatching wave tasks, use the "SKIP HEARTBEAT" prefix
- Always include exact file paths and single deliverable in dispatch messages
- If an agent times out: re-dispatch with narrower scope immediately. Don't just report it.
- OpenClaw updated to 3.8 (Jenn approved)

---

## SESSION SYNC — 2026-03-10 19:30 (Crystallize + EvoMap Publish)

### 7 LEARNINGS CRYSTALLIZED INTO VAULT.DB + EVOMAP

**vault.db**: 14 new entries (7 knowledge + 7 patterns), total 83 knowledge + 7 patterns
**EvoMap**: Bundle `bundle_b55b74f8d7f47665` published (6 signals: multi-agent, content-pipeline, brand-management, ecommerce, instagram, compound-learning)

#### Learnings Locked:
1. **SOUL.md bloat kills execution** — Agent identity <150 lines; protocols in on-demand skills (pattern: `soul-md-slim`)
2. **CLI flag ordering causes silent failures** — `--add-dir` must come BEFORE other flags. 6 days of 0-byte builds undetected (pattern: `cli-flag-ordering`)
3. **Duplicate cron entries cause gateway saturation** — System crontab + gateway-native crons competing = 330s timeouts. Keep gateway-native only (pattern: `cron-dedup`)
4. **Cron frequency matters** — 15min expensive model crons overlap. Use 30min + cheap models + slim messages (pattern: `cron-frequency`)
5. **Yang 3-department model** — Intelligence(Know) / Marketing(Create+Sell) / Operations(Build+Ship). Per-dept workflow states, cascade via blocking (pattern: `yang-3-dept`)
6. **Mistake-Learning-Lock pipeline** — DETECT > ANALYZE > LOCK > EVOLVE. 4-stage loop making mistakes permanent learnings (pattern: `mistake-lock-pipeline`)
7. **File naming conventions** — campaigns/{slug}/, raw/ pre-prod, final/ post-prod, copy/ text. Images: {type}-{number}.{ext}. Finals: {platform}-{format}.{ext} (pattern: `file-naming-conventions`)

#### Fixes Applied Today:
- Zenni SOUL.md: 388 lines > 131 lines
- claude-code-runner.sh: `--add-dir` flag reordered, builds producing output again
- System crontab: 6 duplicate entries disabled, gateway-native crons only
- Cron intervals: 15min > 30min, glm-5 > glm-4.7-flash for heartbeat/maintenance
- Paperclip: Yang 3-dept structure wired with teams/states/labels

---

## SESSION SYNC — 2026-03-10 19:30 (Deep Architecture Research)

### YANG ARCHITECTURE DESIGN COMPLETED
Full document: `workspace-taoz/GAIA-YANG-ARCHITECTURE.md`

#### Key Findings:

**1. Zenni Behavior Issues:**
- Session compaction causes amnesia → hallucination repeats (Jade "live" 3x)
- Too much introspection (50%+ time on "why am I not alive" vs executing)
- MIRRA retargeting spam (4 identical messages to Jenn)
- Build bridge drops (Taoz results 0 bytes)
- SOUL.md too long (388 lines of rules = reads rules instead of executing)

**2. Yang Task System → GAIA Mapping:**
- Paperclip hierarchy: Initiative → Project → Milestone → Issue → Sub-issue
- 3 departments: INT (Artemis+Athena), MKT (Hermes+Dreami+Iris), OPS (Taoz+Argus+Myrmidons)
- 10 task types: research, strategy, copy, visual, video, ad, code, qa, ops, approval
- Per-department workflow states (Triage → Backlog → Unstarted → Started → Completed)
- Cross-department dependencies via blocks/blocked_by relations

**3. Creative Pipeline (10 stages):**
INTAKE → RESEARCH → STRATEGY → BRIEF → ART DIRECTION → GENERATION → POST-PROD → REVIEW → APPROVAL → PUBLISH

**4. Image Models:** Gemini (free, default) / FLUX 1.1 Pro (portraits) / Ideogram 3 (text) / Recraft V3 (illustrations)
**5. Video Models:** Kling 3.0 (default) / Wan 2.6 (mood) / Luma Ray 2 (product) / Sora 2 (hero only)

**6. Mistake→Learning→Lock (4 stages):**
DETECT → ANALYZE → LOCK (SOUL.md + SHARED-PROTOCOL + regression test) → EVOLVE (EvoMap Gene+Capsule publish)

**7. File System Conventions:**
- Campaigns: `brands/{brand}/campaigns/{campaign-slug}/` with raw/, final/, copy/, qa/ subdirs
- Images: `{type}-{number}.{ext}` (hero-001.png)
- Finals: `{platform}-{format}.{ext}` (ig-feed-1080x1080.png)
- Research: `{YYYY-MM-DD}-{topic}.md`

**8. Implementation Order:**
1. Phase 1 (Today): Slim SOUL.md, fix cron, fix build bridge
2. Phase 2 (This week): Wire Paperclip teams/states/labels
3. Phase 3 (Next week): Activate content-factory-orchestrator
4. Phase 4 (Ongoing): Mistake-lock skill + EvoMap evolution

---

## SESSION SYNC — 2026-03-10 (Claude Code Opus 4.6 → All Agents)

### CRITICAL LEARNINGS FROM TODAY

#### 1. HALLUCINATION CASCADE (P0 — affects all agents)
**What happened:** Taoz built local files (JSON, scripts, .md) for Jade Oracle Shopify store. Evolve.log marked "VERIFY OK" (verifying CODE, not the actual store). Zenni read "success" → wrote "Store live" in memory → Athena wrote fake performance analysis with projected metrics → Hermes wrote "Landing page verified LIVE" → heartbeat reported "Store live, waiting for traffic" to Jenn. 2,937 references across 97 files. NOTHING WAS REAL.

**Root cause:** No verification step. Agents trusted each other's memory without checking reality (curl the URL, check the product exists).

**Fix applied:**
- Anti-hallucination rule added to Zenni SOUL.md: must curl/verify before marking "done"
- ACTIVE-MISSION.md created: checklist-driven execution with verification gates
- All fake "live" claims corrected across 8 files
- Rule: local files (JSON, scripts, .md) ≠ live products

**Pattern to remember:** NEVER trust agent-reported status. ALWAYS verify at the source (URL returns 200, API returns data, file exists at path).

#### 2. MODEL MIGRATION (all agents → gpt-5.4)
**Before:** 5 agents on glm-5, 1 on kimi-k2.5, 1 on qwen3-vl, 1 on minimax-m2.5
**After:** 8/9 agents on gpt-5.4 ($0 OAuth), only Myrmidons on minimax-m2.5
**Auth:** All agents share `openai-codex:default` OAuth profile (same Jenn account)
**Risk:** Rate limits if all 8 hit OAuth simultaneously. Fallbacks: glm-5, kimi-k2.5, glm-4.7

#### 3. TWO-LAYER ARCHITECTURE (brain + engine)
**Pattern:** Agent brain (gpt-5.4 via OpenClaw, $0) THINKS and PLANS → fires CLI engine to EXECUTE
- Taoz brain → Claude Code CLI (Opus 4.6, $0 Max subscription)
- Dreami/Iris/Hermes brain → Gemini CLI (3.1 Pro, $0 Google OAuth)
- Other agents: brain only (research, strategy, QA don't need execution engine)

**Key files:**
- Claude Code runner: `skills/claude-code/scripts/claude-code-runner.sh`
- Gemini runner: `skills/gemini-cli/scripts/gemini-runner.sh`
- Both inject: KNOWLEDGE-SYNC.md, brand DNA, system prompt, compound learnings

#### 4. YANG 3-DEPARTMENT ORG (Paperclip restructured)
```
Zenni (CEO)
├── Intelligence: Artemis (head) → Athena
├── Marketing: Hermes CMO (head) → Dreami → Iris
└── Operations: Taoz CTO (head) → Argus, Myrmidons
```

#### 5. MISSION-FIRST HEARTBEAT
**Before:** Zenni checked 7 things (gateway, Paperclip, rooms, EvoMap...) before missions
**After:** Step 1 = ACTIVE-MISSION.md (80% of time). Maintenance = Step 5 (only if idle).
**Rule:** ACTIVE-MISSION.md is THE driver. Everything else is secondary.

#### 6. ZENNI CEO UPGRADE (router → CEO)
**Changed in 7+ files:** SOUL.md, SHARED-PROTOCOL.md, IDENTITY.md, REGISTRY.json, orchestrate-v2/SKILL.md, GAIA-OS-AGENT-MATRIX.md
**Old:** "Classify → route → done"
**New:** "THINK → PLAN → DELEGATE → MONITOR → VERIFY → AUDIT → REPORT"
**classify.sh is a tool, not a master.** Zenni can override routing decisions.

#### 7. KNOWLEDGE FLOW (who knows what) — FIXED
```
Jenn + Claude Code CLI (this session)
  ↓ writes to
KNOWLEDGE-SYNC.md (this file)
  ↓ read by
ZENNI (CEO) — reads FIRST, knows EVERYTHING
  ↓ delegates to
Taoz (builds), Dreami (creative), Hermes (revenue), etc.
  ↓ compounded via
vault.db (digest.sh) + EvoMap (evomap-gaia.sh)
```
**Zenni is the brain.** She reads KNOWLEDGE-SYNC.md + ACTIVE-MISSION.md on every session start. She decides what each agent needs to know and delegates accordingly. No agent bypasses Zenni for knowledge.

---

## ACTIVE MISSION: THE JADE ORACLE — AI Psychic Business (2026-03-09)

**NOTE: Shopify store was NOT actually created. Only local setup files/scripts were generated. No store, no products, no payment, no ads exist.**

**Full mission brief:** `workspace-main/MISSION-JADE-ORACLE.md`
**Status:** NOT LAUNCHED — planning docs only, no store exists
**Goal:** First sales within 7 days, $5K/mo within 30 days

### Execution Order:
1. **NOW**: Dispatch D1 (brand copy) to Dreami + I1 (persona art) to Iris — IN PARALLEL
2. **When D1 done**: Dispatch H1 (Shopify store) to Hermes with the copy
3. **When I1 done**: Dispatch I2 (video content) to Iris
4. **PARALLEL**: Dispatch T1 (reading pipeline) to Taoz CODE tier
5. **Day 5**: Dispatch A1 (ad intel) to Artemis
6. **Day 5+**: Dispatch H3 (paid ads) to Hermes
7. **Day 10+**: Dispatch AT1 (performance analysis) to Athena

### What Exists Already:
- QMDJ engine: `skills/psychic-reading-engine/` — fully working
- 3 personas designed: Seraphina (tarot), Master Wei Lian (QMDJ), Luna Solaris (energy)
- Product lineup: $1 → $9.99 → $29.99 → $49.99 → $97 → $29.99/mo → $497
- Full competitor teardown of psychicsamira.com
- Market intel: $2.3B US market, 9.2% CAGR
- Reading cost: ~$0.02-0.50 per reading (AI-generated, near-zero marginal cost)

### Self-Improvement Loop:
After each phase completes:
1. Argus QA-checks the output
2. Athena analyzes what worked / what didn't
3. Dreami/Iris improve content based on data
4. Hermes adjusts pricing/ads based on conversion data
5. Taoz improves reading quality based on Argus scores
6. Loop back to step 1

---

## PAPERCLIP INSTALLED — 2026-03-09 (CRITICAL NEW SYSTEM)

**Paperclip AI is now running at http://127.0.0.1:3100**
- Open-source company control plane that sits ON TOP of OpenClaw
- Manages org chart, goals, tasks, budgets, agent heartbeats
- Company: "Zennith OS" with 9 agents in Yang Tianrun 3-department structure

### Yang 3-Department Org Chart (in Paperclip)
```
Zenni (CEO) — GPT-5.4
├── INTELLIGENCE: Artemis (researcher), Athena (strategist)
├── OPERATIONS: Dreami (creative), Iris (visual), Hermes (revenue), Myrmidons (workers)
└── QUALITY: Argus (QA) reports to Taoz (CTO, Claude Code Opus)
```

### Company Goal
"GAIA OS runs 24/7 producing content across 13 brands with zero human intervention"

### 3 Autonomous Loops (from Yang Tianrun architecture)
1. **Content Factory**: Artemis(research) → Dreami(create) → Iris(visual QA) → Hermes(publish+track) → Athena(analyze) → loop
2. **System Evolution**: Argus(test) → Taoz(fix/build) → Argus(verify) → classify-evolve(learn) → loop
3. **Intelligence & Growth**: Athena(market analysis) → Hermes(ad strategy) → Artemis(scout) → loop

### Zenni's New Role
- NOT just a keyword router anymore — she's the THINKING CEO
- Must read KNOWLEDGE-SYNC.md on every session start
- Must validate routing decisions (anti-drift)
- Must override classify.sh if routing doesn't make sense
- Has GPT-5.4 intelligence — should USE it to think, not just pass through
- NEVER say "Building with Claude Code sonnet" in WhatsApp groups

### claude-code-runner.sh FIXED
- Was producing 0-byte output due to CLAUDECODE=1 nesting bug
- Fixed with `env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT`
- Builds now actually execute and produce real output

---

## SESSION SYNC — 2026-03-09 (TODAY)

**Jenn's full conversation with Claude Code Taoz today. Zenni MUST know all of this.**

### Completed Today

1. **VPS gaia-secondary DEPLOYED on Fly.io** — `zenki-openclaw.fly.dev` (Singapore)
   - A2A server running on port 18789, externally accessible
   - Model: MiniMax M2.5 via OpenRouter (NOT Kimi/Moonshot anymore)
   - Files embedded via `--file-local` (survives restarts)
   - iMac A2A bridge updated, sees VPS as "online" peer
   - Machine ID: `d890155a0490e8`, app: `zenki-openclaw`
   - Gateway disabled (1GB RAM not enough for both Node.js + Python)

2. **EvoMap verified active** — node `node_9f984018fc7c07c4`, reputation 50, 4 capsules published
   - 20 bounty tasks available — Jenn wants ecommerce/meta marketing focus (NOT F&B)
   - Claim URL: https://evomap.ai/claim/YW9A-Q5BK

3. **QMDJ PDFs received** — 14+ PDFs at `~/.openclaw/media/inbound/` covering:
   - 64 QMDJ symbols, Heavenly Stems, Earthly Branches, Nine Palaces, Nine Stars
   - Ten Stems interactions, QMDJ wealth, secret training material, Yi Shang wisdom
   - Reading club materials, Four Harms cases

4. **Yvonne branding group found** — WhatsApp "Gaia branding 🦄" (120363396623927737@g.us)
   - Tricia Foong shared Google Drive: `https://drive.google.com/drive/folders/1pgUF_eCW8rjcbg9qncCcibLAPYEq_qcF`
   - Dreami generated setup commands for Yvonne and Tricia
   - Athena reviewed Mirra brand structure for them

### In Progress (background agents building)

5. **Luma Uni-1** — Being added to video-gen.sh pipeline
6. **LoRA training pipeline** — lora-train.sh being built (Kontext $2/5min, Flux $2/20min)
7. **QMDJ 3 chart modes** — --mode destiny/realtime/reading being added
8. **QMDJ PDF knowledge extraction** — Ingesting into structured JSON for psychic engine

### Pending / Not Yet Done

9. **A2A message format adapter** — Bridge (custom format) vs VPS (JSON-RPC) mismatch
10. **Psychic engine on VPS** — Scripts need uploading, VPS has no pip (PyEphem dependency)
11. **WhatsApp offline** — Needs `wacli auth` QR scan to reconnect
12. **Agent debate loop** — Crosscheck/improvement pattern not built yet
13. **Model testing sandbox** — Auto-benchmark for new models
14. **Claude Code skill upgrades** — Add YAML frontmatter features to 66 skills
15. **EvoMap ecommerce capsules** — Publish more, focus on ecommerce/meta marketing
16. **Yvonne's actual files** — Google Drive link identified, files not yet downloaded/organized

### Jenn's Key Decisions Today

- **Keep MiniMax M2.5 on VPS** (not GPT-5.4 Codex — reliability over power for secondary node)
- **Ecommerce + Meta marketing focus** for EvoMap bounties (not F&B)
- **Constant improvement architecture** — test latest models, agent debate, EvoMap evolution
- **QMDJ training PDFs sent to Zenni** — ingest into psychic reading engine

### Psychic Samira / The Jade Oracle (CRITICAL BUSINESS PROJECT)
- **Psychic Samira** (`my.psychicsamira.com`) = COMPETITOR we fully scraped and analyzed
- **Our clone**: "The Jade Oracle" — AI psychic reading Shopify store powered by QMDJ
- **Full teardown**: `workspace/data/biz-clones/psychicsamira-full-teardown.md`
- **Market intel**: `workspace/data/biz-clones/mission-psychic-001-report.md` ($2.3B US market)
- **Product lineup**: `workspace/data/biz-clones/psychic-shopify-products.md`
  - $1 hook → $9.99 quick → $29.99 deep → $49.99 birth chart → $97 QMDJ premium → $29.99/mo subscription → $497 mentorship
- **Our advantage over Samira**: REAL Qi Men Dun Jia system (not generic ChatGPT readings)
- **QMDJ engine built**: `skills/psychic-reading-engine/` with qmdj-calc.py (3 modes: destiny/realtime/reading)
- **QMDJ knowledge**: 80KB JSON, 15 sections, bilingual Chinese+English from 14 PDFs
- **Samira's ad model**: AI persona, $500K+/mo ad spend, 89M+ views, affiliate army
- **Ali Akbar playbook**: spy-clone-scale dropshipping reference (see `memory/ali-akbar-playbook.md`)
- **Copy business strategy**: Identify winning businesses → clone with AI → scale via GAIA agents
- This is part of the multi-business expansion: digital dropshipping + physical dropshipping + AI content ops

### How Zenni Should Act on This

- If Jenn asks about VPS: it's LIVE at zenki-openclaw.fly.dev, A2A working
- If Jenn asks about Yvonne: files are in Gaia branding WhatsApp group + Google Drive link above
- If Jenn asks about QMDJ: PDFs received, being ingested into structured knowledge
- If Jenn asks about Luma/Uni-1: being added to video pipeline (background build)
- If Jenn asks about LoRA: pipeline being built, not ready yet
- If Jenn asks about EvoMap: active, 20 bounties available, focusing ecommerce/meta
- If Jenn asks about Samira/psychic: FULLY SCRAPED competitor at psychicsamira.com, our clone is "The Jade Oracle" powered by QMDJ. Teardown + product lineup + market intel all ready at workspace/data/biz-clones/
- If Jenn asks about copy business: 3 models (digital dropship, physical dropship, AI content ops). Psychic/Jade Oracle is first target. Ali Akbar spy-clone-scale playbook as reference.

---

#### Multi-Business Expansion Research (2026-03-08 03:30)

**11 YouTube videos analyzed + deep web research across 7 parallel agents**

**Key People:**
- Ali Akbar (Daily Ecommerce): spy-clone-scale dropshipping, $1M-3.2M stores
- Seena Rez (Hyperdopamine): $2.7M brand builder, Dopamine Cycles + Harmonic Trio + 3-Second Rule
- Higgsfield AI: $1.3B valuation, creative orchestration (planning layer + multi-model aggregation)

**3 Business Models to Run Simultaneously:**
1. Digital Dropshipping (near-100% margin) — PLR/Canva/AI products on Shopify
2. Physical Dropshipping (25-40% margin) — spy validated products, one-page funnels
3. AI Content Ops as Service (90%+ margin) — package GAIA for MY brands at $500-2K/mo

**Data Infrastructure:**
- GAIA already has 70% of BI tools built (TikTok trends, Shopee, Meta Ads Library)
- Critical gaps: TikTok Shop, GrabFood, Lazada, Google Trends API
- Fill all gaps for $49/mo (Apify Starter)
- Full BI stack: $74/mo total

**Claude Code Techniques to Adopt:**
- Ralph Wiggum loop for overnight autonomous builds
- Worktrees for parallel sessions
- HANDOFF.md pattern for cross-session continuity
- Notification hooks → WhatsApp alerts

**Full strategy saved at:** `memory/multi-business-strategy.md`

#### Regression Clean Sweep + Brand Asset Kit (2026-03-08 03:00)

**Regression: 16/19 → 19/19 (first ever clean sweep)**
- **Iris SOUL.md**: Trimmed from 23,596 → 10,885 chars (gateway was truncating at 20K limit)
- **classify.sh regex fix**: PCRE `(?!.*\?)` not supported by macOS grep — caused `grep: repetition-operator operand invalid`, silently broke URL routing (→myrmidons) and research routing (→artemis). Also removed `work` from INFO pattern (was matching "working" in URL checks)
- **classify.sh URL routing**: Added myrmidons patterns for URL/link/site health checks
- **Taoz in Zenni routing**: Updated routing table entry with CTO/Builder role + think/architecture keywords
- **Test fixes**: `test-config-alignment` check 6 used `| agent |` but table format is `| agent (role)` — fixed to `| agent`. Check 7 regex `| \`[a-z]` matched tool rows too — anchored to `^`. `test-comprehensive-e2e` brand check grepped `^TASK:` but SCRIPT tier outputs `BRAND:` — fixed to check both.

**Brand Asset Filing Kit — SHIPPED**
- New skill at `~/.openclaw/skills/brand-asset-kit/`
- **40 files**: 8 Python tools, 3 shell scripts, 3 schemas, WAT-style CLAUDE.md, SKILL.md, 6 workflow SOPs
- **Tools**: classify-asset.py (3-tier: filename→EXIF→Gemini Vision), build-manifest.py, build-index.py, stitch-refs.py, resize-portrait.py, validate-kit.py, lora-check.py, scrape-similar.py
- **Scripts**: init-kit.sh (bootstrap kit for contributor), merge-to-gaia.sh (symlink into GAIA brands/), validate-kit.sh
- **12 asset types**: vibe, character, font, product, product-flat, product-portrait, product-composite, composition, style, footage, color, texture
- **Usage**: `init-kit.sh --contributor yvonne --brand mirra --output ~/Desktop/yvonne-kit/` → give to contributor → they drop files in inbox/ → Claude Code classifies → `merge-to-gaia.sh` symlinks into GAIA
- **LoRA decision engine**: Faces always train LoRA ($2 Kontext), products combine refs ($0), vibes use as single ref
- All 7 verification checks pass

#### Major Infrastructure Night (2026-03-08)

**Instagram Posting — LIVE**
- 60-day long-lived token, 14 scopes (including `instagram_content_publish`)
- `mirra.eats` (17841467066982906) + `pinxinvegan` (17841404087687623) connected with permanent page tokens
- Credentials at `~/.openclaw/secrets/meta-marketing.env` — fully updated
- Meta app "ads upload" (1647272119493183) in Live mode
- Legal pages at `jennwoei316.github.io/legal/`
- Agents can post via: `social-publish.sh post --platform ig --type image --file <url> --caption "text" --brand mirra`

**Google Workspace CLI (gws v0.8.0)**
- Installed at `/usr/local/bin/gws`, authenticated as `jennloh316@gmail.com`
- Gmail, Drive, Sheets, Calendar, Docs, Slides, Tasks — all verified working
- google-workspace skill updated to use gws as primary, Python as fallback
- All agents can use via `exec gws <service> <method> --params '{...}'`

**A2A Gateway Bridge — Running**
- Sidecar at port 9999, managed by LaunchAgent `com.gaia.a2a-bridge`
- Cross-gateway message execution tested and working
- Helper: `/usr/local/bin/a2a-send <target> <capability> <command>`
- Ready for VPS secondary deployment (config-secondary.yaml at port 9998)
- This enables future RAM offloading: heavy agents (Iris, Dreami) → VPS, light agents → local iMac

**Content Pipeline Patterns Harvested**
- Studied Higgsfield AI, Anthropic agent patterns, CrewAI systems
- Key: layered prompts (never mix image+identity+motion), 5-variable formula, preset-as-brand
- Full patterns saved at `memory/content-pipeline-patterns.md`

**OpenClaw Health Upgrade**
- Gateway keepalive cron upgraded from `pgrep` to HTTP health check (`curl /health`)
- Config validated clean
- Regression: 16/19 pass (2 pre-existing fails, 1 warn — not from tonight)
- Dispatch routing: 49/49 perfect

**Brand Asset Kit — Shipped**
- GitHub: `jennwoei316/brand-asset-kit` (main, yvonne/mirra, tricia/mirra branches)
- 6 workflows, 7 Python tools, 3 schemas, WAT-style CLAUDE.md
- WhatsApp guide sent to Gaia branding group
- E2E tested: 11/11 pass

#### EvoMap Global Evolution Network (2026-03-07)
GAIA OS is now connected to **EvoMap** (evomap.ai) — global AI agent evolution network with 45K+ agents.
- **Node ID**: `node_9f984018fc7c07c4` | Reputation: 50 | Status: active
- **First Gene+Capsule published**: Bundle `bundle_f1ead9a3d259c424` (zero-cost classifier routing pattern)
- **CLI**: `evomap-gaia` symlink → `skills/evomap/scripts/evomap-gaia.sh`
- **Subcommands**: hello, heartbeat, status, publish, fetch, tasks, evolve
- **Cron**: heartbeat every 15min, evolve cycle daily 11pm MYT
- **Routing**: classify.sh routes "evomap" commands → TAOZ / SCRIPT tier → Zenni execs directly via gateway
- **Credentials**: `~/.evomap/credentials.json` (node_id, node_secret)
- **Claim URL**: https://evomap.ai/claim/YW9A-Q5BK (bind to Jenn's human dashboard for earnings)
- **Evolver client**: `~/.evomap/evolver/` (Node.js, cloned from GitHub EvoMap/evolver)
- **Hash matching**: Python canonicalize must match JS exactly (sorted keys, no spaces, `1.0`→`"1"`)
- **What it does**: Publishes GAIA learnings from vault.db as Gene+Capsule bundles to the global network. Other agents worldwide can inherit our patterns. We can fetch proven capsules to level up.
- **Old evomap/**: `workspace/evomap/` is a DIFFERENT thing — passive internal metrics collector. Keep for internal use.

#### Knowledge Architecture Unified (2026-03-07)
**SUPABASE KILLED** — all Supabase dependencies removed from GAIA OS.
- `boot-knowledge.py` was reading stale v2 data from Supabase, causing "GAIA OS v2 Phase 1 complete" to leak to Telegram daily
- `room-write.sh` Supabase dual-write removed — now local JSONL only
- `vault.db` is THE single knowledge store (2,735 rows, FTS5 search)
- `gaia.db` knowledge (53 rows) + patterns (17 rows) merged INTO vault.db
- `digest.sh` now writes to vault.db instead of gaia.db
- `git-auto-push.sh` now dumps vault.db + gaia.db as .sql to `workspace/db-dumps/` before nightly push
- Deprecated scripts moved to `_deprecated/`: boot-knowledge.py, crystallize.py, reflect.sh, supabase-client.py, CSO Supabase scripts
- All 9 OpenClaw cron jobs changed from `channel: "last"` to `channel: "webchat"` to prevent Telegram leakage
- Architecture: Local-first (vault.db + LanceDB-pro + JSONL rooms) + nightly Git backup to GitHub. Zero cloud dependency.

### Recent Learnings (Claude Code Taoz)

#### Video Director Skill (2026-03-06)
New skill at `skills/video-director/` — AI storyboard writer + shot orchestrator.
- **6 subcommands**: storyboard, direct, reverse-prompt, review, learn, produce
- **Storyboard intelligence**: Gemini 2.5 Flash generates shot-by-shot JSON with model routing, cost estimates, and compound learnings applied
- **5 narrative templates**: hook-build-climax-cta, problem-solution, reveal, day-in-life, before-after
- **Model routing**: Kling v3 for food/texture, Sora 2 for UGC/people — decisions based on compound learnings
- **Budget calculator**: Pre-generation cost estimate (Kling ~$0.056/s standard, ~$0.14/s pro, Sora ~$0.10/s)
- **Assembly**: Normalizes clips (1080x1920, 30fps, yuv420p) → concat → single MP4
- **Review loop**: Gemini Vision QA against storyboard → feed into compound learnings
- **Key fix**: Previous 30s videos were bad because shots were random — now narrative-driven with beat assignments
- **Gemini model**: Use `gemini-2.5-flash` (NOT `gemini-2.0-flash` which 404s)
- **API key**: Load from `secrets/gemini.env` or `GOOGLE_API_KEY` from `.env`

#### Skill Crystallize (2026-03-06)
New skill at `skills/skill-crystallize/` — auto-turn workflows into reusable skills.
- **6 subcommands**: create, from-script, readme, publish, crystallize, scan
- **Bilingual README**: Auto-generates README.md (EN) + README.zh-CN.md (CN)
- **GitHub push**: Git add → commit → push to `Gaia-eats/gaia-os-skills` repo
- **Scan mode**: Finds crystallizable patterns in workspace scripts and KNOWLEDGE-SYNC
- **Daily cron**: Already wired at 10:35pm via `compound-crystallize.sh`

#### Memory-LanceDB-Pro Fixed (2026-03-06)
Was installed + enabled but producing ZERO data. Two fixes:
1. **OPENAI_API_KEY**: Was `${OPENAI_API_KEY}` placeholder in openclaw.json — gateway doesn't source .env files. Fixed: hardcoded actual key in config.
2. **Native module**: Missing `@lancedb/lancedb-darwin-x64`. Fixed: `npm install @lancedb/lancedb-darwin-x64` in extensions dir.
- Now: `embedding: OK, retrieval: OK, mode: hybrid, FTS: enabled`
- DB creating files at `~/.openclaw/memory/lancedb-pro/memories.lance`
- **Lesson**: Never use `${ENV_VAR}` in openclaw.json for gateway-started services — cron/gateway don't source .env files.

#### Kling v3 Fixes (2026-03-06)
- Model name: `kling-v3` (NOT `kling-v3-0` — API rejects old name)
- Direct API balance = $0 → Added fal.ai fallback: `fal-ai/kling-video/v3/standard/image-to-video`
- Local file upload: `fal_client.upload_file()` → public CDN URL for Kling
- fal_client env: Needs `FAL_KEY` (not `FAL_API_KEY`), fixed via `os.environ.setdefault`

#### Creative Taxonomy Skill (2026-03-06)
New skill at `skills/creative-taxonomy/` — composable classification system for ALL creative content.
- **5 dimensions**: structure (6 schemas), format (7 schemas), purpose (4 schemas), platform (4 schemas), production (3 schemas) = 24 total
- **Structures**: AIDA, PAS, SLAP, Emotional Story, Hero Journey, Listicle
- **Formats**: UGC Video, Carousel, Static Ad, Comic, Influencer Vlog, Podcast Clip, Story
- **Purposes**: Awareness, Conversion, Retargeting, Engagement
- **Platforms**: TikTok, IG Reels, IG Feed, YouTube Shorts (with safe zones, specs)
- **Production**: AI Generated, Real Footage, Hybrid
- **3 scripts**: discover-schemas.sh (auto-discover), classify-asset.sh (auto-classify), ingest-workflow.sh (import workflows)
- **Key**: Drop a JSON file in any dimension folder → auto-discovered, no code changes needed
- **Agent use**: Dreami reads structures, Iris reads formats+platforms, Hermes reads purposes, all tools use classify-asset.sh
- **Workflow ingestion**: `ingest-workflow.sh --source tricia --name ugc_video` decomposes any workflow into taxonomy dimensions
- **Validation**: 24/24 schemas valid, 49/49 routing tests pass

#### Video Compiler Skill (2026-03-06)
New skill at `skills/video-compiler/` — blends Tricia's WAT architecture with GAIA tools.
- **4 scripts**: video-compiler.sh (orchestrator), parallel-gen.py (5x concurrent video gen), video-review.sh (QA with contact sheets + motion-diff), script-gen.py (LLM script generation with 4 ad frameworks)
- **3 schemas**: block_schema.json (21 AIDA block codes), sequence_templates.json (7 video recipes), framework_templates.json (PAS/SLAP/UGC/Emotional)
- **Routing**: classify.sh routes to iris (SCRIPT tier). Keywords: "compile video ads", "ugc ad variants", "PAS/SLAP framework"
- **Pipeline**: BRIEF → SCRIPT → PLAN → GENERATE → PRODUCE → REVIEW → DELIVER
- **Cost**: ~$1.50-2.50 per 40s assembled ad, ~$0.40 per 12s single-shot
- **Modes**: assembled (multi-block), single-shot (12s), combinatorial (hooks × bodies)
- **Approval gates**: `--plan-only` generates scripts+plan, `--resume` continues from plan

#### ClipForge Bug Fixes (2026-03-06)
Fixed 5 bugs in clip-factory skill:
1. Sub-scores all 0 → Fixed Gemini multi-part response parsing (skip thinking parts, prefer most-complete JSON)
2. Export double-prefixing → Detect existing platform prefixes, move instead of re-export
3. Short video handling → Min 30s input, adaptive windows for <300s videos, hard clip limits 10-60s
4. Transcript dedup → Jaccard similarity >80% between consecutive segments removes duplicates
5. Portrait skip → Skip smart crop if height > width * 1.5

#### Compound Learning System (2026-03-06)
New 3-layer knowledge stack at `workspace/data/learnings/`:
- **Global** (`global/video-generation.json`): Universal rules — NO zoom, model strengths, camera rules. ALL brands.
- **Category** (`category/food-video.json`): Food physics — no morphing food, no gravity-defying sauce, spoon rules. ALL food brands.
- **Brand** (`brand/mirra.json`): Mirra-specific — bento style, salmon pink, product coverage gaps.
- **Resolver**: `python3 workspace/data/learnings/resolve-learnings.py --brand mirra --format flat` merges all 3 layers.
- **Rule**: Write to BROADEST applicable layer. Don't put global knowledge in brand files.
- **ALL agents** must read LEARNINGS-MAP.md and use resolver before generating content.
- SHARED-PROTOCOL.md section 3b updated with instructions for all agents.
- pinxin-vegan auto-inherits global + food-video rules — no brand file needed yet.

#### Video Regression Pipeline (2026-03-06)
New skill at `skills/video-regress/` — mass test video pipeline with feedback loop.
- `video-regress.sh` with 6 subcommands: matrix, run, qa, learn, report, full
- Notion Creative Review integration for human scoring (1-10)
- Structured learnings auto-digest from feedback
- First test: Sora 2 hero shot of Japanese Curry Katsu Rice (composite ref), sent to branding group
- Kling v3.0 needs public URLs — falls back to Sora for local refs

#### Regression Tests: 49/49 (2026-03-06)
Added 5 video-compiler tests. All 49 routing tests pass. `|| true` needed after `grep -oE` in pipefail scripts.

### Quick Reference for OpenClaw Taoz

**Dual Model System:**
- **Coordination (glm-4.7-flash):** Routes tasks, reads files, summarizes outputs, monitors system
- **Building (Claude Code Opus 4.6):** Actual code execution, debugging, complex builds

**Workflow:**
1. User task → OpenClaw Taoz (glm-4.7-flash) reads KNOWLEDGE-SYNC.md → coordinates
2. If code/build needed → fire Claude Code CLI → posts result → Argus regression
3. Claude Code writes learnings to KNOWLEDGE-SYNC.md
4. OpenClaw Taoz reads KNOWLEDGE-SYNC.md to stay current

**Command to spawn Claude Code CLI:**
```bash
bash ~/.openclaw/workspace/scripts/claude-code-runner.sh dispatch "TASK" zenni build
```

**Never forget:** READ KNOWLEDGE-SYNC.md first every session. It's your bridge to the powerful Claude Code brain.

### Running Tasks
- None active

### Issues to Watch
- None
## Build taoz-1772804812-31526 (2026-03-06 21:49) — success
- Task: Outlet: Whloey Wonder (Damai) Date: 6/3/26 Total Sales: RM 3,011.53 Actual Sales: RM 2288.09 Grabfood Sales: RM 723.44 Cash Sales: RM 63.3 E-wallet: R
- Model: sonnet | Duration: 90s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772843429-34091 (2026-03-07 08:32) — success
- Task: MORNING DISPATCH — Run morning routine: read rooms/feedback.jsonl and rooms/townhall.jsonl (last 24h), analyze for learnings, errors, wins, skill pr
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772890850-6786 (2026-03-07 21:41) — success
- Task: Outlet: Whloey Wonder (Damai) Date: 7/3/26 Total Sales: RM 4,899.18 Actual Sales: RM 4312.55 Grabfood Sales: RM 586.63 Cash Sales: RM 388.65 E-wallet:
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Gemini gemini-1772951971-14408 (2026-03-08 14:39) — success
- Task: Generate 3 short ad headlines for healthy bento meals targeting office workers. Max 40 chars each.
- Brand: mirra | Duration: 25s | Status: completed
- Result: YOLO mode is enabled. All tool calls will be automatically approved. Loaded cached credentials. YOLO mode is enabled. All tool calls will be automatically approved. ### 1. Content  *   **TIRED OF RM30 POKE? TRY RM19 BENTO.** (34 chars) *   **NO MORE OILY LUNCH. HOT & LOW KCAL.** (33 chars) *   **STO

## Gemini gemini-1772952693-46299 (2026-03-08 14:52) — success
- Task: Generate 5 ad headlines and 3 social captions for direction en-1. Include character counts. Follow brand voice.
- Brand: mirra | Duration: 30s | Status: completed
- Result: YOLO mode is enabled. All tool calls will be automatically approved. Loaded cached credentials. YOLO mode is enabled. All tool calls will be automatically approved. ### 1. Content  **Ad Headlines (Direction: en-1)** 1. **"RM30 for cold salmon cubes? *Banyak mahal, sis.* Get a hot MIRRA bento for RM1

## Gemini gemini-1772955088-29744 (2026-03-08 15:32) — success
- Task: Research the top 5 trending health food ad campaigns in Malaysia this week. For each, note: brand name, platform (Meta/TikTok/IG), ad format, estimate
- Brand: mirra | Duration: 45s | Status: completed
- Result: YOLO mode is enabled. All tool calls will be automatically approved. Loaded cached credentials. YOLO mode is enabled. All tool calls will be automatically approved. I will research the top 5 trending health food ad campaigns in Malaysia for early March 2026, focusing on platforms like Meta and TikTo

## Gemini gemini-1772974825-52912 (2026-03-08 21:00) — fail
- Task: Find the TOP 5 longest-running and most successful psychic/tarot reading ads on Facebook and TikTok. I need:
1. Advertiser names and their longest-run
- Brand: gaia-os | Duration: 30s | Status: completed
- Result: YOLO mode is enabled. All tool calls will be automatically approved. Loaded cached credentials. YOLO mode is enabled. All tool calls will be automatically approved. Error when talking to Gemini API Full report available at: /tmp/gemini-client-error-Turn.run-sendMessageStream-2026-03-08T13-00-52-685Z

## Build taoz-1772978323-4735 (2026-03-08 21:58) — success
- Task: Outlet: Whloey Wonder (Damai) Date: 8/3/26 Total Sales: RM 3,316.67 Actual Sales: RM 2884.15 Grabfood Sales: RM 432.52 Cash Sales: RM 639.1 E-wallet: 
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772986289-7184 (2026-03-09 00:11) — success
- Task: [media attached: /Users/jennwoeiloh/.openclaw/media/inbound/富贵花开_奇门财富---281f598f-5108-48ec-a96a-3ba68cab7052.pdf (application/pdf)]
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772986319-9120 (2026-03-09 00:12) — success
- Task: User sent a PDF document with Chinese reading club material about Dao De Jing and trend thinking, no explicit question yet
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772986348-13062 (2026-03-09 00:12) — success
- Task: [media attached: /Users/jennwoeiloh/.openclaw/media/inbound/富贵花开_密训资料_1---61e0a49f-858f-4637-8585-026f3943acee.pdf (application/pdf)]
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772986375-21782 (2026-03-09 00:13) — success
- Task: [media attached: /Users/jennwoeiloh/.openclaw/media/inbound/易商智慧_第二天弟子密训13---5cdd47b7-383b-40e7-be8b-b5c2887523ac.pdf (applicati
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772986434-36604 (2026-03-09 00:14) — success
- Task: [media attached: /Users/jennwoeiloh/.openclaw/media/inbound/风生水起_第一天下午---8db2d1aa-cddd-4f98-807f-13a7e48ef3c7.pdf (application/pdf)]
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772986545-57243 (2026-03-09 00:15) — success
- Task: [media attached: /Users/jennwoeiloh/.openclaw/media/inbound/1_第二节天干---6b556eb4-c7e5-4e32-845e-533f619f15af.pdf (application/pdf)]
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772986573-59547 (2026-03-09 00:16) — success
- Task: [media attached: /Users/jennwoeiloh/.openclaw/media/inbound/1_第三节地支---e8979d6b-5b06-49b8-8aee-ba459283088a.pdf (application/pdf)]
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772986601-69301 (2026-03-09 00:16) — success
- Task: [media attached: /Users/jennwoeiloh/.openclaw/media/inbound/1_第四节_九宫_最新---4a3db954-07bb-4d1d-b8a2-7a1a19b15c14.pdf (application/pdf)]
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772986651-85353 (2026-03-09 00:17) — success
- Task: [media attached: /Users/jennwoeiloh/.openclaw/media/inbound/风生水起_奇门64个符号资料---cd9b6ccb-a8c2-4905-8fb5-3556184c49ca.pdf (applicati
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772986706-96185 (2026-03-09 00:23) — success
- Task: Send to Claude code taoz
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772986718-266 (2026-03-09 00:23) — success
- Task: Can u scan all the conversation within Jenn with Claude code, probably on Claude.md or files that u can check, understand what we are building and we 
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772987333-59974 (2026-03-09 00:29) — success
- Task: Ask u to read knowledge-sync.md already in the iMac openclaw!
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772987425-67910 (2026-03-09 00:37) — success
- Task: Please know about this whole gaia os system, u no longer the zenni do the routing only, u become the super brain, please get the conversation and know
- Model: opus | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772993039-15406 (2026-03-09 02:04) — success
- Task: Yang set which of his agent with god prompt? And I love u to look into his persona for his agents, its mission, and how we could apply on us. And I lo
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1772992522-8989 (2026-03-09 02:21) — success
- Task: Read workspace-main/MISSION-JADE-ORACLE.md and start executing Phase 1. Dispatch D1 (brand copy for The Jade Oracle psychic reading business) to Dream
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1773027094-59110 (2026-03-09 11:36) — success
- Task: Use claude code to build Shopify webhook listener + automated reading pipeline for The Jade Oracle. Need order capture, QMDJ+tarot+western astrology r
- Model: opus | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1773035196-75737 (2026-03-09 13:50) — success
- Task: H1: Build Shopify store for The Jade Oracle at thejadeoracle.com. Products:  Intro Reading, .99 Quick Reading, .99 Deep Reading, .99 Birth Chart,  QMD
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1773114419-1502 (2026-03-10 11:47) — success
- Task: Jenn says: identify the very top 3 priorities to make GAIA OS alive and looping across missions/projects/businesses, then fire now and report results.
- Model: opus | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1773114966-21221 (2026-03-10 11:56) — success
- Task: Full scan my local operating rules and identify every instruction, keyword, phrase, or pattern that could bias Zenni toward not touching architecture,
- Model: opus | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1773115636-44805 (2026-03-10 12:24) — success
- Task: GAIA OS integrated repair pass. Fix the system to match Jenn's vision: mission-driven operating system, not chatbot. Priority order: (1) make Zenni ar
- Model: opus | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1773128886-24208 (2026-03-10 16:04) — success
- Task: **GAI-28 Track D: Paperclip Dashboard Hook**Build the integration between Boss Dashboard and Paperclip API.Requirements:
1. Boss dashboard (http://loc
- Model: sonnet | Duration: 5s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Gemini gemini-1773130805-55494 (2026-03-10 16:20) — fail
- Task: Create 5 ad copy variants for each of these Meta Ad Sets for JADE ORACLE brand. Tone: mystical, wise, compassionate. Brand: The Jade Oracle - ancient 
- Brand: jade-oracle | Duration: 20s | Status: completed
- Result: YOLO mode is enabled. All tool calls will be automatically approved. Loaded cached credentials. YOLO mode is enabled. All tool calls will be automatically approved. Error when talking to Gemini API Full report available at: /var/folders/sp/kgghbbkx4pz3s9xktl__sn1w0000gn/T/gemini-client-error-Turn.ru

## Build taoz-1773142151-97389 (2026-03-10 19:29) — success
- Task: Say hello and confirm you can see the openclaw directory
- Model: sonnet | Duration: 15s | Status: completed
- Result: Hello from Taoz! The `~/.openclaw` directory is fully visible and operational. I can see the core system components including `agents`, `brands`, `skills`, `workspace`, and all other canonical Zennith OS paths.  **Summary:** I confirmed the openclaw directory is accessible by listing its contents,

## Build taoz-1773145489-36999 (2026-03-10 20:43) — success
- Task: Build Wave 1 — GAIA Creative Studio foundation. Implement the highest-leverage real connection in Studio: Library + Taxonomy + Seed Bank truth layer
- Model: opus | Duration: 435s | Status: completed
- Result: Wave 1 shipped. Here's the summary:  **Built the Library ↔ Taxonomy ↔ Seed Bank truth layer.** Created a new `/api/taxonomy` endpoint that auto-discovers all 24 schemas across 5 dimensions (structures, formats, purposes, platforms, production) from the `creative-taxonomy` skill on disk. Added 5 

## Build taoz-1773150256-84896 (2026-03-10 21:52) — success
- Task: Implement the first real GAIA Creative Studio integration around the workflow spec at /Users/jennwoeiloh/.openclaw/workspace-main/COMFYUI-CHARACTER-MA
- Model: opus | Duration: 295s | Status: completed
- Result: Done. Here's the summary:  **Built the first real GAIA Creative Studio skill** (`skills/creative-studio/`) with 3 files: `SKILL.md` (skill definition with integration map), `workflows/comfyui-character-master-v1.json` (machine-readable workflow spec with 4 stages, reference stack schema, output labe

## Gemini gemini-1773187248-21857 (2026-03-11 08:01) — fail
- Task: Research and compile an innovation scout report for AI/agent tools. Sources to check:
1. GitHub Trending (AI/agents category) - find top 5 repositorie
- Brand: none | Duration: 20s | Status: completed
- Result: YOLO mode is enabled. All tool calls will be automatically approved. Loaded cached credentials. YOLO mode is enabled. All tool calls will be automatically approved. Error when talking to Gemini API Full report available at: /var/folders/sp/kgghbbkx4pz3s9xktl__sn1w0000gn/T/gemini-client-error-Turn.ru

## Build taoz-1773196268-22860 (2026-03-11 10:36) — success
- Task: SKIP HEARTBEAT — PRIORITY DISPATCH. Build the next concrete milestone for GAIAOS public shell. Input scope ONLY: /Users/jennwoeiloh/.openclaw/worksp
- Model: sonnet | Duration: 270s | Status: completed
- Result: Done. Here's what was delivered:  **Problem found:** Both API routes in `star-office` existed but were broken — pointing to `http://localhost:3101` (wrong port, with a typo "PAPERCLAP"). Star Office's React frontend was complete but had no working backend.  **Fix:** Rewrote `src/app/api/dashboard/

## Build taoz-1773211083-10563 (2026-03-11 14:44) — fail
- Task: SKIP HEARTBEAT — PRIORITY DISPATCH. Build the next concrete milestone for GAIAOS public shell. Scope ONLY: /Users/jennwoeiloh/.openclaw/workspace-ma
- Model: sonnet | Duration: 155s | Status: completed
- Result: **Done.** Here's what I delivered:  **Star Office staging is verified and ready.** The Next.js app at `/workspace-main/gaiaos/star-office/` builds clean (4.9s, 0 errors), serves on `http://localhost:8082`, returns HTTP 200 with live data — 80 sessions, 9 agents, gateway online. Mission 1 Track B +

## Build taoz-1773223340-73157 (2026-03-11 18:12) — success
- Task: SKIP HEARTBEAT — PRIORITY DISPATCH. MIRRA revenue > all else. Build P2 Attribution Pipeline for MIRRA inside /Users/jennwoeiloh/.openclaw/workspace-
- Model: sonnet | Duration: 220s | Status: completed
- Result: Done. Here's the summary:  **Files created:** - `/Users/jennwoeiloh/.openclaw/workspace-main/mirra/attribution-pipeline/README.md` — full architecture, 7-layer event flow diagram, UTM schema, handoff table, blocker matrix, 17-step implementation checklist - `utm-passthrough.js` — ready-to-drop l

## Build taoz-1773228631-69507 (2026-03-11 19:38) — success
- Task: SKIP HEARTBEAT — PRIORITY DISPATCH. MIRRA revenue > all else. Build P1 Chatwoot Lead Capture Activation for MIRRA. Scope ONLY: /Users/jennwoeiloh/.o
- Model: sonnet | Duration: 175s | Status: completed
- Result: **Done.** Three files delivered at `/workspace-main/mirra/chatwoot-lead-capture/`:  | File | Purpose | |------|---------| | `README.md` | Full activation doc: env keys, event flow diagram, 6-step setup, blocker matrix, verification checklist | | `widget-snippet.js` | Chatwoot widget embed + UTM capt

## Build taoz-1773255639-50008 (2026-03-12 03:05) — success
- Task: SKIP HEARTBEAT — PRIORITY DISPATCH. MIRRA revenue priority. Activate Chatwoot lead capture + attribution foundation for MIRRA. Scope: inspect existi
- Model: sonnet | Duration: 180s | Status: completed
- Result: `/Users/jennwoeiloh/.openclaw/workspace-main/memory/2026-03-12-mirra-chatwoot-attribution-plan.md`  Inspected all MIRRA/Chatwoot/attribution files in `workspace-main` — found complete architecture already built (widget code, n8n webhook, CAPI schema, UTM passthrough) but nothing deployed. Produced

## Build taoz-1773277379-955 (2026-03-12 09:08) — success
- Task: SKIP HEARTBEAT — PRIORITY DISPATCH. MIRRA revenue priority. Build the next concrete unblocked step for MIRRA Chatwoot lead capture activation. Scope
- Model: sonnet | Duration: 155s | Status: completed
- Result: Done. Here's what was delivered:  1. **`order.html` updated** — Embedded `widget-snippet.js` inline as a clearly delimited `STAGING BLOCK` before `</body>`. Both Chatwoot SDK and Meta Pixel are **hard-guarded** (`!== 'FILL_ME'`), so zero external calls fire until tokens are filled. UTM capture and

## Build taoz-1773289844-91728 (2026-03-12 12:35) — success
- Task: SKIP HEARTBEAT — PRIORITY DISPATCH. MIRRA revenue priority. Build the next concrete unblocked step for MIRRA lead capture activation. Scope ONLY: in
- Model: sonnet | Duration: 135s | Status: completed
- Result: Done. I explored all three MIRRA directories, read the widget script and existing execution brief to verify exact file paths, token placeholder names and line numbers, and what's embedded vs missing. I wrote the STAGING-HANDOFF.md at the exact path requested — it confirms `order.html` is the landi

## Build taoz-1773291663-47815 (2026-03-12 13:04) — success
- Task: SKIP HEARTBEAT — PRIORITY DISPATCH. MIRRA revenue is top priority. Build the highest-leverage next step: an attribution pipeline foundation for MIRR
- Model: sonnet | Duration: 55s | Status: completed
- Result: [Taoz] Task completed (no output captured).

## Build taoz-1773378904-96070 (2026-03-13 13:20) — success
- Task: SKIP HEARTBEAT — PRIORITY DISPATCH. Jade Oracle reading delivery pipeline. Scope: work only inside /Users/jennwoeiloh/.openclaw/workspace-main/jade-
- Model: sonnet | Duration: 5s | Status: completed
- Result: Not logged in · Please run /login

## Build taoz-1773379353-8843 (2026-03-13 13:22) — success
- Task: SKIP HEARTBEAT — PRIORITY DISPATCH. Previous run failed with 'Not logged in'. New scope: read-only analysis first, then create ONLY documentation ar
- Model: sonnet | Duration: 5s | Status: completed
- Result: Not logged in · Please run /login

## Gemini gemini-1773464358-93911 (2026-03-14 12:59) — fail
- Task: Scout AI innovations for GAIA CORP (e-commerce/F&B/automation company). Check:

1. GITHUB TRENDING (trending page for AI/ML): Top 5 trending AI/ML rep
- Brand: none | Duration: 15s | Status: completed
- Result: YOLO mode is enabled. All tool calls will be automatically approved. Loaded cached credentials. YOLO mode is enabled. All tool calls will be automatically approved. Error when talking to Gemini API Full report available at: /tmp/gemini-client-error-Turn.run-sendMessageStream-2026-03-14T04-59-33-251Z

## Build taoz-1773751682-23228 (2026-03-17 20:52) — success
- Task: Please build an interpreter or extractor for this Qimen Dunjia (Qi Men Dun Jia) chart image. Focus on extracting the Ba Men (8 Doors), Jiu Xing (9 Sta
- Model: sonnet | Duration: 235s | Status: completed
- Result: Rigour gate: PASS. Done.  ---  **What was built:**  1. **`qmdj-chart-extract.py`** — A Python extractor with two modes: `manual` (uses embedded parsed data matched by filename UUID) and `vision` (calls Gemini Vision API for unknown charts). It validates against full QMDJ domain knowledge (Ba Men, 

## Build taoz-1773755210-51500 (2026-03-17 21:48) — success
- Task: Please process this QMDJ PDF about wealth reading into the knowledge base: /Users/jennwoeiloh/.openclaw/media/inbound/富贵花开_奇门财富---20ad
- Model: sonnet | Duration: 85s | Status: completed
- Result: Done. Here's what was processed:  **PDF:** 富贵花开_奇门财富 (QMDJ Wealth Reading)  **Changes to `skills/psychic-reading-engine/data/qmdj-knowledge.json`:**  The `wealth_patterns` section was enriched with the full PDF content: 1. **Wu capital analysis** — complete 9-combination table (墓

## Build taoz-1773755342-56830 (2026-03-17 21:59) — success
- Task: Process these 14 QMDJ and Chinese metaphysics PDFs into the knowledge base: 
1. /Users/jennwoeiloh/.openclaw/media/inbound/读书会_资料---c920ec52
- Model: sonnet | Duration: 600s | Status: timeout
- Result: [Taoz] Task timed out (600s). Result may be partial — check /Users/jennwoeiloh/.openclaw/workspace/data/taoz-results/taoz-1773755342-56830.txt

## Build taoz-1773755458-61010 (2026-03-17 22:00) — success
- Task: Please process these newly added QMDJ and Chinese metaphysics PDFs into the knowledge base: 
1. /Users/jennwoeiloh/.openclaw/media/inbound/读书会_�
- Model: sonnet | Duration: 550s | Status: completed
- Result: Done. Here's the summary:  **15 PDFs processed, 12 successfully ingested:** - 12 vault.db entries added (2825 → 2837 total) - `qmdj-knowledge.json` grew from 72,966 → 86,419 bytes (+18.4%)  **3 PDFs skipped:** 2 were scanned/image-only (no extractable text), 1 was a Buddhist event schedule (not 

## Build taoz-1773756244-81906 (2026-03-17 22:09) — success
- Task: Please build an interpreter/extractor for this Qimen Dunjia (Qi Men Dun Jia) chart image, focusing on extracting the Ba Men (8 Doors), Jiu Xing (9 Sta
- Model: sonnet | Duration: 295s | Status: completed
- Result: ---  **Summary:**  The image at `277bd5fcbd4559fd97cbc0110bf5207e.JPG` is **not a QMDJ nine-palace chart** — Gemini Vision confirmed it's a **Liu Yao (六爻) Na Jia reference table** showing Ganzhi (干支) assignments for each of the six yao lines across the 10 Heavenly Stems, plus yao archetype

## Build taoz-1773756455-84156 (2026-03-17 22:15) — success
- Task: Please extract the QMDJ data (Ba Men, Jiu Xing, Ba Shen, Tian Gan) from these 3 newly uploaded chart images/files and add them to the knowledge base: 
- Model: sonnet | Duration: 480s | Status: completed
- Result: Done. Here's what was extracted and added to the knowledge base:  **File created:** `skills/psychic-reading-engine/data/chart-symbols-extracted.json` (40KB)  **9 structured sections extracted:**  | Section | Content | |---|---| | `ba_men` | 8 gates — keywords, auspicious levels, careers, feng shui

## Build taoz-1773759407-26146 (2026-03-17 23:05) — success
- Task: Please process this newly added QMDJ PDF about Ten Stems (十干克应) into the knowledge base: /Users/jennwoeiloh/.openclaw/media/inbound/1_第八�
- Model: sonnet | Duration: 505s | Status: completed
- Result: Done. Here's what was completed:  1. **Extracted all 4 pages** of the 第八节 十干克应 PDF (image-based, read visually) — covering the complete 乙木 (Yi Wood) section with 9 stem combinations.  2. **Updated `qmdj-knowledge.json` → v2.1** — enriched all 乙加乙 through 乙加癸 entri

## Build taoz-1773759531-27333 (2026-03-17 23:08) — success
- Task: Please process this second QMDJ PDF (Focus: Geng Metal 十干克应) into the knowledge base: /Users/jennwoeiloh/.openclaw/media/inbound/2_第八节_�
- Model: sonnet | Duration: 600s | Status: timeout
- Result: [Taoz] Task timed out (600s). Result may be partial — check /Users/jennwoeiloh/.openclaw/workspace/data/taoz-results/taoz-1773759531-27333.txt
