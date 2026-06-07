# Where skill content lives — the 5 storage tiers

> When you're an agent at runtime and you have content (a SKILL.md, a prompt template, a doc snippet),
> there are FIVE distinct places it could end up. They have different power levels, different audiences,
> and different mutability. Confusing them costs tokens, breaks routing, or sends content to a tier
> that can't actually use it. This page is the runtime decision tree.

## Table of contents

- [Quick decision: where does my content go?](#quick-decision-where-does-my-content-go)
- [The five tiers, side by side](#the-five-tiers-side-by-side)
- [Per-tier guidance](#per-tier-guidance)
- [Anti-patterns](#anti-patterns)
- [Future state — server-side skill upload](#future-state--server-side-skill-upload-forthcoming)

## Quick decision: where does my content go?

```
Q1: Is this content local-only (just for this machine, this user)?
    → Tier 1: ~/Skills/<name>/ (or ~/Skills/prompts/<name>.md)

Q2: Does it need substitution at chat-completion time, server-side?
    → Tier 4: LLM gateway /v1/templates  (single-pass {{var}} only)

Q3: Should other agents on other hosts fetch it without cloning the source repo?
    → Tier 2: Tool registry /tools/{tool_id}/skill (and /docs, /scripts, /templates)

Q4: Are you AUTHORING gateway documentation that the gateway team publishes?
    → Tier 3: LLM gateway /guides  (you can't push here; the gateway team owns it)

Q5: Will the LLM use this skill server-side at runtime (not just as agent context)?
    → Tier 5: Forthcoming gateway server-side skill upload  (not shipped yet — see below)
```

## The five tiers, side by side

| # | Where | Owner | Substitution | Mutable by client? | Best for |
|---|---|---|---|---|---|
| **1** | `~/Skills/<name>/SKILL.md` and `~/Skills/prompts/<name>.md` | You (local) | **Full Jinja2** (conditionals, loops, `\| default`, ChainableUndefined) | Yes — edit + `skill install` | Local source-of-truth; agent context auto-loaded by the harness; templated agent-dispatch prompts |
| **2** | Tool Registry `/tools/{tool_id}/skill`, `/docs`, `/scripts`, `/templates` | Per-tool publisher | **None** (`content_type: json\|yaml\|xml\|text` is format, not engine) | Yes — `PUT /tools/{id}/skill` | Per-tool content distribution to other agents/hosts; indexed via `/llms.txt` |
| **3** | LLM Gateway `/guides/{name}` | Gateway team | **None** (static markdown) | **No** — read-only via `GET` | Authoritative gateway documentation; agents fetch on demand for deep-dives |
| **4** | LLM Gateway `/v1/templates` | Caller's org | **Single-pass `{{var}}`** (no conditionals/loops/filters) | Yes — `POST /v1/templates` | Reusable prompts substituted server-side at chat-completion time; usable from chat AND realtime WebSocket |
| **5** | LLM Gateway *server-side skill upload* | Caller's org | **TBD** | TBD | LLM uses the skill DURING its turn (forthcoming — see below) |

## Per-tier guidance

### Tier 1 — local source-of-truth (`~/Skills/`)

The default, the most powerful, and the least shared. Every other tier is downstream of this one.

- **SKILL.md files** are auto-loaded by Claude Code based on description matching. They're the canonical knowledge surface for an agent.
- **prompts/<name>.md** files are Jinja2 templates with frontmatter; consumed via `skill prompt render <name> --vars '<json>'` to produce the rendered text. Used for agent-dispatch sub-task prompts (which would otherwise be inline strings) and for cli-llm-call prompts (audit rubric, discovery rubric).
- Editing here propagates everywhere because the install target is symlinks back into here.

**Use this when**: anything an agent reads, anything you author, anything you're iterating on.

### Tier 2 — tool registry per-tool content

Network-attached cache for SKILL.md / docs / scripts / templates content, namespaced per tool_id.

- `PUT /tools/{tool_id}/skill` uploads a SKILL.md (Markdown body)
- `PUT /tools/{tool_id}/docs/{slug}` uploads a doc page
- `PUT /tools/{tool_id}/scripts/{name}` uploads a script
- `PUT /tools/{tool_id}/templates/{name}` uploads a static template (NOT prompt-substituted — just static text in `json|yaml|xml|text` format)
- `GET /llms.txt` returns an "ab0t Tool Registry — Skills Index" listing every active tool's SKILL.md

**Use this when**: another agent on another host needs the same SKILL.md you have locally, and `git clone` of the source repo isn't on the table.

**Don't use this when**: you want server-side `{{var}}` substitution — registry doesn't have a templating engine. That's tier 4.

### Tier 3 — LLM gateway `/guides`

The gateway team's hand-authored documentation guides. 11 guides today (~167 kB total): `agent-auth`, `auth`, `auth-client`, `authentication`, `chat`, `computer-use`, `embeddings`, `models`, `audio`, `realtime`, `plugins`. The `agent-auth` guide is verbatim written for AI agents.

- **You can't push here** — read-only via `GET /guides/{name}`. The gateway team owns the content.
- **Local mirror exists**: `~/Skills/llm-gateway-guides/` snapshots all 11 as references. Refresh manually with `curl`.
- These supplement (don't replace) `llm-gateway-api-reference` — that one is the API CONTRACT, the guides are NARRATIVE deep-dives.

**Use this when**: an agent needs the gateway's authoritative narrative on a topic and the API-reference skill isn't deep enough.

**Don't use this when**: you want to publish your own content — you can't.

### Tier 4 — LLM gateway `/v1/templates`

Server-side prompt templates with single-pass `{{var}}` substitution.

- `POST /v1/templates` registers a template with name + content + variable list
- Reference from chat completions via `template_id` + `template_vars` + optional `template_prefix`/`template_suffix`
- Reference from realtime WebSocket via `template_id` + `instructions_prefix`/`instructions_suffix` (same `template_id`, field name renames)
- Composition rule: `Final = Prefix + (Template OR Instructions) + Suffix`

**The bounding limitation**: substitution is single-pass dumb find/replace. NO conditionals (`{% if %}`), NO loops (`{% for %}`), NO filters (`| default`). If your local prompt uses Jinja2 control flow, it can't round-trip to this tier — render it locally and send the result.

**Use this when**: you want a prompt to be substituted by the gateway server-side, especially when the same `template_id` should work in both chat and realtime APIs.

**Don't use this when**: cross-org sharing is required (templates are org-scoped — registering once doesn't grant other orgs access). Or when your prompt uses Jinja2 control flow (stays local in tier 1).

### Tier 5 — Forthcoming server-side skill upload

A skill-upload endpoint is planned for the LLM gateway but **not yet in `/openapi.json`**. Per the platform owner: the gateway team is updating the spec; intent is to "connect skills as server skills, like via the registry tool thing" — likely integrating with tier 2 (tool registry) so registry-published skills become runtime-loadable on the gateway without a separate copy.

**What's known:**
- Endpoint will exist
- Intent: skills uploaded → loadable at LLM runtime; chat completions can reference them server-side, analogous to how `template_id` references prompt templates today
- Likely closes the local-source → registry → gateway-runtime loop

**What's unknown until the spec ships:**
- Path (e.g. `/v1/skills`, `/v1/agents/skills`, ...)
- Request shape (full SKILL.md? just a registry tool_id reference?)
- Auth model (org-scoped vs user-scoped)
- How chat completions reference an uploaded skill (analogous to `template_id`?)
- Versioning, expiration, quota model

**Re-check trigger**: when `curl -sS https://llm.dev.ab0t.com/openapi.json | jq -r '.paths | keys[]' | grep -i skill` returns non-empty, OR when `GET /` discovery doc gains a `skills` category.

**Until then**: don't speculate on integration patterns. Treat as a known unknown.

## Anti-patterns

- **Pushing a Jinja2-heavy prompt to tier 4.** The gateway only does `{{var}}` substitution; conditionals/loops will appear literally in the rendered output. Either render locally and push the rendered text, or keep it in tier 1.
- **Treating tier 2 templates as prompt templates.** Tool registry templates are STATIC TEXT (`content_type: json|yaml|xml|text`). No substitution. They're for distributing config/schema/example artifacts, not prompts.
- **Editing local mirrors of tier 3 guides.** `~/Skills/llm-gateway-guides/references/<name>.md` is a verbatim mirror. Edits get overwritten on refresh and don't fix the upstream guide. Drift goes in the SKILL.md "Known guide-vs-spec drift" section instead.
- **Pushing local prompts to tier 4 expecting cross-org reuse.** `/v1/templates` is org-scoped. "Register once, every team uses it" needs a gateway feature change that doesn't exist yet.
- **Building speculative integrations against tier 5.** Wait for the spec.

## Reference: when an agent is *consuming* (not producing) content

Most agent runtime work is consume, not produce. The `skill discover` / `skill similar` / `skill manifest` commands all read from tier 1 (local) — they don't reach across tiers. If you (the agent) need tier-2 content, fetch it via `curl http://localhost:8003/tools/{id}/skill`. If you need tier-3 content, `curl https://llm.dev.ab0t.com/guides/{name}`.

The local `skill` CLI doesn't unify reads across tiers today. If that becomes friction, see `tickets/INVESTIGATE-001-llm-gateway-template-integration.md` for sketches of how a `skill prompt pull --from-gateway-guide <name>` or `skill push <name> --to tool-registry` could work.

## Pointer back to the skill body

The five-and-a-half safe commands (`skill discover`, `skill similar`, `skill manifest`, `skill list --json`, `skill prompt render`) are all tier-1 operations. They never reach across to other tiers. If you find yourself wanting to fetch from tier 2 or tier 3 at runtime, that's a curl, not a `skill` command — and that's correct, not a gap.
