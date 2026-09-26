---
name: penny-trial-balance
description: Run the full test suite and the end of day reconciliation, then write a before and after trial balance report. Use as the final step of a money audit.
---

# Trial balance

1. From sample-app/ run npm test and record pass and fail counts.
2. From sample-app/ run npm run simulate and capture the table.
3. Write penny-report/05-trial-balance.md with:
   - the before table (from the start of the audit, if recorded in earlier reports)
   - the after table
   - total discrepancy before and after, in dollars
   - a list of every finding with its status (fixed and proven, or open)
   - one short paragraph a finance manager could forward to their boss
4. Only report numbers you actually observed from running the commands. Never estimate.
