# skill — a local-first skills manager for agent harnesses

A single static Go binary that manages [Agent Skills](https://agentskills.io)
(`SKILL.md` folders) on a developer machine: install/curate them for Claude
Code (and any `.agents/skills/`-reading harness), organize them with tags,
categories, and named profiles, scope them per-repo, audit their quality with
an LLM rubric, scan them for leaked secrets, track real usage, and route user
prompts to the right skill.

```
curl -fsSL https://raw.githubusercontent.com/ab0t-com/skill-cli/main/install.sh | sh
skill setup
```

## Why

Skills are the unit of agent capability — but every installed skill's
description is paid in tokens on every conversation turn. Past a handful of
skills you need *curation*, not collection. `skill` treats your skills like a
package manager treats packages:

- **a catalog** (`~/.skills/`) with symlink installs into the harness dir,
- **selection** by tag / category / profile instead of brute-forcing all,
- **per-repo scoping** (`skill project init && skill project sync` — real
  files, committable, works for teammates and CI),
- **telemetry** (`skill hooks install` wires a Claude Code hook so actual
  skill fires land in the usage log; `skill suggest` turns that into a
  profile of what you really use),
- **quality + safety gates** (`skill audit` LLM scoring, `skill secrets`
  gitleaks scan, `skill doctor` health checks).

## Quickstart

```bash
skill                       # status table — what's installed, what it costs
skill install --tag billing # selective install
skill profile add mine --tags billing,testing
skill install --profile mine
skill new my-skill          # scaffold; edit; it hot-propagates via symlink
skill audit my-skill        # LLM quality score (needs ANTHROPIC_API_KEY)
skill hooks install         # skill-fire telemetry (Claude Code)
skill suggest               # propose a profile from observed usage
```

Per-repo:

```bash
cd your-repo
skill project init          # writes .claude/skills.json (selectors)
skill project sync          # copies the selected skills in — commit them
```

## For AI agents

Start at **[llms.txt](llms.txt)** — the agent bootstrap. The runtime-safe
command subset is documented by `skill agent` (everything supports `--json`).
Bundled operating knowledge ships in [skills/](skills/):

- `skills/skill-cli-for-agents` — usage patterns + decision rules for agents
- `skills/skill-manager` — the full operator manual as a skill

## Install

One-liner above, or manually: grab `release/skill` (linux-amd64), verify
against `release/checksums.txt`, drop it on your PATH. `install.sh` is
POSIX sh, HTTPS-only, sha256-mandatory, atomic, and keeps your previous
binary as `.previous`.

## Command surface

See [docs/COMMANDS.txt](docs/COMMANDS.txt) (generated from `skill help`) and
[docs/AGENT-API.txt](docs/AGENT-API.txt) (`skill agent`). Highlights:

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

Refuses root · auto-snapshots before any overwrite · `remove` only touches
its own symlinks · imports validate names (no path traversal) and never
overwrite · JSONL audit log of every invocation (`skill log`, `SKILL_LOG=0`
to disable) · secrets never logged.

## License

MIT — see [LICENSE](LICENSE).
