# notifier STATUS.md — reliability hardening snapshot

**Last updated: 2026-06-02.** Living doc. Update when state changes.

Honest picture of where webhook delivery reliability stands, what works
end-to-end, and what's next. Pair with `tickets/TRACKER.md` (per-ticket state).

## Current Status
- Retry+DLQ work IN PROGRESS (`tickets/20260601_webhook_delivery_retries/`) —
  retries shipped, DLQ landing next.

## What's working today

| Surface | Evidence | State |
|---|---|---|
| Delivery retries w/ backoff | UJ-041 8/8 GREEN | ✅ shipped 2026-06-02 |
| Happy-path latency | UJ-042 6/6 GREEN, p50 unchanged | ✅ no regression |
| Signature rotation | UJ-038 12/12, UJ-039 9/9 | ✅ shipped 2026-05-16 |

## Gaps (numbered, prioritized)

### Gap 1: exhausted events still lossy until DLQ lands
**Today:** Task 1 stub logs the would-be DLQ payload to the worker log.
**Needed:** `dead_letter.py` + replay CLI (Task 2, claimed).

### Gap 2: no flapping-endpoint coverage
**Today:** UJ-043 planned, not written.
**Needed:** write + run before closing the ticket (close protocol blocks on it).

## Worklog
- 2026-06-02 — Task 1 (retry loop) shipped; validation: `pytest tests/dispatch -q` green, UJ-041/042 GREEN.
- 2026-06-01 — Reliability audit finding NOTIF-003 ticketed as 20260601_webhook_delivery_retries.

## Lessons learned
1. Writing UJ-041 RED *before* the fix made the review round concrete — keep
   doing test-first for reliability gaps.
