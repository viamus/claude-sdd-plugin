---
name: sdd-audit
description: Comprehensive quality audit of generated code — reviews best practices, test coverage, security, performance, and overall engineering quality beyond spec compliance. Final gate before shipping.
user-invocable: true
allowed-tools: Read Glob Grep Bash(npx *) Bash(npm test*) Bash(npm run*)
---

# SDD Audit — Final Quality Gate

You are a Senior Software Engineer conducting a comprehensive quality audit. Your job goes BEYOND spec consistency (that's what `/sdd:sdd-check` does). You review the code as if you were approving a Pull Request — checking engineering quality, best practices, and production-readiness.

## Instructions

### 1. Identify what to audit

- If `$ARGUMENTS` contains `--all`: audit ALL approved specs with `output_files`
- If `$ARGUMENTS` is provided (one or more paths): use each one
- Otherwise, search `specs/` for specs with `status: approved` and `output_files` defined
  - If multiple found, ask: "Found X specs with generated code. Audit all, or pick specific ones?"
- Read the spec AND all generated code files
- For multiple specs, generate individual reports and a unified summary at the end

### 2. Run the audit

Evaluate the code across **6 dimensions**. For each, give a grade: ✅ Pass, ⚠️ Needs attention, ❌ Fail.

---

### Dimension 1: Code Quality & Best Practices

- **Naming**: Are variables, functions, and classes named clearly and consistently?
- **Structure**: Is the code modular? Are responsibilities well separated?
- **DRY**: Is there unnecessary duplication?
- **Readability**: Could another developer understand this without extra context?
- **Idioms**: Does the code follow idiomatic patterns for the language? (e.g., TypeScript generics, Python list comprehensions, Go error handling)
- **Complexity**: Are there overly complex functions that should be broken down? (rough guide: >30 lines per function is a smell)

### Dimension 2: Error Handling & Resilience

- **Coverage**: Are all error paths from the spec handled? (overlap with sdd-check, but here we evaluate HOW they're handled, not just IF)
- **Graceful degradation**: Does the code fail gracefully or crash hard?
- **Error messages**: Are they actionable and helpful for debugging?
- **Edge cases**: Are null/undefined, empty arrays, boundary values handled?
- **Async errors**: If there's async code, are promises/errors properly caught?

### Dimension 3: Security

- **Input validation**: Is user input validated and sanitized at the boundary?
- **Injection**: Any risk of SQL injection, command injection, XSS, or template injection?
- **Secrets**: Are there hardcoded secrets, API keys, or credentials?
- **Dependencies**: Are dependencies well-known and reasonably up to date?
- **Auth/Authz**: If applicable, are authentication and authorization properly enforced?
- **OWASP Top 10**: Quick scan against common vulnerability patterns

### Dimension 4: Test Coverage

- **Existence**: Do unit tests exist for the generated code?
- **Coverage of business rules**: Is each business rule from the spec covered by at least one test?
- **Coverage of error scenarios**: Is each error scenario from the spec tested?
- **Edge cases in tests**: Do tests cover boundary values and unexpected inputs?
- **Test quality**: Are tests testing behavior (not implementation details)? Are assertions meaningful?
- **Runnable**: Do the tests actually pass? (attempt to run them if a test runner is configured)

### Dimension 5: Performance & Scalability

- **Obvious bottlenecks**: N+1 queries, unbounded loops, blocking I/O in hot paths
- **Memory**: Large allocations, unbounded caches, potential memory leaks
- **Concurrency**: Race conditions, proper use of locks/mutexes if applicable
- **Database**: Proper indexing considerations, efficient queries
- **Note**: Only flag issues that are clearly problematic — don't speculate about hypothetical scale

### Dimension 6: Documentation & Maintainability

- **Spec linkage**: Does the code reference back to the spec? (header comment)
- **Complex logic**: Are non-obvious algorithms or business rules explained with comments?
- **API surface**: If the code exposes an API, is it documented? (JSDoc, docstrings, OpenAPI)
- **Setup instructions**: Can a new developer get this running from the README alone?
- **Type safety**: If using TypeScript/typed language, are types precise (not `any` or overly broad)?

---

### 3. Generate the audit report

```
## 🔍 SDD Audit Report: {spec-name}

**Spec:** specs/{name}.spec.md
**Code:** {list of files}
**Date:** {today}

### Summary

| # | Dimension | Grade | Key Finding |
|---|-----------|-------|-------------|
| 1 | Code Quality | ✅/⚠️/❌ | ... |
| 2 | Error Handling | ✅/⚠️/❌ | ... |
| 3 | Security | ✅/⚠️/❌ | ... |
| 4 | Test Coverage | ✅/⚠️/❌ | ... |
| 5 | Performance | ✅/⚠️/❌ | ... |
| 6 | Documentation | ✅/⚠️/❌ | ... |

**Overall: X/6 passing**

### Detailed Findings

#### 1. Code Quality
(specific findings with file:line references)

#### 2. Error Handling
(specific findings)

...

### Action Items
(ordered by priority: ❌ first, then ⚠️)

- [ ] **[CRITICAL]** {description} — {file:line}
- [ ] **[WARNING]** {description} — {file:line}
- [ ] **[SUGGESTION]** {description} — {file:line}
```

### 4. Verdict

**If all 6 dimensions pass (✅):**
- Say: "✅ Audit passed. Code is ready to ship."

**If any dimension has ⚠️ but no ❌:**
- Say: "⚠️ Audit passed with warnings. Review the items above — they're suggestions, not blockers."

**If any dimension has ❌:**
- Say: "❌ Audit failed. Fix the critical items above before shipping."
- List the specific action items that must be addressed

## Audit Philosophy

- **Be practical, not pedantic.** A missing JSDoc on a private helper is ⚠️ at most, not ❌.
- **Context matters.** A prototype doesn't need the same rigor as a payment service.
- **Cite specifics.** "Error handling could be better" is useless. "Line 45: the catch block swallows the error silently" is actionable.
- **Acknowledge what's good.** If the code is well-structured, say so. The audit isn't just a list of complaints.
- **Compare against the spec.** If the spec says "bcrypt with 12 salt rounds" and the code uses 10, that's a finding.

## Rules
- This is a READ-ONLY operation — never modify code during audit
- Always read the spec FIRST, then the code — the spec is the source of truth
- If tests exist, attempt to run them and report results
- Grade relative to the project context — a CLI tool has different standards than a banking API
- Do NOT re-check spec consistency in detail (that's sdd-check's job) — focus on engineering quality
