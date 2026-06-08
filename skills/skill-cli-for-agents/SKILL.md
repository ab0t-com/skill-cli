---
name: skill-cli-for-agents
description: Instruction set for AI agents calling the local `skills` CLI at runtime. Use when (1) you are an agent that needs to discover which other skill to load for the current user prompt, (2) you need to find skills similar to one already loaded, (3) you need to render a Jinja2 prompt template for an agent-dispatched sub-task, (4) you need the full skill catalog as JSON for local reasoning, (5) you are unsure whether a particular `skill <verb>` invocation is safe to run (read-only) or has side effects (operator-only). Covers the agent-safe subset (discover, similar, manifest, list, prompt render/body/show), the JSON output convention (`--json` flag), error shape contract, exit code semantics, and the operator-only commands that are EXPLICITLY UNSAFE for agent runtime use (install, remove, snapshot, drift, audit, scan, rename, doctor, setup, open, new, prompt edit/history). NOT for: human operators using the CLI interactively (use `skills help` for that), authoring new skills (use `skill-creator`), managing the local skill installation state (use `skill-manager`). This skill assumes you can invoke shell commands via the Bash tool and parse JSON output. Includes worked agent call chains for the three most common runtime patterns: prompt routing, sibling discovery, template hydration.
category: skill-management
tags: [meta, skill, cli, agent-runtime, claude-code]
---

# skill-cli-for-agents

The `skills` CLI is local tooling for managing the catalog of Claude Code skills.
Most of its commands are for human curators. **A small subset is safe and useful
for AI agents to invoke at runtime.** This skill is the runtime contract.

## Quick decision: should I call `skills`?

| Need | Command | Read-only? |
|---|---|---|
| Find which skill answers this user prompt | `skills discover "<prompt>" --json` | yes (one API call) |
| Find skills related to one I've loaded | `skills similar <name> --json` | yes |
| Get the full catalog | `skills manifest` | yes |
| Get catalog with install state | `skills list --json` | yes |
| Filter the catalog by tag/category | `skills list --tag T --category C --json` | yes |
| List skills carrying a tag / in a category | `skills tags <tag> --json` / `skills categories <cat> --json` | yes |
| List curated skill-sets (profiles = agent skill bindings) | `skills profile list --json` / `skills profile show <name> --json` | yes |
| Hydrate a Jinja2 prompt template | `skills prompt render <name> --vars '<json>'` | yes |
| Inspect a prompt template before rendering | `skills prompt body <name>` or `skills prompt show <name>` | yes |
| **Anything else** | **don't call** — it's an operator command (see "DO NOT CALL" below) | varies |

If your task isn't in the table above, the answer is don't shell out.

## The five-and-a-half safe commands

### 1. `skills discover "<user prompt>" --json`

Route a user prompt to the relevant skill(s). Single Anthropic API call (~3 sec, ~$0.01 with Sonnet, ~$0.003 with Haiku). Returns one of three decision branches:

```bash
skills discover "I'm getting a 402 from /billing/reserve" --json
```

```json
{
  "decision": "select",
  "confidence": "high",
  "reasoning_summary": "User's question is about billing-service /billing/reserve...",
  "selected_skills": [
    {"name": "billing-service-api-reference", "load_priority": "primary", "reasoning": "..."}
  ],
  "expand_skills": null,
  "no_skills_reason": null,
  "missing_skill": null
}
```

Decision branches:
- `"select"` — load these skills (use `selected_skills`); optionally expand existing ones (`expand_skills`)
- `"no-skills"` — don't load anything (read `no_skills_reason`)
- `"missing-skill"` — catalog gap; structured proposal in `missing_skill`. Auto-files a ticket at `~/.skills/tickets/MISSING-<ts>-<slug>.md`. Don't act on it; just surface to the user.

**When to call**: at the start of a complex task where the user's domain isn't obvious from their prompt. Don't call for trivial / off-topic / casual prompts — costs an API call.

### 2. `skills similar <name> --json`

Find skills similar to one you've already loaded. No API call — pure local Jaccard.

```bash
skills similar billing-service-api-reference --json
```

```json
{
  "target": "billing-service-api-reference",
  "target_category": "service-api-reference",
  "target_tags": ["ab0t-platform", "api", "billing", "money"],
  "results": [
    {
      "name": "payment-service-api-reference",
      "score": 0.276,
      "category": "service-api-reference",
      "tags": ["payment", "api", "ab0t-platform", "stripe", "money"],
      "shared_tags": ["ab0t-platform", "api", "money"],
      "description_jaccard": 0.18,
      "tag_jaccard": 0.5
    }
    // ... up to 5
  ]
}
```

**When to call**: after `skills discover` selects skill X and you suspect adjacent skills are also relevant. Useful when the user's actual task spans multiple skill boundaries (e.g., billing → payment for top-up flows).

**Caveat**: scores are a guide, not a threshold. A 0.20 sibling can be totally relevant; a 0.50 result can be a false positive. Read the descriptions before loading.

### 3. `skills manifest`

Full catalog as JSON. Always JSON output (no `--json` flag needed).

```bash
skills manifest
```

```json
[
  {"name": "billing-service-api-reference", "description": "...", "category": "service-api-reference", "tags": ["billing", "api", ...]},
  ...
]
```

**When to call**: at the start of a session where you'll be making many routing decisions. Cache the result locally and reason over it without re-invoking. Cheap (no API, ~50ms).

**When NOT to call**: every turn. Manifest is stable across a conversation; one fetch is enough.

### 4. `skills list --json`

Like `manifest` but with `install_state` per skill (`installed`, `not-installed`, `conflict`, `linked-elsewhere`). Use only when you need install state — usually you don't, since the harness only loads installed skills anyway.

### 5. `skills prompt render <name> [--vars '<json>']`

Hydrate a Jinja2 prompt template. Returns the rendered text on stdout.

```bash
skills prompt render create-service-api-reference-skill --vars '{"service_name":"foo","prod_url":"https://foo.example.com/openapi.json"}'
```

The `vars` JSON values fill in `{{ name }}` placeholders in the template body. Missing vars degrade gracefully (Jinja2 `ChainableUndefined` → empty string).

**When to call**: when dispatching a sub-task to another agent (via the Agent tool) and you want to use a templated prompt rather than writing one from scratch. The local prompt library has reusable templates for: creating service-API-reference skills, expanding skills with advanced features, the audit rubric, the discovery prompt, etc.

**Workflow**: render → pass the rendered text as the `prompt` argument to the Agent tool.

### 5.5. `skills prompt body <name>` / `skills prompt show <name>`

Inspect a template before rendering. `body` returns just the body (with Jinja2 syntax intact); `show` returns the full file (frontmatter + body) so you can read the schema and figure out what `vars` to pass.

## Conventions and contract

- **All commands accept `--json` for structured output.** When `--json` is set, no ANSI colors, no progress noise, errors as `{"error": "...", ...}` to stderr.
- **Exit codes**: 0 on success, non-zero on failure. Always check both exit code AND parse stdout JSON.
- **Read-only**. None of the agent-safe commands mutate the catalog. They make at most one Anthropic API call (for `discover`).
- **Idempotent**. Re-running with the same args produces the same output (modulo LLM noise on `discover` at temperature 0 — small).
- **Side-effect**: `skills discover` auto-files `MISSING-*.md` tickets when its decision is `missing-skill`. This is intentional backlog accumulation — don't try to suppress it.

## DO NOT CALL these from an agent loop

These commands have side effects, interactive prompts, or irreversible state changes:

| Command | Why unsafe |
|---|---|
| `skills install` / `skills add` | Mutates symlinks. Operator decision. |
| `skills remove` / `skills rm` | Removes installations. Operator decision. |
| `skills setup` | Writes to `~/.bashrc`. Modifies shell config. |
| `skills open` / `skills edit` | Launches `$EDITOR` — interactive, blocks. |
| `skills new` / `skills create` | Scaffolds new skill on disk. Authoring task. |
| `skills rename` | Renames directories + symlinks. Operator. |
| `skills doctor [--fix]` | Mutates symlinks when --fix is set. |
| `skills audit` | Costs ~$0.10-0.50 in API calls. Curation. |
| `skills scan` | Runs gitleaks. Slow. Curation. |
| `skills snapshot` | Re-captures openapi.json. Mutates references/. |
| `skills drift` | Read-only but slow (multiple HTTP fetches). |
| `skills prompt edit` / `prompt history` / `prompt new` | Authoring / mutation. |

If you find yourself wanting to call one of these, **stop and explain to the user what you're about to do**. They're for humans to invoke deliberately, not for agents in a loop.

## Three worked agent call chains

### Pattern 1: route a user prompt at the start of a task

```bash
USER_PROMPT="I'm getting 402 errors from /billing/reserve after a top-up"

decision=$(skills discover "$USER_PROMPT" --json)
verdict=$(echo "$decision" | jq -r .decision)

case "$verdict" in
  select)
    # Skill(s) named in selected_skills will auto-load via the harness.
    # If you've ALREADY been loaded, you can just continue.
    # If you need richer context, fetch the bodies (the harness already does this).
    primary=$(echo "$decision" | jq -r '.selected_skills[0].name')
    echo "Loaded primary: $primary"
    ;;
  no-skills)
    echo "Off-topic; answering from general knowledge"
    ;;
  missing-skill)
    proposed=$(echo "$decision" | jq -r '.missing_skill.proposed_name')
    echo "Catalog gap; ticket auto-filed at MISSING-*-${proposed}.md"
    # Don't act; surface to user
    ;;
esac
```

### Pattern 2: extend context with sibling skills

```bash
# Already loaded billing-service-api-reference; user's task touches payment too
similar=$(skills similar billing-service-api-reference --json)

# Top result is payment-service-api-reference at 27% score, shared tags include "money"
top_name=$(echo "$similar" | jq -r '.results[0].name')
top_score=$(echo "$similar" | jq -r '.results[0].score')

# Decide: 0.27 with 3 shared tags is enough to load. Threshold ~0.15 with shared tags.
if [ "$(echo "$top_score >= 0.15" | bc)" = "1" ]; then
  # Read its description directly to confirm before loading body
  skills manifest | jq --arg n "$top_name" '.[] | select(.name == $n) | .description'
fi
```

### Pattern 3: hydrate a templated prompt for sub-task dispatch

```bash
# Need to dispatch an agent to create a new service skill for a service named "notifications"
rendered=$(skills prompt render create-service-api-reference-skill --vars '{
  "service_name": "notifications",
  "prod_url": "https://notifications.service.ab0t.com/openapi.json",
  "distinctive_features": ["webhook delivery", "fanout patterns"],
  "sibling_skills_for_not_for_guard": ["integration-service-api-reference"]
}')

# Pass $rendered to the Agent tool's `prompt` argument
# (or to your equivalent — Anthropic API messages user content, etc.)
```

## When the catalog gets very big (1000+ skills)

The `discover` prompt sends the full manifest in one shot. At 1000 skills × 200-token descriptions = 200K tokens per turn — Sonnet handles it but it's expensive.

For scale: pre-filter the manifest by embedding similarity to the user prompt before sending to `discover`, so only the top-50 candidates make the cut. Today's manifest is 35 skills × ~200 tokens ≈ 7K tokens — no pre-filter needed yet.

## Anti-patterns

- **Calling `skills discover` for every user message.** Once routed, stay on that skill until the topic shifts. Each `discover` call is a billable API hit.
- **Caching `discover` results across users.** The decision depends on the prompt; different prompts → different decisions. But within ONE turn, don't call twice.
- **Treating `similar` scores as truth.** A 0.5 score isn't 50% useful; it's a hint. Read the description.
- **Calling operator commands in error-recovery loops.** If `skills discover` fails (API error, timeout), surface the error to the user; don't retry by calling `skills audit` or `skills install`.
- **Parsing colored output.** Always pass `--json` when you'll parse the result. Color escape codes and progress text break parsers.
- **Assuming `skills prompt render` validates vars.** It doesn't — extra keys are ignored, missing keys become empty strings (Jinja2 `ChainableUndefined`). Reading `skills prompt show <name>` first is the safest way to know what `vars` to pass.


## Where to learn more

- `skills agent` — prints just the agent-runtime help (curated subset of `skills help`)
- `skills help` — full operator + agent command list with `[agent]` annotations
- `skill-manager` (bundled alongside this skill) — full skill manager docs (operator-facing)
- `~/.skills/prompts/README.md` — the prompt library v2 conventions

The CLI evolves; this skill describes the runtime contract as of 2026-05-09. The `--json` shapes are stable; the human-facing output may change.
