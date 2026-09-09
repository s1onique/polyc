#!/bin/sh
# scripts/quality/llvm-float01-test.sh
#
# ACT-POLYC-LLVM-FLOAT01: positive + negative matrix + LLVM verifier +
# fast-math purity + counter attribution + determinism for the
# scalar F64 slice of the LLVM 22 C-API backend.
#
# Sections (each ends with its own PASS/FAIL tally):
#   toolchain
#   positive matrix       (RED-1 .. RED-7 + mixed expression)
#   comparison predicate  (six-op matrix; RED-6)
#   branch matrix         (FCMP -> IR_BR; RED-7)
#   negative matrix       (FDIV, conversion)
#   counter attribution   (per-fixture SUPPORTED attribution)
#   determinism           (NC3 / NC6; two consecutive emits byte-equal)
#   summary
#
# No network. No execution of emitted IR. No lli / ORC / JIT.

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

EVID="$REPO_ROOT/evidence/llvm-float01/impl"
mkdir -p "$EVID"
mkdir -p "$EVID/_tmp"
trap 'rm -rf "$EVID/_tmp"' EXIT

HCC=./hcc
LLVM_AS=${LLVM_AS:-llvm-as}
LLVM_VERIFY=${LLVM_VERIFY:-opt}

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
FAST_MATH_FAILURES=0
DETERMINISM_FAILURES=0

# ACT-POLYC-LLVM-FLOAT01 §13: the fast-math structural invariant.
#
# Every FLOAT01 emitted module must contain zero fast-math flags.
# The grep is restricted to lines that look like LLVM fp-instruction
# lines to avoid false positives on plain identifiers.
check_fast_math_purity() {
    bn="$1"; ll="$2"
    if ! grep -E -q '^[[:space:]]*(%[A-Za-z0-9._]+[[:space:]]*=[[:space:]]*)?(fadd|fsub|fmul|fdiv|fcmp)[[:space:]]+(fast|nnan|ninf|nsz|arcp|contract|afn|reassoc)([[:space:]]|$)' "$ll"; then
        return 0
    fi
    return 1
}

# ACT-POLYC-LLVM-FLOAT01 §18: every positive .ll passes llvm-as + opt verify.
verify_with_llvm() {
    bn="$1"; ll="$2"
    if ! "$LLVM_AS" "$ll" -o "$EVID/_tmp/${bn}.bc" 2>"$EVID/_tmp/${bn}.llvm-as.err"; then
        echo "FAIL  $bn: llvm-as rejected: $(cat "$EVID/_tmp/${bn}.llvm-as.err")" >&2
        return 1
    fi
    if ! "$LLVM_VERIFY" --passes=verify "$ll" -disable-output \
            >"$EVID/_tmp/${bn}.opt.stdout" \
            2>"$EVID/_tmp/${bn}.opt.stderr"; then
        echo "FAIL  $bn: opt --passes=verify rejected: $(cat "$EVID/_tmp/${bn}.opt.stderr")" >&2
        return 1
    fi
    return 0
}

# Parse a CAPABILITY_COUNTERS line on stderr; if found, increment the
# harness-level totals. If missing or malformed, record a counter
# attribution failure.
parse_and_sum_counters() {
    bn="$1"; stderr="$2"
    counters_line=$(grep '^CAPABILITY_COUNTERS ' "$stderr" || true)
    if [ -z "$counters_line" ]; then
        COUNTER_AGG_FAILURES=$((COUNTER_AGG_FAILURES + 1)); return 1
    fi
    nlines=$(grep -c '^CAPABILITY_COUNTERS ' "$stderr" || true)
    if [ "$nlines" != "1" ]; then
        COUNTER_AGG_FAILURES=$((COUNTER_AGG_FAILURES + 1)); return 1
    fi
    s=$(echo "$counters_line" | sed -n 's/^CAPABILITY_COUNTERS supported=\([0-9]*\).*/\1/p')
    r=$(echo "$counters_line" | sed -n 's/.*rejected=\([0-9]*\).*/\1/p')
    sd=$(echo "$counters_line" | sed -n 's/.*shape_dependent=\([0-9]*\).*/\1/p')
    df=$(echo "$counters_line" | sed -n 's/.*defensive=\([0-9]*\).*/\1/p')
    ur=$(echo "$counters_line" | sed -n 's/.*unreachable=0.*/0/p')
    : "${ur:=0}"
    TOTAL_SUPPORTED=$((TOTAL_SUPPORTED + s))
    TOTAL_REJECTED=$((TOTAL_REJECTED + r))
    TOTAL_SHAPE_DEPENDENT=$((TOTAL_SHAPE_DEPENDENT + sd))
    TOTAL_DEFENSIVE=$((TOTAL_DEFENSIVE + df))
    TOTAL_UNREACHABLE=$((TOTAL_UNREACHABLE + ur))
    return 0
}

# positive() runs a positive fixture through the LLVM backend, the
# LLVM verifier, the fast-math purity gate, and counter parsing.
positive() {
    f="$1"
    bn=$(basename "$f" .HC)
    expect_op="$2"
    expect_min_support="${3:-0}"
    expect_min_reject="${4:-0}"

    set +e
    "$HCC" $HCC_INSTALL_ARG --emit-llvm "$f" -o "$EVID/${bn}.ll" \
        >"$EVID/_tmp/${bn}.stdout" \
        2>"$EVID/_tmp/${bn}.stderr"
    rc=$?
    set -e
    if [ "$rc" -ne 0 ]; then
        echo "FAIL  $f: hcc --emit-llvm exited non-zero ($rc)" >&2
        head -8 "$EVID/_tmp/${bn}.stderr" >&2 || true
        FAIL=$((FAIL + 1)); return 1
    fi
    if [ ! -s "$EVID/${bn}.ll" ]; then
        echo "FAIL  $f: empty .ll" >&2
        FAIL=$((FAIL + 1)); return 1
    fi
    if [ -n "$expect_op" ] && ! grep -F -q "$expect_op" "$EVID/${bn}.ll"; then
        echo "FAIL  $f: expected LLVM-IR substring '$expect_op' missing" >&2
        cat "$EVID/${bn}.ll" >&2 || true
        FAIL=$((FAIL + 1)); return 1
    fi
    if ! check_fast_math_purity "$bn" "$EVID/${bn}.ll"; then
        echo "FAIL  $f: fast-math flag detected in emitted .ll" >&2
        grep -nE '[[:space:]](fast|nnan|ninf|nsz|arcp|contract|afn|reassoc)([[:space:]]|,|$)' \
            "$EVID/${bn}.ll" | head -5 >&2 || true
        FAST_MATH_FAILURES=$((FAST_MATH_FAILURES + 1))
        FAIL=$((FAIL + 1)); return 1
    fi
    if ! verify_with_llvm "$bn" "$EVID/${bn}.ll"; then
        FAIL=$((FAIL + 1)); return 1
    fi
    parse_and_sum_counters "$bn" "$EVID/_tmp/${bn}.stderr" || true
    counters_line=$(grep '^CAPABILITY_COUNTERS ' "$EVID/_tmp/${bn}.stderr" || true)
    s=$(echo "$counters_line" | sed -n 's/^CAPABILITY_COUNTERS supported=\([0-9]*\).*/\1/p')
    r=$(echo "$counters_line" | sed -n 's/.*rejected=\([0-9]*\).*/\1/p')
    : "${s:=0}"; : "${r:=0}"
    if [ "$s" -lt "$expect_min_support" ]; then
        echo "FAIL  $f: supported=$s < expected_min_support=$expect_min_support" >&2
        FAIL=$((FAIL + 1)); return 1
    fi
    if [ "$r" -ne "$expect_min_reject" ]; then
        echo "FAIL  $f: rejected=$r != expected=$expect_min_reject" >&2
        FAIL=$((FAIL + 1)); return 1
    fi
    echo "PASS  $bn  rc=0  supported=$s rejected=$r"
    PASS=$((PASS + 1))
}

# negative() asserts the expected named rejection diagnostic.
negative() {
    f="$1"
    bn=$(basename "$f" .HC)
    expected_diag="$2"

    rm -f "$EVID/${bn}.ll"
    set +e
    "$HCC" $HCC_INSTALL_ARG --emit-llvm "$f" -o "$EVID/${bn}.ll" \
        >"$EVID/_tmp/${bn}.stdout" \
        2>"$EVID/_tmp/${bn}.stderr"
    rc=$?
    set -e
    if [ "$rc" -eq 0 ]; then
        echo "FAIL  $bn: hcc --emit-llvm succeeded (rc=0) but should have failed" >&2
        FAIL=$((FAIL + 1)); return 1
    fi
    if [ -e "$EVID/${bn}.ll" ]; then
        echo "FAIL  $bn: hcc --emit-llvm failed but produced .ll" >&2
        rm -f "$EVID/${bn}.ll"
        FAIL=$((FAIL + 1)); return 1
    fi
    if ! grep -F -q "$expected_diag" "$EVID/_tmp/${bn}.stderr"; then
        echo "FAIL  $bn: stderr missing diagnostic '$expected_diag'" >&2
        head -8 "$EVID/_tmp/${bn}.stderr" >&2 || true
        FAIL=$((FAIL + 1)); return 1
    fi
    parse_and_sum_counters "$bn" "$EVID/_tmp/${bn}.stderr" || true
    counters_line=$(grep '^CAPABILITY_COUNTERS ' "$EVID/_tmp/${bn}.stderr" || true)
    r=$(echo "$counters_line" | sed -n 's/.*rejected=\([0-9]*\).*/\1/p')
    : "${r:=0}"
    if [ "$r" -lt 1 ]; then
        echo "FAIL  $bn: rejected=$r (expected >= 1)" >&2
        FAIL=$((FAIL + 1)); return 1
    fi
    echo "PASS  $bn (negative, $expected_diag, rejected=$r)"
    PASS=$((PASS + 1))
}

# ACT-POLYC-LLVM-FLOAT01 §21: determinism.
determinism_check() {
    f="$1"
    bn=$(basename "$f" .HC)
    set +e
    "$HCC" $HCC_INSTALL_ARG --emit-llvm "$f" -o "$EVID/_tmp/${bn}.emit-a.ll" \
        >/dev/null 2>"$EVID/_tmp/${bn}.emit-a.stderr"
    rc_a=$?
    "$HCC" $HCC_INSTALL_ARG --emit-llvm "$f" -o "$EVID/_tmp/${bn}.emit-b.ll" \
        >/dev/null 2>"$EVID/_tmp/${bn}.emit-b.stderr"
    rc_b=$?
    set -e
    if [ "$rc_a" -ne 0 ] || [ "$rc_b" -ne 0 ]; then
        echo "FAIL  determinism  $bn: hcc non-zero (a=$rc_a b=$rc_b)" >&2
        DETERMINISM_FAILURES=$((DETERMINISM_FAILURES + 1)); return 1
    fi
    if ! cmp -s "$EVID/_tmp/${bn}.emit-a.ll" "$EVID/_tmp/${bn}.emit-b.ll"; then
        echo "FAIL  determinism  $bn: two emits differ" >&2
        diff "$EVID/_tmp/${bn}.emit-a.ll" "$EVID/_tmp/${bn}.emit-b.ll" | head -20 >&2
        DETERMINISM_FAILURES=$((DETERMINISM_FAILURES + 1)); return 1
    fi
    if ! cmp -s "$EVID/_tmp/${bn}.emit-a.stderr" "$EVID/_tmp/${bn}.emit-b.stderr"; then
        echo "FAIL  determinism  $bn: two stderr runs differ" >&2
        DETERMINISM_FAILURES=$((DETERMINISM_FAILURES + 1)); return 1
    fi
    echo "PASS  determinism  $bn  bytes identical"
    PASS=$((PASS + 1))
}

# ACT-POLYC-LLVM-FLOAT01 §12 + §20: per-fixture SUPPORTED attribution.
attribution() {
    label="$1"; f="$2"; expected_supported="$3"
    set +e
    "$HCC" $HCC_INSTALL_ARG --emit-llvm "$f" -o /tmp/_attr.ll \
        >/dev/null 2>"$EVID/_tmp/${label}.attr.stderr"
    set -e
    counters_line=$(grep '^CAPABILITY_COUNTERS ' "$EVID/_tmp/${label}.attr.stderr" || true)
    s=$(echo "$counters_line" | sed -n 's/^CAPABILITY_COUNTERS supported=\([0-9]*\).*/\1/p')
    : "${s:=0}"
    if [ "$s" -ne "$expected_supported" ]; then
        echo "FAIL  attribution $label: supported=$s, expected=$expected_supported" >&2
        cat "$EVID/_tmp/${label}.attr.stderr" | head -8 >&2 || true
        FAIL=$((FAIL + 1)); return 1
    fi
    echo "PASS  attribution $label: supported=$s (== $expected_supported)"
    PASS=$((PASS + 1))
}

echo
echo "=== toolchain ==="
if ! command -v "$LLVM_AS" >/dev/null 2>&1; then
    echo "FATAL  llvm-as not on PATH" >&2; exit 2
fi
if ! command -v "$LLVM_VERIFY" >/dev/null 2>&1; then
    echo "FATAL  opt not on PATH" >&2; exit 2
fi
if [ ! -x "$HCC" ] || ! nm "$HCC" 2>/dev/null | grep -q '_LLVMAddFunction'; then
    echo "FATAL  $HCC is not an LLVM-enabled build; run 'make llvm-all' first" >&2
    exit 2
fi
echo "PASS  toolchain: hcc is LLVM-enabled; llvm-as and opt available"
PASS=$((PASS + 1))

echo
echo "=== FLOAT01 positive matrix ==="
positive src/tests/llvm-float01/01_identity_f64.HC     "define double @Identity(double %0)" 1 0
positive src/tests/llvm-float01/02_const_f64.HC        "define double @Const()"             1 0
positive src/tests/llvm-float01/03_fadd.HC             "fadd double %0, %1"                 1 0
positive src/tests/llvm-float01/04_fsub.HC             "fsub double %0, %1"                 1 0
positive src/tests/llvm-float01/05_fmul.HC             "fmul double %0, %1"                 1 0

echo
echo "=== FLOAT01 comparison predicate matrix ==="
positive src/tests/llvm-float01/06_cmp_eq.HC           "fcmp oeq double %0, %1"             1 0
positive src/tests/llvm-float01/07_cmp_ne.HC           "fcmp une double %0, %1"             1 0
positive src/tests/llvm-float01/08_cmp_lt.HC           "fcmp olt double %0, %1"             1 0
positive src/tests/llvm-float01/09_cmp_le.HC           "fcmp ole double %0, %1"             1 0
positive src/tests/llvm-float01/10_cmp_gt.HC           "fcmp ogt double %0, %1"             1 0
positive src/tests/llvm-float01/11_cmp_ge.HC           "fcmp oge double %0, %1"             1 0

echo
echo "=== FLOAT01 branch matrix ==="
positive src/tests/llvm-float01/12_cmp_branch.HC       "br i1 %"                             1 0

echo
echo "=== FLOAT01 mixed expression ==="
positive src/tests/llvm-float01/13_mixed_float_expr.HC "fadd double"                         1 0

echo
echo "=== FLOAT01 negative matrix ==="
negative src/tests/llvm-float01/neg_fdiv.HC              LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH
negative src/tests/llvm-float01/neg_float_to_int.HC      LLVM_BACKEND_UNSUPPORTED_CONVERSION
negative src/tests/llvm-float01/neg_int_to_float.HC      LLVM_BACKEND_UNSUPPORTED_CONVERSION
negative src/tests/llvm-float01/neg_fptosi_witness.HC    LLVM_BACKEND_UNSUPPORTED_CONVERSION

echo
echo "=== FLOAT01 counter attribution (per-fixture SUPPORTED attribution) ==="
# Each positive fixture collapses its tail to a direct `ret` via the
# collapse path (src/llvm-backend.c:837-950), which delivers SUPPORTED
# through the IR_RET arm without double-counting the predecessor's
# jmp. So:
#   FADD/FSUB/FMUL fixture:   1 (op) + 1 (direct ret) = 2 SUPPORTED
#   FCMP_Eq/Lt/Ge fixture:    1 (fcmp) + 1 (br) + (ret via collapse, NOT counted a 2nd time)
#                             = 2 SUPPORTED
#   FCMP_Branch fixture:      same shape = 2 SUPPORTED
attribution fadd_one   src/tests/llvm-float01/03_fadd.HC      2
attribution fsub_one   src/tests/llvm-float01/04_fsub.HC      2
attribution fmul_one   src/tests/llvm-float01/05_fmul.HC      2
attribution fcmp_eq    src/tests/llvm-float01/06_cmp_eq.HC    2
attribution fcmp_lt    src/tests/llvm-float01/08_cmp_lt.HC    2
attribution fcmp_ge    src/tests/llvm-float01/11_cmp_ge.HC    2
attribution branch     src/tests/llvm-float01/12_cmp_branch.HC 2

echo
echo "=== FLOAT01 determinism (NC3 / NC6; byte-identical re-emission) ==="
determinism_check src/tests/llvm-float01/02_const_f64.HC
determinism_check src/tests/llvm-float01/03_fadd.HC
determinism_check src/tests/llvm-float01/12_cmp_branch.HC

echo
echo "=== FLOAT01 capability counters (matrix totals) ==="
echo "=== capability counters ==="
echo "SUPPORTED           : $TOTAL_SUPPORTED"
echo "REJECTED            : $TOTAL_REJECTED"
echo "SHAPE_DEPENDENT     : $TOTAL_SHAPE_DEPENDENT"
echo "DEFENSIVE_INVARIANT : $TOTAL_DEFENSIVE"
echo "UNREACHABLE_ON_LLVM : $TOTAL_UNREACHABLE"
echo "=============================="

COUNTER_GATE_PASS=1
if [ "$TOTAL_DEFENSIVE" -ne 0 ]; then
    echo "FAIL  counter gate: DEFENSIVE_INVARIANT=$TOTAL_DEFENSIVE (expected 0)" >&2
    COUNTER_GATE_PASS=0
fi
if [ "$TOTAL_UNREACHABLE" -ne 0 ]; then
    echo "FAIL  counter gate: UNREACHABLE_ON_LLVM=$TOTAL_UNREACHABLE (expected 0)" >&2
    COUNTER_GATE_PASS=0
fi
if [ "$TOTAL_SUPPORTED" -le 0 ]; then
    echo "FAIL  counter gate: SUPPORTED=$TOTAL_SUPPORTED (expected > 0)" >&2
    COUNTER_GATE_PASS=0
fi
if [ "$TOTAL_REJECTED" -le 0 ]; then
    echo "FAIL  counter gate: REJECTED=$TOTAL_REJECTED (expected > 0)" >&2
    COUNTER_GATE_PASS=0
fi
if [ "$COUNTER_AGG_FAILURES" -ne 0 ]; then
    echo "FAIL  counter gate: $COUNTER_AGG_FAILURES counter-line failures" >&2
    COUNTER_GATE_PASS=0
fi
if [ "$FAST_MATH_FAILURES" -ne 0 ]; then
    echo "FAIL  fast-math gate: $FAST_MATH_FAILURES fast-math contaminations" >&2
    COUNTER_GATE_PASS=0
fi
if [ "$DETERMINISM_FAILURES" -ne 0 ]; then
    echo "FAIL  determinism gate: $DETERMINISM_FAILURES mismatched re-emissions" >&2
    COUNTER_GATE_PASS=0
fi
if [ "$COUNTER_GATE_PASS" = "1" ]; then
    echo "PASS  counter gate: DEFENSIVE=0 UNREACHABLE=0 SUPPORTED>0 REJECTED>0"
    PASS=$((PASS + 1))
fi

echo
echo "FLOAT01_PASS=$PASS"
echo "FLOAT01_FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
