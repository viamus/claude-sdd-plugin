# SDD Orchestrator — Plugin Context

This project uses **Spec-Driven Design (SDD)**. Code should only be generated after an approved specification.

## Fundamental Rules

1. **Spec-First**: Never generate implementation code without a corresponding approved spec in `specs/`. Always ask: "Which approved spec am I following?"
2. **Contract Fidelity**: Generated code must implement EXACTLY what the spec defines — no more, no less. Do not add features, parameters, or behaviors that are not in the spec.
3. **Error Coverage**: Every error scenario defined in the spec MUST have corresponding handling in the code.
4. **No Hallucination**: If the spec does not define a behavior for a specific case, ask the developer instead of making it up.

## Workflow

- `/sdd:sdd-init <name>` — Creates a new spec from the template
- `/sdd:sdd-build <name>` — Builds the spec via guided conversation with the dev
- `/sdd:sdd-review` — Validates whether the spec is complete
- `/sdd:sdd-gen` — Generates code from the approved spec
- `/sdd:sdd-check` — Verifies code vs spec consistency
- `/sdd:sdd-status` — Shows the state of all specs

## Plugin Structure

```
claude-sdd-plugin/
├── .claude-plugin/
│   └── plugin.json            # Plugin manifest
├── skills/                    # Slash commands (namespaced as /sdd:*)
│   ├── sdd-init/SKILL.md
│   ├── sdd-build/SKILL.md
│   ├── sdd-review/SKILL.md
│   ├── sdd-gen/SKILL.md
│   ├── sdd-check/SKILL.md
│   └── sdd-status/SKILL.md
├── hooks/
│   ├── hooks.json             # Hook configuration
│   └── spec-enforcer.sh       # PreToolUse enforcement
├── templates/
│   └── spec-template.md       # Spec template
├── specs/                     # User specs live here
└── docs/                      # Documentation
```
