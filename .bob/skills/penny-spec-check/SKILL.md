---
name: penny-spec-check
description: Read a written fee schedule or money policy document and check the code against every rule in it. Use when a payments project has a policy, pricing, or fee document.
---

# Check the code against the written rules

1. Read sample-app/docs/fee-schedule.md in full.
2. Turn each numbered rule into one checkable statement.
3. For each rule, find the code that should enforce it and decide:
   - Enforced: the code does what the rule says
   - Violated: the code does something different
   - Missing: nothing in the code enforces it
4. Write a table to penny-report/02-spec-check.md with columns:
   Rule | What the document says | What the code does | Status | Evidence (file:line)
5. Quote the rule text exactly from the document in the table.
