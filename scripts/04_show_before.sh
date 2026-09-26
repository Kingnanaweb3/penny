#!/usr/bin/env bash
# Rebuilds the original buggy ShopLedger in a temporary folder, in dollars,
# and runs its tests and reconciliation. Use it to record the "before" shot.
# Your repo is not touched.
set -euo pipefail

P1=$(git log --format=%H --grep="Penny P1" -n 1 || true)
if [ -n "$P1" ]; then
  BASE="${P1}^"
else
  BASE="e182a1b"
fi

TMP="$(mktemp -d)"
git archive "$BASE" sample-app | tar -x -C "$TMP"
bash scripts/03_switch_to_usd.sh "$TMP" > /dev/null

cd "$TMP/sample-app"
npm test --silent
npm run simulate --silent
