# Penny

Every penny accounted for. A trial balance for your payment code, built with IBM Bob 2.0.

## About the sample app

sample-app/ (ShopLedger) is a small payments service created as Penny's audit target.
Its money bugs were deliberately seeded to reflect common real world failure patterns.
Penny, running as a custom mode inside IBM Bob 2.0, finds them, proves each one with a
failing test, fixes it, and proves the books balance.
