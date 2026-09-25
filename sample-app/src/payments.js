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
