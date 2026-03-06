---
name: skill-crystallize
version: "0.1.0"
description: >
  Auto-crystallize workflows and learnings into reusable GAIA OS skills.
  Generates SKILL.md + scripts + bilingual README, registers in skill index, and pushes to GitHub.
metadata:
  openclaw:
    scope: orchestration
    guardrails:
      - Never overwrite existing skills — merge or version-bump
      - Always validate SKILL.md frontmatter before registering
      - Git commit message must follow feat(skill-name) convention
    agents:
      - taoz
      - myrmidons
---

# Skill Crystallize — Auto-Turn Workflows into Reusable Skills

## Purpose

Every significant workflow, pipeline, or learning that gets figured out should become
a permanent, reusable skill — not trapped in a single session's context.

This skill automates the crystallization process:
1. Takes a workflow description (or auto-detects from session history)
2. Generates proper SKILL.md with YAML frontmatter
3. Creates script scaffolding
4. Generates bilingual README (EN + CN)
5. Registers via symlink sync
6. Commits + pushes to GitHub

## When to Use

- After building ANY new pipeline or workflow
- After figuring out a non-obvious solution to a recurring problem
- After a Claude Code session that produced reusable knowledge
- When the user says "turn this into a skill" or "crystallize this"
- Automatically triggered by `compound-crystallize.sh` cron (daily 10:35pm)

## Commands

```bash
# Create a new skill from description
skill-crystallize.sh create \
  --name "video-director" \
  --description "AI storyboard writer and video orchestrator" \
  --scope orchestration \
  --agents iris,dreami,taoz

# Scaffold from an existing script
skill-crystallize.sh from-script \
  --script /path/to/working-script.sh \
  --name "my-new-skill"

# Generate bilingual README for an existing skill
skill-crystallize.sh readme --skill video-director

# Register + sync + push to GitHub
skill-crystallize.sh publish --skill video-director

# Full pipeline: create + readme + publish
skill-crystallize.sh crystallize \
  --name "video-director" \
  --description "AI storyboard writer" \
  --scope orchestration

# Scan for crystallizable patterns in recent sessions
skill-crystallize.sh scan
```

## CHANGELOG

### v0.1.0 (2026-03-06)
- Initial release: create, from-script, readme, publish, crystallize, scan
