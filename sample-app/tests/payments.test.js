import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Ledger } from '../src/ledger.js';
import { PaymentService } from '../src/payments.js';
import { receiptTotal } from '../src/invoice.js';

const setup = () => {
  const ledger = new Ledger();
  return { ledger, svc: new PaymentService(ledger) };
};

const order = {
  paymentId: 'pay_test',
  customer: 'customer_1',
  merchant: 'merchant_1',
  items: [{ unitPrice: 1000, qty: 2 }],
  idempotencyKey: 'idem_test',
};

test('charge returns a positive amount', () => {
  const { svc } = setup();
  const r = svc.charge(order);
  assert.ok(r.amount > 0);
});

test('fee is capped at $20 for orders above the cap threshold', () => {
  // order: unitPrice $1,000 × qty 2 → amount $2,150.00, which exceeds the $20 cap.
  // After P5 fix, charge() returns the capped fee ($20.00), not amount × 1.5% ($32.25).
  const { svc } = setup();
  const r = svc.charge(order);
  assert.equal(r.fee, 20);
});

test('receipt includes 7.5 percent VAT', () => {
  assert.equal(receiptTotal([{ unitPrice: 1000, qty: 2 }]), 2150);
});

test('settlement pays the merchant', () => {
  const { ledger, svc } = setup();
  svc.charge(order);
  svc.settle('pay_test');
  assert.ok(ledger.balance('merchant_1') > 0);
});

test('refund moves money back to the customer', () => {
  const { ledger, svc } = setup();
  const r = svc.charge(order);
  svc.settle('pay_test');
  svc.refund('pay_test', 500);
  assert.ok(ledger.balance('customer_1') > -r.amount);
});
