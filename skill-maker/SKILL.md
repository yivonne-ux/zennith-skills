---
name: skill-maker
description: Allows the agent to research, write, and install new skills for itself.
metadata: {"openclaw":{"requires":{"bins":["npm","node"]}}}
---

# Skill-Maker

This skill allows the agent to:

1. Research a requested capability.
2. Create a folder in `~/.openclaw/skills/`.
3. Write a valid `SKILL.md` and supporting scripts.
4. Run `openclaw skills reload` to equip the new ability.

## Operating Notes

- Prefer local documentation first (`/usr/local/lib/node_modules/openclaw/docs`) before web research.
- Keep skills minimal and composable: start with `SKILL.md`, add scripts only when necessary.
- When generating scripts, include:
  - clear usage/help output
  - safe defaults
  - non-destructive behavior
  - basic input validation
- After writing or updating a skill, run:
  - `openclaw skills reload`

## Required Binaries

- `node`
- `npm`
