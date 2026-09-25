# Phase 2 — Spec Check

> Each rule from `docs/fee-schedule.md` is checked against the production code.  
> Status: **Enforced** · **Violated** · **Missing**

---

## Rule table

| # | Rule (verbatim) | What the code does | Status | Evidence |
|---|---|---|---|---|
| 1 | "All money is stored and calculated in whole kobo (1 naira = 100 kobo). No fractional kobo." | Every value is a plain JS `number` (IEEE-754 float). No kobo conversion exists anywhere. `ledger.post()` stores raw floats. `balance()` accumulates without rounding. | **Violated** | `src/ledger.js:6-8`, `src/invoice.js:3`, `src/payments.js:12` |
| 2 | "VAT is 7.5 percent, calculated once on the invoice subtotal and rounded once to the nearest kobo. The amount charged must equal the amount shown on the customer receipt." | `receiptTotal` rounds once on the subtotal (`round2(subtotal × 1.075)`). But `chargeTotal` — the value actually charged — rounds **per line-item** then sums (`Σ round2(item × 1.075)`). The two paths produce different totals for multi-item orders: the customer sees `receiptTotal`; the charge is `chargeTotal`. | **Violated** | `src/invoice.js:9-11` (`receiptTotal`), `src/invoice.js:13-15` (`chargeTotal`), `src/payments.js:11` |
| 3 | "The platform fee is 1.5 percent of the charged amount, capped at 2,000 naira per transaction." | Fee is computed as `amount * FEE_RATE` (`amount * 0.015`). There is no cap check; amounts above ~133,333 naira will produce fees exceeding 2,000 naira. | **Violated** | `src/payments.js:12`, `src/payments.js:25`, `src/config.js:2` |
| 4 | "The platform fee is taken exactly once, at settlement." | `charge()` posts `clearing → platform_fees` for the fee (posting ②). `settle()` independently recomputes and posts another `clearing → platform_fees` for the fee (posting ③). The fee is taken **twice**: once at charge time and again at settlement. `p.fee` (saved at charge) is never used in `settle()`. | **Violated** | `src/payments.js:15` (charge-time fee posting), `src/payments.js:26` (settlement fee posting) |
| 5 | "A charge retried with the same idempotency key must not create a second charge." | `charge()` calls `this.payments.set(paymentId, …)` and posts to the ledger without first checking whether `idempotencyKey` has been seen before. A retry with the same key (or a different `paymentId` but the same `idempotencyKey`) creates a fresh ledger entry. | **Missing** | `src/payments.js:10-18` |
| 6 | "Total refunds on a payment may never exceed the amount charged." | `refund()` increments `p.refunded += amount` and posts the ledger entry with no guard checking that `p.refunded + amount ≤ p.amount`. A caller can issue unlimited refunds. | **Missing** | `src/payments.js:31-37` |
| 7 | "After settlement, the clearing account balance for a payment must be zero." | After `charge()` + `settle()`, clearing has received `amount` (posting ①) and paid out `fee_charge + fee_settle + (amount − fee_settle)`. Net = `amount − fee_charge − fee_settle − amount + fee_settle = −fee_charge`. Clearing ends negative by the charge-time fee (see Rule 4 — the fee is taken twice, and the first debit leaves clearing short). | **Violated** | `src/payments.js:14-15` (charge postings), `src/payments.js:26-27` (settle postings) |

---

## Summary

| Status | Count | Rules |
|--------|-------|-------|
| Enforced | 0 | — |
| Violated | 5 | 1, 2, 3, 4, 7 |
| Missing | 2 | 5, 6 |

No rule is fully enforced. Every rule has either a code violation or no enforcement at all.

---

## Rule dependency note

Rule 7 (clearing must net to zero after settlement) is a **consequence** of Rule 4 (fee taken once at settlement). Fixing Rule 4 will also fix Rule 7, assuming the charge-time fee posting (posting ②) is removed and the settlement fee posting (posting ③) is kept as the single fee debit.

---

*Phase 2 complete. Awaiting instruction to proceed to Phase 3 (prove and fix).*
