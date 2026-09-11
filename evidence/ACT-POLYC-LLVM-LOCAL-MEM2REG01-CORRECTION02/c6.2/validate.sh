#!/bin/sh
# evidence/.../c6.2/validate.sh - re-runs capture.sh and proves
# the verdict channel is real.
#
# Three required proofs:
#   1. all-good geometry: capture.sh rc = 0
#   2. seeded bad geometry: capture.sh self-test branch proves
#      validate_row() emits FAIL when given a pre_rc != 0 row.
#   3. injected bad geometry: capture.sh C6_2_NEG_TEST branch
#      forces every row to be FAIL (via C6_2_FORCE_FAIL sentinel
#      inside capture_one) and proves the script exits non-zero.
#
# We do NOT corrupt production fixtures. The C6_2_FORCE_FAIL
# sentinel is the ONLY path that forces a row to be FAIL.
# All row criteria in c6.1 are preserved unchanged.

set -eu

REPO=/Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc
CAPTURE=$REPO/evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02/c6.2/capture.sh

echo '=== proof 1: all-good geometry ==='
if "$CAPTURE" >/tmp/c6.2/validate.allgood.out 2>&1; then
    allgood_rc=0
else
    allgood_rc=$?
fi
echo "capture.sh rc = $allgood_rc"
tail -2 /tmp/c6.2/validate.allgood.out

echo
echo '=== proof 2: seeded-failure self-test branch ==='
if C6_2_SELF_TEST=1 "$CAPTURE" >/tmp/c6.2/validate.selftest.out 2>&1; then
    selftest_rc=0
else
    selftest_rc=$?
fi
echo "capture.sh (self-test mode) rc = $selftest_rc"
cat /tmp/c6.2/validate.selftest.out

echo
echo '=== proof 3: injected FAIL row (neg-test) ==='
if C6_2_NEG_TEST=1 "$CAPTURE" >/tmp/c6.2/validate.neg.out 2>&1; then
    neg_rc=0
else
    neg_rc=$?
fi
echo "capture.sh (neg-test mode) rc = $neg_rc"
tail -3 /tmp/c6.2/validate.neg.out

echo
echo '=== proof 4: exit-predicate audit ==='
if grep -qE '\[ "\$FAIL" -eq 0 \]' "$CAPTURE"; then
    echo "found: [ \"\$FAIL\" -eq 0 ]"
    audit_rc=0
else
    echo "audit: FAIL - capture.sh does NOT gate exit on FAIL"
    audit_rc=1
fi

echo
echo '=== verdict channel proof ==='
verdict="verdict channel: "
ok=1
if [ "$allgood_rc" -ne 0 ]; then verdict="$verdict all-good rc=$allgood_rc BAD;"; ok=0; fi
if [ "$selftest_rc" -ne 0 ]; then verdict="$verdict self-test rc=$selftest_rc BAD;"; ok=0; fi
if [ "$neg_rc" -eq 0 ]; then verdict="$verdict neg-test rc=0 BAD (FAIL row did not propagate);"; ok=0; fi
if [ "$audit_rc" -ne 0 ]; then verdict="$verdict audit rc=$audit_rc BAD;"; ok=0; fi
if [ "$ok" -eq 1 ]; then
    verdict="$verdict real"
    echo "$verdict"
    echo "false-green possible = NO"
    exit 0
else
    echo "$verdict"
    exit 1
fi
