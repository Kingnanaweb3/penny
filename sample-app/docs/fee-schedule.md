# ShopLedger Fee Schedule and Money Rules

Effective for all merchants on the ShopLedger platform.

1. All money is stored and calculated in whole cents (1 dollar = 100 cents). No fractional cents.
2. Sales tax is 7.5 percent, calculated once on the invoice subtotal and rounded once to the nearest cent. The amount charged must equal the amount shown on the customer receipt.
3. The platform fee is 1.5 percent of the charged amount, capped at 20 dollars per transaction.
4. The platform fee is taken exactly once, at settlement.
5. A charge retried with the same idempotency key must not create a second charge.
6. Total refunds on a payment may never exceed the amount charged.
7. After settlement, the clearing account balance for a payment must be zero.
