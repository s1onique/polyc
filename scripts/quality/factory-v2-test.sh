#!/bin/sh
# scripts/quality/factory-v2-test.sh
#
# ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01
#
# Test matrix for Factory v2 tooling.
#
# Exercises the validators against temporary commit-message
# fixtures and a temporary synthetic Git repository. Does NOT
# touch the production repository state.
#
# Matrix (binding per ACT section 12):
#
#   T1   ordinary non-ACT commit message               PASS
#   T2   valid RED                                     PASS
#   T3   RED with verdict                              FAIL
#   T4   CLOSE without verdict                         FAIL
#   T5   valid CLOSE PASS                              PASS
#   T6   valid qualified PASS                          PASS
#   T7   valid HALT                                    PASS
#   T8   duplicate ACT trailer                         FAIL
#   T9   duplicate phase                               FAIL
#   T10  invalid phase                                 FAIL
#   T11  malformed verdict                             FAIL
#   T12  supersedes without corrected verdict          PASS
#   T12b corrected verdict without supersedes          FAIL
#   T13  range RED->IMPL->CLOSE (3 commits)            PASS
#   T14  range RED->IMPL->EVIDENCE->IMPL->CLOSE (5)    PASS
#   T15  first phase not RED                           FAIL
#   T16  ACT ID changes inside range                   FAIL
#   T17  multiple CLOSE commits                        FAIL
#   T18  CLOSE with subsequent same-ACT IMPL           FAIL

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

MSG_CHECK="$SCRIPT_DIR/factory-v2-commit-msg-check.sh"
RANGE_CHECK="$SCRIPT_DIR/factory-v2-range-check.sh"

if [ ! -x "$MSG_CHECK" ] || [ ! -x "$RANGE_CHECK" ]; then
    echo "STATUS=ERROR"
    echo "REASON=validator scripts missing or not executable"
    exit 2
fi

PASS_COUNT=0
FAIL_COUNT=0

TMPROOT=$(mktemp -d -t polyc-v2-tests.XXXXXX)
SYNTH=$(mktemp -d -t polyc-v2-synth.XXXXXX)
trap 'rm -rf "$TMPROOT" "$SYNTH"' EXIT

mkmsg() {
    name="$1"; subject="$2"; body="$3"; trailers="$4"
    {
        printf '%s\n\n%s\n\n%s\n' "$subject" "$body" "$trailers"
    } > "$TMPROOT/msg-$name.txt"
}

expect_pass() {
    name="$1"
    out=$(sh "$MSG_CHECK" "$TMPROOT/msg-$name.txt" 2>&1); rc=$?
    if [ "$rc" = "0" ]; then
        echo "  PASS  $name"
        PASS_COUNT=$((PASS_COUNT+1))
    else
        echo "  FAIL  $name  rc=$rc  out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
    fi
}

expect_fail() {
    name="$1"
    # `set +e` is local to the function in POSIX sh.
    set +e
    out=$(sh "$MSG_CHECK" "$TMPROOT/msg-$name.txt" 2>&1); rc=$?
    set -e
    if [ "$rc" != "0" ]; then
        echo "  PASS  $name  (rejected as expected)"
        PASS_COUNT=$((PASS_COUNT+1))
    else
        echo "  FAIL  $name  expected reject, got rc=0 out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
    fi
}

expect_range_pass() {
    name="$1"; id="$2"; close="$3"
    # Operate from inside the synthetic repo so the range-check
    # sees the synthetic history.
    cd "$SYNTH/$id"
    out=$(sh "$RANGE_CHECK" "$id" "$close" 2>&1); rc=$?
    if [ "$rc" = "0" ]; then
        echo "  PASS  $name  $out"
        PASS_COUNT=$((PASS_COUNT+1))
    else
        echo "  FAIL  $name  rc=$rc  out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
    fi
}

expect_range_fail() {
    name="$1"; id="$2"; close="$3"
    cd "$SYNTH/$id"
    set +e
    out=$(sh "$RANGE_CHECK" "$id" "$close" 2>&1); rc=$?
    set -e
    if [ "$rc" != "0" ]; then
        echo "  PASS  $name  (rejected as expected)"
        PASS_COUNT=$((PASS_COUNT+1))
    else
        echo "  FAIL  $name  expected reject, got rc=0 out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
    fi
}

mk_synth_repo() {
    id="$1"
    rm -rf "$SYNTH/$id"
    mkdir -p "$SYNTH/$id"
    cd "$SYNTH/$id"
    git init -q -b main .
    git config user.name "polyc-v2-test"
    git config user.email "v2-test@polyc.local"
    echo seed > seed.txt
    git add seed.txt
    git -c core.hooksPath=/dev/null commit -q -m "seed commit"
}

# Build a single ACT commit with the given ACT id, phase, and
# optional verdict.
synth_act_commit() {
    id="$1"; phase="$2"; verdict="$3"; label="$4"
    cd "$SYNTH/$id"
    echo "$label" > "$label.txt"
    git add "$label.txt"
    if [ "$phase" = "CLOSE" ] && [ -n "$verdict" ]; then
        git -c core.hooksPath=/dev/null commit -q -m "$(cat <<MSG
$label: $phase

ACT: $id
ACT-Phase: $phase
ACT-Verdict: $verdict
MSG
)"
    else
        git -c core.hooksPath=/dev/null commit -q -m "$(cat <<MSG
$label: $phase

ACT: $id
ACT-Phase: $phase
MSG
)"
    fi
}

# Build a plain (non-ACT) commit used as a context separator
# for T16.
synth_plain_commit() {
    id="$1"; label="$2"; marker_act="$3"
    cd "$SYNTH/$id"
    echo "$label" > "$label.txt"
    git add "$label.txt"
    if [ -n "$marker_act" ]; then
        git -c core.hooksPath=/dev/null commit -q -m "$(cat <<MSG
$label: IMPL but different ACT

ACT: $marker_act
ACT-Phase: IMPL
MSG
)"
    else
        git -c core.hooksPath=/dev/null commit -q -m "$label"
    fi
}

echo "POLYC_GATE=factory-v2-tests"

echo
echo "--- T1-T12 commit-msg matrix ---"

mkmsg T1 "feat: ordinary commit" "no factory v2 trailers" ""
expect_pass T1

mkmsg T2 "test(llvm): expose unsupported pointer lowering" "real RED commit" \
         "ACT: ACT-POLYC-TEST01
ACT-Phase: RED"
expect_pass T2

mkmsg T3 "test(llvm): bad" "RED must not carry verdict" \
         "ACT: ACT-POLYC-TEST01
ACT-Phase: RED
ACT-Verdict: PASS"
expect_fail T3

mkmsg T4 "docs(polyc): incomplete close" "CLOSE needs verdict" \
         "ACT: ACT-POLYC-TEST01
ACT-Phase: CLOSE"
expect_fail T4

mkmsg T5 "docs(polyc): close" "valid PASS closure" \
         "ACT: ACT-POLYC-TEST01
ACT-Phase: CLOSE
ACT-Verdict: PASS"
expect_pass T5

mkmsg T6 "docs(polyc): close" "qualified PASS closure" \
         "ACT: ACT-POLYC-TEST01
ACT-Phase: CLOSE
ACT-Verdict: PASS_WITH_NEXT_ACT_DECISION"
expect_pass T6

mkmsg T7 "docs(polyc): halt" "valid HALT closure" \
         "ACT: ACT-POLYC-TEST01
ACT-Phase: CLOSE
ACT-Verdict: HALT_RED_NOT_REPRODUCED"
expect_pass T7

mkmsg T8 "feat: two ACT trailers" "duplicate ACT" \
         "ACT: ACT-POLYC-TEST01
ACT: ACT-POLYC-TEST02
ACT-Phase: RED"
expect_fail T8

mkmsg T9 "feat: two phases" "duplicate phase" \
         "ACT: ACT-POLYC-TEST01
ACT-Phase: RED
ACT-Phase: IMPL"
expect_fail T9

mkmsg T10 "feat: bad phase" "invalid phase" \
         "ACT: ACT-POLYC-TEST01
ACT-Phase: NOPE"
expect_fail T10

mkmsg T11 "docs(polyc): bad verdict" "malformed verdict" \
         "ACT: ACT-POLYC-TEST01
ACT-Phase: CLOSE
ACT-Verdict: GARBAGE"
expect_fail T11

mkmsg T12 "docs(polyc): supersedes" "supersedes without corrected verdict allowed" \
         "ACT: ACT-POLYC-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: PASS
ACT-Supersedes: ACT-POLYC-ORIGINAL01"
expect_pass T12

mkmsg T12b "docs(polyc): bad correction" "corrected verdict needs supersedes" \
            "ACT: ACT-POLYC-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: PASS
ACT-Corrected-Verdict: HALT_BUG"
expect_fail T12b

echo
echo "--- T13-T18 range-check matrix ---"

# T13: 3-commit RED/IMPL/CLOSE
mk_synth_repo ACT-POLYC-RANGE-T13
synth_act_commit ACT-POLYC-RANGE-T13 RED  "" a
synth_act_commit ACT-POLYC-RANGE-T13 IMPL "" b
synth_act_commit ACT-POLYC-RANGE-T13 CLOSE PASS c
expect_range_pass T13 ACT-POLYC-RANGE-T13 "$(git -C $SYNTH/ACT-POLYC-RANGE-T13 rev-parse HEAD)"

# T14: 5-commit RED/IMPL/EVIDENCE/IMPL/CLOSE
mk_synth_repo ACT-POLYC-RANGE-T14
synth_act_commit ACT-POLYC-RANGE-T14 RED      ""                       a
synth_act_commit ACT-POLYC-RANGE-T14 IMPL     ""                       b
synth_act_commit ACT-POLYC-RANGE-T14 EVIDENCE ""                       c
synth_act_commit ACT-POLYC-RANGE-T14 IMPL     ""                       d
synth_act_commit ACT-POLYC-RANGE-T14 CLOSE    PASS_WITH_NONBLOCKING_RESIDUE e
expect_range_pass T14 ACT-POLYC-RANGE-T14 "$(git -C $SYNTH/ACT-POLYC-RANGE-T14 rev-parse HEAD)"

# T15: first phase not RED
mk_synth_repo ACT-POLYC-RANGE-T15
synth_act_commit ACT-POLYC-RANGE-T15 IMPL "" a
synth_act_commit ACT-POLYC-RANGE-T15 IMPL "" b
synth_act_commit ACT-POLYC-RANGE-T15 CLOSE PASS c
expect_range_fail T15 ACT-POLYC-RANGE-T15 "$(git -C $SYNTH/ACT-POLYC-RANGE-T15 rev-parse HEAD)"

# T16: ACT ID changes inside the range
mk_synth_repo ACT-POLYC-RANGE-T16
synth_act_commit ACT-POLYC-RANGE-T16 RED "" a
synth_plain_commit ACT-POLYC-RANGE-T16 b ACT-POLYC-DIFFERENT-ID
synth_act_commit ACT-POLYC-RANGE-T16 CLOSE PASS c
expect_range_fail T16 ACT-POLYC-RANGE-T16 "$(git -C $SYNTH/ACT-POLYC-RANGE-T16 rev-parse HEAD)"

# T17: two CLOSE commits in the range
mk_synth_repo ACT-POLYC-RANGE-T17
synth_act_commit ACT-POLYC-RANGE-T17 RED   ""    a
synth_act_commit ACT-POLYC-RANGE-T17 CLOSE PASS b
synth_act_commit ACT-POLYC-RANGE-T17 CLOSE PASS c
expect_range_fail T17 ACT-POLYC-RANGE-T17 "$(git -C $SYNTH/ACT-POLYC-RANGE-T17 rev-parse HEAD)"

# T18: CLOSE followed by another IMPL with the same ACT id
mk_synth_repo ACT-POLYC-RANGE-T18
synth_act_commit ACT-POLYC-RANGE-T18 RED   ""    a
synth_act_commit ACT-POLYC-RANGE-T18 IMPL  ""    b
synth_act_commit ACT-POLYC-RANGE-T18 CLOSE PASS c
synth_act_commit ACT-POLYC-RANGE-T18 IMPL  ""    d
expect_range_fail T18 ACT-POLYC-RANGE-T18 "$(git -C $SYNTH/ACT-POLYC-RANGE-T18 rev-parse HEAD~1)"

echo
echo "--- summary ---"
echo "PASS=$PASS_COUNT"
echo "FAIL=$FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "STATUS=FAIL"
    exit 1
fi
echo "STATUS=PASS"
exit 0
