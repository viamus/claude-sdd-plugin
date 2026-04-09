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
- `/sdd:sdd-gen` — Full pipeline: generate code + consistency check + quality audit + deliver
- `/sdd:sdd-status` — Shows the state of all specs and dependency graph

## Pipeline (automated by sdd-gen)

```
Generate → Consistency Check → Quality Audit → Deliver
              ↑ auto-fix            ↑ auto-fix
```

Check and audit are internal steps — the user only runs `/sdd:sdd-gen`.

## Plugin Structure

```
claude-sdd-plugin/
├── .claude-plugin/
│   ├── plugin.json            # Plugin manifest
│   └── marketplace.json       # Marketplace catalog
├── skills/
│   ├── sdd-init/SKILL.md     # Create spec
│   ├── sdd-build/SKILL.md    # Build spec via conversation
│   ├── sdd-review/SKILL.md   # Validate spec
│   ├── sdd-gen/SKILL.md      # Full pipeline
│   ├── sdd-check/SKILL.md    # (internal) Consistency check
│   ├── sdd-audit/SKILL.md    # (internal) Quality audit
│   └── sdd-status/SKILL.md   # Status + dependency graph
├── templates/
│   └── spec-template.md
└── docs/
```
