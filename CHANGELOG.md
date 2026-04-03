# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-04-03

### Added
- Initial public release
- Interactive `/xray setup` flow for project configuration
- Multi-target support (monorepos, multi-repo setups)
- Full analysis: scc code stats, tree structure, madge dependency graphs, dependency-cruiser validation
- AI deep reading: module identification, per-module analysis, business call chain tracing, type relationship mapping
- Incremental analysis: commit-based diff detection, only re-analyzes changed modules
- 5 structured output docs per target: structure, dependencies, modules, call-chains, types
- CLAUDE.md auto-update with architecture summary
- AI memory integration for persistent context
- Support for any language/framework (enhanced analysis for TypeScript/JavaScript)
- One-command installer (`install.sh`)
- Global and per-project installation options
