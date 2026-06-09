# init.md — Entry Point for Webhook Delivery Retries Workflow

**Ticket:** 20260601_webhook_delivery_retries
**Location:** tickets/20260601_webhook_delivery_retries/
**SERVICE:** notifier (port 8010)
**PROJECT_ROOT:** the notifier service root (all relative paths below assume it)

---

## How to Read This Ticket

Start here. This file maps the workflow and tells you how to enter it at any point.

### File Map
```
tickets/20260601_webhook_delivery_retries/
├── init.md                  <-- YOU ARE HERE
├── TICKET.md
├── IMPLEMENTATION_PLAN.md
└── work_log.md
```

### Reading Order
1. **This file** — scope, constraints, how to pick up work
2. **TICKET.md** — full problem context and test matrix
3. **IMPLEMENTATION_PLAN.md** — 2 tasks, separated by `$---`
4. **work_log.md** — check what's done and what was approved

## What This Ticket Is About

The delivery worker drops events on consumer 5xx/timeout — no retry, no DLQ.
**Goal:** bounded retries with backoff, then dead-letter persistence + replay.

## Entering This Workflow

### If Starting Fresh
1. Read IMPLEMENTATION_PLAN.md in full
2. Verify service running: `make status && make health`
3. Start with Task 1; follow order 1 → 2

### If Resuming
1. Read work_log.md
2. Find first task with `[ ]` unchecked in IMPLEMENTATION_PLAN.md
3. Run the *previous* task's Verification Steps
4. If a prior task fails validation, fix before moving on
5. Claim the current task in work_log.md, then continue

### If Reviewing/Auditing
1. Read work_log.md for history (claims, approvals, rework)
2. For each `[x]` task, re-run its Verification Steps
3. Compare TICKET.md Audit trail lines against current code

## Critical Rules (Non-Negotiable)
1. Read before you edit; verify line numbers still match before each task
2. One task at a time; **wait for approval** before the next (plan-driven work)
3. Update work_log.md for every claim, approval, rejection, and completion
4. No scope creep — new issues go to TICKET.md "Related Issues" or a new ticket
5. Don't change the event payload schema or subscription CRUD (out of scope)
6. Grep before you're done: `grep -rn "giving up" app/` must return nothing
   after Task 1

## Scope Boundaries
**IN SCOPE:** `app/dispatch/`, `app/cli/replay.py`, `tests/dispatch/`,
`tests/user_journeys/UJ-04*.sh`
**OUT OF SCOPE - DO NOT MODIFY:** `app/api/` (emission path), the consumer SDK
(separate repo)

## Key Code Locations
| What | Path | Key Lines |
|---|---|---|
| Delivery worker | `app/dispatch/delivery_worker.py` | deliver() L88-104 |
| Dispatch config | `app/dispatch/config.py` | L12-30 |
| New: DLQ module | `app/dispatch/dead_letter.py` | Task 2 |
| New: replay CLI | `app/cli/replay.py` | Task 2 |

## Quick Commands
```bash
make status && make health
pytest tests/dispatch/ -q
bash tests/user_journeys/UJ-041_retry_then_dlq.sh
bash tests/user_journeys/UJ-042_happy_path.sh
docker compose logs --tail 100 worker
```

## What's Deferred (Out of Scope)
| Item | Why | Future Ticket |
|---|---|---|
| Per-subscription retry policy | needs product decision on limits | `tickets/backlog/RETRY-002-per-subscription-policy.md` |
| DLQ browsing UI | frontend work | not yet cut — tracked in `tickets/TRACKER.md` |

**Begin by reading work_log.md, then proceed with the next [ ] task.**
