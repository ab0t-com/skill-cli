# Changelog

All notable changes to the `skills` CLI are documented here. Versions track the
published `release/VERSION`; `skills update` compares against it.

## [0.1.19-public] — 2026-06-10

### Fixed
- **`skills` now runs as root when root is the only user.** It previously refused to run
  as root for *every* command except `--version` — so on containers, CI, and root-only dev
  boxes the tool was unusable (even `skills help`). The guard was aimed at the real hazard
  (root-owned files under `~/.skills` that break for a later non-root user), but over-shot.
  Now:
  - **read-only verbs** (`help`, `status`, `list`, …) always run as root;
  - **genuine root** (no other user) **just works** — no wall, no flag needed;
  - **`sudo` on a real account** warns that files would be root-owned (likely a mistake) but
    still proceeds — silence with `--allow-root` or `SKILL_ALLOW_ROOT=1`.
  The behavior is documented in `skills help` and the Safety model section above.

## [0.1.18-public] — 2026-06-10

### Fixed
- **`skills scan` no longer sweeps up other tools' skills.** On a populated machine,
  `skills scan ~/` used to report hundreds of "new" skills — almost all of them vendored
  by other harnesses (plugin marketplaces, installed-plugin caches, bundled copies, test
  fixtures) — behind a per-skill `y/N` prompt that was unusable at that scale. Scan now:
  - **skips managed/vendored trees by default** — installed-plugin and marketplace stores,
    `_bundled`/`fixtures`/`sample-output` dirs, and hidden tool dirs (everything except
    `.claude`, where repo skills live). Pass `--all-trees` to include them.
  - **de-duplicates** skills found under more than one path (shows `(+N more copies)`).
  - **approves a whole source tree at once** (`[y/N/a=all/q=quit]`) instead of prompting
    once per skill — turning hundreds of prompts into a handful of decisions.
- **`skills setup` installs shell completion on a fresh machine.** Completion used to be
  skipped when no completion directory pre-existed; setup now creates the standard
  bash-completion user dir and installs there (zsh gets a one-line `fpath` hint when zsh
  is your shell).

## [0.1.17-public] — 2026-06-10

### Added
- **macOS, Linux-arm64, and Windows binaries.** `release.sh` now cross-compiles a
  matrix — `skills-{linux,darwin}-{amd64,arm64}` and `skills-windows-amd64.exe` —
  each sha256-checksummed.
- **`install.sh` auto-detects your platform** (`uname` → the right binary; works
  with `sha256sum` or macOS `shasum`) and still falls back to `~/.local/bin` + wires
  PATH for you. **Windows** has its own one-liner: `irm
  https://raw.githubusercontent.com/ab0t-com/skill-cli/main/install.ps1 | iex`.

### Fixed (Windows correctness, from a portability audit)
- Enable virtual-terminal processing on Windows so colored output renders instead of
  printing raw escape codes on legacy consoles (best-effort; modern terminals
  unaffected).
- Use the real home dir (not `$HOME`, which is unset on Windows) for the cwd hint;
  skip the Unix-only `tput` width probe on Windows.
- Normalize CRLF before scanning scripts and parsing `taxonomy.yml`, so Windows-
  authored (`\r\n`) files are read correctly (incl. the secret/risk scanner).
- `install.ps1`: handle ARM64 Windows (uses the amd64 build under emulation) and
  tolerate CRLF/BOM in `checksums.txt`.

### Removed
- **The python3 + jinja2 runtime dependency.** `discover` and `prompt render` now use a
  pure-Go template renderer covering the subset the prompt library uses — `{% if %}`
  with `and`/`or`/`not`, `{% for %}` with `loop.*`, `{% set %}`, and the
  `default`/`length`/`join` filters — verified byte-for-byte against jinja2. The binary
  is truly self-contained: no Python needed, on any platform.

### Notes
- On Windows, skill linking (`skills setup`) uses symlinks — enable Developer Mode
  (Settings → Privacy & security → For developers) or run elevated; the binary tells
  you if that step is blocked.

## [0.1.9-public] — 2026-06-09

### Added
- **`skills audit` is now a quality + safety audit (rubric v3, 10 dimensions).**
  New dimensions: `operational_safety` (×2.0 — known-vs-hidden risk),
  `conciseness`, `instructional_quality`, `maintainability`. Single-skill audits
  print the per-dimension breakdown.
- **Deep audit by default.** The audit now reads a skill's bundled `scripts/` and
  runs a static risk scan (dangerous-shell-pattern grep + gitleaks when installed)
  and feeds them to the model, so `operational_safety` judges real risk, not just
  the prose. Risk findings print per skill. `--basic` reverts to SKILL.md-only.
- **Durable LLM-call journal + cache.** Every audit call is hashed and saved under
  `~/.skills/.state/llm-calls/` (cache → unchanged skills don't re-bill; `--no-cache`
  to force; `SKILL_LLM_LOG=0` to disable). `skills config` shows the new `state dir`.

### Changed
- **Machine-local state moved under `~/.skills/.state/`** (snapshots, usage log,
  the LLM journal) so the catalog dir lists skills, not data. **Existing installs
  migrate automatically and silently on first run** — `~/.skills/.snapshots` →
  `~/.skills/.state/snapshots` and `~/.skills/skill.log` → `~/.skills/.state/skill.log`
  (one-time, idempotent, symlink-safe; nothing is deleted). `$SKILLS_STATE_DIR`
  overrides the location.
- Audit output format changed (per-dimension lines, risk findings, a journal-path
  footer). `audit` has no `--json` mode, so this affects only screen-scrapers.

### Notes
- Deep audits cost more than the old SKILL.md-only pass (they send scripts; the
  rubric recommends `claude-sonnet-4-6`). Caching offsets repeats; use `--basic`
  for a cheap shallow pass. The model is still configurable via `SKILL_AUDIT_MODEL`
  (default `claude-haiku-4-5-20251001`).
- Clients with a hand-authored pre-v3 `prompts/skill-audit-rubric.md` get a one-line
  skew warning and 6-dimension scoring until they refresh it; everyone else uses the
  binary's built-in v3 rubric.

## [0.1.2-public] — 2026-06-08

### Changed (breaking)
- **The command is renamed `skill` → `skills`.** `skill(1)` already exists on
  Linux (the procps signal-sender, sibling of `kill`), so the binary on your
  PATH is now `skills`. Every invocation changes (`skills install`,
  `skills setup`, `skills doctor`, …), and shell completion now completes
  `skills`.
- Unchanged: the repository name (`skill-cli`), the `SKILL.md` file format, the
  `~/.skills/` catalog directory, and all `SKILL_*` environment variables.

### Migration
- Re-run the installer (or `skills setup`) to lay down the `skills` binary —
  setup installs the new `~/bin/skills` shim and **automatically removes the
  legacy `~/bin/skill` shim** it owns.
- If you wired telemetry, re-run `skills hooks install`; it refreshes the hook
  to call `skills fired` (replacing the stale `skill fired` command in place).

## [0.1.1-public] — 2026-06-08

### Fixed
- `skill config` now displays the `fired_weight` and `on_fire` settings
  (they resolved and worked before, but were missing from the output).

## [0.1.0-public] — 2026-06-08

### Added
- Initial public release: a single static Go binary that manages
  [Agent Skills](https://agentskills.io) (`SKILL.md` folders) — catalog,
  selective install, profiles, per-repo scoping, LLM quality audits, secret
  scanning, usage telemetry, and prompt→skill routing.
- Verified installer (`install.sh`): POSIX sh, HTTPS-only, mandatory sha256,
  atomic, keeps the prior binary as `.previous`.
- `skill update` self-version check against this repo's published `release/VERSION`.
- Bundled operating-knowledge skills (`skill-cli-for-agents`, `skill-manager`)
  and an agent bootstrap (`llms.txt`).
