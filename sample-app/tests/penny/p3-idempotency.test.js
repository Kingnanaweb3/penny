/**
 * P3 — Missing idempotency
 * Rule 5: "A charge retried with the same idempotency key must not create
 * a second charge."
 *
 * The retry must return the original result and post nothing to the ledger.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Ledger } from '../../src/ledger.js';
import { PaymentService } from '../../src/payments.js';

const makeOrder = () => ({
  paymentId:      'pay_p3_test',
  customer:       'customer_p3',
  merchant:       'merchant_p3',
  items:          [{ unitPrice: 100, qty: 1 }],
  idempotencyKey: 'idem_p3_test',
});

test('P3: second charge with same idempotency key does not debit the customer again', () => {
  const ledger = new Ledger();
  const svc    = new PaymentService(ledger);
  const order  = makeOrder();

  const first  = svc.charge(order);
  const second = svc.charge(order);   // retry with identical idempotencyKey

  // Customer must be debited exactly once.
  const customerDebits = -ledger.balance(order.customer);
  assert.equal(
    customerDebits,
    first.amount,
    `Customer was debited $${customerDebits.toFixed(2)} but should have been debited $${first.amount.toFixed(2)} (exactly once)`
  );
});

test('P3: retry returns the original charge result', () => {
  const ledger = new Ledger();
  const svc    = new PaymentService(ledger);
  const order  = makeOrder();

  const first  = svc.charge(order);
  const second = svc.charge(order);

  assert.equal(second.paymentId, first.paymentId);
  assert.equal(second.amount,    first.amount);
  assert.equal(second.fee,       first.fee);
});

test('P3: retry posts no new ledger entries', () => {
  const ledger = new Ledger();
  const svc    = new PaymentService(ledger);
  const order  = makeOrder();

  svc.charge(order);
  const entriesAfterFirst = ledger.entries.length;

  svc.charge(order);   // retry
  const entriesAfterRetry = ledger.entries.length;

  assert.equal(
    entriesAfterRetry,
    entriesAfterFirst,
    `Retry added ${entriesAfterRetry - entriesAfterFirst} ledger entries; expected 0`
  );
});
