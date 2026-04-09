---
name: sdd-check
description: Verify that generated code is consistent with its approved SDD specification. Use to detect drift between spec and implementation.
user-invocable: true
allowed-tools: Read Glob Grep
---

# SDD Check — Consistency Verification

You are the SDD Orchestrator verifying that implementation code is consistent with its specification.

## Instructions

1. Determine which specs to check:
   - If `$ARGUMENTS` contains `--all`: check ALL approved specs with `output_files`
   - If `$ARGUMENTS` is provided (one or more paths): use each one
   - If no arguments: search `specs/` for files with `status: approved` that have `output_files` defined
     - If multiple found, ask: "Found X specs with generated code. Check all, or pick specific ones?"
   - If none found, say: "No specs with generated code found."
   - For multiple specs, process each one and generate a unified summary at the end

2. Read the spec file completely

3. Read the `output_files` listed in the spec frontmatter
   - If `output_files` is empty, try to find related code by matching file names against the spec name

4. Perform consistency checks:

### Check Matrix

| # | Check | How to Verify |
|---|-------|---------------|
| 1 | **Interface Match** | Input types in code match spec's Inputs table |
| 2 | **Output Match** | Return types in code match spec's Outputs table |
| 3 | **Business Rules** | Each numbered rule in spec has corresponding logic in code |
| 4 | **Error Handling** | Each error scenario in spec has a corresponding catch/throw/return |
| 5 | **No Extra Features** | Code doesn't implement functionality not in the spec |
| 6 | **Dependencies Used** | Libraries listed in spec are the ones used in code |

5. Generate consistency report:

```
## 🔍 SDD Consistency Report: {spec-name}

**Spec:** specs/{name}.spec.md
**Code:** {list of code files}

### Results

| # | Check | Status | Details |
|---|-------|--------|---------|
| 1 | Interface Match | ✅/❌ | ... |
| 2 | Output Match | ✅/❌ | ... |
| 3 | Business Rules | ✅/❌ | X/Y rules implemented |
| 4 | Error Handling | ✅/❌ | X/Y scenarios covered |
| 5 | No Extra Features | ✅/⚠️ | ... |
| 6 | Dependencies | ✅/❌ | ... |

### Divergences Found
<!-- List specific mismatches -->

### Recommendations
<!-- For each divergence, suggest: fix code OR update spec -->
```

6. **If ALL pass:**
   - Say: "✅ Code is consistent with the spec. Implementation is in compliance."

7. **If ANY fail:**
   - For each failure, clearly state:
     - What the spec says
     - What the code does
     - Recommendation: adjust the code or update the spec
   - Say: "❌ Divergences found. Fix the code or update the spec."

## Rules
- This is a READ-ONLY operation — never modify code or specs during check
- Be specific about divergences — quote the spec section and the code section
- "No Extra Features" should be a warning (⚠️), not a hard fail, since minor additions may be acceptable
- If the code clearly evolved beyond the spec, recommend updating the spec rather than reverting the code
