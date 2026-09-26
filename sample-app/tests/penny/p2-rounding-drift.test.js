/**
 * P2 — Rounding drift
 * Rule 2: VAT is calculated once on the invoice subtotal and rounded once.
 * The amount charged must equal the amount shown on the customer receipt.
 *
 * This test uses two items whose individual per-line VAT rounding differs
 * from a single rounding on the combined subtotal, exposing the drift.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { receiptTotal, chargeTotal } from '../../src/invoice.js';

// Two items chosen so that per-line rounding drifts from the whole-subtotal rounding.
// unitPrice 100.005 does not exist in practice, but we use integer-friendly figures:
// Item A: unitPrice=666.67, qty=1  -> line total 666.67, VAT-inc = 666.67 * 1.075 = 716.67025 -> round2 = 716.67
// Item B: unitPrice=333.34, qty=1  -> line total 333.34, VAT-inc = 333.34 * 1.075 = 358.3405  -> round2 = 358.34
// chargeTotal (per-line) = 716.67 + 358.34 = 1075.01
//
// subtotal = 666.67 + 333.34 = 1000.01
// receiptTotal = round2(1000.01 * 1.075) = round2(1075.01075) = 1075.01
//
// These happen to match. Try a triple-item case where drift is larger:
// Item A: unitPrice=33.34, qty=1  -> VAT-inc = 33.34 * 1.075 = 35.8405  -> round2 = 35.84
// Item B: unitPrice=33.33, qty=1  -> VAT-inc = 33.33 * 1.075 = 35.82975 -> round2 = 35.83
// Item C: unitPrice=33.33, qty=1  -> VAT-inc = 33.33 * 1.075 = 35.82975 -> round2 = 35.83
// chargeTotal (per-line) = 35.84 + 35.83 + 35.83 = 107.50
//
// subtotal = 33.34 + 33.33 + 33.33 = 100.00
// receiptTotal = round2(100.00 * 1.075) = 107.50  — also matches.
//
// Use the worked example from the findings register directly:
// Item A: unitPrice=100.005, qty=1  -> VAT-inc = 107.505375 -> round2 = 107.51
// Item B: unitPrice=200.005, qty=1  -> VAT-inc = 215.005375 -> round2 = 215.01
// chargeTotal = 107.51 + 215.01 = 322.52
//
// subtotal = 300.01
// receiptTotal = round2(300.01 * 1.075) = round2(322.5107...) = 322.51
//
// Drift = 322.52 - 322.51 = 0.01 overcharge.

const items = [
  { unitPrice: 100.005, qty: 1 },
  { unitPrice: 200.005, qty: 1 },
];

test('P2: chargeTotal equals receiptTotal (Rule 2 — no rounding drift)', () => {
  const receipt = receiptTotal(items);
  const charge  = chargeTotal(items);
  assert.equal(
    charge,
    receipt,
    `chargeTotal (₦${charge.toFixed(2)}) must equal receiptTotal (₦${receipt.toFixed(2)}); drift = ₦${(charge - receipt).toFixed(2)}`
  );
});
