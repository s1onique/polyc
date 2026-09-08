#!/bin/sh
# scripts/quality/factory-v2-test.sh
#
# ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01
# ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01-CORRECTION01
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
#
# CORRECTION01 additions (RED-1..RED-3 grammar binding):
#
#   T19  ACT id with shell-glob chars (AAevil)         FAIL
#   T20  ACT id with slash (AA/BAD)                    FAIL
#   T21  ACT id with whitespace (AA BAD)               FAIL
#   T22  ACT id single-character suffix (A)            FAIL
#   T23  ACT-Verdict with whitespace
#        (PASS WITH NEXT ACT)                          FAIL
#   T24  ACT-Verdict hyphen in segment
#        (PASS_X-bad)                                  FAIL
#   T25  ACT-Verdict slash in segment
#        (HALT_X/bad)                                  FAIL
#   T26  ACT-Corrected-Verdict space
#        (HALT_X bad)                                  FAIL
#   T27  positive boundary ACT-POLYC-A1                PASS
#   T28  positive boundary ACT-POLYC-LLVM-CORE04       PASS
#   T29  positive boundary ACT-POLYC-FOO_BAR-01        PASS
#   T30  positive verdict PASS                         PASS
#   T31  positive verdict
#        PASS_WITH_NEXT_ACT_DECISION                   PASS
#   T32  positive verdict
#        HALT_RED_NOT_REPRODUCED                       PASS
#   T33  range-check: ACT id arg single-char rejected  FAIL
#   T34  range-check: CLOSE with verdict
#        PASS_X-bad rejected                           FAIL

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

# Like expect_range_fail but does not cd into $SYNTH/<id>.
# Used when the test exercises the validator's id-arg grammar
# check and the synth repo path would differ from the id arg.
expect_range_fail_no_cd() {
    name="$1"; id="$2"; close="$3"
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

# --- CORRECTION01: trailer-grammar binding tests ---

# T19: shell-glob-defeating ACT id suffix
mkmsg T19 "feat: glob evil" "RED-1 RED-2 RED-3 negative matrix" \
         "ACT: ACT-POLYC-AAevil
ACT-Phase: RED"
expect_fail T19

# T20: slash in ACT id
mkmsg T20 "feat: slash" "RED-1 shell glob also accepts slashes" \
         "ACT: ACT-POLYC-AA/BAD
ACT-Phase: RED"
expect_fail T20

# T21: whitespace in ACT id (gsub used to silently rewrite)
mkmsg T21 "feat: space in id" "RED-2 gsub would silently PASS this" \
         "ACT: ACT-POLYC-AA BAD
ACT-Phase: RED"
expect_fail T21

# T22: single-character suffix (RED-4 doctrine fix)
mkmsg T22 "feat: one char" "RED-4: regex now uses + not *" \
         "ACT: ACT-POLYC-A
ACT-Phase: RED"
expect_fail T22

# T23: whitespace inside ACT-Verdict (gsub used to silently rewrite)
mkmsg T23 "docs: close spaced" "RED-2 verdict with spaces" \
         "ACT: ACT-POLYC-GRAMMAR-CHECK
ACT-Phase: CLOSE
ACT-Verdict: PASS WITH NEXT ACT"
expect_fail T23

# T24: hyphen inside a verdict segment
mkmsg T24 "docs: close hyphen" "RED-3 verdict glob accepts this" \
         "ACT: ACT-POLYC-GRAMMAR-CHECK
ACT-Phase: CLOSE
ACT-Verdict: PASS_X-bad"
expect_fail T24

# T25: slash inside a verdict segment
mkmsg T25 "docs: close slash" "RED-3 verdict glob accepts this" \
         "ACT: ACT-POLYC-GRAMMAR-CHECK
ACT-Phase: CLOSE
ACT-Verdict: HALT_X/bad"
expect_fail T25

# T26: whitespace inside ACT-Corrected-Verdict
mkmsg T26 "docs: corrected spaced" "RED-3 corrected verdict with space" \
         "ACT: ACT-POLYC-GRAMMAR-CHECK
ACT-Phase: CLOSE
ACT-Verdict: PASS
ACT-Supersedes: ACT-POLYC-ORIG
ACT-Corrected-Verdict: HALT_X bad"
expect_fail T26

# T27-T32: positive boundary cases
mkmsg T27 "feat: A1" "smallest legal ACT id" \
         "ACT: ACT-POLYC-A1
ACT-Phase: RED"
expect_pass T27

mkmsg T28 "feat: LLVM-CORE04" "real-world id shape" \
         "ACT: ACT-POLYC-LLVM-CORE04
ACT-Phase: RED"
expect_pass T28

mkmsg T29 "feat: FOO_BAR-01" "underscore and dash in suffix" \
         "ACT: ACT-POLYC-FOO_BAR-01
ACT-Phase: RED"
expect_pass T29

mkmsg T30 "docs: close bare PASS" "bare PASS verdict" \
         "ACT: ACT-POLYC-GRAMMAR-CHECK
ACT-Phase: CLOSE
ACT-Verdict: PASS"
expect_pass T30

mkmsg T31 "docs: close qualified" "qualified PASS verdict" \
         "ACT: ACT-POLYC-GRAMMAR-CHECK
ACT-Phase: CLOSE
ACT-Verdict: PASS_WITH_NEXT_ACT_DECISION"
expect_pass T31

mkmsg T32 "docs: close halt" "HALT verdict" \
         "ACT: ACT-POLYC-GRAMMAR-CHECK
ACT-Phase: CLOSE
ACT-Verdict: HALT_RED_NOT_REPRODUCED"
expect_pass T32

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

# T33: range-check ACT id arg single-character (RED-4 also applies)
# Use the T13 synth repo as the history to operate on, but pass
# a malformed single-character-suffix id to the range-check so
# the validator must reject it.
cd "$SYNTH/ACT-POLYC-RANGE-T13"
expect_range_fail_no_cd T33 ACT-POLYC-A "$(git rev-parse HEAD)"

# T34: range-check verdict grammar binding.
# Same shape as T13 but verdict contains a hyphen -> rejected.
mk_synth_repo ACT-POLYC-RANGE-T34
synth_act_commit ACT-POLYC-RANGE-T34 RED  "" a
synth_act_commit ACT-POLYC-RANGE-T34 IMPL "" b
synth_act_commit ACT-POLYC-RANGE-T34 CLOSE PASS_X-bad c
expect_range_fail T34 ACT-POLYC-RANGE-T34 "$(git -C $SYNTH/ACT-POLYC-RANGE-T34 rev-parse HEAD)"

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
