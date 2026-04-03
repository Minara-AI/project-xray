# X-Ray — Deep Codebase Analysis for Claude Code

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Skill-blueviolet?logo=anthropic&logoColor=white)](https://claude.ai/claude-code)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey)]()

[中文文档](README_CN.md)

**Turn any codebase into a structured architecture document with one command.**

X-Ray runs professional code analysis tools + AI deep reading to generate a complete project architecture skeleton — module responsibilities, dependency graphs, business call chains, type relationships, and more.

Works with **any language and framework**. TypeScript/JavaScript projects get enhanced analysis via madge and dependency-cruiser.

## What It Does

```
/xray
  → Detects project structure
  → Runs scc, madge, dependency-cruiser (auto-installed)
  → AI reads every module in depth
  → Generates 5 structured docs per target
  → Updates CLAUDE.md with architecture summary
  → Supports incremental analysis (only re-analyzes changed modules)
```

### Output Example

After running `/xray`, you get:

```
docs/codebase/
├── frontend/
│   ├── structure.md      # Directory layout + code stats
│   ├── dependencies.md   # Module dependency graph + circular deps
│   ├── modules.md        # Per-module deep analysis
│   ├── call-chains.md    # Key business flow tracing
│   └── types.md          # Core type/interface relationships
├── backend/
│   ├── structure.md
│   ├── dependencies.md
│   ├── modules.md
│   ├── call-chains.md
│   └── types.md
└── .analysis-meta.json   # Incremental analysis metadata
```

Plus a concise summary injected into your `CLAUDE.md` so Claude always has architectural context.

## Quick Start

### Option 1: One-command install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/Minara-AI/project-xray/main/install.sh | bash
```

The installer lets you choose between global install (`~/.claude/skills/`), per-project install (`.claude/skills/`), or both.

### Option 2: Let Claude install it for you

Copy and paste this prompt into Claude Code:

> Install the X-Ray codebase analysis skill: run **`curl -fsSL https://raw.githubusercontent.com/Minara-AI/project-xray/main/install.sh | bash`** and choose global install. Then tell me it's ready and I can use `/xray setup` to configure my project, or `/xray` to start analysis directly.

### Option 3: Manual install

```bash
# Install globally (available in all projects)
git clone --single-branch --depth 1 https://github.com/Minara-AI/project-xray.git /tmp/project-xray \
  && mkdir -p ~/.claude/skills \
  && cp -r /tmp/project-xray/skills/xray ~/.claude/skills/xray \
  && rm -rf /tmp/project-xray

# Or install into current project (shared with teammates via git)
git clone --single-branch --depth 1 https://github.com/Minara-AI/project-xray.git /tmp/project-xray \
  && mkdir -p .claude/skills \
  && cp -r /tmp/project-xray/skills/xray .claude/skills/xray \
  && rm -rf /tmp/project-xray
```

### First Run

```
/xray setup    # Interactive configuration — detects your project structure
/xray          # Run analysis
```

On first run without setup, X-Ray will automatically guide you through configuration.

## Usage

| Command | Description |
|---------|-------------|
| `/xray` | Auto-detect incremental/full, analyze all targets |
| `/xray setup` | Interactive setup — configure targets, paths, options |
| `/xray [target]` | Analyze a specific target (e.g., `/xray frontend`) |
| `/xray --full` | Force full analysis (ignore cached results) |

## How It Works

### Phase 0: Setup & Environment
- Reads `.xray-config.json` (or runs interactive setup if missing)
- Auto-installs `scc`, `madge`, `dependency-cruiser` as needed

### Phase 1: Incremental Detection
- Compares current commit against last analyzed commit
- Only re-analyzes modules with changes (config file changes trigger full re-analysis)

### Phase 2: Tool Analysis (parallel)
- **scc** — Code statistics (lines, complexity, languages)
- **tree** — Directory structure visualization
- **madge** — Dependency graph, circular dependencies, orphan files (JS/TS only)
- **dependency-cruiser** — Dependency rule validation (JS/TS only)

### Phase 3: AI Deep Reading (parallel agents)
- Round 1: Module identification and responsibility mapping
- Round 2: Per-module deep analysis — business logic, call chains, type relationships

### Phase 4: Output Synthesis
- 5 structured docs per target in `docs/codebase/`
- Architecture summary in `CLAUDE.md`
- AI memory files for persistent context

## Supported Languages & Frameworks

| Language | Framework | Enhanced Analysis |
|----------|-----------|-------------------|
| TypeScript/JavaScript | Next.js, NestJS, React, Express, Fastify | scc + madge + depcruise + AI |
| Go | Standard, Gin, Echo | scc + go mod graph + AI |
| Rust | Standard, Actix, Axum | scc + cargo tree + AI |
| Python | Django, FastAPI, Flask | scc + pipdeptree + AI |
| Java/Kotlin | Spring Boot, Gradle | scc + dependency tree + AI |
| Any other | — | scc + AI deep reading |

## Configuration

X-Ray stores its config in `.xray-config.json` at the project root:

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
    }
  ],
  "outputDir": "docs/codebase",
  "updateClaudeMd": true,
  "updateMemory": true,
  "excludeDirs": ["node_modules", "dist", "coverage", "build"],
  "sameRepo": true
}
```

Run `/xray setup` at any time to reconfigure.

## Requirements

| Requirement | Version | Note |
|-------------|---------|------|
| Claude Code | Latest | CLI, desktop, or IDE extension |
| OS | macOS / Linux | Windows via WSL |
| Git | Any | For incremental analysis |
| scc | Auto-installed | Code statistics |
| madge | Auto-installed | JS/TS dependency graphs (optional) |
| dependency-cruiser | Auto-installed | JS/TS dep rules (optional) |

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE) — free for personal and commercial use.
