# Work Log: Webhook Delivery Retries + DLQ

Ticket: `tickets/20260601_webhook_delivery_retries/` · append-only — corrections
are new entries, never edits.

## Investigation Phase (2026-05-31 to 2026-06-01)

- Consumer report: missing `order.created` events during their 14:02 deploy window
- Worker logs show `delivery failed ... — giving up` at matching timestamps
- Read `app/dispatch/delivery_worker.py` in full — single attempt, exception path drops
- Ruled out: queue loss (Redis stream offsets intact), emission path (events
  present in stream), consumer dedup (no evt_ids ever arrived) — via log + code read
- Root cause: `delivery_worker.py:88-104` log-and-drop on DeliveryError
- Wrote UJ-041 RED first: `UJ-041: 0/8` — drop reproduced mechanically
- Audit cross-ref: this is finding `NOTIF-003` in
  `tasklist_20260520_notifier_reliability_audit.md`

## Review Rounds (2026-06-01)

### Round 1 — 3 findings, 2 accepted, 1 rejected
- Backoff needs jitter or synchronized consumers thundering-herd → accepted (plan updated)
- DLQ replay must go through the normal stream, not direct POST → accepted (Task 2 step 2)
- "Make retries per-subscription configurable now" → rejected as scope creep;
  filed `tickets/backlog/RETRY-002-per-subscription-policy.md`

## Implementation Phase

2026-06-02T09:14Z  TASK-1  [~]  — claimed (claude+mike)
2026-06-02T11:40Z  TASK-1  done — retry loop + RetryPolicy landed;
  verify: `pytest tests/dispatch/test_retry.py -q` → 7 passed;
  verify: UJ-041 8/8 GREEN; UJ-042 6/6 GREEN (no regression)
2026-06-02T11:55Z  TASK-1  approved by mike — "ship it; keep the jitter cap"
2026-06-02T12:01Z  TASK-2  [~]  — claimed (claude+mike)

## Verification Phase

(pending Task 2 — exit criteria in IMPLEMENTATION_PLAN.md; close per protocol-spec §9)
