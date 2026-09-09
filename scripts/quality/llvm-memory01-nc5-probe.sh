#!/bin/sh
# scripts/quality/llvm-memory01-nc5-probe.sh
#
# ACT-POLYC-LLVM-MEMORY01-CORRECTION01 NC5 (strong binding): regression
# probe that proves the per-fixture SHAPE_DEPENDENT assertions in
# scripts/quality/llvm-memory01-test.sh are sensitive to a real
# counter-suppression regression.
#
# Mechanism:
#   1. Snapshot src/llvm-backend.c to a temp file.
#   2. Mutate the source: remove the LL_INC_SHAPE_DEPENDENT(lc);
#      call inside the IR_LOAD_DEREF dispatch arm (one call site).
#   3. Rebuild hcc against the mutated source.
#   4. Run scripts/quality/llvm-memory01-test.sh.
#   5. ASSERT: the harness must FAIL (per-fixture red_load_deref
#      NC5 assertion trips because SHAPE_DEPENDENT for that
#      fixture drops from 1 to 0).
#   6. Always restore the source and rebuild, regardless of the
#      harness exit code, so the working tree is never mutated.
#
# This probe is the empirical proof that the permanent per-fixture
# NC5 assertions in the GREEN harness are bound to a real
# regression. If this probe ever silently passes after a source
# mutation, the NC5 binding has been broken (e.g. the assertion
# became a no-op, or the IR_LOAD_DEREF case lost its counter call
# without anything noticing).
#
# No network. No execution of produced code. No lli / ORC / JIT.

set -u

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

PROBE_TMP="${TMPDIR:-/tmp}/llvm-memory01-nc5-probe.$$"
mkdir -p "$PROBE_TMP"
ORIG_BACKEND="$PROBE_TMP/llvm-backend.c.orig"
MUT_BACKEND="$PROBE_TMP/llvm-backend.c.mut"
# Order matters: cp first (restores source), THEN remove the temp
# dir. Reversing the order would delete $ORIG_BACKEND before cp
# can use it, leaving the working tree in the mutated state.
trap 'cp "$ORIG_BACKEND" src/llvm-backend.c 2>/dev/null; make llvm-all > /dev/null 2>&1 || true; rm -rf "$PROBE_TMP"' EXIT

cp src/llvm-backend.c "$ORIG_BACKEND"

# Sanity: the IR_LOAD_DEREF case must contain the LL_INC_SHAPE_DEPENDENT
# call BEFORE we mutate. If not, the probe is meaningless (the binding
# is already gone, and we want to be loud about it).
case_begin=$(grep -n 'case IR_LOAD_DEREF: {' "$ORIG_BACKEND" | head -1 | cut -d: -f1)
case_end=$(grep -n 'case IR_STORE_DEREF: {' "$ORIG_BACKEND" | head -1 | cut -d: -f1)
if [ -z "$case_begin" ] || [ -z "$case_end" ]; then
    echo "FAIL probe: could not locate IR_LOAD_DEREF case in source" >&2
    exit 1
fi
if ! sed -n "${case_begin},${case_end}p" "$ORIG_BACKEND" \
        | grep -q 'LL_INC_SHAPE_DEPENDENT(lc);'; then
    echo "FAIL probe: IR_LOAD_DEREF case lacks LL_INC_SHAPE_DEPENDENT call" >&2
    echo "         NC5 binding was already broken before this probe ran" >&2
    exit 1
fi

# Mutate: delete exactly one LL_INC_SHAPE_DEPENDENT(lc); inside the
# IR_LOAD_DEREF case (between case_begin and case_end). Use awk so
# we keep the rest of the file byte-identical.
awk -v cb="$case_begin" -v ce="$case_end" '
    NR >= cb && NR <= ce {
        if (!removed && /LL_INC_SHAPE_DEPENDENT\(lc\);/) {
            removed = 1
            next
        }
    }
    { print }
' "$ORIG_BACKEND" > "$MUT_BACKEND"

mut_count=$(sed -n "${case_begin},${case_end}p" "$MUT_BACKEND" \
            | grep -c 'LL_INC_SHAPE_DEPENDENT(lc);' || true)
if [ "$mut_count" != "0" ]; then
    echo "FAIL probe: mutation did not delete the IR_LOAD_DEREF counter call" >&2
    exit 1
fi

cp "$MUT_BACKEND" src/llvm-backend.c
echo "=== probe: source mutated (IR_LOAD_DEREF counter call removed) ==="
echo "=== probe: rebuilding hcc ==="
if ! make llvm-all > "$PROBE_TMP/build.log" 2>&1; then
    echo "FAIL probe: build failed" >&2
    exit 1
fi

echo "=== probe: running harness (must FAIL on NC5 red_load_deref) ==="
set +e
HCC_INSTALL_DIR="${HCC_INSTALL_DIR:-/tmp/polyc-test-prefix}" \
    sh scripts/quality/llvm-memory01-test.sh > "$PROBE_TMP/harness.out" 2>&1
harness_rc=$?
set -e
tail -10 "$PROBE_TMP/harness.out"

# Probe verdict.
if [ "$harness_rc" -ne 0 ] \
        && grep -q 'FAIL  NC5 red_load_deref' "$PROBE_TMP/harness.out"; then
    echo
    echo "PASS probe: NC5 strong binding confirmed."
    echo "  harness rc        = $harness_rc (expected non-zero)"
    echo "  NC5 trip observed = FAIL NC5 red_load_deref"
    exit 0
fi
echo
echo "FAIL probe: NC5 strong binding NOT confirmed."
echo "  harness rc        = $harness_rc (expected non-zero)"
echo "  NC5 trip observed = $(grep -c 'FAIL  NC5 red_load_deref' "$PROBE_TMP/harness.out")"
exit 1
