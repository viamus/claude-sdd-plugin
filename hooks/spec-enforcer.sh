#!/bin/bash
# SDD Spec Enforcer Hook
# Intercepts Write/Edit operations and blocks code generation without approved specs
#
# This hook receives JSON on stdin from Claude Code with the tool input.
# It checks if the target file is source code and if there's an approved spec.

set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)

# Extract the file path being written/edited
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
  # Can't determine file path, allow operation
  exit 0
fi

# Get just the filename and extension
FILENAME=$(basename "$FILE_PATH")
EXTENSION="${FILENAME##*.}"

# Allowlist: file types that DON'T need a spec
ALLOWED_EXTENSIONS="md json yaml yml toml ini cfg conf sh bash zsh spec lock css scss html svg png jpg gif ico txt"

for ext in $ALLOWED_EXTENSIONS; do
  if [ "$EXTENSION" = "$ext" ]; then
    exit 0
  fi
done

# Allowlist: paths that DON'T need a spec
ALLOWED_PATHS="hooks/ templates/ docs/ .claude/ .claude-plugin/ specs/ test/ tests/ __tests__ node_modules/ .github/ .vscode/ skills/"

for path in $ALLOWED_PATHS; do
  if echo "$FILE_PATH" | grep -q "$path"; then
    exit 0
  fi
done

# Allowlist: filenames that DON'T need a spec
ALLOWED_FILES="package.json tsconfig.json .gitignore .eslintrc Makefile Dockerfile docker-compose"

for name in $ALLOWED_FILES; do
  if echo "$FILENAME" | grep -qi "$name"; then
    exit 0
  fi
done

# Check for test files
if echo "$FILENAME" | grep -qE '\.(test|spec)\.[^.]+$'; then
  exit 0
fi

# This is a source code file — check for approved specs
# CLAUDE_PROJECT_DIR is the user's project, not the plugin root
SPECS_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}/specs"

if [ ! -d "$SPECS_DIR" ]; then
  # SDD not initialized in this project — silently allow everything
  exit 0
fi

# Check if ANY spec is approved
APPROVED_FOUND=false
for spec_file in "$SPECS_DIR"/*.spec.md; do
  [ -f "$spec_file" ] || continue
  if head -20 "$spec_file" | grep -q "status: approved"; then
    APPROVED_FOUND=true
    break
  fi
done

if [ "$APPROVED_FOUND" = false ]; then
  # No approved specs — block with guidance
  cat <<'BLOCK_JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "🛑 SDD Enforcer: No approved spec found. In Spec-Driven Design, code can only be generated after a specification is created and approved.\n\nNext steps:\n1. /sdd-init <name> — Create a new spec\n2. Fill in the spec with inputs, outputs, rules, and errors\n3. /sdd-review — Validate and approve the spec\n4. /sdd-gen — Generate code from the approved spec"
  }
}
BLOCK_JSON
  exit 0
fi

# There are approved specs — allow the operation but inject context
cat <<'ALLOW_JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "📋 SDD: Approved specs found. Make sure this code is aligned with the corresponding spec. Use /sdd-check to verify consistency."
  }
}
ALLOW_JSON
exit 0
