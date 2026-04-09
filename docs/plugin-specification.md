# SDD Orchestrator — Plugin Specification

> The Spec of the Spec: this document defines how the SDD Orchestrator plugin works.

## 1. Overview

The SDD Orchestrator is a plugin for Claude Code that **enforces the Spec-Driven Design methodology** in the development workflow. It ensures that no code is generated without a validated and approved specification.

### Plugin Architecture

```
claude-sdd-plugin/
├── .claude/
│   ├── settings.json              # Interception hooks
│   └── skills/
│       ├── sdd-init/SKILL.md      # Create spec
│       ├── sdd-review/SKILL.md    # Validate spec
│       ├── sdd-gen/SKILL.md       # Generate code
│       ├── sdd-check/SKILL.md     # Verify consistency
│       └── sdd-status/SKILL.md    # Workflow status
├── hooks/
│   └── spec-enforcer.sh           # Hook that blocks code-gen without spec
├── templates/
│   └── spec-template.md           # Default spec template
├── docs/
│   ├── workflow-state-machine.md  # State machine
│   └── plugin-specification.md    # This file
├── CLAUDE.md                      # Persistent plugin context
└── README.md                      # Usage instructions
```

## 2. Interface — Inputs and Outputs

### 2.1 `/sdd-init <component-name>`

**Input:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| component-name | string | Yes | Name of the component/feature to specify |

**Output:**
- Creates file `specs/<component-name>.spec.md` with filled template
- Displays confirmation message with next steps

**Behavior:**
1. Receives the component name via `$ARGUMENTS`
2. Creates `specs/` directory if it doesn't exist
3. Generates `.spec.md` file using the template in `templates/spec-template.md`
4. Fills in the `name` and `created_at` fields in the frontmatter
5. Displays instructions for the dev to fill in the spec

**Errors:**
| Scenario | Message | Action |
|----------|---------|--------|
| Name not provided | "Usage: /sdd-init <component-name>" | Displays help |
| Spec already exists | "Spec 'X' already exists at specs/X.spec.md" | Asks whether to overwrite |

---

### 2.2 `/sdd-review [path]`

**Input:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| path | string | No | Path to the spec. If omitted, searches for pending specs |

**Output:**
- Validation report with completeness checklist
- If valid: marks spec as `status: approved`
- If invalid: lists gaps with correction suggestions

**Behavior:**
1. Reads the `.spec.md` file
2. Validates presence and quality of each required section:

| Section | Validation |
|---------|------------|
| `## Inputs` | Has at least 1 input with defined type |
| `## Outputs` | Has at least 1 output with defined type |
| `## Business Rules` | Has at least 1 documented rule |
| `## Error Handling` | Has at least 1 error scenario |
| `## Dependencies` | Section exists (may be empty) |

3. Generates report with ✅/❌ for each criterion
4. If all pass: updates frontmatter `status: approved`
5. If fails: returns detailed gap report

**Errors:**
| Scenario | Message |
|----------|---------|
| File not found | "Spec not found at: {path}" |
| Invalid format | "The file does not follow the SDD template. Use /sdd-init to create a valid spec" |

---

### 2.3 `/sdd-gen [path]`

**Input:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| path | string | No | Path to the approved spec |

**Output:**
- Source code generated according to the specification
- Files created at the paths defined in the spec

**Behavior:**
1. Reads the spec and verifies `status: approved` in the frontmatter
2. If not approved: blocks and redirects to `/sdd-review`
3. Injects the full spec content as context
4. Instructs Claude to generate code **strictly** according to:
   - Input/output interfaces as defined
   - Business rules as documented
   - Error handling as specified
5. After generation, automatically runs `/sdd-check`

**Errors:**
| Scenario | Message |
|----------|---------|
| Spec not approved | "This spec has not been approved yet. Run /sdd-review first" |
| Spec not found | "No approved spec found" |

---

### 2.4 `/sdd-check [path]`

**Input:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| path | string | No | Path to the spec to verify |

**Output:**
- Consistency report: spec vs code
- List of divergences found

**Behavior:**
1. Reads the approved spec
2. Identifies the generated code files (`output_files` field in the spec or name heuristics)
3. For each code file, verifies:
   - Exported functions/classes match the spec
   - Parameter types match
   - Error handling implemented for each scenario in the spec
   - No "extra" functionality not specified in the spec
4. Generates conformance report

**Errors:**
| Scenario | Message |
|----------|---------|
| Code not found | "No generated code found for this spec" |
| Spec without approved status | "Only approved specs can be verified" |

---

### 2.5 `/sdd-status`

**Input:** None

**Output:**
- Table with all project specs and their current states

**Behavior:**
1. Searches for all `*.spec.md` files in the `specs/` directory
2. Reads the frontmatter of each one
3. Displays table:

```
| Spec                | Status   | Last Updated       |
|---------------------|----------|--------------------|
| user-auth.spec.md   | approved | 2026-04-09         |
| payment.spec.md     | draft    | 2026-04-08         |
| notification.spec.md| review   | 2026-04-09         |
```

## 3. Interception Hook (Spec-First Enforcement)

### spec-enforcer.sh

**Trigger:** `PreToolUse` on tools `Write` and `Edit`

**Logic:**
```
IF the file being created/edited is source code (.ts, .js, .py, etc.)
  AND there is NO corresponding approved spec
  AND it is NOT a spec, test, config, or doc file
THEN
  Block with guidance message
ELSE
  Allow the operation
```

**Configuration in settings.json:**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/hooks/spec-enforcer.sh\"",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

**Exceptions (files that are NOT blocked):**
- `*.spec.md` — spec files
- `*.test.*` / `*.spec.*` — test files
- `*.md` — documentation
- `*.json` / `*.yaml` / `*.yml` — configuration
- `*.sh` — plugin's own scripts
- Any file inside `hooks/`, `templates/`, `docs/`, `.claude/`

## 4. Spec Template

The default template generated by `/sdd-init`:

```markdown
---
name: {component-name}
status: draft
created_at: {date}
updated_at: {date}
output_files: []
---

# {Component Name} — Specification

## Overview
<!-- Describe the purpose of this component in 2-3 sentences -->

## Inputs
<!-- Define each input with type, constraints, and examples -->

| Name | Type | Required | Constraints | Example |
|------|------|----------|-------------|---------|
| | | | | |

## Outputs
<!-- Define each output with type and examples -->

| Name | Type | Description | Example |
|------|------|-------------|---------|
| | | | |

## Business Rules
<!-- List each business rule as a numbered item -->

1.

## Error Handling
<!-- Define each error scenario -->

| Scenario | Code/Type | Message | Recovery Action |
|----------|-----------|---------|-----------------|
| | | | |

## Dependencies
<!-- List required libraries, APIs, or services -->

- 

## Notes
<!-- Design decisions, trade-offs, references -->
```

## 5. Context Injection

### How it works

When a spec is approved (`/sdd-review` → status: approved), the `/sdd-gen` skill injects the spec content directly into the generation prompt. This ensures that Claude Code has the complete contract before generating any line of code.

The project's `CLAUDE.md` contains permanent instructions that make Claude respect the SDD workflow in all interactions.

## 6. Dependencies

| Dependency | Type | Usage |
|------------|------|-------|
| Claude Code CLI | Runtime | Plugin host |
| bash | Runtime | Execution of the spec-enforcer hook |
| jq | Runtime | JSON parsing in the hook |
| git | Optional | Spec versioning |

## 7. Known Limitations

1. The interception hook does not block code generated via `Bash` (e.g., `echo "code" > file.ts`)
2. The consistency validation (`/sdd-check`) is heuristic, not formal
3. Specs must follow the template to be parsed correctly
