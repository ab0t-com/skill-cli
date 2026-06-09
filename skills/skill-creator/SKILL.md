---
name: skill-creator
description: Guide for creating, evaluating, and improving skills across coding agent harnesses (Claude Code, Gemini CLI, Codex CLI). Use when creating a new skill, updating an existing skill, porting a skill between harnesses, auditing skill quality, or designing a skill for autonomous self-improvement loops. Covers the Agent Skills open standard, SKILL.md anatomy, frontmatter fields, progressive disclosure, bundled resources, cross-harness format differences, and common anti-patterns.
category: skill-management
tags: [meta, skill, claude-code, authoring]
---

# Skill Creator

Create effective, portable skills for coding agent harnesses.

## What Skills Are

Skills are modular packages that extend an agent's capabilities with specialized knowledge, workflows, and tools. They transform a general-purpose agent into a domain specialist by providing procedural knowledge that no model fully possesses.

Skills follow the [Agent Skills open standard](https://agentskills.io) — a cross-tool format compatible with Claude Code, Gemini CLI, Codex CLI, and Cursor.

## Skill Formats by Harness

### Claude Code Skills

**Location:** `.claude/skills/<name>/SKILL.md` (project) or `~/.claude/skills/<name>/SKILL.md` (user)

```
skill-name/
├── SKILL.md              # Required — YAML frontmatter + markdown body
├── scripts/              # Optional — deterministic executable code
├── references/           # Optional — docs loaded on demand into context
└── assets/               # Optional — files used in output (templates, images)
```

**Frontmatter fields:**

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Skill identifier |
| `description` | Yes | What it does + when to trigger (primary trigger mechanism) |
| `disable-model-invocation` | No | If `true`, only manual `/slash` invocation works |
| `user-invocable` | No | If `true`, appears in slash command menu |
| `allowed-tools` | No | Tool whitelist: `Read, Grep, Write` |
| `model` | No | Model override: `sonnet`, `opus`, `haiku` |
| `context` | No | `fork` runs in a subagent context |
| `agent` | No | Named agent to run the skill in |
| `hooks` | No | Hook definitions scoped to this skill |

### Gemini CLI Skills (UPDATED 2026-06: Gemini now supports Agent Skills)

**Skills (the Claude-equivalent path):** `SKILL.md` dirs at
`.gemini/skills/<name>/` or `.agents/skills/<name>/` (workspace) and
`~/.gemini/skills/` or `~/.agents/skills/` (user). Frontmatter: `name` +
`description` only. Loaded progressively — the model calls an
`activate_skill` tool (with user consent) to pull the full body. Manage via
`/skills list|link|enable|disable|reload` and `gemini skills install <url>`.

**Custom commands (still exist, user-invoked only):**
`.gemini/commands/<name>.toml` — TOML with `prompt` (required) +
`description`; `{{args}}`, shell injection `!{...}` (auto-escaped), file
injection `@{...}`; subdirs namespace (`git/commit.toml` → `/git:commit`).
**Extensions** (`~/.gemini/extensions/`) bundle commands + hooks + skills +
GEMINI.md and carry the update flow (`gemini extensions update --all`).

### Codex CLI Skills (UPDATED 2026-06: full Agent Skills support)

**Location:** `.agents/skills/<name>/SKILL.md` (repo, searched cwd→root) and
`~/.agents/skills/` (user) — NOT `.codex/`. Frontmatter: `name` +
`description`; everything else (display, `allow_implicit_invocation`, MCP
tool dependencies) goes in an optional `agents/openai.yaml`. Bundled
`scripts/`, `references/`, `assets/` work as in Claude. Triggering: `/skills`
browse, `$skill-name` mention, or implicit description-match (initial list
capped at ~2% of context). Built-ins: `$skill-creator` (agent scaffolds its
own skills), `$skill-installer` (curated + git installs).

Legacy custom prompts (`~/.codex/prompts/*.md`) are **deprecated** — manual
slash only, never model-invoked. Don't create new ones.

> Full per-harness detail (incl. opencode, Hermes, pi, OpenClaw — all of
> which also speak SKILL.md): see the `harness-extensibility-inventory`
> skill. The portability story improved: **`.agents/skills/` is read by
> Codex, Gemini, opencode, pi, and OpenClaw** — one dir, five harnesses.

## Core Design Principles

### 1. Concise Is Key

The context window is shared with system prompts, conversation history, other skills, and user requests. Every token in a skill displaces something else.

**Default assumption: the agent is already very smart.** Only include knowledge the agent doesn't already have. Challenge every paragraph: "Does this justify its token cost?"

Prefer concise examples over verbose explanations.

### 2. Progressive Disclosure

Skills use a three-level loading system:

| Level | What loads | Size target | When |
|-------|-----------|-------------|------|
| **Metadata** | `name` + `description` | ~100 words | Always in context |
| **Body** | SKILL.md markdown | <500 lines | When skill triggers |
| **Resources** | `references/`, `scripts/` | Unlimited | On demand by agent |

The `description` field is the primary trigger mechanism — it determines whether the skill activates. All "when to use" information belongs in `description`, not in the body.

### 3. Match Freedom to Fragility

| Freedom level | When to use | Format |
|---------------|-------------|--------|
| **High** (text guidance) | Multiple valid approaches, context-dependent | Markdown instructions |
| **Medium** (pseudocode) | Preferred pattern exists, some variation OK | Parameterized scripts |
| **Low** (exact scripts) | Fragile operations, consistency critical | Deterministic `scripts/` |

## Creating a Skill

### Step 1: Define the Trigger Surface

Write the `description` first. It must answer:
- What does this skill do?
- What user requests should trigger it?
- What keywords, file types, or contexts are relevant?

```yaml
# Bad — vague, won't trigger reliably
description: Helps with databases

# Good — specific triggers, clear scope
description: Create, query, and optimize PostgreSQL databases. Use when writing SQL queries, designing schemas, creating migrations, optimizing slow queries (EXPLAIN ANALYZE), setting up connection pools, or debugging pg_stat errors.
```

### Step 2: Plan Bundled Resources

For each concrete use case, ask:
- Am I rewriting the same code every time? → `scripts/`
- Do I need reference docs while working? → `references/`
- Do I need template files in the output? → `assets/`

### Step 3: Write SKILL.md Body

Structure the body as a workflow the agent follows:

```markdown
# Skill Name

## Quick Start
[Minimal example to get working immediately]

## Workflow
[Step-by-step procedure with decision points]

## Reference Files
- **[schemas.md](references/schemas.md)** — database schemas, read when querying
- **[optimization.md](references/optimization.md)** — read when EXPLAIN shows seq scans

## Common Patterns
[2-3 concise examples covering the most frequent cases]
```

### Step 4: Organize References

Keep SKILL.md under 500 lines. Split by domain or variant:

```
my-skill/
├── SKILL.md                    # Core workflow + navigation
└── references/
    ├── aws.md                  # Only loaded for AWS tasks
    ├── gcp.md                  # Only loaded for GCP tasks
    └── troubleshooting.md      # Only loaded when errors occur
```

Reference files longer than 100 lines should include a table of contents. Keep references one level deep from SKILL.md — no nested subdirectories.

## Anti-Patterns

| Anti-Pattern | Why It's Bad | Fix |
|-------------|-------------|-----|
| "When to Use" section in body | Body loads after triggering — too late | Move to `description` |
| README.md, CHANGELOG.md | Clutter for humans, not agents | Delete them |
| Entire API docs in SKILL.md | Bloats context for every invocation | Move to `references/` |
| Duplicated content across files | Wastes tokens, risks drift | Single source of truth |
| Deeply nested references | Agent can't discover them | Flat `references/` dir |
| Generic instructions the model already knows | Token waste | Delete them |

## Cross-Harness Portability

Skills are most portable when the core content is plain markdown instructions. The wrapping differs:

| Aspect | Claude | Gemini | Codex |
|--------|--------|--------|-------|
| **Frontmatter** | YAML (rich) | TOML (minimal) | None |
| **Directory** | Yes (subdirs) | No (single file) | No (single file) |
| **Tool restrictions** | `allowed-tools` | N/A | N/A |
| **Model override** | `model` field | N/A | N/A |
| **Hooks** | In frontmatter | N/A | N/A |

**To port a Claude skill to Codex/Gemini/opencode/pi/OpenClaw (2026-06):** copy the skill DIRECTORY as-is to `.agents/skills/` — all five read SKILL.md natively; harness-specific frontmatter is ignored by the others. Only Gemini *commands* (the TOML kind) still need body extraction.

**To port a Gemini command to Claude:** Wrap in SKILL.md format, add `name` and `description` frontmatter, optionally add `references/` for large content.

## Skill Quality Checklist

Before deploying a skill, verify:

- [ ] `description` covers all trigger scenarios (specific keywords, file types, contexts)
- [ ] Body is under 500 lines
- [ ] No information the model already knows
- [ ] No "When to Use" section in the body (belongs in `description`)
- [ ] References are one level deep, with TOC if >100 lines
- [ ] Scripts are tested and deterministic
- [ ] No README, CHANGELOG, or auxiliary docs
- [ ] Instructions use imperative form ("Create the migration" not "You should create")

## Deep Dives

- **[progressive-disclosure.md](references/progressive-disclosure.md)** — read when designing skill loading levels and splitting content
- **[information-density.md](references/information-density.md)** — read when writing skill content for maximum token efficiency
- **[autonomous-improvement.md](references/autonomous-improvement.md)** — read when creating skills from session analysis or feedback loops
- **[formats-by-harness.md](references/formats-by-harness.md)** — read when porting skills between Claude, Gemini, and Codex

## Autonomous Skill Improvement

When an agent uses a skill and encounters friction, it can improve the skill:

1. **Identify the gap** — What was missing, wrong, or ambiguous?
2. **Classify the fix** — Is it a trigger issue (description), a workflow issue (body), or a reference gap?
3. **Apply the minimum change** — Edit the specific section. Don't restructure the whole skill.
4. **Test the change** — Use the skill on the original task to verify improvement.

Common improvement signals:
- Agent had to search for information the skill should have provided → add to `references/`
- Agent triggered the wrong skill → refine `description` keywords
- Agent followed the skill but produced wrong output → fix the workflow steps
- Agent ignored the skill entirely → `description` didn't match the request pattern
