# Phase 2 — Spec Check

> Each rule from `docs/fee-schedule.md` is checked against the production code at the time of audit.
> **Status at audit** records the finding as observed. **Status now** records changes made in Phase 4.
> Status values: **Enforced** · **Violated** · **Missing**

---

## Rule table

| # | Rule (verbatim) | What the code does | Status at audit | Status now | Evidence |
|---|---|---|---|---|---|
| 1 | "All money is stored and calculated in whole cents (1 dollar = 100 cents). No fractional cents." | Every value was a plain JS `number` (IEEE-754 float). No cent conversion existed anywhere. `ledger.post()` stored raw floats. `balance()` accumulated without rounding. | **Violated** | **Partial** — P1 fix: `ledger.js` now stores whole cents; `invoice.js` computes in integer cents. `payments.js` fee computation is still a raw float. | `src/ledger.js:6-8`, `src/invoice.js:3`, `src/payments.js:12` |
| 2 | "Sales tax is 7.5 percent, calculated once on the invoice subtotal and rounded once to the nearest cent. The amount charged must equal the amount shown on the customer receipt." | `receiptTotal` rounded once on the subtotal. But `chargeTotal` — the value actually charged — rounded **per line-item** then summed. The two paths produced different totals for multi-item orders. | **Violated** | **Enforced** — P2 fix: `chargeTotal` now calls the same `totalWithVat()` function as `receiptTotal`. One subtotal, one rounding, in whole cents. | `src/invoice.js:9-11` (`receiptTotal`), `src/invoice.js:13-15` (`chargeTotal`), `src/payments.js:11` |
| 3 | "The platform fee is 1.5 percent of the charged amount, capped at 20 dollars per transaction." | Fee is computed as `amount * FEE_RATE`. There is no `Math.min(fee, 20)` guard; any order above ~$1,333.33 produces a fee exceeding $20. | **Violated** | **Violated** — not yet fixed. | `src/payments.js:12`, `src/payments.js:25`, `src/config.js:2` |
| 4 | "The platform fee is taken exactly once, at settlement." | `charge()` posts `clearing → platform_fees` for the fee (posting ②). `settle()` independently recomputes and posts another `clearing → platform_fees` for the fee (posting ③). The fee is taken **twice**: once at charge time and again at settlement. `p.fee` (saved at charge) is never used in `settle()`. | **Violated** | **Violated** — not yet fixed. | `src/payments.js:15` (charge-time fee posting), `src/payments.js:26` (settlement fee posting) |
| 5 | "A charge retried with the same idempotency key must not create a second charge." | `charge()` calls `this.payments.set(paymentId, …)` and posts to the ledger without first checking whether `idempotencyKey` has been seen before. A retry with the same key creates a fresh ledger entry. | **Missing** | **Missing** — not yet fixed. | `src/payments.js:10-18` |
| 6 | "Total refunds on a payment may never exceed the amount charged." | `refund()` increments `p.refunded += amount` and posts the ledger entry with no guard checking that `p.refunded + amount ≤ p.amount`. A caller can issue unlimited refunds. | **Missing** | **Missing** — not yet fixed. | `src/payments.js:31-37` |
| 7 | "After settlement, the clearing account balance for a payment must be zero." | After `charge()` + `settle()`, clearing has received `amount` (posting ①) and paid out `fee_charge + fee_settle + (amount − fee_settle)`. Net = `amount − fee_charge − fee_settle − amount + fee_settle = −fee_charge`. Clearing ends negative by the charge-time fee (see Rule 4). | **Violated** | **Violated** — not yet fixed. | `src/payments.js:14-15` (charge postings), `src/payments.js:26-27` (settle postings) |

---

## Summary at audit

| Status at audit | Count | Rules |
|--------|-------|-------|
| Enforced | 0 | — |
| Violated | 5 | 1, 2, 3, 4, 7 |
| Missing | 2 | 5, 6 |

No rule was fully enforced at audit. Every rule had either a code violation or no enforcement at all.

## Summary now (after P1 and P2)

| Status now | Count | Rules |
|--------|-------|-------|
| Enforced | 1 | 2 |
| Partial | 1 | 1 |
| Violated | 3 | 3, 4, 7 |
| Missing | 2 | 5, 6 |

---

## Rule dependency note

Rule 7 (clearing must net to zero after settlement) is a **consequence** of Rule 4 (fee taken once at settlement). Fixing Rule 4 will also fix Rule 7, assuming the charge-time fee posting (posting ②) is removed and the settlement fee posting (posting ③) is kept as the single fee debit.

---

*Phase 2 complete. Awaiting instruction to proceed to Phase 3 (prove and fix).*
