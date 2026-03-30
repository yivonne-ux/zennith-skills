# Collaboration System — 3 People, 1 Brain
## Yi-Vonne (Jenn) + Tricia + [Third Collaborator]
## Version 1.0 | 2026-03-30

---

## THE PROBLEM

3 people building skills, intelligence, and content for the same brands.
Without a system: files scatter, knowledge duplicates, work conflicts.

## THE SOLUTION

```
┌─────────────────────────────────────────────────────────────────┐
│                     SINGLE SOURCE OF TRUTH                       │
│                                                                  │
│   GitHub (zennith-skills)          Google Drive (Zennith)        │
│   ├── skills/        (CODE)       ├── Brand Assets/  (BINARY)   │
│   ├── brands/        (DNA)        ├── Exports/       (OUTPUTS)  │
│   ├── workspace-*/   (MEMORY)     ├── References/    (IMAGES)   │
│   ├── projects/      (SYSTEMS)    └── Client Files/  (DOCS)     │
│   └── intelligence/  (NEW)                                       │
│                                                                  │
│   WHAT GOES WHERE:                                               │
│   • Text/code/intelligence → GitHub (versioned, mergeable)       │
│   • Images/video/assets → Google Drive (large files, shareable)  │
│   • Both sync to local _WORK/ for production                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## TWO SYSTEMS, CLEAR SPLIT

### GITHUB (zennith-skills) — Code + Intelligence + Skills
**What goes here:** Anything TEXT-BASED that benefits from version control.

```
zennith-skills/
├── skills/                    ← Reusable AI skills (86+ and growing)
│   ├── ads-meta/              ← Meta Ads automation skill
│   ├── brand-studio/          ← Brand content generation
│   ├── social-engine/         ← Social media production
│   └── [new-skill]/           ← Anyone can add
│
├── brands/                    ← Brand DNA files (14 brands)
│   ├── mirra/DNA.json         ← Brand config
│   ├── pinxin-vegan/DNA.json
│   └── [new-brand]/
│
├── intelligence/              ← NEW: Shared intelligence layer
│   ├── MARKETING-SALES-INTELLIGENCE.md
│   ├── FILING-SYSTEM.md
│   ├── BRAND-ONBOARDING-STANDARD.md
│   ├── meta-ads/              ← Universal Meta research
│   ├── creative-automation/   ← AI automation research
│   ├── design/                ← Design research
│   └── compound-learnings/    ← Cross-brand learnings
│
├── projects/                  ← Active project systems
│   ├── apex-meta/             ← Meta Ads automation platform
│   ├── mirra-menu-pipeline/   ← Menu generation
│   └── video-engine/          ← NEW: Tricia's video automation
│
├── workspace-yivonne/         ← Jenn's memory + knowledge
├── workspace-tricia/          ← NEW: Tricia's memory + knowledge
├── workspace-main/            ← Shared agent workspace
└── CLAUDE.md                  ← Agent system docs
```

### GOOGLE DRIVE (Zennith) — Assets + Exports + References
**What goes here:** Binary files (images, video, fonts, PDFs) that are too large for git.

```
Google Drive: Zennith/
├── Brands/
│   ├── Mirra/
│   │   ├── Assets/            ← Logos, fonts, food photos
│   │   ├── References/        ← Curated ref images (FORMAT/AESTHETIC/CONTENT)
│   │   ├── Exports/           ← Production outputs (social, campaigns, video)
│   │   └── Client Files/      ← Invoices, contracts, raw client materials
│   ├── Pinxin/
│   │   ├── Assets/
│   │   ├── References/
│   │   ├── Exports/
│   │   └── Client Files/
│   ├── DotDot/
│   └── Bloom & Bare/
│
├── Shared/
│   ├── Templates/             ← Universal templates
│   ├── Fonts/                 ← Shared font library
│   └── Stock/                 ← Shared stock images
│
└── Archive/                   ← Old/rejected outputs (extracted learnings first)
```

---

## HOW THE 3 PEOPLE WORK

### Yi-Vonne (Jenn) — Marketing + Creative Intelligence
**Owns:** Brand strategy, Meta Ads, social content production, creative intelligence
**Works in:** `_WORK/[brand]/` locally, syncs intelligence to GitHub
**Tools:** Claude Code, NANO, PIL, Meta Graph API, autoads cron

### Tricia — Video Production Engine
**Owns:** Video automation, camera AI, editing pipeline, video templates
**Works in:** Her local machine, syncs to GitHub `projects/video-engine/`
**Tools:** FFmpeg, Sora, video AI models, Claude Code

### [Third] — TBD
**Owns:** TBD
**Works in:** Their local machine, syncs to GitHub

### Shared Ground Rules
1. **Push to GitHub daily** — intelligence, skills, learnings, code
2. **Push assets to GDrive** — images, video, large exports
3. **Never work on same file simultaneously** — use branches or communicate
4. **Own your workspace** — `workspace-yivonne/`, `workspace-tricia/`
5. **Share intelligence** — if it helps 2+ brands, it goes in `intelligence/`
6. **Skills are reusable** — build once, use across brands

---

## DAILY WORKFLOW

### Morning (sync)
```
1. git pull origin main          ← Get latest from everyone
2. Check GDrive sync             ← New assets/exports from others?
3. Read COMPOUND-LEDGER changes  ← What did others learn yesterday?
```

### During work (create)
```
4. Work in your local _WORK/[brand]/ folder
5. Follow FILING-SYSTEM.md for every new file
6. Build new skills in zennith-skills/skills/[name]/
7. Save learnings to your workspace-[name]/knowledge/memory/
```

### End of day (push)
```
8. git add + commit + push       ← Push intelligence, skills, learnings
9. Upload new exports to GDrive  ← Push images, video, assets
10. Update COMPOUND-LEDGER       ← What you learned today
```

---

## ADDING NEW SKILLS

Anyone can create a new skill. Follow this structure:

```
skills/[skill-name]/
├── SKILL.md              ← What it does, when to use it
├── [skill-name].py       ← Main script (or .js, .sh)
├── config.json           ← Skill configuration (optional)
└── examples/             ← Example inputs/outputs (optional)
```

**Rules:**
- Skill name = lowercase-with-hyphens
- SKILL.md is required (what, when, how)
- Must work independently (no hard dependencies on other skills)
- If brand-specific, put in `brands/[brand]/skills/` instead

---

## ADDING NEW INTELLIGENCE

When you learn something that applies to 2+ brands:

```
1. Write it in intelligence/[topic].md
2. If it's a RULE → add to intelligence/compound-learnings/
3. If it's RESEARCH → add to intelligence/[meta-ads|design|creative-automation]/
4. git commit + push
5. Others pull and have the knowledge
```

**Intelligence vs Memory:**
- **Intelligence** (GitHub) = universal knowledge, shared across team
- **Memory** (workspace-[name]/) = personal context, session handoffs, per-person learning style

---

## SYNCING LOCAL _WORK/ WITH GITHUB + GDRIVE

### What syncs to GitHub (via git)
```
_WORK/_shared/
├── FILING-SYSTEM.md              → intelligence/FILING-SYSTEM.md
├── BRAND-ONBOARDING-STANDARD.md  → intelligence/BRAND-ONBOARDING-STANDARD.md
├── MARKETING-SALES-INTELLIGENCE.md → intelligence/MARKETING-SALES-INTELLIGENCE.md
├── creative-intelligence/autoads/ → projects/apex-meta/autoads/
└── 03_research/                   → intelligence/[topic]/
```

### What syncs to GDrive (via GDrive desktop app)
```
_WORK/[brand]/01_assets/         → GDrive: Brands/[Brand]/Assets/
_WORK/[brand]/04_references/     → GDrive: Brands/[Brand]/References/
_WORK/[brand]/06_exports/        → GDrive: Brands/[Brand]/Exports/
```

### What stays LOCAL only
```
_WORK/[brand]/05_scripts/        ← Production scripts (in git, not GDrive)
_WORK/[brand]/07_working/        ← Temp files, never synced
/tmp/                            ← Throwaway
```

---

## GIT WORKFLOW

### Branches
```
main                ← Production. Always stable.
yivonne/[feature]   ← Jenn's feature branches
tricia/[feature]    ← Tricia's feature branches
```

### Commit Messages
```
[brand] [type]: description

Examples:
mirra skill: add social-engine v2 production pipeline
pinxin intelligence: compound learnings from W3 batch
shared research: meta ads andromeda entity ID findings
tricia video: add video-engine project with FFmpeg pipeline
```

### Pull Request Flow
```
1. Create branch: git checkout -b yivonne/mirra-social-engine
2. Work, commit, push
3. Create PR → other person reviews
4. Merge to main
5. Everyone pulls
```

For SMALL changes (typo fixes, daily compound ledger updates):
```
Direct commit to main is OK. No PR needed.
```

---

## GOOGLE DRIVE SETUP

### Shared Folder
**URL:** https://drive.google.com/drive/u/5/folders/1BN_mDlVyfRybPG3RaKQUV3b5Mjka95wm

### How to Sync Locally
1. Open Google Drive for Desktop
2. Right-click the Zennith shared folder → "Add shortcut to Drive"
3. It syncs to: `~/Library/CloudStorage/GoogleDrive-[email]/My Drive/Zennith/`
4. OR use "Folders from my computer" to sync `_WORK/[brand]/01_assets/` up

### Folder Structure to Create
```
Zennith (Shared Drive or Shared Folder)
├── README.md (link to this doc)
├── Brands/
│   ├── Mirra/
│   │   ├── Assets/
│   │   │   ├── logos/
│   │   │   ├── fonts/
│   │   │   ├── food-library/
│   │   │   └── testimonials/
│   │   ├── References/
│   │   │   ├── FORMAT/
│   │   │   ├── AESTHETIC/
│   │   │   ├── CONTENT/
│   │   │   └── ads-library/
│   │   ├── Exports/
│   │   │   ├── social/
│   │   │   ├── campaigns/
│   │   │   └── video/
│   │   └── Client/
│   ├── Pinxin/
│   │   └── (same structure)
│   ├── DotDot/
│   │   └── (same structure)
│   └── Bloom & Bare/
│       └── (same structure)
├── Shared/
│   ├── Templates/
│   ├── Fonts/
│   └── Stock/
└── Archive/
    └── (old exports, extracted learnings first, then moved here)
```

### Access
- Yi-Vonne: Owner (full access)
- Tricia: Editor (read/write)
- [Third]: Editor (read/write)
- All use Google Drive for Desktop → auto-syncs to local

---

## ONBOARDING A NEW COLLABORATOR

```
1. Add them to GitHub repo (collaborator access)
2. Add them to GDrive shared folder (editor access)
3. Create their workspace: workspace-[name]/ in zennith-skills
4. They read (in order):
   a. COLLABORATION-SYSTEM.md (this file)
   b. FILING-SYSTEM.md (where files go)
   c. BRAND-ONBOARDING-STANDARD.md (folder structure)
   d. MARKETING-SALES-INTELLIGENCE.md (strategy)
5. They clone the repo: git clone https://github.com/jennwoei316/zennith-skills.git
6. They set up GDrive for Desktop
7. They're ready to work
```

---

## GOLDEN RULE: ADD-ONLY, NEVER EDIT OTHERS

```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│   YOU CAN:                                               │
│   ✅ ADD new files (skills, research, learnings)         │
│   ✅ ADD new folders                                     │
│   ✅ EDIT your OWN files (workspace-[you]/, your skills) │
│   ✅ ADD to intelligence/ (new research, new learnings)  │
│                                                          │
│   YOU CANNOT:                                            │
│   ❌ EDIT someone else's files                           │
│   ❌ DELETE someone else's files                         │
│   ❌ RENAME someone else's files                         │
│   ❌ MOVE someone else's files                           │
│                                                          │
│   IF YOU FIND AN ISSUE:                                  │
│   💬 Message the owner on WhatsApp/Telegram              │
│   💬 Or create a GitHub Issue                            │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Ownership Map

| Path | Owner | Others Can |
|------|-------|-----------|
| `workspace-yivonne/` | Jenn | READ only |
| `workspace-tricia/` | Tricia | READ only |
| `skills/[skill-name]/` | Whoever created it | READ only. Fork to create variant. |
| `brands/[brand]/DNA.json` | Jenn (brand owner) | READ only |
| `intelligence/` | Shared (ADD-only) | ADD new files. NEVER edit existing. |
| `intelligence/compound-learnings/` | Shared (ADD-only) | ADD your learnings as new file. |
| `projects/apex-meta/` | Jenn | READ only |
| `projects/video-engine/` | Tricia | READ only |

### How Merging Works

**New skill or research?**
→ ADD it as a new file. Push. Everyone pulls. Done.

**Updating shared intelligence?**
→ ADD a new dated file (e.g., `compound-learnings/2026-03-30-mirra-batch2.md`)
→ DON'T edit the existing MARKETING-SALES-INTELLIGENCE.md directly
→ The owner (Jenn) merges new learnings into the master doc periodically

**Found a bug in someone's script?**
→ Message them. DON'T fix it yourself.

**Want to improve someone's skill?**
→ Fork it: copy to `skills/[skill-name]-v2/` under YOUR name
→ Or message them and they update their own

### Google Drive Same Rules
- Your exports → your brand's Exports/ folder
- Your assets → your brand's Assets/ folder
- NEVER delete or overwrite another person's files
- If something looks wrong → message, don't delete

## CONFLICT RESOLUTION

| Situation | Resolution |
|-----------|-----------|
| Want to change shared intelligence | ADD new file with your finding. Owner merges. |
| Disagreement on strategy | Discuss in person/WA. Brand owner decides. |
| Skill overlap | Keep both. Or message to merge collaboratively. |
| Brand file in wrong location | Message the owner. They move it. |
| New intelligence contradicts old | ADD your finding as dated file. Owner reconciles. |
| Accidental edit of other's file | `git revert` immediately. Notify the person. |

---

*Three people, one brain. GitHub for intelligence. GDrive for assets. Local for production.*
*Push daily. Pull daily. Learn together. Never duplicate.*
