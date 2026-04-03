# Contributing to X-Ray

Thanks for your interest in contributing! Here's how to get started.

## Project Structure

```
project-xray/
├── skills/xray/
│   └── SKILL.md        # The skill definition (core logic)
├── install.sh           # One-command installer
├── README.md            # English documentation
├── README_CN.md         # Chinese documentation
├── CONTRIBUTING.md      # This file
├── CHANGELOG.md         # Version history
├── LICENSE              # MIT license
├── package.json         # Project metadata
└── .gitignore
```

## How X-Ray Works

X-Ray is a **Claude Code skill** — a markdown file (`SKILL.md`) that instructs Claude how to perform deep codebase analysis. It does not contain executable code; instead, it provides structured instructions that Claude follows when a user invokes `/xray`.

The skill orchestrates:
1. External tools (scc, madge, dependency-cruiser) for static analysis
2. AI deep reading for semantic understanding
3. Structured output generation

## How to Contribute

### Reporting Issues

- Use GitHub Issues for bug reports and feature requests
- Include your project type (language, framework, monorepo vs single repo)
- Include relevant error output or unexpected behavior

### Improving the Skill

The main file to edit is `skills/xray/SKILL.md`. When making changes:

1. **Test with different project types** — try it on a JS/TS project, a Go project, a Python project, etc.
2. **Keep it language-agnostic** — new features should work for all languages, with optional enhancements for specific ones
3. **Preserve incremental analysis** — changes should not break the incremental detection logic
4. **Keep output format stable** — other tools may depend on the doc structure

### Adding Language Support

To add enhanced analysis for a new language:

1. Add tool commands in Phase 2 (similar to how madge/depcruise are used for JS/TS)
2. Add framework-specific module detection patterns in Phase 3.1
3. Update the supported languages table in README.md
4. Test with a real project in that language

### Pull Request Process

1. Fork the repo and create a branch
2. Make your changes
3. Test with at least one real project
4. Update CHANGELOG.md
5. Submit a PR with a clear description of what changed and why

## Code of Conduct

Be kind and constructive. We're all here to build useful tools.
