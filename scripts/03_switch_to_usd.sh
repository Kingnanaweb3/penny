#!/usr/bin/env bash
# Switches ShopLedger and Penny from naira/kobo to dollars/cents.
# Usage: bash scripts/03_switch_to_usd.sh        (converts this repo)
#        bash scripts/03_switch_to_usd.sh DIR    (converts DIR/sample-app only, used by 04)
set -euo pipefail

ROOT="${1:-.}"
APP="$ROOT/sample-app"

if [ ! -d "$APP/src" ]; then
  echo "Could not find $APP/src. Run this from the penny folder."
  exit 1
fi

# Word swaps for code, tests and Penny's instructions.
swap() {
  perl -pi -e '
    s/balanceKobo/balanceCents/g;
    s/KOBO/CENTS/g; s/Kobo/Cents/g; s/kobo/cents/g;
    s/NAIRA/DOLLARS/g; s/Naira/Dollars/g; s/naira/dollars/g;
    s/\x{20A6}/\$/g; s/\xE2\x82\xA6/\$/g;
    s/NGN/USD/g;
  ' "$@"
}

# 1. App code and tests
find "$APP/src" "$APP/tests" -type f -name "*.js" -print0 | xargs -0 -r perl -pi -e '
  s/balanceKobo/balanceCents/g;
  s/KOBO/CENTS/g; s/Kobo/Cents/g; s/kobo/cents/g;
  s/NAIRA/DOLLARS/g; s/Naira/Dollars/g; s/naira/dollars/g;
  s/\xE2\x82\xA6/\$/g; s/NGN/USD/g;
'

# Penny's own decompose script, if it exists (Penny must still update its prices and cap)
if [ -f "$APP/scripts/penny-decompose.js" ]; then
  perl -pi -e '
    s/balanceKobo/balanceCents/g;
    s/KOBO/CENTS/g; s/Kobo/Cents/g; s/kobo/cents/g;
    s/NAIRA/DOLLARS/g; s/Naira/Dollars/g; s/naira/dollars/g;
    s/\xE2\x82\xA6/\$/g; s/NGN/USD/g;
  ' "$APP/scripts/penny-decompose.js"
fi

# 2. Fee schedule in dollars
cat > "$APP/docs/fee-schedule.md" << 'EOF'
# ShopLedger Fee Schedule and Money Rules

Effective for all merchants on the ShopLedger platform.

1. All money is stored and calculated in whole cents (1 dollar = 100 cents). No fractional cents.
2. Sales tax is 7.5 percent, calculated once on the invoice subtotal and rounded once to the nearest cent. The amount charged must equal the amount shown on the customer receipt.
3. The platform fee is 1.5 percent of the charged amount, capped at 20 dollars per transaction.
4. The platform fee is taken exactly once, at settlement.
5. A charge retried with the same idempotency key must not create a second charge.
6. Total refunds on a payment may never exceed the amount charged.
7. After settlement, the clearing account balance for a payment must be zero.
EOF

# 3. Finance team's reconciliation in dollars
cat > "$APP/scripts/simulate-day.js" << 'EOF'
import { Ledger } from '../src/ledger.js';
import { PaymentService } from '../src/payments.js';

let seed = 42;
const rand = () => {
  seed = (seed * 1664525 + 1013904223) % 4294967296;
  return seed / 4294967296;
};
const pick = (arr) => arr[Math.floor(rand() * arr.length)];

const PRICES = [1.5, 4.99, 12.5, 29.99, 75, 189.95, 450, 1299.99];
const CUSTOMERS = Array.from({ length: 40 }, (_, i) => `customer_${i + 1}`);
const MERCHANTS = ['merchant_harbor_foods', 'merchant_summit_gadgets', 'merchant_northgate_textiles'];
const ORDERS = 500;

const ledger = new Ledger();
const svc = new PaymentService(ledger);
const toCents = (dollars) => Math.round(dollars * 100);

// Finance team's expectation, computed in whole cents from docs/fee-schedule.md
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

  const subtotalCents = items.reduce((s, i) => s + toCents(i.unitPrice) * i.qty, 0);
  const receiptCents = Math.round((subtotalCents * 1075) / 1000);
  const feeCents = Math.min(Math.round((receiptCents * 15) / 1000), 2000);

  svc.charge(order);
  if (rand() < 0.03) {
    svc.charge(order);
    retries++;
  }
  svc.settle(paymentId);

  let refundedCents = 0;
  if (rand() < 0.06) {
    const requests = rand() < 0.35 ? 2 : 1;
    for (let r = 0; r < requests; r++) {
      const requestCents = Math.round(receiptCents * 0.6);
      svc.refund(paymentId, requestCents / 100);
      refundedCents += Math.min(requestCents, receiptCents - refundedCents);
      refundRequests++;
    }
  }

  expected.customers += receiptCents - refundedCents;
  expected.merchants += receiptCents - feeCents - refundedCents;
  expected.fees += feeCents;
}

const sum = (accounts) =>
  typeof ledger.balanceCents === 'function'
    ? accounts.reduce((s, a) => s + ledger.balanceCents(a), 0) / 100
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
console.log('Account'.padEnd(28) + 'Expected (USD)'.padEnd(20) + 'Ledger says (USD)'.padEnd(28) + 'Difference');
console.log('-'.repeat(90));

let gap = 0;
for (const [name, exp, act] of rows) {
  const diff = act - exp;
  gap += Math.abs(diff);
  console.log(name.padEnd(28) + exp.toFixed(2).padEnd(20) + String(act).padEnd(28) + diff.toFixed(2));
}

console.log('-'.repeat(90));
console.log(gap < 0.005 ? 'Books balance.' : `Books are off. Total discrepancy: USD ${gap.toFixed(2)}`);
console.log('');
EOF

# 4. Penny's mode, rules and skills (only when converting the real repo)
if [ "$ROOT" = "." ] && [ -d ".bob" ]; then
  find .bob -type f \( -name "*.md" -o -name "*.yaml" \) -print0 | xargs -0 -r perl -pi -e '
    s/balanceKobo/balanceCents/g;
    s/KOBO/CENTS/g; s/Kobo/Cents/g; s/kobo/cents/g;
    s/NAIRA/DOLLARS/g; s/Naira/Dollars/g; s/naira/dollars/g;
    s/\xE2\x82\xA6/\$/g; s/NGN/USD/g;
  '
  echo "Updated Penny mode, rules and skills to dollars and cents."
fi

echo "Converted $APP to dollars and cents."
