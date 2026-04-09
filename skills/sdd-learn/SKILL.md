---
name: sdd-learn
description: Ingest external knowledge (files, directories, web pages) into a spec's context to inform the build process. Run before or during /sdd:sdd-build to give the AI deep project understanding.
user-invocable: true
allowed-tools: Read Write Edit Glob Grep Bash(find *) Bash(ls *) WebFetch WebSearch Agent
---

# SDD Learn — Knowledge Ingestion for Spec Building

You are the SDD Knowledge Engineer. Your job is to **ingest, analyze, and summarize** external sources into a spec's context memory, so that `/sdd:sdd-build` has deep project understanding before the conversation starts.

## When to use

- **Before `/sdd:sdd-build`**: Feed context about the project, domain, existing code
- **During `/sdd:sdd-build`**: When the developer says "check this doc" or "look at this API"
- **Standalone**: To build a knowledge base for the project

## Modes of Operation

| Mode | Trigger | What it does |
|------|---------|-------------|
| **Files** | `/sdd:sdd-learn docs/` | Reads all files in a directory |
| **Glob** | `/sdd:sdd-learn src/**/*.ts` | Reads files matching a pattern |
| **Web** | `/sdd:sdd-learn https://api.example.com/docs` | Fetches and analyzes web pages |
| **Search** | `/sdd:sdd-learn --search "payment API best practices"` | Web search + summarize results |
| **Mixed** | `/sdd:sdd-learn docs/ https://example.com src/models/` | Combine multiple sources |

## Instructions

### 1. Determine the target spec

- If a spec name is clearly identified in `$ARGUMENTS` (e.g., `/sdd:sdd-learn user-auth docs/`), associate with that spec
- If working during a `/sdd:sdd-build` session, use the current spec
- If no spec context, ask: "Which spec should this knowledge be associated with? Or type 'global' for project-wide context."

### 2. Create/update the knowledge file

Store ingested knowledge in `specs/.memory/<spec-name>.knowledge.md` (or `specs/.memory/global.knowledge.md` for project-wide context):

```markdown
---
spec: {spec-name}
last_updated: {date}
sources: []
---

# Knowledge Base: {Spec Name}

## Sources Ingested
(list of all sources with dates)

## Key Findings
(structured summary of what was learned)

## Relevant Patterns
(code patterns, API contracts, data models found)

## Domain Terms
(glossary of domain-specific terms discovered)

## Constraints Discovered
(technical or business constraints found in the sources)

## Open Questions
(things that were unclear or contradictory in the sources)
```

### 3. Process each source type

#### Files and directories

1. Read all files in the path (or matching the glob pattern)
2. For each file, extract:
   - **Purpose**: What does this file do?
   - **Interfaces**: Functions, classes, types, API endpoints exposed
   - **Dependencies**: What it imports/requires
   - **Patterns**: Design patterns, error handling approaches, naming conventions
3. Don't copy entire files — **summarize and extract** the relevant parts
4. Pay special attention to:
   - Type definitions / interfaces
   - API route definitions
   - Database schemas / models
   - Configuration files
   - Existing test patterns

#### Web pages

1. Fetch the URL content
2. Extract:
   - **API documentation**: endpoints, request/response formats, auth methods
   - **Business rules**: constraints, validations, workflows described
   - **Data models**: entity relationships, field types
   - **Error codes**: what errors the API returns
3. If the page links to related pages (e.g., API docs with multiple sections), ask: "This page links to X related pages. Should I fetch those too?"

#### Web search

1. Search for the query
2. Read top 3-5 relevant results
3. Synthesize findings into actionable knowledge for spec building

### 4. Analyze and structure the knowledge

After ingesting all sources, create a **structured summary**:

```
## 📚 Knowledge Ingestion Report

**Spec:** {name}
**Sources processed:** X files, Y web pages

### What I learned:

#### Architecture
- The project uses {framework/pattern}
- Data flows from {A} → {B} → {C}

#### Existing Interfaces
- `UserService.authenticate(email, password) → Token`
- `PaymentGateway.charge(amount, currency, token) → Receipt`

#### Data Models
- User: { id, email, passwordHash, createdAt }
- Payment: { id, userId, amount, status, gateway }

#### Business Rules Found
1. Passwords must be hashed with bcrypt
2. Payments require idempotency keys
3. Users are soft-deleted, never hard-deleted

#### Constraints
- API rate limit: 100 req/min per user
- Database: PostgreSQL 15, max connections: 50

#### Domain Glossary
- **Idempotency key**: unique token to prevent duplicate charges
- **Soft delete**: mark as deleted without removing from database

### How this helps the spec:
(specific suggestions for what to include in the spec based on findings)

Ready to build! Run /sdd:sdd-build {name} to start the guided conversation with this context.
```

### 5. Link knowledge to build

When `/sdd:sdd-build` starts for a spec that has a `.knowledge.md` file:
- The build skill reads the knowledge file FIRST
- It uses the findings to:
  - Pre-fill obvious sections (known interfaces, data models)
  - Ask more specific questions (based on discovered constraints)
  - Suggest business rules found in existing code
  - Reference domain terms the developer used in docs

### 6. Incremental learning

If the knowledge file already exists:
- Don't overwrite — **append** new findings
- Update the `sources` list and `last_updated`
- If new findings contradict old ones, flag it:
  "⚠️ Conflict: docs say max 100 req/min, but existing code enforces 50. Which is correct?"

## Progress Reporting

```
📚 Learning from 3 sources...

  📄 docs/architecture.md — extracted: architecture overview, 3 data models
  📄 src/models/*.ts — extracted: 5 interfaces, 2 enums, validation rules
  🌐 https://api.stripe.com/docs — extracted: 12 endpoints, auth flow, error codes

✅ Knowledge base created: specs/.memory/payment.knowledge.md
   - 5 data models
   - 12 API endpoints
   - 8 business rules
   - 3 constraints

Next: /sdd:sdd-build payment (knowledge will be loaded automatically)
```

## Rules
- NEVER generate implementation code during learn
- NEVER modify existing source files — this is READ-ONLY
- Summarize and extract — don't copy entire files into knowledge
- If a source is too large (>1000 lines), focus on interfaces, types, and exports
- Always ask before fetching more than 5 web pages
- Knowledge files are append-only by default — new sources add to existing knowledge
