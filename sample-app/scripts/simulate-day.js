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

const sum = (accounts) =>
  typeof ledger.balanceKobo === 'function'
    ? accounts.reduce((s, a) => s + ledger.balanceKobo(a), 0) / 100
    : accounts.reduce((s, a) => s + ledger.balance(a), 0);
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
