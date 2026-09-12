#!/bin/sh
# scripts/quality/factory-halt-classification-test.sh
#
# ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01
#
# Deterministic regression matrix for
# factory-halt-classification-check.sh. Twelve fixtures
# (R1..R12) exercise:
#
#   R1 -- HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO  (PASS)
#   R2 -- HALT_CLASS=PRODUCTION / BLOCKS_NEXT=YES (PASS)
#   R3 -- HALT_* verdict missing HALT_CLASS        (FAIL)
#   R4 -- HALT_* verdict missing BLOCKS_NEXT       (FAIL)
#   R5 -- PASS verdict carrying BLOCKS_NEXT=YES    (FAIL)
#   R6 -- GOVERNANCE / YES combination             (FAIL)
#   R7 -- PRODUCTION / NO combination              (FAIL)
#   R8 -- historical-style PASS commit lacking new
#         trailers (PASS; documents that a PASS
#         commit without the new trailers is still
#         valid -- the verifier's default mode
#         inspects only the named commit and never
#         walks history)
#   R9 -- DEPENDENCY / YES (allowed)
#   R10 -- DEPENDENCY / NO (allowed)
#   R11 -- non-ACT commit (PASS, MODE=NON_ACT)
#   R12 -- RED phase passes through (only CLOSE is
#         bound by the new contract)
#
# Each fixture writes a synthetic commit message to a
# temp file, invokes the verifier, and asserts the
# expected rc.

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
CHECK="$SCRIPT_DIR/factory-halt-classification-check.sh"

if [ ! -x "$CHECK" ]; then
    echo "POLYC_GATE=factory-halt-classification"
    echo "STATUS=ERROR"
    echo "REASON=verifier not executable: $CHECK"
    exit 2
fi

PASS=0
FAIL=0

# fixture NAME EXPECT_RC MSG_TEXT
run_fixture() {
    name="$1"
    want_rc="$2"
    msg="$3"
    tmp=$(mktemp)
    printf '%s\n' "$msg" > "$tmp"
    set +e
    out=$("$CHECK" "$tmp" 2>&1)
    got_rc=$?
    set -e
    rm -f "$tmp"
    got_status=$(printf '%s\n' "$out" | grep -E '^STATUS=' | head -1 | cut -d= -f2-)
    if [ "$got_rc" = "$want_rc" ]; then
        PASS=$((PASS + 1))
        printf '  PASS  %s  (rc=%s status=%s)\n' "$name" "$got_rc" "$got_status"
    else
        FAIL=$((FAIL + 1))
        printf '  FAIL  %s  want rc=%s got rc=%s status=%s\n  %s\n' \
            "$name" "$want_rc" "$got_rc" "$got_status" "$out"
    fi
}

run_fixture 'R1 governance halt, NO block' 0 \
'subject

body

ACT: ACT-POLYC-EXAMPLE01
ACT-Phase: CLOSE
ACT-Verdict: HALT_GOVERNANCE_HALT
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO'

run_fixture 'R2 production halt, YES block' 0 \
'subject

body

ACT: ACT-POLYC-EXAMPLE02
ACT-Phase: CLOSE
ACT-Verdict: HALT_PRODUCTION_DEFECT
HALT_CLASS: PRODUCTION
BLOCKS_NEXT: YES'

run_fixture 'R3 halt missing HALT_CLASS' 1 \
'subject

ACT: ACT-POLYC-EXAMPLE03
ACT-Phase: CLOSE
ACT-Verdict: HALT_X
BLOCKS_NEXT: YES'

run_fixture 'R4 halt missing BLOCKS_NEXT' 1 \
'subject

ACT: ACT-POLYC-EXAMPLE04
ACT-Phase: CLOSE
ACT-Verdict: HALT_X
HALT_CLASS: PRODUCTION'

run_fixture 'R5 PASS verdict with BLOCKS_NEXT' 1 \
'subject

ACT: ACT-POLYC-EXAMPLE05
ACT-Phase: CLOSE
ACT-Verdict: PASS
BLOCKS_NEXT: YES'

run_fixture 'R6 GOVERNANCE/YES rejected' 1 \
'subject

ACT: ACT-POLYC-EXAMPLE06
ACT-Phase: CLOSE
ACT-Verdict: HALT_GOVERNANCE_HALT
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: YES'

run_fixture 'R7 PRODUCTION/NO rejected' 1 \
'subject

ACT: ACT-POLYC-EXAMPLE07
ACT-Phase: CLOSE
ACT-Verdict: HALT_PRODUCTION_DEFECT
HALT_CLASS: PRODUCTION
BLOCKS_NEXT: NO'

run_fixture 'R8 historical-style PASS, no trailers' 0 \
'subject

body

ACT: ACT-POLYC-EXAMPLE08
ACT-Phase: CLOSE
ACT-Verdict: PASS'

run_fixture 'R9 DEPENDENCY/YES allowed' 0 \
'subject

ACT: ACT-POLYC-EXAMPLE09
ACT-Phase: CLOSE
ACT-Verdict: HALT_DEPENDENCY_HALT
HALT_CLASS: DEPENDENCY
BLOCKS_NEXT: YES'

run_fixture 'R10 DEPENDENCY/NO allowed' 0 \
'subject

ACT: ACT-POLYC-EXAMPLE10
ACT-Phase: CLOSE
ACT-Verdict: HALT_DEPENDENCY_HALT
HALT_CLASS: DEPENDENCY
BLOCKS_NEXT: NO'

run_fixture 'R11 non-ACT commit' 0 \
'ordinary commit message

no trailers here'

run_fixture 'R12 RED phase, halt verdict, no trailers' 0 \
'subject

ACT: ACT-POLYC-EXAMPLE12
ACT-Phase: RED
ACT-Verdict: HALT_DRAFT'

echo "--- summary ---"
printf 'PASS=%d\n' "$PASS"
printf 'FAIL=%d\n' "$FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "STATUS=PASS"
    exit 0
fi
echo "STATUS=FAIL"
exit 1
