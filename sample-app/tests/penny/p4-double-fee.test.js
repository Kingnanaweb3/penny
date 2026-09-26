/**
 * P4 — Double fees
 * Rule 4: "The platform fee is taken exactly once, at settlement."
 *
 * charge() must not post any fee to platform_fees.
 * After charge + settle, platform_fees holds exactly one fee and clearing is zero.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Ledger } from '../../src/ledger.js';
import { PaymentService } from '../../src/payments.js';

const FEE_RATE = 0.015;

const setup = () => {
  const ledger = new Ledger();
  const svc    = new PaymentService(ledger);
  return { ledger, svc };
};

const order = {
  paymentId:      'pay_p4_test',
  customer:       'customer_p4',
  merchant:       'merchant_p4',
  items:          [{ unitPrice: 1000, qty: 1 }],
  idempotencyKey: 'idem_p4_test',
};

test('P4: platform_fees receives exactly one fee after charge + settle (Rule 4)', () => {
  const { ledger, svc } = setup();
  const r = svc.charge(order);
  svc.settle(order.paymentId);

  const expectedFeeCents = Math.round(r.amount * 100 * FEE_RATE);
  const actualFeeCents   = ledger.balanceCents('platform_fees');

  assert.equal(
    actualFeeCents,
    expectedFeeCents,
    `platform_fees holds ${actualFeeCents} cents but should hold ${expectedFeeCents} cents (exactly one fee)`
  );
});

test('P4: clearing account is zero after charge + settle (Rule 7 follows from Rule 4)', () => {
  const { ledger, svc } = setup();
  svc.charge(order);
  svc.settle(order.paymentId);

  assert.equal(
    ledger.balanceCents('clearing'),
    0,
    `clearing holds ${ledger.balanceCents('clearing')} cents after charge + settle; expected 0`
  );
});

test('P4: charge() alone posts nothing to platform_fees', () => {
  const { ledger, svc } = setup();
  svc.charge(order);

  assert.equal(
    ledger.balanceCents('platform_fees'),
    0,
    `platform_fees holds ${ledger.balanceCents('platform_fees')} cents after charge alone; expected 0`
  );
});
