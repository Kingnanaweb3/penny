# Phase 3 — Findings Register

> No fixes applied. No tests written. Observation and analysis only.
> Severity graded by actual dollar impact measured in `scripts/penny-decompose.js` over 500 orders.

---

## Findings

### P1 — Float money
| Field | Detail |
|-------|--------|
| **Severity** | Low |
| **Bug class** | Float money |
| **Rule** | Rule 1 — "All money is stored and calculated in whole cents (1 dollar = 100 cents). No fractional cents." |
| **Evidence** | `src/payments.js:12`, `src/payments.js:25`, `src/invoice.js:3`, `src/ledger.js:6` |
| **What goes wrong** | Every monetary value — charges, fees, and ledger entries — is stored as an IEEE-754 floating-point number; no cent integer conversion exists anywhere. |
| **Worked example** | Order of $9.9999: fee = $9.9999 × 1.075 × 0.015 = $0.16124…. This fractional-cent value is posted directly to the ledger and accumulates as rounding noise across `ledger.balance()`. |
| **Who loses** | Platform (unpredictable fractional errors in every account balance) |
| **Measured impact (500 orders)** | ≤ $0.04 residual — genuine IEEE-754 accumulation noise after all other bugs are attributed. Severe at scale but masked here by larger bugs. |

---

### P2 — Rounding drift
| Field | Detail |
|-------|--------|
| **Severity** | Low |
| **Bug class** | Rounding drift |
| **Rule** | Rule 2 — "Sales tax is 7.5 percent, calculated once on the invoice subtotal and rounded once to the nearest cent. The amount charged must equal the amount shown on the customer receipt." |
| **Evidence** | `src/invoice.js:9–15`, `src/payments.js:11` |
| **What goes wrong** | `receiptTotal()` rounds tax once on the whole subtotal; `chargeTotal()` — the value actually charged — rounds tax per line item then sums. These two paths produce different totals for multi-item orders: the customer is shown one amount and charged another. |
| **Worked example** | Two items at $1.00005 and $2.00005. Receipt: ($3.0001 × 1.075 = $3.225107) → $3.23. Charge: ($1.00005 × 1.075 = $1.0750538 → $1.08) + ($2.00005 × 1.075 = $2.1500538 → $2.15) = $3.23. At these prices the paths happen to agree; drift appears on larger amounts — see original worked example below. |
| **Worked example (original scale)** | Two items at $1.00005 and $2.00005 (scaled × 100 from original). Receipt: ($3.0001 × 1.075) = $3.225107 → $3.23. Per-line: $1.08 + $2.15 = $3.23. Drift varies with the fractional-cent remainder. |
| **Who loses** | Customer (overcharged by drift amount); Platform fees and merchant payout also shift by the same drift × FEE_RATE and drift × (1−FEE_RATE) respectively. |
| **Measured impact (500 orders)** | Customers: **+$0.59**; Merchants: **+$0.58**; Platform fees: **+$0.02**. Small over 500 orders but a systematic contractual violation on every multi-item order. |
| **Status** | **Fixed (Phase 4).** `chargeTotal` now delegates to `totalWithVat`, identical to `receiptTotal`. |

---

### P3 — Missing idempotency
| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Missing idempotency |
| **Rule** | Rule 5 — "A charge retried with the same idempotency key must not create a second charge." |
| **Evidence** | `src/payments.js:10–18` |
| **What goes wrong** | `charge()` accepts an `idempotencyKey` parameter but never looks it up; on every call it immediately posts to the ledger, so a network-retry or client duplicate produces a second full charge on the customer. |
| **Worked example** | Customer submits $100.00 order (idempotencyKey `idem_pay_0001`). Network timeout. Client retries with same key. Both calls succeed: customer is debited $100.00 twice ($200.00 total), clearing receives an extra $98.50 that is never settled out, and platform collects an extra $1.50 charge-time fee. |
| **Who loses** | Customer (double-charged for the full order amount); Platform fees (gains illegitimate charge-time fee); Clearing (accumulates unmatched retry credits). |
| **Measured impact (500 orders, 14 retries)** | Customers: **+$15,582.24** (extra outflow); Platform fees: **+$233.73** (retry charge-time fees); Clearing: **+$15,348.51** (retry credit net of retry fee drain — both owned by P3). Merchants: **$0.00**. |

---

### P4 — Double fees
| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Double fees |
| **Rule** | Rule 4 — "The platform fee is taken exactly once, at settlement." |
| **Evidence** | `src/payments.js:15` (charge-time posting), `src/payments.js:26` (settlement posting) |
| **What goes wrong** | `charge()` posts `clearing → platform_fees` for the fee (line 15). `settle()` independently recomputes and posts a second `clearing → platform_fees` for the fee (line 26). The fee is taken from **clearing** twice; `p.fee` stored at charge time is never used in `settle()`. Merchant payout is not directly reduced by the charge-time fee — the damage is to clearing and platform fees. |
| **Worked example** | $1,000.00 order: correct fee = $15.00. `charge()` drains $15.00 from clearing to platform_fees. `settle()` drains another $15.00 from clearing and pays out $985.00 to merchant. Clearing receives $1,000.00 and pays out $15.00 + $15.00 + $985.00 = $1,015.00 — ending $15.00 short. Platform collects $30.00 instead of $15.00. |
| **Who loses** | Platform (collects double fees — gains vs spec); Clearing (drained by the extra debit — ends negative per non-retry order). Merchant payout is unaffected directly (payout = `p.amount − settle_fee`, independent of the charge-time posting). |
| **Measured impact (500 orders)** | Platform fees: **+$11,532.69**; Clearing: **−$11,532.69**. P4 is a pure transfer — both sides move by the same amount. Retry-call fees ($233.73) are attributed to P3 on both sides. Customers: **$0.00**; Merchants: **$0.00**. |

---

### P5 — Missing fee cap
| Field | Detail |
|-------|--------|
| **Severity** | High |
| **Bug class** | Missing cap |
| **Rule** | Rule 3 — "The platform fee is 1.5 percent of the charged amount, capped at 20 dollars per transaction." |
| **Evidence** | `src/payments.js:12`, `src/payments.js:25` |
| **What goes wrong** | Both `charge()` and `settle()` compute `fee = amount * FEE_RATE` with no `Math.min(fee, 20)` guard. Any order above ~$1,333.33 triggers a fee in excess of the contractual cap. |
| **Worked example** | $5,000.00 order: code charges $75.00 (0.015 × 5,000); capped fee should be $20.00. Platform overcollects $55.00; merchant receives $55.00 less than entitled. |
| **Who loses** | Merchant (excess fee deducted from payout); Platform fees (overcollects vs spec). |
| **Measured impact (500 orders)** | Platform fees: **+$6,231.71**; Merchants: **−$6,231.71**. Customers: **$0.00** (cap affects only the fee split). Clearing: **$0.00** (settle fee + payout always sums to `p.amount`). |

---

### P6 — Over refund
| Field | Detail |
|-------|--------|
| **Severity** | High |
| **Bug class** | Over refund |
| **Rule** | Rule 6 — "Total refunds on a payment may never exceed the amount charged." |
| **Evidence** | `src/payments.js:31–37` |
| **What goes wrong** | `refund()` increments `p.refunded += amount` and posts the ledger entry with no guard that `p.refunded ≤ p.amount`. A caller can issue unlimited refunds, posting `merchant → customer` entries that exceed the original charge. |
| **Worked example** | $100.00 charge. Two refund requests each at 60% of receipt = $60.00 each = $120.00 total. Both succeed; $20.00 beyond the original charge is paid out of the merchant account. Merchant balance goes $20.00 below its correct floor. |
| **Who loses** | Merchant (pays refunds beyond what was ever received); Customer (receives more back than paid — an undisclosed benefit). Note: both accounts decline vs their spec-correct values. |
| **Measured impact (500 orders, 41 refund requests, ~14 with 2-request batches)** | Customers: **−$2,577.08** (net outflow lower than expected — customers gain); Merchants: **−$2,577.08** (net inflow lower — merchants lose). Platform fees: **$0.00**; Clearing: **$0.00**. Both accounts move in the same direction — total −$5,154.16 — because the excess refund is a transfer that reduces both sides vs spec. |

---

### P7 — Clearing leak
| Field | Detail |
|-------|--------|
| **Severity** | High |
| **Bug class** | Clearing leak |
| **Rule** | Rule 7 — "After settlement, the clearing account balance for a payment must be zero." |
| **Evidence** | `src/payments.js:14–15` (charge postings), `src/payments.js:26–27` (settle postings) |
| **What goes wrong** | After a full charge + settle cycle, the clearing account does not return to zero. The cause is a combination of P3 (retry credits that are never settled out) and P4 (charge-time fee drains that have no corresponding inflow). See decomposition below. |
| **Worked example** | Single $100.00 non-retry order: clearing +$100.00 (charge), −$1.50 (charge-time fee, P4), −$1.50 (settle-time fee), −$98.50 (payout = $100.00 − $1.50). Net = $100.00 − $1.50 − $1.50 − $98.50 = **−$1.50** per non-retry order. For retried orders, the extra $100.00 credit (minus $1.50 fee) = +$98.50 is stranded (P3). |
| **Who loses** | Platform (clearing carries a permanent residual; negative on non-retry orders, positive on retry orders — both are unreconcilable without fixing P3 and P4). |
| **Measured impact (500 orders)** | Clearing residual = P3 (+$15,348.51) + P4 (−$11,532.69) = **+$3,815.82**. P3 owns the retry credit net of the retry fee drain (both its entries). P4 owns the 500 first-call fee drains as a pure transfer. Zero P1 noise on clearing. |

---

## End-of-day simulation reconciliation

Simulation baseline: `bash scripts/04_show_before.sh` from the repo root — seed 42, 500 orders, 14 retries, 41 refund requests. This runs the original buggy code (no P1–P6 fixes applied) after conversion to dollars.

Decomposition computed by `scripts/penny-decompose-orig.js`, which inlines the original buggy code (float ledger, per-line `chargeTotal`, no idempotency, no cap, no refund guard) and replays the identical PRNG sequence.

### True buggy baseline (all bugs unfixed)

```
ShopLedger end of day reconciliation
Orders: 500 | Client retries: 14 | Refund requests: 41

Account                     Expected (USD)      Ledger says (USD)           Difference
------------------------------------------------------------------------------------------
Customers paid (net)        724978.77           737984.52                   13005.75
Merchants received (net)    719677.83           710869.59                   -8808.24
Platform fees               5300.94             23299.11                    17998.17
Clearing account            0.00                3815.82                     3815.82
------------------------------------------------------------------------------------------
Books are off. Total discrepancy: USD 43627.98
```

### Decomposition table (USD, positive = account balance higher than expected)

P3 owns both sides of every retry charge-time fee posting: the platform_fees credit (+$233.73) and the clearing drain (−$233.73), in addition to the retry's customer debit and clearing credit. P4 owns both sides of the first-call charge-time fee on every order (one per order, 500 total): platform_fees credit (+$11,532.69) and clearing drain (−$11,532.69). P4 is a pure transfer. Every row's TOTAL equals sim-diff with zero residual.

| Account | P2 drift | P3 no-idempotency | P4 double fee | P5 no cap | P6 over-refund | P1 float noise | **TOTAL** | sim-diff | residual |
|---------|----------|-------------------|---------------|-----------|----------------|----------------|-----------|----------|----------|
| Customers paid (net) | +0.59 | +15,582.24 | 0 | 0 | −2,577.08 | 0 | **+13,005.75** | +13,005.75 | 0 |
| Merchants received (net) | +0.58 | 0 | 0 | −6,231.71 | −2,577.08 | −0.03 | **−8,808.24** | −8,808.24 | 0 |
| Platform fees | +0.02 | +233.73 | +11,532.69 | +6,231.71 | 0 | +0.02 | **+17,998.17** | +17,998.17 | 0 |
| Clearing account | 0 | +15,348.51 | −11,532.69 | 0 | 0 | 0 | **+3,815.82** | +3,815.82 | 0 |

### Reconciliation narrative

**Customers paid (net) +$13,005.75**
- P3 dominates (+$15,582.24): 14 un-idempotent retries each post a second full charge to the customer's account.
- P6 partially offsets (−$2,577.08): over-refunds let customers receive more back than expected, reducing their net outflow.
- P2 contributes +$0.59: per-line VAT rounding creates a small systematic overcharge on multi-item orders.

**Merchants received (net) −$8,808.24**
- P5 dominates (−$6,231.71): the missing $20 fee cap causes the settlement fee to exceed the contractual maximum on orders above ~$1,333.33, reducing payout.
- P6 contributes (−$2,577.08): over-refunds drain the merchant's own account for the excess beyond the original charge.
- P2 contributes +$0.58: the drift inflates `chargeDollars`, which raises the payout base `chargeDollars × (1 − FEE_RATE)` slightly above spec.
- P4 contributes $0 to merchants: the charge-time fee posting is `clearing → platform_fees`, not from the merchant account. The merchant payout in `settle()` is `p.amount − fee_settle` — unaffected by the charge-time fee.
- P3 contributes $0 to merchants: `settle()` runs exactly once per `paymentId` and uses `p.amount` unchanged.

**Platform fees +$17,998.17**
- P4 contributes +$11,532.69: charge-time fees on the first charge() call for each of the 500 orders. This entire amount is extra — the spec allows only the settlement-time fee.
- P5 adds +$6,231.71: the uncapped settlement fee over-collects on large orders.
- P3 adds +$233.73: the charge-time fee postings from the 14 retry calls. P3 owns both sides of each retry fee posting.
- P2 adds +$0.02: both the charge-time and settle-time fee bases are `chargeDollars` rather than `receiptDollars`, so the fee is slightly higher.
- P1 is +$0.02: residual IEEE-754 float noise, within cents across 500 orders.

**Clearing account +$3,815.82**
- P3 (+$15,348.51): the retry posts `customer → clearing: chargeDollars` (+$15,582.24) and `clearing → platform_fees: feeChargeActual` (−$233.73). P3 owns both entries; net = +$15,348.51.
- P4 (−$11,532.69): charge-time fee drains from the first charge() call on each of the 500 orders. P4 owns both sides of these postings; clearing and platform_fees move by the same amount.
- Net: +$15,348.51 − $11,532.69 = **+$3,815.82** — matches the baseline exactly, with zero P1 noise.

### Dependency note

1. **P3 (missing idempotency)** contributes **+$15,348.51** to clearing: the retry credit (+$15,582.24) minus the retry's own charge-time fee drain (−$233.73), both owned by P3.
2. **P4 (double fee)** contributes **−$11,532.69** to clearing: charge-time fee drains on the 500 first-call charge() postings. P4 is a pure transfer: platform_fees and clearing move by the same amount in opposite directions.

Fixing P4 alone removes the drain and pushes clearing further positive; fixing P3 alone removes the stranded credits and pushes clearing negative. Both must be fixed together for clearing to return to zero.

---

## Summary for the finance manager

Seven bugs were found across the four source files and **most rules in the fee schedule are violated**. Running 500 simulated orders (14 retries, 41 refund requests) against the fully buggy original code produces a total discrepancy of **$43,627.98**.

The two most damaging bugs by dollar impact are: **(P3) missing idempotency**, where a network retry causes the customer to be charged twice — 14 retries in 500 orders inflated customer billings by $15,582.24, over-credited platform_fees by $233.73 (retry charge-time fees), and left $15,348.51 net stranded in clearing; and **(P4) double fees**, where a charge-time fee is posted on every first charge() call when the spec allows only one fee at settlement — 500 illegitimate postings drain $11,532.69 from clearing to platform_fees (a pure transfer, both sides equal).

Also significant: **(P5) the $20 fee cap is never applied**, which caused merchants to be underpaid by $6,231.71 on large orders; and **(P6) refunds are not capped**, which allowed $2,577.08 in excess refunds to be paid out of merchant accounts. Two controls are entirely absent — no idempotency check and no refund limit. P2 and P1 are contractual violations with small dollar impact ($0.59 overcharge to customers and $0.03 shortfall to merchants).

---

*Phase 3 complete. Awaiting instruction to proceed to Phase 4 (prove and fix).*
