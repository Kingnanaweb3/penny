---
name: penny-map-money
description: Map every place a payments codebase creates, moves, rounds, converts or stores money. Use at the start of a money audit, before looking for bugs.
---

# Map the money

1. Read every file under sample-app/src.
2. Follow one order end to end: items, invoice total, charge, fee, settlement, payout, refund.
3. For every step record:
   - file and line
   - what money moves, from which account, to which account
   - the number type used (float dollars, integer cents, other)
   - any rounding, and where it happens
4. Draw the flow as a Mermaid diagram showing accounts as boxes and postings as arrows.
5. Write everything to penny-report/01-money-map.md.
6. Do not judge correctness yet. This phase is a map, not a verdict.
