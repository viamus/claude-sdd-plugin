# SDD Orchestrator — State Machine

## State Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           SDD WORKFLOW                                    │
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
│   (guided                           │                      ▼             │
│    conversation)                    │              ┌────────────┐        │
│     ▲    │                          │              │  CODE_GEN  │        │
│     │    │                          │              └─────┬──────┘        │
│     └────┘                          │                    │               │
│   (multi-turn)                      │                    ▼               │
│                                     │           ┌────────────────┐       │
│                                     │           │CONSISTENCY_CHECK│      │
│                                     │           └───────┬────────┘       │
│                                     │             pass/ │ \fail          │
│                                     │                  ▼    ▼            │
│                                     │          ┌──────┐ ┌────────┐      │
│                                     │          │ DONE │ │CODE_GEN│      │
│                                     │          └──────┘ └────────┘      │
│                                     │                                    │
│  [user tries to write code without spec]                                 │
│           ▼                                                              │
│    ┌───────────┐                                                         │
│    │ BLOCKED   │── "Create the spec first with /sdd:sdd-init"           │
│    └───────────┘                                                         │
└──────────────────────────────────────────────────────────────────────────┘
```

## State Descriptions

### INIT
- **Trigger:** `/sdd:sdd-init <component-name>`
- **Action:** Creates directory structure and `.spec.md` file with template
- **Transition:** → SPEC_DRAFT or → SPEC_BUILD

### SPEC_BUILD (new)
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
- **Action:** Validates that the spec has all required fields:
  - ✅ Inputs defined (types, formats, constraints)
  - ✅ Outputs defined (types, formats)
  - ✅ Business Rules documented
  - ✅ Error Handling specified
  - ✅ Dependencies listed
- **Transition:**
  - If valid → SPEC_APPROVED
  - If invalid → SPEC_DRAFT (with gap report)

### SPEC_APPROVED
- **Trigger:** Validation passes successfully
- **Action:** 
  - Marks spec as `status: approved` in frontmatter
- **Transition:** → CODE_GEN (via `/sdd:sdd-gen`)

### CODE_GEN
- **Trigger:** `/sdd:sdd-gen <path-to-spec>`
- **Action:** Generates code based exclusively on the approved spec
- **Transition:** → CONSISTENCY_CHECK

### CONSISTENCY_CHECK
- **Trigger:** Automatic after CODE_GEN
- **Action:** `/sdd:sdd-check` validates that:
  - All interfaces from the spec are implemented
  - Input/output types match
  - Error handling covers the specified scenarios
- **Transition:**
  - If consistent → DONE
  - If divergent → CODE_GEN (with divergence report)

### BLOCKED
- **Trigger:** PreToolUse hook detects an attempt to create code without an approved spec
- **Action:** Blocks the operation and guides the dev to create the spec first
- **Transition:** → INIT

## Commands (Slash Commands)

| Command | State | Description |
|---------|-------|-------------|
| `/sdd:sdd-init <name>` | → SPEC_DRAFT | Creates spec template |
| `/sdd:sdd-build <name>` | → SPEC_BUILD | Builds spec via guided conversation |
| `/sdd:sdd-review [path]` | SPEC_DRAFT → SPEC_REVIEW | Validates spec completeness |
| `/sdd:sdd-gen [path]` | SPEC_APPROVED → CODE_GEN | Generates code from spec |
| `/sdd:sdd-check [path]` | CODE_GEN → CONSISTENCY_CHECK | Verifies consistency |
| `/sdd:sdd-status` | Any | Shows current workflow state |

## Session Memory

`/sdd:sdd-build` maintains context in `specs/.memory/<name>.context.md`:
- **What we know so far** — accumulates information with each round
- **Decisions made** — decisions with justification
- **Open questions** — pending items the dev still needs to resolve
- **Discarded ideas** — discarded ideas and why

This allows pausing and resuming spec construction between Claude Code sessions.
