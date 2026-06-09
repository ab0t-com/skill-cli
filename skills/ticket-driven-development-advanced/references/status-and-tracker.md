# STATUS.md & TRACKER.md — Living Coordination Documents

Unlike tasklists (run-once execution specs) these are **continuously updated
coordination docs**: append-only, no deletion of completed/deferred items, every
state change backed by evidence (UJ run IDs, file:line audit refs, test verdicts).

Contents:
1. [Which one, and where](#1-which-one-and-where)
2. [TRACKER.md — master ticket list (per service)](#2-trackermd--master-ticket-list-per-service)
3. [TRACKER.md — audit-claims registry](#3-trackermd--audit-claims-registry)
4. [STATUS.md — gap inventory / honest snapshot](#4-statusmd--gap-inventory--honest-snapshot)
5. [STATUS.md — ticket-level findings board](#5-statusmd--ticket-level-findings-board)
6. [STATUS.md — session context dump](#6-statusmd--session-context-dump)
7. [ICE-ranked status tables](#7-ice-ranked-status-tables)
8. [Status vocabulary](#8-status-vocabulary)
9. [Update protocol](#9-update-protocol)
10. [STATUS vs TRACKER vs tasklist vs work_log](#10-status-vs-tracker-vs-tasklist-vs-work_log)

---

## 1. Which one, and where

| Artifact | Granularity | Location | Bundled/sketched in |
|---|---|---|---|
| Master ticket TRACKER | All tickets of one service | `<svc>/output/tickets/TRACKER.md` | **[../assets/example-service-docs/TRACKER.md](../assets/example-service-docs/TRACKER.md)** + §2 |
| Audit-claims TRACKER | Findings of one audit | `<svc>/output/TRACKER.md` or `TRACKER_<ts>/md/TRACKER.md` | §3 (production examples reach 2400+ lines) |
| Service STATUS | One service's audit/hardening state | `<svc>/output/STATUS.md` | **[../assets/example-service-docs/STATUS.md](../assets/example-service-docs/STATUS.md)** + §4 |
| Ops STATUS | Deploy automation, gaps, roadmap | `ops/STATUS.md` | §4 |
| Ticket STATUS | One long-running ticket | `tickets/<dir>/STATUS.md` | §5 |
| Ranked tasklist status | One initiative's items by priority | `tickets/<dir>/tasklist_status.md` | §7 |

## 2. TRACKER.md — master ticket list (per service)

The session entry point for a whole service. Header says so explicitly:

```markdown
# Ticket Tracker — Resource Service

Master list of tickets, their status, and what to work on next.
Check this file at the start of every session.

**Last updated:** 2026-03-26

---

## Strategic / Discussion
### Multi-Cloud Adapter Strategy (`20260326_multi_cloud_adapter_strategy/`) — DISCUSSION

## Completed Tickets
### GPU Quota TOCTOU Race (`20260323_gpu_quota_toctou/`) — COMPLETE
DynamoDB atomic counter replaces scan-then-allocate TOCTOU gap.
- `database.py`: `increment_quota()`, `decrement_quota()`, `reconcile_quota()` — all implemented
- UJ-109: 19/19 GREEN

## Active Tickets
### 1. EKS Sandbox Proving Ground (`20260206_eks_sandbox_proving_ground/`)
**Status:** IN PROGRESS — Scripts 26, 27, 28, 31 PASS. Script 32 not yet run.
**Priority:** HIGH
**What's left:**
- Run script 32 (persistent server)
- Write docs

## Architecture Tickets (Proposals — Not Yet Implemented)

## Unimplemented Features
| # | Ticket | Priority | Dir | Status |
|---|---|---|---|---|
| 15 | Firecracker microVM Production | HIGH | `20260323_firecracker_microvm_production/` | PHASES 1-7 DONE — Go manager (54 tests)... |

## UJ Test Suite
| UJ | Name | Status |
|---|---|---|
| UJ-109 | GPU quota atomic counter | GREEN (19/19) |
```

Every entry carries the ticket dir in backticks (the link into the chain), a
one-line state with **evidence**, and "What's left" for active items. Completed
tickets keep their proof (UJ counts) forever.

## 3. TRACKER.md — audit-claims registry

For coordinating multi-agent remediation of a big audit. Header states the rules
and the source audit; body is claims with **nested update history**:

```markdown
# Global Task Tracker

## Status Legend
- [ ] Not started
- [~] In progress
- [x] Completed
- [d] Deferred

## Operating Rules
- Small, reviewable patches only.
- No breaking API/interface changes without approval.
- Log every meaningful action in the worklog.

## Source
- Audit file: tickets/audit/20260302_215912_global_payment_mesh_audit.md
- Tracker generated: 2026-03-03T00:06:52Z UTC

## Claims
- [x] 2026-02-11 `Codex` claimed: <finding title> — `20260210_215323_auth_appv2_permission_mesh_audit.md:81`
  - Update: fix landed in `permission_service.py:118-225`
  - Evidence: UJ-094: 11/11 passed, Run ID: uj094_1770803654_2373188
  - Regression test: scripts/curl_tests/user_journeys/UJ-094_....sh

## Critical Findings
- [x] **PAYMENT-AUDIT-050** (readiness/critical): Test/stub routers are mounted...
  ```text
  $----- [] <PAYMENT-AUDIT-050:readiness:critical>
  <verbatim evidence block from the audit>
  ```

## High Findings
- [x] **PAYMENT-AUDIT-001** (security/high): Unauthenticated Prometheus metrics endpoint...
```

Key mechanics:
- **Claims carry date + agent name + audit-file:line** — who took what, from where.
- **Updates nest under the claim** (indented bullets) with run IDs, file:line of
  the fix, regression-test paths — history legible without git blame.
- **Verbatim evidence blocks** quoted from the audit so the tracker stands alone.
- `[d]` deferred items stay marked, never removed.

## 4. STATUS.md — gap inventory / honest snapshot

The "honest picture" doc — what works end-to-end, what's manual, what's next.
Canonical shape (an ops/deploy example):

```markdown
# ops/STATUS.md — automation status & gap inventory

**Last updated: 2026-05-08.** Living doc. Update when state changes.

This is the honest picture of where automated deploy stands today, what
works end-to-end, what's still manual, and what needs to be built next.
Pair with `ops/DEPLOY.md` (the lifecycle reference).

## What's working today
| Phase | Script | State |
|---|---|---|
| 0. one-time clone setup | `ops/setup-laptop-setup-0.sh` | ✅ ran, green |
| 1. provision AWS | `ops/aws/bootstrap-prod-provision-1.sh` | ✅ ran end-to-end |

## Gaps (numbered, prioritized)
### Gap 1: Trigger (with approval gate)
**Today:** every prod deploy is a manual `bash ops/deploy/...-4.sh <svc>` invocation.
**Needed:** push-to-main triggers automated build + ECR push; prod deploy still gated.

## What we've run end-to-end
| Run | Outcome |
|---|---|
| `bootstrap-prod-provision-1.sh --fix` (last green run) | 20 ok / 0 failed |

## Roadmap (ordered by my recommendation)
1. **Run pipeline-4 once...** — `billing` or `audit`. Manual run...
```

Pattern: **Today/Needed** pairs per gap; outcomes tables with real numbers; a
companion-doc pointer in the header. The service-level variant
(`tool/output/STATUS.md`) is leaner: `## Current Status` one-liner + `## Worklog`
of single-line append entries ending in the validation command that proves the
state.

## 5. STATUS.md — ticket-level findings board

For long-running security/audit tickets: findings ↔ UJ evidence ↔ per-fix
tasklists ↔ owners, plus a recommended order:

```markdown
# Ticket 20260428 — ab0t-quota Proxy Security Audit

**Opened:** 2026-04-28
**Status:** OPEN — findings proven by UJ tests; fixes designed but not yet landed.
**Origin:** Audit triggered while debugging `/pricing` page rendering...

## Findings + UJ evidence
| ID | Severity | Description | UJ proof | Verdict |
|---|---|---|---|---|
| A1 | HIGH | Non-admin org member can perform admin billing actions | `scripts/curl_tests/user_journeys/UJ-072_...` | RED — confirmed; topup created |
| A2 | HIGH (latent) | Payment service API key not org-scoped | `UJ-076_...` | RED — confirmed |

## Per-fix tasklists
- [tasklist_A1_admin_dep_collapse.md](tasklist_A1_admin_dep_collapse.md)
- [tasklist_A2_payment_service_key_org_scoping.md](tasklist_A2_payment_service_key_org_scoping.md)

## Ownership boundaries (high-level)
| Surface | Owner | Tasklists |
|---|---|---|
| `shared/ab0t-quota/` (library) | Library team | A3, I3, I1, LIB |
| `payment/output/` (upstream) | Payment-service team | A2, B2 |

## Suggested order
1. **A1** — real-money exposure (topup proven). Short-term sandbox fix is small.
2. **B2** — until 500s are clean, A3 verification is blocked.
```

Note the verdict vocabulary: **RED = exploit confirmed** (the UJ proved the bug),
GREEN = passing. Each finding spawns its own per-fix tasklist file.

## 6. STATUS.md — session context dump

For proving-ground / exploratory work, STATUS.md doubles as the session handoff:

```markdown
# <Project> — Full Context Dump
**Date:** 2026-02-06
**Branch:** `feature/schema-branch-01`
**Working Dir:** <service>/output

## WHAT WE ARE DOING
## WHAT WAS DONE THIS SESSION
### 1. <change> — **Files modified:** ...
## SIDETRACK LOG
**2026-02-07:** Got sidetracked building the cluster-agent...
## WHAT NEEDS TO BE DONE — TASK LIST
### Step 3: Run EKS test scripts — IN PROGRESS
- [x] 26-nginx-simple.sh — PASS
- [ ] 32-persistent-server.sh — NOT RUN
## LESSONS LEARNED THIS SESSION
1. **Don't assume what the user wants** — ...
```

The **Sidetrack Log** and **Lessons Learned** sections are unique to this flavor —
record them; they're the cheapest institutional memory you'll ever write.

## 7. ICE-ranked status tables

When an initiative has many independent items, rank by ICE
(Impact × Confidence × Ease, each 1-10, multiplied):

```markdown
# PMM tasklist status — quick reference

**Last updated:** 2026-04-27
**Source ranking:** [`PMM_AUDIT_2026-04-25.md`](../../instances/legal/docs/PMM_AUDIT_2026-04-25.md), §12
**Index (full detail):** [README.md](README.md)

| Rank | ICE | Status | Item | Effort | Tasklist |
|---|---|---|---|---|---|
| 1 | 729 | ✅ DONE 2026-04-27 | ✦ Output disclaimer + audit-trail link | 1d | [disclaimer_audit_trail](tasklist_20260427_disclaimer_audit_trail.md) |

## Legend
| Status | Meaning |
|---|---|
| ✅ DONE | Shipped, tests passing, work log closed in tasklist file |
| NEXT | The next item recommended for pickup |
| in progress | Active work, see tasklist's work log for current state |
| pending | On the shortlist, waiting for slot |
| shortlist | Recommended for the current sprint (✦ in column) |
| off-shortlist | Lower priority; revisit when shortlist is clear |
```

Completion dates attach to the status (`✅ DONE 2026-04-27`); each row links to
its per-item tasklist file.

## 8. Status vocabulary

- Checkboxes: `[ ]` not started · `[~]` in progress · `[x]` completed · `[d]` deferred · `[!]` blocked
- Tests: `GREEN (19/19)` · `RED — confirmed` · `PASS` / `FAIL` / `NOT RUN` · `PARTIAL 91%`
- Tickets: `DISCUSSION` · `IN PROGRESS` · `COMPLETE` · `Planning` · `OPEN — <state>` · `Blocked on <reason>`
- Health marks: ✅ working · ⚠️ partial · `NEXT` · `✦` shortlisted
- Finding tags: `<Name:security|logic|readiness|compliance|bug|reliability|governance:critical|high|medium|low|info>`

## 9. Update protocol

When an item changes state, update **every place that mentions it**, same session:

1. The row/claim in STATUS.md or TRACKER.md (status cell + date + evidence)
2. The item's tasklist work log (start / blocker / decision / completion entry)
3. Any index (README.md) row to match
4. `**Last updated:**` in the doc header

Never delete: completed and deferred items remain forever with their evidence.
Corrections are new nested entries, not edits to old ones.

## 10. STATUS vs TRACKER vs tasklist vs work_log

| Artifact | Focus | State model | Cadence | Primary use |
|---|---|---|---|---|
| **STATUS.md** | Health, readiness, what-we-did, gaps | Coarse status + ✅/⚠️ tables | Sporadic; milestones | Snapshot, handoff, honesty check |
| **TRACKER.md** | Per-ticket or per-claim execution + evidence | `[ ] [~] [x] [d]` + nested update history | Append-only, per claim | Session entry point, multi-agent coordination, audit trail |
| **tasklist** | Spec + acceptance criteria, how to execute | Checkbox + worklog | Append-only per task | Step-by-step implementation |
| **work_log.md** | What happened, who, when, decisions | Free narrative, dated | Append-only | Retrospective, context recovery |
