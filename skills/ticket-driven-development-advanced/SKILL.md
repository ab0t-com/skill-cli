---
name: ticket-driven-development-advanced
description: |
  The complete house system for tickets, implementation plans, tasklists, work logs,
  init.md entry points, and STATUS/TRACKER coordination docs — a
  git-repo-as-issue-tracker workflow where each service owns a
  `<service>/output/tickets/` tree and projects keep local `tickets/` dirs. Use when
  asked to: (1) "create a ticket" / "file a ticket" / "write this up as a ticket"
  for a bug, feature, investigation, audit finding, or migration, (2) write a full
  IMPLEMENTATION_PLAN.md for a large feature spanning many files (per-task
  verification, rollback plans, approval gates, the 10 Architectural Principles),
  (3) write an `init.md` / `INIT.md` agent-onboarding entry point for a ticket
  ("handoff doc", "execution contract", "how does a new agent pick this up"),
  (4) create or update a `tasklist_<bashdate>.md` / `tasklist_<bashdate>.sh`,
  (5) maintain a work_log.md, STATUS.md, or TRACKER.md (master ticket list, audit
  claims tracker, gap inventory, ICE-ranked status table), (6) investigate an issue
  before ticketing it, (7) mark tasks done / update status / close out work / resume
  someone else's ticket mid-stream, (8) resolve conflicts between artifacts or apply
  the normative protocol (status precedence, ID grammars, evidence formats),
  (9) wire up the backreference chain between tickets, plans, tasklists, work logs,
  trackers, UJ tests, commits, and code ("linked list of context"). Covers ticket
  anatomy, naming conventions, task delimiters ($-----, $---, <!-- >>> TASK -->,
  # >>> TASK), approval-gated execution, status discipline, and the
  investigation-first lifecycle.
category: workflow
tags: [tickets, tasklists, planning, worklog, implementation-plan, tracker]
---

# Ticket-Driven Development (Advanced)

The git repo is the issue tracker. Every piece of non-trivial work gets a ticket
(the *why* and *what*), a plan or tasklist (the *how*, broken into verifiable
steps), and a work log (the *what actually happened*). Large work adds an `init.md`
(the *how a fresh agent enters this*) and service-level STATUS/TRACKER docs (the
*where everything stands*). Every artifact backreferences the artifact that spawned
it, forming a linked list of context that lets any future reader — human or agent —
walk from a line of code back to the original symptom, and forward from a symptom
to the tests that prove the fix.

A complete worked example (one ticket with every artifact, fully cross-linked)
ships with this skill: **[assets/example-ticket/](assets/example-ticket/)** and
**[assets/example-service-docs/](assets/example-service-docs/)**. When in doubt
about any format, open those.

## The full artifact stack

| Layer | Purpose | Lives in |
|---|---|---|
| **Ticket** | Strategic intent: problem, evidence, scope, acceptance criteria, risks | `tickets/<id>/TICKET.md` or `tickets/<ID>-slug.md` |
| **Implementation plan** | Large multi-file work: per-task code, verification commands, rollback, approval gates | `tickets/<id>/IMPLEMENTATION_PLAN.md` (1000–2500 lines for big features) |
| **init.md** | Agent onboarding + execution contract: read order, rules, entry modes (fresh/resuming/auditing) | `tickets/<id>/init.md` (or `INIT.md`) |
| **Tasklist** | Smaller work breakdown: ordered, verifiable tasks with status markers | `tasklist_<bashdate>[_desc].md` (ticket dir, repo root, or project root) |
| **Work log** | Execution record: append-only, timestamped, what/when/verified-how | `work_log.md` per ticket; `## Work Log` section in tasklists |
| **TRACKER.md** | Living coordination: master ticket list or audit-claims registry with nested evidence | `tickets/TRACKER.md` (per service) or `output/TRACKER.md` |
| **STATUS.md** | Honest snapshot: what works, gaps, next steps, lessons learned | `output/STATUS.md`, `tickets/<id>/STATUS.md`, `ops/STATUS.md` |

When artifacts disagree, the **normative protocol** decides — precedence, state
machine, ID grammars, evidence formats:
**[references/protocol-spec.md](references/protocol-spec.md)**.

## Where things live

- **Per-service:** `<service>/output/tickets/` — each service owns its tree.
  Ticket = a directory named `YYYYMMDD_short_description/` (bashdate:
  `$(date +%Y%m%d)`; add `_HHMMSS` for same-day collisions or audit-style
  timestamping).
- **Project-local:** a `tickets/` dir at the project root with single-file tickets
  named `PREFIX-NNN-slug.md`. PREFIX groups by theme (CLI, AUDIT, IMPORT, MIGRATE,
  INVESTIGATE...); NNN is a per-prefix counter. Backlog: `tickets/backlog/`.
- **Service master list:** `tickets/TRACKER.md` — "check this file at the start of
  every session." Cross-service tasklists live at the code root
  (`tasklist_<bashdate>_<initiative>.md`).

## Files inside a ticket directory

Scale the file set to the work. A one-file `TICKET.md` is fine for a small fix.
The full large-ticket kit:

| File | When |
|---|---|
| `init.md` | Multi-session / handoff work — entry point, read FIRST, created at scoping time |
| `TICKET.md` | Always — problem, reproduction, fix, properties guaranteed/not-changed, tests, audit trail |
| `IMPLEMENTATION_PLAN.md` | Large features (5+ modules) — per-task code templates, verification, rollback, approval gates |
| `work_log.md` | Anything spanning more than a sitting — append-only, dated phases and review rounds |
| `tasklist_<bashdate>_<desc>.md` | Smaller work breakdown with `$--------` task blocks and checkboxes |
| `STATUS.md` | Long-running tickets — session dumps, findings+UJ-evidence tables, suggested order |
| `DECISIONS.md` | Any ticket carrying open decisions for the user — per-decision: needed / context / agent's best-practice recommendation / annotation of the call actually made (by whom, when, why). See **Decision logs** below |
| `DISCUSSION.md` / `WHY.md` | Design options, rejected approaches, business reasoning, regressions to avoid |
| `FINDINGS.md` / `INVESTIGATION.md` | Audit/discovery results before remediation is planned |
| `CONTEXT_DUMP.md` / `context.md` / `context/` | Grep results, file:line refs, snapshot of external state at scoping time |
| `*.sh`, `*.py` | Test/migration scripts belonging to the ticket — keep them with the ticket |

Templates: **[references/ticket-anatomy.md](references/ticket-anatomy.md)**.
Worked example: **[assets/example-ticket/](assets/example-ticket/)**.

## Choosing the planning artifact

- **Tasklist only** — single-file fixes, config changes, doc updates, small features.
- **IMPLEMENTATION_PLAN.md** — multi-file features (5+ modules), architecture
  changes, security overhauls, migrations, compliance automation. Each task carries
  complete code snippets, exact verification bash, success criteria, and a rollback
  plan; execution is **approval-gated** (stop after each task). Full anatomy:
  **[references/implementation-plan.md](references/implementation-plan.md)**.
- **+ init.md** — whenever the work will span sessions or be handed to another
  agent. It is the stateless wayfinder: mandatory read order, rules, entry modes.
  Full anatomy: **[references/init-md.md](references/init-md.md)**.

## Decision logs: `DECISIONS.md`

When a ticket carries choices that are the **user's to make** — not the agent's —
collect them in a `DECISIONS.md` rather than burying them in the ticket prose or
deciding silently. The agent's job is to *frame each decision and recommend*, then
let the user *annotate the actual call*. It is the approval gate made into an
artifact: a decision stays ⬜ open until the user signs its annotation block, and
work that depends on it is blocked until then.

Each decision entry carries four parts, in order:

1. **Decision needed** — the question, stated so a one-line answer resolves it.
2. **Context** — the constraints that make it a real choice (file:line evidence,
   the security/architecture rule in play, what already exists). Enough for the
   user to decide *without* re-reading the code.
3. **Recommendation (mine)** — the agent's best-practice engineering call *for this
   project*, with the reasoning and the tempting-but-wrong alternative named. When
   there are discrete options, list them as `(A)/(B)/(C)` with pros/cons first.
4. **Annotation block** — left blank for the user; the *authoritative* record once filled:

   ```
   DECISION: <chosen option>
   BY:       <name>   DATE: <YYYY-MM-DD>
   WHY:      <one or two lines>
   ```

Conventions:

- **IDs + status legend.** `D-1, D-2, …` (cross-reference them from TICKET.md and
  tasklist tasks). `✅ decided · ⬜ awaiting decision`. End the file with a summary
  table (`ID | Decision | Recommendation | Status`) so the open set is scannable.
- **Append-only resolutions** (same rule as work logs and trackers). Keep the
  original ⬜ block + recommendation as the record of *why the call was framed that
  way*; add resolutions in a dated "Decision updates" section below. A later entry
  **SUPERSEDES** earlier status for the same ID — say so explicitly, and note any
  resulting change to TICKET.md so the two don't silently disagree.
- **Spawn artifacts, don't inline research.** When a decision needs investigation
  (e.g. "how do others do this"), the finding goes in its own file
  (`<TOPIC>_RESEARCH.md`, `COMPONENT_INVENTORY.md`) and the annotation cites it —
  keeps `DECISIONS.md` a decision *index*, not a dumping ground.
- **A decided `DECISIONS.md` overrides TICKET.md** where they conflict (it is the
  newer, owner-signed record); note the supersession in both directions.

This slots into the lifecycle at **step 3 (Plan)**: surface the decisions, ship the
ticket for review, and only execute the tasks whose blocking decisions (D-N) are
✅. Template: **[references/ticket-anatomy.md](references/ticket-anatomy.md)** §10.

## Lifecycle (investigation-first)

1. **Investigate before ticketing.** Capture symptoms (logs, failing curls, test
   output), read the relevant source fully, rule out alternative hypotheses
   explicitly ("Ruled out X, Y, Z via code read"), root cause with file:line
   evidence. Investigation notes become `FINDINGS.md`/`CONTEXT_DUMP.md` or the
   ticket's Problem/Reproduction sections.
2. **Write the ticket.** Problem narrative, reproduction, severity, surface,
   evidence. State what the ticket does NOT address — explicit non-goals, each
   with a pointer to the follow-up ticket if one exists.
3. **Plan.** Tasklist for small work; IMPLEMENTATION_PLAN.md for large. Every task
   gets: file/line target, what, why, risk, verification, and (in plans) rollback.
   Order by dependency, then priority (user-facing first, infra last; heavy-load
   isolation first when relevant). **Surface user decisions** — anything that is the
   user's call, not yours, goes in `DECISIONS.md` (framed + recommended, annotation
   left blank); tasks blocked on a decision cite its `D-N` and don't execute until
   it's ✅. See **Decision logs** above.
4. **Scaffold the entry point.** For multi-session work, write `init.md` and an
   empty `work_log.md`; register the ticket in `tickets/TRACKER.md` (create the
   TRACKER on first ticket if absent).
5. **Review rounds (production-impact work).** Numbered rounds in the work log:
   `### Round 1 — 5 findings, all accepted`, with each finding's resolution.
6. **Execute, approval-gated.** One task at a time. Validate assumptions before
   coding (line numbers still match, issue still exists). Implement → verify →
   present → **wait for approval** → update work_log.md → mark `[x]` → next task.
7. **Verify, then mark.** A task flips `[ ]` → `[x]` only after its verification
   ran (UJ test GREEN with assert counts, command output recorded). No exceptions.
8. **Close.** Run the close protocol (protocol-spec.md §9): ticket Status →
   `RESOLVED (YYYY-MM-DD) — <proof summary>`; TRACKER entry moves to Completed
   with evidence; surviving gaps become new tickets, backreferenced both ways;
   lessons learned land in STATUS.md.

## Tasklists: `tasklist_<bashdate>.md`

Header backreferences inputs (`**Findings:**`, `**Branch:**`), then delimited task
blocks, then an append-only `## Work Log` and `## Exit Criteria`. Status markers:
`[ ]` open · `[~]` in progress · `[x]` done-and-verified · `[d]`/`[DEFER]` deferred
· `[!]` blocked.

Four delimiter dialects — keep them byte-stable, never invent a fifth:

| Delimiter | Where |
|---|---|
| `$-------- [ ] TASK N:` | Plain tasklists |
| `$----- [] <Name:category:level>` | Audit findings logs / severity-tagged compliance tasklists |
| `$---` | Between tasks inside IMPLEMENTATION_PLAN.md |
| `<!-- >>> TASK -->` / `# >>> TASK` | Markdown task registries / executable `.sh` DONE-logs (`./tasklist_<date>.sh todo\|show T03\|verify`) |

Full formats: **[references/tasklist-formats.md](references/tasklist-formats.md)**.

## The backreference chain ("linked list of context")

Every artifact points back at what spawned it and forward at what it spawned:

```
                     tickets/TRACKER.md (master list — start every session here)
                          ↑ registers / routes ↓
symptom → FINDINGS/CONTEXT_DUMP → TICKET.md ←─ init.md (read order hub)
            ↑                        ↑  ↓ Related / Spawned-from
   work_log phases          sibling & parent tickets
            ↓                        ↓
   task [x] + verify ← IMPLEMENTATION_PLAN tasks → UJ-NNN tests ←→ `file.py:NN-NN`
            ↓
   STATUS.md snapshot (findings ↔ UJ evidence ↔ per-fix tasklists ↔ owners)
```

Conventions (exact syntax in **[references/backreferencing.md](references/backreferencing.md)**):

- **Parent/spawn:** `**Spawned from:** \`tickets/<dir>/....md\` — <why>` in the
  child; the parent's "What this does NOT address" names the child.
- **Related section:** every ticket ends with `## Related` listing siblings as
  `` `tickets/<dir>/` — <one-line relation> (fixed|deployed|open) ``.
- **init.md → everything:** a Mandatory Read Order list is the hub's outbound edges.
- **Tasklist → ticket:** `ticket: SELECT-001 §Phase2` — `§` anchors pin a task to
  a ticket subsection.
- **TRACKER claims → audit lines:** `<audit-file>.md:81` — finding evidence cites
  the audit file *with line number*; updates nest under the claim with UJ run IDs.
- **Tests:** `UJ-284 | 15/15 GREEN | <what it proves>`; RED = exploit confirmed.
- **Code:** always backticked path + lines: `` `api/discovery.py:124-125` ``.
- **Worklog lines:** `2026-06-01T12:02Z  SEL-2  done  — <what> verify: <how>`.

When you create any new artifact, your first edit after the header is wiring these
links — both directions.

## Severity, status, and header conventions

```markdown
**Date:** 2026-05-08
**Severity:** HIGH (silent data loss for consumers, not a security issue)
**Surface:** webhook dispatcher; delivery worker
**Status:** RESOLVED (2026-06-03) — retry + DLQ landed, 10/10 UJs GREEN
```

- Severity always carries a parenthetical rationale, never bare. Scales and their
  mapping (P0–P3 ↔ CRITICAL/HIGH/MEDIUM/LOW ↔ audit `critical…info`):
  protocol-spec.md §5.
- Ticket status values: `In Progress`, `DESIGN (awaiting review)`, `DISCUSSION`,
  `Backlog (proposed|deferred)`, `OPEN — <findings state>`, `RESOLVED (date) — summary`, `Done`.
- Audit finding tags: `<Name:security|logic|readiness|compliance:critical|high|medium|low|info>`.
- Test verdicts: `GREEN (12/12)` · `PARTIAL 91%` · `RED — confirmed` · `FAILED`.

## The 10 Architectural Principles

Implementation plans and init.md files restate these and require every task to say
which it applies. Keep the canonical numbering:

1. Pure Functional — business logic as pure functions
2. Pipeline Architecture — linear data flow through transformations
3. Explicit Contracts — full type hints, dataclasses for schemas
4. Async-First — all I/O async
5. Encapsulation — one module = one responsibility
6. Testability — pure functions = easy tests
7. No Magic — explicit > implicit, constants named
8. Performance-Aware — target metrics stated (e.g. 1000+ req/s)
9. Debuggability — logs + metrics at boundaries
10. Idempotent — safe to replay

## Rules

1. **Investigate before writing.** Never ticket a symptom without root-cause
   evidence (file:line, logs, ruled-out alternatives).
2. **Bashdate everything.** Dirs and tasklists carry `$(date +%Y%m%d)`; logs carry
   full dates; never relative dates. (Timestamp rules: protocol-spec.md §4.)
3. **Append-only logs and trackers.** Never rewrite history or delete completed/
   deferred items — corrections and updates are new nested entries.
4. **Verify before `[x]`.** Status flips only on recorded verification in the
   evidence grammar (protocol-spec.md §6).
5. **One task at a time, approval-gated.** In plan-driven work, do not proceed to
   the next task without explicit approval; on rejection, fix → re-verify → re-present.
6. **Read before you edit; grep before you're done.** Validate line numbers and
   assumptions still hold before each task; sweep call sites after.
7. **Explicit non-goals.** Every ticket states what it does NOT address; deferred
   items get their own ticket and a two-way link.
8. **No scope creep.** New discoveries go to TICKET.md "Related Issues" or a new
   ticket — never fixed inline.
9. **Greppable delimiters.** Keep `$-----`/`$---`/`>>> TASK` markers byte-stable.
10. **The artifact lives with the work.** Scripts, repro curls, migration code go
    in the ticket dir, not /tmp.

## Reference files

- **[protocol-spec.md](references/protocol-spec.md)** — the NORMATIVE spec: artifact
  precedence + sync order, task status state machine with required evidence per
  transition, identifier grammars, timestamp rules, severity mapping, verification
  evidence grammar, approval-gate rules, resume protocol (with and without init.md),
  close protocol. Read when artifacts disagree or when enforcing the system.
- **[ticket-anatomy.md](references/ticket-anatomy.md)** — verbatim templates for
  TICKET.md (fix/audit/investigation/feature/migration/results variants), work_log.md,
  the `PREFIX-NNN` single-file style, and shape selection. Read when writing a ticket.
- **[implementation-plan.md](references/implementation-plan.md)** — full anatomy of
  large IMPLEMENTATION_PLAN.md files: per-task template ($--- blocks, Objective →
  Current State → Steps → Verification → Success Criteria → Principles Applied →
  Rollback), approval workflow, when to use one. Read when planning large features.
- **[init-md.md](references/init-md.md)** — the agent-onboarding entry point: read
  order, entry modes (fresh/resuming/auditing), rules sections, key-code-location
  tables, quick commands. Read when scaffolding or picking up multi-session work.
- **[status-and-tracker.md](references/status-and-tracker.md)** — TRACKER.md (master
  ticket list, audit-claims registry with nested evidence), STATUS.md (gap inventory,
  session dumps, findings+UJ tables, ICE-ranked status), update protocols. Read when
  maintaining coordination docs or starting a session on a service.
- **[tasklist-formats.md](references/tasklist-formats.md)** — the task-block dialects,
  worklog line format, exit criteria. Read when creating or updating a tasklist.
- **[backreferencing.md](references/backreferencing.md)** — exact link syntax for
  every edge in the context chain. Read when wiring a new artifact into the chain
  or auditing link completeness.

## Bundled examples (assets/)

A complete, internally cross-linked worked example — fictional `notifier` service,
ticket `20260601_webhook_delivery_retries`. Copy these as starting templates:

- **[assets/example-ticket/init.md](assets/example-ticket/init.md)** — entry point
- **[assets/example-ticket/TICKET.md](assets/example-ticket/TICKET.md)** — problem/fix ticket
- **[assets/example-ticket/IMPLEMENTATION_PLAN.md](assets/example-ticket/IMPLEMENTATION_PLAN.md)** — full per-task form (condensed to 2 tasks)
- **[assets/example-ticket/work_log.md](assets/example-ticket/work_log.md)** — investigation → review → implementation → verification
- **[assets/example-service-docs/TRACKER.md](assets/example-service-docs/TRACKER.md)** — service master ticket list
- **[assets/example-service-docs/STATUS.md](assets/example-service-docs/STATUS.md)** — service snapshot
