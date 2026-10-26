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
#
# ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01 additions:
#
#   T35  valid HALT_CLASS=GOVERNANCE + BLOCKS_NEXT=NO PASS
#   T36  valid HALT_CLASS=PRODUCTION + BLOCKS_NEXT=YES PASS
#   T37  HALT without HALT_CLASS                      FAIL
#   T38  HALT without BLOCKS_NEXT                     FAIL
#   T39  duplicate HALT_CLASS                         FAIL
#   T40  duplicate BLOCKS_NEXT                        FAIL
#   T41  invalid HALT_CLASS enum                      FAIL
#   T42  GOVERNANCE with BLOCKS_NEXT=YES              FAIL
#   T43  PASS CLOSE carrying HALT-only fields         FAIL
#   T44  ACT footer git cannot parse -> NOT NON_ACT   FAIL
#   T45  ordinary non-ACT commit                      PASS
#   T46  literal "ACT:" in ordinary prose             PASS (NON_ACT)
#   T47  split ACT trailer block                      FAIL
#   T48  valid HALT lifecycle range                   PASS
#   T49  HALT CLOSE then same-ACT continuation        FAIL
#   T50  HALT CLOSE, ordinary commit, same-ACT cont.  FAIL
#   T51  historical invalid topology stays invalid    FAIL
#   T52  existing valid PASS lifecycle                PASS
#
# Every negative case asserts the nonzero return code AND the
# MODE=ACT / STATUS=FAIL classification, so an intentionally malformed
# fixture cannot pass because of an unrelated setup error.

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

# ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01 C2.
#
# Strict rejection assertion: the message must be REJECTED (nonzero rc)
# AND classified as MODE=ACT / STATUS=FAIL. A mere nonzero rc is not
# enough -- the validator must have recognised the message as ACT
# metadata and rejected it on the ACT grammar, not on some unrelated
# setup error.
#
# Usage: expect_act_fail <name> [expected-reason-substring]
expect_act_fail() {
    name="$1"; want_reason="$2"
    set +e
    out=$(sh "$MSG_CHECK" "$TMPROOT/msg-$name.txt" 2>&1); rc=$?
    set -e
    if [ "$rc" = "0" ]; then
        echo "  FAIL  $name  expected reject, got rc=0 out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
        return
    fi
    if ! printf '%s\n' "$out" | grep -q '^MODE=ACT$'; then
        echo "  FAIL  $name  rejected but not MODE=ACT: out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
        return
    fi
    if ! printf '%s\n' "$out" | grep -q '^STATUS=FAIL$'; then
        echo "  FAIL  $name  rejected but not STATUS=FAIL: out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
        return
    fi
    if [ -n "$want_reason" ] \
        && ! printf '%s\n' "$out" | grep -qF "$want_reason"; then
        echo "  FAIL  $name  wrong reason; wanted '$want_reason': out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
        return
    fi
    echo "  PASS  $name  (rejected as expected)"
    PASS_COUNT=$((PASS_COUNT+1))
}

# Strict acceptance assertion for the commit-message validator: rc=0
# AND MODE=ACT AND STATUS=PASS.
expect_act_pass() {
    name="$1"; want="$2"
    set +e
    out=$(sh "$MSG_CHECK" "$TMPROOT/msg-$name.txt" 2>&1); rc=$?
    set -e
    if [ "$rc" != "0" ]; then
        echo "  FAIL  $name  expected pass, got rc=$rc out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
        return
    fi
    if ! printf '%s\n' "$out" | grep -q '^MODE=ACT$'; then
        echo "  FAIL  $name  expected MODE=ACT: out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
        return
    fi
    if ! printf '%s\n' "$out" | grep -q '^STATUS=PASS$'; then
        echo "  FAIL  $name  expected STATUS=PASS: out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
        return
    fi
    if [ -n "$want" ] && ! printf '%s\n' "$out" | grep -qF "$want"; then
        echo "  FAIL  $name  expected field '$want': out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
        return
    fi
    echo "  PASS  $name"
    PASS_COUNT=$((PASS_COUNT+1))
}

# Strict NON_ACT acceptance assertion: rc=0 AND MODE=NON_ACT.
expect_non_act_pass() {
    name="$1"
    set +e
    out=$(sh "$MSG_CHECK" "$TMPROOT/msg-$name.txt" 2>&1); rc=$?
    set -e
    if [ "$rc" != "0" ]; then
        echo "  FAIL  $name  expected pass, got rc=$rc out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
        return
    fi
    if ! printf '%s\n' "$out" | grep -q '^MODE=NON_ACT$'; then
        echo "  FAIL  $name  expected MODE=NON_ACT: out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
        return
    fi
    echo "  PASS  $name"
    PASS_COUNT=$((PASS_COUNT+1))
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

# ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01 C2.
#
# Build an ACT commit whose footer carries extra trailer lines
# (e.g. HALT_CLASS / BLOCKS_NEXT). `extra` is appended verbatim to the
# trailer block.
synth_act_commit_with_trailers() {
    id="$1"; phase="$2"; verdict="$3"; label="$4"; extra="$5"
    cd "$SYNTH/$id"
    echo "$label" > "$label.txt"
    git add "$label.txt"
    if [ "$phase" = "CLOSE" ] && [ -n "$verdict" ]; then
        git -c core.hooksPath=/dev/null commit -q -m "$(cat <<MSG
$label: $phase

ACT: $id
ACT-Phase: $phase
ACT-Verdict: $verdict
$extra
MSG
)"
    else
        git -c core.hooksPath=/dev/null commit -q -m "$(cat <<MSG
$label: $phase

ACT: $id
ACT-Phase: $phase
$extra
MSG
)"
    fi
}

# Build a plain (non-ACT) commit with no ACT trailer at all.
synth_ordinary_commit() {
    id="$1"; label="$2"
    cd "$SYNTH/$id"
    echo "$label" > "$label.txt"
    git add "$label.txt"
    git -c core.hooksPath=/dev/null commit -q -m "$label"
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

# ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01 C2.
#
# T7 is a CONFORMING HALT_* CLOSE. docs/factory/GIT-METADATA.md
# section 2.4 requires exactly one HALT_CLASS and exactly one BLOCKS_NEXT
# on every HALT_* CLOSE commit, so the fixture carries them. The
# authoritative PolyC classifier
# (tools/factory/factory-halt-classification.HC) rejects a HALT_* CLOSE
# without them (REASON=HALT_CLASS count=0, expected 1 for HALT verdict),
# and the two shell validators now agree with it. The REJECT case for a
# HALT_* CLOSE without HALT_CLASS is covered separately as T37.
mkmsg T7 "docs(polyc): halt" "valid HALT closure" \
         "ACT: ACT-POLYC-TEST01
ACT-Phase: CLOSE
ACT-Verdict: HALT_RED_NOT_REPRODUCED
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO"
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

# ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01 C2: a conforming HALT_*
# CLOSE carries the mandatory HALT_CLASS / BLOCKS_NEXT trailers
# (docs/factory/GIT-METADATA.md section 2.4). The authoritative PolyC
# classifier rejects the non-conforming form; see T7's note.
mkmsg T32 "docs: close halt" "HALT verdict" \
         "ACT: ACT-POLYC-GRAMMAR-CHECK
ACT-Phase: CLOSE
ACT-Verdict: HALT_RED_NOT_REPRODUCED
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO"
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
echo "--- T35-T47 ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01 commit-msg matrix ---"

# T35: valid HALT_CLASS=GOVERNANCE + BLOCKS_NEXT=NO
mkmsg T35 "docs: close governance halt" "valid HALT closure" \
         "ACT: ACT-POLYC-HALTCLASS01
ACT-Phase: CLOSE
ACT-Verdict: HALT_GOVERNANCE_HALT
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO"
expect_act_pass T35 "HALT_CLASS=GOVERNANCE"

# T36: valid HALT_CLASS=PRODUCTION + BLOCKS_NEXT=YES
mkmsg T36 "docs: close production halt" "valid HALT closure" \
         "ACT: ACT-POLYC-HALTCLASS01
ACT-Phase: CLOSE
ACT-Verdict: HALT_PRODUCTION_DEFECT
HALT_CLASS: PRODUCTION
BLOCKS_NEXT: YES"
expect_act_pass T36 "BLOCKS_NEXT=YES"

# T37: HALT without HALT_CLASS
mkmsg T37 "docs: halt missing class" "HALT needs HALT_CLASS" \
         "ACT: ACT-POLYC-HALTCLASS01
ACT-Phase: CLOSE
ACT-Verdict: HALT_RED_NOT_REPRODUCED
BLOCKS_NEXT: NO"
expect_act_fail T37 "HALT_CLASS count=0"

# T38: HALT without BLOCKS_NEXT
mkmsg T38 "docs: halt missing blocks" "HALT needs BLOCKS_NEXT" \
         "ACT: ACT-POLYC-HALTCLASS01
ACT-Phase: CLOSE
ACT-Verdict: HALT_RED_NOT_REPRODUCED
HALT_CLASS: GOVERNANCE"
expect_act_fail T38 "BLOCKS_NEXT count=0"

# T39: duplicate HALT_CLASS
mkmsg T39 "docs: dup class" "duplicate HALT_CLASS" \
         "ACT: ACT-POLYC-HALTCLASS01
ACT-Phase: CLOSE
ACT-Verdict: HALT_RED_NOT_REPRODUCED
HALT_CLASS: GOVERNANCE
HALT_CLASS: PRODUCTION
BLOCKS_NEXT: NO"
expect_act_fail T39 "HALT_CLASS count=2"

# T40: duplicate BLOCKS_NEXT
mkmsg T40 "docs: dup blocks" "duplicate BLOCKS_NEXT" \
         "ACT: ACT-POLYC-HALTCLASS01
ACT-Phase: CLOSE
ACT-Verdict: HALT_RED_NOT_REPRODUCED
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO
BLOCKS_NEXT: YES"
expect_act_fail T40 "BLOCKS_NEXT count=2"

# T41: invalid classification enum
mkmsg T41 "docs: bad class" "invalid HALT_CLASS enum" \
         "ACT: ACT-POLYC-HALTCLASS01
ACT-Phase: CLOSE
ACT-Verdict: HALT_RED_NOT_REPRODUCED
HALT_CLASS: BOGUS
BLOCKS_NEXT: NO"
expect_act_fail T41 "not in enum"

# T42: GOVERNANCE with BLOCKS_NEXT=YES
mkmsg T42 "docs: bad combination" "GOVERNANCE requires NO" \
         "ACT: ACT-POLYC-HALTCLASS01
ACT-Phase: CLOSE
ACT-Verdict: HALT_RED_NOT_REPRODUCED
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: YES"
expect_act_fail T42 "requires BLOCKS_NEXT=NO"

# T43: PASS CLOSE carrying HALT-only fields
mkmsg T43 "docs: pass with halt fields" "PASS forbids HALT fields" \
         "ACT: ACT-POLYC-HALTCLASS01
ACT-Phase: CLOSE
ACT-Verdict: PASS
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO"
expect_act_fail T43 "PASS verdict forbids HALT_CLASS"

# T44: an ACT-like footer that git cannot parse must NOT be NON_ACT.
# This is the fail-open control. The footer below carries ACT metadata
# and HALT classification trailers whose KEYS ARE MALFORMED ("HALT CLASS"
# and "BLOCKS NEXT" -- a space before the colon). git therefore drops the
# ENTIRE trailer block, so a parser that trusts git's output sees no ACT
# trailer at all. Before the repair that produced MODE=NON_ACT
# STATUS=PASS. The validator must now classify the message as ACT and
# REJECT it, and it must NOT silently correct the malformed lookalike
# into a valid HALT_CLASS (C1 contract P8).
mkmsg T44 "docs: unparseable halt footer" "fail-open control" \
         "ACT: ACT-POLYC-HALTCLASS01
ACT-Phase: CLOSE
ACT-Verdict: HALT_RED_NOT_REPRODUCED
HALT CLASS: GOVERNANCE
BLOCKS NEXT: NO"
expect_act_fail T44 "no parseable ACT trailer"

# T45: ordinary non-ACT commit
mkmsg T45 "feat: ordinary work" "no factory trailers" "Reviewed-by: Someone"
expect_non_act_pass T45

# T46: a literal "ACT:" in ordinary message PROSE is not ACT metadata.
mkmsg T46 "docs: prose mention" "literal ACT in prose" \
         "This commit discusses the ACT: trailer format in prose.
It is not a trailer and must not classify the commit as an ACT."
expect_non_act_pass T46

# T47: split ACT trailer block (ACT / ACT-Phase / ACT-Verdict separated
# by blank lines) is malformed and must be rejected, not partially
# accepted. git itself parses only the LAST fragment, which would yield
# a verdict with no ACT.
{
    printf 'docs: split footer\n\nbody\n\n'
    printf 'ACT: ACT-POLYC-HALTCLASS01\n\n'
    printf 'ACT-Phase: CLOSE\n\n'
    printf 'ACT-Verdict: PASS\n'
} > "$TMPROOT/msg-T47.txt"
expect_act_fail T47 "malformed"

# T52: an existing valid PASS lifecycle still passes.
mkmsg T52 "docs: close pass" "valid PASS closure" \
         "ACT: ACT-POLYC-HALTCLASS01
ACT-Phase: CLOSE
ACT-Verdict: PASS"
expect_act_pass T52 "VERDICT=PASS"

echo
echo "--- T48-T51 ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01 range matrix ---"

# T48: a valid HALT lifecycle range is accepted.
mk_synth_repo ACT-POLYC-RANGE-T48
synth_act_commit ACT-POLYC-RANGE-T48 RED "" a
synth_act_commit ACT-POLYC-RANGE-T48 EVIDENCE "" b
synth_act_commit_with_trailers ACT-POLYC-RANGE-T48 CLOSE \
    HALT_MANDATORY_AC_NOT_GREEN c \
    "HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO"
expect_range_pass T48 ACT-POLYC-RANGE-T48 \
    "$(git -C $SYNTH/ACT-POLYC-RANGE-T48 rev-parse HEAD)"

# T49: a HALT CLOSE followed by a same-ACT continuation is rejected.
mk_synth_repo ACT-POLYC-RANGE-T49
synth_act_commit ACT-POLYC-RANGE-T49 RED "" a
synth_act_commit_with_trailers ACT-POLYC-RANGE-T49 CLOSE \
    HALT_MANDATORY_AC_NOT_GREEN b \
    "HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO"
T49_CLOSE=$(git -C $SYNTH/ACT-POLYC-RANGE-T49 rev-parse HEAD)
synth_act_commit ACT-POLYC-RANGE-T49 IMPL "" c
expect_range_fail T49 ACT-POLYC-RANGE-T49 "$T49_CLOSE"

# T50: a HALT CLOSE, an ORDINARY commit, then a same-ACT continuation.
# The intervening ordinary commit must NOT hide the continuation.
mk_synth_repo ACT-POLYC-RANGE-T50
synth_act_commit ACT-POLYC-RANGE-T50 RED "" a
synth_act_commit_with_trailers ACT-POLYC-RANGE-T50 CLOSE \
    HALT_MANDATORY_AC_NOT_GREEN b \
    "HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO"
T50_CLOSE=$(git -C $SYNTH/ACT-POLYC-RANGE-T50 rev-parse HEAD)
synth_ordinary_commit ACT-POLYC-RANGE-T50 unrelated
synth_act_commit ACT-POLYC-RANGE-T50 IMPL "" c
expect_range_fail T50 ACT-POLYC-RANGE-T50 "$T50_CLOSE"

# T51: a historical invalid topology stays invalid. The predecessor
# BOOTSTRAP-BUILD01 committed a same-ACT EVIDENCE commit AFTER its C4
# CLOSE. That historical violation must remain rejected; a newly
# working parser must not retroactively legitimise it.
if [ -d "$REPO_ROOT/.git" ]; then
    cd "$REPO_ROOT"
    set +e
    out=$(sh "$RANGE_CHECK" \
        ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 \
        290d9170555d0b071db5ac4ab163d1176c71aa00 2>&1); rc=$?
    set -e
    if [ "$rc" != "0" ] \
        && printf '%s\n' "$out" | grep -q 'must not continue past CLOSE'; then
        echo "  PASS  T51  (historical invalid topology still rejected)"
        PASS_COUNT=$((PASS_COUNT+1))
    else
        echo "  FAIL  T51  expected historical rejection, got rc=$rc out=$out"
        FAIL_COUNT=$((FAIL_COUNT+1))
    fi
else
    echo "  FAIL  T51  repository not found for the historical control"
    FAIL_COUNT=$((FAIL_COUNT+1))
fi

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
