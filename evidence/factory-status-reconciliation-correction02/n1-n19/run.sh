#!/bin/bash
# N1..N19 hermetic negative tests for the factory closure-status
# exact-token checker.
#
# This runner covers the bounded 6-pair managed universe
# (5 ACT-POLYC-LLVM-CORE03-CORRECTION0X pairs +
#  1 ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02 pair),
# as established by ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02.
#
# IMPORTANT: this checker enforces independent bidirectional
# completeness against the bounded managed universe. Every test
# sandbox MUST contain all 6 managed ACT/HANDOFF fixtures (or a
# deliberate subset for completeness tests).
#
# N19 (added by CORRECTION02): remove the new CORRECTION02 row
# from the 6-row manifest -> UNMAPPED_MANAGED_ACTS=1
# UNMAPPED_MANAGED_HANDOFFS=1 rc=1. Demonstrates the new bounded
# pair is enforced by the same independent-completeness invariant
# that CORRECTION01's N16 introduced.

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
    write_act "$sb" docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02.md PASS
    write_handoff "$sb" evidence/llvmspike01-core03-correction01/HANDOFF.md HALT_TOPOLOGY_RECORDED
    write_handoff "$sb" evidence/llvmspike01-core03-correction02/HANDOFF.md HALT_SCOPE_CONTRACT_VIOLATED
    write_handoff "$sb" evidence/llvmspike01-core03-correction03/HANDOFF.md HALT_CORRECTION03_WIRE_AND_IDENTITY_CONTRACT
    write_handoff "$sb" evidence/llvmspike01-core03-correction04/HANDOFF.md HALT_CORRECTION04_STATUS_AND_LF_EVIDENCE
    write_handoff "$sb" evidence/llvmspike01-core03-correction05/HANDOFF.md HALT_CORRECTION05_OWN_GATE_RED
    write_handoff "$sb" evidence/factory-status-reconciliation-correction02/HANDOFF.md PASS
    cat > "$sb/docs/factory/act-handoff-map.tsv" <<MANIFEST_EOF
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md	evidence/llvmspike01-core03-correction02/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md	evidence/llvmspike01-core03-correction03/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION04.md	evidence/llvmspike01-core03-correction04/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION05.md	evidence/llvmspike01-core03-correction05/HANDOFF.md
docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02.md	evidence/factory-status-reconciliation-correction02/HANDOFF.md
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
-----

$tok
EOF
}

echo "=== baseline (clean 6-pair universe) ==="
make_sandbox baseline
seed_managed_universe "$SANDBOX"
run_checker_in_sandbox "$SANDBOX"
assert_eq "BASELINE_PASS" 0 "$RC"
grep -q MANAGED_ACTS=6 /tmp/sandbox_checker.out && assert_eq "BASELINE-MANAGED_ACTS_6" yes yes || assert_eq "BASELINE-MANAGED_ACTS_6" yes no
grep -q MANAGED_HANDOFFS=6 /tmp/sandbox_checker.out && assert_eq "BASELINE-MANAGED_HANDOFFS_6" yes yes || assert_eq "BASELINE-MANAGED_HANDOFFS_6" yes no
grep -q MANIFEST_ROWS=6 /tmp/sandbox_checker.out && assert_eq "BASELINE-MANIFEST_ROWS_6" yes yes || assert_eq "BASELINE-MANIFEST_ROWS_6" yes no
grep -q PAIR_OK=6 /tmp/sandbox_checker.out && assert_eq "BASELINE-PAIR_OK_6" yes yes || assert_eq "BASELINE-PAIR_OK_6" yes no
rm -rf "$SANDBOX"

echo "=== N1 empty manifest -> FAIL MANIFEST_ROWS=0 ==="
make_sandbox n1
seed_managed_universe "$SANDBOX"
: > "$SANDBOX/docs/factory/act-handoff-map.tsv"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N1-FAIL" 1 "$RC"
grep -q MANIFEST_ROWS=0 /tmp/sandbox_checker.out && assert_eq "N1-MANIFEST_ROWS_0" yes yes || assert_eq "N1-MANIFEST_ROWS_0" yes no
grep -q UNMAPPED_MANAGED_ACTS=6 /tmp/sandbox_checker.out && assert_eq "N1-UNMAPPED_ACTS_6" yes yes || assert_eq "N1-UNMAPPED_ACTS_6" yes no
grep -q UNMAPPED_MANAGED_HANDOFFS=6 /tmp/sandbox_checker.out && assert_eq "N1-UNMAPPED_HANDOFFS_6" yes yes || assert_eq "N1-UNMAPPED_HANDOFFS_6" yes no
rm -rf "$SANDBOX"

echo "=== N2 manifest under-reports -> FAIL UNMAPPED_*=6 ==="
make_sandbox n2
seed_managed_universe "$SANDBOX"
: > "$SANDBOX/docs/factory/act-handoff-map.tsv"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N2-FAIL" 1 "$RC"
grep -q UNMAPPED_MANAGED_ACTS=6 /tmp/sandbox_checker.out && assert_eq "N2-UNMAPPED_ACTS_6" yes yes || assert_eq "N2-UNMAPPED_ACTS_6" yes no
grep -q UNMAPPED_MANAGED_HANDOFFS=6 /tmp/sandbox_checker.out && assert_eq "N2-UNMAPPED_HANDOFFS_6" yes yes || assert_eq "N2-UNMAPPED_HANDOFFS_6" yes no
rm -rf "$SANDBOX"

echo "=== N3 duplicate ACT path -> FAIL DUPLICATE_ACT_PATHS=1 ==="
make_sandbox n3
seed_managed_universe "$SANDBOX"
# Duplicate the first row by appending it again with a different handoff.
printf 'docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md\tevidence/llvmspike01-core03-correction02/HANDOFF.md\n' >> "$SANDBOX/docs/factory/act-handoff-map.tsv"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N3-FAIL" 1 "$RC"
grep -q DUPLICATE_ACT_PATHS=1 /tmp/sandbox_checker.out && assert_eq "N3-DUPLICATE_ACTS_1" yes yes || assert_eq "N3-DUPLICATE_ACTS_1" yes no
rm -rf "$SANDBOX"

echo "=== N4 duplicate HANDOFF path -> FAIL DUPLICATE_HANDOFF_PATHS=1 ==="
make_sandbox n4
seed_managed_universe "$SANDBOX"
# Duplicate the first handoff by appending a second row pointing to it.
printf 'docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md\tevidence/llvmspike01-core03-correction01/HANDOFF.md\n' >> "$SANDBOX/docs/factory/act-handoff-map.tsv"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N4-FAIL" 1 "$RC"
grep -q DUPLICATE_HANDOFF_PATHS=1 /tmp/sandbox_checker.out && assert_eq "N4-DUPLICATE_HANDOFFS_1" yes yes || assert_eq "N4-DUPLICATE_HANDOFFS_1" yes no
rm -rf "$SANDBOX"

echo "=== N5 exact-token mismatch -> FAIL EXACT_VERDICT_MISMATCHES=1 ==="
make_sandbox n5
seed_managed_universe "$SANDBOX"
sed -i 's/^HALT_TOPOLOGY_RECORDED$/PASS/' "$SANDBOX/evidence/llvmspike01-core03-correction01/HANDOFF.md"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N5-FAIL" 1 "$RC"
grep -q EXACT_VERDICT_MISMATCHES=1 /tmp/sandbox_checker.out && assert_eq "N5-MISMATCH_1" yes yes || assert_eq "N5-MISMATCH_1" yes no
rm -rf "$SANDBOX"

echo "=== N6 PASS vs PASS_WITH_NEXT_ACT_DECISION (5 mismatches) ==="
make_sandbox n6
seed_managed_universe "$SANDBOX"
for i in 01 02 03 04 05; do
    write_act "$SANDBOX" "docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION${i}.md" PASS
    write_handoff "$SANDBOX" "evidence/llvmspike01-core03-correction${i}/HANDOFF.md" PASS_WITH_NEXT_ACT_DECISION
done
run_checker_in_sandbox "$SANDBOX"
assert_eq "N6-FAIL" 1 "$RC"
grep -q EXACT_VERDICT_MISMATCHES=5 /tmp/sandbox_checker.out && assert_eq "N6-MISMATCH_5" yes yes || assert_eq "N6-MISMATCH_5" yes no
rm -rf "$SANDBOX"

echo "=== N7 missing ## Status block -> FAIL MALFORMED_ACT_STATUS=1 ==="
make_sandbox n7
seed_managed_universe "$SANDBOX"
sed -i '/^## Status$/d' "$SANDBOX/docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N7-FAIL" 1 "$RC"
grep -q MALFORMED_ACT_STATUS=1 /tmp/sandbox_checker.out && assert_eq "N7-MALFORMED_ACTS_1" yes yes || assert_eq "N7-MALFORMED_ACTS_1" yes no
rm -rf "$SANDBOX"

echo "=== N8 duplicate ## Status block -> FAIL MALFORMED_ACT_STATUS=1 ==="
make_sandbox n8
seed_managed_universe "$SANDBOX"
# Append a duplicate "## Status\nPASS" to the first ACT.
printf '\n## Status\n\nPASS\n' >> "$SANDBOX/docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N8-FAIL" 1 "$RC"
grep -q MALFORMED_ACT_STATUS=1 /tmp/sandbox_checker.out && assert_eq "N8-MALFORMED_ACTS_1" yes yes || assert_eq "N8-MALFORMED_ACTS_1" yes no
rm -rf "$SANDBOX"

echo "=== N9 duplicate VERDICT block -> FAIL MALFORMED_HANDOFF_VERDICT=1 ==="
make_sandbox n9
seed_managed_universe "$SANDBOX"
printf '\nVERDICT\n-----\n\nPASS\n' >> "$SANDBOX/evidence/llvmspike01-core03-correction01/HANDOFF.md"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N9-FAIL" 1 "$RC"
grep -q MALFORMED_HANDOFF_VERDICT=1 /tmp/sandbox_checker.out && assert_eq "N9-MALFORMED_HANDOFFS_1" yes yes || assert_eq "N9-MALFORMED_HANDOFFS_1" yes no
rm -rf "$SANDBOX"

echo "=== N10 manifest row -> missing ACT file -> FAIL MISSING_ACT_FILES=1 ==="
make_sandbox n10
seed_managed_universe "$SANDBOX"
rm "$SANDBOX/docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N10-FAIL" 1 "$RC"
grep -q MISSING_ACT_FILES=1 /tmp/sandbox_checker.out && assert_eq "N10-MISSING_ACTS_1" yes yes || assert_eq "N10-MISSING_ACTS_1" yes no
rm -rf "$SANDBOX"

echo "=== N11 manifest row -> missing HANDOFF file -> FAIL MISSING_HANDOFF_FILES=1 ==="
make_sandbox n11
seed_managed_universe "$SANDBOX"
rm "$SANDBOX/evidence/llvmspike01-core03-correction01/HANDOFF.md"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N11-FAIL" 1 "$RC"
grep -q MISSING_HANDOFF_FILES=1 /tmp/sandbox_checker.out && assert_eq "N11-MISSING_HANDOFFS_1" yes yes || assert_eq "N11-MISSING_HANDOFFS_1" yes no
rm -rf "$SANDBOX"

echo "=== N12 empty manifest regression -> FAIL MANIFEST_ROWS=0 ==="
make_sandbox n12
seed_managed_universe "$SANDBOX"
: > "$SANDBOX/docs/factory/act-handoff-map.tsv"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N12-FAIL" 1 "$RC"
grep -q MANIFEST_ROWS=0 /tmp/sandbox_checker.out && assert_eq "N12-MANIFEST_ROWS_0" yes yes || assert_eq "N12-MANIFEST_ROWS_0" yes no
rm -rf "$SANDBOX"

echo "=== N13 PASS_WITH_NEXT_ACT_DECISION qualified equality -> PASS ==="
make_sandbox n13
seed_managed_universe "$SANDBOX"
# Re-write all 6 pairs to use PASS_WITH_NEXT_ACT_DECISION on both sides.
for pair in 01 02 03 04 05; do
    sed -i 's/^HALT_[A-Z0-9_]\+$/PASS_WITH_NEXT_ACT_DECISION/' "$SANDBOX/docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION${pair}.md"
    sed -i 's/^HALT_[A-Z0-9_]\+$/PASS_WITH_NEXT_ACT_DECISION/' "$SANDBOX/evidence/llvmspike01-core03-correction${pair}/HANDOFF.md"
done
sed -i 's/^PASS$/PASS_WITH_NEXT_ACT_DECISION/' "$SANDBOX/docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02.md"
sed -i 's/^PASS$/PASS_WITH_NEXT_ACT_DECISION/' "$SANDBOX/evidence/factory-status-reconciliation-correction02/HANDOFF.md"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N13-PASS" 0 "$RC"
grep -q PAIR_OK=6 /tmp/sandbox_checker.out && assert_eq "N13-PAIR_OK_6" yes yes || assert_eq "N13-PAIR_OK_6" yes no
rm -rf "$SANDBOX"

echo "=== N14 duplicate ACT path (alternate) -> FAIL DUPLICATE_ACT_PATHS=1 ==="
make_sandbox n14
seed_managed_universe "$SANDBOX"
# Duplicate a different ACT row.
printf 'docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md\tevidence/llvmspike01-core03-correction02/HANDOFF.md\n' >> "$SANDBOX/docs/factory/act-handoff-map.tsv"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N14-FAIL" 1 "$RC"
grep -q DUPLICATE_ACT_PATHS=1 /tmp/sandbox_checker.out && assert_eq "N14-DUPLICATE_ACTS_1" yes yes || assert_eq "N14-DUPLICATE_ACTS_1" yes no
rm -rf "$SANDBOX"

echo "=== N15 full real-tree mirror PASS (9 counter assertions) ==="
make_sandbox n15
seed_managed_universe "$SANDBOX"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N15-FULL_PASS" 0 "$RC"
grep -q STATUS=PASS /tmp/sandbox_checker.out && assert_eq "N15-STATUS_PASS" yes yes || assert_eq "N15-STATUS_PASS" yes no
grep -q VERDICT=PASS /tmp/sandbox_checker.out && assert_eq "N15-VERDICT_PASS" yes yes || assert_eq "N15-VERDICT_PASS" yes no
grep -q PAIR_OK=6 /tmp/sandbox_checker.out && assert_eq "N15-PAIR_OK_6" yes yes || assert_eq "N15-PAIR_OK_6" yes no
grep -q PAIR_FAIL=0 /tmp/sandbox_checker.out && assert_eq "N15-PAIR_FAIL_0" yes yes || assert_eq "N15-PAIR_FAIL_0" yes no
grep -q MANAGED_ACTS=6 /tmp/sandbox_checker.out && assert_eq "N15-MANAGED_ACTS_6" yes yes || assert_eq "N15-MANAGED_ACTS_6" yes no
grep -q MANAGED_HANDOFFS=6 /tmp/sandbox_checker.out && assert_eq "N15-MANAGED_HANDOFFS_6" yes yes || assert_eq "N15-MANAGED_HANDOFFS_6" yes no
grep -q UNMAPPED_MANAGED_ACTS=0 /tmp/sandbox_checker.out && assert_eq "N15-UNMAPPED_ACTS_0" yes yes || assert_eq "N15-UNMAPPED_ACTS_0" yes no
grep -q UNMAPPED_MANAGED_HANDOFFS=0 /tmp/sandbox_checker.out && assert_eq "N15-UNMAPPED_HANDOFFS_0" yes yes || assert_eq "N15-UNMAPPED_HANDOFFS_0" yes no
grep -q EXTRA_MANIFEST_ACTS=0 /tmp/sandbox_checker.out && assert_eq "N15-EXTRA_ACTS_0" yes yes || assert_eq "N15-EXTRA_ACTS_0" yes no
grep -q EXTRA_MANIFEST_HANDOFFS=0 /tmp/sandbox_checker.out && assert_eq "N15-EXTRA_HANDOFFS_0" yes yes || assert_eq "N15-EXTRA_HANDOFFS_0" yes no
rm -rf "$SANDBOX"

echo "=== N16 bounded completeness: remove CORE03-CORRECTION02 row ==="
make_sandbox n16
seed_managed_universe "$SANDBOX"
# Targeted removal of the CORE03-CORRECTION02 row only.
grep -v -F 'docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md	evidence/llvmspike01-core03-correction02/HANDOFF.md' \
    "$SANDBOX/docs/factory/act-handoff-map.tsv" \
    > "$SANDBOX/docs/factory/act-handoff-map.tsv.tmp"
mv "$SANDBOX/docs/factory/act-handoff-map.tsv.tmp" "$SANDBOX/docs/factory/act-handoff-map.tsv"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N16-COMPLETENESS_FAIL" 1 "$RC"
grep -q UNMAPPED_MANAGED_ACTS=1 /tmp/sandbox_checker.out && assert_eq "N16-UNMAPPED_ACTS_1" yes yes || assert_eq "N16-UNMAPPED_ACTS_1" yes no
grep -q UNMAPPED_MANAGED_HANDOFFS=1 /tmp/sandbox_checker.out && assert_eq "N16-UNMAPPED_HANDOFFS_1" yes yes || assert_eq "N16-UNMAPPED_HANDOFFS_1" yes no
grep -q PAIR_OK=5 /tmp/sandbox_checker.out && assert_eq "N16-PAIR_OK_5" yes yes || assert_eq "N16-PAIR_OK_5" yes no
rm -rf "$SANDBOX"

echo "=== N17 mirror negative (out-of-managed extra row) ==="
make_sandbox n17
seed_managed_universe "$SANDBOX"
# Add a row pointing to ACT-POLYC-FACTORY-STATUS-RECONCILIATION (the
# predecessor, NOT in the bounded 6-pair managed universe).
write_act "$SANDBOX" docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION.md PASS
write_handoff "$SANDBOX" evidence/factory-status-reconciliation/HANDOFF.md PASS
cat >> "$SANDBOX/docs/factory/act-handoff-map.tsv" <<EOF
docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION.md	evidence/factory-status-reconciliation/HANDOFF.md
EOF
run_checker_in_sandbox "$SANDBOX"
assert_eq "N17-EXTRA_FAIL" 1 "$RC"
grep -q EXTRA_MANIFEST_ACTS=1 /tmp/sandbox_checker.out && assert_eq "N17-EXTRA_ACTS_1" yes yes || assert_eq "N17-EXTRA_ACTS_1" yes no
grep -q EXTRA_MANIFEST_HANDOFFS=1 /tmp/sandbox_checker.out && assert_eq "N17-EXTRA_HANDOFFS_1" yes yes || assert_eq "N17-EXTRA_HANDOFFS_1" yes no
grep -q PAIR_OK=7 /tmp/sandbox_checker.out && assert_eq "N17-PAIR_OK_7" yes yes || assert_eq "N17-PAIR_OK_7" yes no
rm -rf "$SANDBOX"

echo "=== N18 POSIX shell portability (dash) ==="
make_sandbox n18
seed_managed_universe "$SANDBOX"
( cd "$SANDBOX" && dash scripts/quality/factory-closure-status-check.sh > /tmp/sandbox_checker.out 2>&1 ) && RC=0 || RC=$?
assert_eq "N18-DASH_PASS" 0 "$RC"
grep -q PAIR_OK=6 /tmp/sandbox_checker.out && assert_eq "N18-DASH_PAIR_OK_6" yes yes || assert_eq "N18-DASH_PAIR_OK_6" yes no
grep -q MANAGED_ACTS=6 /tmp/sandbox_checker.out && assert_eq "N18-DASH_MANAGED_ACTS_6" yes yes || assert_eq "N18-DASH_MANAGED_ACTS_6" yes no
grep -q MANAGED_HANDOFFS=6 /tmp/sandbox_checker.out && assert_eq "N18-DASH_MANAGED_HANDOFFS_6" yes yes || assert_eq "N18-DASH_MANAGED_HANDOFFS_6" yes no
rm -rf "$SANDBOX"

echo "=== N19 bounded completeness: remove the CORRECTION02 row (this ACT) ==="
make_sandbox n19
seed_managed_universe "$SANDBOX"
# Targeted removal of the FACTORY-STATUS-RECONCILIATION-CORRECTION02 row.
grep -v -F 'docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02.md	evidence/factory-status-reconciliation-correction02/HANDOFF.md' \
    "$SANDBOX/docs/factory/act-handoff-map.tsv" \
    > "$SANDBOX/docs/factory/act-handoff-map.tsv.tmp"
mv "$SANDBOX/docs/factory/act-handoff-map.tsv.tmp" "$SANDBOX/docs/factory/act-handoff-map.tsv"
run_checker_in_sandbox "$SANDBOX"
assert_eq "N19-COMPLETENESS_FAIL" 1 "$RC"
grep -q UNMAPPED_MANAGED_ACTS=1 /tmp/sandbox_checker.out && assert_eq "N19-UNMAPPED_ACTS_1" yes yes || assert_eq "N19-UNMAPPED_ACTS_1" yes no
grep -q UNMAPPED_MANAGED_HANDOFFS=1 /tmp/sandbox_checker.out && assert_eq "N19-UNMAPPED_HANDOFFS_1" yes yes || assert_eq "N19-UNMAPPED_HANDOFFS_1" yes no
grep -q PAIR_OK=5 /tmp/sandbox_checker.out && assert_eq "N19-PAIR_OK_5" yes yes || assert_eq "N19-PAIR_OK_5" yes no
rm -rf "$SANDBOX"

echo
echo "=== SUMMARY ==="
echo "PASS=$PASS  FAIL=$FAIL"
[ -n "$FAIL_LIST" ] && echo "FAILING:$FAIL_LIST"
[ "$FAIL" -eq 0 ]
