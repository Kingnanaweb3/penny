# Phase 4 — Fix Log

| Finding | Test file | Failed with | Change made | Passes now |
|---------|-----------|-------------|-------------|------------|
| P1 — Float money | `tests/penny/p1-float-money.test.js` | (1) `Entry "processing fee" amountKobo=undefined — not a whole-kobo integer`; (2) `ledger.balanceKobo is not a function` | `src/ledger.js` — `post()` now converts naira to integer kobo via `Math.round(amount * 100)` and stores `amountKobo`; `balance()` sums `amountKobo` and divides by 100 on return; new `balanceKobo()` returns the integer sum directly. No change to `payments.js` or `invoice.js`. | yes |
| P2 — Rounding drift | `tests/penny/p2-rounding-drift.test.js` | `chargeTotal (₦322.52) must equal receiptTotal (₦322.51); drift = ₦0.01` — `322.52 !== 322.51` | `src/invoice.js` — removed per-line `round2()` in `chargeTotal`. Introduced `totalWithVat(items)`: converts subtotal to integer kobo (`Math.round(subtotal * 100)`), applies VAT in kobo (`Math.round(subtotalKobo * 1.075)`), returns kobo ÷ 100. Both `receiptTotal` and `chargeTotal` now delegate to this single function — one subtotal, one rounding, VAT calculated in whole kobo. | yes |

## Notes on existing tests

No existing test in `tests/payments.test.js` was changed. The test `"fee is 1.5 percent of the charge"` asserts `r.fee === r.amount * 0.015`. This still holds because `PaymentService.charge()` still computes and returns the fee in naira as `amount * FEE_RATE`; only the ledger's internal storage changed. That test is asserting buggy fee behavior (P4 will fix it later) — it is left intact per the audit rules and will be updated when P4 is fixed.
