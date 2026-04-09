# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, use one of these methods:

1. **GitHub Security Advisories** (preferred): [Report a vulnerability](https://github.com/viamus/claude-sdd-plugin/security/advisories/new)
2. **Email**: Open a private security advisory on the repository

## Scope

This plugin is a collection of Markdown instructions and JSON configuration — it contains no executable runtime code. However, security concerns may include:

- Prompt injection via malicious spec files
- Unsafe commands in hook configurations
- Exposure of sensitive data through generated code
- Vulnerabilities in recommended external tools (Semgrep, Trivy, etc.)

## Response

We will acknowledge receipt within 48 hours and aim to provide a fix or mitigation within 7 days for confirmed vulnerabilities.
