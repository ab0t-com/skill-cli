# init.md — The Agent Onboarding Entry Point

`init.md` (sometimes `INIT.md`) is the **execution contract and stateless
wayfinder** at the root of a ticket directory. It is the first file a fresh agent
or engineer reads when entering (or re-entering) a ticket, at every session
boundary. It routes — it tells you what to read, in what order, and under what
rules. The *what to do* lives in IMPLEMENTATION_PLAN.md; the *why* in TICKET.md.

Contents:
1. [Lifecycle](#1-lifecycle)
2. [Canonical examples](#2-canonical-examples)
3. [Full skeleton](#3-full-skeleton)
4. [Entry modes: fresh / resuming / auditing](#4-entry-modes-fresh--resuming--auditing)
5. [The rules sections](#5-the-rules-sections)
6. [Companion artifacts](#6-companion-artifacts)
7. [Design decisions baked into every init.md](#7-design-decisions-baked-into-every-initmd)

---

## 1. Lifecycle

- **Created** once per ticket, at scoping time (after investigation completes),
  alongside `TICKET.md`, `IMPLEMENTATION_PLAN.md`, and an empty `work_log.md`.
- **Read** cold, with zero prior context, at every session boundary — by agents
  picking up mid-stream, by reviewers, by new engineers.
- **Updated** rarely — only if the workflow or constraints change. Per-task state
  goes in `work_log.md`, never here.

## 2. Worked example and flavors

A complete worked example ships with this skill:
**[../assets/example-ticket/init.md](../assets/example-ticket/init.md)** — copy it
as a starting point. It demonstrates the standard shape: read order, file map,
the three entry modes, rules, scope boundaries, key-code-location table.

Flavors seen in production (adapt the skeleton, don't fork it):

| Flavor | Distinctive additions |
|---|---|
| Multi-service feature | fullest standard shape; existing-vs-new code-location tables; deferred-items table |
| Backend refactor | task-by-task approval workflow spelled out; task dependency diagram |
| Enterprise refactor | boundary guardrails (which code path may do what); priority rules; mandatory read order spanning *other tickets'* design docs |
| Frontend fixes | hard scope walls (IN/OUT-OF-SCOPE paths); key line-number table; per-task verification greps |
| Research ticket | per-item timed read order ("**8 min**"); hard read-only rules; phased workflow with a gated final phase |
| Project-level loop | init.md as meta-process contract for a whole repo, not one ticket |

## 3. Full skeleton

```markdown
# init.md — Entry Point for <Ticket Title> Workflow
        (or: # INIT: Agentic Workflow Handoff / # Agent Initialization: <title>)

**Ticket:** <YYYYMMDD_slug>
**Location:** <absolute ticket dir>
**SERVICE:** <service> (port <N>)
**PROJECT_ROOT:** <absolute root all relative paths assume>

---

## How to Read This Ticket / Mandatory Read Order
Start here. This file maps the workflow and tells you how to enter it at any point.

### File Map
```
tickets/<dir>/
├── init.md                  <-- YOU ARE HERE
├── TICKET.md
├── IMPLEMENTATION_PLAN.md
├── work_log.md
└── context/
    └── <grep dumps>
```

### Reading Order
1. **This file** — scope, constraints, how to pick up work
2. **TICKET.md** — full problem context
3. **IMPLEMENTATION_PLAN.md** — N tasks, each separated by $---
4. **work_log.md** — check what's done
5. **context/** — exact file:line locations
<For complex refactors the read order extends into sibling tickets' design docs
and relevant skill/runbook docs — list them explicitly with paths.
Optionally annotate each entry with a time estimate: "**8 min**.">

## What This Ticket Is About
<3-6 bullet summary of gaps + one-line **Goal:**>

## Entering This Workflow
<the three entry modes — see §4>

## Critical Rules / Execution Rules (Non-Negotiable)
<see §5>

## Scope Boundaries
**IN SCOPE:** <paths>
**OUT OF SCOPE - DO NOT MODIFY:** <paths, with reason ("separate repo")>

## Architecture Principles (For All Tasks)
<the 10 principles, restated>

## Task Workflow Protocol
For each task:
1. Read task in IMPLEMENTATION_PLAN.md
2. Verify prerequisites completed (- [x])
3. Read files listed before changing
4. Implement following the task's steps
5. Validate using every check
6. Verify no regressions (make journey UJ=001/002)
7. Wait for approval
8. On approval: update work_log.md, check [x] in plan
9. On rejection: make changes, re-run validation, present again

## Key Code Locations
| What | Path | Key Lines |
|---|---|---|
| Email Service | appv2/modules/email/services/email_service.py | send_email() L53 |
<split into "Existing" vs "New Code (Created by This Ticket)" tables; pair line
numbers with symbol names so refs survive drift>

## Conventions
<path prefixes, DynamoDB key patterns, Redis keys, naming, permission formats —
only the ones this ticket touches>

## Quick Commands
```bash
make status && make health
docker compose logs --tail 100
make journey UJ=001
source ../venv/bin/activate && python
```

## If Stuck
1. Re-read IMPLEMENTATION_PLAN.md for that task
2. Check CONTEXT_DUMP.md for grep results
3. Look at existing patterns
4. Ask user for clarification
5. DO NOT guess or assume

## What's Deferred (Out of Scope)
| Item | Why | Future Ticket |

## Completion Criteria / Success Criteria
- [ ] <ticket-level done conditions>

**Begin by reading work_log.md, then proceed with next [ ] task.**
```

Optional sections seen in the wild: **Priority Rule** (e.g. "heavy-load isolation
tasks first: Task 4 → 5 → 10, then plan order"), **Boundary Guardrails** (which
code path may do what: "Ingress/write path: validation/auth/idempotent enqueue
only"), **Approval Protocol** (the explicit ask: `"Task N complete. Approve to
proceed?"` — do not proceed until user says approved), **Hard read-only rules**
for research tickets ("these dirs are read-only — all writes go to the ticket
dir"), **Workflow by phase**
(Phase A/B/C with per-phase steps and an optional gated phase).

## 4. Entry modes: fresh / resuming / auditing

The signature section — init.md must support all three entries:

```markdown
### If Starting Fresh
1. Read IMPLEMENTATION_PLAN.md in full
2. Verify service running: make status && make health
3. Start with Task 1; follow order 1 → 2 → ... → N

### If Resuming
1. Read work_log.md
2. Find first task with [ ] unchecked
3. Run its Validation section
4. If a prior task fails validation, fix before moving on
5. Continue with current task

### If Reviewing/Auditing
1. Read work_log.md for history
2. For each [x] task, run its Validation steps
3. Check context/ files for original state
4. Compare against current code
```

Fast-start variant (boundary-heavy tickets) — a Quick Start block of literal
commands:

```markdown
## Quick Start
```bash
Read: tickets/<dir>/TICKET.md
Read: tickets/<dir>/IMPLEMENTATION_PLAN.md
Read: tickets/<dir>/work_log.md
grep -n "\[ \]" tickets/<dir>/IMPLEMENTATION_PLAN.md | head -5
```
```

## 5. The rules sections

Every init.md carries hard constraints. The recurring set (~100% of examples):

- **Read before you edit** — never modify a file you haven't read this session.
- **Validate before implementing** — check the issue still exists and line
  numbers still match before each task.
- **One task at a time** — no jumping, no combining.
- **Wait for approval** after each task before proceeding.
- **Grep before you're done** — sweep all call sites.
- **Log everything** — every change traceable to a task in work_log.md.
- **No scope creep** — new issues go to TICKET.md "Related Issues" or a new
  ticket, never fixed inline.
- **Don't change X** — ticket-specific invariants (JWT structure, test framework,
  existing model/function names).
- Environment facts: PROJECT_ROOT, venv activation, log commands, "don't run
  make summary (30+ minutes)".

## 6. Companion artifacts

| File | Purpose | Written | Read by |
|---|---|---|---|
| `TICKET.md` | Problem statement, root cause, affected code | Before init.md | Anyone needing "why" |
| `IMPLEMENTATION_PLAN.md` | Task list (`$---` separated), per-task verification | Before init.md | Agent finding current task |
| `work_log.md` | Progress + per-task completion evidence | Created empty, updated per task | Agent resuming, reviewer auditing |
| `CONTEXT_DUMP.md` / `context/` | Grep results, file:line refs, code snippets (read-only) | During investigation | Agent looking up exact locations |
| `WHY.md` | Business reasoning, regressions to avoid (R1-R10 constraints) | Longer/risky tickets | Agent weighing trade-offs |
| `RUNBOOK.md`, `FINAL_AUDIT_SUMMARY.md`, `ENDPOINT_PERMISSION_MAP.md` | Optional completion artifacts | At close | Operators, auditors |

## 7. Design decisions baked into every init.md

1. **Entry-point independence** — assumes zero prior context; readable cold.
2. **Approval-gated execution** — non-optional, restated even though the plan
   also says it.
3. **Stateless** — no per-task status here; that's work_log.md's job. init.md
   stays valid all ticket long.
4. **Routing over content** — link to TICKET/plan/context rather than duplicating
   them; duplication drifts.
5. **Scope walls** — explicit IN/OUT-OF-SCOPE paths prevent cross-repo damage.
6. **Principles as law** — the 10 Architectural Principles restated, not linked,
   so they survive being read in isolation.
