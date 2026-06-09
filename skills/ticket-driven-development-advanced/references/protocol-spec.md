# Protocol Spec (Normative)

This file is the tie-breaker. The other references describe the artifacts; this
one defines the rules that hold between them. Key words MUST / MUST NOT / SHOULD
are normative. When an observed artifact conflicts with this spec, the artifact is
wrong — fix it forward (new entries, never rewrites).

Contents:
1. [Artifact precedence & sync order](#1-artifact-precedence--sync-order)
2. [Task status state machine](#2-task-status-state-machine)
3. [Identifier grammars](#3-identifier-grammars)
4. [Timestamp rules](#4-timestamp-rules)
5. [Severity mapping](#5-severity-mapping)
6. [Verification evidence grammar](#6-verification-evidence-grammar)
7. [Approval-gate rules](#7-approval-gate-rules)
8. [Resume protocol](#8-resume-protocol)
9. [Close protocol](#9-close-protocol)
10. [Registration & creation rules](#10-registration--creation-rules)

---

## 1. Artifact precedence & sync order

**Execution-status precedence** (highest wins when artifacts disagree):

1. `IMPLEMENTATION_PLAN.md` task checklist — *if a plan exists, it is the
   execution source of truth*
2. The tasklist (`tasklist_*.md`) — source of truth when no plan exists
3. `work_log.md` — evidence record (explains status, never defines it)
4. `TRACKER.md` — summary (claims/rollups)
5. `STATUS.md` — snapshot
6. Ticket header `Status:` — coarsest summary, updated at phase changes and close

**Sync order on every state change** — update top-down, same session:

```
plan/tasklist marker  →  work_log entry  →  TRACKER row/claim  →  STATUS (if it
mentions the item)  →  ticket header (only at phase change or close)
```

A disagreement found later is a defect: fix the lower-precedence artifact to match
the higher one, and append a work_log line recording the correction.

**init.md is stateless** — it MUST NOT carry per-task status. If you are tempted
to write status into init.md, it belongs in work_log.md.

## 2. Task status state machine

Canonical marker enum and transitions:

```
            ┌────────────────────────────┐
            ▼                            │
[ ] open ──▶ [~] in-progress ──▶ [x] done (terminal)
  │                │
  │                └──▶ [!] blocked ──▶ [~]   (unblock)
  └──▶ [d] deferred (terminal here; reopens as a NEW task/ticket)
```

| Transition | Required evidence (recorded at the marker or in work_log) |
|---|---|
| `[ ]` → `[~]` | Claim: date + owner (`2026-06-01 claude+mike claimed`) |
| `[~]` → `[x]` | Verification in the evidence grammar (§6). NEVER without it |
| `[~]` → `[!]` | `NOTE:` naming the concrete blocker + who/what unblocks it |
| `[!]` → `[~]` | One line: what unblocked it |
| `[ ]`/`[~]` → `[d]` | Destination: backlog ticket path or "wontfix + reason" |

**Legacy aliases** (read, don't write): `[]` ≡ `[ ]` · `[DEFER]` ≡ `[d]`.
Registry dialects spell the same states as words: `todo / partial / done /
blocked / wontfix` — `partial` ≡ `[~]` with an explicit "what remains" note.

Tasks are never renumbered or deleted. A superseded task keeps its marker and a
new task `refs:` it.

## 3. Identifier grammars

| ID | Grammar | Notes |
|---|---|---|
| Ticket dir | `YYYYMMDD[_HHMMSS]_snake_case_slug/` | `_HHMMSS` only for same-day collisions or audit timestamping |
| Single-file ticket | `PREFIX-NNN-kebab-slug.md` | `PREFIX` = `[A-Z]{2,12}` theme; `NNN` = zero-padded per-prefix counter, never reused |
| Auto-filed ticket | `MISSING-<ISO8601>-<hex4>-<slug>.md` | machine-generated; dedup by slug |
| Task (registry) | `<EPIC>-<n>` (e.g. `SEL-2`) or `T<nn>` | epic-prefixed in .md registries; `T<nn>` in .sh logs |
| Task (plan/tasklist) | `TASK <n>` / `Task <n>` | scoped to that one document |
| Finding (audit-time) | `<Name:category:level>` | the `$-----` handle; Name is UpperCamelCase |
| Finding (stable) | `<AREA>-NNN` (e.g. `BACKEND-001`, `PAYMENT-AUDIT-050`) | assigned **when the remediation tasklist/tracker is cut**, by its author; immutable thereafter |
| UJ test | `UJ-NNN` | per-service counter; numbers are never reused, even for deleted tests |
| Ticket-local finding | single letter+digit (`A1`, `B2`) | only inside one ticket's STATUS board; joins table ↔ per-fix tasklists ↔ owners |

Rule: once an ID has appeared in two or more artifacts it is frozen — renaming
requires a new ID with a `was:` backreference.

## 4. Timestamp rules

| Context | Format | Example |
|---|---|---|
| Dir/file names | bashdate `$(date +%Y%m%d)` (+`_%H%M%S` when needed) | `tasklist_20260601_retries.md` |
| Header fields (`Date:`, `Created:`, `Last updated:`) | `YYYY-MM-DD` | `2026-06-01` |
| Worklog lines | ISO 8601 UTC, minutes precision | `2026-06-01T12:02Z` |
| Audit headers / generated stamps | `YYYY-MM-DD HH:MM:SS UTC` or full ISO 8601 | `2026-02-16 03:04:42 UTC` |
| Prose | absolute dates only | "on 2026-06-01", never "yesterday" |

## 5. Severity mapping

One scale per artifact family; this table is the rosetta:

| Ticket priority | Plan/ticket severity | Audit finding level | Meaning |
|---|---|---|---|
| P0 | CRITICAL / `P0 - Critical (...)` | `critical` | production blocker, data loss, auth bypass — drop other work |
| P1 | HIGH | `high` | blocks a core workflow; fix this sprint |
| P2 | Medium | `medium` | feature gap, degraded UX; schedule |
| P3 | Low | `low` | cleanup, polish; backlog |
| — | — | `info` | inventory/overview entries — not defects |

Severity MUST carry a parenthetical rationale:
`HIGH (silent data loss for consumers, not a security issue)`. A bare `HIGH` is
non-compliant.

## 6. Verification evidence grammar

Everything that flips a task to `[x]` records evidence in one of three forms:

```
verify: UJ-NNN N/N GREEN [Run ID: <id>]
verify: `<command>` → <observed output matching expectation>
verify: manual: <what was checked and what was seen>
```

- UJ form is preferred wherever a test exists; assert counts are mandatory
  (`19/19 GREEN`, never bare `GREEN`).
- Command form quotes the actual command and the relevant observed line.
- Manual form is the last resort and MUST say what was *seen*, not what was done.
- Worklog line shape: `<ISO-ts>  <task-ID>  <status>  — <what>  verify: <evidence>`.
- A claim of "verified" with no evidence string is treated as unverified.

Verdict vocabulary: `GREEN (n/n)` pass · `PARTIAL nn%` (name the failing assert)
· `RED — confirmed` (the test *proved the bug* — used in findings boards) ·
`FAILED` (with one-line root cause) · `NOT RUN`.

## 7. Approval-gate rules

- **Plan-driven work (IMPLEMENTATION_PLAN.md exists): always gated.** One task at
  a time; after verification, present and explicitly ask
  (`"Task N complete. Approve to proceed?"`); do not start the next task until
  approval is recorded. On rejection: fix → re-run the task's full verification →
  re-present. Both rejection and rework go in work_log.md.
- **Tasklist-only work: batch execution allowed** — tasks may be executed
  consecutively without per-task approval, unless the tasklist header or ticket
  says otherwise. Verification-before-`[x]` still applies per task.
- **Phase gates:** in phased plans, all phase-N tasks MUST be approved before any
  phase-N+1 task starts.
- Approval is recorded as a work_log line (`approved by <who>` or the review-round
  outcome), not assumed from silence.

## 8. Resume protocol

**With init.md:** follow its "If Resuming" section (read work_log.md → first
unchecked task → run the *previous* task's validation → continue).

**Without init.md (default sequence):**

1. `tickets/TRACKER.md` — confirm the ticket's current state and claims
2. Ticket header `Status:` — phase and any `claimed` marker
3. The plan/tasklist — find the first `[ ]`/`[~]` task
4. Validate the most recent `[x]` task's verification still passes (cheap re-run)
5. `work_log.md` last entries — context for the in-flight task, open review items
6. Claim the task (`[~]` + date + owner) before touching code

If step 4 fails, fixing that regression precedes the next task, and the work_log
records it as a new entry (the old `[x]` is not unchecked; append a correction).

## 9. Close protocol

A ticket is closed only when ALL of:

- [ ] Every plan/tasklist task is `[x]`, `[d]` (with destination), or explicitly
      superseded
- [ ] Exit criteria / completion checklist evaluated and quoted in work_log.md
- [ ] Test matrix in TICKET.md is current; all listed UJs GREEN with assert counts
- [ ] Ticket header → `**Status:** RESOLVED (YYYY-MM-DD) — <one-line proof>`
- [ ] TRACKER entry moved to Completed, carrying the same proof line
- [ ] "What this does NOT address" lists every surviving gap, each with a created
      follow-up ticket path (two-way linked)
- [ ] STATUS.md updated if the close changes the service snapshot; `Last updated:`
      bumped
- [ ] Lessons learned recorded (STATUS.md or work_log.md) if any rule above was
      hard to follow — that friction is the next process fix

## 10. Registration & creation rules

- Creating a **directory ticket** in a service tree: register it in
  `tickets/TRACKER.md` in the same session. If no TRACKER exists, create one with
  the master-list skeleton (status-and-tracker.md §2) and register both this and
  any pre-existing unregistered tickets you can see.
- Creating an artifact: the **first edit after the header is its backreferences**,
  both directions (backreferencing.md §13 checklist).
- Creating `init.md` implies creating an empty `work_log.md` at the same time.
- A new tasklist that supersedes another MUST name its predecessor
  (`Prior tasklist:`) and the predecessor gains a forward note.
- Scripts/repro artifacts created during the work are saved into the ticket dir
  before the session ends — `/tmp` contents are presumed lost.
