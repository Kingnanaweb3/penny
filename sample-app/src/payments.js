import { FEE_RATE } from './config.js';
import { chargeTotal } from './invoice.js';

export class PaymentService {
  constructor(ledger) {
    this.ledger = ledger;
    this.payments = new Map();
    this.idempotencyKeys = new Map();  // idempotencyKey → original charge result
  }

  charge({ paymentId, customer, merchant, items, idempotencyKey }) {
    // Rule 5: a retry with the same idempotency key must not create a second charge.
    if (idempotencyKey && this.idempotencyKeys.has(idempotencyKey)) {
      return this.idempotencyKeys.get(idempotencyKey);
    }

    const amount = chargeTotal(items);

    this.ledger.post({ ref: paymentId, from: customer, to: 'clearing', amount, memo: 'charge' });
    // Rule 4: fee is taken exactly once, at settlement — no charge-time fee posting.

    this.payments.set(paymentId, { paymentId, customer, merchant, amount, idempotencyKey, refunded: 0, settled: false });
    const result = { paymentId, amount, fee: amount * FEE_RATE };
    if (idempotencyKey) this.idempotencyKeys.set(idempotencyKey, result);
    return result;
  }

  settle(paymentId) {
    const p = this.payments.get(paymentId);
    if (!p) throw new Error(`Unknown payment ${paymentId}`);

    // Compute fee and payout in whole cents so feeCents + payoutCents = amountCents exactly.
    // This guarantees clearing nets to zero after settlement (Rule 7).
    const amountCents = Math.round(p.amount * 100);
    const feeCents    = Math.round(amountCents * FEE_RATE);
    const payoutCents = amountCents - feeCents;

    this.ledger.post({ ref: paymentId, from: 'clearing', to: 'platform_fees', amount: feeCents / 100, memo: 'settlement fee' });
    this.ledger.post({ ref: paymentId, from: 'clearing', to: p.merchant, amount: payoutCents / 100, memo: 'merchant payout' });
    p.settled = true;
  }

  refund(paymentId, amount) {
    const p = this.payments.get(paymentId);
    if (!p) throw new Error(`Unknown payment ${paymentId}`);

    p.refunded += amount;
    this.ledger.post({ ref: paymentId, from: p.merchant, to: p.customer, amount, memo: 'refund' });
  }
}
