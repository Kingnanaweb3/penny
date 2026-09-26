/**
 * P5 — Missing fee cap
 * Rule 3: "The platform fee is 1.5 percent of the charged amount,
 * capped at 20 dollars per transaction."
 *
 * Two cases:
 *   A) Large order: uncapped fee > $20 → platform receives exactly $20,
 *      merchant receives amount − $20.
 *   B) Small order: uncapped fee < $20 → platform receives amount × 1.5%
 *      (cap has no effect).
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Ledger } from '../../src/ledger.js';
import { PaymentService } from '../../src/payments.js';

const FEE_CAP_CENTS = 2000;   // $20.00 in cents
const FEE_RATE      = 0.015;

// ── Case A: large order — fee must be capped ─────────────────────────────────
// unitPrice $5,000, qty 1 → subtotal $5,000 → taxed total = Math.round(500000 * 1.075) / 100 = $5,375.00
// Uncapped fee = $5,375 × 0.015 = $80.625 → $80.63 — well above the $20 cap.
const largeOrder = {
  paymentId:      'pay_p5_large',
  customer:       'customer_p5_large',
  merchant:       'merchant_p5_large',
  items:          [{ unitPrice: 5000, qty: 1 }],
  idempotencyKey: 'idem_p5_large',
};

test('P5: platform_fees receives exactly $20 cap on a large order (Rule 3)', () => {
  const ledger = new Ledger();
  const svc    = new PaymentService(ledger);
  const r = svc.charge(largeOrder);
  svc.settle(largeOrder.paymentId);

  assert.equal(
    ledger.balanceCents('platform_fees'),
    FEE_CAP_CENTS,
    `platform_fees holds ${ledger.balanceCents('platform_fees')} cents; expected ${FEE_CAP_CENTS} (cap)`
  );
});

test('P5: merchant receives amount minus capped fee on a large order', () => {
  const ledger = new Ledger();
  const svc    = new PaymentService(ledger);
  const r = svc.charge(largeOrder);
  svc.settle(largeOrder.paymentId);

  const amountCents   = Math.round(r.amount * 100);
  const expectedPayout = amountCents - FEE_CAP_CENTS;

  assert.equal(
    ledger.balanceCents(largeOrder.merchant),
    expectedPayout,
    `merchant holds ${ledger.balanceCents(largeOrder.merchant)} cents; expected ${expectedPayout}`
  );
});

test('P5: charge() returns the capped fee on a large order', () => {
  const ledger = new Ledger();
  const svc    = new PaymentService(ledger);
  const r = svc.charge(largeOrder);

  assert.equal(
    Math.round(r.fee * 100),
    FEE_CAP_CENTS,
    `charge() returned fee of ${r.fee}; expected ${FEE_CAP_CENTS / 100} (cap)`
  );
});

// ── Case B: small order — fee stays at 1.5%, cap not reached ─────────────────
// unitPrice $100, qty 1 → subtotal $100 → taxed total = Math.round(10000 * 1.075) / 100 = $107.50
// Uncapped fee = $107.50 × 0.015 = $1.6125 → 161 or 162 cents — well under $20.
const smallOrder = {
  paymentId:      'pay_p5_small',
  customer:       'customer_p5_small',
  merchant:       'merchant_p5_small',
  items:          [{ unitPrice: 100, qty: 1 }],
  idempotencyKey: 'idem_p5_small',
};

test('P5: platform_fees receives 1.5% fee on a small order (cap not reached)', () => {
  const ledger = new Ledger();
  const svc    = new PaymentService(ledger);
  const r = svc.charge(smallOrder);
  svc.settle(smallOrder.paymentId);

  const amountCents      = Math.round(r.amount * 100);
  const expectedFeeCents = Math.min(Math.round(amountCents * FEE_RATE), FEE_CAP_CENTS);

  assert.equal(
    ledger.balanceCents('platform_fees'),
    expectedFeeCents,
    `platform_fees holds ${ledger.balanceCents('platform_fees')} cents; expected ${expectedFeeCents}`
  );
});
