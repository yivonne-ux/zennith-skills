# Zennith OS — Team Workflow
> 4 Claude Codes, 1 machine. Everyone builds, everyone learns, everyone evolves.

---

## The Idea

Each person has Claude Code on their MacBook. Each Claude Code reads this same repo.
When anyone builds something better — a skill, a workflow, a fix — it goes into the repo
and EVERY Claude Code gets smarter. The machine compounds.

---

## Before You Start Working

```bash
cd ~/.openclaw && git pull
```

Every time. No exceptions. This gets you everyone else's latest work.

---

## While You Work

Build whatever you're building with Claude Code. It reads skills from `~/.openclaw/skills/`
and knows the full system from `CLAUDE.md`, `PROJECT-STATE.md`, and agent SOULs.

**Where to put things:**

| What you built | Where it goes |
|----------------|---------------|
| New skill or improved skill | `skills/{skill-name}/SKILL.md` + `scripts/` |
| Brand config change | `brands/{brand}/DNA.json` |
| Agent personality update | `workspace-{agent}/SOUL.md` |
| Shared utility script | `workspace/scripts/` |
| New brand DNA | `brands/{brand}/DNA.json` (run onboard-brand skill) |

**What stays local (NOT in git):**
- Generated images/videos (too large)
- API keys (`openclaw.json`)
- User data, sessions, credentials

---

## After You Finish a Session

```bash
cd ~/.openclaw
git add -A
git commit -m "what you built — keep it short and clear"
git push
```

**Commit message examples:**
- `improve video-gen: add Kling 3.0 support + auto-retry on timeout`
- `fix nanobanana brand bleed: skip enrichment for character mode`
- `add mirra CNY campaign briefs + ad copy variants`
- `jade bot: persistent user store + default shipan for all questions`

---

## When You Build Something Significant

Update `PROJECT-STATE.md` with what you did. This is the shared brain — it's how
other Claude Code instances know what's live, what works, what's broken.

Add your update under the right project section. Keep it factual:
- What changed
- What's live vs not
- Any gotchas or decisions made

Then commit and push.

---

## When There's a Conflict

If `git pull` shows a merge conflict:

```bash
# See what conflicted
git status

# Open the file, pick the right version (usually keep both changes)
# Look for <<<<<<< HEAD ... ======= ... >>>>>>> markers

# After fixing:
git add -A
git commit -m "merge: resolved conflict in {file}"
git push
```

If unsure, ask Claude Code to help resolve it — it can read both versions and pick the right merge.

---

## Skill Evolution Protocol

When you improve an existing skill:

1. **Read the current SKILL.md first** — understand what's there
2. **Build on it, don't rewrite from scratch** — evolution, not revolution
3. **Test it** — run the skill, verify it works
4. **Update SKILL.md** if the interface changed (new flags, new behavior)
5. **Commit with clear message** — others need to know what changed and why

When you create a new skill:

1. Create `skills/{name}/SKILL.md` — describe what it does, when to use it, how to call it
2. Create `skills/{name}/scripts/` — the actual code
3. Commit and push — it's immediately available to everyone's Claude Code

---

## Who's Building What

| Person | Machine | Current Focus |
|--------|---------|---------------|
| Jenn | iMac (this machine) | Jade Oracle, system architecture, strategy |
| Tricia | MacBook | Video workflows, image refine, ad creative, brand visuals |
| Yivonne | MacBook | Ad upload, content scheduling, multi-brand ops |

Update this table when focus shifts.

---

## How the Compounding Works

```
Jenn builds Jade Oracle bot
  → pushes to repo
    → Tricia pulls, her Claude Code now knows about Jade
      → she builds video content skill for Jade
        → pushes to repo
          → Yivonne pulls, sees both Jade bot + video skill
            → she builds ad upload pipeline for Jade videos
              → pushes to repo
                → everyone pulls → the machine is smarter
```

Every push makes every Claude Code smarter. That's the whole point.

---

## Rules

1. **Always pull before working.** Stale code = merge hell.
2. **Always push after building.** Unpushed work = invisible to the team.
3. **Update PROJECT-STATE.md after big builds.** Otherwise the shared brain goes stale.
4. **Don't delete other people's skills.** Improve them or build alongside.
5. **Don't commit API keys or secrets.** The .gitignore handles this, but double-check.
6. **Commit often.** Small commits > big dumps. Easier to understand, easier to merge.
7. **Write clear commit messages.** Future-you and future-Claude-Code will thank you.
