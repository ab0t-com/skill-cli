# Tasklist Formats — The Four Dialects

Contents:
1. [Plain tasklist — `$--------` blocks](#1-plain-tasklist--$---------blocks)
2. [Compliance-style tasklist — severity-tagged `$-----` blocks](#2-compliance-style-tasklist--severity-tagged-$-----blocks)
3. [Markdown task registry — `<!-- >>> TASK -->` blocks](#3-markdown-task-registry-----task----blocks)
4. [Executable .sh DONE-log — `# >>> TASK` blocks](#4-executable-sh-done-log----task-blocks)
5. [Worklog line format](#5-worklog-line-format)
6. [Cross-service tasklists](#6-cross-service-tasklists)
7. [Status discipline](#7-status-discipline)

All dialects share one contract: **byte-stable greppable delimiters**, checkbox
status, per-task file targets, and an append-only work log. Pick the dialect that
matches the surrounding repo; never invent a fifth. (A related fifth delimiter,
`$---`, separates tasks *inside* IMPLEMENTATION_PLAN.md — see
[implementation-plan.md](implementation-plan.md); it is not a tasklist dialect.)

Naming: `tasklist_<bashdate>[_<desc>].md` where bashdate = `$(date +%Y%m%d)`,
e.g. `tasklist_20260309_test_suite_fixes.md`. Cross-service variants:
`tasklist_20260226_064457-resource.md` (timestamp + service suffix).

---

## 1. Plain tasklist — `$--------` blocks

The default for ticket-scoped and repo-root tasklists.

```markdown
# Tasklist: Test Suite Fixes — Speed, Rate Limits, Idempotency

**Date:** 2026-03-09
**Findings:** `tickets/findings_20260309_test_suite_investigation.md`
**Branch:** `feature/schema-branch-01`

**Execution order:** Task 1 unblocks 2-4; Task 5 last (depends on all).

---

$-------- [x] TASK 1: Triple rate limits in docker-compose.yml

**File:** `docker-compose.yml` (lines 48-54)
**What:** <brief description>
**Why:** <justification with numbers/evidence>
**Risk:** <assessment>

**Before:**
```yaml
RATE_LIMIT: 10
```
**After:**
```yaml
RATE_LIMIT: 30
```

**Work log:**
2026-03-10 — applied, compose config validated, suite re-run 14m→6m.

$-------- [ ] TASK 2: <next task, same structure>

$-------- [DEFER] TASK 3: <deferred task — state why and where it went>

## Work Log
(Append-only — each entry records what was done and when)

### 2026-03-27 — Investigation
<timestamped notes>

### 2026-03-30 — Implementation
<timestamped notes>

## Exit Criteria
<what "done" looks like for the whole tasklist>
```

Markers: `[ ]`/`[]` open · `[~]` in progress · `[x]` done-and-verified ·
`[d]`/`[DEFER]` punted (say where) · `[!]` blocked (name the blocker).

## 2. Compliance-style tasklist — severity-tagged `$-----` blocks

Used by audit-remediation work (see the `compliance-audit-schema-contracts-workflow`
skill, which owns this format end-to-end). Task delimiter carries machine-readable
ratings:

```markdown
# Tasklist: <title> — <service> <goal>
**Created:** <date>
**Status:** OPEN
**Scope:** <one-line>

## Audit Summary
| Category | Endpoints | Typed | Untyped | Notes |
|---|---|---|---|---|

## Tasks
$----- [] severity:HIGH regression-risk:LOW code-change:SMALL cognitive-complexity:0
### Task N: <router> — `<METHOD> <path>` <action summary>
**File:** `<relative path>:<line>`
**Current:** <what it does now>
**Action:** <what to do>

## Work Log
| Date | Task | Status | Notes |
|---|---|---|---|
```

Rules carried over from that workflow: every audited item appears as a task —
actionable or SKIP; SKIP tasks state the reason and reference a compliance comment
placed in the source; tasks ordered user-facing first, infra last.

## 3. Markdown task registry — `<!-- >>> TASK -->` blocks

Used for project-level forward backlogs organized into epics — a
`tasklist_<bashdate>.md` at the project root.

File skeleton: **Back-references** (tickets, prior tasklists, docs) → **Legend**
(status: done/partial/todo/blocked/wontfix · tier: prod/migration/dev) →
**Summary table** (epic-level rollup) → epic sections of task blocks → **Worklog**.

```markdown
**Back-references**
- Tickets: [`CLI-001`](../tickets/CLI-001-modernize-skill-cli.md) (modernize/rewrite trigger), `SELECT-001`, ...
- Prior tasklist: `tasklist_20260601.sh` (T00–T45, the rewrite + migration)
- Docs: docs/{PRODUCT,DESIGN,PARITY,CUTOVER,VERSIONING}.md

<!-- >>> TASK -->
### `SEL-1` install/remove by `--tag` / `--category`
- **status**: done · **tier**: prod · **ticket**: SELECT-001 §Phase1
- **refs**: docs/SELECTION-AND-SCOPING.md §1; reuse filter from sh T07/T12
- **acceptance**: `skill install --tag billing` links only billing-tagged skills
- **files**: internal/commands/install.go, internal/catalog
- **depends**: SEL-0
- **was**: sh T35
<!-- <<< TASK -->
```

Field notes: `ticket: <ID> §<section>` pins the task to a ticket subsection;
`was: sh T35` links to the predecessor task in the .sh log; `depends:` orders
execution; task IDs are epic-prefixed (`SEL-1`, `VER-2`).

## 4. Executable .sh DONE-log — `# >>> TASK` blocks

A bash script that is both the historical task record and its own query tool —
a `tasklist_<bashdate>.sh` at the project root.

```bash
# >>> TASK
# ID: T35
# STATUS: blocked
# OWNER: claude+mike
# AREA: server
# TITLE: registry integration — skill push/pull/sync/serve
# ACCEPTANCE: skill push/pull a bundle; skill sync compares bundle_hash
# FILES: docs/REGISTRY-INTEGRATION.md internal/registry/ (future)
# NOTE: BLOCKED on registry readiness — 0 tools, /llms.txt 500s
# <<< TASK
```

Fields per task: `ID, STATUS, OWNER, AREA, TITLE, ACCEPTANCE, FILES` (+optional
`NOTE, DEPENDS, REFS`). A runner section at the bottom parses the blocks:

```bash
./tasklist_20260601.sh           # summary counts
./tasklist_20260601.sh list      # one line per task
./tasklist_20260601.sh todo      # only unfinished
./tasklist_20260601.sh show T03  # full detail of one task
./tasklist_20260601.sh verify    # build + vet + tests + parity gate
```

Lifecycle convention: when a .sh log fills up (all tasks T00–TNN done), it becomes
the frozen DONE-log and the forward backlog moves to a fresh `.md` registry that
back-references it (`NOTE: this .sh file is the DONE log (T00–T45); forward backlog
lives in tasklist_20260601.md`).

## 5. Worklog line format

One line per task as it lands, append-only, in the tasklist's `## Worklog`:

```
2026-06-01T12:02Z  SEL-2  done  — internal/selection: Query.Resolve over catalog; verify: go test ./internal/selection 11/11
```

Format: `<ISO timestamp>  <task-ID>  <status>  — <what>  verify: <how it was proven>`.
Table form is also used (cross-service tasklists):

```markdown
## Worklog
| Date | Work Done |
|------|-----------|
| 2026-02-26 | Auth production/ overhauled (see auth/output/production/CHANGE_LOG.txt) |
| 2026-02-26 | This tasklist created |
```

## 6. Cross-service tasklists

Live at the code root (e.g. `TASKLIST_20260226_034101.md`,
`tasklist_20260508_prod_iam_drift_remediation.md`). Beyond the standard skeleton
they carry: a **Context** section, a **Services Overview table** (port, Redis
ownership, region, complexity), a **Decision** section when there's an Option A vs
Option B fork, phase-by-phase breakdown, and a **"Rules, Gotchas, and Knowledge for
the Task Master"** section — the tribal-knowledge dump (env file conventions, IAM
requirements, known bugs in sibling services, what NOT to do). Each task references
the per-service tickets it touches:

```markdown
**Related tickets:**
- `tickets/20260508_api_key_validation_path_unification/` — same auth-path surface
- `tickets/20260508_workspace_orgs_inherit_part3_config/` — separate work, same date
```

## 7. Status discipline

- A task flips to `[x]` / `done` **only after verification is recorded** (UJ GREEN
  with assert counts, command output, or a manual check noted in the work log).
- `partial` is allowed in registry dialects — say exactly what remains.
- `blocked` requires a `NOTE:` naming the blocker.
- The tasklist is the single source of truth for status; tickets, TRACKER.md, and
  STATUS.md summarize (`Status: RESOLVED ... 10/10 UJs GREEN`) but never
  contradict it — when a task changes state, update those summaries in the same
  session (see [status-and-tracker.md](status-and-tracker.md) §9).
- Never renumber or delete tasks; supersede with a new task that `refs:` the old.
- In plan-driven (IMPLEMENTATION_PLAN.md) work, execution is approval-gated: one
  task at a time, wait for explicit approval before the next.
