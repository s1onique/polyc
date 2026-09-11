#!/bin/sh
# evidence/.../c6.3/validate.sh - re-runs capture.sh and proves
# the verdict channel is real.
#
# Required proofs:
#   1. all-good geometry: capture.sh rc = 0 (all 7 rows PASS)
#   2. seeded bad geometry (pre): capture.sh self-test branch proves
#      validate_row() emits FAIL when given a pre_rc != 0 row.
#   3. injected bad geometry: capture.sh C6_2_NEG_TEST branch
#      forces every row to be FAIL (via C6_2_FORCE_FAIL sentinel
#      inside capture_one) and proves the script exits non-zero.
#   4. seeded idem-failure (NEW IN C6.3): capture.sh C6_3_IDEM_TEST
#      branch proves that an idem_rc != 0 metric, with all other
#      criteria good, causes validate_row() to emit FAIL. This is
#      the exact c6.2 false-GREEN path that c6.3 corrects.
#   5. exit-predicate audit: capture.sh source contains
#      [ "$FAIL" -eq 0 ] gate.
#
# We do NOT corrupt production fixtures. The C6_2_FORCE_FAIL sentinel
# is the ONLY path that forces a row to be FAIL in the injected test.
# The seeded tests invoke validate_row() directly with hand-crafted
# metrics. All row criteria in c6.2 are preserved; idem_rc is now a
# mandatory fail criterion.

set -eu

REPO=/Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc
CAPTURE=$REPO/evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02/c6.3/capture.sh

echo '=== proof 1: all-good geometry ==='
if "$CAPTURE" >/tmp/c6.3/validate.allgood.out 2>&1; then
    allgood_rc=0
else
    allgood_rc=$?
fi
echo "capture.sh rc = $allgood_rc"
tail -2 /tmp/c6.3/validate.allgood.out

echo
echo '=== proof 2: seeded-failure self-test branch (pre_rc) ==='
if C6_2_SELF_TEST=1 "$CAPTURE" >/tmp/c6.3/validate.selftest.out 2>&1; then
    selftest_rc=0
else
    selftest_rc=$?
fi
echo "capture.sh (self-test mode) rc = $selftest_rc"
cat /tmp/c6.3/validate.selftest.out

echo
echo '=== proof 3: injected FAIL row (neg-test) ==='
if C6_2_NEG_TEST=1 "$CAPTURE" >/tmp/c6.3/validate.neg.out 2>&1; then
    neg_rc=0
else
    neg_rc=$?
fi
echo "capture.sh (neg-test mode) rc = $neg_rc"
tail -3 /tmp/c6.3/validate.neg.out

echo
echo '=== proof 4: seeded idem-failure self-test (c6.3 mandatory) ==='
if C6_3_IDEM_TEST=1 "$CAPTURE" >/tmp/c6.3/validate.idem.out 2>&1; then
    idem_rc=0
else
    idem_rc=$?
fi
echo "capture.sh (idem-self-test mode) rc = $idem_rc"
cat /tmp/c6.3/validate.idem.out

echo
echo '=== proof 5: exit-predicate audit ==='
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
if [ "$idem_rc" -ne 0 ]; then verdict="$verdict idem-self-test rc=$idem_rc BAD (idem_rc !-> FAIL);"; ok=0; fi
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