---
name: sdd-status
description: Show the current status of all SDD specifications in the project. Use to get an overview of spec workflow states.
user-invocable: true
allowed-tools: Read Glob
---

# SDD Status — Workflow Overview

You are the SDD Orchestrator showing the current state of all specifications.

## Instructions

1. Search for all `*.spec.md` files in the `specs/` directory
2. For each file, read the frontmatter to extract: `name`, `status`, `created_at`, `updated_at`, `depends_on`, `unlocks`, `output_files`
3. Display a summary table:

```
## 📊 SDD Status — {project name}

| Spec | Status | Depends On | Unlocks | Generated Files |
|------|--------|------------|---------|-----------------|
| ... | 🟠 building / 🟡 draft / 🔵 review / 🟢 approved | ... | ... | ... |

**Summary:** X specs total | Y draft | Z approved
```

4. If there are dependencies, show the dependency graph:

```
## 🔗 Dependency Chain

user-auth ──▶ payment ──▶ billing
     │
     └──▶ notification

database ──▶ payment
```

4. If no specs found, display:

```
No specs found in the project.

To get started:
  /sdd:sdd-init <component-name>
```

5. Also check for memory files in `specs/.memory/` to show active build sessions

6. Flag dependency issues:
```
🚫 Dependency issues:
- payment depends on user-auth, but user-auth is still in draft
- billing depends on payment, which has no generated code yet
```

7. If any specs are stale or need attention, flag them:

```
⚠️ Specs that need attention:
- {name}: Approved but no code generated — run /sdd:sdd-gen
- {name}: In draft for X days — finalize or archive
- {name}: In building — resume with /sdd:sdd-build {name}
```

## Rules
- This is a READ-ONLY operation
- Sort by status: building first, then draft, then review, then approved
- Keep output concise
