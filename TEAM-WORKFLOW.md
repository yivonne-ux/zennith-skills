# Zennith Skills — Team Workflow
> 3 humans, 3 Claude Codes, 1 repo. Pull → Build → Push → Everyone gets smarter.

---

## Setup (first time only)

```bash
# 1. Clone the repo
git clone https://github.com/jennwoei316/zennith-skills.git
cd zennith-skills

# 2. Read these files to understand what we're building
#    - CLAUDE.md          → system overview, agents, file rules
#    - PROJECT-STATE.md   → what's live, what's built, what's next
#    - This file          → how we work together
```

That's it. No OpenClaw install needed. No special tools. Just git + Claude Code.

---

## Daily Flow

```
START SESSION:     git pull origin main
DO YOUR WORK:      build, fix, create — whatever Jenn assigned
END SESSION:       git add → git commit → git push origin main
```

### Pull (every time you start)

```bash
cd zennith-skills
git pull origin main
```

This gets you everyone else's latest work. **Never skip this.**

### Push (every time you finish)

```bash
git add <the files you changed>
git commit -m "short description of what you did"
git push origin main
```

**Don't use `git add -A`** — only add files you actually worked on.
**Don't commit** API keys, .env files, secrets, or huge media files.

### If push fails

Someone else pushed while you were working. Normal — just:

```bash
git pull --rebase origin main
# fix any conflicts if needed
git push origin main
```

---

## Where Things Go

| What you're building | Where to put it |
|---------------------|-----------------|
| Skill (code that does a thing) | `skills/{skill-name}/SKILL.md` + `scripts/` |
| Brand config | `brands/{brand}/DNA.json` |
| Store assets (HTML, SVG, images) | `workspace/data/images/{brand}/` |
| Research / knowledge | `workspace/knowledge/` |
| Agent workspace docs | `workspace-{agent}/` |
| Shared scripts | `workspace/scripts/` or `bin/` |

**What stays OUT of git:**
- Generated images/videos (too large)
- API keys, tokens, secrets
- `openclaw.json` (local to each machine)
- Temporary test files

---

## Commit Message Style

Keep it short, say what you did:

```
jade bot: fix cards bug + refine UX tone
add store product cards + testimonial HTML
zenki sync: product research + 1688 suppliers
pub-sub routing system for agent dispatch
```

---

## How to Check What Others Did

```bash
git log --oneline -20          # recent commits
git log --oneline --since="yesterday"   # what happened today
git diff HEAD~1                # what the last commit changed
```

---

## When You Build Something Big

Update `PROJECT-STATE.md` — that's the shared brain. Other Claude Codes read it to know what's live, what's broken, what's next.

---

## The Team

| Person | Machine | Role |
|--------|---------|------|
| Jenn | iMac | CEO — strategy, Jade Oracle, system architecture |
| Tricia | MacBook | Designer — video, visuals, ad creative, store design |
| Yivonne | MacBook | Ops — ads, content scheduling, operations |

Each person runs Claude Code on their own machine. We all push to the same repo. Every push makes every Claude Code smarter.

---

## How It Compounds

```
Jenn builds Jade Oracle bot → pushes
  Tricia pulls → sees bot + store assets → builds Shopify pages → pushes
    Yivonne pulls → sees everything → sets up ad pipeline → pushes
      Jenn pulls → the whole machine is smarter
```

The repo IS the brain. Git IS the sync. Simple.

---

## Rules

1. **Always pull before working.** Stale code = merge pain.
2. **Always push when done.** Unpushed work is invisible.
3. **Update PROJECT-STATE.md after big builds.**
4. **Don't delete other people's work.** Build on it or build alongside.
5. **Don't commit secrets.** Ever.
6. **Commit often.** Small commits > big dumps.
7. **Ask Jenn if unsure.**
