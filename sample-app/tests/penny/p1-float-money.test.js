/**
 * P1 — Float money
 * Rule 1: "All money is stored and calculated in whole kobo (1 naira = 100 kobo).
 *          No fractional kobo."
 *
 * Proves that:
 * (a) every amount stored in ledger.entries is a whole integer number of kobo
 * (b) ledger.balanceKobo(account) exists and returns an integer
 *
 * Uses ₦999.99 × 1 item — a price that produces a fractional-kobo fee
 * under the current code:
 *   chargeTotal = round2(999.99 × 1.075) = 1074.99 naira
 *   fee = 1074.99 × 0.015 = 16.12485 naira = 1612.485 kobo  ← fractional
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

test('P1: every ledger entry amount is stored as a whole number of kobo', () => {
  const ledger = new Ledger();
  const svc = new PaymentService(ledger);

  svc.charge(fractionalOrder);
  svc.settle('pay_p1');

  for (const entry of ledger.entries) {
    // After the fix the ledger stores amountKobo (integer). Assert it is an integer.
    assert.ok(
      Number.isInteger(entry.amountKobo),
      `Entry "${entry.memo}" amountKobo=${entry.amountKobo} — not a whole-kobo integer`
    );
  }
});

test('P1: ledger.balanceKobo(account) exists and returns an integer', () => {
  const ledger = new Ledger();
  const svc = new PaymentService(ledger);

  svc.charge(fractionalOrder);
  svc.settle('pay_p1');

  assert.equal(typeof ledger.balanceKobo, 'function', 'ledger.balanceKobo is not a function');

  for (const account of ledger.accounts()) {
    const kobo = ledger.balanceKobo(account);
    assert.ok(
      Number.isInteger(kobo),
      `balanceKobo("${account}") returned ${kobo} — not an integer`
    );
  }
});

test('P1: ledger.balanceKobo(account) equals ledger.balance(account) * 100 for a whole-naira amount', () => {
  // Sanity check: for an amount that IS whole naira (₦2000), the two methods agree.
  const ledger = new Ledger();
  const svc = new PaymentService(ledger);

  svc.charge({
    paymentId: 'pay_p1c',
    customer: 'cust_1',
    merchant: 'merch_1',
    items: [{ unitPrice: 1000, qty: 2 }], // 2000 naira → VAT 7.5% = 2150 naira
    idempotencyKey: 'idem_p1c',
  });
  svc.settle('pay_p1c');

  assert.equal(typeof ledger.balanceKobo, 'function', 'ledger.balanceKobo is not a function');
  const balNaira = ledger.balance('merch_1');
  const balKobo  = ledger.balanceKobo('merch_1');
  assert.equal(balKobo, Math.round(balNaira * 100),
    `balanceKobo (${balKobo}) does not equal balance*100 (${balNaira * 100})`);
});
