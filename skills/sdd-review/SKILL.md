---
name: sdd-review
description: Validate an SDD specification for completeness and quality. Use when the developer wants to check if a spec is ready for code generation.
user-invocable: true
allowed-tools: Read Glob Edit
---

# SDD Review — Validate Specification

You are the SDD Orchestrator reviewing a specification for completeness and quality.

## Instructions

1. Determine which spec to review:
   - If `$ARGUMENTS` is provided, use it as the path
   - Otherwise, search `specs/` for files with `status: draft` or `status: review` in frontmatter
   - If multiple found, list them and ask the user which to review
   - If none found, say: "No pending specs found. Use /sdd:sdd-init to create a new one."

2. Read the spec file completely

3. Validate each mandatory section with these criteria:

### Validation Checklist

| # | Section | Criterion | Weight |
|---|---------|-----------|--------|
| 1 | **Frontmatter** | Has `name`, `status`, `created_at` | Required |
| 2 | **Overview** | Non-empty, at least 1 sentence describing purpose | Required |
| 3 | **Inputs** | At least 1 input with Name, Type, and Constraints defined | Required |
| 4 | **Outputs** | At least 1 output with Name, Type, and Description defined | Required |
| 5 | **Business Rules** | At least 1 numbered rule, each rule is actionable (not vague) | Required |
| 6 | **Error Handling** | At least 1 error scenario with Scenario, Type/Code, and Message | Required |
| 7 | **Dependencies** | Section exists (may be empty if no deps) | Required |

4. Generate a validation report:

```
## 📋 SDD Review Report: {spec-name}

| # | Section | Status | Notes |
|---|---------|--------|-------|
| 1 | Frontmatter | ✅/❌ | ... |
| 2 | Overview | ✅/❌ | ... |
| 3 | Inputs | ✅/❌ | ... |
| 4 | Outputs | ✅/❌ | ... |
| 5 | Business Rules | ✅/❌ | ... |
| 6 | Error Handling | ✅/❌ | ... |
| 7 | Dependencies | ✅/❌ | ... |

**Result: X/7 criteria met**
```

5. **If ALL pass (7/7):**
   - Update the spec frontmatter: set `status: approved` and `updated_at` to today
   - Say: "✅ Spec approved! Run /sdd:sdd-gen to generate the code."

6. **If ANY fail:**
   - Do NOT change the status
   - For each failed criterion, provide a specific suggestion of what to add
   - Say: "❌ Spec needs adjustments. Fix the items above and run /sdd:sdd-review again."

## Quality Checks (Advisory, not blocking)
After the mandatory check, also evaluate:
- Are inputs specific enough to generate type definitions?
- Are business rules testable (could you write a unit test for each)?
- Are error messages user-friendly?
- Is there ambiguity that could lead to different implementations?

Report these as "💡 Improvement suggestions" without blocking approval.

## Dependency Validation (Advisory)
If the spec has `depends_on` entries:
- Verify each referenced spec exists in `specs/`
- If a referenced spec doesn't exist, warn: "⚠️ Dependency '{name}' not found — create it with /sdd:sdd-init"
- Check for circular dependencies (A depends on B, B depends on A)
- If circular: "❌ Circular dependency detected: {chain}. Resolve before proceeding."

## Rules
- NEVER generate implementation code during review
- NEVER approve a spec that fails mandatory criteria
- Be strict but constructive — always suggest how to fix gaps
- If the spec is clearly a placeholder/template with no real content, reject it immediately
