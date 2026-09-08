#!/bin/sh
# scripts/quality/llvm-spike-contract-check.sh
#
# ACT-POLYC-LLVM-CORE03: per-fixture matrix decoder.
#
# For each fixture, this script:
#   1. Invokes hcc --emit-llvm (if the fixture has a .expected
#      file with SUPPORTED) OR hcc --emit-llvm (and asserts rc!=0
#      if the .expected says REJECTED).
#   2. Parses stderr and stdout for:
#      - the contract validation message ("LLVM backend capability
#        contract: ok (N rows)");
#      - any DEFENSIVE_INVARIANT_TRIPPED occurrences;
#      - any LLVM_BACKEND_UNSUPPORTED_* diagnostic (negative case).
#   3. Compares (observed_class, observed_diagnostic) against
#      (.expected).
#   4. Prints a `=== contract check: <fixture> ===` block per
#      fixture and increments PASS/FAIL counters.
#
# This script is meant to be a strict superset of the existing
# llvm-spike-test.sh harness — it does NOT replace the existing
# harness; it adds the contract-check layer on top.
#
# No network. No execution. No native fallback.

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

EVID="$REPO_ROOT/evidence/llvmspike01-core03"
mkdir -p "$EVID"
mkdir -p "$EVID/_tmp"
trap 'rm -rf "$EVID/_tmp"' EXIT

HCC=./hcc
HCC_INSTALL_DIR=${HCC_INSTALL_DIR:-}
HCC_INSTALL_ARG=""
if [ -n "$HCC_INSTALL_DIR" ]; then
    HCC_INSTALL_ARG="--install-dir=$HCC_INSTALL_DIR"
fi

PASS=0
FAIL=0

# contract_check <fixture> <expected_class> <expected_diagnostic>
#
# expected_class:    SUPPORTED | REJECTED
# expected_diagnostic: <LLVM_BACKEND_UNSUPPORTED_*> | - | PARSE_TIME_REJECTION
contract_check() {
    fixture="$1"
    exp_class="$2"
    exp_diag="$3"
    bn=$(basename "$fixture" .HC)

    case "$exp_class" in
        SUPPORTED)
            if ! "$HCC" --emit-llvm $HCC_INSTALL_ARG "$fixture" \
                -o "$EVID/_tmp/$bn.ll" \
                >"$EVID/_tmp/$bn.stdout" 2>"$EVID/_tmp/$bn.stderr"; then
                echo "FAIL  $bn: SUPPORTED expected, but rc!=0" >&2
                echo "  stderr: $(cat "$EVID/_tmp/$bn.stderr")" >&2
                FAIL=$((FAIL+1))
                return 1
            fi
            obs_class=SUPPORTED
            # Look for the most specific defensive_trip signal in stderr.
            obs_diag="-"
            if grep -q "LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED" \
                "$EVID/_tmp/$bn.stderr"; then
                obs_diag=LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED
            fi
            ;;
        REJECTED)
            if [ "$exp_diag" = "PARSE_TIME_REJECTION" ]; then
                # neg_asm.HC: parse-time, not backend. Don't run --emit-llvm.
                "$HCC" $HCC_INSTALL_ARG "$fixture" -o /tmp/__neg_${bn}_out__ \
                    >"$EVID/_tmp/$bn.stdout" 2>"$EVID/_tmp/$bn.stderr" \
                    && rc=0 || rc=$?
                rm -f /tmp/__neg_${bn}_out__
                if [ "$rc" -ne 0 ] && grep -q "error:" "$EVID/_tmp/$bn.stderr"; then
                    obs_class=REJECTED
                    obs_diag=PARSE_TIME_REJECTION
                else
                    echo "FAIL  $bn: PARSE_TIME_REJECTION expected" >&2
                    FAIL=$((FAIL+1))
                    return 1
                fi
            else
                set +e
                "$HCC" --emit-llvm $HCC_INSTALL_ARG "$fixture" \
                    -o "$EVID/_tmp/$bn.ll" \
                    >"$EVID/_tmp/$bn.stdout" 2>"$EVID/_tmp/$bn.stderr"
                rc=$?
                set -e
                if [ "$rc" -eq 0 ]; then
                    echo "FAIL  $bn: REJECTED expected, but rc=0" >&2
                    FAIL=$((FAIL+1))
                    return 1
                fi
                # Find the most specific diagnostic token.
                obs_class=REJECTED
                obs_diag=$(grep -oE 'LLVM_BACKEND_[A-Z_]+' \
                    "$EVID/_tmp/$bn.stderr" | head -1 || true)
                if [ -z "$obs_diag" ]; then
                    obs_diag="-"
                fi
            fi
            ;;
        *)
            echo "FAIL  $bn: unknown expected_class '$exp_class'" >&2
            FAIL=$((FAIL+1))
            return 1
            ;;
    esac

    # Also check that the contract validation message is present in stderr.
    contract_ok=NO
    if grep -q "LLVM backend capability contract: ok" \
        "$EVID/_tmp/$bn.stderr"; then
        contract_ok=YES
    fi

    # Defensive_trips: count DEFENSIVE_INVARIANT_TRIPPED occurrences.
    defensive_trips=0
    if [ -f "$EVID/_tmp/$bn.stderr" ]; then
        defensive_trips=$(grep -c "LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED" \
            "$EVID/_tmp/$bn.stderr" || true)
    fi

    verdict="PASS"
    fail_reason=""
    if [ "$obs_class" != "$exp_class" ]; then
        verdict="FAIL"
        fail_reason="class mismatch"
    fi
    if [ "$obs_diag" != "$exp_diag" ]; then
        verdict="FAIL"
        fail_reason="${fail_reason:+$fail_reason; }diagnostic mismatch"
    fi

    echo "=== contract check: $bn ==="
    echo "  expected_class:    $exp_class"
    echo "  observed_class:    $obs_class"
    echo "  expected_diagnostic: $exp_diag"
    echo "  observed_diagnostic: $obs_diag"
    echo "  contract_validated: $contract_ok"
    echo "  defensive_trips:   $defensive_trips"
    if [ -n "$fail_reason" ]; then
        echo "  fail_reason:       $fail_reason"
    fi
    echo "  verdict:           $verdict"

    if [ "$verdict" = "PASS" ]; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
    fi
}

# Per-fixture expectations. The 18 harness fixtures are mapped
# 1:1 to a (class, diagnostic) pair. Adding a new fixture requires
# adding an entry here.
contract_check src/tests/llvm-spike/01_const.HC            SUPPORTED -
contract_check src/tests/llvm-spike/02_add.HC              SUPPORTED -
contract_check src/tests/llvm-spike/03_sub_mul.HC          SUPPORTED -
contract_check src/tests/llvm-spike/04_cmp_branch.HC       SUPPORTED -
contract_check src/tests/llvm-spike/05_call.HC             SUPPORTED -
contract_check src/tests/llvm-spike/red_pred_eq.HC         SUPPORTED -
contract_check src/tests/llvm-spike/red_pred_ne.HC         SUPPORTED -
contract_check src/tests/llvm-spike/red_pred_slt.HC        SUPPORTED -
contract_check src/tests/llvm-spike/red_pred_sle.HC        SUPPORTED -
contract_check src/tests/llvm-spike/red_pred_sgt.HC        SUPPORTED -
contract_check src/tests/llvm-spike/red_pred_sge.HC        SUPPORTED -
contract_check src/tests/llvm-spike/neg_f64.HC             REJECTED  LLVM_BACKEND_UNSUPPORTED_TYPE
contract_check src/tests/llvm-spike/neg_pointer.HC         REJECTED  LLVM_BACKEND_UNSUPPORTED_TYPE
contract_check src/tests/llvm-spike/neg_struct.HC          REJECTED  LLVM_BACKEND_UNSUPPORTED_TYPE
contract_check src/tests/llvm-spike/red_idiv_unclassified.HC     REJECTED  LLVM_BACKEND_UNSUPPORTED_INT_DIVISION
contract_check src/tests/llvm-spike/red_local_multi_def.HC       REJECTED  LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL
contract_check src/tests/llvm-spike/red_conversion_trunc.HC      REJECTED  LLVM_BACKEND_UNSUPPORTED_CONVERSION
contract_check src/tests/llvm-spike/red_remainder_mod.HC         REJECTED  LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER
contract_check src/tests/llvm-spike/red_shift_shl.HC             REJECTED  LLVM_BACKEND_UNSUPPORTED_INT_SHIFT
contract_check src/tests/llvm-spike/neg_asm.HC             REJECTED  PARSE_TIME_REJECTION

echo
echo "================================="
echo "Summary: PASS=$PASS  FAIL=$FAIL"
echo "================================="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
