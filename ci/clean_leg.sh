#!/usr/bin/env bash
# Clean leg: the clean/ twin must pass (rc == 0) and no INVARIANT
# VIOLATED marker may appear anywhere in the output.
set -uo pipefail

cd clean
out=$(forge test -vv 2>&1)
rc=$?
echo "$out"

if [ $rc -ne 0 ]; then
  echo "clean-passes: FAIL (forge test rc=$rc)"
  exit 1
fi
if grep -q "INVARIANT VIOLATED" <<<"$out"; then
  echo "clean-passes: FAIL (marker printed on the clean leg)"
  exit 1
fi
echo "clean-passes: OK"
