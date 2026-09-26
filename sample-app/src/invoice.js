import { VAT_RATE } from './config.js';

export function subtotal(items) {
  return items.reduce((sum, item) => sum + item.unitPrice * item.qty, 0);
}

// VAT is calculated once on the invoice subtotal and rounded once to the nearest kobo
// (Rule 2). Both receiptTotal and chargeTotal use this single-rounding path so the
// amount shown to the customer equals the amount charged.
function totalWithVat(items) {
  const subtotalKobo = Math.round(subtotal(items) * 100);
  const totalKobo = Math.round(subtotalKobo * (1 + VAT_RATE));
  return totalKobo / 100;
}

export function receiptTotal(items) {
  return totalWithVat(items);
}

export function chargeTotal(items) {
  return totalWithVat(items);
}
