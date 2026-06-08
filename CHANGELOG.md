# Changelog

All notable changes to the `skill` CLI are documented here. Versions track the
published `release/VERSION`; `skill update` compares against it.

## [Unreleased]

### Changed (planned — breaking)
- **The command will be renamed `skill` → `skills`.** `skill(1)` already exists
  on Linux (the procps signal-sender, sibling of `kill`), so the binary on your
  PATH will become `skills` to avoid the collision. Every invocation changes
  (`skills install`, `skills setup`, `skills doctor`, …). After upgrading,
  remove the old `~/bin/skill` shim. The repository, the `SKILL.md` file format,
  the `~/.skills/` catalog directory, and all environment variables are
  unchanged. This will ship as a minor version with a migration note.

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
