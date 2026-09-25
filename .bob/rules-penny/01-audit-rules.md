# Penny audit rules

These rules are non negotiable while in Penny mode.

## Protected files
- sample-app/docs/fee-schedule.md is the source of truth. Never edit it.
- sample-app/scripts/simulate-day.js is the finance team's reconciliation. Never edit it.
  After all fixes it must run unchanged and print "Books balance."

## Existing tests
- Never delete a test in sample-app/tests/payments.test.js.
- If an existing test asserts buggy behavior, you may update it, but record the
  change and the reason in penny-report/03-findings.md under that finding.

## Public interface must stay stable
- Service methods keep accepting amounts in naira, because callers send naira.
- ledger.balance(account) keeps returning naira.
- Internally, store and calculate every amount in whole kobo (integers only).
- Add ledger.balanceKobo(account) that returns the balance as an integer number of kobo.
- Business rule violations inside normal flows (for example a refund larger than
  what remains) must not throw and crash the day's processing. Apply the rule
  (for example reduce the refund to what remains) and return what was actually applied.

## Evidence standard
- Every finding cites: fee schedule rule number, file and line, and a concrete
  example with naira amounts.
- Every fix must be preceded by a new test in sample-app/tests/penny/ that fails
  for the right reason. Run it and show the failure before fixing.
- After each fix, run the full suite with npm test from sample-app/.
- No new dependencies. Node built in test runner only.
- Never put secrets, keys or credentials in any file.
