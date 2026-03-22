# Google Drive Shared Drive Setup — Zennith Creative
> For Jenn to execute. Takes ~15 minutes.

---

## Why Shared Drive (not "My Drive")

- **My Drive** = belongs to ONE person. If that person leaves, files go with them.
- **Shared Drive** = belongs to the TEAM. Files persist regardless of who joins/leaves.
- All 3 of us get equal access. No "can you share that folder?" requests.

---

## Step 1: Create Shared Drive

1. Go to https://drive.google.com
2. Left sidebar → **Shared drives**
3. Click **+ New** → Name it: `Zennith Creative`
4. Add members:
   - `love@huemankind.world` (Manager)
   - `admin@bloomandbare.co` (Manager)
   - `yivonne@gaiaeats.com` (Manager)

## Step 2: Create Folder Structure

Inside `Zennith Creative`, create:

```
Zennith Creative/
├── _shared/
│   ├── fonts/
│   ├── references/
│   └── templates/
├── pinxin/
│   ├── assets/
│   ├── exports/
│   │   ├── finals/
│   │   └── campaigns/
│   └── references/
├── mirra/
│   ├── assets/
│   ├── exports/
│   │   ├── finals/
│   │   └── campaigns/
│   └── references/
├── bloom-bare/
│   ├── assets/
│   ├── exports/
│   │   └── finals/
│   └── references/
├── jade-oracle/
│   ├── assets/
│   ├── exports/
│   │   └── finals/
│   └── references/
└── serein/
    ├── assets/
    └── exports/
```

## Step 3: Each Person — Google Drive for Desktop Settings

1. Open **Google Drive for Desktop** app
2. Click gear icon → **Preferences**
3. Find `Zennith Creative` shared drive
4. Change to: **Mirror files** (not Stream)
   - This keeps REAL files on disk so Python/AI scripts can access them
5. Under **"My Mac"** section, click **Add folder**:
   - Select your local `~/Desktop/_WORK/[brand]/06_exports/finals/`
   - Choose "Sync with Google Drive" → destination: Zennith Creative/[brand]/exports/finals/

## Step 4: Move Existing Assets

Pinxin assets currently on `love@huemankind.world` My Drive:
- `/Pinxin/Resources/Finalized Image/` → move to `Zennith Creative/pinxin/assets/photos/`
- `/Pinxin/Creative Team Template/Brand Identity/Elements/` → move to `Zennith Creative/pinxin/assets/`

(Or keep them where they are and create shortcuts — moving is cleaner long-term)

---

## What Syncs Where (Final Map)

| Content | Location | Syncs Via |
|---|---|---|
| Skills, scripts, learnings | GitHub (zennith-skills) | `git pull/push` |
| Approved ad outputs | GDrive Shared Drive/[brand]/exports/finals/ | Auto (Mirror mode) |
| Brand assets (photos, logos) | GDrive Shared Drive/[brand]/assets/ | Auto (Mirror mode) |
| Campaign batches under review | GDrive Shared Drive/[brand]/exports/campaigns/ | Auto |
| Working files, rejected, scratch | LOCAL ONLY (each person's ~/Desktop/_WORK/) | NOT synced |
| Strategy docs, research | GitHub (zennith-skills/workspace/knowledge/) | `git pull/push` |

---

## Daily Workflow After Setup

```
Morning:
  cd ~/Desktop/zennith-skills && git pull    ← get team's latest skills/research

Work:
  - Scripts save outputs to 06_exports/finals/ → auto-syncs to GDrive
  - Team sees outputs in Shared Drive immediately
  - Grab assets from GDrive (auto-downloaded in Mirror mode)

End of day:
  git add workspace/knowledge/ skills/
  git commit -m "what you did"
  git push                                    ← share learnings with team
```
