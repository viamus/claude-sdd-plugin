---
name: sdd-gen
description: Generate implementation code from approved SDD specifications. Supports single spec, multiple specs, or all approved specs in parallel using subagents. Use after /sdd:sdd-review approves a spec.
user-invocable: true
allowed-tools: Read Glob Write Edit Bash(mkdir *) Bash(npm *) Bash(npx *) Agent
---

# SDD Gen — Generate Code from Spec

You are the SDD Orchestrator generating implementation code strictly from approved specifications.

## Modes of Operation

This skill supports three modes:

| Mode | Trigger | Behavior |
|------|---------|----------|
| **Single** | `/sdd:sdd-gen path/to/spec.spec.md` | Generates code for one spec |
| **Multiple** | `/sdd:sdd-gen spec1 spec2 spec3` | Generates code for listed specs in parallel |
| **All** | `/sdd:sdd-gen --all` | Finds all approved specs and generates in parallel |

## Instructions

### 1. Determine which specs to implement

- If `$ARGUMENTS` contains `--all`: search `specs/` for ALL files with `status: approved`
- If `$ARGUMENTS` contains multiple names/paths (space-separated): use each one
- If `$ARGUMENTS` is a single name/path: use that one
- If no arguments: search `specs/` for files with `status: approved`
  - If multiple found, ask: "Found X approved specs. Generate all in parallel, or pick specific ones?"
  - If none found, say: "No approved specs found. Use /sdd:sdd-review to approve a spec."

### 2. Validate all specs before starting

For each spec:
- Read the file
- **GATE CHECK 1 — Approval**: Verify `status: approved` in frontmatter
  - If NOT approved: "⚠️ Skipping {name} — not approved. Run /sdd:sdd-review first."
- **GATE CHECK 2 — Dependency chain**: Check the `depends_on` field in frontmatter
  - For each dependency listed, verify:
    - The dependency spec exists in `specs/`
    - The dependency spec has `status: approved`
    - The dependency spec has `output_files` (code already generated)
  - If ANY dependency is NOT satisfied, **block that spec** with a clear message:

```
🚫 Cannot generate {name} — unmet dependencies:

| Dependency | Status | Code Generated | Issue |
|------------|--------|----------------|-------|
| user-auth | ✅ approved | ✅ yes | OK |
| database | ✅ approved | ❌ no | Needs /sdd:sdd-gen database first |
| payment | ❌ draft | ❌ no | Needs /sdd:sdd-review first |

Resolve the dependencies above, then retry.
```

- If NO specs pass both gates, STOP.
- For `--all` mode: automatically determine the correct **execution order** based on the dependency graph (topological sort). Generate specs with no dependencies first, then their dependents, etc. Specs at the same level can run in parallel.

### 3. Present the implementation plan

#### Single spec mode:

```
## 📦 Implementation Plan: {spec-name}

**Based on spec:** specs/{name}.spec.md

### Files to create:
- `src/{name}.ts` — Main implementation
- `src/{name}.types.ts` — Types and interfaces (if applicable)
- `src/{name}.test.ts` — Unit tests

### Interfaces derived from the spec:
- Input: {input summary}
- Output: {output summary}

### Business rules to implement:
1. {rule 1}
2. {rule 2}

### Error scenarios to cover:
1. {error 1}
2. {error 2}

Do you want to proceed with the generation?
```

#### Multi-spec mode (parallel with dependency awareness):

```
## 📦 Parallel Implementation Plan

### Execution Order (based on dependency chain):

🔵 Wave 1 (no dependencies — run in parallel):
  - user-auth (4 rules, 3 errors)
  - database (2 rules, 2 errors)

🔵 Wave 2 (depends on Wave 1 — run in parallel after Wave 1 completes):
  - payment → depends on: user-auth, database (6 rules, 5 errors)
  - notification → depends on: user-auth (3 rules, 2 errors)

🔵 Wave 3 (depends on Wave 2):
  - billing → depends on: payment (4 rules, 3 errors)

**Total:** 5 specs → ~15 files in 3 waves

⚡ Specs within each wave run in parallel. Waves run sequentially.

Do you want to proceed?
```

### 4. Wait for user confirmation before generating any code

### 5. Generate code

#### Single spec: generate directly

Follow the code generation rules below.

#### Multiple specs: launch parallel subagents

For each spec, launch a subagent using the Agent tool with:
- **description**: "SDD Gen: {spec-name}"
- **prompt**: Include the full spec content and all code generation rules below
- Run subagents **in parallel** (all Agent calls in a single message)

Each subagent must:
1. Read the spec it's assigned
2. Generate all code files for that spec
3. Update the spec frontmatter with `output_files`
4. Report what was generated

After all subagents complete, show a unified summary:

```
## ✅ Parallel Generation Complete

| # | Spec | Status | Files Generated |
|---|------|--------|-----------------|
| 1 | user-auth | ✅ Done | src/user-auth.ts, src/user-auth.test.ts |
| 2 | payment | ✅ Done | src/payment.ts, src/payment.test.ts |
| 3 | notification | ✅ Done | src/notification.ts, src/notification.test.ts |

Next steps:
- /sdd:sdd-check --all  → Verify consistency for all specs
- /sdd:sdd-audit --all  → Run quality audit on all generated code
```

### 6. Code Generation Rules (apply to both single and parallel modes)

- **Interface First**: Start by creating types/interfaces that mirror the spec's Inputs and Outputs tables EXACTLY
- **1:1 Mapping**: Every business rule in the spec = one clearly identifiable block in the code
- **Error Coverage**: Every error scenario in the spec = one error handling branch in the code
- **No Extras**: Do NOT add functionality, parameters, validations, or error cases not in the spec
- **No Stubs**: Every function must be fully implemented, not a placeholder
- **Testable**: Each business rule should be testable in isolation
- **Cross-spec awareness**: When generating multiple specs in parallel, if specs reference each other (shared types, dependencies), ensure consistency between generated files

### Code Header
```
/**
 * Implementation of: specs/{name}.spec.md
 * Generated by SDD Orchestrator
 * DO NOT modify without updating the spec first
 */
```

### 7. After generation

- Update each spec frontmatter: add `output_files` array with paths of generated files, update `updated_at`
- For single spec: automatically trigger consistency check logic (as described in /sdd:sdd-check)
- For multiple specs: suggest running `/sdd:sdd-check --all`

## Rules
- NEVER generate code without an approved spec
- NEVER add features beyond what the spec defines
- ALWAYS link generated code back to the spec
- If the spec is ambiguous on any point, ASK the user rather than guessing
- Generated code should be idiomatic for the target language
- When running parallel, each subagent works independently — they should not depend on each other's output
