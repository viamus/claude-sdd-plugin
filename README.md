# SDD Orchestrator — Plugin for Claude Code

Plugin that enforces **Spec-Driven Design (SDD)** in Claude Code: code is only generated after a specification is created, validated, and approved.

## What it does

- **Spec-First Workflow**: Guides developers to write specs before code
- **Contract Validation**: Validates that the spec has inputs, outputs, business rules, and error handling
- **Dependency Chain**: Specs can declare predecessors/successors, enforced at generation time
- **Automated Pipeline**: Generation includes automatic consistency check, quality audit, and self-correction
- **Parallel Generation**: Multiple specs generated simultaneously, respecting dependency order

## Installation

### Via Marketplace

```bash
# Add the marketplace
/plugin marketplace add viamus/claude-sdd-plugin

# Install the plugin
/plugin install sdd@viamus-sdd
```

### Local development

```bash
# Clone the repository
git clone https://github.com/viamus/claude-sdd-plugin.git

# Use with --plugin-dir to test
claude --plugin-dir ./claude-sdd-plugin
```

## Usage

### Complete workflow

```
1. /sdd:sdd-init user-auth       → Creates specs/user-auth.spec.md (empty template)
2. /sdd:sdd-build user-auth      → Builds the spec via guided conversation (recommended)
   (or edit the spec manually)
3. /sdd:sdd-review                → Validates the spec (7 criteria)
4. /sdd:sdd-gen                   → Generates code + auto-check + auto-audit + delivers
5. /sdd:sdd-status                → Overview of all specs and dependency graph
```

### Commands

| Command | Description |
|---------|-------------|
| `/sdd:sdd-init <name>` | Creates a new spec from the template |
| `/sdd:sdd-build <name>` | Builds the spec via guided conversation |
| `/sdd:sdd-review [path]` | Validates spec completeness |
| `/sdd:sdd-gen [path\|--all]` | Full pipeline: generate + check + audit + deliver |
| `/sdd:sdd-status` | Shows all specs, statuses, and dependency graph |

### What `/sdd:sdd-gen` does automatically

```
Generate code from spec
  ↓
Consistency Check (does code match spec?)
  → If issues: auto-correct → re-check (max 2 retries)
  ↓
Quality Audit (best practices, security, tests, performance)
  → If critical issues: auto-correct → re-audit (max 2 retries)
  ↓
Deliver (final report with results)
```

### Spec dependencies

Specs can declare dependencies on other specs:

```yaml
---
name: payment
depends_on: [user-auth, database]   # must be implemented first
unlocks: [billing]                   # can be implemented after this
---
```

When running `/sdd:sdd-gen --all`, specs are generated in waves respecting the dependency chain. Specs at the same level run in parallel.

### Example spec

```markdown
---
name: user-auth
status: draft
created_at: 2026-04-09
updated_at: 2026-04-09
depends_on: []
unlocks: [payment, notification]
output_files: []
---

# User Auth — Specification

## Overview
User authentication module via email/password with JWT.

## Inputs
| Name | Type | Required | Constraints | Example |
|------|------|----------|-------------|---------|
| email | string | Yes | valid email format | "user@example.com" |
| password | string | Yes | min 8 chars, 1 uppercase, 1 number | "Pass1234" |

## Outputs
| Name | Type | Description | Example |
|------|------|-------------|---------|
| token | string | JWT valid for 24h | "eyJhbG..." |
| user | object | Authenticated user data | { id, email, name } |

## Business Rules
1. Email must be unique in the system
2. Password is stored with bcrypt (salt rounds: 12)
3. JWT token expires in 24 hours
4. Maximum 5 login attempts per IP within 15 minutes

## Error Handling
| Scenario | Code/Type | Message | Recovery Action |
|----------|-----------|---------|-----------------|
| Email not found | 401 | "Invalid credentials" | None (do not reveal if email exists) |
| Wrong password | 401 | "Invalid credentials" | Increment attempt counter |
| Rate limit exceeded | 429 | "Too many attempts. Try again in 15 minutes" | Temporarily block IP |

## Dependencies
- bcrypt: password hashing
- jsonwebtoken: JWT generation
```

## Plugin Structure

```
claude-sdd-plugin/
├── .claude-plugin/
│   ├── plugin.json                # Plugin manifest
│   └── marketplace.json           # Marketplace catalog
├── skills/
│   ├── sdd-init/SKILL.md         # Create spec (template)
│   ├── sdd-build/SKILL.md        # Build spec via conversation
│   ├── sdd-review/SKILL.md       # Validate spec
│   ├── sdd-gen/SKILL.md          # Full pipeline: generate + check + audit
│   ├── sdd-check/SKILL.md        # (internal) Consistency verification
│   ├── sdd-audit/SKILL.md        # (internal) Quality audit
│   └── sdd-status/SKILL.md       # Workflow status + dependency graph
├── templates/
│   └── spec-template.md          # Default template
├── docs/
│   ├── workflow-state-machine.md
│   └── plugin-specification.md
├── CLAUDE.md                      # Persistent SDD context
└── README.md
```

## Development

```bash
# Test locally
claude --plugin-dir ./claude-sdd-plugin

# Validate the plugin
/plugin validate

# Reload after changes
/reload-plugins
```

## Philosophy

> "No code without a contract. No contract without validation."

The SDD Orchestrator treats specifications as first-class citizens. Just as a compiler rejects code with type errors, this plugin rejects code without a specification.
