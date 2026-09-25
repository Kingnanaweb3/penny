#!/usr/bin/env bash
set -euo pipefail

APP="sample-app"
mkdir -p "$APP/src" "$APP/tests" "$APP/scripts" "$APP/docs"

cat > "$APP/package.json" << 'EOF'
{
  "name": "shopledger",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node --test tests/*.test.js",
    "simulate": "node scripts/simulate-day.js"
  }
}
EOF

cat > "$APP/docs/fee-schedule.md" << 'EOF'
# ShopLedger Fee Schedule and Money Rules

Effective for all merchants on the ShopLedger platform.

1. All money is stored and calculated in whole kobo (1 naira = 100 kobo). No fractional kobo.
2. VAT is 7.5 percent, calculated once on the invoice subtotal and rounded once to the nearest kobo. The amount charged must equal the amount shown on the customer receipt.
3. The platform fee is 1.5 percent of the charged amount, capped at 2,000 naira per transaction.
4. The platform fee is taken exactly once, at settlement.
5. A charge retried with the same idempotency key must not create a second charge.
6. Total refunds on a payment may never exceed the amount charged.
7. After settlement, the clearing account balance for a payment must be zero.
EOF

cat > "$APP/src/config.js" << 'EOF'
export const VAT_RATE = 0.075;
export const FEE_RATE = 0.015;
EOF

cat > "$APP/src/ledger.js" << 'EOF'
export class Ledger {
  constructor() {
    this.entries = [];
  }

  post({ ref, from, to, amount, memo = '' }) {
    this.entries.push({ ref, from, to, amount, memo, seq: this.entries.length + 1 });
  }

  balance(account) {
    let total = 0;
    for (const e of this.entries) {
      if (e.to === account) total += e.amount;
      if (e.from === account) total -= e.amount;
    }
    return total;
  }

  accounts() {
    return [...new Set(this.entries.flatMap((e) => [e.from, e.to]))];
  }
}
EOF

cat > "$APP/src/invoice.js" << 'EOF'
import { VAT_RATE } from './config.js';

const round2 = (n) => Math.round(n * 100) / 100;

export function subtotal(items) {
  return items.reduce((sum, item) => sum + item.unitPrice * item.qty, 0);
}

export function receiptTotal(items) {
  return round2(subtotal(items) * (1 + VAT_RATE));
}

export function chargeTotal(items) {
  return items.reduce((sum, item) => sum + round2(item.unitPrice * item.qty * (1 + VAT_RATE)), 0);
}
EOF

cat > "$APP/src/payments.js" << 'EOF'
import { FEE_RATE } from './config.js';
import { chargeTotal } from './invoice.js';

export class PaymentService {
  constructor(ledger) {
    this.ledger = ledger;
    this.payments = new Map();
  }

  charge({ paymentId, customer, merchant, items, idempotencyKey }) {
    const amount = chargeTotal(items);
    const fee = amount * FEE_RATE;

    this.ledger.post({ ref: paymentId, from: customer, to: 'clearing', amount, memo: 'charge' });
    this.ledger.post({ ref: paymentId, from: 'clearing', to: 'platform_fees', amount: fee, memo: 'processing fee' });

    this.payments.set(paymentId, { paymentId, customer, merchant, amount, fee, idempotencyKey, refunded: 0, settled: false });
    return { paymentId, amount, fee };
  }

  settle(paymentId) {
    const p = this.payments.get(paymentId);
    if (!p) throw new Error(`Unknown payment ${paymentId}`);

    const fee = p.amount * FEE_RATE;
    this.ledger.post({ ref: paymentId, from: 'clearing', to: 'platform_fees', amount: fee, memo: 'settlement fee' });
    this.ledger.post({ ref: paymentId, from: 'clearing', to: p.merchant, amount: p.amount - fee, memo: 'merchant payout' });
    p.settled = true;
  }

  refund(paymentId, amount) {
    const p = this.payments.get(paymentId);
    if (!p) throw new Error(`Unknown payment ${paymentId}`);

    p.refunded += amount;
    this.ledger.post({ ref: paymentId, from: p.merchant, to: p.customer, amount, memo: 'refund' });
  }
}
EOF

cat > "$APP/tests/payments.test.js" << 'EOF'
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

test('fee is 1.5 percent of the charge', () => {
  const { svc } = setup();
  const r = svc.charge(order);
  assert.equal(r.fee, r.amount * 0.015);
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
EOF

cat > "$APP/scripts/simulate-day.js" << 'EOF'
import { Ledger } from '../src/ledger.js';
import { PaymentService } from '../src/payments.js';

let seed = 42;
const rand = () => {
  seed = (seed * 1664525 + 1013904223) % 4294967296;
  return seed / 4294967296;
};
const pick = (arr) => arr[Math.floor(rand() * arr.length)];

const PRICES = [150, 499.99, 1250.5, 2999.99, 7500, 18999.95, 45000, 129999.99];
const CUSTOMERS = Array.from({ length: 40 }, (_, i) => `customer_${i + 1}`);
const MERCHANTS = ['merchant_ada_foods', 'merchant_eko_gadgets', 'merchant_jos_textiles'];
const ORDERS = 500;

const ledger = new Ledger();
const svc = new PaymentService(ledger);
const toKobo = (naira) => Math.round(naira * 100);

// Finance team's expectation, computed in whole kobo from docs/fee-schedule.md
const expected = { customers: 0, merchants: 0, fees: 0 };
let retries = 0;
let refundRequests = 0;

for (let n = 1; n <= ORDERS; n++) {
  const paymentId = `pay_${String(n).padStart(4, '0')}`;
  const items = Array.from({ length: 1 + Math.floor(rand() * 3) }, () => ({
    unitPrice: pick(PRICES),
    qty: 1 + Math.floor(rand() * 4),
  }));
  const order = { paymentId, customer: pick(CUSTOMERS), merchant: pick(MERCHANTS), items, idempotencyKey: `idem_${paymentId}` };

  const subtotalKobo = items.reduce((s, i) => s + toKobo(i.unitPrice) * i.qty, 0);
  const receiptKobo = Math.round((subtotalKobo * 1075) / 1000);
  const feeKobo = Math.min(Math.round((receiptKobo * 15) / 1000), 200000);

  svc.charge(order);
  if (rand() < 0.03) {
    svc.charge(order);
    retries++;
  }
  svc.settle(paymentId);

  let refundedKobo = 0;
  if (rand() < 0.06) {
    const requests = rand() < 0.35 ? 2 : 1;
    for (let r = 0; r < requests; r++) {
      const requestKobo = Math.round(receiptKobo * 0.6);
      svc.refund(paymentId, requestKobo / 100);
      refundedKobo += Math.min(requestKobo, receiptKobo - refundedKobo);
      refundRequests++;
    }
  }

  expected.customers += receiptKobo - refundedKobo;
  expected.merchants += receiptKobo - feeKobo - refundedKobo;
  expected.fees += feeKobo;
}

const sum = (accounts) => accounts.reduce((s, a) => s + ledger.balance(a), 0);
const actual = {
  customers: -sum(CUSTOMERS),
  merchants: sum(MERCHANTS),
  fees: ledger.balance('platform_fees'),
  clearing: ledger.balance('clearing'),
};

const rows = [
  ['Customers paid (net)', expected.customers / 100, actual.customers],
  ['Merchants received (net)', expected.merchants / 100, actual.merchants],
  ['Platform fees', expected.fees / 100, actual.fees],
  ['Clearing account', 0, actual.clearing],
];

console.log('\nShopLedger end of day reconciliation');
console.log(`Orders: ${ORDERS} | Client retries: ${retries} | Refund requests: ${refundRequests}\n`);
console.log('Account'.padEnd(28) + 'Expected (NGN)'.padEnd(20) + 'Ledger says (NGN)'.padEnd(28) + 'Difference');
console.log('-'.repeat(90));

let gap = 0;
for (const [name, exp, act] of rows) {
  const diff = act - exp;
  gap += Math.abs(diff);
  console.log(name.padEnd(28) + exp.toFixed(2).padEnd(20) + String(act).padEnd(28) + diff.toFixed(2));
}

console.log('-'.repeat(90));
console.log(gap < 0.005 ? 'Books balance.' : `Books are off. Total discrepancy: NGN ${gap.toFixed(2)}`);
console.log('');
EOF

echo "Sample app created in $APP/"
