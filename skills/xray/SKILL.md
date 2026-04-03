---
name: xray
description: |
  Deep codebase analysis & understanding. Runs code analysis tools (scc/madge/dependency-cruiser),
  AI deep-reads each module, generates architecture skeleton docs.
  Supports incremental analysis (commit-based diff). Outputs to docs/codebase/, CLAUDE.md, memory/.
  Use /xray to trigger. Use /xray setup for first-time configuration.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
---

# X-Ray — Deep Codebase Analysis & Understanding

Run professional code analysis tools + AI layer-by-layer deep reading to generate a project architecture skeleton. Supports incremental updates: full analysis on first run, subsequent runs only analyze modules changed since last commit.

## Usage

| Command | Description |
|---------|-------------|
| `/xray` | Auto-detect incremental/full, analyze all configured targets |
| `/xray setup` | Interactive setup — configure targets, paths, options |
| `/xray [target]` | Analyze a specific target (e.g., `/xray frontend`) |
| `/xray --full` | Force full analysis (ignore existing results) |

## Workflow

```
/xray
  |
  v
[Phase 0] Setup & Environment
  |  ├── Check .xray-config.json exists (if not → run setup)
  |  └── Check/install scc, madge, dependency-cruiser
  |
  v
[Phase 1] Incremental Detection
  |  ├── Read docs/codebase/.analysis-meta.json
  |  ├── Compare current commit vs last analyzed commit
  |  └── Decide: full / incremental / skip
  |
  v
[Phase 2] Tool Analysis (targets in parallel)
  |  ├── scc → code statistics
  |  ├── tree → directory structure
  |  ├── madge → dependency graph + circular deps + orphans
  |  └── depcruise → dependency rule validation
  |
  v
[Phase 3] AI Deep Reading (parallel Agents)
  |  ├── Round 1: module identification & overview
  |  └── Round 2: per-module deep analysis (business logic, call chains, type relationships)
  |
  v
[Phase 4] Output Synthesis
  |  ├── docs/codebase/{target}/ → 5 detailed docs
  |  ├── CLAUDE.md → append/update "Project Architecture" section
  |  └── memory/ → AI memory files (if configured)
  |
  v
[Done] Update .analysis-meta.json, print summary
```

## Execution Guide

---

### Phase 0: Setup & Environment

#### 0.1 Configuration Check

Read `.xray-config.json` from the project root. If it does not exist, **automatically enter setup flow**.

#### 0.2 Setup Flow (interactive, triggered by `/xray setup` or first run)

Ask the user the following questions to build the config:

**Step 1: Identify project targets**

Look at the project structure first:

```bash
ls -d */ 2>/dev/null
ls package.json pyproject.toml Cargo.toml go.mod pom.xml build.gradle *.sln 2>/dev/null
```

Then ask: "I detected the following project structure. Which directories should I analyze as separate targets?"

Provide smart defaults:
- Monorepo with `frontend/` + `backend/` → suggest two targets
- Single repo with `src/` → suggest one target named after the repo
- Workspace with `packages/` → suggest each package as a target

**Step 2: For each target, confirm:**
- **name**: display name (e.g., "frontend", "backend", "api", "web")
- **path**: relative path from project root (e.g., `./frontend`, `.`, `./packages/api`)
- **srcDir**: source directory within the target (e.g., `src`, `lib`, `app`)
- **language**: primary language/framework (auto-detect from package.json / Cargo.toml / go.mod / etc.)
- **tsconfig** (if TypeScript): path to tsconfig.json (auto-detect)

**Step 3: Output options**
- **outputDir**: where to write analysis docs (default: `docs/codebase`)
- **updateClaudeMd**: whether to update CLAUDE.md with summary (default: true)
- **updateMemory**: whether to write AI memory files (default: true)
- **excludeDirs**: directories to exclude (default: `["node_modules", ".next", "dist", "coverage", "build", "__pycache__", "target", "vendor"]`)

**Step 4: Git topology**
- Ask: "Are these targets in the same git repo, or separate git repos (git submodules / independent repos)?"
- **sameRepo**: `true` if all targets share one `.git`, `false` if each target has its own `.git`

**Step 5: Write config**

Write `.xray-config.json`:

```json
{
  "version": 1,
  "targets": [
    {
      "name": "frontend",
      "path": "./frontend",
      "srcDir": "src",
      "language": "typescript",
      "framework": "nextjs",
      "tsconfig": "./frontend/tsconfig.json"
    },
    {
      "name": "backend",
      "path": "./backend",
      "srcDir": "src",
      "language": "typescript",
      "framework": "nestjs",
      "tsconfig": "./backend/tsconfig.json"
    }
  ],
  "outputDir": "docs/codebase",
  "updateClaudeMd": true,
  "updateMemory": true,
  "excludeDirs": ["node_modules", ".next", "dist", "coverage", "build", "__pycache__", "target", "vendor"],
  "sameRepo": false
}
```

Print confirmation and suggest adding `.xray-config.json` to the repo (it's not sensitive).

#### 0.3 Tool Installation

Check and install analysis tools as needed.

**Important**: `madge` and `dependency-cruiser` must be installed as **devDependencies in the target project**, not globally. This ensures version compatibility and avoids global pollution. `scc` is a standalone binary installed system-wide.

```bash
# scc (code statistics) — system-wide binary, works for all languages
which scc || brew install scc  # macOS
# Linux: download from https://github.com/boyter/scc/releases

# For TypeScript/JavaScript targets only:
# Install madge and dependency-cruiser into the target project as devDependencies
cd {target.path}

# madge (dependency graph)
if ! npx madge --version >/dev/null 2>&1; then
  echo "Installing madge as devDependency in {target.path}..."
  npm install --save-dev madge
fi

# dependency-cruiser
if ! npx depcruise --version >/dev/null 2>&1; then
  echo "Installing dependency-cruiser as devDependency in {target.path}..."
  npm install --save-dev dependency-cruiser
fi
```

When running madge/depcruise in Phase 2, always use `npx` to invoke the project-local version:
```bash
cd {target.path} && npx madge --json ...
cd {target.path} && npx depcruise --output-type json ...
```

If a tool fails to install, print a warning and continue (that tool's analysis steps will be skipped).

**Platform detection**: Check `uname` to determine macOS vs Linux and use appropriate install commands.

#### 0.4 Validate targets exist

```bash
# For each target, check that the path exists
for target in $(jq -r '.targets[].path' .xray-config.json); do
  ls "$target" >/dev/null 2>&1 || echo "WARNING: target path $target not found"
done
```

---

### Phase 1: Incremental Detection

#### 1.1 Read Metadata

Read `{outputDir}/.analysis-meta.json`. If the file doesn't exist or user passed `--full`, enter **full analysis mode**.

#### 1.2 Get Current State

For each target, get the current git state:

```bash
# If sameRepo is true:
git rev-parse HEAD
git branch --show-current

# If sameRepo is false (each target has own repo):
cd {target.path} && git rev-parse HEAD && git branch --show-current
```

#### 1.3 Decision Logic

For each target independently:

| Condition | Mode |
|-----------|------|
| `.analysis-meta.json` doesn't exist | Full |
| `--full` flag | Full |
| Current commit == last analyzed commit | **Skip** (print "No changes, skipping") |
| Changes involve config files (`package.json`, `tsconfig.json`, `Cargo.toml`, `go.mod`, etc.) | Full |
| Changes only involve source files | **Incremental** (only analyze affected modules) |

#### 1.4 Incremental: Identify Affected Modules

```bash
# Get changed files since last analysis
git diff --name-only {old_commit}..HEAD -- {target.path}
```

Map changed file paths to module names by their top-level directory under srcDir (e.g., `src/modules/auth/` → `auth`, `src/components/Button/` → `Button`). Deduplicate to get the list of modules needing re-analysis.

---

### Phase 2: Tool Analysis

For targets that need analysis, run the following tools **in parallel**. Store output in `{outputDir}/.tmp/`.

Read the config to get `excludeDirs` and build exclude patterns.

#### 2.1 Code Statistics (scc)

```bash
mkdir -p {outputDir}/.tmp
# Build exclude flags from config
EXCLUDES=$(jq -r '.excludeDirs | join(",")' .xray-config.json)
scc --format json --exclude-dir "$EXCLUDES" {target.path}/ > {outputDir}/.tmp/{target.name}-scc.json 2>/dev/null
```

#### 2.2 Directory Structure (tree)

```bash
# Build tree ignore pattern from excludeDirs
TREE_IGNORE=$(jq -r '.excludeDirs | join("|")' .xray-config.json)
tree -I "$TREE_IGNORE|.git" -L 3 --dirsfirst {target.path}/ > {outputDir}/.tmp/{target.name}-tree.txt
```

If `tree` is not installed, fall back to:
```bash
find {target.path} -maxdepth 3 -not -path '*/node_modules/*' -not -path '*/.git/*' | head -200
```

#### 2.3 Dependency Graph (madge) — TypeScript/JavaScript only

Skip this step for non-JS/TS targets.

```bash
# All madge/depcruise commands use npx to invoke the project-local version
cd {target.path}

# Dependency graph JSON
npx madge --json --ts-config {target.tsconfig} {target.srcDir}/ > {outputDir}/.tmp/{target.name}-deps.json 2>/dev/null

# Circular dependencies
npx madge --circular --ts-config {target.tsconfig} {target.srcDir}/ > {outputDir}/.tmp/{target.name}-circular.txt 2>/dev/null

# Orphan files
npx madge --orphans --ts-config {target.tsconfig} {target.srcDir}/ > {outputDir}/.tmp/{target.name}-orphans.txt 2>/dev/null
```

**Note**: If tsconfig.json is not at the expected location, use `find {target.path} -name tsconfig.json -maxdepth 2` to locate it. If madge errors (some monorepo configs are incompatible), log the error and skip.

#### 2.4 Dependency Rule Validation (depcruise) — TypeScript/JavaScript only

```bash
cd {target.path}
npx depcruise --output-type json {target.srcDir}/ > {outputDir}/.tmp/{target.name}-cruise.json 2>/dev/null
```

If there's no `.dependency-cruiser.cjs` config file, depcruise may error — skip in that case.

#### 2.5 Language-Specific Analysis (non-JS/TS)

For other languages, use appropriate tools if available:

- **Rust**: `cargo tree`, `cargo udeps`
- **Go**: `go mod graph`, `go vet`
- **Python**: `pipdeptree`, `pylint --generate-rcfile`
- **Java/Kotlin**: `gradle dependencies`, `mvn dependency:tree`

If these tools are not available, skip and rely on AI deep reading in Phase 3.

---

### Phase 3: AI Deep Reading

The core phase. AI uses Phase 2 tool outputs + direct source code reading to understand the project layer by layer.

#### 3.1 Round 1: Module Identification & Overview

For each target:

1. Read `{outputDir}/.tmp/{target.name}-tree.txt` to understand directory structure
2. Identify all top-level modules based on the framework:
   - **NestJS**: `src/modules/` directories
   - **Next.js**: `src/app/` routes + `src/components/`
   - **Express/Fastify**: `src/routes/` or `src/controllers/`
   - **React (non-Next)**: `src/components/`, `src/pages/`, `src/features/`
   - **Go**: top-level packages under `cmd/` and `internal/`
   - **Rust**: `src/` modules, workspace members
   - **Python/Django**: `apps/` or top-level packages
   - **Generic**: top-level directories under srcDir
3. For each module, read entry files (`index.ts`, `module.ts`, `page.tsx`, `mod.rs`, `__init__.py`, `main.go`, etc.)
4. Generate module manifest: name, path, one-line responsibility, main exports

**Incremental mode**: Read existing `modules.md`, only re-analyze affected modules, merge results.

#### 3.2 Round 2: Deep Analysis

Launch **multiple Agents in parallel** to analyze different modules. Each Agent handles one or more modules:

**For each module, analyze and record:**

- **Responsibility**: what this module does, what problem it solves
- **Core files**: key files and their roles
- **Public interface**: exported APIs, components, functions, types
- **Internal dependencies**: which other modules it depends on (reference madge output if available)
- **External dependencies**: which third-party libraries it uses
- **Data flow**: how data flows in, gets processed, and flows out

**Key Business Call Chain Tracing:**

Identify the 3-5 most important business paths in the project (e.g., user auth flow, core transaction flow, data query flow), trace the complete call chain:

```
Entry point (route/page)
  -> Controller/Handler
    -> Service (business logic)
      -> Repository/External API
        -> Database/Third-party service
```

**Type/Interface Relationships:**

- Identify core Entities/DTOs/Interfaces/Structs
- Record inheritance, composition, and reference relationships
- Which types are shared across modules

**Test Coverage:**

```bash
# Count test files (adapt pattern to language)
find {target.path}/{target.srcDir} -name "*.spec.*" -o -name "*.test.*" -o -name "*_test.*" | wc -l
# Count source files
find {target.path}/{target.srcDir} -name "*.ts" -o -name "*.tsx" -o -name "*.go" -o -name "*.rs" -o -name "*.py" | grep -v -E "(spec|test|_test)" | wc -l
```

Record which modules have tests and which don't.

**Incremental mode**: Only run Round 2 for changed modules. Read existing `call-chains.md` and `types.md`; if changed modules touch already-documented call chains or types, update those sections.

---

### Phase 4: Output Synthesis

#### 4.1 Write `{outputDir}/{target.name}/` (detailed analysis)

Create 5 files per target:

**structure.md** — Directory structure + code statistics
```markdown
# {target.name} Project Structure

## Basic Info
- Tech Stack: {detected framework} + {language}
- Analyzed at: {branch}@{commit_short} ({date})

## Code Statistics
| Language | Files | Code Lines | Comment Lines | Complexity |
|----------|-------|------------|---------------|------------|
(extracted from scc JSON)

## Directory Structure
(tree output with annotations for key directories)
```

**dependencies.md** — Module dependency relationships
```markdown
# {target.name} Dependencies

## Module Dependency Graph
(from madge JSON or AI analysis, rendered as ASCII or mermaid diagram)

## Circular Dependencies
(list all circular dependency chains, or "No circular dependencies found")

## Orphan Files
(files not referenced by any other file)

## Third-Party Dependencies Overview
(major third-party libraries and their purposes)
```

**modules.md** — Per-module analysis
```markdown
# {target.name} Module Analysis

## Module Overview
| Module | Path | Responsibility | Files | Has Tests |
|--------|------|---------------|-------|-----------|

## {Module A}
### Responsibility
### Core Files
### Public Interface
### Dependencies
### Data Flow

## {Module B}
...
```

**call-chains.md** — Key business call chains
```markdown
# {target.name} Key Business Call Chains

## Call Chain 1: {business name}
### Trigger
### Full Call Path
### Key Decision Points
### Error Handling

## Call Chain 2: ...
```

**types.md** — Core type relationships
```markdown
# {target.name} Core Types & Interfaces

## Type Overview
| Type | Location | Purpose | Reference Count |
|------|----------|---------|-----------------|

## Core Entities
## Core DTOs / VOs
## Shared Interfaces
## Type Inheritance/Composition Diagram
```

#### 4.2 Update `CLAUDE.md` (concise summary)

Look for `<!-- XRAY:START -->` and `<!-- XRAY:END -->` markers in CLAUDE.md:
- If found → replace content between markers
- If not found → append at end of file
- If CLAUDE.md doesn't exist → create it with the xray section

Content template (keep under ~50 lines):

```markdown
<!-- XRAY:START -->
## Project Architecture

> Auto-generated by `/xray`, based on {target1}@{commit_short} {target2}@{commit_short} ({date})
> Detailed analysis in `{outputDir}/`

### {Target 1 Name}
- **Tech Stack**: {framework} + {language} + {key libraries}
- **Core Modules**:
  - `{module}` — {one-liner}
  - ...
- **Key Routes/Endpoints**: {overview}

### {Target 2 Name}
...

### Key Business Paths
1. **{path name}**: {brief entry -> exit}
2. ...

### Notes
- {non-obvious design decisions or gotchas}
<!-- XRAY:END -->
```

#### 4.3 Write AI Memory (if configured)

Only if `updateMemory` is true in config.

Create or update a memory file at the Claude memory path for this project:

```markdown
---
name: codebase-understanding
description: Deep codebase architecture summary with module responsibilities, key paths, tech stack. Based on code analysis tools + AI deep reading.
type: project
---

## Tech Stack
- {target1}: {overview}
- {target2}: {overview}

## Core Modules ({target1})
{one line per module: name — responsibility}

## Core Modules ({target2})
{one line per module: name — responsibility}

## Key Business Paths
{3-5 most important end-to-end paths}

## Non-Obvious Design Decisions
{important design choices you wouldn't know without reading the code}

## Known Issues
{circular dependencies, orphan files, modules lacking tests, etc.}

Based on analysis: {target1}@{commit_short} {target2}@{commit_short} ({date})
```

Also update `memory/MEMORY.md` index.

#### 4.4 Update Metadata

Write `{outputDir}/.analysis-meta.json`:

```json
{
  "version": 1,
  "analyzedAt": "{ISO 8601}",
  "targets": {
    "{target.name}": {
      "branch": "{current branch}",
      "commit": "{full commit hash}",
      "commitShort": "{7-char short hash}",
      "timestamp": "{ISO 8601}",
      "modules": ["module-a", "module-b"]
    }
  }
}
```

#### 4.5 Clean Up

```bash
rm -rf {outputDir}/.tmp/
```

#### 4.6 Print Summary

```
X-Ray analysis complete

{Target 1} ({target1.framework}):
  Branch: {branch}  Commit: {short_hash}
  Modules: {N}  Code: {lines} lines  Circular deps: {N}
  Mode: full / incremental ({M} modules updated)

{Target 2} ({target2.framework}):
  ...

Output:
  docs/codebase/{target1}/ (5 files)
  docs/codebase/{target2}/ (5 files)
  CLAUDE.md -> "Project Architecture" section updated
  memory/ -> codebase_understanding.md updated
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `.xray-config.json` missing | Auto-enter setup flow |
| Target path doesn't exist | Warn and skip that target |
| Tool install fails | Warn, skip that tool's analysis, continue |
| madge errors (tsconfig incompatible) | `find` to locate tsconfig, retry; still fails → skip |
| depcruise no config file | Skip dependency rule validation, use madge only |
| Old commit doesn't exist (e.g., after force push) | Auto-fallback to full analysis |
| Single module analysis fails | Log error, continue with other modules |
| Non-JS/TS project | Skip madge/depcruise, rely on scc + AI deep reading |

---

## Notes

1. All targets are analyzed based on the config in `.xray-config.json` — run `/xray setup` to reconfigure
2. If `sameRepo` is false, git commands must `cd` into each target's directory
3. Phase 2 tool analysis can run **in parallel** across targets (they are independent)
4. Phase 3 AI deep reading can use **Agent tool for parallel** module analysis
5. In incremental mode, **read existing docs first**, only update changed parts, preserve unchanged module analysis
6. `<!-- XRAY:START/END -->` markers in CLAUDE.md ensure incremental updates don't break other content
7. `.analysis-meta.json` and `.tmp/` should be added to `.gitignore` (or not, depending on team preference)
8. The skill works with any language/framework — JS/TS projects get richer analysis via madge/depcruise, others rely more on AI reading
