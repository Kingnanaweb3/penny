#!/usr/bin/env bash
# Fills in the observed "after" total from penny-report/05-trial-balance.md,
# and adds an honest line about the final phase running outside Bob.
# Run from the penny folder.
set -euo pipefail

JS=site/src/main.js; HTML=site/index.html; REPORT=penny-report/05-trial-balance.md
[ -f "$REPORT" ] || { echo "Run scripts/11_trial_balance.sh first."; exit 1; }

# Read the after total straight from the report, so nothing is typed by hand
AFTER="$(grep -E '^\| After Penny' "$REPORT" | sed -E 's/.*\| *USD ([0-9.,]+) *\|.*/\1/')"
[ -n "$AFTER" ] || { echo "Could not read the after total from $REPORT"; exit 1; }
echo "After total from the report: \$${AFTER}"

perl -pi -e "s#const AFTER_TOTAL = null;.*#const AFTER_TOTAL = '\\\$${AFTER}';#" "$JS"

if ! grep -q "Last phase ran outside Bob" "$HTML"; then
  perl -0pi -e 's#(<div><b>Not a human auditor</b>.*?</div>)#$1\n          <div><b>Last phase ran outside Bob</b><p>Our 40 Bobcoin budget ran out while Penny was writing the final regression test. The trial balance was then run from a script that pastes raw command output into the report, and says so at the top.</p></div>#s' "$HTML"
fi

grep -n "AFTER_TOTAL =" "$JS" | head -1
echo "Done. Your dev server will refresh on its own."
