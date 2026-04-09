# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-04-09

### Added

- **`/sdd:sdd-init`** — Create new specs from template. Auto-creates `sdd.config.json` with default audit configuration.
- **`/sdd:sdd-build`** — Interactive guided spec builder with multi-turn conversation. Supports session memory (`specs/.memory/`) for pause/resume across sessions.
- **`/sdd:sdd-review`** — Validates specs against 7 mandatory criteria (frontmatter, overview, inputs, outputs, business rules, error handling, dependencies). Detects circular dependencies.
- **`/sdd:sdd-gen`** — Full automated pipeline: Generate → Check → Test → Audit → Deliver.
  - Supports single spec, multiple specs, or `--all` mode
  - Parallel generation via subagents with dependency-aware wave execution
  - Automatic consistency check with auto-correction (max 2 retries)
  - Mandatory test execution (never skipped)
  - Quality audit with configurable dimensions
  - Loop-back on critical audit failures (max 2 full loops)
  - Real-time progress reporting
- **`/sdd:sdd-status`** — Overview of all specs with status, dependency graph, and stale spec detection.
- **Spec dependency chain** — `depends_on` and `unlocks` fields in spec frontmatter. Enforced at generation time with topological sort for execution order.
- **Configurable audit** via `sdd.config.json` — Enable/disable dimensions, set severity (error vs warning), toggle individual rules, set thresholds (e.g., min test coverage).
- **Optional external security tools** — Semgrep, npm audit, Trivy support (disabled by default, zero dependencies).
- **Marketplace support** — Install via `/plugin marketplace add viamus/claude-sdd-plugin`.

### Internal

- `sdd-check` — Consistency verification (6 checks: interfaces, outputs, business rules, error handling, extras, dependencies)
- `sdd-audit` — Quality audit across 6 configurable dimensions (code quality, error handling, security, test coverage, performance, documentation)
