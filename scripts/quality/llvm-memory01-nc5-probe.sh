#!/bin/sh
# scripts/quality/llvm-memory01-nc5-probe.sh
#
# ACT-POLYC-LLVM-MEMORY01-CORRECTION01 + CORRECTION02 NC5 (strong
# binding): regression probe that proves the per-fixture
# SHAPE_DEPENDENT assertions in
# scripts/quality/llvm-memory01-test.sh are sensitive to a real
# counter-suppression regression.
#
# Usage:
#   llvm-memory01-nc5-probe.sh            # default mode = load
#   llvm-memory01-nc5-probe.sh load      # IR_LOAD_DEREF arm
#   llvm-memory01-nc5-probe.sh store     # IR_STORE_DEREF arm
#
# Mechanism (per mode):
#   1. Snapshot src/llvm-backend.c to a temp file.
#   2. Mutate the source: remove the LL_INC_SHAPE_DEPENDENT(lc);
#      call inside the named dispatch arm (one call site).
#   3. Rebuild hcc against the mutated source.
#   4. Run scripts/quality/llvm-memory01-test.sh.
#   5. ASSERT: the harness must FAIL with the corresponding
#      per-fixture NC5 trip:
#        - load mode  -> FAIL  NC5 red_load_deref
#        - store mode -> FAIL  NC5 red_store_deref
#   6. Always restore the source and rebuild, regardless of the
#      harness exit code, so the working tree is never mutated.
#
# This probe is the empirical proof that the permanent per-fixture
# NC5 assertions in the GREEN harness are bound to a real
# regression for both LOAD_DEREF and STORE_DEREF. If either mode
# ever silently passes after a source mutation, the NC5 binding
# for that arm has been broken.
#
# Build correctness: the probe uses `make -B` and deletes the
# hcc binary and llvm-backend.c.o before each build, because
# sub-second mtime resolution on APFS causes `make` to skip the
# recompile (observed as a flaky false-GREEN), violating the
# strict invariant that "the harness must observe the
# suppressed counter".
#
# No network. No execution of produced code. No lli / ORC / JIT.

set -u

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

# Mode: load (default) or store.
MODE="${1:-load}"
case "$MODE" in
    load)  OP="IR_LOAD_DEREF"  ; TRIP="red_load_deref"  ; LABEL="IR_LOAD_DEREF"  ;;
    store) OP="IR_STORE_DEREF" ; TRIP="red_store_deref" ; LABEL="IR_STORE_DEREF" ;;
    *)
        echo "FAIL probe: unknown mode '$MODE' (use 'load' or 'store')" >&2
        exit 1
        ;;
esac

PROBE_TMP="${TMPDIR:-/tmp}/llvm-memory01-nc5-probe.$$"
mkdir -p "$PROBE_TMP"
ORIG_BACKEND="$PROBE_TMP/llvm-backend.c.orig"
MUT_BACKEND="$PROBE_TMP/llvm-backend.c.mut"
# Order matters: cp first (restores source), THEN remove the temp
# dir. Reversing the order would delete $ORIG_BACKEND before cp
# can use it, leaving the working tree in the mutated state.
trap 'cp "$ORIG_BACKEND" src/llvm-backend.c 2>/dev/null; touch src/llvm-backend.c; rm -f hcc build/CMakeFiles/hcc.dir/llvm-backend.c.o; env MAKEFLAGS="-B" make -B llvm-all > /dev/null 2>&1 || true; rm -rf "$PROBE_TMP"' EXIT

cp src/llvm-backend.c "$ORIG_BACKEND"

# Sanity: the named case must exist BEFORE we mutate. If not, the
# probe is meaningless (the binding is already gone, and we want
# to be loud about it).
case_begin=$(grep -n "case ${OP}: {" "$ORIG_BACKEND" | head -1 | cut -d: -f1)
if [ -z "$case_begin" ]; then
    echo "FAIL probe: could not locate ${OP} case in source" >&2
    exit 1
fi
# End = next `case IR_X: {` after case_begin, or EOF.
case_end=$(awk -v cb="$case_begin" 'NR>cb && /^[[:space:]]+case IR_[A-Z_]+: \{/ {print NR; exit}' "$ORIG_BACKEND")
if [ -z "$case_end" ]; then
    case_end=$(wc -l < "$ORIG_BACKEND")
fi
if ! sed -n "${case_begin},${case_end}p" "$ORIG_BACKEND" \
        | grep -q 'LL_INC_SHAPE_DEPENDENT(lc);'; then
    echo "FAIL probe: ${OP} case lacks LL_INC_SHAPE_DEPENDENT call" >&2
    echo "         NC5 binding was already broken before this probe ran" >&2
    exit 1
fi

# Mutate: delete exactly one LL_INC_SHAPE_DEPENDENT(lc); inside the
# named case (between case_begin and case_end). Use awk so we keep
# the rest of the file byte-identical.
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
    echo "FAIL probe: mutation did not delete the ${OP} counter call" >&2
    exit 1
fi

cp "$MUT_BACKEND" src/llvm-backend.c
# Force a clean rebuild: delete hcc binary AND llvm-backend.c.o
# so that `make` cannot decide "nothing changed" via stale
# mtimes. Sub-second mtime resolution on this filesystem causes
# `touch` to be insufficient when the .o file already has the
# same sub-second timestamp as the source. We also force
# `make -B` (always-make) via the -B flag passed to the
# underlying make to bypass any residual stat-cache.
touch src/llvm-backend.c
rm -f hcc build/CMakeFiles/hcc.dir/llvm-backend.c.o
echo "=== probe (mode=${MODE}): source mutated (${LABEL} counter call removed) ==="
echo "=== probe: rebuilding hcc (forced) ==="
if ! env MAKEFLAGS='-B' make -B llvm-all > "$PROBE_TMP/build.log" 2>&1; then
    echo "FAIL probe: build failed" >&2
    tail -20 "$PROBE_TMP/build.log" >&2
    exit 1
fi
# Verify the rebuild actually happened.
post_build_hash=$(shasum -a 256 hcc 2>/dev/null | cut -d' ' -f1)
if [ -z "$post_build_hash" ]; then
    echo "FAIL probe: hcc binary missing after build" >&2
    exit 1
fi

echo "=== probe: running harness (must FAIL on NC5 ${TRIP}) ==="
set +e
HCC_INSTALL_DIR="${HCC_INSTALL_DIR:-/tmp/polyc-test-prefix}" \
    sh scripts/quality/llvm-memory01-test.sh > "$PROBE_TMP/harness.out" 2>&1
harness_rc=$?
set -e
tail -10 "$PROBE_TMP/harness.out"

# Probe verdict.
if [ "$harness_rc" -ne 0 ] \
        && grep -q "FAIL  NC5 ${TRIP}" "$PROBE_TMP/harness.out"; then
    echo
    echo "PASS probe (${MODE}): NC5 strong binding confirmed for ${LABEL}."
    echo "  harness rc        = $harness_rc (expected non-zero)"
    echo "  NC5 trip observed = FAIL NC5 ${TRIP}"
    exit 0
fi
echo
echo "FAIL probe (${MODE}): NC5 strong binding NOT confirmed for ${LABEL}."
echo "  harness rc        = $harness_rc (expected non-zero)"
echo "  NC5 trip observed = $(grep -c "FAIL  NC5 ${TRIP}" "$PROBE_TMP/harness.out")"
exit 1
