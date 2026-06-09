---
name: skill-manager
description: Operate the local Claude Code skill manager (the `skills` CLI). Use when the user wants to (1) install, uninstall, or list skills on this machine, (2) understand why a skill isn't auto-triggering ("skill not loading"), (3) scaffold a new skill (`skills new <name>`), (4) fix a skill whose directory name doesn't match its frontmatter `name:` field, (5) resolve install conflicts where a real directory exists at the install target, (6) recover a previous version of a skill from the auto-snapshot directory, (7) install a skill into a project rather than per-user (`--project` flag), (8) understand the source-dir vs install-target symlink architecture, (9) edit an existing skill (`skills open <name>`), (10) run a health check (`skills doctor`) and interpret its output, (11) run an LLM-backed quality + safety audit (`skills audit`) using the v3 rubric (10 dimensions incl. operational_safety) — deep by default (scans bundled scripts/ + gitleaks, `--basic` to skip; caches every LLM call durably under `~/.skills/.state/llm-calls/`), (12) scan for accidentally committed credentials (`skills scan`, gitleaks under the hood; honors `~/.skills/.gitleaksignore`), (13) capture or refresh bundled OpenAPI snapshots for client-side service skills (`skills snapshot`) or check whether they've drifted from live (`skills drift`), (14) manage the prompt library at `~/.skills/prompts/` (`skills prompt list/show/body/edit/history/new`) — LLM templates that drive the tooling itself (e.g. the audit rubric). Covers the source-of-truth model (source = `~/.skills/`, install target = `~/.claude/skills/`, symlinks bridge the two so live edits propagate), the auto-snapshot safety net (real-dir conflicts get backed up to `~/.skills/.state/snapshots/<name>-installed-<date>/` before replacement), the command catalog with aliases, the `setup` first-run workflow, doctor categories and which issues are auto-fixable, the rename-to-match-frontmatter fix pattern, per-project vs per-user install, the bundled openapi.json + meta + drift workflow, the gitleaks scan + ignore-by-fingerprint workflow, the audit rubric v3 (10 calibrated dimensions incl. operational_safety/conciseness/instructional_quality/maintainability, scoring discipline, weighting /140, evidence requirement, deep-vs-basic payload, static risk scan + gitleaks), and the prompt library convention (one .md per template with YAML frontmatter).
category: skill-management
tags: [meta, skill, cli, claude-code]
---

# skill-manager

The `skills` CLI (a single static Go binary, invoked as `skills` once it is on PATH) is a local tool for managing Claude Code skills. This skill documents how it works and how to use it.


## The mental model in one paragraph

Two directories: **`~/.skills/`** (source — where you author and edit) and **`~/.claude/skills/`** (target — where Claude Code reads from). The manager creates **symlinks** from target → source, so editing a skill in `~/.skills/foo/SKILL.md` is immediately visible to Claude Code with no re-install. The source-of-truth is always `~/.skills/`. Anything mutating the target (install, remove, replace) is auto-snapshotted to `~/.skills/.state/snapshots/` first if there's something to lose.

## Command reference

```
skills                         status (default — like `git status`)
skills setup                    first-run: install all + shim + PATH + doctor
skills list                     same as status                              (alias: ls)
skills install [name|--all|--tag T|--category C|--profile P]   symlink SELECTED skills (stop brute-forcing all)
skills profile <list|show|add|rm>   manage named skill-sets (curated selections = groups for agents)   (agent: list/show --json)
skills project <sync|init|show>     copy a repo's selected skills into <repo>/.claude/skills/ (per-project, committable)
skills suggest                      propose a profile from the usage log (what you actually use)
skills sync [name|--all]            update local skills from their source: (drift-for-skills; --apply to pull)
skills add <url|owner/repo>     fetch a skill from github / raw URL / registry into ~/.skills/  (alias: fetch, get)
skills scan [path|--home]       scan a local tree for skill dirs and copy approved ones into the master area (never overwrites; asks per skill; --yes for non-interactive; -n to preview)
skills remove  [name|--all]     remove symlinks                             (alias: rm, uninstall)
skills doctor [--fix]           health check; --fix repairs safe issues
skills rename <dir> <new>       rename a skill dir + update its symlink atomically
skills open <name>              open SKILL.md in $EDITOR
skills new <name>               scaffold a new skill
skills audit [name|--all]       LLM-backed quality audit (uses prompts/skill-audit-rubric.md)
skills secrets [name|--all]     secret-leak scan with gitleaks (--git for full history)   (alias: gitleaks, leaks)
skills snapshot [name|--all]    re-capture references/openapi.json from each skill's source_url  (alias: snap)
skills drift [name|--all]       check if bundled openapi.json drifted from live (read-only)      (alias: check)
skills prompt <action>          manage the prompt library (list|show|body|edit|history|new|render)
skills manifest                 JSON catalog of installed skills (name + description)
skills discover "<prompt>"      LLM router: pick skill(s) for a user prompt; auto-files missing-skill tickets   (alias: route)
skills tag <name> [+t -t | --set t...]     manage a skill's tags as a SET (add / remove / replace)
skills categorize <name> <cat> [tags...]   set category (+ ADD tags) in frontmatter (deterministic)
skills classify <name> [--apply]           LLM-suggest a category + tags (prefers taxonomy.yml); --apply writes it
skills tags [tag]                           tag inventory, or — with a tag — the skills carrying it   (agent: --json)
skills categories [cat]                     category inventory, or — with a category — the skills in it
skills list --tag T [--category C]          filter the skills list by tag/category (works with --json)
skills config [init]                        show resolved settings (defaults ← config.json ← env), or write the base config.json
skills log [-n N]                           view the usage/audit log (in the canonical dir)   (agent: --json)
skills hooks <install|status|rm> [--harness claude|gemini|all]   wire skill-fire telemetry into harness settings (snapshot-first, merge-not-clobber; codex deliberately unwired — no skill-call seam)
skills fired <name> [--source S]            log a harness-side skill fire (called BY hooks, not by hand; silent, exit 0; runs matching `on_fire` config rules detached)
skills update                               check the configured github raw URL for a newer version (knows its own --version)
skills help                     reference
```

Organizing skills:
- **Tags are a set of strings.** `skills tag <name> money api` ADDS (union, deduped); `-api` removes;
  `--set a b c` replaces. Adding never clobbers existing tags. `categorize`/`classify` also ADD tags.
- **`categorize`** is the human path (sets the category, deterministic); **`classify`** is the LLM path
  (suggests category + tags, prefers `taxonomy.yml`; writes only with `--apply`).
- **Browse/filter**: `skills tags <tag>` and `skills categories <cat>` list the matching skills;
  `skills list --tag T --category C` filters the status list (both support `--json` for agents).
- Same data model the catalog already uses: per-skill frontmatter `category:` + `tags:`, with
  `taxonomy.yml` as the controlled vocabulary. No database — the filesystem + frontmatter is the store
  (the richer provider/tool/team graph is the server-side tool-registry, not this CLI).

Selection & scoping (don't brute-force all skills — every installed skill's description is paid
every turn): `skills install --tag/--category/--profile` installs only a subset; **profiles** are
named curated selections (a profile == an agent's skill-set == the registry's `/agents/{id}/skills`
binding); `skills project sync` scopes skills to a repo via `<repo>/.claude/skills.json`; `skill
suggest` proposes a profile from your usage log; `skills` shows the current per-turn token estimate.

Universal flags:
- `--project` — target `<cwd>/.claude/skills/` instead of `~/.claude/skills/` (per-repo, can be committed)
- `--dry-run` / `-n` — preview without changing anything
- `--force` — skip confirmation on destructive ops (rare; auto-snapshot makes this almost never needed)
- `-h` / `--help` — works at top level (`skills --help`) AND per-command (`skills audit --help`, `skills scan --help`, etc.). Per-command help shows usage, behavior, env vars, and examples specific to that command.

Configuration (layered — nothing is hardcoded in command code):

    built-in defaults  ←  config.json (the BASE)  ←  env vars (override)

The BASE settings live in `<canonical-dir>/config.json` (run `skills config init`, or `skills setup`
writes it). View the resolved values + their source with `skills config`. The **canonical dir**
defaults to `~/.skills` and is the one bootstrap, overridable via `$SKILLS_HOME`. Keys (config.json /
env override): `source_dir`/`SKILLS_SOURCE`, `target_dir`, `bin_dir`, `audit_model`/`SKILL_AUDIT_MODEL`,
`discover_model`/`SKILL_DISCOVER_MODEL`, `parallel`/`SKILL_PARALLEL`, `registry_url`/`REGISTRY_URL`,
`update_url`/`SKILL_UPDATE_URL`, `editor`/`EDITOR`, `log`/`SKILL_LOG`,
`fired_weight`/`SKILL_FIRED_WEIGHT` (how many operator touches one harness fire is worth in `skills suggest`; default 3),
`on_fire` (file-only: `[{"match": "<glob>", "run": "<shell>"}]` — trigger rules run detached per skill fire with
`$SKILL_NAME`/`$SKILL_SOURCE` in env; a hanging rule never delays the hook). The API key is a secret —
env-only (`ANTHROPIC_API_KEY`), never stored in config.json.

Logging & safety: every invocation appends one JSON line to `~/.skills/skill.log`
(ts, version, verb, redacted args, exit, ms) — view with `skills log`, disable with `SKILL_LOG=0`;
secrets are never logged. `skills scan`/`add` validate imported skill names (reject path-traversal
like `../`), gate copies behind explicit approval, and never overwrite a same-named skill.

Environment variables:
- `ANTHROPIC_API_KEY` — required for `skills audit`, `skills discover`, `skills classify` (Anthropic API; uses prompt caching)
- `SKILL_AUDIT_MODEL` — override audit model (default: `claude-haiku-4-5-20251001`; use `claude-sonnet-4-6` for sharper scoring at ~5x cost)

## Status output, decoded

```
[*] ab0t-cicd-pipeline-usage           # ok — installed and points back to source
[ ] some-skill (not installed)          # in source, not linked into target
[!] foo (conflict — real dir at target) # target has a real dir, not our symlink — install will auto-snapshot then replace
[~] bar -> /some/other/path             # symlink exists but points elsewhere — install will re-link
```

The hint after the summary picks the most useful next command for your state:
- All clean → no hint
- Nothing installed → `first time? run: skills setup`
- Some missing or conflicting → `to install/repair: skills install --all`

## Common operations

### First-time setup on a new machine

```bash
skills setup
```

One command. Idempotent. Safe to re-run. It does:
1. Install every skill in `~/.skills/` (symlinks).
2. Create `~/bin/skills` shim if missing.
3. Append `export PATH="$HOME/bin:$PATH"` to `~/.bashrc` (or `~/.zshrc` if present) if PATH doesn't already include `~/bin`.
4. Run `skills doctor`.

After running, open a new shell or `source ~/.bashrc` to pick up the PATH change.

### Authoring a new skill

```bash
skills new my-new-skill        # scaffolds dir + SKILL.md template
skills open my-new-skill       # edit in $EDITOR
skills install my-new-skill    # symlink it into the target
```

The scaffold writes a SKILL.md with `name:` already matching the dirname and a `description:` placeholder marked `TODO`. Fill in the description (the harness uses it to decide when to auto-trigger).

### Fixing a dirname / frontmatter mismatch

`skills doctor` flags this when the dirname in `~/.skills/` doesn't match the `name:` field in SKILL.md frontmatter. Fix:

```bash
skills rename auth_fastapi_skill ab0t-auth-fastapi
```

`rename` is atomic: it moves the directory in source AND updates the symlink in target in one step. If the skill wasn't installed, only the rename happens.

### Recovering a previous version after an overwrite

Every replacement is auto-snapshotted to `~/.skills/.state/snapshots/<name>-installed-<date>/`. To recover:

```bash
ls ~/.skills/.state/snapshots/
# diff against current
diff -r ~/.skills/<name> ~/.skills/.state/snapshots/<name>-installed-2026-05-08/
# restore (manual cp; the manager doesn't auto-restore)
cp -a ~/.skills/.state/snapshots/<name>-installed-2026-05-08 ~/.skills/<name>
```

Snapshots are cumulative per-day (re-running install on the same day is a no-op for snapshots, since the dated dir already exists). Old snapshots are not auto-pruned — clean by hand when comfortable.

### Per-project skills (committed to a repo)

```bash
cd /path/to/repo
skills --project install --all
# creates symlinks in <repo>/.claude/skills/ pointing back to ~/.skills/<name>
```

This puts the install target inside the repo. **The symlinks won't survive being committed and cloned elsewhere** (they point to a path on this machine). For real per-project skills, copy the source skill INTO the repo and check it in — don't symlink. The `--project` mode is most useful when iterating on a per-repo skill before promoting it to `~/.skills/`.

### Removing all skills (clean slate)

```bash
skills rm --all     # confirms first; only removes our symlinks, never real dirs
```

Refuses to delete anything that isn't a symlink we created (a symlink that points into `~/.skills/`). Real directories or external symlinks are left alone with a warning.

### Running an LLM-backed quality audit

```bash
skills audit                       # all skills with default model (Haiku)
skills audit billing               # one skill
SKILL_AUDIT_MODEL=claude-sonnet-4-6 skills audit --all   # sharper scoring, ~5x cost
```

Loads the rubric from `~/.skills/prompts/skill-audit-rubric.md`, calls the Anthropic API per skill, scores 6 dimensions (description specificity, trigger coverage, false-positive safety, body completeness, actionability, bug-prevention value), assigns a verdict (`exceptional` ≥ 90, `strong` 75–89, `good` 60–74, `weak` 45–59, `drop` < 45). Per-call cost ~$0.004 with Haiku, ~$0.015 with Sonnet. The rubric uses prompt caching so subsequent calls are cheap.

Output: per-skill verdict + score, sorted ascending (worst first). Issues + first suggested fix print inline for `weak` / `good` / `drop`. Raw JSON saved per-skill in `/tmp/skill-audit-<rand>/<skill>.json` for `jq` drill-in. `audit --all` runs in parallel (default 5 workers; `--parallel N` to tune).

### Scanning for accidentally leaked credentials

```bash
skills secrets                            # all skills, current files, skip .state/snapshots/
skills secrets billing                    # one skill
skills secrets --git                      # also scan git history (slower, deeper)
skills secrets --include-snapshots        # scan .state/snapshots/ too
```

Wraps gitleaks. Auto-installs prompt if gitleaks isn't on PATH. Honors `~/.skills/.gitleaksignore` (one fingerprint per line: `<file>:<rule-id>:<line>`). Exits non-zero if findings exist (CI-friendly).

### Managing bundled OpenAPI snapshots

For client-side service skills (e.g. `billing-service-api-reference`) that bundle a snapshot of their service's OpenAPI spec at `references/openapi.json`:

```bash
skills snapshot                        # refresh all snapshots (idempotent)
skills snapshot billing                # one skill
skills snapshot --dry-run              # preview without writing
skills drift                           # read-only: compare snapshots vs live
skills drift billing                   # one skill
```

`snapshot` reads `references/openapi.meta.json` for the source_url, fetches live, validates the response is OpenAPI-shaped, writes the new snapshot only if changed, updates the meta with new timestamp + path/schema counts. Auto-fills placeholders (skills whose service was unreachable at creation time get a `references/openapi.placeholder.md`; `snapshot` replaces it once the service is up).

`drift` does the same fetch + compare but never writes. Reports paths added/removed and schemas added/removed per skill. Exits non-zero if any drift exists (CI-friendly).

### Managing the prompt library (v2 conventions)

LLM templates that drive the tooling live in `~/.skills/prompts/`. Two consumption patterns share the same library:

| `consumed_by:` | Invocation | Examples |
|---|---|---|
| `cli-llm-call` | Script reads it, sends to API, parses response | `skill-audit-rubric` |
| `agent-dispatch` | Operator copies, fills placeholders, passes to `Agent` tool | `create-service-api-reference-skill`, `expand-skill-with-advanced-features` |
| `human-reference` | Read by a person as guidance | `how-to-write-a-prompt-template` (the meta-prompt) |

```bash
skills prompt list                              # all prompts (filters .example.md)        (alias: ls)
skills prompt show <name>                       # full file (frontmatter + body)           (alias: cat)
skills prompt body <name>                       # body pre-render (Jinja2 syntax visible)
skills prompt render <name>                     # body post-Jinja2 with empty vars
skills prompt render <name> --vars '<json>'     # render with inline vars
skills prompt render <name> --vars-file <path>  # vars from a file (use - for stdin)
skills prompt edit <name>                       # open in $EDITOR                          (alias: open)
skills prompt history <name>                    # git log for that prompt's file           (alias: log)
skills prompt new <name>                        # scaffold v2 frontmatter + body template  (alias: create)
```

**Two files per prompt:**
- `prompts/<name>.md` — the prompt itself (YAML frontmatter + Jinja2 body)
- `prompts/<name>.example.md` — at least one reproducible input → hydrated-prompt → output run

**v2 frontmatter has three semantic layers:**
1. **Intent layer**: `purpose`, `when_to_use`, `why_intent`, `how_to_think` — answer "should I use this?" without reading the body
2. **Interface layer**: `schema:` — declares every Jinja2 variable; defaults to `required: false` for graceful degradation
3. **Contract layer**: `output_format` + `output_schema` + body + `.example.md`

**Read `~/.skills/prompts/how-to-write-a-prompt-template.md` (`skills prompt show how-to-write-a-prompt-template`) before authoring a new prompt.** It's the meta-prompt — defines the conventions, anti-patterns, and validation checklist. `skills prompt new <name>` scaffolds the v2 frontmatter; the meta-prompt fills in the rationale.

**Tools that consume prompts read from this library** — e.g. `skills audit` loads its rubric from `prompts/skill-audit-rubric.md` rather than embedding it in the script. Editing the rubric never requires touching the CLI source. Bumping a prompt's `version:` field signals a contract-visible change to callers.

**Rendering** uses an in-process Jinja2 subset (`{{ var }}`, `| default(...)`, `{% if %}`, `ChainableUndefined`); it falls back to `python3` + Jinja2 only for templates that use constructs outside that subset (e.g. `{% for %}`). Templates with `template_engine: none` are returned verbatim (skip Jinja2). Missing vars become empty strings — the prompt should still produce a useful (if degraded) output even when called with `{}`.

### Discovering skills for a user prompt (LLM-routed)

When the catalog grows past ~50 skills, naive description-matching at the harness level breaks down. `skills discover` adds an LLM routing layer:

```bash
skills discover "I need to set up DataDog APM for the billing service"
```

The CLI builds a JSON manifest of installed skills (`skills manifest`), feeds it to the `skill-discovery` prompt with the user prompt, and returns one of three decision branches:

- **`select`**: load these specific skills now (with `load_priority` per skill — primary vs reference)
- **`no-skills`**: don't load anything; the prompt is out-of-scope or trivial
- **`missing-skill`**: the catalog has a gap; **auto-files a structured proposal** at `tickets/MISSING-<ISO-ts>-<4hex>-<proposed-name>.md` (timestamp + random suffix → no name collisions; sortable lexicographically = chronologically) with user_problem / why_needed / information_to_present / intent_and_scope / trigger_phrases / siblings_to_disambiguate_from / estimated_priority

The `select` decision can also include `expand_skills` — existing skills that cover the topic but miss aspects relevant to this user case. They get loaded AND flagged for future expansion.

**The `missing-skill` workflow accumulates a backlog of skills worth writing.** Each ticket has the full context needed to dispatch `create-service-api-reference-skill` (or a similar scaffolder) when the proposal is ready to materialize. Re-running `skills discover` on the same prompt is deduplicated by `proposed_name` — no spam tickets.

**Override the model** with `SKILL_DISCOVER_MODEL=claude-sonnet-4-6` (the default; Haiku also works at lower cost).

**Catalog scaling**: today's manifest is ~6 KB JSON for 33 skills. As the catalog grows past hundreds, pre-filter the manifest by embedding-similarity to the user prompt before passing to discovery — the prompt itself doesn't pre-filter.

## Doctor categories

`skills doctor` checks four things:

| Category | Auto-fixable? | Fix |
|---|---|---|
| **Broken symlink** in target (points to a missing source) | yes (`--fix` removes it) | `skills doctor --fix` |
| **Dirname / frontmatter mismatch** (dir is `foo_bar`, frontmatter says `foo-bar`) | no — too destructive to auto-rename | `skills rename <dir> <newname>` (printed as a hint) |
| **Missing `name:` in frontmatter** | no — needs human input | edit the SKILL.md and add the field |
| **Missing `description:` in frontmatter** | no — needs human-written description | `skills open <name>` and write one |

`--fix` is intentionally conservative: it only does things that have one obvious correct answer. Anything that requires a judgment call gets surfaced as a hint, not auto-applied.

## Safety guarantees

The manager is built to be safe by default:

1. **Refuses to run as root** — operating on `~/.claude/skills/` as root would create files only root can edit later.
2. **Ctrl-C trap** — interrupts cleanly without leaving half-states.
3. **Auto-snapshot before overwrite** — any time a real directory is about to be deleted, it's first copied to `~/.skills/.state/snapshots/<name>-installed-<date>/`.
4. **`rm --all` confirms** — bulk-uninstall asks before acting (override with `--force`).
5. **`rm` only touches our symlinks** — refuses to delete real directories, even with `--force`. To delete a real dir at the target, do it manually.
6. **`--dry-run` works on every mutating command** — preview before applying.
7. **Idempotent** — running `install --all` repeatedly is a no-op after the first.

## Internals reference

| Path | Role |
|---|---|
| `~/.skills/` | source dir; canonical content lives here |
| `~/.skills/<name>/SKILL.md` | the skill itself; frontmatter `name:` should match `<name>` |
| `~/.skills/<name>/references/openapi.json` | bundled OpenAPI snapshot for client-side service skills; managed by `skills snapshot` |
| `~/.skills/<name>/references/openapi.meta.json` | snapshot metadata: `source_url`, `captured_at`, `path_count`, `schema_count` |
| `~/.skills/<name>/references/openapi.placeholder.md` | placeholder when service was unreachable at skill creation; `skills snapshot` auto-fills when service comes up |
| `~/.skills/.state/snapshots/` | auto-backups of overwritten dirs; date-stamped |
| `~/.skills/prompts/<name>.md` | LLM prompt template (YAML frontmatter + body); managed by `skills prompt` |
| `~/.skills/prompts/README.md` | prompt library conventions |
| `~/.skills/tickets/` | deferred work tickets (e.g. auto-filed `MISSING-*` proposals from `skills discover`) |
| `~/.skills/.gitleaksignore` | suppression file for known-false-positive `skills scan` findings |
| `~/.claude/skills/` | install target Claude Code reads from (default scope) |
| `<repo>/.claude/skills/` | install target for `--project` scope |
| `~/bin/skills` | shim/symlink to the Go binary, for the bare `skills` command |
| `$SKILLS_SOURCE` env var | override the source dir (default `~/.skills/`) |
| `$NO_COLOR` env var | disable ANSI colors |
| `$EDITOR` env var | which editor `skills open` / `skills prompt edit` launches (defaults to `vi`) |
| `$ANTHROPIC_API_KEY` env var | required for `skills audit` (Anthropic API key) |
| `$SKILL_AUDIT_MODEL` env var | override audit model (default `claude-haiku-4-5-20251001`) |

## When NOT to use the manager

- **Don't use it on system-wide skills installed by a package manager** — those live elsewhere and shouldn't be symlinked from `~/.skills/`.
- **Don't use `--project` if you intend to commit the result to git** — the symlinks contain absolute paths that won't work for other clones. Copy the source content into the repo instead.
- **Don't manually edit `~/.claude/skills/<name>/`** — that's the install target, not the source. Edits there get lost on next install. Edit `~/.skills/<name>/` instead and the symlink propagates the change immediately.

## Anti-patterns

- **Editing a skill via the install target.** The target is downstream. Always edit in `~/.skills/<name>/`.
- **Running `skills` with `sudo`.** The script refuses; if the refusal seems wrong, your real problem is permission state on `~/.claude/skills/` — fix that with `chown` instead.
- **`rm -rf ~/.claude/skills/<name>` directly.** If it was a symlink, fine — but if it was a real dir, you've now lost it without a snapshot. Always go through `skills rm <name>` so the manager can refuse-or-snapshot appropriately.
- **Renaming a skill dir with `mv` instead of `skills rename`.** `mv` leaves the install symlink dangling. Doctor will flag it next run, but `skills rename` does both steps atomically.
- **Treating snapshots as durable backup.** They live next to the source on the same disk. For real backup, copy `~/.skills/` to a separate machine or remote.
- **Embedding new LLM prompts inline in the CLI source.** Add them to `~/.skills/prompts/<name>.md` and load them from there. Prompts deserve their own version history.
- **Editing the audit rubric in the CLI source.** Edit `~/.skills/prompts/skill-audit-rubric.md` instead. Bump the `version:` field in frontmatter and add a changelog entry.
- **Manually editing `references/openapi.json` snapshots.** They're machine-captured. Re-run `skills snapshot <skill>` to refresh from live. Manual edits will get overwritten on next `snapshot` and won't match `drift` checks.
- **Putting non-fingerprint lines in `.gitleaksignore`.** The format is one fingerprint per line (`<file>:<rule-id>:<line>`), with `#` comments allowed. Random text breaks gitleaks parsing and silently disables the suppression.
