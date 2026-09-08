#!/bin/sh
# N1..N15 hermetic negative tests for the factory closure-status
# exact-token checker.
#
# Each test creates a sandbox under /tmp with:
#   - a copy of scripts/quality/factory-closure-status-check.sh
#   - a copy of docs/factory/act-handoff-map.tsv (mutated per test)
#   - a fixture ACT and HANDOFF (mutated per test)
# then runs the checker against the sandbox and asserts:
#   defect-introduced   -> checker exits non-zero
#   defect-removed      -> checker exits zero
#
# We construct the sandbox by copying the repo files into a
# temporary location and then editing them in place. This avoids
# polluting the real repo.

set -eu
REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
SCRIPT="$REPO/scripts/quality/factory-closure-status-check.sh"
MANIFEST="$REPO/docs/factory/act-handoff-map.tsv"

# Detect whether we're on bash; the script uses POSIX sh features
# but we need a few bashisms below for $( ... ) and arrays. Try
# bash first; fall back to sh.
if command -v bash >/dev/null 2>&1; then SH=bash; else SH=sh; fi

PASS=0
FAIL=0
FAIL_LIST=""

assert_eq() {
    # assert_eq <name> <expected> <actual>
    if [ "$2" = "$3" ]; then
        echo "  PASS  $1  expected=$2 actual=$3"
        PASS=$((PASS+1))
    else
        echo "  FAIL  $1  expected=$2 actual=$3"
        FAIL=$((FAIL+1))
        FAIL_LIST="$FAIL_LIST $1"
    fi
}

run_checker_in_sandbox() {
    # run_checker_in_sandbox <sandbox_dir>
    # Sets global RC.
    ( cd "$1" && sh scripts/quality/factory-closure-status-check.sh > /tmp/sandbox_checker.out 2>&1 ) && RC=0 || RC=$?
}

make_sandbox() {
    # make_sandbox <name>
    # Returns path via global SANDBOX.
    SANDBOX="/tmp/polyc-n-sandbox-$1-$$"
    rm -rf "$SANDBOX"
    mkdir -p "$SANDBOX"
    mkdir -p "$SANDBOX/scripts/quality"
    mkdir -p "$SANDBOX/docs/factory"
    mkdir -p "$SANDBOX/docs/acts"
    mkdir -p "$SANDBOX/evidence"
    cp "$SCRIPT" "$SANDBOX/scripts/quality/factory-closure-status-check.sh"
    cp "$MANIFEST" "$SANDBOX/docs/factory/act-handoff-map.tsv"
}

write_act() {
    # write_act <sandbox> <relpath> <status_token>
    local sb="$1" rp="$2" tok="$3"
    mkdir -p "$sb/$(dirname "$rp")"
    cat > "$sb/$rp" <<EOF
# ACT for negative test fixture
## Status

$tok
EOF
}

write_handoff() {
    # write_handoff <sandbox> <relpath> <verdict_token>
    local sb="$1" rp="$2" tok="$3"
    mkdir -p "$sb/$(dirname "$rp")"
    cat > "$sb/$rp" <<EOF
HANDOFF fixture
VERDICT
-------
$tok
EOF
}

# Baseline: a valid 1-pair universe should pass.
echo "=== baseline ==="
make_sandbox baseline
write_act "$SANDBOX" docs/acts/ACT-POLYC-N-BASE.md PASS
write_handoff "$SANDBOX" evidence/n-base/HANDOFF.md PASS
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-N-BASE.md	evidence/n-base/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "baseline-PASS" 0 "$RC"
rm -rf "$SANDBOX"

# N1 — missing ACT file: manifest row points to a non-existent ACT.
echo "=== N1 missing ACT file ==="
make_sandbox n1
write_handoff "$SANDBOX" evidence/n1/HANDOFF.md OPEN
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-N1.md	evidence/n1/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N1-MISSING_ACT_FAIL" 1 "$RC"
grep -q MISSING_ACT_FILE /tmp/sandbox_checker.out && assert_eq "N1-MISSING_ACT_KEYWORD" yes yes || assert_eq "N1-MISSING_ACT_KEYWORD" yes no
rm -rf "$SANDBOX"

# N2 — missing HANDOFF file: ACT present, HANDOFF absent.
echo "=== N2 missing HANDOFF file ==="
make_sandbox n2
write_act "$SANDBOX" docs/acts/ACT-POLYC-N2.md OPEN
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-N2.md	evidence/n2/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N2-MISSING_HANDOFF_FAIL" 1 "$RC"
grep -q MISSING_HANDOFF_FILE /tmp/sandbox_checker.out && assert_eq "N2-MISSING_HANDOFF_KEYWORD" yes yes || assert_eq "N2-MISSING_HANDOFF_KEYWORD" yes no
rm -rf "$SANDBOX"

# N3 — duplicate ACT path in manifest.
echo "=== N3 duplicate ACT path ==="
make_sandbox n3
write_act "$SANDBOX" docs/acts/ACT-POLYC-N3.md OPEN
write_handoff "$SANDBOX" evidence/n3-a/HANDOFF.md OPEN
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-N3.md	evidence/n3-a/HANDOFF.md
docs/acts/ACT-POLYC-N3.md	evidence/n3-b/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N3-DUP_ACT_FAIL" 1 "$RC"
grep -q DUPLICATE_ACT_PATH /tmp/sandbox_checker.out && assert_eq "N3-DUP_ACT_KEYWORD" yes yes || assert_eq "N3-DUP_ACT_KEYWORD" yes no
rm -rf "$SANDBOX"

# N4 — duplicate HANDOFF path in manifest.
echo "=== N4 duplicate HANDOFF path ==="
make_sandbox n4
write_act "$SANDBOX" docs/acts/ACT-POLYC-N4A.md OPEN
write_act "$SANDBOX" docs/acts/ACT-POLYC-N4B.md OPEN
write_handoff "$SANDBOX" evidence/n4/HANDOFF.md OPEN
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-N4A.md	evidence/n4/HANDOFF.md
docs/acts/ACT-POLYC-N4B.md	evidence/n4/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N4-DUP_HANDOFF_FAIL" 1 "$RC"
grep -q DUPLICATE_HANDOFF_PATH /tmp/sandbox_checker.out && assert_eq "N4-DUP_HANDOFF_KEYWORD" yes yes || assert_eq "N4-DUP_HANDOFF_KEYWORD" yes no
rm -rf "$SANDBOX"

# N5 — exact mismatch between ACT and HANDOFF.
echo "=== N5 exact mismatch ==="
make_sandbox n5
write_act "$SANDBOX" docs/acts/ACT-POLYC-N5.md HALT_FACTORY_N5
write_handoff "$SANDBOX" evidence/n5/HANDOFF.md PASS
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-N5.md	evidence/n5/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N5-MISMATCH_FAIL" 1 "$RC"
grep -q EXACT_VERDICT_MISMATCHES=1 /tmp/sandbox_checker.out && assert_eq "N5-MISMATCH_COUNT" yes yes || assert_eq "N5-MISMATCH_COUNT" yes no
rm -rf "$SANDBOX"

# N6 — malformed ACT token (lowercase).
echo "=== N6 malformed ACT token (lowercase) ==="
make_sandbox n6
write_act "$SANDBOX" docs/acts/ACT-POLYC-N6.md halt_factory_n6
write_handoff "$SANDBOX" evidence/n6/HANDOFF.md halt_factory_n6
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-N6.md	evidence/n6/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N6-MALFORMED_TOKEN_FAIL" 1 "$RC"
grep -q MALFORMED_ACT_TOKEN /tmp/sandbox_checker.out && assert_eq "N6-MALFORMED_KEYWORD" yes yes || assert_eq "N6-MALFORMED_KEYWORD" yes no
rm -rf "$SANDBOX"

# N7 — missing ## Status heading in ACT.
echo "=== N7 missing ## Status heading ==="
make_sandbox n7
mkdir -p "$SANDBOX/docs/acts"
cat > "$SANDBOX/docs/acts/ACT-POLYC-N7.md" <<EOF
# ACT for negative test fixture
## Goal
There is intentionally no ## Status heading here.
EOF
write_handoff "$SANDBOX" evidence/n7/HANDOFF.md OPEN
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-N7.md	evidence/n7/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N7-MISSING_STATUS_FAIL" 1 "$RC"
grep -q MALFORMED_ACT_STATUS /tmp/sandbox_checker.out && assert_eq "N7-MISSING_STATUS_KEYWORD" yes yes || assert_eq "N7-MISSING_STATUS_KEYWORD" yes no
rm -rf "$SANDBOX"

# N8 — duplicated ## Status heading in ACT.
echo "=== N8 duplicated ## Status heading ==="
make_sandbox n8
mkdir -p "$SANDBOX/docs/acts"
cat > "$SANDBOX/docs/acts/ACT-POLYC-N8.md" <<EOF
# ACT for negative test fixture
## Status

PASS

## Status

PASS
EOF
write_handoff "$SANDBOX" evidence/n8/HANDOFF.md PASS
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-N8.md	evidence/n8/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N8-DUP_STATUS_FAIL" 1 "$RC"
grep -q MALFORMED_ACT_STATUS /tmp/sandbox_checker.out && assert_eq "N8-DUP_STATUS_KEYWORD" yes yes || assert_eq "N8-DUP_STATUS_KEYWORD" yes no
rm -rf "$SANDBOX"

# N9 — duplicated VERDICT section in HANDOFF.
echo "=== N9 duplicated VERDICT ==="
make_sandbox n9
write_act "$SANDBOX" docs/acts/ACT-POLYC-N9.md PASS
mkdir -p "$SANDBOX/evidence/n9"
cat > "$SANDBOX/evidence/n9/HANDOFF.md" <<EOF
HANDOFF fixture
VERDICT
-------
PASS

VERDICT
-------
PASS
EOF
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-N9.md	evidence/n9/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N9-DUP_VERDICT_FAIL" 1 "$RC"
grep -q MALFORMED_HANDOFF_VERDICT /tmp/sandbox_checker.out && assert_eq "N9-DUP_VERDICT_KEYWORD" yes yes || assert_eq "N9-DUP_VERDICT_KEYWORD" yes no
rm -rf "$SANDBOX"

# N10 — manifest line with empty HANDOFF path.
echo "=== N10 manifest parse error ==="
make_sandbox n10
write_act "$SANDBOX" docs/acts/ACT-POLYC-N10.md OPEN
write_handoff "$SANDBOX" evidence/n10/HANDOFF.md OPEN
# A manifest row with no second field
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-N10.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N10-PARSE_FAIL" 1 "$RC"
grep -q MANIFEST_PARSE_ERRORS /tmp/sandbox_checker.out && assert_eq "N10-PARSE_KEYWORD" yes yes || assert_eq "N10-PARSE_KEYWORD" yes no
rm -rf "$SANDBOX"

# N11 — manifest pointing at a non-inferred path (RED-3A1 reversed:
# the manifest now binds a previously invisible pair; checker must
# succeed when the metadata agrees and FAIL when it disagrees).
echo "=== N11 manifest binds non-inferred path ==="
make_sandbox n11
write_act "$SANDBOX" docs/acts/ACT-POLYC-N11.md HALT_N11
write_handoff "$SANDBOX" evidence/some/custom/path/HANDOFF.md HALT_N11
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-N11.md	evidence/some/custom/path/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N11-NON_INFERRED_PASS" 0 "$RC"
# Now break it
echo "HALT_N11" > "$SANDBOX/docs/acts/ACT-POLYC-N11.md.tmp"
cat > "$SANDBOX/docs/acts/ACT-POLYC-N11.md" <<EOF
# ACT for negative test fixture
## Status

HALT_N11_OTHER
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N11-NON_INFERRED_FAIL" 1 "$RC"
rm -rf "$SANDBOX"

# N12 — manifest row removed (RED-3A3): even if both files exist,
# the manifest must enumerate them.
echo "=== N12 manifest row removed ==="
make_sandbox n12
write_act "$SANDBOX" docs/acts/ACT-POLYC-N12.md OPEN
write_handoff "$SANDBOX" evidence/n12/HANDOFF.md OPEN
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
# manifest intentionally empty for N12
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N12-EMPTY_MANIFEST_FAIL" 1 "$RC"
grep -q MANIFEST_ROWS=0 /tmp/sandbox_checker.out && assert_eq "N12-MANIFEST_ROWS_0" yes yes || assert_eq "N12-MANIFEST_ROWS_0" yes no
rm -rf "$SANDBOX"

# N13 — manifest present but binder is missing the HANDOFF.
echo "=== N13 binder missing HANDOFF ==="
make_sandbox n13
write_act "$SANDBOX" docs/acts/ACT-POLYC-N13.md OPEN
# No HANDOFF written
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-N13.md	evidence/n13/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N13-MISSING_HANDOFF_FAIL" 1 "$RC"
grep -q MISSING_HANDOFF_FILE /tmp/sandbox_checker.out && assert_eq "N13-MISSING_HANDOFF_KEYWORD" yes yes || assert_eq "N13-MISSING_HANDOFF_KEYWORD" yes no
rm -rf "$SANDBOX"

# N14 — PASS != PASS_WITH_NEXT_ACT_DECISION: ensures the lossy
# normalization bug does not return via PASS-qualifier collision.
echo "=== N14 PASS vs PASS_WITH_NEXT_ACT_DECISION ==="
make_sandbox n14
write_act "$SANDBOX" docs/acts/ACT-POLYC-N14.md PASS
write_handoff "$SANDBOX" evidence/n14/HANDOFF.md PASS_WITH_NEXT_ACT_DECISION
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-N14.md	evidence/n14/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N14-PASS_QUALIFIER_FAIL" 1 "$RC"
grep -q EXACT_VERDICT_MISMATCHES=1 /tmp/sandbox_checker.out && assert_eq "N14-PASS_QUALIFIER_MISMATCH" yes yes || assert_eq "N14-PASS_QUALIFIER_MISMATCH" yes no
rm -rf "$SANDBOX"

# N15 — full real-tree PASS with corrected HANDOFFs (positive test
# mirroring the post-reconciliation real-tree state).
echo "=== N15 full real-tree mirror PASS ==="
make_sandbox n15
write_act "$SANDBOX" docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md HALT_TOPOLOGY_RECORDED
write_act "$SANDBOX" docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md HALT_SCOPE_CONTRACT_VIOLATED
write_act "$SANDBOX" docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md HALT_CORRECTION03_WIRE_AND_IDENTITY_CONTRACT
write_act "$SANDBOX" docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION04.md HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE
write_act "$SANDBOX" docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION05.md HALT_CORRECTION05_OWN_GATE_RED
write_handoff "$SANDBOX" evidence/llvmspike01-core03-correction01/HANDOFF.md HALT_TOPOLOGY_RECORDED
write_handoff "$SANDBOX" evidence/llvmspike01-core03-correction02/HANDOFF.md HALT_SCOPE_CONTRACT_VIOLATED
write_handoff "$SANDBOX" evidence/llvmspike01-core03-correction03/HANDOFF.md HALT_CORRECTION03_WIRE_AND_IDENTITY_CONTRACT
write_handoff "$SANDBOX" evidence/llvmspike01-core03-correction04/HANDOFF.md HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE
write_handoff "$SANDBOX" evidence/llvmspike01-core03-correction05/HANDOFF.md HALT_CORRECTION05_OWN_GATE_RED
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md	evidence/llvmspike01-core03-correction02/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md	evidence/llvmspike01-core03-correction03/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION04.md	evidence/llvmspike01-core03-correction04/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION05.md	evidence/llvmspike01-core03-correction05/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N15-FULL_PASS" 0 "$RC"
grep -q PAIR_OK=5 /tmp/sandbox_checker.out && assert_eq "N15-PAIR_OK_5" yes yes || assert_eq "N15-PAIR_OK_5" yes no
grep -q PAIR_FAIL=0 /tmp/sandbox_checker.out && assert_eq "N15-PAIR_FAIL_0" yes yes || assert_eq "N15-PAIR_FAIL_0" yes no
rm -rf "$SANDBOX"

echo
echo "=== SUMMARY ==="
echo "PASS=$PASS  FAIL=$FAIL"
[ -n "$FAIL_LIST" ] && echo "FAILING:$FAIL_LIST"
[ "$FAIL" -eq 0 ]
