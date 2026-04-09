---
name: sdd-audit
description: Internal — Comprehensive quality audit of generated code. Automatically called by sdd-gen after consistency check passes. Configurable via sdd.config.json.
user-invocable: false
allowed-tools: Read Glob Grep Bash(npx *) Bash(npm test*) Bash(npm run*)
---

# SDD Audit — Final Quality Gate

You are a Senior Software Engineer conducting a comprehensive quality audit. Your job goes BEYOND spec consistency (that's what `/sdd:sdd-check` does). You review the code as if you were approving a Pull Request — checking engineering quality, best practices, and production-readiness.

## Configuration

**Before running any checks, read `sdd.config.json` from the project root.** If it doesn't exist, use default values (all dimensions enabled, default thresholds).

The config controls:
- Which dimensions are **enabled/disabled**
- **Severity** per dimension: `"error"` (can trigger loop-back) or `"warning"` (reported but non-blocking)
- **Individual rules** within each dimension (can be toggled on/off)
- **Thresholds** (e.g., `min_coverage_percent: 80`)

Example config excerpt:
```json
{
  "audit": {
    "dimensions": {
      "security": {
        "enabled": true,
        "severity": "error",
        "rules": {
          "check_owasp_top_10": false,
          "check_hardcoded_secrets": true
        }
      },
      "test_coverage": {
        "enabled": true,
        "severity": "error",
        "rules": {
          "min_coverage_percent": 80
        }
      },
      "performance": {
        "enabled": false
      }
    }
  }
}
```

## Instructions

### 1. Load configuration

1. Read `sdd.config.json` from the project root
2. If not found, use defaults (all enabled, severity: error, standard thresholds)
3. Merge: config values override defaults, missing values fall back to defaults

### 2. Identify what to audit

- If `$ARGUMENTS` contains `--all`: audit ALL approved specs with `output_files`
- If `$ARGUMENTS` is provided (one or more paths): use each one
- Otherwise, search `specs/` for specs with `status: approved` and `output_files` defined
- Read the spec AND all generated code files

### 3. Run enabled dimensions

**Only run dimensions where `enabled: true` in config.** Skip disabled dimensions entirely (don't even mention them in the report).

For each enabled dimension, apply only the rules that are `true` in the config.

---

### Dimension 1: Code Quality & Best Practices
**Config key:** `code_quality`
**Default:** enabled, severity: error

| Rule | Config key | Default | What to check |
|------|-----------|---------|---------------|
| Function length | `max_function_lines` | 30 | Functions over N lines are flagged |
| File length | `max_file_lines` | 300 | Files over N lines are flagged |
| Naming | `enforce_naming_convention` | true | Clear, consistent naming |
| DRY | `check_dry` | true | No unnecessary duplication |

Also checks: structure, readability, idiomatic patterns (always on if dimension enabled).

### Dimension 2: Error Handling & Resilience
**Config key:** `error_handling`
**Default:** enabled, severity: error

| Rule | Config key | Default | What to check |
|------|-----------|---------|---------------|
| Graceful degradation | `require_graceful_degradation` | true | Fails gracefully, not crashes |
| Actionable messages | `require_actionable_messages` | true | Error messages help debugging |
| Async errors | `check_async_errors` | true | Promises/errors properly caught |

Also checks: edge cases (null, empty, boundary values) — always on.

### Dimension 3: Security
**Config key:** `security`
**Default:** enabled, severity: error

| Rule | Config key | Default | What to check |
|------|-----------|---------|---------------|
| Input validation | `check_input_validation` | true | User input validated at boundary |
| Injection risks | `check_injection_risks` | true | SQL, command, XSS, template injection |
| Hardcoded secrets | `check_hardcoded_secrets` | true | No API keys, passwords in code |
| OWASP Top 10 | `check_owasp_top_10` | true | Common vulnerability patterns |
| Auth/Authz | `check_auth` | true | Proper authentication/authorization |

**External tools (optional):** The security dimension can optionally run external scanners. These are configured in `sdd.config.json` under `security.external_tools`. Each tool has:
- `name`: tool identifier
- `command`: CLI command to run
- `enabled`: whether to use it (default: false)
- `install_hint`: how to install if missing

**How external tools work:**
1. Only run tools where `enabled: true`
2. Before running, check if the tool is installed (try `which {tool}` or `where {tool}`)
3. If not installed: **skip silently** — log a note in the report: "⏭️ {tool} not found (install: {hint})"
4. If installed: run the command, parse JSON output, include findings in the report
5. External tool findings are **additive** — they supplement Claude's own analysis, not replace it

**Important:** External tools are always optional. The security audit works without any external tools — Claude performs code analysis directly. Tools like Semgrep, npm audit, or Trivy add depth but are not required.

### Dimension 4: Test Coverage
**Config key:** `test_coverage`
**Default:** enabled, severity: error

| Rule | Config key | Default | What to check |
|------|-----------|---------|---------------|
| Min coverage | `min_coverage_percent` | 80 | At least N% of business rules covered |
| Business rule tests | `require_business_rule_tests` | true | Each spec rule has a test |
| Error scenario tests | `require_error_scenario_tests` | true | Each spec error scenario tested |
| Edge case tests | `require_edge_case_tests` | false | Boundary values tested |

### Dimension 5: Performance & Scalability
**Config key:** `performance`
**Default:** disabled, severity: warning

| Rule | Config key | Default | What to check |
|------|-----------|---------|---------------|
| N+1 queries | `check_n_plus_1` | true | No N+1 database query patterns |
| Unbounded loops | `check_unbounded_loops` | true | No loops without limits |
| Memory leaks | `check_memory_leaks` | true | No obvious memory issues |
| Concurrency | `check_concurrency` | false | Race conditions, proper locking |

### Dimension 6: Documentation & Maintainability
**Config key:** `documentation`
**Default:** enabled, severity: warning

| Rule | Config key | Default | What to check |
|------|-----------|---------|---------------|
| Spec linkage | `require_spec_linkage` | true | Code references the spec |
| Complex logic comments | `require_complex_logic_comments` | true | Non-obvious logic explained |
| API docs | `require_api_docs` | false | JSDoc/docstrings on public API |
| Type safety | `require_type_safety` | true | No `any`, precise types |

---

### 4. Generate the audit report

```
## 🔍 SDD Audit Report: {spec-name}

**Spec:** specs/{name}.spec.md
**Code:** {list of files}
**Config:** sdd.config.json (or defaults)

### Summary

| # | Dimension | Severity | Grade | Key Finding |
|---|-----------|----------|-------|-------------|
| 1 | Code Quality | error | ✅/⚠️/❌ | ... |
| 2 | Error Handling | error | ✅/⚠️/❌ | ... |
| 3 | Security | error | ✅/⚠️/❌ | ... |
| 4 | Test Coverage | error | ✅/⚠️/❌ | ... |
| 5 | Performance | ⏭️ skipped | — | disabled in config |
| 6 | Documentation | warning | ✅/⚠️/❌ | ... |

**Enabled: X/6 | Passing: Y/X**

### Action Items
(ordered by priority: ❌ first, then ⚠️)

- [ ] **[CRITICAL]** {description} — {file:line}
- [ ] **[WARNING]** {description} — {file:line}
```

### 5. Verdict

**Only dimensions with `severity: "error"` can trigger a pipeline loop-back.**

Dimensions with `severity: "warning"` are reported but NEVER trigger a loop-back, even if they fail with ❌.

- **All error-severity dimensions pass:** "✅ Audit passed."
- **Warning-severity failures only:** "⚠️ Audit passed with warnings."
- **Any error-severity dimension fails:** "❌ Audit failed. Critical issues need fixing." → triggers loop-back in sdd-gen

## Audit Philosophy

- **Be practical, not pedantic.** A missing JSDoc on a private helper is ⚠️ at most, not ❌.
- **Context matters.** A prototype doesn't need the same rigor as a payment service.
- **Cite specifics.** "Error handling could be better" is useless. "Line 45: the catch block swallows the error silently" is actionable.
- **Acknowledge what's good.** If the code is well-structured, say so.
- **Compare against the spec.** If the spec says "bcrypt with 12 salt rounds" and the code uses 10, that's a finding.
- **Respect the config.** If a dimension is disabled, do not check or report on it.

## Rules
- This is a READ-ONLY operation — never modify code during audit
- Always read `sdd.config.json` FIRST, then the spec, then the code
- If tests exist, attempt to run them and report results
- Grade relative to the project context
- Do NOT re-check spec consistency in detail (that's sdd-check's job)
- Disabled dimensions = invisible. Don't mention them except as "skipped" in the summary table.
