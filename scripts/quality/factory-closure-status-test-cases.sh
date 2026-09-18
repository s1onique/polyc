#!/bin/sh
# scripts/quality/factory-closure-status-test-cases.sh
# ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01 P0-4.
# Extracted 12-case regression matrix. Invoked by the PolyC driver.
set -u
CHECKER="${1:-scripts/quality/factory-closure-status-check.sh}"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
expect() {
  n=$1; erc=$2; esub=$3; mc=$4
  mp="$TMP/$n.tsv"; printf '%s' "$mc" > "$mp"
  out=$(FACTORY_ACT_HANDOFF_MAP="$mp" sh "$CHECKER" 2>&1); rc=$?
  if [ "$rc" = "$erc" ] && printf '%s' "$out" | grep -qF "$esub"; then
    PASS=$((PASS+1)); echo "PASS  $n"
  else
    FAIL=$((FAIL+1)); echo "FAIL  $n  rc=$rc exp=$erc sub=$esub"
  fi
}
expect T01 0 STATUS=PASS "docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md	evidence/llvmspike01-core03-correction02/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md	evidence/llvmspike01-core03-correction03/HANDOFF.md"
expect T02 1 DUPLICATE_ACT_PATH "docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction02/HANDOFF.md"
expect T03 1 DUPLICATE_HANDOFF_PATH "docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md	evidence/llvmspike01-core03-correction01/HANDOFF.md"
expect T04 1 DUPLICATE "docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md"
expect T05 1 MISSING_ACT_FILE "docs/acts/ACT-POLYC-DOES-NOT-EXIST.md	evidence/llvmspike01-core03-correction01/HANDOFF.md"
expect T06 1 MISSING_HANDOFF_FILE "docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md	docs/factory/HANDOFF-DOES-NOT-EXIST.md"
expect T07 1 EMPTY_HANDOFF_PATH "only-one-field
three-fields	here	too"
expect T08 1 HALT_EMPTY_MANAGED_UNIVERSE ""
expect T09 0 STATUS=PASS "docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md	evidence/llvmspike01-core03-correction02/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md	evidence/llvmspike01-core03-correction03/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION04.md	evidence/llvmspike01-core03-correction04/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION05.md	evidence/llvmspike01-core03-correction05/HANDOFF.md
docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02.md	evidence/factory-status-reconciliation-correction02/HANDOFF.md
docs/acts/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01.md	docs/factory/HANDOFF-ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01.md
docs/acts/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01-CORRECTION01.md	docs/factory/HANDOFF-ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01-CORRECTION01.md"
expect T10 0 STATUS=PASS "docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md	evidence/llvmspike01-core03-correction02/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md"
expect T11 1 PATH_TRAVERSAL_REJECTED "docs/../etc/passwd	evidence/llvmspike01-core03-correction01/HANDOFF.md"
expect T12 1 MISSING_HANDOFF_FILE "docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md	evidence/llvmspike01-core03-correction01/HANDOFF.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md	docs/factory/HANDOFF-DOES-NOT-EXIST-FOR-T12.md"
echo "FACTORY_CLOSURE_STATUS_TEST_PASS=$PASS"
echo "FACTORY_CLOSURE_STATUS_TEST_FAIL=$FAIL"
[ "$FAIL" = 0 ]
