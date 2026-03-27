# Quality Checklist & Common Mistakes

## Quality Checklist

Before shipping any skill, verify:

- [ ] YAML frontmatter has `name`, `description`, and `agents` fields
- [ ] Description contains ONLY trigger conditions (no workflow summary)
- [ ] Description is under 500 characters
- [ ] Skill body is under 350 lines
- [ ] Each procedure step has agent role, inputs, process, output
- [ ] At least one example included
- [ ] Related skills listed (no @-links)
- [ ] Eval run completed (baseline vs with-skill)
- [ ] Symlink created to `~/.claude/skills/`
- [ ] Git committed

## Versioning

When updating an existing skill, increment the version in frontmatter. Keep a CHANGELOG.md in the skill directory if changes are significant.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Description summarizes workflow | Rewrite to only list trigger conditions |
| Too many MUST/NEVER/ALWAYS | Explain the reasoning instead |
| Skill over 500 lines | Move heavy reference to `references/` subdirectory |
| No eval run | Always test baseline vs with-skill before shipping |
| @-linking other skills | Use skill name only — @-links force-load context |
| Generic agent assignment | Assign specific agents with reasons |
| Missing "When NOT to use" | Add to prevent false triggers |
