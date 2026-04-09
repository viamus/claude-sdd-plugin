# SDD Orchestrator — Plugin for Claude Code

Plugin that enforces **Spec-Driven Design (SDD)** in Claude Code: code is only generated after a specification is created, validated, and approved.

## What it does

- **Spec-First Workflow**: Guides developers to write specs before code
- **Contract Validation**: Validates that the spec has inputs, outputs, business rules, and error handling
- **Context Injection**: Feeds Claude with the spec context before generating code
- **Consistency Check**: Verifies that the generated code is aligned with the spec
- **Quality Audit**: Final gate reviewing best practices, security, tests, and performance

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
4. /sdd:sdd-gen                   → Generates code from the approved spec
5. /sdd:sdd-check                 → Verifies spec consistency
6. /sdd:sdd-audit                 → Final quality gate (best practices, security, tests)
7. /sdd:sdd-status                → Overview of all specs
```

### Commands

| Command | Description |
|---------|-------------|
| `/sdd:sdd-init <name>` | Creates a new spec from the template |
| `/sdd:sdd-build <name>` | Builds the spec via guided conversation |
| `/sdd:sdd-review [path]` | Validates spec completeness |
| `/sdd:sdd-gen [path\|--all]` | Generates code from approved specs (supports parallel) |
| `/sdd:sdd-check [path\|--all]` | Verifies code vs spec consistency |
| `/sdd:sdd-audit [path\|--all]` | Final quality gate (best practices, security, tests, performance) |
| `/sdd:sdd-status` | Shows the state of all specs |

### Example spec

```markdown
---
name: user-auth
status: draft
created_at: 2026-04-09
updated_at: 2026-04-09
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
├── skills/                        # Slash commands (/sdd:*)
│   ├── sdd-init/SKILL.md         # Create spec (template)
│   ├── sdd-build/SKILL.md        # Build spec via conversation
│   ├── sdd-review/SKILL.md       # Validate spec
│   ├── sdd-gen/SKILL.md          # Generate code
│   ├── sdd-check/SKILL.md        # Verify consistency
│   ├── sdd-audit/SKILL.md        # Final quality gate
│   └── sdd-status/SKILL.md       # Workflow status
├── templates/
│   └── spec-template.md          # Default template
├── specs/                         # User specs
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
