# ShopLedger Fee Schedule and Money Rules

Effective for all merchants on the ShopLedger platform.

1. All money is stored and calculated in whole kobo (1 naira = 100 kobo). No fractional kobo.
2. VAT is 7.5 percent, calculated once on the invoice subtotal and rounded once to the nearest kobo. The amount charged must equal the amount shown on the customer receipt.
3. The platform fee is 1.5 percent of the charged amount, capped at 2,000 naira per transaction.
4. The platform fee is taken exactly once, at settlement.
5. A charge retried with the same idempotency key must not create a second charge.
6. Total refunds on a payment may never exceed the amount charged.
7. After settlement, the clearing account balance for a payment must be zero.
