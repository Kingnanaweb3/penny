---
name: penny-hunt
description: Hunt for money correctness bugs in payment code by bug class and produce a findings register. Use after mapping money flows and checking the fee schedule.
---

# Hunt for money bugs

Check each bug class. For each one, either record findings or state clearly that none were found.

1. Float money: amounts stored or calculated as fractional numbers instead of whole kobo.
2. Rounding drift: rounding applied per line, or more than once, so totals disagree
   (for example receipt total differs from charged total).
3. Missing idempotency: retrying a request with the same idempotency key creates a second charge.
4. Double fees: the same fee taken at more than one step.
5. Missing caps and limits: a cap or limit in the fee schedule that the code ignores.
6. Over refunds: refunds that can add up to more than the amount charged.
7. Clearing leaks: an intermediate account that should end at zero but does not.

For each finding write to penny-report/03-findings.md:
- ID (P1, P2, ...), severity (Critical, High, Medium)
- bug class and fee schedule rule number
- file and line
- what goes wrong, in one plain sentence a finance person understands
- a worked example with real naira amounts showing the loss or gain
- who loses money: customer, merchant or platform

End the register with a one paragraph summary for a finance manager.
