# IMPLEMENTATION_PLAN.md — Full Anatomy

The heavyweight planning artifact for large features and large tasks needing many
changes across multiple files. Real examples run 800–2500 lines: complete code
snippets per task, exact verification bash, rollback plans, and approval gates.

Contents:
1. [When to write one](#1-when-to-write-one)
2. [Canonical examples on this machine](#2-canonical-examples-on-this-machine)
3. [Document skeleton](#3-document-skeleton)
4. [Per-task template (the `$---` block)](#4-per-task-template-the-$---block)
5. [The approval workflow](#5-the-approval-workflow)
6. [Distinctive sections in the best plans](#6-distinctive-sections-in-the-best-plans)
7. [Plan vs tasklist vs ticket](#7-plan-vs-tasklist-vs-ticket)

---

## 1. When to write one

Write an IMPLEMENTATION_PLAN.md when the work is:
- a multi-file feature spanning **5+ modules**
- an architecture change (plugin extraction, event-system migration)
- a security overhaul touching multiple endpoints
- production deployment / readiness remediation
- compliance automation, system-wide refactoring

A simple tasklist suffices for: single-file bug fixes, doc updates, config
changes, small feature flags.

The plan is generated **after** investigation (ticket → investigation → plan) and
always lives next to `TICKET.md`, `work_log.md`, and usually `init.md`.

## 2. Worked example and production shapes

A complete, condensed worked example ships with this skill:
**[../assets/example-ticket/IMPLEMENTATION_PLAN.md](../assets/example-ticket/IMPLEMENTATION_PLAN.md)**
(2 tasks, full per-task template, approval workflow, work-log table) — copy it as
a starting point.

Shapes seen at production scale (what "full size" looks like per domain):

| Lines | Domain | Distinctive features |
|---|---|---|
| ~2500 | Architecture extraction (plugin system) | 18 tasks / 7 phases, per-phase approval gates, rollback per task |
| ~1700 | Compliance automation | principles cited per task, perf benchmarks as success criteria, DB migrations, curl-spec'd endpoints |
| ~1700 | Production security hardening | P0/P1 tasks, parameterized IAM policy templates, deployment validation scripts |
| ~1650 | Readiness remediation | 20 tasks, complete error-sanitization utility code, typed model additions |
| ~800 | System migration (events v2) | phased approach, migration scripts inline |

If your repo already has plans under `tickets/`, read the largest one in your
domain before writing your first.

## 3. Document skeleton

```markdown
# <Project Title> - <Implementation Plan | Production Readiness | Feature Automation>

**Ticket**: <ticket dir name>
**Start Date**: <date>
**Updated**: <date>
**Phase**: <N> (<description> - <estimated duration>)
**Priority**: CRITICAL / HIGH / MEDIUM
**Status**: READY FOR <next task> / IN_PROGRESS / COMPLETED

---

## Context / Architecture Overview
<System diagram or bulleted flow. State the key insight that constrains the design, e.g.:>
Event Ingestion Flow:
POST /logs/ingest → event_queue.enqueue_event() → Redis batch →
event_processor.py → AuditEvent objects → ClickHouse INSERT
Key Insight: Control mapping must happen in event_processor (worker), NOT in API.

## Core Principles
<Restate the 10 Architectural Principles — every task cites which it applies.>

## Task Checklist
- [ ] **Task 1**: <name> (<priority>)
- [ ] **Task 2**: <name> (<priority>)
...
**Task Status Legend**: [ ] Not Started · [~] In Progress · [x] Completed · [!] Blocked

---

<task blocks, separated by $--->

---

## Approval Workflow
<see §5 — verbatim block>

## Summary / Completion Checklist
<final deliverables list>

## Work Log
<table tracking completion status of each task>

---
**Created**: <date>  **Status**: <status>  **Next Action**: <action>
```

For very large plans, group tasks into phases with **per-phase gates** (all phase-N
tasks approved before phase N+1 starts).

## 4. Per-task template (the `$---` block)

Tasks are separated by the `$---` delimiter. Every task is self-contained — an
agent should be able to execute it with no other context than the plan + init.md.

```markdown
$---

### TASK <N>: <TITLE>

**Priority**: <P0-P2> - <severity>
**File(s)**: `path/to/file.py`
**Line(s)**: <line numbers>
**Estimated Time**: <estimate>
**Risk if Skipped**: <consequence>

---

#### Objective
<1-2 sentences: what this task accomplishes>

#### Current State
**File**: `path/to/file:line_number`
```python
# Current problematic code, verbatim
```
**Problem**: <bulleted issues>

#### Implementation Steps
1. **<Step name>**
   <detailed instructions>
   ```python
   # exact code to add/change — complete, not sketched
   ```
2. **<Step name>** ...

#### Verification Steps
1. **<Approach>**:
   ```bash
   <exact commands>
   ```
   **Expected**: <what success looks like>
2. **<Integration check>**: <how to verify no regressions>

#### Success Criteria
- ✅ <measurable criterion>
- ✅ <measurable criterion>

#### Principles Applied
- ✅ **Principle 3 (Explicit Contracts)**: <how this task applies it>
- ✅ **Principle 9 (Debuggability)**: ...

#### Rollback Plan
<if this task fails or is rejected, how to revert safely — per task, not per plan>
```

Non-negotiables per task: **complete code** (paste-ready, not pseudocode), **exact
verification bash with expected output**, **a rollback path**, and **principle
citations**. Performance-sensitive tasks state benchmarks as success criteria
("< 0.01ms per mapping, 100,000+ mappings/sec", with the curl/pytest that proves it).

## 5. The approval workflow

Every plan ends with this contract (verbatim pattern):

```markdown
## Approval Workflow
**After completing each task above:**
1. ✅ Run verification steps
2. ✅ Ensure no regressions (run existing tests)
3. ✅ Check performance benchmarks
4. ⏸️ **WAIT FOR USER APPROVAL**
5. ✅ Update `work_log.md` with task completion
6. ✅ Mark task as `[x]` in this plan
7. ➡️ Move to next task

**Do NOT proceed to the next task without explicit user approval.**
```

On rejection: read feedback → make changes → re-run the task's full verification →
present again. The work_log.md records both the rejection and the rework.

## 6. Distinctive sections in the best plans

Include when relevant:

- **Architecture notes with a "Key Insight"** — the one constraint that, if missed,
  invalidates the design (where in the pipeline a concern must live).
- **Complete code templates** — Pydantic models, error-sanitization utilities,
  migration scripts, validation helpers, written out in full in the task body.
- **API endpoint specs with example curls** — request + expected response inline.
- **Performance benchmarks** — numeric targets + the command that measures them.
- **IAM / infra templates** — parameterized policy JSON, deployment validation
  scripts (production-hardening plans).
- **Dependency diagram / task order** — explicit "Tasks must execute in order 1-7"
  with the reason, or a phase DAG.

## 7. Plan vs tasklist vs ticket

| Artifact | Size | Carries | Status model |
|---|---|---|---|
| `TICKET.md` | 100–500 lines | Problem, evidence, decisions, test matrix | Header Status line |
| `IMPLEMENTATION_PLAN.md` | 800–2500 lines | Complete per-task code + verification + rollback, approval gates | `[ ] [~] [x] [!]` checklist + Work Log table |
| `tasklist_*.md` | 50–400 lines | What/why/risk per task, before/after sketches | `[ ] [x] [DEFER]` + `## Work Log` |

The plan **contains** everything an executor needs; the ticket **explains** it; the
tasklist is the lightweight alternative when the plan would be overkill. When a
plan exists, the ticket references it for details and the plan's Task Checklist —
not the ticket — is the execution source of truth.
