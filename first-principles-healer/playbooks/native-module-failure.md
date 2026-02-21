# Playbook: Native Module Failure

## Error Signature
- `node-gyp ERR!`
- `binding.gyp not found`
- `better-sqlite3`, `bcrypt`, `node-sass` compilation errors
- `Cannot find module` after npm install
- Prebuilt binary download failures

## First Principles Root Cause

Native Node.js modules contain C/C++ code that must be compiled for the specific:
1. **Node.js version** (ABI compatibility)
2. **Operating system** (macOS, Linux, Windows)
3. **Architecture** (ARM64 vs x86_64)
4. **Build toolchain** (Xcode, Python, make)

When any of these don't align, the module fails to load or compile.

## Fix Procedure

### Step 1: Diagnose Environment (30s)
```bash
# Check Node.js version
node -v

# Check architecture
node -p "process.arch"

# Check build tools (macOS)
xcode-select -p
xcode-select --install  # if not installed

# Check Python (for node-gyp)
python3 --version
```

**Verification:** All commands return valid output without errors.

### Step 2: Clean Slate (10s)
```bash
# Remove potentially corrupted modules
rm -rf node_modules package-lock.json

# Clear npm cache if needed
npm cache clean --force
```

**Verification:** `ls node_modules` returns "No such file or directory"

### Step 3: Install with Build Tools (60-120s)
```bash
# Standard install with verbose logging
npm install 2>&1 | tee npm-install.log

# If that fails, try with specific Node version compatibility
npm install --build-from-source
```

**Verification:** Check for `node_modules/<package-name>/build/Release/*.node` files

### Step 4: Fallback Strategies (if Step 3 fails)

#### Option A: Use Pure-JS Alternative
Replace native module with JavaScript equivalent:
- `better-sqlite3` → `sqlite3` (has pure JS mode) or `sql.js`
- `bcrypt` → `bcryptjs`
- `node-sass` → `sass` (Dart Sass, pure JS)

```bash
npm uninstall better-sqlite3
npm install sqlite3
```

**Verification:** App starts without native module errors.

#### Option B: Downgrade Node.js
```bash
# If using nvm
nvm install 20
nvm use 20
npm install

# Pin for future
node -v > .nvmrc
```

**Verification:** `node -v` shows LTS version (18.x or 20.x)

#### Option C: Use Prebuilt Binaries
```bash
# Force prebuilt binary download
npm install --fallback-to-build=false

# Or set environment variable
npm_config_build_from_source=false npm install
```

**Verification:** No compilation output in npm install logs.

### Step 5: Verify Fix (10s)
```bash
# Test the module loads
node -e "require('better-sqlite3')"

# Or test the app starts
npm start &
sleep 3
curl http://localhost:19800/api/health
```

**Verification:** No errors, app responds with HTTP 200.

## Decision Tree

```
better-sqlite3 failed to install
        ↓
Node 25+ (latest)? ──Yes──→ Try pure-JS alternative first
        ↓ No
Build tools installed? ──No──→ Install Xcode CLI tools
        ↓ Yes
Clean install works? ──No──→ Try --build-from-source
        ↓ Yes
App starts? ──No──→ Check for runtime linking errors
        ↓ Yes
      [FIXED]
```

## Prevention

1. **Pin Node.js version** in `.nvmrc` or `package.json` engines
2. **Use pure-JS alternatives** when performance allows
3. **Dockerize** for consistent environments
4. **CI/CD testing** across Node versions

## Related Patterns

- `native-better-sqlite3-node25` - Specific to better-sqlite3 on Node 25
- `native-node-sass-deprecated` - node-sass is deprecated, use dart-sass
- `native-bcrypt-arch-mismatch` - ARM vs x86 issues on Apple Silicon

## Learning Log Template

When this playbook is executed, log to `healing-log.jsonl`:
```json
{
  "ts": 1707734400000,
  "pattern_id": "native-better-sqlite3-node25",
  "fix_applied": "fallback-to-sqlite3",
  "success": true,
  "duration_seconds": 45,
  "context": {
    "node_version": "v25.6.0",
    "package": "better-sqlite3",
    "fallback_used": "sqlite3"
  }
}
```
