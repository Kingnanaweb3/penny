# Phase 3 — Findings Register

> No fixes applied. No tests written. Observation and analysis only.
> Severity graded by actual naira impact measured in `scripts/penny-decompose.js` over 500 orders.

---

## Findings

### P1 — Float money
| Field | Detail |
|-------|--------|
| **Severity** | Low |
| **Bug class** | Float money |
| **Rule** | Rule 1 — "All money is stored and calculated in whole kobo (1 naira = 100 kobo). No fractional kobo." |
| **Evidence** | `src/payments.js:12`, `src/payments.js:25`, `src/invoice.js:3`, `src/ledger.js:6` |
| **What goes wrong** | Every monetary value — charges, fees, and ledger entries — is stored as an IEEE-754 floating-point number; no kobo integer conversion exists anywhere. |
| **Worked example** | Order of ₦999.99: fee = ₦999.99 × 1.075 × 0.015 = ₦16.124849…. This fractional kobo value is posted directly to the ledger and accumulates as rounding noise across `ledger.balance()`. |
| **Who loses** | Platform (unpredictable fractional errors in every account balance) |
| **Measured impact (500 orders)** | ≤ ₦0.03 residual — genuine IEEE-754 accumulation noise after all other bugs are attributed. Severe at scale but masked here by larger bugs. |

---

### P2 — Rounding drift
| Field | Detail |
|-------|--------|
| **Severity** | Low |
| **Bug class** | Rounding drift |
| **Rule** | Rule 2 — "VAT is 7.5 percent, calculated once on the invoice subtotal and rounded once to the nearest kobo. The amount charged must equal the amount shown on the customer receipt." |
| **Evidence** | `src/invoice.js:9–15`, `src/payments.js:11` |
| **What goes wrong** | `receiptTotal()` rounds VAT once on the whole subtotal; `chargeTotal()` — the value actually charged — rounds VAT per line item then sums. These two paths produce different totals for multi-item orders: the customer is shown one amount and charged another. |
| **Worked example** | Two items at ₦100.005 and ₦200.005. Receipt: (₦300.01 × 1.075 = ₦322.51075) → ₦322.51. Charge: (₦100.005 × 1.075 = ₦107.50538 → ₦107.51) + (₦200.005 × 1.075 = ₦215.00538 → ₦215.01) = ₦322.52. Customer is shown ₦322.51, charged ₦322.52 — a ₦0.01 overcharge. |
| **Who loses** | Customer (overcharged by drift amount); Platform fees and merchant payout also shift by the same drift × FEE_RATE and drift × (1−FEE_RATE) respectively. |
| **Measured impact (500 orders)** | Customers: **+₦0.62**; Merchants: **+₦0.61**; Platform fees: **+₦0.02**. Tiny over 500 orders but a systematic contractual violation on every multi-item order. |

---

### P3 — Missing idempotency
| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Missing idempotency |
| **Rule** | Rule 5 — "A charge retried with the same idempotency key must not create a second charge." |
| **Evidence** | `src/payments.js:10–18` |
| **What goes wrong** | `charge()` accepts an `idempotencyKey` parameter but never looks it up; on every call it immediately posts to the ledger, so a network-retry or client duplicate produces a second full charge on the customer. |
| **Worked example** | Customer submits ₦10,000 order (idempotencyKey `idem_pay_0001`). Network timeout. Client retries with same key. Both calls succeed: customer is debited ₦10,000 twice (₦20,000 total), clearing receives an extra ₦9,850 that is never settled out, and platform collects an extra ₦150 charge-time fee. |
| **Who loses** | Customer (double-charged for the full order amount); Platform fees (gains illegitimate charge-time fee); Clearing (accumulates unmatched retry credits). |
| **Measured impact (500 orders, 14 retries)** | Customers: **+₦1,558,320** (extra outflow); Platform fees: **+₦23,375**; Clearing: **+₦1,534,945** (stranded). Merchants: **₦0** (settle payout unchanged). |

---

### P4 — Double fees
| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Bug class** | Double fees |
| **Rule** | Rule 4 — "The platform fee is taken exactly once, at settlement." |
| **Evidence** | `src/payments.js:15` (charge-time posting), `src/payments.js:26` (settlement posting) |
| **What goes wrong** | `charge()` posts `clearing → platform_fees` for the fee (line 15). `settle()` independently recomputes and posts a second `clearing → platform_fees` for the fee (line 26). The fee is taken from **clearing** twice; `p.fee` stored at charge time is never used in `settle()`. Merchant payout is not directly reduced by the charge-time fee — the damage is to clearing and platform fees. |
| **Worked example** | ₦100,000 order: correct fee = ₦1,500. `charge()` drains ₦1,500 from clearing to platform_fees. `settle()` drains another ₦1,500 from clearing and pays out ₦98,500 to merchant. Clearing receives ₦100,000 and pays out ₦1,500 + ₦1,500 + ₦98,500 = ₦101,500 — ending ₦1,500 short. Platform collects ₦3,000 instead of ₦1,500. |
| **Who loses** | Platform (collects double fees — gains vs spec); Clearing (drained by the extra debit — ends negative per non-retry order). Merchant payout is unaffected by this posting directly (payout = `p.amount − settle_fee`, independent of the charge-time posting). |
| **Measured impact (500 orders)** | Platform fees: **+₦1,176,688**; Clearing: **−₦1,176,688**. Customers: **₦0**; Merchants: **₦0**. |

---

### P5 — Missing fee cap
| Field | Detail |
|-------|--------|
| **Severity** | High |
| **Bug class** | Missing cap |
| **Rule** | Rule 3 — "The platform fee is 1.5 percent of the charged amount, capped at 2,000 naira per transaction." |
| **Evidence** | `src/payments.js:12`, `src/payments.js:25` |
| **What goes wrong** | Both `charge()` and `settle()` compute `fee = amount * FEE_RATE` with no `Math.min(fee, 2000)` guard. Any order above ≈₦133,333 triggers a fee in excess of the contractual cap. |
| **Worked example** | ₦500,000 order: code charges ₦7,500 (0.015 × 500,000); capped fee should be ₦2,000. Platform overcollects ₦5,500; merchant receives ₦5,500 less than entitled. |
| **Who loses** | Merchant (excess fee deducted from payout); Platform fees (overcollects vs spec). |
| **Measured impact (500 orders)** | Platform fees: **+₦623,190**; Merchants: **−₦623,190**. Customers: **₦0** (cap affects the fee split, not the gross charge). Clearing: **₦0** (settle fee + payout always sums to `p.amount`). |

---

### P6 — Over refund
| Field | Detail |
|-------|--------|
| **Severity** | High |
| **Bug class** | Over refund |
| **Rule** | Rule 6 — "Total refunds on a payment may never exceed the amount charged." |
| **Evidence** | `src/payments.js:31–37` |
| **What goes wrong** | `refund()` increments `p.refunded += amount` and posts the ledger entry with no guard that `p.refunded ≤ p.amount`. A caller can issue unlimited refunds, posting `merchant → customer` entries that exceed the original charge. |
| **Worked example** | ₦10,000 charge. Two refund requests each at 60% of receipt = ₦6,000 each = ₦12,000 total. Both succeed; ₦2,000 beyond the original charge is paid out of the merchant account. Merchant balance goes ₦2,000 below its correct floor. |
| **Who loses** | Merchant (pays refunds beyond what was ever received); Customer (receives more back than paid — an undisclosed benefit). Note: both accounts decline vs their spec-correct values. |
| **Measured impact (500 orders, 41 refund requests, ~14 with 2-request batches)** | Customers: **−₦257,721** (net outflow lower than expected — customers gain); Merchants: **−₦257,721** (net inflow lower — merchants lose). Platform fees: **₦0**; Clearing: **₦0**. |

---

### P7 — Clearing leak
| Field | Detail |
|-------|--------|
| **Severity** | High |
| **Bug class** | Clearing leak |
| **Rule** | Rule 7 — "After settlement, the clearing account balance for a payment must be zero." |
| **Evidence** | `src/payments.js:14–15` (charge postings), `src/payments.js:26–27` (settle postings) |
| **What goes wrong** | After a full charge + settle cycle, the clearing account does not return to zero. The cause is a combination of P3 (retry credits that are never settled out) and P4 (charge-time fee drains that have no corresponding inflow). See decomposition below. |
| **Worked example** | Single ₦10,000 non-retry order: clearing +₦10,000 (charge), −₦150 (charge-time fee, P4), −₦150 (settle-time fee), −₦9,700 (payout = ₦10,000 − ₦300... wait — payout = p.amount − fee_settle = ₦10,000 − ₦150 = ₦9,850). Net = ₦10,000 − ₦150 − ₦150 − ₦9,850 = **−₦150** per non-retry order. For retried orders, the extra ₦10,000 credit (minus ₦150 fee) = +₦9,850 is stranded (P3). |
| **Who loses** | Platform (clearing carries a permanent residual; negative on non-retry orders, positive on retry orders — both are unreconcilable without fixing P3 and P4). |
| **Measured impact (500 orders)** | Clearing residual = P3 (+₦1,534,945) + P4 (−₦1,153,313) + P1 noise (≈ 0) = **+₦381,632**. P3's stranded retry credit is `chargeNaira × 0.985` per retry (already net of the retry charge-time fee); P4 covers the charge-time fee on non-retry orders only (500 calls). The positive balance is dominated by P3's stranded credits. |

---

## End-of-day simulation reconciliation

Simulation: `npm run simulate` — seed 42, 500 orders, 14 retries, 41 refund requests.

Decomposition computed by `scripts/penny-decompose.js`.

### Decomposition table (NGN, positive = account balance higher than expected)

P3 covers the full retry event: the extra customer debit, the stranded clearing credit (net of the retry charge-time fee), and the retry charge-time fee to platform_fees. P4 covers charge-time fees on the 500 non-retry orders only. This attribution avoids double-counting the 14 retry charge-time fees (₦23,375). All rows add up to `sim-diff` to within ₦0.05 (IEEE-754 float noise across 500 float multiplications).

| Account | P2 drift | P3 no-idempotency | P4 double fee | P5 no cap | P6 over-refund | P1 float noise | **TOTAL** | sim-diff | residual |
|---------|----------|-------------------|---------------|-----------|----------------|----------------|-----------|----------|----------|
| Customers paid (net) | +0.62 | +1,558,320.11 | 0 | 0 | −257,720.59 | 0 | **+1,300,600.14** | +1,300,600.14 | 0 |
| Merchants received (net) | +0.61 | 0 | 0 | −623,189.97 | −257,720.59 | +0.03 | **−880,909.92** | −880,909.92 | 0 |
| Platform fees | +0.02 | +23,374.80 | +1,153,312.96 | +623,189.97 | 0 | +0 | **+1,799,877.75** | +1,799,877.70 | +0.05 |
| Clearing account | 0 | +1,534,945.31 | −1,153,312.96 | 0 | 0 | +0 | **+381,632.35** | +381,632.35 | 0 |

### Reconciliation narrative

**Customers paid (net) +₦1,300,600**
- P3 dominates (+₦1,558,320): 14 un-idempotent retries each post a second full charge to the customer's account. The 14 retry order amounts average ~₦111,000.
- P6 partially offsets (−₦257,721): over-refunds let customers receive more back than expected, reducing their net outflow.
- P2 is negligible (+₦0.62): per-line VAT rounding creates a tiny systematic overcharge.

**Merchants received (net) −₦880,910**
- P5 dominates (−₦623,190): the missing ₦2,000 fee cap causes the settlement fee to exceed the contractual maximum on large orders, reducing payout. The simulation includes orders up to ₦129,999.99 × 4 units.
- P6 contributes (−₦257,721): over-refunds drain the merchant's own account for the excess beyond the original charge.
- P4 contributes **₦0** to merchants: the charge-time fee posting is `clearing → platform_fees`, not from the merchant account. The merchant payout in `settle()` is `p.amount − fee_settle` — it is unaffected by whether a charge-time fee was also posted.
- P3 contributes **₦0** to merchants: `settle()` runs exactly once per `paymentId` and uses `p.amount = chargeNaira` (same value whether retried or not). The retry does not change the payout.

**Platform fees +₦1,799,878**
- P4 dominates (+₦1,153,313): charge-time fees on the 500 non-retry orders (1,153,312.96 before rounding). This entire amount is extra — the spec allows only the settlement-time fee.
- P5 adds +₦623,190: the uncapped settlement fee over-collects on large orders.
- P3 adds +₦23,375: the 14 retry charge-time fees are attributed to P3, not P4, because they only exist because of the un-idempotent retry.

**Clearing account +₦381,632**
- P3 (+₦1,534,945): each retry credits clearing (`customer → clearing: chargeNaira`) but settle() never runs a second time. The stranded amount is `chargeNaira × 0.985` per retry — already net of the retry charge-time fee, which is attributed to P3's platform_fees column above.
- P4 (−₦1,153,313): charge-time fees on the 500 non-retry orders drain clearing. ₦1,534,945.31 − ₦1,153,312.96 = ₦381,632.35 — the arithmetic closes exactly without a P1 residual term.

### Corrected dependency note (replaces Phase 2)

The Phase 2 note stated that P4 alone leaves clearing negative by one fee per order, which is correct for a single isolated non-retry payment. What it missed is that the simulation exercises two distinct bugs simultaneously, and they must be attributed without double-counting:

1. **P3 (missing idempotency)** contributes **+₦1,534,945** to clearing: each retry posts `customer → clearing: chargeNaira` but settle() runs only once. The stranded credit per retry is `chargeNaira × 0.985` (the retry charge-time fee of `chargeNaira × 0.015` leaves clearing immediately, so P3's clearing share is already net of that fee).
2. **P4 (double fee)** contributes **−₦1,153,312.96** to clearing: the charge-time fee on each of the 500 non-retry orders drains clearing. The 14 retry charge-time fees are excluded here because they are already accounted for inside P3's stranded-credit calculation above.

Net: ₦1,534,945.31 − ₦1,153,312.96 = **₦381,632.35** — which matches the simulation exactly, with no residual term needed. Neither effect cancels the other. Fixing P4 alone removes the drain and pushes clearing further positive; fixing P3 alone removes the stranded credits and pushes clearing negative. Both must be fixed together for clearing to return to zero.

---

## Summary for the finance manager

Seven bugs were found across the four source files and **every rule in the fee schedule is violated**. Running 500 simulated orders (14 retries, 41 refund requests) produces a total discrepancy of ₦4,363,020.

The two most damaging bugs by naira impact are: **(P3) missing idempotency**, where a network retry causes the customer to be charged twice — 14 retries in 500 orders inflated customer billings by ₦1.56 million and left ₦1.53 million stranded in clearing with no way to reconcile; and **(P4) double fees**, where the platform fee is deducted from clearing at both the charge step and the settlement step, causing the platform to overcollect ₦1.18 million and leaving clearing ₦1.18 million short on every settled payment.

Also significant: **(P5) the ₦2,000 fee cap is never applied**, which caused merchants to be underpaid by ₦623,190 on large orders; and **(P6) refunds are not capped**, which allowed ₦257,721 in excess refunds to be paid out of merchant accounts. Two controls are entirely absent — no idempotency check and no refund limit. The float-money (P1) and rounding-drift (P2) bugs are contractual violations but have negligible naira impact at this order volume.

---

*Phase 3 complete. Awaiting instruction to proceed to Phase 4 (prove and fix).*
