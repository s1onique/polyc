#!/bin/sh
# scripts/quality/ir-return-slot-forwarding01-test.sh
#
# ACT-POLYC-IR-RETURN-SLOT-FORWARDING01 GREEN harness.
#
# Verifies that the irForwardReturnSlot single-predecessor guard
# keeps the three previously-failing multi-predecessor exit
# fixtures producing verifier-valid LLVM IR (hcc EXIT=0 + llvm-as
# PASS + opt --passes=verify PASS), AND that the structural NC
# fixture still has the rewrite fire on its single-predecessor
# exit (--dump-ir post-optimisation shows direct return of the
# function-local, not the load-result tmp).
#
# This is a separate harness from llvm-byte-memory01-test.sh
# because:
#
#   1. The defect is a generic neutral-IR optimizer defect,
#      not a byte-memory01-specific defect (the I64-only
#      probes i64_collapse_probe.HC and single_cond_probe.HC
#      reproduce the same dominance class).
#   2. The reviewer explicitly required a dedicated harness
#      for this ACT.
#
# Sections:
#   toolchain
#   R1: pos_b0_compare_digit GREEN (hcc + llvm-as + opt verify)
#   R2: i64_collapse_probe   GREEN (hcc + llvm-as + opt verify)
#   R3: single_cond_probe    GREEN (hcc + llvm-as + opt verify)
#   NC: safe_fwd_single_pred structural rewrite still fires
#       AND compile + llvm-as + opt verify all PASS
#   summary

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

EVID="$REPO_ROOT/evidence/llvm-ir-return-slot-forwarding01"
TMP="$EVID/_tmp"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

HCC=${HCC:-./hcc}
HCC_INSTALL_DIR=${HCC_INSTALL_DIR:-/tmp/polyc-install}
HCC_INSTALL_ARG="--install-dir=$HCC_INSTALL_DIR"
LLVM_AS=${LLVM_AS:-llvm-as}
LLVM_OPT=${LLVM_OPT:-opt}

PASS=0
FAIL=0

section() { printf '\n=== %s ===\n' "$1"; }

# ---- toolchain ----
section "toolchain"
if [ ! -x "$HCC" ]; then echo "FAIL  HCC not found at $HCC"; exit 2; fi
if ! command -v "$LLVM_AS" >/dev/null 2>&1; then
    echo "FAIL  llvm-as not in PATH"; exit 2
fi
if ! command -v "$LLVM_OPT" >/dev/null 2>&1; then
    echo "FAIL  opt not in PATH"; exit 2
fi
echo "PASS  hcc + llvm-as + opt available"
PASS=$((PASS+1))

# ---- R1, R2, R3: RED fixtures must be GREEN ----
for fx in pos_b0_compare_digit i64_collapse_probe single_cond_probe ; do
    section "R: $fx"
    FX_PATH="src/tests/llvm-byte-memory01/${fx}.HC"
    if [ ! -f "$FX_PATH" ]; then
        echo "FAIL  $FX_PATH missing"
        FAIL=$((FAIL+1)); continue
    fi
    if ! "$HCC" --emit-llvm $HCC_INSTALL_ARG \
            -o "$TMP/${fx}.ll" "$FX_PATH" \
            2>"$TMP/${fx}.err"; then
        echo "FAIL  $fx: hcc did not exit 0"
        cat "$TMP/${fx}.err"
        FAIL=$((FAIL+1)); continue
    fi
    if [ ! -s "$TMP/${fx}.ll" ]; then
        echo "FAIL  $fx: .ll not produced or empty"
        cat "$TMP/${fx}.err"
        FAIL=$((FAIL+1)); continue
    fi
    if ! "$LLVM_AS" "$TMP/${fx}.ll" -o "$TMP/${fx}.bc" 2>"$TMP/${fx}.as.err"; then
        echo "FAIL  $fx: llvm-as rejected .ll"
        cat "$TMP/${fx}.as.err"
        FAIL=$((FAIL+1)); continue
    fi
    if ! "$LLVM_OPT" --passes=verify "$TMP/${fx}.bc" -o /dev/null \
            2>"$TMP/${fx}.opt.err"; then
        echo "FAIL  $fx: opt --passes=verify rejected .bc"
        cat "$TMP/${fx}.opt.err"
        FAIL=$((FAIL+1)); continue
    fi
    echo "PASS  $fx: hcc + llvm-as + opt --passes=verify"
    PASS=$((PASS+1))
done

# ---- NC: structural control ----
section "NC: safe_fwd_single_pred (structural)"
FX_PATH="src/tests/llvm-byte-memory01/safe_fwd_single_pred.HC"
if [ ! -f "$FX_PATH" ]; then
    echo "FAIL  $FX_PATH missing"
    FAIL=$((FAIL+1))
else
    # 1. Compile path must succeed and produce verifier-valid .ll.
    if ! "$HCC" --emit-llvm $HCC_INSTALL_ARG \
            -o "$TMP/safe_fwd_single_pred.ll" "$FX_PATH" \
            2>"$TMP/safe_fwd_single_pred.err"; then
        echo "FAIL  safe_fwd_single_pred: hcc did not exit 0"
        cat "$TMP/safe_fwd_single_pred.err"
        FAIL=$((FAIL+1))
    elif ! "$LLVM_AS" "$TMP/safe_fwd_single_pred.ll" \
            -o "$TMP/safe_fwd_single_pred.bc" \
            2>"$TMP/safe_fwd_single_pred.as.err"; then
        echo "FAIL  safe_fwd_single_pred: llvm-as rejected .ll"
        cat "$TMP/safe_fwd_single_pred.as.err"
        FAIL=$((FAIL+1))
    elif ! "$LLVM_OPT" --passes=verify \
            "$TMP/safe_fwd_single_pred.bc" -o /dev/null \
            2>"$TMP/safe_fwd_single_pred.opt.err"; then
        echo "FAIL  safe_fwd_single_pred: opt --passes=verify rejected .bc"
        cat "$TMP/safe_fwd_single_pred.opt.err"
        FAIL=$((FAIL+1))
    else
        echo "PASS  safe_fwd_single_pred: hcc + llvm-as + opt --passes=verify"
        PASS=$((PASS+1))
    fi
    # 2. Structural proof: rewrite must STILL fire on this single-
    #    predecessor exit. After basic optimisations, the dump-ir
    #    must show `ret %l6` (function-local) not `ret %t8`
    #    (load-result tmp).
    if ! "$HCC" --dump-ir $HCC_INSTALL_ARG "$FX_PATH" \
            >"$TMP/safe_fwd_single_pred.dump" \
            2>"$TMP/safe_fwd_single_pred.dump.err"; then
        echo "FAIL  safe_fwd_single_pred: --dump-ir failed"
        cat "$TMP/safe_fwd_single_pred.dump.err"
        FAIL=$((FAIL+1))
    else
        # After the "===== After basic optimisations =====" marker,
        # the ret operand of the merged block must be %l6 (local),
        # not %t8 (load-result tmp).
        if awk '
            /^===== After basic optimisations =====/ { p = 1; next }
            p && /^[[:space:]]*ret[[:space:]]+%l6/ { found = 1; exit }
            p && /^[[:space:]]*ret[[:space:]]+%t8/ { bad = 1; exit }
            END { exit (found && !bad) ? 0 : 1 }
        ' "$TMP/safe_fwd_single_pred.dump"; then
            echo "PASS  safe_fwd_single_pred: structural (ret %l6 post-opt)"
            PASS=$((PASS+1))
        else
            echo "FAIL  safe_fwd_single_pred: rewrite did NOT fire"
            echo "      (post-opt ret operand is not %l6 function-local)"
            sed -n '/===== After basic optimisations =====/,$p' \
                "$TMP/safe_fwd_single_pred.dump" | head -10
            FAIL=$((FAIL+1))
        fi
    fi
fi

# ---- summary ----
section "summary"
echo "IR_RETURN_SLOT_FORWARDING01_PASS=$PASS"
echo "IR_RETURN_SLOT_FORWARDING01_FAIL=$FAIL"
if [ "$FAIL" = 0 ]; then
    echo "STATUS=PASS"
else
    echo "STATUS=FAIL"
fi
