/**
 * P1 — Float money
 * Rule 1: "All money is stored and calculated in whole cents (1 dollars = 100 cents).
 *          No fractional cents."
 *
 * Proves that:
 * (a) every amount stored in ledger.entries is a whole integer number of cents
 * (b) ledger.balanceCents(account) exists and returns an integer
 *
 * Uses $999.99 × 1 item — a price that produces a fractional-cents fee
 * under the current code:
 *   chargeTotal = round2(999.99 × 1.075) = 1074.99 dollars
 *   fee = 1074.99 × 0.015 = 16.12485 dollars = 1612.485 cents  ← fractional
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Ledger } from '../../src/ledger.js';
import { PaymentService } from '../../src/payments.js';

const fractionalOrder = {
  paymentId: 'pay_p1',
  customer: 'cust_1',
  merchant: 'merch_1',
  items: [{ unitPrice: 999.99, qty: 1 }],
  idempotencyKey: 'idem_p1',
};

test('P1: every ledger entry amount is stored as a whole number of cents', () => {
  const ledger = new Ledger();
  const svc = new PaymentService(ledger);

  svc.charge(fractionalOrder);
  svc.settle('pay_p1');

  for (const entry of ledger.entries) {
    // After the fix the ledger stores amountCents (integer). Assert it is an integer.
    assert.ok(
      Number.isInteger(entry.amountCents),
      `Entry "${entry.memo}" amountCents=${entry.amountCents} — not a whole-cents integer`
    );
  }
});

test('P1: ledger.balanceCents(account) exists and returns an integer', () => {
  const ledger = new Ledger();
  const svc = new PaymentService(ledger);

  svc.charge(fractionalOrder);
  svc.settle('pay_p1');

  assert.equal(typeof ledger.balanceCents, 'function', 'ledger.balanceCents is not a function');

  for (const account of ledger.accounts()) {
    const cents = ledger.balanceCents(account);
    assert.ok(
      Number.isInteger(cents),
      `balanceCents("${account}") returned ${cents} — not an integer`
    );
  }
});

test('P1: ledger.balanceCents(account) equals ledger.balance(account) * 100 for a whole-dollars amount', () => {
  // Sanity check: for an amount that IS whole dollars ($2000), the two methods agree.
  const ledger = new Ledger();
  const svc = new PaymentService(ledger);

  svc.charge({
    paymentId: 'pay_p1c',
    customer: 'cust_1',
    merchant: 'merch_1',
    items: [{ unitPrice: 1000, qty: 2 }], // 2000 dollars → VAT 7.5% = 2150 dollars
    idempotencyKey: 'idem_p1c',
  });
  svc.settle('pay_p1c');

  assert.equal(typeof ledger.balanceCents, 'function', 'ledger.balanceCents is not a function');
  const balDollars = ledger.balance('merch_1');
  const balCents  = ledger.balanceCents('merch_1');
  assert.equal(balCents, Math.round(balDollars * 100),
    `balanceCents (${balCents}) does not equal balance*100 (${balDollars * 100})`);
});
