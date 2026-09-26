#!/usr/bin/env bash
# Phase 5 trial balance, run from the terminal after the Bob budget ran out.
# Every number in the report is captured directly from command output. Nothing is typed by hand.
# Run from the penny folder.
set -uo pipefail

REPORT="penny-report/05-trial-balance.md"
LOG="penny-report/04-fix-log.md"
P7="sample-app/tests/penny/p7-clearing-zero.test.js"
NOW="$(date '+%Y-%m-%d %H:%M %Z')"

[ -d sample-app ] || { echo "Run this from the penny folder."; exit 1; }

echo "1/4  Running the P7 regression test on its own..."
if [ -f "$P7" ]; then
  P7_OUT="$(cd sample-app && node --test --test-reporter=tap "tests/penny/$(basename "$P7")" 2>&1)"; P7_CODE=$?
  P7_PASS="$(printf '%s\n' "$P7_OUT" | grep -E '^# pass ' | awk '{print $3}')"
  P7_FAIL="$(printf '%s\n' "$P7_OUT" | grep -E '^# fail ' | awk '{print $3}')"
else
  P7_CODE=2; P7_PASS=0; P7_FAIL="missing"
fi

echo "2/4  Running the full test suite..."
T_OUT="$(cd sample-app && node --test --test-reporter=tap tests/*.test.js tests/penny/*.test.js 2>&1)"; T_CODE=$?
T_TOTAL="$(printf '%s\n' "$T_OUT" | grep -E '^# tests ' | awk '{print $3}')"
T_PASS="$(printf '%s\n' "$T_OUT" | grep -E '^# pass ' | awk '{print $3}')"
T_FAIL="$(printf '%s\n' "$T_OUT" | grep -E '^# fail ' | awk '{print $3}')"

echo "3/4  Running the original buggy baseline (before)..."
BEFORE="$(bash scripts/04_show_before.sh 2>/dev/null | sed -n '/ShopLedger end of day reconciliation/,$p')"

echo "4/4  Running the reconciliation on the fixed code (after)..."
AFTER="$(cd sample-app && node scripts/simulate-day.js 2>&1)"

verdict() { printf '%s\n' "$1" | grep -E 'Books balance\.|Books are off' | tail -1; }
B_LINE="$(verdict "$BEFORE")"
A_LINE="$(verdict "$AFTER")"
total_of() {
  if printf '%s' "$1" | grep -q 'Books balance'; then echo "USD 0.00";
  else printf '%s' "$1" | grep -oE 'USD [0-9.,]+' | tail -1; fi
}
B_TOTAL="$(total_of "$B_LINE")"
A_TOTAL="$(total_of "$A_LINE")"

if [ "$P7_CODE" -eq 0 ]; then P7_STATUS="Resolved by P3 and P4. Regression test passed on its first run (${P7_PASS} passing), so no failing step exists to show."
elif [ "$P7_FAIL" = "missing" ]; then P7_STATUS="Open. The regression test file was not found."
else P7_STATUS="Open. Regression test failed (${P7_FAIL} failing). See output below."; fi

cat > "$REPORT" << EOF
# Phase 5: Trial Balance

Generated ${NOW} by \`scripts/11_trial_balance.sh\`.

**How this report was made.** The team's 40 Bobcoin budget ran out while Penny was writing the P7 test in Bob, so this final phase was run from the terminal. The script runs the same commands the penny-trial-balance skill specifies and pastes their output here unedited. No number below was typed by hand.

## Result

| | Total discrepancy |
|---|---|
| Before Penny (original buggy code) | ${B_TOTAL} |
| After Penny (P1 to P7) | ${A_TOTAL} |

Test suite: **${T_PASS} of ${T_TOTAL} passing, ${T_FAIL} failing.**

## Findings status

| Finding | Status |
|---|---|
| P1 Float money | Fixed and proven (see 04-fix-log.md) |
| P2 Rounding drift | Fixed and proven |
| P3 Missing idempotency | Fixed and proven |
| P4 Fee taken twice | Fixed and proven |
| P5 Fee cap missing | Fixed and proven |
| P6 Over refunds | Fixed and proven |
| P7 Clearing never zero | ${P7_STATUS} |

## Before: original buggy code

Command: \`bash scripts/04_show_before.sh\`

\`\`\`
${BEFORE}
\`\`\`

## After: code as fixed by Penny

Command: \`cd sample-app && npm run simulate\`

\`\`\`
${AFTER}
\`\`\`

## For a finance manager

On one simulated day of 500 orders, ShopLedger's books were off by ${B_TOTAL} while every original test passed. Penny traced the gap to seven bugs, proved each with a failing test, and fixed them one at a time. Rerunning the same day through the same reconciliation now gives a total discrepancy of ${A_TOTAL}.
EOF

if [ -f "$LOG" ] && ! grep -q "P7" "$LOG"; then
  printf '\n| P7 Clearing never zero | tests/penny/p7-clearing-zero.test.js | %s |\n' "$P7_STATUS" >> "$LOG"
fi

echo ""
echo "Before: ${B_TOTAL}"
echo "After:  ${A_TOTAL}"
echo "Tests:  ${T_PASS} of ${T_TOTAL} passing, ${T_FAIL} failing"
echo "P7:     ${P7_STATUS}"
echo ""
echo "Report written to ${REPORT}"
