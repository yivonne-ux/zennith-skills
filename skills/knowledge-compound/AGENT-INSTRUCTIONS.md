# Knowledge Compound — Agent Instructions

## What This Is
A self-learning loop. Every research finding, workflow study, user correction, session learning, and tool discovery gets stored, searched, and auto-promoted into agent capabilities.

## How to Use (ALL agents)

### Store a learning
```bash
bash ~/.openclaw/skills/knowledge-compound/scripts/digest.sh \
  --source "session/<your-id>/$(date +%Y-%m-%d)" \
  --type "session-learning" \
  --fact "What you learned" \
  --agent "<your-id>"
```

### Search before acting (avoid duplicate work)
```bash
bash ~/.openclaw/skills/knowledge-compound/scripts/digest.sh search "topic"
```

### Check what's known
```bash
bash ~/.openclaw/skills/knowledge-compound/scripts/digest.sh recent
bash ~/.openclaw/skills/knowledge-compound/scripts/digest.sh stats
```

### Track a pattern (auto-promotes at 3x → validated, 5x → implemented)
```bash
bash ~/.openclaw/skills/knowledge-compound/scripts/digest.sh \
  --source "your-source" \
  --type "pattern" \
  --fact "Description of the pattern" \
  --pattern "pattern-name-kebab-case" \
  --agent "<your-id>"
```

## Types
`workflow` `competitor-intel` `user-correction` `session-learning` `tool-discovery` `brand-update` `performance-data` `tutorial` `pattern`

## When to Digest
1. **End of session** — store what you learned (End-of-Session Protocol)
2. **After research** — store findings before they're lost
3. **User corrections** — immediately store with high priority
4. **New tool/API discovered** — store with `tool-discovery` type
5. **Pattern noticed** — use `--pattern` flag to track occurrences
