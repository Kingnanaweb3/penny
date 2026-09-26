/**
 * P7 — Clearing leak
 * Rule 7: "After settlement, the clearing account balance for a payment must be zero."
 *
 * P7 was caused by P3 (stranded retry credits) and P4 (charge-time fee drain).
 * Both are fixed. This test is a regression guard.
 *
 * Three scenarios:
 *   A) Normal order: charge then settle.
 *   B) Retried order: charge twice with the same idempotency key, then settle.
 *      The retry is now a no-op (P3 fixed), so clearing still nets to zero.
 *   C) Refunded order: charge, settle, then refund.
 *      Refunds move between merchant and customer — clearing is not touched.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Ledger } from '../../src/ledger.js';
import { PaymentService } from '../../src/payments.js';

const makeOrder = (suffix) => ({
  paymentId:      `pay_p7_${suffix}`,
  customer:       `customer_p7_${suffix}`,
  merchant:       `merchant_p7_${suffix}`,
  items:          [{ unitPrice: 100, qty: 1 }],
  idempotencyKey: `idem_p7_${suffix}`,
});

test('P7: clearing is zero after charge + settle (normal order)', () => {
  const ledger = new Ledger();
  const svc    = new PaymentService(ledger);
  const order  = makeOrder('normal');

  svc.charge(order);
  svc.settle(order.paymentId);

  assert.equal(
    ledger.balanceCents('clearing'),
    0,
    `clearing holds ${ledger.balanceCents('clearing')} cents after charge + settle; expected 0`
  );
});

test('P7: clearing is zero after idempotent retry + settle', () => {
  const ledger = new Ledger();
  const svc    = new PaymentService(ledger);
  const order  = makeOrder('retry');

  svc.charge(order);               // first call — posts to ledger
  svc.charge(order);               // retry with same idempotencyKey — no-op (P3 fixed)
  svc.settle(order.paymentId);

  assert.equal(
    ledger.balanceCents('clearing'),
    0,
    `clearing holds ${ledger.balanceCents('clearing')} cents after retry + settle; expected 0`
  );
});

test('P7: clearing is zero after charge + settle + partial refund', () => {
  const ledger = new Ledger();
  const svc    = new PaymentService(ledger);
  const order  = makeOrder('refund');

  const r = svc.charge(order);
  svc.settle(order.paymentId);
  svc.refund(order.paymentId, r.amount * 0.5);  // 50% refund — goes merchant→customer

  assert.equal(
    ledger.balanceCents('clearing'),
    0,
    `clearing holds ${ledger.balanceCents('clearing')} cents after charge + settle + refund; expected 0`
  );
});
