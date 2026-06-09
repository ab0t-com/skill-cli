# Ticket Anatomy — Verbatim Templates

Contents:
1. [Directory-style ticket (infra services)](#1-directory-style-ticket-infra-services)
2. [TICKET.md — problem/fix variant](#2-ticketmd--problemfix-variant)
3. [TICKET.md — audit variant](#3-ticketmd--audit-variant)
4. [IMPLEMENTATION_PLAN.md](#4-implementation_planmd)
5. [work_log.md](#5-work_logmd)
6. [Single-file PREFIX-NNN tickets (project-local)](#6-single-file-prefix-nnn-tickets-project-local)
7. [Feature / investigation / migration / results variants](#7-feature--investigation--migration--results-variants)
8. [Auto-filed MISSING tickets](#8-auto-filed-missing-tickets)
9. [Choosing the right shape](#9-choosing-the-right-shape)

---

## 1. Directory-style ticket (infra services)

Location: `<service>/output/tickets/<YYYYMMDD>_<short_description>/`

Scaling by size:

```
# Small fix
tickets/20260508_x_api_key_admin_endpoint_access/
└── TICKET.md

# Medium (investigation + implementation)
tickets/20260327_validate_token_team_permission_resolution/
├── TICKET.md
├── DISCUSSION.md
├── tasklist_20260327_zanzibar_team_permission_fix.md
└── migrate_team_zanzibar_perms.py

# Complex multi-phase
tickets/20260222_scheduler_autoscale_kills_ec2_instances/
├── TICKET.md
├── IMPLEMENTATION_PLAN.md
└── work_log.md

# Large feature / multi-session handoff (the full kit)
tickets/20260226_email_observability_and_tenant_management/
├── init.md                    (entry point — read FIRST; see references/init-md.md)
├── TICKET.md
├── IMPLEMENTATION_PLAN.md     (full per-task form; see references/implementation-plan.md)
├── work_log.md
└── context/
    ├── email_references.txt   (grep dumps, file:line refs)
    └── super_admin_references.txt

# Full audit with remediation
tickets/2026-02-24_audit/
├── 2026-02-24_audit.md        (findings, canonical evidence log)
├── tasklist.md                (remediation tasks, cite finding IDs)
└── context.md                 (state of the world at audit time)
```

Naming: `YYYYMMDD_snake_case_description` (primary). Add `_HHMMSS` for audit-style
precision (`20260216_030442_payment_layer_audit.md`). Older tickets use
`YYYY-MM-DD-kebab-description`; don't create new ones in that style. Backlog items:
`tickets/backlog/PREFIX-NNN-slug.md`.

## 2. TICKET.md — problem/fix variant

```markdown
# <Imperative title of the fix>

**Date:** 2026-05-08
**Severity:** Medium (feature gap + registry inconsistency, not a security issue)
**Surface:** API-key authentication; permission registry validator
**Status:** In Progress

## Problem
<2-3 paragraph narrative. What is broken, who hits it, why it matters.>

## Reproduction
<Exact curl/code that demonstrates it. Real output, not paraphrased.>

## Fix
### `<file 1>`
<Diff or before/after block + why this is the right change.>
### `<file 2>`
...

## Properties guaranteed
- <invariant preserved, bulleted>

## Properties NOT changed
- <explicitly untouched behavior — preempts reviewer questions>

## Tests
### Functional / regression
| UJ | Status | Asserts |
|---|---|---|
| UJ-282 | 10/10 GREEN | X-API-Key works on POST /api-keys/ |
| UJ-283 | 14/14 GREEN | JWT-only endpoints unaffected |

### Adversarial / hacker-mindset (added in this ticket)
| UJ-284 | 15/15 GREEN | 15 malformed-input attacks all rejected 401 |

## Audit trail
| File | Lines | What |
|---|---|---|
| `api/discovery.py` | 124-125 | listed X-API-Key as accepted auth header |

## What this does NOT address
- <gap> — see `tickets/<follow-up-dir>/`

## Related
- `tickets/20260322_jwt_audience_slug_bug/` — same gateway client, audience issue (fixed)
- `tickets/20260314_api_key_permission_resolution_investigation/` — similar resolution issue (open)
```

On close, update the header:
`**Status:** RESOLVED (2026-03-30) — write-through + migration + include_permissions API fix, 10/10 UJs GREEN`

## 3. TICKET.md — audit variant

Audit tickets are findings logs with a per-finding delimiter that encodes
name, category, and level. Declare the delimiter format in the header.

```markdown
# <Layer> Audit - <scope>

- Date: 2026-02-16 03:04:42 UTC
- Scope: `app/` (mesh payment layer)
- Method: full-file code read + targeted grep + readiness/security/compliance/logic review
- Entry format delimiter: `$----- [] <name:category:level>`

## Working Log

### Group: <subsystem> (Initial Deep Pass)
<summary of what was audited in this pass>

$----- [] <RefundAuthBypassAndOrgScopeGap:security:critical>
- Files: `app/api/refunds.py:88-120`
- Evidence: <grep output / code excerpt>
- Problem: <explanation>
- Risk: <impact>
- Recommendation: <fix approach>

$----- [] <FeatureInventory:overview:info>
## API Surface (Observed)
<endpoint inventory by category>

$----- [] <ReadinessAssessment:overview:info>
## Overall Readiness (Based on Code Review)
- Security posture: <assessment> due to: <bullets>
- Correctness posture: ...
- Operability posture: ...

## Highest Priority Fix Order (Suggested)
1. ...

## Coverage
## Additional Context Reviewed
```

Categories seen: `security`, `readiness`, `compliance`, `logic`, `overview`.
Levels: `critical`, `high`, `medium`, `low`, `info`. Findings later get stable IDs
(`BACKEND-001`…) when remediation tasklists are cut; every task must cite finding IDs.

For very large audits, split into numbered files:
`00-EXECUTIVE-SUMMARY.md`, `01-FINDINGS.md`, `02-CRITICAL-FINDINGS.md`,
`03-HARDCODED-VALUES-AND-DEFAULTS.md`.

## 4. IMPLEMENTATION_PLAN.md

Two weights. The **full form** — for large features spanning 5+ modules, with
complete per-task code, exact verification bash, per-task rollback, the 10
Architectural Principles, `$---` task delimiters, and approval gates — is
documented in **[implementation-plan.md](implementation-plan.md)**. Real examples
run 800–2500 lines.

The **lightweight phased form** below fits medium tickets (a few files, prod
impact, but no need for paste-ready code in the plan). Each phase has tasks; each
task has a verification step.

```markdown
# Implementation Plan: <ticket title>

**Ticket:** `TICKET.md` (this dir)
**Branch:** `fix/<slug>`

## Phase 1 — <stop the bleeding>
### Task 1: <imperative>
- **File:** `services/scheduler.py:210-240`
- **Change:** <what>
- **Verify:** <command or UJ that proves it>

## Phase 2 — <root-cause fix>
...

## Phase 3 — <regression coverage>
### Task N: Write UJ-NNN <attack/regression description>
- **Verify:** UJ-NNN GREEN, NN/NN asserts

## Rollback
<how to revert each phase independently>
```

## 5. work_log.md

Append-only. Dated phase headers; review rounds are numbered with finding counts.

```markdown
# Work Log: <ticket title>

## Investigation Phase (2026-02-20 to 2026-02-22)
- Identified sandbox "still starting" issue — EC2 instances disappearing after launch
- CloudTrail confirmed terminations from our own IP via aiobotocore
- Exhaustive code review ruled out: DELETE API, cleanup scheduler, optimizer, ...
- Discovered Redis was checked on wrong database (db=2 instead of db=6)
- Found root cause: `_monitor_resources` stores fabricated `cpu_utilization: 0` ...
- Confirmed with live Redis evidence: all EC2 allocations have `cpu_utilization: 0`

## Review Rounds (2026-02-22)
### Round 1 — 5 findings, all accepted
- `status=stopped` breaks `ResourceStatus` enum → keep status as-is
- Task 1 fix insufficient ... → add `has_datapoints` signal

## Implementation Phase (2026-02-23)
### Task 1: <description> — COMPLETE [x]
<what was done, exact changes>

## Verification Phase
<UJ runs, manual checks, live evidence the fix holds>
```

The "ruled out" lines matter: list every alternative hypothesis eliminated and how.

## 6. Single-file PREFIX-NNN tickets (project-local)

Location: `<project>/tickets/PREFIX-NNN-slug.md` (e.g. `tickets/SELECT-001-skill-selection-and-scoping.md`).
PREFIX groups by theme (CLI, AUDIT, IMPORT, MIGRATE, SELECT, INVESTIGATE, MISSING);
NNN increments per prefix.

Invariant header — a 2-column table:

```markdown
# SELECT-001: skill selection & scoping

| | |
|---|---|
| **Status** | In progress (claimed) |
| **Created** | 2026-06-01 |
| **Author** | Mike Hall |
| **Owner** | claude+mike |
| **Priority** | P1 — fixes the biggest standing design debt |
| **Type** | Feature / architecture (acme-api) |
| **Design** | `acme-api/docs/SELECTION-AND-SCOPING.md` |
| **Related** | `CLI-001` (modernize), `IMPORT-001` (scan/import), `tasklist_20260601.sh` (T46 epic) |
```

Mandatory fields: Status, Created (or Filed), Author, Owner, Priority (with
rationale), Type. Optional: Design, Related, Effort, Source, Confidence (router),
Depends, Refs.

## 7. Feature / investigation / migration / results variants

Section sets by ticket type (all `##` level, in this order):

**Feature:** TL;DR → Core intent → Behavior / In scope (phased: `### Phase N — <desc>`)
→ Out of scope → Acceptance criteria (checkbox list) → Risks / Open questions →
Related → Notes for the implementer.

Acceptance criteria are concrete and testable:

```markdown
## Acceptance criteria
- [ ] `skill import` (no args) scans cwd, lists found skills with their classification (new / exists-skip / self-ignore).
- [ ] A find whose name already exists in the master area is **skipped** and reported; the master copy is byte-unchanged.
- [ ] Unit tests: the scan/classify logic over a temp tree (new vs exists-skip vs self-ignore).
- [ ] `skill import --help` documents flags, behavior, and the safety model.
```

**Investigation:** Background → TL;DR (with recommendation) → deep analysis →
Integration options as lettered alternatives (`### Option A — ...`, each with
Pros/Cons, then a recommendation explaining the pick) → Migration / rollout path →
Open questions for the operator → Surprise findings. Status:
`Investigation complete (proposal; nothing implemented)`.

**Migration (after the fact):** What changed → How it was done → Verification →
Rollback → Notes / open items. Status: `Done`. No acceptance criteria — it shipped.

**Results/findings (e.g. audit results):** TL;DR → Why → What changed → Results
(verbatim tables, scores, verdicts) → Action items the audit surfaced (checkboxes)
→ Cost → What this enables → What's still missing (deferred) → Files changed →
Related.

## 8. Auto-filed MISSING tickets

Filed mechanically (e.g. by `skill discover`), named
`MISSING-<ISO8601-timestamp>-<hex4>-<slug>.md`. Sections: User problem → Why this
is needed → Information the skill should present → Intent and scope (incl. NOT-for
guards) → Trigger phrases → Siblings to disambiguate from → Triggering user prompt
(verbatim, blockquote) → Router reasoning → Next steps (checkboxes). Status:
`Backlog (proposed)`; header carries `Source` and `Confidence (router)`.

## 9. Choosing the right shape

| Situation | Shape |
|---|---|
| Bug with known small fix | Dir + lone `TICKET.md` (infra) or `PREFIX-NNN.md` (project) |
| Bug needing investigation | Dir + `TICKET.md` + `work_log.md`; findings in TICKET Problem/Evidence |
| Multi-phase change, prod impact | Dir + `TICKET.md` + `IMPLEMENTATION_PLAN.md` (lightweight form) + `work_log.md`, review rounds |
| Large feature, many files, multi-session | Full kit: `init.md` + `TICKET.md` + full `IMPLEMENTATION_PLAN.md` + `work_log.md` + `context/`; register in `tickets/TRACKER.md` |
| Whole-surface audit | Dir + audit findings file (`$-----` delimited) + `tasklist.md` + `context.md`; claims tracked in a TRACKER.md |
| Long-running security/audit ticket | Add `STATUS.md` (findings ↔ UJ evidence ↔ per-fix tasklists; see status-and-tracker.md) |
| Design decision needed (agent decides) | `INVESTIGATE-NNN` single file or `DISCUSSION.md` with lettered options |
| Decision is the **user's** to make | `DECISIONS.md` — framed + recommended, annotation left for the user (§10) |
| Already-shipped change to record | Migration variant, Status: Done |
| Idea for later | `tickets/backlog/PREFIX-NNN-slug.md`, Status: Backlog (deferred/proposed) |

Whenever the shape includes `init.md`, also create an empty `work_log.md` at
scoping time and add the ticket to the service's `tickets/TRACKER.md`.

## 10. DECISIONS.md — user-decision log

For tickets carrying choices the **user** must make. The agent frames + recommends;
the user annotates the call. Open decisions block the tasks that depend on them.
See the SKILL.md **Decision logs** section for the convention; this is the shape.

```markdown
# Decision Log — <ticket title>

Authoritative record of decisions for this ticket. Each entry carries the
**decision needed**, **context**, **engineering best-practice recommendation**
(mine, for this project), and an **annotation** block for the call actually made —
*what, by whom, when, why*. A decided entry here SUPERSEDES any conflicting
recommendation in TICKET.md (noted both ways).

Annotation block to fill per decision:
```
DECISION: <chosen option>
BY:       <name>   DATE: <YYYY-MM-DD>
WHY:      <one or two lines>
```
Status legend: ✅ decided · ⬜ awaiting your decision.

---

## ⬜ D-1 — <short title> — **highest-impact**

**Decision needed.** <the question; a one-line answer resolves it>

**Context.** <the constraint that makes this a real choice — file:line evidence,
the security/architecture rule in play, what already exists. Enough to decide
without re-reading the code.>

**Options.**
- **(A) <name>.** *Pro:* … *Con:* …
- **(B) <name>.** *Pro:* … *Con:* …

**Recommendation (mine): A**, because <reasoning>. <Name the tempting-but-wrong
option and why it's wrong here.> <If it needs research, cite the spawned file.>

```
DECISION:
BY:                DATE:
WHY:
```

---

## ✅ D-2 — <short title>

… (same shape; annotation filled) …

---

## Summary table

| ID | Decision | Recommendation | Status |
|----|----------|----------------|--------|
| D-1 | <topic> | **A <name>** (+ guardrails) | ⬜ open |
| D-2 | <topic> | **B <name>** | ✅ decided |

<one line: which decisions block which tasks>

---

# Decision updates — append-only log

> Convention: decisions are **append-only**. The ⬜ blocks + summary table above are
> preserved as the original record (the options + recommendation that led to each
> call). Resolutions are appended below with date/owner; later entries SUPERSEDE
> earlier status for the same ID.

## <YYYY-MM-DD> — User decisions (owner: <name>)

**D-1 → DECIDED. SUPERSEDES the "…" recommendation.**
- DECISION: <what was chosen>
- WHY: <reasoning>
- RESULTING CHANGE to TICKET §N.N: <what in the ticket this changes>
```

Keep `DECISIONS.md` a decision *index*: when a call needs investigation, spawn a
sibling artifact (`<TOPIC>_RESEARCH.md`, `COMPONENT_INVENTORY.md`) and cite it from
the annotation rather than inlining the analysis.
