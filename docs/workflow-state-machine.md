# SDD Orchestrator — State Machine

## State Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           SDD WORKFLOW                                    │
│                                                                          │
│  USER COMMANDS                                                           │
│  ════════════                                                            │
│                                                                          │
│  ┌──────┐    ┌────────────┐                                              │
│  │ INIT │───▶│ SPEC_DRAFT │──────────────┐                               │
│  └──────┘    └────────────┘              │                               │
│     │              ▲                     ▼                               │
│     │              │            ┌──────────────┐    ┌──────────────┐     │
│     ▼              │            │ SPEC_REVIEW  │───▶│ SPEC_APPROVED│     │
│  ┌──────────┐      │            └──────────────┘    └──────┬───────┘     │
│  │SPEC_BUILD│──────┘                  │                    │             │
│  └──────────┘                   [reject]                   │             │
│   (guided                                                  ▼             │
│    conversation)                                                         │
│     ▲    │                    ┌─────────────────────────────────────┐    │
│     │    │                    │  SDD-GEN PIPELINE (automated)       │    │
│     └────┘                    │                                     │    │
│   (multi-turn)                │                                     │    │
│                               │  ┌─────────┐◀─────────────────┐    │    │
│                               │  │GENERATE │  (loop back if   │    │    │
│                               │  └────┬────┘  audit critical, │    │    │
│                               │       ▼       max 2 loops)    │    │    │
│                               │  ┌─────────┐                  │    │    │
│                               │  │ CHECK   │ (auto-fix+retry) │    │    │
│                               │  └────┬────┘                  │    │    │
│                               │       ▼                       │    │    │
│                               │  ┌─────────┐                  │    │    │
│                               │  │  TEST   │ (mandatory)      │    │    │
│                               │  └────┬────┘                  │    │    │
│                               │       ▼              critical │    │    │
│                               │  ┌─────────┐    ❌───────────┘    │    │
│                               │  │ AUDIT   │                      │    │
│                               │  └────┬────┘                      │    │
│                               │       │ ✅ pass                    │    │
│                               │       ▼                            │    │
│                               │  ┌─────────┐                      │    │
│                               │  │ DELIVER │                      │    │
│                               │  └─────────┘                      │    │
│                               └─────────────────────────────────────┘    │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

## User-Facing Commands

| Command | Description |
|---------|-------------|
| `/sdd:sdd-init <name>` | Creates spec template |
| `/sdd:sdd-build <name>` | Builds spec via guided conversation |
| `/sdd:sdd-review [path]` | Validates spec completeness |
| `/sdd:sdd-gen [path\|--all]` | Full pipeline: generate + check + test + audit + deliver |
| `/sdd:sdd-status` | Shows all specs, statuses, and dependency graph |

## Internal Steps (automated by sdd-gen)

| Step | What it does | On failure |
|------|-------------|------------|
| **Check** | Verifies code matches spec (interfaces, rules, errors) | Auto-corrects and re-checks (max 2 retries) |
| **Test** | Runs all tests (MANDATORY, cannot be skipped) | Auto-fixes code and re-tests (max 2 retries) |
| **Audit** | Reviews code quality, security, performance | If critical: loops back to Generate (max 2 full loops) |

## State Descriptions

### INIT
- **Trigger:** `/sdd:sdd-init <component-name>`
- **Action:** Creates directory structure and `.spec.md` file with template
- **Transition:** → SPEC_DRAFT or → SPEC_BUILD

### SPEC_BUILD
- **Trigger:** `/sdd:sdd-build <component-name>`
- **Action:** Guided multi-turn conversation for requirements discovery
  - Creates session memory in `specs/.memory/<name>.context.md`
  - Guides the dev through: Purpose → Inputs → Outputs → Rules → Errors → Deps
  - Progressively updates the spec with each round
  - Can be paused and resumed (memory persists)
- **Transition:** → SPEC_DRAFT (when conversation completes, status changes to `draft`)

### SPEC_DRAFT
- **Trigger:** Developer edits the `.spec.md` file manually or SPEC_BUILD finishes
- **Action:** Spec is ready for validation
- **Transition:** → SPEC_REVIEW (via `/sdd:sdd-review`)

### SPEC_REVIEW
- **Trigger:** `/sdd:sdd-review <path-to-spec>`
- **Action:** Validates 7 required fields, checks dependency references, detects circular deps
- **Transition:**
  - If valid → SPEC_APPROVED
  - If invalid → SPEC_DRAFT (with gap report)

### SPEC_APPROVED
- **Trigger:** Validation passes successfully
- **Action:** Marks spec as `status: approved` in frontmatter
- **Transition:** → SDD-GEN PIPELINE (via `/sdd:sdd-gen`)

### SDD-GEN PIPELINE (automated)

Single command triggers the full chain:

1. **GENERATE**: Creates code from spec
2. **CHECK**: Verifies consistency (6 checks). Auto-corrects on failure (max 2 retries).
3. **AUDIT**: Reviews quality (6 dimensions). Auto-corrects critical issues (max 2 retries).
4. **DELIVER**: Final report with results, warnings, and generated files list.

### Parallel execution with dependencies

For `--all` mode, specs are organized in waves:

```
Wave 1 (no dependencies — parallel): user-auth, database
Wave 2 (depends on Wave 1 — parallel): payment, notification
Wave 3 (depends on Wave 2): billing
```

Each spec runs the full pipeline independently. Waves run sequentially.

## Session Memory

`/sdd:sdd-build` maintains context in `specs/.memory/<name>.context.md`:
- **What we know so far** — accumulates information with each round
- **Decisions made** — decisions with justification
- **Open questions** — pending items the dev still needs to resolve
- **Discarded ideas** — discarded ideas and why

This allows pausing and resuming spec construction between Claude Code sessions.
