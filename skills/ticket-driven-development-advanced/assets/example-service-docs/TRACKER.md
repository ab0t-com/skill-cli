# Ticket Tracker — Notifier Service

Master list of tickets, their status, and what to work on next.
Check this file at the start of every session.

**Last updated:** 2026-06-02

---

## Active Tickets

### 1. Webhook Delivery Retries + DLQ (`20260601_webhook_delivery_retries/`)
**Status:** IN PROGRESS — Task 1 done (UJ-041 8/8 GREEN), Task 2 claimed.
**Priority:** HIGH
**What's left:**
- Task 2: DLQ module + replay CLI
- UJ-043 (flapping endpoint, ordering) — planned

## Strategic / Discussion

### Exactly-Once Delivery Investigation (`20260528_exactly_once_investigation/`) — DISCUSSION
Lettered options written up; recommendation pending operator answer on consumer
dedup guarantees.

## Completed Tickets

### Subscription Signature Rotation (`20260514_subscription_signature_rotation/`) — COMPLETE
Dual-key window + rotation endpoint.
- UJ-038: 12/12 GREEN · UJ-039: 9/9 GREEN

## Unimplemented Features

| # | Ticket | Priority | Dir/File | Status |
|---|---|---|---|---|
| 4 | Per-subscription retry policy | P2 | `backlog/RETRY-002-per-subscription-policy.md` | Backlog (deferred) — spawned from 20260601 retries ticket |
| 5 | DLQ browsing UI | P3 | not yet cut | needs frontend scoping |

## UJ Test Suite

| UJ | Name | Status |
|---|---|---|
| UJ-038 | signature rotation dual-key window | GREEN (12/12) |
| UJ-041 | retry then DLQ on persistent 5xx | GREEN (8/8) |
| UJ-042 | happy-path delivery unchanged | GREEN (6/6) |
| UJ-043 | flapping endpoint ordering | NOT RUN (planned) |
