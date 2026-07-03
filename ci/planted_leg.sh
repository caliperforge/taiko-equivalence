#!/usr/bin/env bash
# Planted leg, INVERTED assertion: the planted/ twin must FAIL its
# forge run (rc != 0) AND print at least one `INVARIANT VIOLATED <case>`
# marker. The job is green exactly when the planted breaks are caught;
# the markers are copied into the GitHub job summary so a reviewer
# clicking the job sees each catch.
set -uo pipefail

summary="${GITHUB_STEP_SUMMARY:-/dev/null}"

cd planted
out=$(forge test -vv 2>&1)
rc=$?
echo "$out"

markers=$(grep "INVARIANT VIOLATED" <<<"$out" | sed 's/^[[:space:]]*//' | sort -u)

if [ $rc -eq 0 ]; then
  echo "planted-bug-twin-fails: FAIL (planted twin passed, rc=0)"
  exit 1
fi
if [ -z "$markers" ]; then
  echo "planted-bug-twin-fails: FAIL (rc=$rc but no INVARIANT VIOLATED marker)"
  exit 1
fi

{
  echo "## Planted-twin catches"
  echo ""
  echo '```'
  echo "$markers"
  echo '```'
} >>"$summary"

echo "planted-bug-twin-fails: OK (rc=$rc, markers below)"
echo "$markers"
