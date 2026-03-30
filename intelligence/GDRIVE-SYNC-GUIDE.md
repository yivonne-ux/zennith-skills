# Google Drive Sync Guide
## What uploads where. How to keep GDrive = local _WORK/.
## Version 1.0 | 2026-03-30

---

## THE RULE: GDrive mirrors _WORK/ by FOLDER structure

```
LOCAL                              GOOGLE DRIVE
_WORK/                             Zennith/
├── mirra/                         ├── Mirra/
│   ├── 00_brand-guide/            │   ├── 00_brand-guide/
│   ├── 01_assets/                 │   ├── 01_assets/
│   ├── 02_strategy/               │   ├── 02_strategy/
│   ├── 03_research/               │   ├── 03_research/
│   ├── 04_references/             │   ├── 04_references/
│   ├── 05_scripts/                │   ├── 05_scripts/
│   ├── 06_exports/                │   ├── 06_exports/
│   └── 07_working/                │   └── (NOT synced — temp files)
├── pinxin/                        ├── Pinxin/
├── dotdot/                        ├── DotDot/
├── bloom-bare/                    ├── Bloom & Bare/
└── _shared/                       └── _Shared/
    ├── intelligence/              │   ├── intelligence/ (also on GitHub)
    └── creative-intelligence/     │   └── creative-intelligence/
```

---

## WHAT UPLOADS vs WHAT DOESN'T

### UPLOAD TO GDRIVE (binary + docs + everything except temp)

| Folder | Upload? | Why |
|--------|---------|-----|
| `00_brand-guide/` | ✅ YES | Brand DNA, guidelines — everyone needs access |
| `01_assets/` | ✅ YES | Logos, fonts, photos, mascots — production assets |
| `02_strategy/` | ✅ YES | Strategy docs — team needs to read |
| `03_research/` | ✅ YES | Research — team reference |
| `04_references/` | ✅ YES | Reference images — production pipeline needs them |
| `05_scripts/` | ✅ YES | Scripts — also on GitHub, GDrive is backup |
| `06_exports/` | ✅ YES | Production outputs — team needs to review/use |
| `07_working/` | ❌ NO | Temp files, archived scripts — local only |
| `_shared/intelligence/` | ✅ YES | Also on GitHub — GDrive is extra access point |

### SPECIAL CASES

| Case | What to do |
|------|-----------|
| `pinxin/01_assets/gdrive-sync/` | ALREADY ON GDRIVE — don't re-upload (30GB) |
| `07_working/_archived_scripts/` | DON'T upload — archived, local-only |
| `06_exports/_archive/` | DON'T upload — old versions, local-only |
| `.env`, `.meta-token*` | NEVER upload — security risk |
| `.DS_Store` | NEVER upload — macOS junk |

---

## HOW TO SYNC (Google Drive for Desktop)

### Option A: "Folders from my computer" (RECOMMENDED)
1. Open Google Drive for Desktop preferences
2. Click "Add folder"
3. Add each brand folder: `~/Desktop/_WORK/mirra/`, `~/Desktop/_WORK/pinxin/`, etc.
4. Choose "Sync with Google Drive" → select Zennith shared folder as destination
5. Exclude: `07_working/`, `_archived_*`, `.env`, `.DS_Store`

### Option B: Manual upload (first time)
1. Open https://drive.google.com/drive/u/5/folders/1BN_mDlVyfRybPG3RaKQUV3b5Mjka95wm
2. Create brand folders matching the structure above
3. Upload each numbered folder (00-06) per brand
4. Skip 07_working/

### Option C: rclone (for large initial sync)
```bash
# Install rclone
brew install rclone
# Or: curl https://rclone.org/install.sh | sudo bash

# Configure Google Drive remote
rclone config
# → New remote → name: zennith → type: drive → follow auth flow

# Sync each brand (excluding temp/archive)
rclone sync ~/Desktop/_WORK/mirra/ zennith:Zennith/Mirra/ \
  --exclude "07_working/**" \
  --exclude "_archived_*/**" \
  --exclude ".env" \
  --exclude ".DS_Store" \
  --exclude "*.pyc" \
  --progress

rclone sync ~/Desktop/_WORK/pinxin/ zennith:Zennith/Pinxin/ \
  --exclude "07_working/**" \
  --exclude "_archived_*/**" \
  --exclude "01_assets/gdrive-sync/**" \
  --exclude ".env" \
  --exclude ".DS_Store" \
  --progress

rclone sync ~/Desktop/_WORK/dotdot/ zennith:Zennith/DotDot/ \
  --exclude "07_working/**" \
  --exclude ".DS_Store" \
  --progress

rclone sync ~/Desktop/_WORK/bloom-bare/ zennith:Zennith/Bloom\ \&\ Bare/ \
  --exclude "07_working/**" \
  --exclude ".DS_Store" \
  --progress

rclone sync ~/Desktop/_WORK/_shared/ zennith:Zennith/_Shared/ \
  --exclude ".DS_Store" \
  --progress
```

---

## ONGOING SYNC RULES

### After every production batch:
```
1. New exports in 06_exports/ → auto-syncs if using GDrive for Desktop
   OR manually upload the new week folder
2. New strategy docs → auto-syncs or manually upload
3. New reference images → upload to 04_references/[correct subfolder]
```

### After every intelligence update:
```
1. Push to GitHub (git add + commit + push)
2. GDrive auto-syncs if intelligence/ is in the sync path
   OR copy updated .md files to GDrive manually
```

### After cleanup/archival:
```
1. Archived files moved to 07_working/ → NOT synced to GDrive
2. Deleted files → delete from GDrive too (or let sync handle it)
```

---

## LEARNINGS & INTELLIGENCE — DUAL SYNC

Learnings live in TWO places (intentionally):

| Location | What | Who accesses |
|----------|------|-------------|
| **GitHub** `intelligence/` | Universal research, compound learnings | All collaborators via git pull |
| **GitHub** `workspace-[name]/knowledge/memory/` | Personal learnings | Owner only |
| **GDrive** `_Shared/intelligence/` | Mirror of GitHub intelligence/ | Non-git users, mobile access |
| **Local** `~/.claude/projects/*/memory/` | Claude Code session memory | Claude Code agent only |

### Why dual?
- **GitHub** = versioned, mergeable, diff-able (for developers)
- **GDrive** = accessible from phone, shareable link, no git needed (for everyone)
- **Local memory** = fast agent access during production sessions

### How to keep in sync:
1. Write learning locally (Claude Code saves to memory/)
2. Important learnings → also push to GitHub `intelligence/compound-learnings/`
3. GDrive auto-syncs from local if configured, OR copy manually

---

## PIPELINE & PRODUCTION OUTPUTS

### Social media posts (per brand):
```
06_exports/social/
├── week-2026-03-30/      ← Current week
│   ├── pending_posts.json ← Schedule queue
│   ├── PXW-01.png         ← Production images
│   └── ...
├── week-2026-04-06/      ← Next week
└── published_log.json    ← What's been published

→ GDrive: Zennith/[Brand]/06_exports/social/
→ Team can review pending posts from GDrive
```

### Ad campaign creatives:
```
06_exports/campaigns/
├── [campaign-name]/
│   ├── manifest.json
│   ├── FINAL-*.png
│   └── caption.txt

→ GDrive: Zennith/[Brand]/06_exports/campaigns/
→ Team can review ad creatives before deployment
```

### Video exports (Tricia):
```
06_exports/video/
├── [video-name].mp4
└── [video-name]-thumbnail.png

→ GDrive: Zennith/[Brand]/06_exports/video/
→ Tricia uploads here, team reviews
```

---

## FIRST-TIME UPLOAD CHECKLIST

```
□ Create Zennith/ folder structure on GDrive (or verify it exists)
□ Create brand subfolders: Mirra/, Pinxin/, DotDot/, Bloom & Bare/
□ Create numbered subfolders (00-06) in each brand
□ Upload _shared/ → _Shared/
□ Upload each brand's 00-06 folders (skip 07_working/)
□ Skip pinxin/01_assets/gdrive-sync/ (already on GDrive)
□ Verify: can Tricia access all folders?
□ Verify: can Jenn access from phone?
□ Set up ongoing sync (GDrive for Desktop or manual)
```

---

*GDrive = the team's shared file system. GitHub = the team's shared brain.*
*Both mirror the same structure. Both follow the same rules.*
