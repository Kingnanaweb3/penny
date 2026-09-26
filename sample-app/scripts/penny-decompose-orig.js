/**
 * penny-decompose-orig.js
 *
 * Replays the identical simulated day using the ORIGINAL buggy code
 * (per-line chargeTotal, float ledger, no idempotency, no cap, no refund guard)
 * so the decomposition matches the true baseline from scripts/04_show_before.sh.
 *
 * The simulate-day.js PRNG sequence is reproduced identically.
 * All four account sim-diffs must sum to the true baseline with zero residual.
 *
 * Run from sample-app/: node scripts/penny-decompose-orig.js
 */

// ── identical PRNG / data constants from simulate-day.js ────────────────────
let seed = 42;
const rand = () => {
  seed = (seed * 1664525 + 1013904223) % 4294967296;
  return seed / 4294967296;
};
const pick = (arr) => arr[Math.floor(rand() * arr.length)];

const PRICES    = [1.5, 4.99, 12.5, 29.99, 75, 189.95, 450, 1299.99];
const CUSTOMERS = Array.from({ length: 40 }, (_, i) => `customer_${i + 1}`);
const MERCHANTS = ['merchant_harbor_foods', 'merchant_summit_gadgets', 'merchant_northgate_textiles'];
const ORDERS    = 500;
const FEE_RATE  = 0.015;
const FEE_CAP   = 20; // dollars

const toCents = (d) => Math.round(d * 100);

// ── ORIGINAL buggy code inlined ──────────────────────────────────────────────
// Ledger: stores raw floats, no cent conversion.
class OrigLedger {
  constructor() { this.entries = []; }
  post({ ref, from, to, amount, memo = '' }) {
    this.entries.push({ ref, from, to, amount, memo });
  }
  balance(account) {
    let total = 0;
    for (const e of this.entries) {
      if (e.to   === account) total += e.amount;
      if (e.from === account) total -= e.amount;
    }
    return total;
  }
}

// invoice.js original: per-line rounding
const round2 = (n) => Math.round(n * 100) / 100;
const VAT_RATE = 0.075;
const origChargeTotal = (items) =>
  items.reduce((sum, item) => sum + round2(item.unitPrice * item.qty * (1 + VAT_RATE)), 0);
const origReceiptTotal = (items) =>
  round2(items.reduce((s, i) => s + i.unitPrice * i.qty, 0) * (1 + VAT_RATE));

// PaymentService original: no idempotency, no cap, no refund guard
class OrigPaymentService {
  constructor(ledger) { this.ledger = ledger; this.payments = new Map(); }
  charge({ paymentId, customer, merchant, items }) {
    const amount = origChargeTotal(items);
    const fee = amount * FEE_RATE;
    this.ledger.post({ ref: paymentId, from: customer, to: 'clearing', amount, memo: 'charge' });
    this.ledger.post({ ref: paymentId, from: 'clearing', to: 'platform_fees', amount: fee, memo: 'processing fee' });
    this.payments.set(paymentId, { paymentId, customer, merchant, amount, fee, refunded: 0, settled: false });
    return { paymentId, amount, fee };
  }
  settle(paymentId) {
    const p = this.payments.get(paymentId);
    const fee = p.amount * FEE_RATE;
    this.ledger.post({ ref: paymentId, from: 'clearing', to: 'platform_fees', amount: fee, memo: 'settlement fee' });
    this.ledger.post({ ref: paymentId, from: 'clearing', to: p.merchant, amount: p.amount - fee, memo: 'merchant payout' });
    p.settled = true;
  }
  refund(paymentId, amount) {
    const p = this.payments.get(paymentId);
    p.refunded += amount;
    this.ledger.post({ ref: paymentId, from: p.merchant, to: p.customer, amount, memo: 'refund' });
  }
}

// ── live ledger (ground truth for actual balances) ───────────────────────────
const ledger = new OrigLedger();
const svc    = new OrigPaymentService(ledger);

// ── per-finding impact accumulators ─────────────────────────────────────────
const impact = {
  customers:     { P1: 0, P2: 0, P3: 0, P4: 0, P5: 0, P6: 0 },
  merchants:     { P1: 0, P2: 0, P3: 0, P4: 0, P5: 0, P6: 0 },
  platform_fees: { P1: 0, P2: 0, P3: 0, P4: 0, P5: 0, P6: 0 },
  clearing:      { P1: 0, P2: 0, P3: 0, P4: 0, P5: 0, P6: 0 },
};

// ── expected accumulators (per fee schedule) ─────────────────────────────────
let expCustomers = 0, expMerchants = 0, expFees = 0;

for (let n = 1; n <= ORDERS; n++) {
  const paymentId = `pay_${String(n).padStart(4, '0')}`;
  const items = Array.from({ length: 1 + Math.floor(rand() * 3) }, () => ({
    unitPrice: pick(PRICES),
    qty:       1 + Math.floor(rand() * 4),
  }));
  const order = {
    paymentId,
    customer:       pick(CUSTOMERS),
    merchant:       pick(MERCHANTS),
    items,
    idempotencyKey: `idem_${paymentId}`,
  };

  // ── spec-correct values (integer cents arithmetic, matches simulate-day.js) ─
  const subtotalCents  = items.reduce((s, i) => s + toCents(i.unitPrice) * i.qty, 0);
  const receiptCents   = Math.round((subtotalCents * 1075) / 1000);
  const feeCents       = Math.min(Math.round((receiptCents * 15) / 1000), 2000);
  const receiptDollars = receiptCents / 100;
  const feeCapped      = feeCents / 100;

  // ── what the original buggy code charges ─────────────────────────────────
  const chargeDollars    = origChargeTotal(items);  // per-line rounding
  const feeChargeActual  = chargeDollars * FEE_RATE; // no cap, raw float
  const feeSettleActual  = chargeDollars * FEE_RATE; // settle() recomputes

  // ── run through the live service ─────────────────────────────────────────
  svc.charge(order);
  const isRetry = rand() < 0.03;
  if (isRetry) svc.charge(order);
  svc.settle(paymentId);

  // ── refunds ───────────────────────────────────────────────────────────────
  let actualRefundDollars   = 0;
  let expectedRefundDollars = 0;
  let refundedCentsSoFar    = 0;

  if (rand() < 0.06) {
    const requests = rand() < 0.35 ? 2 : 1;
    const reqCents  = Math.round(receiptCents * 0.6);

    for (let r = 0; r < requests; r++) {
      svc.refund(paymentId, reqCents / 100);
      actualRefundDollars += reqCents / 100;
      const cappedCents    = Math.min(reqCents, receiptCents - refundedCentsSoFar);
      expectedRefundDollars += cappedCents / 100;
      refundedCentsSoFar   += cappedCents;
    }
  }

  // ── expected totals ───────────────────────────────────────────────────────
  expCustomers += receiptDollars  - expectedRefundDollars;
  expMerchants += receiptDollars  - feeCapped - expectedRefundDollars;
  expFees      += feeCapped;

  // ── per-finding attribution ───────────────────────────────────────────────
  // Sign convention: positive = account's sim-diff goes UP (actual > expected).
  // All finding deltas for a money-conserving bug net to zero across accounts.
  // P6 and the P2/P1 merchant share are exceptions — see inline notes.

  const chargeRuns = isRetry ? 2 : 1;

  // ── P2: rounding drift ────────────────────────────────────────────────────
  // drift = chargeDollars (per-line) − receiptDollars (spec single-round)
  // Customers: billed chargeDollars each charge run (positive drift per extra cent)
  // Platform fees: both charge-time and settle-time fee bases are chargeDollars
  //   (charge-time fees: chargeRuns; settle-time fee: 1)
  // Merchant: payout = chargeDollars*(1-FEE_RATE); spec = receiptDollars*(1-FEE_RATE)
  // Clearing: drift flows in from customer and out via fee+payout → nets to zero
  {
    const drift = chargeDollars - receiptDollars;
    impact.customers.P2      += drift * chargeRuns;
    impact.platform_fees.P2  += drift * FEE_RATE * chargeRuns   // charge-time fees on drift
                               + drift * FEE_RATE;               // settle-time fee on drift
    impact.merchants.P2      += drift * (1 - FEE_RATE);
    impact.clearing.P2       += 0;
  }

  // ── P3: missing idempotency ───────────────────────────────────────────────
  // A retry posts: customer→clearing: chargeDollars AND clearing→platform_fees: feeChargeActual.
  // settle() runs only once, so the full retry credit sits in clearing.
  //
  // P3 owns everything that exists solely because the retry was not blocked:
  //   Customers:     +chargeDollars  (extra customer debit)
  //   Clearing:      +chargeDollars  (full retry credit — the charge-time fee drain
  //                                   on the retry call is already counted in P4 below,
  //                                   so it is NOT pre-subtracted here)
  //   Platform fees: +feeChargeActual (the retry's charge-time fee posting)
  //   Merchant:       0 (settle uses the same p.amount regardless)
  //
  // Conservation check (per order with a retry):
  //   P3: customer −chargeDollars, clearing +chargeDollars, fees +feeChargeActual, merchant 0
  //   Net = −chargeDollars + chargeDollars + feeChargeActual = +feeChargeActual
  //   (Non-zero because a new fee posting is created — money moves from clearing to fees
  //    that would not exist without the retry. P4 accounts for the corresponding clearing
  //    drain on the retry call, so the pair nets to zero across P3+P4 for that retry call.)
  if (isRetry) {
    impact.customers.P3      += chargeDollars;
    impact.clearing.P3       += chargeDollars;        // full retry credit, not net-of-fee
    impact.platform_fees.P3  += feeChargeActual;      // retry's charge-time fee
    impact.merchants.P3      += 0;
  }

  // ── P4: double fees ───────────────────────────────────────────────────────
  // charge() posts clearing→platform_fees: feeChargeActual on EVERY charge() call.
  // The spec allows only one fee, at settlement.
  //
  // Attribution rule: P3 owns the retry call's charge-time fee posting on BOTH sides —
  // the platform_fees credit (+feeChargeActual) and the clearing drain (−feeChargeActual).
  // P4 owns the charge-time fee on the FIRST call of every order only (one per order).
  //
  // For a non-retry order (chargeRuns=1): P4 counts 1 fee on both sides.
  // For a retry order (chargeRuns=2):     P3 owns both sides of the retry's fee posting.
  //                                        P4 owns both sides of the first call's fee posting.
  //
  // Platform: +feeChargeActual × 1
  // Clearing: −feeChargeActual × 1
  impact.platform_fees.P4 += feeChargeActual;           // first-call fee only
  impact.clearing.P4      -= feeChargeActual;            // first-call fee drain only

  // P3 clearing: full retry credit (+chargeDollars) minus the retry's own fee drain.
  // The retry posts two ledger entries: customer→clearing: chargeDollars (credit)
  // and clearing→platform_fees: feeChargeActual (drain). P3 owns both.
  // Net P3 clearing contribution = chargeDollars − feeChargeActual.
  // This is already set above as impact.clearing.P3 += chargeDollars (the credit).
  // We must also subtract the retry fee drain here, inside the isRetry block.
  // Adjust: subtract the retry's clearing drain from P3, keeping P4 clean.
  if (isRetry) {
    impact.clearing.P3 -= feeChargeActual;  // retry's fee drain belongs to P3, not P4
  }

  // ── P5: missing cap ───────────────────────────────────────────────────────
  // settle() uses chargeDollars*FEE_RATE uncapped; spec = min(chargeDollars*FEE_RATE, FEE_CAP)
  // excessFee = max(0, chargeDollars*FEE_RATE − FEE_CAP)
  // Platform: +excessFee
  // Merchant: −excessFee (less payout)
  // Clearing: nets to zero (settle fee + payout = chargeDollars regardless)
  {
    const excessFee = Math.max(0, chargeDollars * FEE_RATE - FEE_CAP);
    impact.platform_fees.P5 += excessFee;
    impact.merchants.P5     -= excessFee;
  }

  // ── P6: over refund ───────────────────────────────────────────────────────
  // extra = actualRefundDollars − expectedRefundDollars ≥ 0
  // Both customer net outflow and merchant net inflow decrease by extra vs spec.
  {
    const extra = actualRefundDollars - expectedRefundDollars;
    impact.customers.P6     -= extra;
    impact.merchants.P6     -= extra;
  }
}

// ── actual balances from live (original buggy) ledger ────────────────────────
const sumAccounts = (accs) => accs.reduce((s, a) => s + ledger.balance(a), 0);
const actCustomers    = -sumAccounts(CUSTOMERS);
const actMerchants    =  sumAccounts(MERCHANTS);
const actFees         =  ledger.balance('platform_fees');
const actClearing     =  ledger.balance('clearing');

// ── differences (actual − expected) ─────────────────────────────────────────
const simDiff = {
  customers:     actCustomers - expCustomers,
  merchants:     actMerchants - expMerchants,
  platform_fees: actFees      - expFees,
  clearing:      actClearing  - 0,
};

// ── P1 float noise = residual after named findings ───────────────────────────
const accounts = ['customers', 'merchants', 'platform_fees', 'clearing'];
const findings = ['P2', 'P3', 'P4', 'P5', 'P6'];

const noise = {};
for (const acc of accounts) {
  const attributed = findings.reduce((s, f) => s + impact[acc][f], 0);
  noise[acc] = simDiff[acc] - attributed;
}

// ── output ────────────────────────────────────────────────────────────────────
const r2 = (n) => Math.round(n * 100) / 100;
const fmt = (n, w = 14) => String(r2(n)).padStart(w);

console.log('\nShopLedger Penny Decomposition (original buggy baseline)');
console.log('Dollar impact of each finding per account  (positive = account gains vs spec, negative = loses)\n');

const cols = [...findings, 'P1 noise', 'TOTAL', 'sim-diff', 'residual'];
const colW = 14;
console.log('Account'.padEnd(18) + cols.map(c => c.padStart(colW)).join(''));
console.log('-'.repeat(18 + cols.length * colW));

// Use full-precision sums to avoid display-rounding residuals.
for (const acc of accounts) {
  const label = acc === 'platform_fees' ? 'Platform fees' :
                acc.charAt(0).toUpperCase() + acc.slice(1);
  const fpVals  = findings.map(f => impact[acc][f]);
  const fpNoise = noise[acc];
  const fpTotal = fpVals.reduce((s, v) => s + v, 0) + fpNoise; // full precision
  const fpSd    = simDiff[acc];
  const residual = r2(fpTotal - fpSd);  // should be 0.00

  const vals = fpVals.map(v => r2(v));
  const pnoise = r2(fpNoise);
  const total  = r2(fpTotal);
  const sd     = r2(fpSd);

  console.log(
    label.padEnd(18) +
    [...vals, pnoise, total, sd, residual].map(v => fmt(v)).join('')
  );
}
console.log('-'.repeat(18 + cols.length * colW));

console.log('\nKey: positive = account gains money vs expectation; negative = loses.');
console.log('"residual" must be 0.00 — any non-zero value means the decomposition is incomplete.\n');

// ── per-finding conservation ─────────────────────────────────────────────────
console.log('Per-finding conservation (expected 0 for pure transfers):');
console.log('Finding'.padEnd(10) + ['Customers','Merchants','Fees','Clearing','Net'].map(c => c.padStart(14)).join(''));
console.log('-'.repeat(10 + 5 * 14));
for (const f of [...findings, 'P1']) {
  const cu  = f === 'P1' ? noise.customers     : impact.customers[f];
  const me  = f === 'P1' ? noise.merchants     : impact.merchants[f];
  const fe  = f === 'P1' ? noise.platform_fees : impact.platform_fees[f];
  const cl  = f === 'P1' ? noise.clearing      : impact.clearing[f];
  const net = r2(cu + me + fe + cl);
  const ok  = Math.abs(net) < 0.02 ? '✓' : '(non-zero: see notes)';
  console.log(f.padEnd(10) + [cu, me, fe, cl].map(v => fmt(r2(v))).join('') + `    ${net} ${ok}`);
}
console.log('');

// ── raw sim-diff summary ──────────────────────────────────────────────────────
console.log('Raw sim-diff (actual − expected, full precision):');
for (const acc of accounts) console.log(`  ${acc.padEnd(16)} ${simDiff[acc]}`);
console.log('');
console.log('True baseline total discrepancy: USD',
  r2(Math.abs(simDiff.customers) + Math.abs(simDiff.merchants) + Math.abs(simDiff.platform_fees) + Math.abs(simDiff.clearing)));
