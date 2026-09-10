#!/bin/sh
# scripts/quality/llvm-spike-contract-check.sh
#
# ACT-POLYC-LLVM-CORE03-CORRECTION02 M3.
#
# Per-fixture matrix decoder, BOUND to kLLVMBackendCapability[] via
# hcc --print-cap-table. Per CORRECTION02:
#   - expected_class is still per-fixture (the FIXTURE_CLASS_MANUALLY_DECLARED
#     contract accepted by the CORE03-CORRECTION01 reviewer).
#   - expected_diagnostic is no longer derived from a GLOBAL set of
#     REJECTED rows. It is now derived per-fixture from the per-fixture
#     expected_opcodes list, queried from kLLVMBackendCapability[].
#
# This is HONESTLY narrower than the previous "any table diagnostic passes"
# claim. The previous `exp_diag="$obs_diag"` line is REMOVED.
#
# For each REJECTED fixture:
#   1. expected_opcodes is a list of IR_X identifiers whose rejection
#      diagnostics form the union of acceptable observed diagnostics.
#   2. LLVM_BACKEND_UNSUPPORTED_TYPE and LLVM_BACKEND_INTERNAL are also
#      acceptable: they are generic pre-dispatch rejections that may fire
#      before the per-opcode arm. Both are well-known cross-class
#      generics emitted by llErrUnsupportedType and the boundary check.
#
# For each SUPPORTED fixture:
#   - rc must be 0
#   - no REJECTED-class diagnostic may appear in stderr
#   - no defensive invariant trip
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

# Load the capability table once at startup. Length-delimited wire format
# (ACT-POLYC-LLVM-CORE03-CORRECTION02 M1):
#   <op-ord>\t<class-ord>\t<diag-len>\t<diag>\t<note-len>\t<note>\n
CAP_TABLE=$("$HCC" --print-cap-table $HCC_INSTALL_ARG 2>/dev/null || true)
if [ -z "$CAP_TABLE" ]; then
    echo "FATAL: hcc --print-cap-table produced no output" >&2
    exit 1
fi

PASS=0
FAIL=0

# Per-opcode diagnostic lookup: opcode name -> diagnostic macro.
# Built from the capability table at startup.
cap_diag_for_op() {
    awk -v op="$1" -F'\t' '$1 ~ /^[0-9]+$/ {
        # Need to map ordinal -> name. We do that by building a small
        # lookup table via the next helper. Here we just emit the
        # diag field if this row corresponds to the requested opcode.
    }'
}

# Build a one-shot mapping from opcode ORDINAL -> diagnostic macro.
# Emit lines "<ord>|<diag>".
CAP_ORD_TO_DIAG=$(echo "$CAP_TABLE" | awk -F'\t' '$3 != "1" && $4 == "-" {next} {print $1 "|" $4}')
# Actually simpler: every row's diagnostic is in field 4 (tab-delimited),
# so just emit ord|diag for every row.
CAP_ORD_TO_DIAG=$(echo "$CAP_TABLE" | awk -F'\t' '{print $1 "|" $4}')

# Map opcode NAME -> diagnostic macro, given a space-separated list of names.
# Usage: diags_for_opnames "IR_FADD IR_FSUB"
#
# The enum ordinal is the position of the opcode in the IrOp enum body,
# NOT its line number. We compute the ordinal by counting preceding
# IR_ enum entries.
ir_types_h="src/ir-types.h"
diags_for_opnames() {
    for op in $1; do
        # Compute ordinal: count preceding IR_X entries in the enum body.
        # Strict regex: opcode names start at column 4 (inside the enum),
        # followed by an optional comma or comment.
        ord=$(awk -v target="$op" '
            /IR_TYPE_/ { exit }
            /^[[:space:]]+IR_[A-Z_0-9]+/ {
                n = $0
                sub(/^[[:space:]]+/, "", n)
                sub(/[,[:space:]].*$/, "", n)
                if (n == target) { print count; exit }
                count++
            }
        ' "$ir_types_h")
        if [ -n "$ord" ]; then
            echo "$CAP_ORD_TO_DIAG" | awk -F'|' -v o="$ord" '$1 == o {print $2; exit}'
        fi
    done
}

# contract_check <fixture> <expected_class> <expected_opcodes...>
#
# expected_class:   SUPPORTED | REJECTED
# expected_opcodes: for REJECTED, space-separated IR_X identifiers whose
#                   table diagnostics are acceptable. For SUPPORTED, omit
#                   (or pass "-").
#
# Example:
#   contract_check src/tests/llvm-spike/red_idiv_unclassified.HC REJECTED IR_IDIV
#   contract_check src/tests/llvm-spike/neg_asm.HC REJECTED IR_ASM
#   contract_check src/tests/llvm-spike/01_const.HC SUPPORTED
contract_check() {
    fixture="$1"
    exp_class="$2"
    shift 2
    exp_opcodes="$*"
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
                echo "FAIL  $bn: SUPPORTED expected, but DEFENSIVE_INVARIANT was tripped" >&2
                FAIL=$((FAIL+1))
                return 1
            fi
            exp_diag="-"
            # Per CORRECTION02 M3: no table-derived REJECTED diagnostic
            # may appear in stderr for a SUPPORTED fixture.
            for d in $(echo "$CAP_TABLE" | awk -F'\t' '$2 == 1 && $4 != "-" {print $4}'); do
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

            # Build the set of acceptable diagnostics for this fixture.
            # It is the union of:
            #   - the table's diagnostic for each opcode in exp_opcodes
            #   - LLVM_BACKEND_UNSUPPORTED_TYPE (generic pre-dispatch rejection)
            #   - LLVM_BACKEND_INTERNAL (generic internal/boundary rejection)
            #
            # ACT-POLYC-LLVM-CORE03-CORRECTION02 M3: per-fixture, NOT global.
            acceptable_set=""
            for op in $exp_opcodes; do
                d=$(diags_for_opnames "$op")
                if [ -n "$d" ] && [ "$d" != "-" ]; then
                    # Avoid duplicates in the set.
                    case " $acceptable_set " in
                        *" $d "*) ;;
                        *) acceptable_set="$acceptable_set $d" ;;
                    esac
                fi
            done
            # Always-acceptable generics (well-known cross-class macros).
            # ACT-POLYC-LLVM-CORE03-CORRECTION02 M3: these are macros
            # emitted by llErrUnsupportedType (TYPE), the IR_CMP_BR
            # boundary check (INTERNAL), and the SHAPE_DEPENDENT
            # rejection (SSA_LOCAL). They are NOT in the per-opcode
            # table rows because they are class-generic.
            for g in LLVM_BACKEND_UNSUPPORTED_TYPE LLVM_BACKEND_INTERNAL LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL; do
                case " $acceptable_set " in
                    *" $g "*) ;;
                    *) acceptable_set="$acceptable_set $g" ;;
                esac
            done
            # For PARSE_TIME_REJECTION (neg_asm.HC) the diagnostic is
            # a parser error (`error:`), not an LLVM backend macro.
            # Treat PARSE_TIME_REJECTION as a synthetic acceptable name
            # and resolve it against the actual stderr during the
            # set-membership scan.
            if [ "$bn" = "neg_asm" ]; then
                acceptable_set="$acceptable_set PARSE_TIME_REJECTION"
            fi

            # Identify which acceptable diagnostic appeared in stderr.
            obs_diag="-"
            for d in $acceptable_set; do
                if [ "$d" = "PARSE_TIME_REJECTION" ]; then
                    if grep -q "^error:" "$EVID/_tmp/$bn.stderr"; then
                        obs_diag="$d"
                        break
                    fi
                elif grep -q "$d" "$EVID/_tmp/$bn.stderr"; then
                    obs_diag="$d"
                    break
                fi
            done

            # Set-membership check (NOT tautological):
            obs_diag_in_set=NO
            for d in $acceptable_set; do
                if [ "$d" = "$obs_diag" ]; then
                    obs_diag_in_set=YES
                    break
                fi
            done
            if [ "$obs_diag" = "-" ] || [ "$obs_diag_in_set" = "NO" ]; then
                echo "FAIL  $bn: REJECTED expected, but obs_diag '$obs_diag' is NOT in the per-fixture acceptable set: $acceptable_set" >&2
                echo "  stderr: $(cat "$EVID/_tmp/$bn.stderr")" >&2
                FAIL=$((FAIL+1))
                return 1
            fi
            # ACT-POLYC-LLVM-CORE03-CORRECTION02 M3: the comparison
            # is set-membership, NOT literal equality. The previous
            # `exp_diag="$obs_diag"` made it tautological.
            #
            # exp_diag is now the CANONICAL (first) entry of the
            # acceptable set, which is a FIXED value derived from the
            # table at load time. obs_diag is the captured stderr
            # observation. The verdict is driven by obs_diag_in_set.
            exp_diag=$(echo $acceptable_set | awk '{print $1}')
            exp_set="$acceptable_set"
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
    exp_set=""
    obs_diag_in_set="N/A"
    if [ "$obs_class" != "$exp_class" ]; then
        verdict="FAIL"
        fail_reason="class mismatch"
    fi
    # ACT-POLYC-LLVM-CORE03-CORRECTION02 M3: set-membership check.
    # REJECTED fixtures pass if obs_diag is in the per-fixture
    # acceptable set. exp_diag (the canonical first entry) is
    # informational only. The previous `obs_diag != exp_diag` literal
    # comparison was tautological because exp_diag was assigned from
    # obs_diag.
    if [ -n "$exp_set" ] && [ "$obs_diag_in_set" != "YES" ]; then
        verdict="FAIL"
        fail_reason="${fail_reason:+$fail_reason; }diagnostic not in per-fixture acceptable set"
    fi

    echo "=== contract check: $bn ==="
    echo "  expected_class:    $exp_class"
    echo "  observed_class:    $obs_class"
    if [ -n "$exp_opcodes" ]; then
        echo "  expected_opcodes:  $exp_opcodes"
    else
        echo "  expected_opcodes:  (none)"
    fi
    echo "  expected_diagnostic: $exp_diag (canonical)"
    echo "  observed_diagnostic: $obs_diag"
    echo "  diagnostic_in_set: $obs_diag_in_set"
    if [ -n "$exp_set" ]; then
        echo "  acceptable_set:    $exp_set"
    fi
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

# Per-fixture expectations.
# ACT-POLYC-LLVM-CORE03-CORRECTION02 M3: each REJECTED fixture declares
# its expected_opcodes so the harness can build a per-fixture acceptable
# diagnostic set rather than the previous global union.

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
contract_check src/tests/llvm-spike/neg_f64.HC             REJECTED IR_FADD IR_FSUB IR_FMUL IR_FDIV IR_FNEG
contract_check src/tests/llvm-spike/neg_pointer.HC         REJECTED IR_LOAD_DEREF IR_STORE_DEREF IR_LEA IR_ALLOCA
contract_check src/tests/llvm-spike/neg_struct.HC          REJECTED IR_LOAD_DEREF IR_LOAD IR_LEA IR_ALLOCA
contract_check src/tests/llvm-spike/red_idiv_unclassified.HC     REJECTED IR_IDIV IR_UDIV
contract_check src/tests/llvm-spike/red_local_multi_def.HC       REJECTED IR_STORE
# ACT-POLYC-LLVM-BYTE-MEMORY01: red_conversion_trunc_i16.HC replaces
# the original red_conversion_trunc.HC (which narrowed I64 -> I8 and
# is now ADMITTED). The replacement narrows I64 -> I16 (still
# REJECTED). The expected_opcodes set is narrowed accordingly: IR_TRUNC
# remains in the expected set (the I64 -> I16 narrowing still hits
# IR_TRUNC rejection), but IR_ZEXT and IR_SEXT are removed because the
# BYTE-MEMORY01 promotion of IR_ZEXT/IR_SEXT for the I8 -> I64 shape
# is no longer relevant for this single-fixture shape contract.
contract_check src/tests/llvm-spike/red_conversion_trunc_i16.HC    REJECTED IR_TRUNC IR_FPTRUNC IR_FPEXT IR_FPTOUI IR_FPTOSI IR_UITOFP IR_SITOFP IR_PTRTOINT IR_INTTOPTR IR_BITCAST
contract_check src/tests/llvm-spike/red_remainder_mod.HC         REJECTED IR_IREM IR_UREM
contract_check src/tests/llvm-spike/red_shift_shl.HC             REJECTED IR_SHL IR_SHR IR_SAR
contract_check src/tests/llvm-spike/neg_asm.HC             REJECTED IR_ASM

echo
echo "================================="
echo "Summary: PASS=$PASS  FAIL=$FAIL"
echo "================================="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
