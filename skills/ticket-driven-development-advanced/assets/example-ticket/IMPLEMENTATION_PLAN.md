# Webhook Delivery Retries + DLQ - Implementation Plan

**Ticket**: 20260601_webhook_delivery_retries
**Start Date**: 2026-06-01
**Updated**: 2026-06-02
**Phase**: 1 (retry + DLQ core - est. 2 days)
**Priority**: HIGH
**Status**: IN_PROGRESS (Task 1 complete, Task 2 ready)

---

## Context / Architecture Overview

```
POST /events → event_queue.enqueue() → Redis stream →
delivery_worker.deliver() → consumer endpoint
                 └─(on exhaustion)→ dead_letter.write() → DLQ table → replay CLI
```

**Key Insight**: retries must live in the worker, NOT in the API path — the API
must stay fast and the worker already owns per-subscription ordering.

## Core Principles
This plan applies the 10 Architectural Principles (see SKILL.md); each task cites
the ones it exercises.

## Task Checklist
- [x] **Task 1**: Retry loop with backoff in delivery worker (HIGH)
- [ ] **Task 2**: Dead-letter queue module + replay entrypoint (HIGH)

**Task Status Legend**: [ ] Not Started · [~] In Progress · [x] Completed · [!] Blocked

---

$---

### TASK 1: Retry loop with exponential backoff

**Priority**: P1 - HIGH
**File(s)**: `app/dispatch/delivery_worker.py`, `app/dispatch/config.py`
**Line(s)**: worker 88-104, config 12-30
**Estimated Time**: 3h
**Risk if Skipped**: every consumer blip loses events (the headline bug)

#### Objective
Replace log-and-drop with bounded retries: 5 attempts, exponential backoff with
jitter (1s base, 60s cap), then DLQ hand-off.

#### Current State
**File**: `app/dispatch/delivery_worker.py:88-104`
```python
async def deliver(self, event: Event, sub: Subscription) -> None:
    try:
        await self._post(sub.url, event)
    except DeliveryError as e:
        log.error("delivery failed for %s: %s — giving up", event.id, e)
```
**Problem**: single attempt; exception path discards the event.

#### Implementation Steps
1. **Add typed retry settings** to `config.py`:
   ```python
   @dataclass(frozen=True)
   class RetryPolicy:
       max_attempts: int = 5
       base_delay_s: float = 1.0
       max_delay_s: float = 60.0
   ```
2. **Wrap deliver() in the retry loop** (pure backoff calculator + async loop):
   ```python
   async def deliver(self, event: Event, sub: Subscription) -> DeliveryOutcome:
       for attempt in range(1, self.policy.max_attempts + 1):
           try:
               await self._post(sub.url, event)
               return DeliveryOutcome.delivered(attempt)
           except DeliveryError as e:
               if attempt == self.policy.max_attempts:
                   return DeliveryOutcome.exhausted(attempt, e)
               await asyncio.sleep(backoff_delay(self.policy, attempt))
   ```
3. **Route `exhausted` outcomes to the DLQ stub** (full DLQ is Task 2).

#### Verification Steps
1. **Unit**:
   ```bash
   pytest tests/dispatch/test_retry.py -q
   ```
   **Expected**: 7 passed (backoff_delay pure-function table + loop behavior)
2. **UJ**:
   ```bash
   bash tests/user_journeys/UJ-041_retry_then_dlq.sh
   ```
   **Expected**: `UJ-041: 8/8 GREEN`
3. **Regression**: `bash tests/user_journeys/UJ-042_happy_path.sh` → `6/6 GREEN`

#### Success Criteria
- ✅ 5xx endpoint sees exactly 5 attempts with increasing gaps
- ✅ happy path still single-attempt (no perf regression; p50 unchanged)

#### Principles Applied
- ✅ **Principle 3 (Explicit Contracts)**: `DeliveryOutcome` replaces None-return
- ✅ **Principle 7 (No Magic)**: policy constants named in `RetryPolicy`
- ✅ **Principle 10 (Idempotent)**: retry resend is safe under consumer dedup

#### Rollback Plan
Revert the two files; `RetryPolicy` is additive config — no migration to undo.

$---

### TASK 2: Dead-letter queue module + replay entrypoint

**Priority**: P1 - HIGH
**File(s)**: `app/dispatch/dead_letter.py` (new), `app/cli/replay.py` (new)
**Estimated Time**: 4h
**Risk if Skipped**: exhausted events still vanish — Task 1 alone only delays the loss

#### Objective
Persist exhausted deliveries (`evt_id`, `subscription_id`, `attempts`,
`last_error`, `first_failed_at`) and provide `notifier replay <evt_id|--all>`.

#### Current State
No DLQ exists; Task 1 leaves a `# TODO(TASK 2)` stub at the exhaustion branch.

#### Implementation Steps
1. **`dead_letter.py`**: `write(outcome)` + `list(subscription_id)` + `pop(evt_id)`
   over the existing storage layer (one module, one responsibility).
2. **`replay.py` CLI**: re-enqueue through the normal stream so ordering and
   retry policy apply to replays too (pipeline architecture — no side door).

#### Verification Steps
1. ```bash
   pytest tests/dispatch/test_dead_letter.py -q
   ```
   **Expected**: all green
2. ```bash
   bash tests/user_journeys/UJ-041_retry_then_dlq.sh   # asserts DLQ row content
   ```
   **Expected**: `UJ-041: 8/8 GREEN`

#### Success Criteria
- ✅ exhausted event queryable in DLQ within 1s of final attempt
- ✅ replayed event delivered once; DLQ row removed only on confirmed delivery

#### Principles Applied
- ✅ **Principle 5 (Encapsulation)**, **Principle 2 (Pipeline Architecture)**

#### Rollback Plan
Delete the two new modules; Task 1's stub branch logs-and-keeps the DLQ payload
to the worker log (lossy but explicit) until re-landed.

---

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

## Work Log
| Date | Task | Status | Notes |
|---|---|---|---|
| 2026-06-02 | Task 1 | [x] | verify: UJ-041 8/8 GREEN; approved by mike — see work_log.md |
| 2026-06-02 | Task 2 | [ ] | ready; claimed in work_log.md |

---
**Created**: 2026-06-01  **Status**: IN_PROGRESS  **Next Action**: execute Task 2
