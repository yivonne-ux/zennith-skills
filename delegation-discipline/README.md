# Delegation Discipline - Development Guide

## Quick Start

### Prerequisites
- Node.js 18+
- OpenClaw installed
- GAIA CORP-OS agent system

### Installation

```bash
# Skill is built into OpenClaw core
# No additional installation required
```

## Usage

### Determine Target Agent

```javascript
const delegation = require('@openclaw/skill-delegation-discipline');

// Get agent for task
const agentId = delegation.getTargetAgent('Build a new skill for WeChat integration');
// Returns: 'taoz'

const agent = delegation.getAgentSummary(agentId);
// Returns: { name: 'Taoz', role: 'Builder/Coder', ... }
```

### Check if Should Delegate

```javascript
const shouldDelegate = delegation.shouldDelegate(5);
// Returns: true (5 lookups > 3 threshold)
```

### Generate Delegation Brief

```javascript
const brief = delegation.generateBrief({
  task: 'Research organic coconut oil products on Taobao',
  targetAgent: 'artemis',
  params: { minRating: 4.5, maxPrice: 60 },
});

// Returns: "DELEGATE TO ARTEMIS:\n\nTask: Research organic coconut oil products on Taobao\n\nPurpose: research, analysis, trends, external resources\n\nParameters: {"minRating":4.5,"maxPrice":60}\n\nBegin work now. Return results in structured format."
```

### Token Discipline Check

```javascript
const shouldWrite = delegation.shouldWriteToFile(8);
// Returns: true (8 items > 5 threshold)
```

## File Structure

```
delegation-discipline/
├── SKILL.md              # Main skill documentation
├── index.js              # Main entry point
├── package.json          # NPM config
└── test.js               # Test script
```

## Testing

```bash
cd ~/.openclaw/skills/delegation-discipline

# Run tests
npm test
```

## Integration Examples

### In Agent SOUL.md

```markdown
## Delegation Discipline

I follow strict delegation rules:

1. **When to delegate:**
   - >3 lookups → Myrmidons
   - Coding → Taoz
   - Research → Artemis
   - Creative → Dreami/Iris
   - Copy → Dreami
   - Strategy → Athena/Hermes

2. **How to delegate:**
   - Write clear briefs
   - Batch related tasks
   - Trust the brief, don't micromanage

3. **Token discipline:**
   - Never burn tokens on lookups
   - Write files, don't keep in head
   - Compact proactively
```

### In Agent Workflow

```javascript
// Before doing work, check delegation
const delegation = require('@openclaw/skill-delegation-discipline');

// Determine if should delegate
const shouldDelegate = delegation.shouldDelegate(estimatedToolCalls);

if (shouldDelegate) {
  const targetAgent = delegation.getTargetAgent(taskDescription);
  const brief = delegation.generateBrief({
    task: taskDescription,
    targetAgent: targetAgent,
    params: taskParams,
  });
  
  // Delegate to sub-agent
  sessions_spawn({
    agentId: targetAgent,
    task: brief,
  });
} else {
  // Do work myself
  performTask(taskDescription);
}
```

## Update routing matrix

Edit `index.js` to modify agent keywords or add new agents:

```javascript
const AGENT_MATRIX = {
  // ... existing agents
  newagent: {
    name: 'New Agent',
    role: 'New Role',
    focus: 'new focus area',
    keywords: ['keyword1', 'keyword2'],
  },
};
```

## Contributing

1. Test changes with sample tasks
2. Update SKILL.md with new patterns
3. Update routing matrix as needed
4. Run tests before commit

---

*For questions, contact Taoz (GAIA CORP-OS)*
