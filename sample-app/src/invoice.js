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
