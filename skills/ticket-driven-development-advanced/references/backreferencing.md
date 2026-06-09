# Backreferencing — The Linked List of Context

Every artifact links backward to what spawned it and forward to what it spawned.
The result: from any node (a line of code, a failing test, a worklog entry, a
ticket) a reader can walk the chain in either direction and reconstruct the full
story without asking anyone. This file is the exact syntax for every edge.

Contents:
1. [The chain](#1-the-chain)
2. [Ticket → ticket](#2-ticket--ticket)
3. [Ticket ↔ tasklist](#3-ticket--tasklist)
4. [Task → ticket section (§ anchors)](#4-task--ticket-section--anchors)
5. [Ticket/task ↔ UJ tests](#5-tickettask--uj-tests)
6. [Anything → code](#6-anything--code)
7. [Findings → remediation tasks](#7-findings--remediation-tasks)
8. [Worklog → task → ticket](#8-worklog--task--ticket)
9. [Tasklist ↔ tasklist (succession)](#9-tasklist--tasklist-succession)
10. [init.md → everything (the read-order hub)](#10-initmd--everything-the-read-order-hub)
11. [TRACKER claims → audit lines + UJ evidence](#11-tracker-claims--audit-lines--uj-evidence)
12. [STATUS boards → per-fix tasklists + owners](#12-status-boards--per-fix-tasklists--owners)
13. [Completeness checklist](#13-completeness-checklist)

---

## 1. The chain

```
                tickets/TRACKER.md  (master list — registers every ticket, start sessions here)
                      ↕
symptom/evidence
   ↓ captured in
FINDINGS.md / CONTEXT_DUMP.md / investigation work_log phase
   ↓ root cause becomes
TICKET.md  ──Spawned-from──▶ parent ticket
   │  ▲                          │
   │  └──"does NOT address"──────┘   (parent names child; child names parent)
   ├◀── init.md (read-order hub: routes to TICKET/plan/work_log/context, holds rules)
   ↓ Findings:/ticket: headers
IMPLEMENTATION_PLAN.md / tasklist_<bashdate>.md
   ↓ task blocks ($--- / § anchors into ticket)
execution  ──verify──▶ UJ-NNN tests ──▶ code `file.py:NN-NN`
   ↓ append
worklog lines (task-ID + verify note)        TRACKER claims (date + agent + audit:line
   ↓ close                                     + nested updates with UJ run IDs)
TICKET Status: RESOLVED (date) — summary; TRACKER entry → Completed with evidence;
gaps → new tickets (two-way links); STATUS.md snapshot updated
```

Rule: **wire links in both directions at creation time.** When you create a child
ticket, add the forward pointer to the parent in the same edit session.

## 2. Ticket → ticket

**Parent/spawn (in the child's header area):**

```markdown
- **Spawned from:** `tickets/20260508_invitation_list_returns_empty_and_no_email/PART3_invite_landing_redirect_architecture.md` — the PART3 work shipped per-org config...
- Parent: `tickets/20260508_invitation_list_returns_empty_and_no_email/PART3_invite_landing_redirect_architecture.md`
- Sibling (path-unification, fixed): `tickets/20260508_api_key_validation_path_unification/TICKET.md`
```

**Related section (every ticket ends with one):**

```markdown
## Related
- `tickets/20260322_jwt_audience_slug_bug/` — same gateway client, audience issue (fixed)
- `tickets/20260311_cross_service_user_default_team_fix/` — team assignment fix (deployed, working)
- `tickets/2026-02-17_zanzibar-permission-convergence/` — Zanzibar migration (created the two-path resolution)
```

Pattern: backticked relative path (dir form ends with `/`) + ` — ` + one-line
relation + parenthetical state `(fixed)` `(open)` `(deployed, working)`.

**Single-file style** — the `Related` header field, comma-separated:

```markdown
| **Related** | `CLI-001` (modernize), `IMPORT-001` (scan/import), `MIGRATE-001` (dir migration), `docs/REGISTRY-INTERFACE.md` (T35), `tasklist_20260601.sh` (T46 epic) |
```

**Forward pointer from the parent** — the "What this does NOT address" section:

```markdown
## What this does NOT address
- Org-scoped key rotation — see `tickets/20260512_org_key_rotation/`
```

## 3. Ticket ↔ tasklist

**Tasklist header points back at its inputs:**

```markdown
**Findings:** `tickets/findings_20260309_test_suite_investigation.md`
**Branch:** `feature/schema-branch-01`
```

Registry-style tasklists carry a Back-references block:

```markdown
**Back-references**
- Tickets: [`CLI-001`](../tickets/CLI-001-modernize-skill-cli.md) (modernize/rewrite trigger), `SELECT-001`, ...
- Prior tasklist: `tasklist_20260601.sh` (T00–T45, the rewrite + migration)
- Docs: docs/{PRODUCT,DESIGN,PARITY,CUTOVER}.md
```

**Ticket points forward at its tasklist** — via the Related field
(`` `tasklist_20260601.sh` (T46 epic) ``) or by housing the tasklist in the ticket
dir itself (`tickets/<dir>/tasklist_<bashdate>_<desc>.md`).

## 4. Task → ticket section (§ anchors)

Task metadata pins to a specific ticket subsection with `§`:

```markdown
- **status**: done · **tier**: prod · **ticket**: SELECT-001 §Phase1
- **refs**: docs/SELECTION-AND-SCOPING.md §1; reuse filter from sh T07/T12
```

`§Phase1`, `§recommendation`, `§2` refer to heading text or numbered sections in
the target doc. Also used in prose: "implements SELECT-001 §Phase 6 / T35".

## 5. Ticket/task ↔ UJ tests

UJ tests are the proof layer (see the `uj-test-harness` skill for writing them).
Reference by number with assertion counts; tickets carry a test matrix:

```markdown
| UJ | Status | Asserts |
|---|---|---|
| UJ-282 | 10/10 GREEN | X-API-Key works on POST /api-keys/, POST /organizations/{id}/invite |
| UJ-283 | 14/14 GREEN | JWT-only endpoints unaffected by X-API-Key fallback |
| UJ-284 | 15/15 GREEN | 15 malformed-input attacks against X-API-Key all rejected 401 |
```

Discovery direction (test found the bug) is stated in prose:
`UJ-282 demonstrated both gaps. UJ-284 demonstrated a third issue once the first was addressed.`

Status vocabulary: `GREEN (12/12)` · `PARTIAL 91%` (with which assert failed) ·
`FAILED` (with root cause one-liner).

## 6. Anything → code

Always backticked path, with line ranges when pointing at specific logic:

```markdown
`api/discovery.py:124-125` listed `X-API-Key` as an accepted auth header
`api/api_keys.py:42`'s docstring said "Use key for auth -> Header: X-API-Key: {token}"
```

Tabular form for audit trails:

```markdown
| File | Lines | What |
|---|---|---|
| `appv2/services/auth/auth_service_base.py` | 2055-2060 | validate_token calls get_user_permissions |
| `appv2/services/authz/permission_service.py` | 118-225 | get_user_permissions — two-path resolution |
```

Line numbers go stale; pair them with the symbol name so the reference survives
drift (`get_user_permissions — two-path resolution`).

## 7. Findings → remediation tasks

Audit findings get stable IDs; remediation tasks must cite them:

```markdown
- Findings: `BACKEND-001` to `BACKEND-013` (23 total)
- Canonical evidence log: `2026-02-24_audit.md`
- Every task must reference one or more finding IDs
```

Inside the audit file itself, findings carry the `$----- [] <Name:category:level>`
delimiter (see ticket-anatomy.md §3); the `Name` doubles as the citable handle
until a stable ID is assigned.

## 8. Worklog → task → ticket

Worklog lines carry the task ID, which carries the ticket §, closing the loop:

```
2026-06-01T12:02Z  SEL-2  done  — internal/selection: Query.Resolve over catalog; verify: go test ./internal/selection 11/11
```

`SEL-2` → task block (`ticket: SELECT-001 §Phase1`) → SELECT-001 → its Related
field → design doc and sibling tickets. Commits correlate via `git log` over the
same dates/files — quote commit hashes in the worklog when a task lands as a
discrete commit.

## 9. Tasklist ↔ tasklist (succession)

When a tasklist is superseded or frozen, both ends say so:

```markdown
# in the frozen .sh DONE-log:
NOTE: this .sh file is the DONE log (T00–T45); forward backlog lives in tasklist_20260601.md.

# in the successor .md registry:
- Prior tasklist: `tasklist_20260601.sh` (T00–T45, the rewrite + migration)
# and per-task lineage:
- **was**: sh T35
```

## 10. init.md → everything (the read-order hub)

init.md is pure outbound edges — a Mandatory Read Order over the ticket's own
files, sibling tickets' design docs, and relevant skills:

```markdown
## Mandatory Read Order
1. tickets/<this-dir>/TICKET.md
2. tickets/<this-dir>/IMPLEMENTATION_PLAN.md
3. tickets/<this-dir>/work_log.md
4. tickets/20260218_043423_ai_compliance_agent_platform/architecture_boundaries.md
5. <skills-dir>/auth_fastapi_skill/SKILL.md
```

Plus a File Map (tree with `<-- YOU ARE HERE`) and per-file "When to Read" table.
init.md never carries state — it points at work_log.md for that. See
[init-md.md](init-md.md).

## 11. TRACKER claims → audit lines + UJ evidence

TRACKER.md claims cite the source audit **with line number** and nest their
evidence updates under the claim — history readable without git blame:

```markdown
- [x] 2026-02-11 `Codex` claimed: <finding> — `20260210_215323_auth_appv2_permission_mesh_audit.md:81`
  - Update: fix landed in `permission_service.py:118-225`
  - Evidence: UJ-094: 11/11 passed, Run ID: uj094_1770803654_2373188
  - Regression test: scripts/curl_tests/user_journeys/UJ-094_....sh
```

The tracker header names its source (`Audit file: <path>`); finding entries quote
the verbatim `$----- [] <Name:category:level>` block so the tracker stands alone.
Master ticket TRACKERs reference tickets by backticked dir
(`` `20260323_gpu_quota_toctou/` — COMPLETE ``) and keep proof inline
(`UJ-109: 19/19 GREEN`). See [status-and-tracker.md](status-and-tracker.md).

## 12. STATUS boards → per-fix tasklists + owners

Ticket-level STATUS.md boards link findings → UJ proof → per-fix tasklist files →
owning teams, giving each finding its own chain:

```markdown
| ID | Severity | Description | UJ proof | Verdict |
|---|---|---|---|---|
| A1 | HIGH | Non-admin can perform admin billing actions | `UJ-072_...` | RED — confirmed |

## Per-fix tasklists
- [tasklist_A1_admin_dep_collapse.md](tasklist_A1_admin_dep_collapse.md)

## Ownership boundaries
| Surface | Owner | Tasklists |
| `shared/ab0t-quota/` (library) | Library team | A3, I3, LIB |
```

Finding IDs (`A1`, `B2`) are the join key across the table, the tasklist
filenames, the ownership matrix, and the suggested fix order.

## 13. Completeness checklist

When creating or closing an artifact, verify every applicable edge exists:

- [ ] New ticket: `Spawned from:` / parent link present (if any), parent updated
      with forward pointer in the same session
- [ ] New ticket registered in the service's `tickets/TRACKER.md` (if one exists)
- [ ] Ticket has a `## Related` section (or Related field) — even if one entry
- [ ] init.md (if present) lists every ticket file in its read order — no orphans
- [ ] Tasklist/plan header names its Findings/ticket inputs and branch
- [ ] Every task carries a file target; registry tasks carry `ticket: <ID> §<sec>`
- [ ] Every `[x]` has a verify note (UJ-NNN with asserts, or command output)
- [ ] TRACKER claims cite audit `file.md:line`; updates nest with run IDs
- [ ] Closed ticket's Status line summarizes proof (`10/10 UJs GREEN`); TRACKER
      entry moved to Completed with the same evidence
- [ ] Deferred gaps are listed under "What this does NOT address" with a ticket
      path each (create the ticket if it doesn't exist)
- [ ] Superseded tasklists point at successors and vice versa
- [ ] STATUS.md `**Last updated:**` bumped if state changed

Mechanical audit: `grep -rn 'tickets/' <artifact>` should resolve to paths that
exist; `grep -n '\[x\]' tasklist*.md` entries should each have a nearby
`verify`/work-log note.
