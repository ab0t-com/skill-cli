# Webhook delivery has no retry or dead-letter handling

**Date:** 2026-06-01
**Severity:** HIGH (silent data loss for consumers, not a security issue)
**Surface:** webhook dispatcher; delivery worker
**Status:** In Progress

## Problem

When a consumer endpoint returns 5xx or times out, the delivery worker logs the
error and drops the event. There is no retry, no backoff, and no dead-letter
queue — consumers silently miss events whenever they have a deploy blip.

Discovered while investigating a consumer report of missing `order.created`
events (see `work_log.md` Investigation Phase). UJ-041 demonstrated the drop.

## Reproduction

```bash
# Point a subscription at a 503-returning endpoint, emit one event:
curl -s -X POST localhost:8010/events -d '{"type":"order.created","id":"evt_1"}'
# Worker log:
#   delivery failed for evt_1: 503 — giving up
# No retry attempt, evt_1 never redelivered. UJ-041 asserts this drop.
```

## Fix

### `app/dispatch/delivery_worker.py`
Wrap `deliver()` in a retry loop: 5 attempts, exponential backoff with jitter
(1s base, 60s cap). On exhaustion, hand off to the DLQ instead of dropping.
See `IMPLEMENTATION_PLAN.md` TASK 1 for the exact code.

### `app/dispatch/dead_letter.py` (new)
DLQ writer + replay entrypoint. Records `evt_id`, `subscription_id`,
`attempts`, `last_error`, `first_failed_at`. TASK 2.

## Properties guaranteed
- Every event reaches the consumer or the DLQ — no third outcome.
- Delivery order within a subscription is preserved across retries.
- Replay is idempotent: re-delivering a DLQ'd event a consumer already has is
  safe (consumer dedup contract on `evt_id` is unchanged).

## Properties NOT changed
- Event emission API and payload schema — untouched.
- Subscription CRUD endpoints — untouched.
- At-least-once semantics — we still do not promise exactly-once.

## Tests

### Functional / regression
| UJ | Status | Asserts |
|---|---|---|
| UJ-041 | 8/8 GREEN | 5xx endpoint → 5 retries with backoff → event lands in DLQ, not dropped |
| UJ-042 | 6/6 GREEN | happy-path delivery unaffected; single attempt, no DLQ write |

### Adversarial (added in this ticket)
| UJ | Status | Asserts |
|---|---|---|
| UJ-043 | planned | flapping endpoint (alternating 200/503) — no duplicate deliveries, order preserved |

## Audit trail
| File | Lines | What |
|---|---|---|
| `app/dispatch/delivery_worker.py` | 88-104 | deliver() logged + dropped on failure |
| `app/dispatch/config.py` | 12-30 | no retry/backoff settings existed |

## What this does NOT address
- Per-subscription retry policy overrides — see `tickets/backlog/RETRY-002-per-subscription-policy.md` (created, Backlog)
- DLQ browsing UI — follow-up ticket not yet cut; tracked in `tickets/TRACKER.md` Unimplemented Features

## Related
- `tickets/20260514_subscription_signature_rotation/` — same worker, signing path (fixed)
- `tasklist_20260520_notifier_reliability_audit.md` — the audit that ranked this gap (finding `NOTIF-003`)
