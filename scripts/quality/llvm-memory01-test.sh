#!/bin/sh
# scripts/quality/llvm-memory01-test.sh
#
# ACT-POLYC-LLVM-MEMORY01: GREEN harness for the smallest real
# LLVM memory slice (pointer parameter + I64 load/store).
#
# Positive matrix:
#   P1 pointer-param signature only (PtrParam: I64 *p returns 0)
#   P2 load I64 through pointer parameter (Load: I64 *p returns *p)
#   P3 store I64 through pointer parameter (Store: *p = x)
#   P4 load + scalar arithmetic (LoadAdd: *p + 1)
#   P5 store value produced by scalar arithmetic (StoreInc: *p = *p + 1)
#
# Negative matrix:
#   N1..N4 are NOT_EXPRESSIBLE_IN_CURRENT_LANGUAGE per ACT §14.
#   Only neg_struct.HC is exercised here; it proves the existing
#   pointer/aggregate REJECTED path still fires.
#
# Verifier: llvm-as + opt --passes=verify (LLVM 22).
# Purity: no alloca, no getelementptr, no ptrtoint/inttoptr/bitcast.
# Counter gate: SHAPE_DEPENDENT>=1, SUPPORTED>=1, DEFENSIVE=0,
# UNREACHABLE=0.
#
# No network. No execution. No object emission. No ORC/JIT.

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

EVID="$REPO_ROOT/evidence/llvm-memory01/impl"
mkdir -p "$EVID" "$EVID/_tmp" "$EVID/ll"
trap 'rm -rf "$EVID/_tmp"' EXIT

HCC=./hcc
LLVM_CONFIG=${LLVM_CONFIG:-llvm-config}
LLVM_AS=${LLVM_AS:-llvm-as}
LLVM_OPT=${LLVM_OPT:-opt}
LLVM_LIBDIR=$("$LLVM_CONFIG" --libdir 2>/dev/null || echo "")

HCC_INSTALL_DIR=${HCC_INSTALL_DIR:-}
HCC_INSTALL_ARG=""
if [ -n "$HCC_INSTALL_DIR" ]; then
    HCC_INSTALL_ARG="--install-dir=$HCC_INSTALL_DIR"
fi

PASS=0
FAIL=0

TOTAL_SUPPORTED=0
TOTAL_REJECTED=0
TOTAL_SHAPE_DEPENDENT=0
TOTAL_DEFENSIVE=0
TOTAL_UNREACHABLE=0
COUNTER_AGG_FAILURES=0

# ACT-POLYC-LLVM-MEMORY01-CORRECTION01 NC5: per-fixture counter
# bookkeeping. Each positive fixture is uniquely tagged with the
# number of IR_LOAD_DEREF / IR_STORE_DEREF dispatches it exercises
# (see RED-2 / RED-3 / P4 / P5 in evidence/llvm-memory01/red/).
# Per-fixture SHAPE_DEPENDENT counts are recorded here so the
# NC5 binding can assert that the count is uniquely attributable
# to the dereference dispatch (no fall-through to IR_STORE or to
# the pre-existing scalar-shaping path).
#
# POSIX-shell associative arrays are not portable; we use a
# per-fixture temp file keyed by fixture basename.
PER_FIXTURE_DIR="$EVID/_tmp/per_fixture"
mkdir -p "$PER_FIXTURE_DIR"

check_counter_purity() {
    bn="$1"; out="$2"
    if grep -q '^CAPABILITY_COUNTERS ' "$out"; then
        echo "FAIL  $bn: CAPABILITY_COUNTERS contaminated LLVM IR output" >&2
        FAIL=$((FAIL+1)); COUNTER_AGG_FAILURES=$((COUNTER_AGG_FAILURES+1))
        return 1
    fi
    return 0
}

parse_and_sum_counters() {
    bn="$1"; se="$2"
    if [ ! -f "$se" ]; then
        echo "FAIL  $bn: counters stderr file missing" >&2
        FAIL=$((FAIL+1)); COUNTER_AGG_FAILURES=$((COUNTER_AGG_FAILURES+1))
        return 1
    fi
    n=$(grep -c '^CAPABILITY_COUNTERS ' "$se" || true)
    if [ "$n" = "0" ]; then
        echo "FAIL  $bn: no CAPABILITY_COUNTERS line in stderr" >&2
        sed 's/^/    /' "$se" >&2
        FAIL=$((FAIL+1)); COUNTER_AGG_FAILURES=$((COUNTER_AGG_FAILURES+1))
        return 1
    fi
    if [ "$n" != "1" ]; then
        echo "FAIL  $bn: expected exactly one CAPABILITY_COUNTERS line, got $n" >&2
        FAIL=$((FAIL+1)); COUNTER_AGG_FAILURES=$((COUNTER_AGG_FAILURES+1))
        return 1
    fi
    line=$(grep '^CAPABILITY_COUNTERS ' "$se" | head -1)
    sup=$(printf '%s\n' "$line" | sed -n 's/^CAPABILITY_COUNTERS supported=\([0-9][0-9]*\) .*/\1/p')
    rej=$(printf '%s\n' "$line" | sed -n 's/^.* rejected=\([0-9][0-9]*\) .*/\1/p')
    sdp=$(printf '%s\n' "$line" | sed -n 's/^.* shape_dependent=\([0-9][0-9]*\) .*/\1/p')
    def=$(printf '%s\n' "$line" | sed -n 's/^.* defensive=\([0-9][0-9]*\) .*/\1/p')
    unr=$(printf '%s\n' "$line" | sed -n 's/^.* unreachable=\([0-9][0-9]*\).*/\1/p')
    if [ -z "$sup" ] || [ -z "$rej" ] || [ -z "$sdp" ] || [ -z "$def" ] || [ -z "$unr" ]; then
        echo "FAIL  $bn: malformed CAPABILITY_COUNTERS line: $line" >&2
        FAIL=$((FAIL+1)); COUNTER_AGG_FAILURES=$((COUNTER_AGG_FAILURES+1))
        return 1
    fi
    if [ "$unr" != "0" ]; then
        echo "FAIL  $bn: unreachable=$unr (expected 0)" >&2
        FAIL=$((FAIL+1)); COUNTER_AGG_FAILURES=$((COUNTER_AGG_FAILURES+1))
        return 1
    fi
    TOTAL_SUPPORTED=$((TOTAL_SUPPORTED + sup))
    TOTAL_REJECTED=$((TOTAL_REJECTED + rej))
    TOTAL_SHAPE_DEPENDENT=$((TOTAL_SHAPE_DEPENDENT + sdp))
    TOTAL_DEFENSIVE=$((TOTAL_DEFENSIVE + def))
    # ACT-POLYC-LLVM-MEMORY01-CORRECTION01 NC5: persist per-fixture
    # counts. Keyed by basename so the assertion phase can read
    # them after every fixture has been processed.
    pf="$PER_FIXTURE_DIR/$bn"
    {
        printf 'supported=%s\n' "$sup"
        printf 'rejected=%s\n' "$rej"
        printf 'shape_dependent=%s\n' "$sdp"
        printf 'defensive=%s\n' "$def"
        printf 'unreachable=%s\n' "$unr"
    } > "$pf"
    return 0
}

positive() {
    f="$1"; out="$2"; expect_load="$3"; expect_store="$4"
    bn=$(basename "$f" .HC)
    if ! "$HCC" --emit-llvm $HCC_INSTALL_ARG "$f" -o "$out" \
        > "$EVID/_tmp/$bn.stdout" 2> "$EVID/_tmp/$bn.stderr"; then
        echo "FAIL  $f: hcc --emit-llvm exited non-zero" >&2
        echo "  stderr: $(cat "$EVID/_tmp/$bn.stderr")" >&2
        FAIL=$((FAIL+1)); return 1
    fi
    if [ ! -s "$out" ]; then
        echo "FAIL  $f: no .ll output" >&2
        FAIL=$((FAIL+1)); return 1
    fi
    check_counter_purity "$bn" "$out" || return 1
    DYLD_LIBRARY_PATH="$LLVM_LIBDIR:${DYLD_LIBRARY_PATH:-}" \
    LD_LIBRARY_PATH="$LLVM_LIBDIR:${LD_LIBRARY_PATH:-}" \
        "$LLVM_AS" "$out" -o "$EVID/_tmp/$bn.bc" \
        > "$EVID/_tmp/$bn.as_stdout" 2> "$EVID/_tmp/$bn.as_stderr" || {
        echo "FAIL  $f: llvm-as rejected output" >&2
        echo "  stderr: $(cat "$EVID/_tmp/$bn.as_stderr")" >&2
        FAIL=$((FAIL+1)); return 1
    }
    DYLD_LIBRARY_PATH="$LLVM_LIBDIR:${DYLD_LIBRARY_PATH:-}" \
    LD_LIBRARY_PATH="$LLVM_LIBDIR:${LD_LIBRARY_PATH:-}" \
        "$LLVM_OPT" --passes=verify "$out" -disable-output \
        > "$EVID/_tmp/$bn.opt_stdout" 2> "$EVID/_tmp/$bn.opt_stderr" || {
        echo "FAIL  $f: LLVM verifier rejected output" >&2
        echo "  stderr: $(cat "$EVID/_tmp/$bn.opt_stderr")" >&2
        FAIL=$((FAIL+1)); return 1
    }
    # MEMORY01 structural purity: no alloca, no GEP, no pointer casts.
    # Match the operation as a bare word at the start of a line
    # (possibly after whitespace and an SSA name + '=' assignment).
    # This catches `%x = alloca ...`, `  alloca ...`, etc. without
    # accidentally matching legitimate IR constructs that mention
    # these names in other contexts (e.g. comments, type names).
    # We strip ';' line comments first to avoid false matches.
    body_no_comments=$(sed 's/;.*$//' "$out")
    bad_alloca=$(printf '%s\n' "$body_no_comments" | grep -nE '(^|[[:space:]])alloca([[:space:]]|$)' || true)
    if [ -n "$bad_alloca" ]; then
        echo "FAIL  $f: alloca in positive .ll (forbidden):" >&2
        printf '  %s\n' "$bad_alloca" | head -3 >&2
        FAIL=$((FAIL+1)); return 1
    fi
    bad_gep=$(printf '%s\n' "$body_no_comments" | grep -nE '(^|[[:space:]])getelementptr([[:space:]]|$)' || true)
    if [ -n "$bad_gep" ]; then
        echo "FAIL  $f: getelementptr in positive .ll (forbidden):" >&2
        printf '  %s\n' "$bad_gep" | head -3 >&2
        FAIL=$((FAIL+1)); return 1
    fi
    bad_cast=$(printf '%s\n' "$body_no_comments" | grep -nE '(^|[[:space:]])(ptrtoint|inttoptr|bitcast)([[:space:]]|$)' || true)
    if [ -n "$bad_cast" ]; then
        echo "FAIL  $f: pointer cast in positive .ll (forbidden):" >&2
        printf '  %s\n' "$bad_cast" | head -3 >&2
        FAIL=$((FAIL+1)); return 1
    fi
    if [ "$expect_load" = "load" ]; then
        if ! grep -qE 'load[[:space:]]+i64,[[:space:]]+ptr' "$out"; then
            echo "FAIL  $f: missing \`load i64, ptr\` in .ll" >&2
            FAIL=$((FAIL+1)); return 1
        fi
    fi
    if [ "$expect_store" = "store" ]; then
        if ! grep -qE 'store[[:space:]]+i64[[:space:]]+[%0-9a-zA-Z_.]+,[[:space:]]+ptr' "$out"; then
            echo "FAIL  $f: missing \`store i64, ptr\` in .ll" >&2
            FAIL=$((FAIL+1)); return 1
        fi
    fi
    parse_and_sum_counters "$bn" "$EVID/_tmp/$bn.stderr" || return 1
    PASS=$((PASS+1))
    echo "PASS  $f"
}

negative_shape() {
    f="$1"; code="$2"
    bn=$(basename "$f" .HC)
    set +e
    "$HCC" --emit-llvm $HCC_INSTALL_ARG "$f" \
        > "$EVID/_tmp/$bn.neg.out" 2> "$EVID/_tmp/$bn.neg.err"
    rc=$?
    set -e
    if [ "$rc" -eq 0 ]; then
        echo "FAIL  $bn: hcc --emit-llvm succeeded but negative expected ($code)" >&2
        FAIL=$((FAIL+1)); return 1
    fi
    if ! grep -q "$code" "$EVID/_tmp/$bn.neg.err"; then
        echo "FAIL  $bn: stderr missing '$code' (got: $(cat "$EVID/_tmp/$bn.neg.err"))" >&2
        FAIL=$((FAIL+1)); return 1
    fi
    parse_and_sum_counters "$bn" "$EVID/_tmp/$bn.neg.err" || true
    PASS=$((PASS+1))
    echo "PASS  $bn (negative, $code)"
}

echo "=== MEMORY01 positive matrix ==="
positive src/tests/llvm-memory01/red_pointer_param.HC  "$EVID/ll/red_pointer_param.ll"  ""       ""
positive src/tests/llvm-memory01/red_load_deref.HC     "$EVID/ll/red_load_deref.ll"     "load"  ""
positive src/tests/llvm-memory01/red_store_deref.HC    "$EVID/ll/red_store_deref.ll"    ""      "store"
positive src/tests/llvm-memory01/p4_load_add.HC        "$EVID/ll/p4_load_add.ll"        "load"  ""
positive src/tests/llvm-memory01/p5_store_inc.HC       "$EVID/ll/p5_store_inc.ll"       "load"  "store"

echo
echo "=== MEMORY01 negative matrix (struct aggregate -> REJECTED) ==="
negative_shape src/tests/llvm-spike/neg_struct.HC  LLVM_BACKEND_UNSUPPORTED_TYPE

echo
echo "=== MEMORY01 counter gate ==="
echo "=== capability counters (MEMORY01 matrix) ==="
echo "SUPPORTED           : $TOTAL_SUPPORTED"
echo "REJECTED            : $TOTAL_REJECTED"
echo "SHAPE_DEPENDENT     : $TOTAL_SHAPE_DEPENDENT"
echo "DEFENSIVE_INVARIANT : $TOTAL_DEFENSIVE"
echo "UNREACHABLE_ON_LLVM : $TOTAL_UNREACHABLE"
echo "=============================="
if [ "$TOTAL_SHAPE_DEPENDENT" -lt 1 ]; then
    echo "FAIL  MEMORY01: expected SHAPE_DEPENDENT >= 1, got $TOTAL_SHAPE_DEPENDENT" >&2
    FAIL=$((FAIL+1))
fi
if [ "$TOTAL_SUPPORTED" -lt 1 ]; then
    echo "FAIL  MEMORY01: expected SUPPORTED > 0, got $TOTAL_SUPPORTED" >&2
    FAIL=$((FAIL+1))
fi
if [ "$TOTAL_DEFENSIVE" -ne 0 ]; then
    echo "FAIL  MEMORY01: DEFENSIVE_INVARIANT must remain 0, got $TOTAL_DEFENSIVE" >&2
    FAIL=$((FAIL+1))
fi
if [ "$TOTAL_UNREACHABLE" -ne 0 ]; then
    echo "FAIL  MEMORY01: UNREACHABLE_ON_LLVM must remain 0, got $TOTAL_UNREACHABLE" >&2
    FAIL=$((FAIL+1))
fi
if [ "$COUNTER_AGG_FAILURES" -eq 0 ] && \
   [ "$TOTAL_SHAPE_DEPENDENT" -ge 1 ] && \
   [ "$TOTAL_SUPPORTED" -ge 1 ] && \
   [ "$TOTAL_DEFENSIVE" -eq 0 ] && \
   [ "$TOTAL_UNREACHABLE" -eq 0 ]; then
    echo "PASS  counter gate: SHAPE_DEPENDENT>=1, SUPPORTED>=1, DEFENSIVE=0, UNREACHABLE=0"
fi

# ACT-POLYC-LLVM-MEMORY01-CORRECTION01 NC5 (strong binding).
#
# Each positive fixture is tagged with the number of
# IR_LOAD_DEREF / IR_STORE_DEREF dispatches it is expected to
# contribute to SHAPE_DEPENDENT. Asserting these expectations
# proves that the SHAPE_DEPENDENT counter is uniquely
# attributable to the dereference dispatch: any code-path that
# suppresses or doubles one LL_INC_SHAPE_DEPENDENT call inside
# IR_LOAD_DEREF / IR_STORE_DEREF will trip the corresponding
# per-fixture assertion below.
#
# red_pointer_param.HC  : IR_TYPE_PTR parameter only, no deref.
#                         Expected SHAPE_DEPENDENT == 0.
# red_load_deref.HC     : one IR_LOAD_DEREF dispatch.
#                         Expected SHAPE_DEPENDENT >= 1.
# red_store_deref.HC    : one IR_STORE_DEREF dispatch.
#                         Expected SHAPE_DEPENDENT >= 1.
# p4_load_add.HC        : one IR_LOAD_DEREF dispatch
#                         (+ one IR_IADD which is SUPPORTED, not
#                         SHAPE_DEPENDENT).
#                         Expected SHAPE_DEPENDENT >= 1.
# p5_store_inc.HC       : one IR_LOAD_DEREF + one IR_STORE_DEREF.
#                         Expected SHAPE_DEPENDENT >= 2.
#
# These bounds are tight on the lower side and intentionally
# loose on the upper side (the predecessor scalar-shaping path
# may legitimately contribute 0 SHAPE_DEPENDENT to each
# fixture; that is fine, because per-fixture SUP/REJ/DEF/UNR
# are still independently gated).
echo
echo "=== MEMORY01 NC5 per-fixture attribution ==="
NC5_FAILURES=0
check_nc5_min() {
    bn="$1"; min="$2"
    pf="$PER_FIXTURE_DIR/$bn"
    if [ ! -f "$pf" ]; then
        echo "FAIL  NC5 $bn: per-fixture counter file missing" >&2
        FAIL=$((FAIL+1)); NC5_FAILURES=$((NC5_FAILURES+1))
        return 1
    fi
    sdp=$(sed -n 's/^shape_dependent=\([0-9][0-9]*\)$/\1/p' "$pf")
    if [ -z "$sdp" ]; then
        echo "FAIL  NC5 $bn: malformed per-fixture shape_dependent" >&2
        FAIL=$((FAIL+1)); NC5_FAILURES=$((NC5_FAILURES+1))
        return 1
    fi
    if [ "$sdp" -lt "$min" ]; then
        echo "FAIL  NC5 $bn: expected SHAPE_DEPENDENT >= $min, got $sdp" >&2
        FAIL=$((FAIL+1)); NC5_FAILURES=$((NC5_FAILURES+1))
        return 1
    fi
    echo "PASS  NC5 $bn: shape_dependent=$sdp (>= $min)"
    return 0
}
check_nc5_eq() {
    bn="$1"; eq="$2"
    pf="$PER_FIXTURE_DIR/$bn"
    if [ ! -f "$pf" ]; then
        echo "FAIL  NC5 $bn: per-fixture counter file missing" >&2
        FAIL=$((FAIL+1)); NC5_FAILURES=$((NC5_FAILURES+1))
        return 1
    fi
    sdp=$(sed -n 's/^shape_dependent=\([0-9][0-9]*\)$/\1/p' "$pf")
    if [ -z "$sdp" ]; then
        echo "FAIL  NC5 $bn: malformed per-fixture shape_dependent" >&2
        FAIL=$((FAIL+1)); NC5_FAILURES=$((NC5_FAILURES+1))
        return 1
    fi
    if [ "$sdp" -ne "$eq" ]; then
        echo "FAIL  NC5 $bn: expected SHAPE_DEPENDENT == $eq, got $sdp" >&2
        FAIL=$((FAIL+1)); NC5_FAILURES=$((NC5_FAILURES+1))
        return 1
    fi
    echo "PASS  NC5 $bn: shape_dependent=$sdp (== $eq)"
    return 0
}
# red_pointer_param has IR_TYPE_PTR param but does NOT deref.
check_nc5_eq  red_pointer_param  0
# One IR_LOAD_DEREF dispatch each.
check_nc5_min red_load_deref     1
# One IR_STORE_DEREF dispatch.
check_nc5_min red_store_deref    1
# P4: one load + arith. IR_IADD is SUPPORTED, so only load counts.
check_nc5_min p4_load_add        1
# P5: load + add + store. Two deref dispatches.
check_nc5_min p5_store_inc       2
if [ "$NC5_FAILURES" -eq 0 ]; then
    echo "PASS  NC5 per-fixture attribution: SHAPE_DEPENDENT uniquely attributable to IR_LOAD_DEREF / IR_STORE_DEREF"
fi

echo
echo "================================="
echo "MEMORY01 GREEN summary: PASS=$PASS FAIL=$FAIL"
echo "================================="
if [ "$FAIL" != "0" ]; then
    exit 1
fi
exit 0
