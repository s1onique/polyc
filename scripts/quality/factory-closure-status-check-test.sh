#!/bin/sh
# scripts/quality/factory-closure-status-check-test.sh
#
# ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01 §41: dedicated
# Factory closure-status checker test target.
#
# Required cases:
#   T01 baseline valid manifest
#   T02 duplicate ACT
#   T03 duplicate HANDOFF
#   T04 duplicate pair
#   T05 missing ACT
#   T06 missing HANDOFF
#   T07 malformed row
#   T08 empty manifest
#   T09 add-valid-row-without-checker-change
#   T10 row-order independence
#   T11 path traversal / absolute path
#   T12 canonical self-row missing-HANDOFF RED
#
# Required:
#   FACTORY_CLOSURE_STATUS_TEST_PASS=12
#   FACTORY_CLOSURE_STATUS_TEST_FAIL=0
#
# Each case constructs a temporary manifest, runs the checker with
# FACTORY_ACT_HANDOFF_MAP=<tmp>, asserts the expected exit code and
# detection token.

# Note: set -u only. Do not set -e because the test invokes the checker
# with expected non-zero exit codes for failure cases.
set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

CHECKER=scripts/quality/factory-closure-status-check.sh
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0

# expect: assert_case <name> <expected_rc> <expected_substring_in_output> <manifest_content>
expect() {
    name="$1"
    expected_rc="$2"
    expected_substr="$3"
    manifest_content="$4"
    manifest_path="$TMP/$name.tsv"
    printf '%s' "$manifest_content" > "$manifest_path"
    # Capture stdout+stderr and rc explicitly.
    out=$(FACTORY_ACT_HANDOFF_MAP="$manifest_path" sh "$CHECKER" 2>&1)
    rc=$?
    if [ "$rc" = "$expected_rc" ] && printf '%s' "$out" | grep -qF "$expected_substr"; then
        PASS=$((PASS+1))
        printf 'PASS  %s\n' "$name"
    else
        FAIL=$((FAIL+1))
        printf 'FAIL  %s  rc=%s expected=%s substr=%s\n' "$name" "$rc" "$expected_rc" "$expected_substr"
        printf '%s\n' "$out" | head -5
    fi
}

# T01: baseline valid manifest (3 valid rows)
expect T01 0 STATUS=PASS "$(cat << 'EOF'
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md	evidence/llvmspike01-core03-correction02/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md	evidence/llvmspike01-core03-correction03/HANDOFF.md
EOF
)"

# T02: duplicate ACT
expect T02 1 DUPLICATE_ACT_PATH "$(printf 'docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md\tevidence/llvmspike01-core03-correction01/HANDOFF.md\ndocs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md\tevidence/llvmspike01-core03-correction02/HANDOFF.md\n')"

# T03: duplicate HANDOFF
expect T03 1 DUPLICATE_HANDOFF_PATH "$(printf 'docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md\tevidence/llvmspike01-core03-correction01/HANDOFF.md\ndocs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md\tevidence/llvmspike01-core03-correction01/HANDOFF.md\n')"

# T04: duplicate pair (exact duplicate row -> DUPLICATE_PAIR or DUPLICATE_ACT_PATH both fail-closed)
expect T04 1 DUPLICATE "$(printf 'docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md\tevidence/llvmspike01-core03-correction01/HANDOFF.md\ndocs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md\tevidence/llvmspike01-core03-correction01/HANDOFF.md\n')"

# T05: missing ACT
expect T05 1 MISSING_ACT_FILE "$(printf 'docs/acts/ACT-POLYC-DOES-NOT-EXIST.md\tevidence/llvmspike01-core03-correction01/HANDOFF.md\n')"

# T06: missing HANDOFF
expect T06 1 MISSING_HANDOFF_FILE "$(printf 'docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md\tevidence/llvmspike01-core03-correction01/HANDOFF.md\ndocs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md\tdocs/factory/HANDOFF-DOES-NOT-EXIST.md\n')"

# T07: malformed row (one-field and three-field)
expect T07 1 EMPTY_HANDOFF_PATH "$(printf 'only-one-field\nthree-fields\there\ttoo\n')"

# T08: empty manifest
expect T08 1 HALT_EMPTY_MANAGED_UNIVERSE "$(printf '')"

# T09: add-valid-row-without-checker-change (baseline + one existing pair)
expect T09 0 STATUS=PASS "$(cat << 'EOF'
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md	evidence/llvmspike01-core03-correction02/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md	evidence/llvmspike01-core03-correction03/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION04.md	evidence/llvmspike01-core03-correction04/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION05.md	evidence/llvmspike01-core03-correction05/HANDOFF.md
docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02.md	evidence/factory-status-reconciliation-correction02/HANDOFF.md
docs/acts/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01.md	docs/factory/HANDOFF-ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01.md
docs/acts/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01-CORRECTION01.md	docs/factory/HANDOFF-ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01-CORRECTION01.md
EOF
)"

# T10: row-order independence (2 valid rows in reverse order)
expect T10 0 STATUS=PASS "$(printf 'docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md\tevidence/llvmspike01-core03-correction02/HANDOFF.md\ndocs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md\tevidence/llvmspike01-core03-correction01/HANDOFF.md\n')"

# T11: path traversal
expect T11 1 PATH_TRAVERSAL_REJECTED "$(printf 'docs/../etc/passwd\tevidence/llvmspike01-core03-correction01/HANDOFF.md\n')"

# T12: canonical self-row missing-HANDOFF RED
expect T12 1 MISSING_HANDOFF_FILE "$(printf 'docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01.md\tdocs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01.md\n')"

echo
echo "FACTORY_CLOSURE_STATUS_TEST_PASS=$PASS"
echo "FACTORY_CLOSURE_STATUS_TEST_FAIL=$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
exit 0
