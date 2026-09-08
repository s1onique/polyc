#!/bin/bash
# N1..N18 hermetic negative tests for the CORRECTION01 factory
# closure-status exact-token checker.
#
# IMPORTANT: this checker now enforces independent bidirectional
# completeness against the bounded managed universe. Every test
# sandbox MUST contain all 5 managed ACT/HANDOFF fixtures (or a
# deliberate subset for completeness tests). Earlier N1..N15
# relied on the predecessor's manifest-only iteration, which has
# been removed (HALT_FACTORY_STATUS_COMPLETENESS_NOT_BOUND).

set -eu
REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
SCRIPT="$REPO/scripts/quality/factory-closure-status-check.sh"
MANIFEST="$REPO/docs/factory/act-handoff-map.tsv"

PASS=0
FAIL=0
FAIL_LIST=""

assert_eq() {
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
    ( cd "$1" && sh scripts/quality/factory-closure-status-check.sh > /tmp/sandbox_checker.out 2>&1 ) && RC=0 || RC=$?
}

make_sandbox() {
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

seed_managed_universe() {
    local sb="$1"
    write_act "$sb" docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md HALT_TOPOLOGY_RECORDED
    write_act "$sb" docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md HALT_SCOPE_CONTRACT_VIOLATED
    write_act "$sb" docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md HALT_CORRECTION03_WIRE_AND_IDENTITY_CONTRACT
    write_act "$sb" docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION04.md HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE
    write_act "$sb" docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION05.md HALT_CORRECTION05_OWN_GATE_RED
    write_handoff "$sb" evidence/llvmspike01-core03-correction01/HANDOFF.md HALT_TOPOLOGY_RECORDED
    write_handoff "$sb" evidence/llvmspike01-core03-correction02/HANDOFF.md HALT_SCOPE_CONTRACT_VIOLATED
    write_handoff "$sb" evidence/llvmspike01-core03-correction03/HANDOFF.md HALT_CORRECTION03_WIRE_AND_IDENTITY_CONTRACT
    write_handoff "$sb" evidence/llvmspike01-core03-correction04/HANDOFF.md HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE
    write_handoff "$sb" evidence/llvmspike01-core03-correction05/HANDOFF.md HALT_CORRECTION05_OWN_GATE_RED
    cat > "$sb/docs/factory/act-handoff-map.tsv" <<MANIFEST_EOF
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md	evidence/llvmspike01-core03-correction02/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md	evidence/llvmspike01-core03-correction03/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION04.md	evidence/llvmspike01-core03-correction04/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION05.md	evidence/llvmspike01-core03-correction05/HANDOFF.md
MANIFEST_EOF
}

write_act() {
    local sb="$1" rp="$2" tok="$3"
    mkdir -p "$sb/$(dirname "$rp")"
    cat > "$sb/$rp" <<EOF
# ACT for negative test fixture
## Status

$tok
EOF
}

write_handoff() {
    local sb="$1" rp="$2" tok="$3"
    mkdir -p "$sb/$(dirname "$rp")"
    cat > "$sb/$rp" <<EOF
HANDOFF fixture
VERDICT
-------
$tok
EOF
}

write_act_extra_metadata() {
    local sb="$1" rp="$2" tok="$3"
    mkdir -p "$sb/$(dirname "$rp")"
    cat > "$sb/$rp" <<EOF
# ACT for negative test fixture (extra ## Status block)
## Status

$tok

## Status

$tok
EOF
}

write_handoff_extra_metadata() {
    local sb="$1" rp="$2" tok="$3"
    mkdir -p "$sb/$(dirname "$rp")"
    cat > "$sb/$rp" <<EOF
HANDOFF fixture (extra VERDICT block)
VERDICT
-------
$tok

VERDICT
-------
$tok
EOF
}

echo "=== baseline ==="
make_sandbox baseline
seed_managed_universe "$SANDBOX"
run_checker_in_sandbox "$SANDBOX"
assert_eq "baseline-PASS" 0 "$RC"
grep -q PAIR_OK=5 /tmp/sandbox_checker.out && assert_eq "baseline-PAIR_OK_5" yes yes || assert_eq "baseline-PAIR_OK_5" yes no
rm -rf "$SANDBOX"

echo "=== N1 empty manifest ==="
make_sandbox n1
seed_managed_universe "$SANDBOX"
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
# intentionally empty
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N1-EMPTY_MANIFEST_FAIL" 1 "$RC"
grep -q MANIFEST_ROWS=0 /tmp/sandbox_checker.out && assert_eq "N1-MANIFEST_ROWS_0" yes yes || assert_eq "N1-MANIFEST_ROWS_0" yes no
rm -rf "$SANDBOX"

echo "=== N2 manifest under-reports the bounded universe ==="
make_sandbox n2
seed_managed_universe "$SANDBOX"
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N2-UNDER_REPORTED_FAIL" 1 "$RC"
grep -q UNMAPPED_MANAGED_ACTS=4 /tmp/sandbox_checker.out && assert_eq "N2-UNMAPPED_MANAGED_ACTS_4" yes yes || assert_eq "N2-UNMAPPED_MANAGED_ACTS_4" yes no
grep -q UNMAPPED_MANAGED_HANDOFFS=4 /tmp/sandbox_checker.out && assert_eq "N2-UNMAPPED_MANAGED_HANDOFFS_4" yes yes || assert_eq "N2-UNMAPPED_MANAGED_HANDOFFS_4" yes no
rm -rf "$SANDBOX"

echo "=== N3 duplicate ACT path ==="
make_sandbox n3
seed_managed_universe "$SANDBOX"
cat >> "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N3-DUPLICATE_ACT_FAIL" 1 "$RC"
grep -q DUPLICATE_ACT_PATHS=1 /tmp/sandbox_checker.out && assert_eq "N3-DUPLICATE_ACT_KEYWORD" yes yes || assert_eq "N3-DUPLICATE_ACT_KEYWORD" yes no
rm -rf "$SANDBOX"

echo "=== N4 duplicate HANDOFF path ==="
make_sandbox n4
seed_managed_universe "$SANDBOX"
cat >> "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction02/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N4-DUPLICATE_HANDOFF_FAIL" 1 "$RC"
grep -q DUPLICATE_HANDOFF_PATHS=1 /tmp/sandbox_checker.out && assert_eq "N4-DUPLICATE_HANDOFF_KEYWORD" yes yes || assert_eq "N4-DUPLICATE_HANDOFF_KEYWORD" yes no
rm -rf "$SANDBOX"

echo "=== N5 exact-token mismatch ==="
make_sandbox n5
seed_managed_universe "$SANDBOX"
sed -i 's/^HALT_TOPOLOGY_RECORDED$/HALT_FAKE_TOKEN/' "$SANDBOX/evidence/llvmspike01-core03-correction01/HANDOFF.md"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N5-EXACT_VERDICT_FAIL" 1 "$RC"
grep -q EXACT_VERDICT_MISMATCHES=1 /tmp/sandbox_checker.out && assert_eq "N5-EXACT_MISMATCH_KEYWORD" yes yes || assert_eq "N5-EXACT_MISMATCH_KEYWORD" yes no
rm -rf "$SANDBOX"

echo "=== N6 PASS vs PASS_WITH_NEXT_ACT_DECISION ==="
make_sandbox n6
seed_managed_universe "$SANDBOX"
for i in 01 02 03 04 05; do
    write_act "$SANDBOX" "docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION${i}.md" PASS
    write_handoff "$SANDBOX" "evidence/llvmspike01-core03-correction${i}/HANDOFF.md" PASS_WITH_NEXT_ACT_DECISION
done
run_checker_in_sandbox "$SANDBOX"
assert_eq "N6-PASS_QUALIFIER_FAIL" 1 "$RC"
grep -q EXACT_VERDICT_MISMATCHES=5 /tmp/sandbox_checker.out && assert_eq "N6-EXACT_MISMATCH_5" yes yes || assert_eq "N6-EXACT_MISMATCH_5" yes no
rm -rf "$SANDBOX"

echo "=== N7 missing ## Status block ==="
make_sandbox n7
seed_managed_universe "$SANDBOX"
sed -i '/^## Status$/d' "$SANDBOX/docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N7-MALFORMED_STATUS_FAIL" 1 "$RC"
grep -q MALFORMED_ACT_STATUS=1 /tmp/sandbox_checker.out && assert_eq "N7-MALFORMED_KEYWORD" yes yes || assert_eq "N7-MALFORMED_KEYWORD" yes no
rm -rf "$SANDBOX"

echo "=== N8 duplicate ## Status block ==="
make_sandbox n8
seed_managed_universe "$SANDBOX"
write_act_extra_metadata "$SANDBOX" docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md HALT_TOPOLOGY_RECORDED
run_checker_in_sandbox "$SANDBOX"
assert_eq "N8-DUP_STATUS_FAIL" 1 "$RC"
grep -q MALFORMED_ACT_STATUS=1 /tmp/sandbox_checker.out && assert_eq "N8-MALFORMED_KEYWORD" yes yes || assert_eq "N8-MALFORMED_KEYWORD" yes no
rm -rf "$SANDBOX"

echo "=== N9 duplicate VERDICT block ==="
make_sandbox n9
seed_managed_universe "$SANDBOX"
write_handoff_extra_metadata "$SANDBOX" evidence/llvmspike01-core03-correction01/HANDOFF.md HALT_TOPOLOGY_RECORDED
run_checker_in_sandbox "$SANDBOX"
assert_eq "N9-DUP_VERDICT_FAIL" 1 "$RC"
grep -q MALFORMED_HANDOFF_VERDICT=1 /tmp/sandbox_checker.out && assert_eq "N9-MALFORMED_KEYWORD" yes yes || assert_eq "N9-MALFORMED_KEYWORD" yes no
rm -rf "$SANDBOX"

echo "=== N10 manifest row points to missing ACT ==="
make_sandbox n10
seed_managed_universe "$SANDBOX"
rm "$SANDBOX/docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N10-MISSING_ACT_FAIL" 1 "$RC"
grep -q MISSING_ACT_FILES=1 /tmp/sandbox_checker.out && assert_eq "N10-MISSING_ACT_KEYWORD" yes yes || assert_eq "N10-MISSING_ACT_KEYWORD" yes no
rm -rf "$SANDBOX"

echo "=== N11 manifest row points to missing HANDOFF ==="
make_sandbox n11
seed_managed_universe "$SANDBOX"
rm "$SANDBOX/evidence/llvmspike01-core03-correction03/HANDOFF.md"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N11-MISSING_HANDOFF_FAIL" 1 "$RC"
grep -q MISSING_HANDOFF_FILES=1 /tmp/sandbox_checker.out && assert_eq "N11-MISSING_HANDOFF_KEYWORD" yes yes || assert_eq "N11-MISSING_HANDOFF_KEYWORD" yes no
rm -rf "$SANDBOX"

echo "=== N12 empty manifest regression ==="
make_sandbox n12
seed_managed_universe "$SANDBOX"
cat > "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
# intentionally empty
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N12-EMPTY_MANIFEST_FAIL" 1 "$RC"
grep -q MANIFEST_ROWS=0 /tmp/sandbox_checker.out && assert_eq "N12-MANIFEST_ROWS_0" yes yes || assert_eq "N12-MANIFEST_ROWS_0" yes no
rm -rf "$SANDBOX"

echo "=== N13 PASS_WITH_NEXT_ACT_DECISION qualified equality ==="
make_sandbox n13
seed_managed_universe "$SANDBOX"
for i in 01 02 03 04 05; do
    write_act "$SANDBOX" "docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION${i}.md" PASS_WITH_NEXT_ACT_DECISION
    write_handoff "$SANDBOX" "evidence/llvmspike01-core03-correction${i}/HANDOFF.md" PASS_WITH_NEXT_ACT_DECISION
done
run_checker_in_sandbox "$SANDBOX"
assert_eq "N13-QUALIFIED_PASS" 0 "$RC"
grep -q PAIR_OK=5 /tmp/sandbox_checker.out && assert_eq "N13-PAIR_OK_5" yes yes || assert_eq "N13-PAIR_OK_5" yes no
rm -rf "$SANDBOX"

echo "=== N14 duplicate ACT path (alternate) ==="
make_sandbox n14
seed_managed_universe "$SANDBOX"
cat >> "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md	evidence/llvmspike01-core03-correction03/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N14-DUP_FAIL" 1 "$RC"
grep -q DUPLICATE_ACT_PATHS=1 /tmp/sandbox_checker.out && assert_eq "N14-DUP_ACT_KEYWORD" yes yes || assert_eq "N14-DUP_ACT_KEYWORD" yes no
rm -rf "$SANDBOX"

echo "=== N15 full real-tree mirror PASS ==="
make_sandbox n15
seed_managed_universe "$SANDBOX"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N15-FULL_PASS" 0 "$RC"
grep -q PAIR_OK=5 /tmp/sandbox_checker.out && assert_eq "N15-PAIR_OK_5" yes yes || assert_eq "N15-PAIR_OK_5" yes no
grep -q PAIR_FAIL=0 /tmp/sandbox_checker.out && assert_eq "N15-PAIR_FAIL_0" yes yes || assert_eq "N15-PAIR_FAIL_0" yes no
grep -q MANAGED_ACTS=5 /tmp/sandbox_checker.out && assert_eq "N15-MANAGED_ACTS_5" yes yes || assert_eq "N15-MANAGED_ACTS_5" yes no
grep -q MANAGED_HANDOFFS=5 /tmp/sandbox_checker.out && assert_eq "N15-MANAGED_HANDOFFS_5" yes yes || assert_eq "N15-MANAGED_HANDOFFS_5" yes no
grep -q UNMAPPED_MANAGED_ACTS=0 /tmp/sandbox_checker.out && assert_eq "N15-UNMAPPED_ACTS_0" yes yes || assert_eq "N15-UNMAPPED_ACTS_0" yes no
grep -q UNMAPPED_MANAGED_HANDOFFS=0 /tmp/sandbox_checker.out && assert_eq "N15-UNMAPPED_HANDOFFS_0" yes yes || assert_eq "N15-UNMAPPED_HANDOFFS_0" yes no
grep -q EXTRA_MANIFEST_ACTS=0 /tmp/sandbox_checker.out && assert_eq "N15-EXTRA_ACTS_0" yes yes || assert_eq "N15-EXTRA_ACTS_0" yes no
grep -q EXTRA_MANIFEST_HANDOFFS=0 /tmp/sandbox_checker.out && assert_eq "N15-EXTRA_HANDOFFS_0" yes yes || assert_eq "N15-EXTRA_HANDOFFS_0" yes no
rm -rf "$SANDBOX"

echo "=== N16 bounded completeness 4-row manifest ==="
make_sandbox n16
seed_managed_universe "$SANDBOX"
grep -v 'CORRECTION02' "$SANDBOX/docs/factory/act-handoff-map.tsv" > "$SANDBOX/docs/factory/act-handoff-map.tsv.tmp"
mv "$SANDBOX/docs/factory/act-handoff-map.tsv.tmp" "$SANDBOX/docs/factory/act-handoff-map.tsv"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N16-COMPLETENESS_FAIL" 1 "$RC"
grep -q UNMAPPED_MANAGED_ACTS=1 /tmp/sandbox_checker.out && assert_eq "N16-UNMAPPED_ACTS_1" yes yes || assert_eq "N16-UNMAPPED_ACTS_1" yes no
grep -q UNMAPPED_MANAGED_HANDOFFS=1 /tmp/sandbox_checker.out && assert_eq "N16-UNMAPPED_HANDOFFS_1" yes yes || assert_eq "N16-UNMAPPED_HANDOFFS_1" yes no
grep -q PAIR_OK=4 /tmp/sandbox_checker.out && assert_eq "N16-PAIR_OK_4" yes yes || assert_eq "N16-PAIR_OK_4" yes no
rm -rf "$SANDBOX"

echo "=== N17 mirror negative (extra row) ==="
make_sandbox n17
seed_managed_universe "$SANDBOX"
write_act "$SANDBOX" docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION.md PASS
write_handoff "$SANDBOX" evidence/factory-status-reconciliation/HANDOFF.md PASS
cat >> "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION.md	evidence/factory-status-reconciliation/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N17-EXTRA_FAIL" 1 "$RC"
grep -q EXTRA_MANIFEST_ACTS=1 /tmp/sandbox_checker.out && assert_eq "N17-EXTRA_ACTS_1" yes yes || assert_eq "N17-EXTRA_ACTS_1" yes no
grep -q EXTRA_MANIFEST_HANDOFFS=1 /tmp/sandbox_checker.out && assert_eq "N17-EXTRA_HANDOFFS_1" yes yes || assert_eq "N17-EXTRA_HANDOFFS_1" yes no
grep -q PAIR_OK=6 /tmp/sandbox_checker.out && assert_eq "N17-PAIR_OK_6" yes yes || assert_eq "N17-PAIR_OK_6" yes no
rm -rf "$SANDBOX"

echo "=== N18 POSIX shell portability (dash) ==="
make_sandbox n18
seed_managed_universe "$SANDBOX"
( cd "$SANDBOX" && dash scripts/quality/factory-closure-status-check.sh > /tmp/sandbox_checker.out 2>&1 ) && RC=0 || RC=$?
assert_eq "N18-DASH_PASS" 0 "$RC"
grep -q PAIR_OK=5 /tmp/sandbox_checker.out && assert_eq "N18-DASH_PAIR_OK_5" yes yes || assert_eq "N18-DASH_PAIR_OK_5" yes no
grep -q MANAGED_ACTS=5 /tmp/sandbox_checker.out && assert_eq "N18-DASH_MANAGED_ACTS_5" yes yes || assert_eq "N18-DASH_MANAGED_ACTS_5" yes no
grep -q MANAGED_HANDOFFS=5 /tmp/sandbox_checker.out && assert_eq "N18-DASH_MANAGED_HANDOFFS_5" yes yes || assert_eq "N18-DASH_MANAGED_HANDOFFS_5" yes no
rm -rf "$SANDBOX"

echo
echo "=== SUMMARY ==="
echo "PASS=$PASS  FAIL=$FAIL"
[ -n "$FAIL_LIST" ] && echo "FAILING:$FAIL_LIST"
[ "$FAIL" -eq 0 ]
