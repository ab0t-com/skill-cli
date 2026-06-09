# Skill Formats by Harness — Detailed Reference

## Claude Code Skills

### Directory Structure

```
.claude/skills/<name>/
├── SKILL.md              # Required
├── scripts/              # Optional — executable code
│   ├── deploy.sh
│   └── validate.py
├── references/           # Optional — docs loaded on demand
│   ├── api-docs.md
│   └── schemas.md
└── assets/               # Optional — files used in output
    ├── template.html
    └── logo.png
```

**Scopes:**
- Project: `.claude/skills/<name>/SKILL.md`
- User: `~/.claude/skills/<name>/SKILL.md`

### SKILL.md Frontmatter — All Fields

```yaml
---
# Required
name: my-skill
description: >
  What this skill does and when to trigger it.
  Include specific keywords, file types, and contexts.

# Optional — triggering behavior
disable-model-invocation: true    # Only /slash invocation, never auto-triggered
user-invocable: true              # Appears in slash command menu

# Optional — execution constraints
allowed-tools: Read, Grep, Write  # Tool whitelist
model: sonnet                     # Model override: sonnet, opus, haiku
context: fork                     # Run in a subagent (separate context window)
agent: my-agent                   # Run within a named agent definition

# Optional — scoped hooks
hooks:
  PreToolUse:
    - matcher: Bash
      command: "echo 'blocked' && exit 1"

# Optional — metadata
license: MIT
metadata:
  version: "1.0"
  author: "team"
  tags: ["deployment", "aws"]

# Optional — environment
compatibility:
  platforms: [linux, macos]
  requires: [docker, python3]
---
```

### Body Best Practices

- Use imperative form: "Create the migration" not "You should create"
- Keep under 500 lines
- Reference bundled resources with relative paths: `[see schemas](references/schemas.md)`
- Include a "Quick Start" section first for immediate usability
- Group by workflow, not by concept

### Resource Guidelines

**scripts/:**
- Must be executable and tested
- Token-efficient — can be run without reading into context
- Name clearly: `rotate_pdf.py`, `deploy.sh`, not `script1.py`

**references/:**
- Loaded only when the agent determines it's needed
- Keep under 10k words per file (include grep patterns in SKILL.md if larger)
- Include table of contents if >100 lines
- One level deep from SKILL.md — no nested subdirectories

**assets/:**
- Files used in output, not loaded into context
- Templates, images, boilerplate code
- Copied or modified by the agent during task execution

---

## Gemini CLI Custom Commands

### File Format

```
.gemini/commands/<name>.md
```

Single markdown file. No subdirectory, no bundled resources.

**Scopes:**
- Project: `.gemini/commands/<name>.md`
- User: `~/.gemini/commands/<name>.md`

### Frontmatter

Optional TOML-style frontmatter:

```markdown
---
description: "Explain code with visual diagrams and analogies"
---

Analyze the selected code and provide:
1. A high-level overview of what it does
2. A step-by-step walkthrough of the logic
3. An ASCII diagram showing the data flow
4. Real-world analogies for complex concepts
```

Only `description` is supported. No tool restrictions, model overrides, or hooks.

### Invocation

Slash command matching the filename: `/explain-code`

### Limitations

- No bundled resources (scripts, references, assets)
- No tool restrictions
- No model selection
- No execution context control
- No hooks

---

## Codex CLI Slash Commands

### File Format

```
.codex/commands/<name>.md
```

Single markdown file. Even simpler than Gemini — no frontmatter at all.

**Scope:** Project-level only.

### Example

```markdown
Review the current git diff and check for:
- Security vulnerabilities (injection, XSS, auth bypass)
- Logic errors and edge cases
- Performance issues (N+1 queries, unbounded loops)
- Style inconsistencies with the rest of the codebase

Report findings with severity ratings and specific line references.
```

### Invocation

Slash command matching the filename: `/review`

### Limitations

- No frontmatter or metadata
- No bundled resources
- No tool/model/hook control
- Project-level only

---

## Portability Matrix

| Feature | Claude | Gemini | Codex |
|---------|--------|--------|-------|
| Markdown instructions | Yes | Yes | Yes |
| Frontmatter metadata | YAML (rich) | TOML (minimal) | None |
| Subdirectory structure | Yes | No | No |
| Bundled scripts | Yes | No | No |
| Bundled references | Yes | No | No |
| Bundled assets | Yes | No | No |
| Tool restrictions | `allowed-tools` | No | No |
| Model override | `model` field | No | No |
| Scoped hooks | `hooks` in frontmatter | No | No |
| Fork/subagent context | `context: fork` | No | No |
| Slash command | `user-invocable` | Always | Always |
| Auto-trigger | Default (unless disabled) | No | No |
| User-level scope | `~/.claude/skills/` | `~/.gemini/commands/` | No |

## Porting Guide

### Claude → Gemini

1. Extract the markdown body from SKILL.md
2. Add `description` as TOML frontmatter
3. Save as `.gemini/commands/<name>.md`
4. Discard: `allowed-tools`, `model`, `hooks`, `context`, bundled resources
5. If the skill references `references/` files, inline the critical content

### Claude → Codex

1. Extract the markdown body from SKILL.md
2. Remove all frontmatter
3. Save as `.codex/commands/<name>.md`
4. Discard all Claude-specific features
5. Inline critical reference content

### Gemini/Codex → Claude

1. Create directory: `.claude/skills/<name>/`
2. Add YAML frontmatter with `name` and `description`
3. Copy markdown body into SKILL.md
4. Optionally extract large sections into `references/`
5. Optionally add `allowed-tools`, `model`, `hooks` for enhanced control
