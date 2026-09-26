/**
 * P6 — Over refund
 * Rule 6: "Total refunds on a payment may never exceed the amount charged."
 *
 * Two refund requests of 60% each on a $100 order (total requested: $120).
 * Expected:
 *   - First refund: $60 applied in full.
 *   - Second refund: reduced to $40 (the remaining balance), not $60.
 *   - Customer receives back exactly $100 (the full charge, no more).
 *   - Merchant pays out exactly $100 (the full charge, no more).
 *   - refund() returns the amount actually applied, not the amount requested.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Ledger } from '../../src/ledger.js';
import { PaymentService } from '../../src/payments.js';

// unitPrice $100, qty 1 → subtotal $100 → taxed = Math.round(10000 * 1.075) / 100 = $107.50
// 60% of $107.50 = $64.50
const order = {
  paymentId:      'pay_p6_test',
  customer:       'customer_p6',
  merchant:       'merchant_p6',
  items:          [{ unitPrice: 100, qty: 1 }],
  idempotencyKey: 'idem_p6_test',
};

const setup = () => {
  const ledger = new Ledger();
  const svc    = new PaymentService(ledger);
  const r      = svc.charge(order);
  svc.settle(order.paymentId);
  return { ledger, svc, amount: r.amount };
};

test('P6: total refunds do not exceed the charged amount (Rule 6)', () => {
  const { ledger, svc, amount } = setup();
  const sixtyPct = amount * 0.6;   // $64.50

  svc.refund(order.paymentId, sixtyPct);   // first: $64.50 applied in full
  svc.refund(order.paymentId, sixtyPct);   // second: must be capped at remaining balance

  // Customer net outflow = charged − refunded. After a full refund it must be exactly $0.
  // Use balanceCents to avoid JavaScript −0 vs 0 distinction.
  assert.equal(
    ledger.balanceCents(order.customer),
    0,
    `Customer balance is ${ledger.balanceCents(order.customer)} cents; should be 0 after full refund`
  );
});

test('P6: total refunded never exceeds amount charged', () => {
  const { ledger, svc, amount } = setup();
  const sixtyPct    = amount * 0.6;
  const amountCents = Math.round(amount * 100);

  svc.refund(order.paymentId, sixtyPct);
  svc.refund(order.paymentId, sixtyPct);

  // Merchant paid out at most amountCents in refunds total.
  // Merchant received payoutCents (= amountCents - feeCents) at settlement.
  // So merchant balance >= −feeCents (it cannot be drained below what the fee cost it).
  // The strict cap check: total refund postings from merchant ≤ amountCents.
  const totalRefundedCents = ledger.entries
    .filter(e => e.from === order.merchant && e.memo === 'refund')
    .reduce((s, e) => s + e.amountCents, 0);

  assert.ok(
    totalRefundedCents <= amountCents,
    `Total refunded ${totalRefundedCents} cents exceeds charged ${amountCents} cents`
  );
});

test('P6: second refund returns the reduced amount actually applied', () => {
  const { ledger, svc, amount } = setup();
  const sixtyPct    = amount * 0.6;          // $64.50
  const amountCents = Math.round(amount * 100);
  const firstCents  = Math.round(sixtyPct * 100);
  const remainCents = amountCents - firstCents;  // $107.50 - $64.50 = $43.00

  svc.refund(order.paymentId, sixtyPct);          // first: applied in full
  const applied = svc.refund(order.paymentId, sixtyPct);  // second: capped

  assert.equal(
    Math.round(applied * 100),
    remainCents,
    `Second refund applied ${applied}; expected ${remainCents / 100} (the remaining balance)`
  );
});
