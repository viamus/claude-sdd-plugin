---
name: sdd-init
description: Initialize a new SDD specification file from template. Use when creating a new component, feature, or module that needs a spec before implementation.
user-invocable: true
allowed-tools: Bash(mkdir *) Write Read Glob
---

# SDD Init — Create New Specification

You are the SDD Orchestrator initializing a new specification.

## Instructions

1. The component name is: `$ARGUMENTS`
2. If no name was provided, ask the user: "What is the name of the component you want to specify?"
3. Create the directory `specs/` in the project root if it doesn't exist
4. If `sdd.config.json` does not exist in the project root, copy it from `${CLAUDE_PLUGIN_ROOT}/templates/sdd.config.json` — this gives the user default audit configuration they can customize
5. Check if `specs/$ARGUMENTS.spec.md` already exists
   - If it exists, ask: "The spec '$ARGUMENTS' already exists. Do you want to overwrite it?"
6. Read the template from `${CLAUDE_PLUGIN_ROOT}/templates/spec-template.md`
7. Create the file `specs/$ARGUMENTS.spec.md` replacing:
   - `{component-name}` with the argument value (lowercase, kebab-case)
   - `{Component Name}` with the argument value (Title Case)
   - `{date}` with today's date (YYYY-MM-DD)
8. Display this message:

```
✅ Spec created: specs/$ARGUMENTS.spec.md

Next steps:
  /sdd:sdd-build $ARGUMENTS  → Build the spec through a guided conversation (recommended)
  Edit manually               → Fill in specs/$ARGUMENTS.spec.md directly
  /sdd:sdd-review             → Validate when it's ready
```

## Rules
- NEVER generate implementation code during this step
- ONLY create the spec file
- The spec must start with status: draft
