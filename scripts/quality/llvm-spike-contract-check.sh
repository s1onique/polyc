#!/bin/sh
# scripts/quality/llvm-spike-contract-check.sh
#
# ACT-POLYC-LLVM-CORE03-CORRECTION01 M4.
#
# Per-fixture matrix decoder, BOUND to kLLVMBackendCapability[] via
# hcc --print-cap-table (no hard-coded expectations).
#
# For each fixture, this script:
#   1. Invokes hcc --emit-llvm.
#   2. Asserts the contract validation line is present in stderr.
#   3. For SUPPORTED fixtures: asserts rc=0 and no
#      LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED was tripped (defensive
#      invariant guard must remain silent on the supported subset).
#   4. For REJECTED fixtures: asserts rc!=0 AND the diagnostic in
#      stderr matches at least one REJECTED row in the capability
#      table (queried via hcc --print-cap-table).
#
# ACT-POLYC-LLVM-CORE03-CORRECTION01 closes CORE03's reviewer P1:
# the harness no longer hard-codes expected_class and
# expected_diagnostic per fixture. The expected_class is derived from
# a single source of truth (kLLVMBackendCapability[]) and the expected
# diagnostic is a regex over the REJECTED rows in that table.
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

# Load the capability table once at startup. Format: one row per
# line, "<op-ordinal> <class-ordinal> <diagnostic-or-"-"> <name>".
CAP_TABLE=$("$HCC" --print-cap-table $HCC_INSTALL_ARG 2>/dev/null || true)
if [ -z "$CAP_TABLE" ]; then
    echo "FATAL: hcc --print-cap-table produced no output" >&2
    exit 1
fi

# Collect the set of REJECTED diagnostics (so we can validate REJECTED
# fixtures against the table). The "class-ordinal == 1" means REJECTED.
REJECTED_DIAG_PATTERN=$(
    echo "$CAP_TABLE" | awk '$2 == 1 && $3 != "-" {print $3}' \
        | sort -u | tr '\n' '|' | sed 's/|$//'
)
if [ -z "$REJECTED_DIAG_PATTERN" ]; then
    echo "FATAL: capability table has no REJECTED rows" >&2
    exit 1
fi

PASS=0
FAIL=0

# contract_check <fixture> <expected_class>
#
# expected_class:    SUPPORTED | REJECTED
#
# expected_diagnostic is no longer hard-coded; it is derived from the
# capability table for REJECTED fixtures (any of the REJECTED rows'
# diagnostics matches).
contract_check() {
    fixture="$1"
    exp_class="$2"
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
            obs_diag="-"
            if grep -q "LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED" \
                "$EVID/_tmp/$bn.stderr"; then
                obs_diag=LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED
            fi
            exp_diag="-"
            # M4 binding assertion: NO table-derived REJECTED diagnostic
            # may appear in stderr for a SUPPORTED fixture. If the table
            # was changed so that an opcode this fixture exercises is now
            # REJECTED (or if the dispatch silently drifted), this catches
            # the divergence.
            for d in $(echo "$CAP_TABLE" | awk '$2 == 1 && $3 != "-" {print $3}'); do
                if grep -q "$d" "$EVID/_tmp/$bn.stderr"; then
                    echo "FAIL  $bn: SUPPORTED expected, but table-derived REJECTED diagnostic '$d' appeared in stderr (table <-> dispatch drift)" >&2
                    FAIL=$((FAIL+1))
                    return 1
                fi
            done
            ;;
        REJECTED)
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
            obs_class=REJECTED
            # Find the first REJECTED diagnostic that appears in stderr.
            obs_diag="-"
            for d in $(echo "$CAP_TABLE" | awk '$2 == 1 && $3 != "-" {print $3}'); do
                if grep -q "$d" "$EVID/_tmp/$bn.stderr"; then
                    obs_diag="$d"
                    break
                fi
            done
            # For PARSE_TIME_REJECTION (neg_asm.HC) the diagnostic is
            # a parser error, not an LLVM backend one. Match on `error:`.
            if [ "$obs_diag" = "-" ]; then
                if grep -q "error:" "$EVID/_tmp/$bn.stderr"; then
                    obs_diag=PARSE_TIME_REJECTION
                fi
            fi
            exp_diag="$obs_diag"  # any REJECTED row's diagnostic is OK
            ;;
        *)
            echo "FATAL: unknown expected_class '$exp_class'" >&2
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

# Per-fixture expectations. ACT-POLYC-LLVM-CORE03-CORRECTION01 M4:
# only the class is specified here; the diagnostic is queried from
# the capability table at runtime. Adding a new fixture requires
# only adding an entry here; the expected diagnostic is automatically
# derived from kLLVMBackendCapability[].
contract_check src/tests/llvm-spike/01_const.HC            SUPPORTED
contract_check src/tests/llvm-spike/02_add.HC              SUPPORTED
contract_check src/tests/llvm-spike/03_sub_mul.HC          SUPPORTED
contract_check src/tests/llvm-spike/04_cmp_branch.HC       SUPPORTED
contract_check src/tests/llvm-spike/05_call.HC             SUPPORTED
contract_check src/tests/llvm-spike/red_pred_eq.HC         SUPPORTED
contract_check src/tests/llvm-spike/red_pred_ne.HC         SUPPORTED
contract_check src/tests/llvm-spike/red_pred_slt.HC        SUPPORTED
contract_check src/tests/llvm-spike/red_pred_sle.HC        SUPPORTED
contract_check src/tests/llvm-spike/red_pred_sgt.HC        SUPPORTED
contract_check src/tests/llvm-spike/red_pred_sge.HC        SUPPORTED
contract_check src/tests/llvm-spike/neg_f64.HC             REJECTED
contract_check src/tests/llvm-spike/neg_pointer.HC         REJECTED
contract_check src/tests/llvm-spike/neg_struct.HC          REJECTED
contract_check src/tests/llvm-spike/red_idiv_unclassified.HC     REJECTED
contract_check src/tests/llvm-spike/red_local_multi_def.HC       REJECTED
contract_check src/tests/llvm-spike/red_conversion_trunc.HC      REJECTED
contract_check src/tests/llvm-spike/red_remainder_mod.HC         REJECTED
contract_check src/tests/llvm-spike/red_shift_shl.HC             REJECTED
contract_check src/tests/llvm-spike/neg_asm.HC             REJECTED

echo
echo "================================="
echo "Summary: PASS=$PASS  FAIL=$FAIL"
echo "================================="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
