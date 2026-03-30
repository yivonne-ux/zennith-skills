# Zennith Skills — Repo Map
## What every folder is. Read this if you're new or lost.
## Last updated: 2026-03-30

---

## QUICK ANSWER: WHERE DO I PUT MY FILE?

| I want to... | Go to |
|-------------|-------|
| Add a reusable AI skill | `skills/[skill-name]/` |
| Add shared knowledge/research | `intelligence/[topic]/` |
| Add brand DNA or config | `brands/[brand-name]/` |
| Save my personal learnings | `workspace-[myname]/knowledge/memory/` |
| Build a project/system | `projects/[project-name]/` |
| Read how to file things | `intelligence/FILING-SYSTEM.md` |
| Read how we collaborate | `intelligence/COLLABORATION-SYSTEM.md` |
| Read the full OS blueprint | `ZENNITH-OS-BLUEPRINT.md` |

---

## FOLDER-BY-FOLDER GUIDE

### `skills/` — Reusable AI Skills (86+)
**What:** Self-contained capabilities any agent can use.
**Who adds:** Anyone. Follow the naming convention.
**Structure per skill:**
```
skills/[skill-name]/
├── SKILL.md       ← What it does, when to use, how to run
├── *.py / *.sh    ← The actual script(s)
└── config.json    ← Optional configuration
```
**Examples:** `ads-meta/` (Meta Ads), `brand-studio/` (content gen), `remotion-renderer/` (video), `product-studio/` (product shots)

**Rule:** Skill name = lowercase-with-hyphens. SKILL.md is required.

---

### `intelligence/` — Shared Knowledge (NEW)
**What:** Universal knowledge that helps ALL brands and ALL collaborators.
**Who adds:** Anyone (ADD-only, never edit others' files).
**Structure:**
```
intelligence/
├── FILING-SYSTEM.md                 ← Where every file goes
├── COLLABORATION-SYSTEM.md          ← How 3 people work together
├── BRAND-ONBOARDING-STANDARD.md     ← Standard folder structure per brand
├── MARKETING-SALES-INTELLIGENCE.md  ← Marketing/ads master strategy
├── meta-ads/                        ← Meta Ads platform research
├── design/                          ← Design research & techniques
├── creative-automation/             ← AI automation research
└── compound-learnings/              ← Cross-brand learnings (dated files)
```

**Rule:** If it helps 2+ brands, it goes here. If it's brand-specific, it goes in `brands/` or your `workspace-*/`.

---

### `brands/` — Brand DNA Files (14 brands)
**What:** Brand identity, config, and DNA for each brand.
**Who edits:** Brand owner only (Jenn for most brands).
**Structure per brand:**
```
brands/[brand-name]/
├── DNA.json              ← Brand config (colors, voice, audience, channels)
├── onboarding-status.json ← Onboarding checklist status
├── moods/                ← Mood presets (optional, Gaia brands have 6)
├── assets/               ← Brand-specific assets (optional)
└── skills/               ← Brand-specific skills (optional)
```

**Current brands:** dr-stan, gaia-eats, gaia-learn, gaia-os, gaia-print, gaia-recipes, gaia-supplements, iris, jade-oracle, luna, mirra, pinxin-vegan, rasaya, serein, wholey-wonder

---

### `projects/` — Active Systems & Platforms
**What:** Larger systems that are more than a single skill.
**Who owns:** Listed in each project's README.
**Current projects:**
```
projects/
├── apex-meta/           ← Meta Ads automation platform (Owner: Jenn)
├── mirra-menu-pipeline/ ← Monthly menu generation (Owner: Jenn)
├── style-kingdom/       ← Roblox game project (Owner: Tricia/Taoz)
└── video-engine/        ← Video automation engine (Owner: Tricia)
```

**Rule:** Each project has a README.md with owner, status, and integration points.

---

### `workspace-[name]/` — Personal Workspaces
**What:** Your memory, research, and session context. Private to you.
**Who edits:** ONLY the owner. Others can READ but never WRITE.
**Structure:**
```
workspace-[name]/
├── knowledge/
│   ├── memory/     ← Compound learnings (.md files)
│   └── research/   ← Research outputs
└── README.md       ← What's in your workspace
```

**Current workspaces:**
- `workspace-yivonne/` — Jenn's 134 memory files, 7,730 lines of compound learnings
- `workspace-tricia/` — Tricia's workspace
- `workspace-main/` — Shared agent (Zenni) workspace
- `workspace-dreami/` — Creative director agent
- `workspace-jade/` — Jade Oracle agent
- `workspace-taoz/` — CTO agent
- `workspace-scout/` — Scout agent
- `workspace-myrmidons/` — Bulk operations agent
- `workspace/` — Central knowledge base (product research, supplier data)

---

### `bin/` — Utility Scripts
**What:** Helper scripts for system operations.
**Examples:** Launcher scripts, deployment helpers.

---

### `grab-listing-optimizer/` — Grab Listing Tool
**What:** Grab Malaysia listing optimization with benchmarks.
**Status:** Active development.

---

### `.github/` — GitHub Configuration
**What:** Repository settings.
- `CODEOWNERS` — Who approves changes to which files.

---

### `.claude/` — Claude Code Configuration
**What:** Claude Code agent settings for this repo.
- `settings.json` — Model and permission config.
- `launch.json` — Launch configuration.

---

## ROOT FILES

| File | What It Is |
|------|-----------|
| `CLAUDE.md` | Agent system context (auto-generated from openclaw.json) |
| `ZENNITH-OS-BLUEPRINT.md` | THE master blueprint. Read FIRST every session. |
| `REPO-MAP.md` | THIS FILE. What every folder is for. |
| `.gitignore` | Files that should never be committed (tokens, large binaries) |
| `PROJECT-STATE.md` | Project overview and current state |
| `TEAM-WORKFLOW.md` | Team processes |

---

## THE ADD-ONLY RULE

```
✅ You CAN:
   - ADD new files anywhere you have ownership
   - ADD new skills to skills/
   - ADD new research to intelligence/
   - EDIT files in YOUR workspace-[name]/
   - EDIT files in YOUR projects/

❌ You CANNOT:
   - EDIT someone else's files
   - DELETE someone else's files
   - RENAME or MOVE someone else's files
   - Overwrite existing intelligence/ docs (add new dated files instead)

💬 If you find an issue in someone else's file:
   - Message them on WhatsApp/Telegram
   - Or create a GitHub Issue
```

---

## GOOGLE DRIVE (for binary files)

**URL:** https://drive.google.com/drive/u/5/folders/1BN_mDlVyfRybPG3RaKQUV3b5Mjka95wm

**What goes on GDrive (NOT GitHub):**
- Images (PNG, JPG, WebP)
- Video (MP4, MOV)
- Fonts (TTF, OTF)
- Design files (PSD, AI)
- Large exports

**What goes on GitHub (NOT GDrive):**
- Code (.py, .js, .sh)
- Documentation (.md)
- Configuration (.json)
- Intelligence & research (.md)

---

*Lost? Start with `ZENNITH-OS-BLUEPRINT.md` for the big picture, or `intelligence/FILING-SYSTEM.md` for where to put things.*
