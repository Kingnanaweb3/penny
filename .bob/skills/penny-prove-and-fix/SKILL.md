---
name: penny-prove-and-fix
description: For each money finding, write a failing test that proves the discrepancy, apply the smallest fix, and prove it passes. Use after a findings register exists.
---

# Prove, then fix

For each finding in penny-report/03-findings.md, in ID order:

1. Write a test in sample-app/tests/penny/ named after the finding, for example
   p1-float-money.test.js. The test asserts what the fee schedule requires.
2. Run it from sample-app/ with: node --test tests/penny/<file>
   Confirm it fails, and that it fails because of the bug, not a typo.
3. Apply the smallest change that fixes the bug. Follow .bob/rules-penny.
4. Rerun that test. Confirm it passes.
5. Run the full suite with npm test. Everything must pass.
6. Append to penny-report/04-fix-log.md:
   Finding | Test file | Failed with (short message) | Change made (file) | Passes now (yes or no)

Do not batch all fixes into one change. One finding, one proof, one fix.
Update the test script in sample-app/package.json so npm test also runs tests/penny/.
