# Studio Regression Testing Skill

## Purpose
Mandatory regression gate for ALL changes to GAIA Creative Studio.
No code change — model swap, UI update, config tweak, dependency bump — goes live without passing regression.

## When to Use
- Before ANY deploy of Creative Studio
- Before merging any PR touching `apps/gaia-creative-studio/`
- After model changes, config updates, or dependency bumps
- After any subagent completes studio work

## Project Location
`~/.openclaw/workspace/apps/gaia-creative-studio/`

## Regression Suite

### Phase 1: Build Check
```bash
cd ~/.openclaw/workspace/apps/gaia-creative-studio
npm run build 2>&1
# MUST exit 0 with no errors
```

### Phase 2: Server Smoke
```bash
# Start server, verify it responds
node server/index.js &
SERVER_PID=$!
sleep 3
curl -s http://localhost:3001/api/health || curl -s http://localhost:3001/ 
# Verify 200 response
kill $SERVER_PID
```

### Phase 3: Route Integrity
All routes must render without crash:
- `/` — Home/Dashboard
- `/create` — Create page (output types + workflow templates)
- `/library` — Asset library
- `/publish` — Content calendar / Pipeline

### Phase 4: Component Smoke (Playwright)
```bash
node scripts/qa-journey.js
```
Tests:
1. App loads (no black screen)
2. Auth gate renders
3. Brand selector works
4. Create page shows output types
5. Library loads assets
6. Publish calendar renders
7. Chat panel opens/closes
8. Image modal works

### Phase 5: API Endpoints
```bash
# All must return valid JSON, not 500
curl -s http://localhost:3001/api/output-types | python3 -c "import sys,json;json.load(sys.stdin);print('OK')"
curl -s http://localhost:3001/api/workflow-templates | python3 -c "import sys,json;json.load(sys.stdin);print('OK')"
curl -s http://localhost:3001/api/brands | python3 -c "import sys,json;json.load(sys.stdin);print('OK')"
curl -s http://localhost:3001/api/library | python3 -c "import sys,json;json.load(sys.stdin);print('OK')"
curl -s http://localhost:3001/api/projects | python3 -c "import sys,json;json.load(sys.stdin);print('OK')"
```

### Phase 6: Visual Diff (Optional)
Take screenshots of each page, compare against baseline in `tests/baselines/`.

## Runner Script
Use `scripts/regression.sh` (created alongside this skill):

```bash
bash ~/.openclaw/workspace/apps/gaia-creative-studio/scripts/regression.sh
```

Exit codes:
- 0 = ALL PASS — safe to deploy
- 1 = FAIL — do NOT deploy, fix first

## Enforcement Rules
1. **Taoz** must run regression after every code change before reporting "done"
2. **Zenni** must verify regression passed before approving any deploy
3. **Any agent** touching studio code must run regression before handoff
4. Failed regression = block deploy, fix issues, re-run
5. Results logged to `apps/gaia-creative-studio/tests/regression-results.log`

## Adding New Tests
When adding a new page or feature:
1. Add route check to Phase 3
2. Add component test to `qa-journey.js` (Phase 4)
3. Add API endpoint check to Phase 5 if applicable
4. Update baseline screenshots if visual diff is active
