# Versioning + CHANGELOG for Self-Improving Skills

Read when recording a minor edit. Covers the `version:` frontmatter field, the
semver bump rules, the CHANGELOG.md format, and how recorded versioning composes
with the skill-manager auto-snapshot safety net.

## Why record at all

A minor edit is only *safe* because it is *reversible and legible*. Two readers
need the trail:

- **The next session / agent** — to know what the skill currently guarantees and
  what recently changed (so it can trust or distrust a step it's about to take).
- **Rollback** — to map "this regressed after the last edit" to a specific version
  and restore it.

An unrecorded edit is an untracked weight update: it silently changes behavior and
leaves no way to attribute a later regression. Always bump + log, even for a typo.

## The `version:` field

Add a `version:` line to the skill's frontmatter. A skill with no version yet starts
at **`1.0.0`** on its first recorded edit (adding the field is itself the first
CHANGELOG entry — note "adopt versioning" as the reason).

```yaml
---
name: my-skill
description: |
  ...
version: 1.2.0
---
```

The field is informational metadata; harnesses ignore unknown frontmatter keys, so
it is safe across Claude / Gemini / Codex.

## Bump rules (semver through the learning-rate lens)

The bump size **is** the step size. Picking the bump is picking your learning rate.

| Bump | When | Editing examples |
|---|---|---|
| **PATCH** `x.y.Z` | Clarify / correct / retune. No change to *what triggers it* or *what it does*. | Typo; reword a confusing line; add or sharpen a trigger keyword; fix a stale path / line ref / version number; tighten a workflow step; small fact correction in a reference. |
| **MINOR** `x.Y.0` | Additive. New capability that doesn't break existing use. Reset PATCH to 0. | New `references/` file for a recurring gap; new optional workflow step; a new decision row; a new script *with* a fallback; an added example covering a fresh case. |
| **MAJOR** `X.0.0` | Breaking. Restructure / rename / repurpose / change the trigger surface or core workflow. Reset MINOR+PATCH to 0. | **Out of scope for this skill** — a MAJOR bump means your learning rate is too high; stop and use `skill-creator`. |

The MAJOR row is a tripwire, not a path: if an edit warrants it, you are no longer
doing minor self-improvement. The version number governs the discipline.

Most self-improvement edits are PATCH. MINOR shows up when a recurring gap genuinely
needs a new bundled resource. If you find yourself wanting MAJOR, escalate.

## CHANGELOG.md format

One file per skill, in the skill directory, newest entry first, one line per step.
Each line: the bump level, what changed, and (briefly) the friction it removes.

```markdown
# Changelog — my-skill

## [1.2.0] — 2026-06-08
- MINOR: add references/troubleshooting.md for the 403-on-refresh case (recurred 3×).

## [1.1.1] — 2026-06-07
- PATCH: description — add "rotate credentials" trigger; was missing rotate-flow asks.

## [1.1.0] — 2026-06-05
- MINOR: add the "verify before close" workflow step (skill skipped verification twice).

## [1.0.0] — 2026-06-01
- Adopt versioning. Baseline of the existing skill.
```

Rules:

- **Dates are bashdates** (`$(date +%Y-%m-%d)`), never relative — consistent with the
  house ticket conventions.
- **The "why" is the gradient.** A line without the friction it addresses is a step
  with no recorded direction; include it, briefly.
- **Append-only.** Never rewrite past entries; a correction is a new entry. (Same
  discipline as work logs and decision logs.)
- **One line per logical step.** If you "batched" three unrelated changes onto one
  line, that's the anti-pattern — they should have been separate gated edits.

## Composing with the snapshot safety net

The local skill manager (`skills` CLI) **auto-snapshots a skill on install/edit** —
full-directory copies land under the source area's `.snapshots/`
(e.g. `<skill>-installed-YYYY-MM-DD`). That is the mechanical rollback; the CHANGELOG
is the human-readable index that tells you *which* snapshot to roll back to and why.

The two are complementary:

| Layer | Answers | Granularity |
|---|---|---|
| `.snapshots/` (skill-manager) | "Restore the bytes from before" | Per install/edit event |
| `version:` + CHANGELOG.md | "What changed, when, and why" | Per logical edit |

So the record step of the loop is cheap: the bytes are already backed up by the
tooling; you are adding the *meaning*. Knowing rollback is one restore away is
exactly what licenses small, frequent steps — the whole point of a low learning rate.

Mechanics (`skills open`, snapshot recovery, `skills doctor`/`audit`) live in the
**`skill-manager`** skill; this file only covers the versioning convention layered
on top.
