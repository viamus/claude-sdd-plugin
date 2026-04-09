# Contributing to SDD Orchestrator

Thank you for your interest in contributing! This guide explains how to get involved.

## Reporting Bugs

Open a [GitHub Issue](https://github.com/viamus/claude-sdd-plugin/issues/new?template=bug_report.md) using the bug report template. Include:

- A clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Your Claude Code version and OS

## Suggesting Features

Open a [Feature Request](https://github.com/viamus/claude-sdd-plugin/issues/new?template=feature_request.md) issue. Describe the use case and proposed solution.

## Submitting Pull Requests

1. **Fork** the repository
2. **Create a branch** from `main` (`git checkout -b feature/my-change`)
3. **Make your changes**
4. **Test locally** (see below)
5. **Open a PR** against `main`

Keep PRs focused on a single change. Reference any related issues.

## Code Style

This is a Markdown-based Claude Code plugin with no runtime code. Guidelines:

- Use clear, concise Markdown
- Follow the existing file structure in `skills/` and `templates/`
- Keep SKILL.md files focused on a single responsibility
- Use consistent heading levels and formatting

## Testing Locally

Load the plugin in Claude Code using the local directory:

```bash
claude --plugin-dir /path/to/claude-sdd-plugin
```

Then test the skills by running the slash commands (`/sdd-init`, `/sdd-build`, etc.) and verifying behavior.

## SDD Methodology

This project follows **Spec-Driven Design**: every feature starts with an approved specification before implementation. If you're adding a new skill or changing behavior, create or update the relevant spec in `specs/` first. See `CLAUDE.md` for the full workflow.

## Questions?

Open a [discussion](https://github.com/viamus/claude-sdd-plugin/issues) or reach out via GitHub Issues.
