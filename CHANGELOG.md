# Changelog

All notable changes to the `skills` CLI are documented here. Versions track the
published `release/VERSION`; `skills update` compares against it.

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
