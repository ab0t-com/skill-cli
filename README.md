<p align="center">
  <img src="assets/hero.png" alt="skills — Kado the archivist, a cream index-card mascot with brass librarian glasses, filing glowing skill cards into a wall of catalog drawers" width="880">
</p>

<h1 align="center">skill</h1>

<p align="center"><em>the librarian for what your AI agent knows how to do</em></p>

---

**skills — a local-first skills manager for agent harnesses**

A single static Go binary that manages [Agent Skills](https://agentskills.io)
(`SKILL.md` folders) on a developer machine: install/curate them for Claude
Code (and any `.agents/skills/`-reading harness), organize them with tags,
categories, and named profiles, scope them per-repo, audit their quality with
an LLM rubric, scan them for leaked secrets, track real usage, and route user
prompts to the right skill.

```
curl -fsSL https://raw.githubusercontent.com/ab0t-com/skill-cli/main/install.sh | sh
skills setup
```

## Why

Skills are the unit of agent capability — but every installed skill's
description is paid in tokens on every conversation turn. Past a handful of
skills you need *curation*, not collection. `skills` treats your skills like a
package manager treats packages:

- **a catalog** (`~/.skills/`) with symlink installs into the harness dir,
- **selection** by tag / category / profile instead of brute-forcing all,
- **per-repo scoping** (`skills project init && skills project sync` — real
  files, committable, works for teammates and CI),
- **telemetry** (`skills hooks install` wires a Claude Code hook so actual
  skill fires land in the usage log; `skills suggest` turns that into a
  profile of what you really use),
- **quality + safety gates** (`skills audit` LLM scoring, `skills secrets`
  gitleaks scan, `skills doctor` health checks).

## Where skills come from

A fresh install starts with an **empty catalog** — `skills` is the manager, not a
bundle of content. The catalog at `~/.skills/` is filled three ways:

- **seed** — `skills setup` self-seeds a small **starter set** from this repo on an
  empty catalog (needs git + network), so you begin with something useful;
- **fetch** — `skills add <owner/repo[/path]>` pulls any skill from GitHub or a raw
  URL, e.g. `skills add ab0t-com/skill-cli/skills/skill-creator`;
- **author** — `skills new <name>` scaffolds your own; it hot-propagates via symlink.

Seeding and fetching are strictly additive: an existing skill dir is **never**
overwritten or deleted.

## Quickstart

```bash
skills setup                 # seeds the starter set, shim, PATH, doctor
skills                       # status table — what's installed, what it costs
skills add ab0t-com/skill-cli/skills/skill-creator   # fetch more, any time
skills profile add mine --tags meta,authoring        # group a curated set
skills new my-skill          # scaffold your own; edit; it hot-propagates
skills audit my-skill        # LLM quality score (needs ANTHROPIC_API_KEY)
skills hooks install         # skill-fire telemetry (Claude Code)
skills suggest               # propose a profile from observed usage
```

> LLM-backed verbs (`audit`, `discover`, `classify`) need `ANTHROPIC_API_KEY`;
> everything else is local and free.

Per-repo:

```bash
cd your-repo
skills project init          # writes .claude/skills.json (selectors)
skills project sync          # copies the selected skills in — commit them
```

## For AI agents

Start at **[llms.txt](llms.txt)** — the agent bootstrap. The runtime-safe
command subset is documented by `skills agent` (everything supports `--json`).
Bundled operating knowledge ships in [skills/](skills/):

- `skills/skill-cli-for-agents` — usage patterns + decision rules for agents
- `skills/skill-manager` — the full operator manual as a skill

## Install

One-liner above (Linux/macOS use `install.sh`; Windows uses `install.ps1`). Or
manually: grab the right `release/skills-<os>-<arch>` (`skills-linux-amd64`,
`skills-linux-arm64`, `skills-darwin-amd64`, `skills-darwin-arm64`, or
`skills-windows-amd64.exe`), verify it against its line in `release/checksums.txt`,
and drop it on your PATH as `skills`. `install.sh` is POSIX sh, HTTPS-only,
sha256-mandatory, atomic, and keeps your previous binary as `.previous`.

## Command surface

See [docs/COMMANDS.txt](docs/COMMANDS.txt) (generated from `skills help`) and
[docs/AGENT-API.txt](docs/AGENT-API.txt) (`skills agent`). Highlights:

| Area | Verbs |
|---|---|
| Catalog | `list` `tree` `tags` `categories` `similar` `manifest` |
| Install | `install` `remove` `setup` `doctor` (selection: `--tag/--category/--profile`) |
| Curation | `profile` `project` `suggest` `tag` `categorize` `classify` |
| Authoring | `new` `open` `rename` `scan` `add` |
| Quality | `audit` `secrets` `snapshot` `drift` `sync` |
| Telemetry | `hooks` `fired` `log` |
| Routing | `discover` (LLM router; auto-files missing-skill proposals) |

Every command has `--help` with a "NEXT — people usually" section; every
mutating command supports `--dry-run`; destructive paths auto-snapshot first.

## Safety model

Root-aware (not root-blocking): read-only verbs always run; when root is the
only user — containers, CI, dev boxes — `skills` just works; invoked via `sudo`
on a real account it warns that files would be root-owned but still runs
(`--allow-root` / `SKILL_ALLOW_ROOT=1` to silence) · auto-snapshots before any
overwrite · `remove` only touches its own symlinks · imports validate names (no
path traversal) and never overwrite · JSONL audit log of every invocation
(`skills log`, `SKILL_LOG=0` to disable) · secrets never logged.

## License

MIT — see [LICENSE](LICENSE).

## Privacy & telemetry

- **No phone-home telemetry to ab0t or any third-party analytics service** — there is
  none in the binary, the install scripts, or the bundled skill content.
- **No opt-in/opt-out telemetry toggle**, because there is no external telemetry to toggle.

For full transparency, the only times `skills` makes a network request are:

- `skills update` — a version check against this repo's `release/VERSION` on GitHub.
- `skills audit` / `discover` / `classify` — call the Anthropic API using **your own**
  `ANTHROPIC_API_KEY` (your prompts go to Anthropic under your key, not to ab0t).
- `skills add <url>` / `skills setup` on an empty catalog — fetch the skill(s) you asked
  for from GitHub.
- `skills snapshot` / `skills drift` — fetch each service skill's OpenAPI doc from the
  `source_url` declared in that skill's own frontmatter.

In every case the destination is a public source you can see; none of it reports usage
back to ab0t or any analytics service.

Usage logging is **local only** (`~/.skills/.state/skill.log`; `SKILL_LOG=0` to disable)
and never leaves your machine; secret scans run locally and secrets are never logged.
