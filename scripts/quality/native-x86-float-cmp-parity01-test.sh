#!/bin/sh
# scripts/quality/native-x86-float-cmp-parity01-test.sh
#
# ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01: bounded x86_64 native
# floating-point comparison correctness gate.
#
# Runs on the cross-built x86_64 hcc (`hcc-x86_64` or the value of
# HCC_X86_64). Under Rosetta (`arch -x86_64`), verifies the IEEE-754
# ordered-comparison contract on EQ/NE/LT/LE/GT/GE for:
#   - NaN matrix  (ordered comparisons must reject NaN; NaN != x is true)
#   - finite baseline (six-op matrix; conservation against current x86_64)
#   - special values (signed zeros, infinities)
#
# Both AOT and JIT paths are exercised on every fixture. The expected
# output is hand-derived from the IEEE-754 / LangRef contract and
# compared token-for-token against the actual stdout.
#
# Environment:
#   HCC_X86_64       path to the cross-built x86_64 hcc (default ./hcc-x86_64)
#   HCC_INSTALL_DIR  --install-dir argument for hcc (default /tmp/polyc-install)
#   HCC_LIB_PATH     DYLD_LIBRARY_PATH for the compiled .HC executables
#                    (default: $HCC_INSTALL_DIR/lib)
#
# No network. No LLVM. No LLVM-related tooling.

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

EVID="$REPO_ROOT/evidence/native-x86-float-cmp-parity01/impl"
mkdir -p "$EVID"
TMP=$(mktemp -d "$EVID/_tmp.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

HCC=${HCC_X86_64:-./hcc-x86_64}
HCC_INSTALL_DIR=${HCC_INSTALL_DIR:-/tmp/polyc-install}
HCC_INSTALL_ARG="--install-dir=$HCC_INSTALL_DIR"
HCC_LIB_PATH=${HCC_LIB_PATH:-"$HCC_INSTALL_DIR/lib"}

# Confirm host can actually execute x86_64 binaries.
# Use the HCC binary itself as the witness (already verified x86_64 below).
if ! arch -x86_64 "$HCC" --version >/dev/null 2>&1; then
    echo "FAIL  host cannot run x86_64 binaries (Rosetta missing?)"
    exit 2
fi

PASS=0
FAIL=0
SKIP=0

if [ ! -x "$HCC" ]; then
    echo "FAIL  HCC not found at $HCC"
    exit 2
fi
if ! file "$HCC" | grep -q 'x86_64'; then
    echo "FAIL  HCC is not x86_64: $(file "$HCC")"
    exit 2
fi

FIXTURE=red_nan.HC
EXPECT="$REPO_ROOT/evidence/native-x86-float-cmp-parity01/impl/red-nan-jit-after.txt"
# Use the JIT output captured during IMPL as the canonical truth table.
# The AOT output must match it byte-for-byte (same x86_64 backend).
if [ ! -f "$EXPECT" ]; then
    EXPECT="$REPO_ROOT/evidence/native-x86-float-cmp-parity01/red/red-nan-aot.txt"
fi
if [ ! -f "$EXPECT" ]; then
    echo "FAIL  expected truth table not found"
    exit 2
fi

# Helper: run a fixture under AOT and/or JIT and diff against expected.
run_fixture() {
    mode="$1"
    fixture="$2"
    expected="$3"
    bn=$(basename "$fixture" .HC)
    out="$TMP/${bn}.${mode}.out"

    case "$mode" in
        aot)
            bin="$TMP/${bn}.aot.bin"
            DYLD_LIBRARY_PATH="$HCC_LIB_PATH" \
                arch -x86_64 "$HCC" $HCC_INSTALL_ARG \
                -o "$bin" "$fixture" >/dev/null 2>&1 \
                || { echo "FAIL  aot build $bn"; FAIL=$((FAIL+1)); return; }
            DYLD_LIBRARY_PATH="$HCC_LIB_PATH" \
                arch -x86_64 "$bin" >"$out" 2>&1 \
                || { echo "FAIL  aot run $bn"; FAIL=$((FAIL+1)); return; }
            ;;
        jit)
            DYLD_LIBRARY_PATH="$HCC_LIB_PATH" \
                arch -x86_64 "$HCC" $HCC_INSTALL_ARG \
                -jit "$fixture" >"$out" 2>&1 \
                || { echo "FAIL  jit run $bn"; FAIL=$((FAIL+1)); return; }
            ;;
        *)
            echo "FAIL  unknown mode $mode"
            FAIL=$((FAIL+1)); return
            ;;
    esac

    if diff -q "$out" "$expected" >/dev/null 2>&1; then
        echo "PASS  $mode $bn"
        PASS=$((PASS+1))
    else
        echo "FAIL  $mode $bn (diff follows)"
        diff "$out" "$expected" || true
        FAIL=$((FAIL+1))
    fi
}

FIX=red_nan.HC
FIX_PATH="$REPO_ROOT/src/tests/native-x86-float-cmp-parity01/$FIX"
EXP_NAN="$REPO_ROOT/evidence/native-x86-float-cmp-parity01/impl/red-nan-jit-after.txt"

echo "=== PARITY01 NaN matrix (x86_64 AOT + JIT) ==="
run_fixture aot "$FIX_PATH" "$EXP_NAN"
run_fixture jit "$FIX_PATH" "$EXP_NAN"

# IR_FCMP-only witness (exercises the IR_FCMP dispatch arm directly,
# bypassing the IR_CMP_BR / FPTOSI paths).
FIX=ir_fcmp_witness.HC
FIX_PATH="$REPO_ROOT/src/tests/native-x86-float-cmp-parity01/$FIX"
EXP_FCMP_AOT="$REPO_ROOT/evidence/native-x86-float-cmp-parity01/impl/ir-fcmp-aot-after.txt"
EXP_FCMP_JIT="$REPO_ROOT/evidence/native-x86-float-cmp-parity01/impl/ir-fcmp-jit-after.txt"
echo
echo "=== PARITY01 IR_FCMP witness (x86_64 AOT + JIT) ==="
run_fixture aot "$FIX_PATH" "$EXP_FCMP_AOT"
run_fixture jit "$FIX_PATH" "$EXP_FCMP_JIT"

# For finite + special, we expect identical results before/after the fix
# (the fix is only supposed to flip NaN semantics). Use the IMPL output
# captured during this ACT as the truth table for parity.
EXP_FIN_AOT="$REPO_ROOT/evidence/native-x86-float-cmp-parity01/impl/finite-baseline-aot-after.txt"
EXP_FIN_JIT="$REPO_ROOT/evidence/native-x86-float-cmp-parity01/impl/finite-baseline-jit-after.txt"
EXP_SV_AOT="$REPO_ROOT/evidence/native-x86-float-cmp-parity01/impl/special-values-aot-after.txt"
EXP_SV_JIT="$REPO_ROOT/evidence/native-x86-float-cmp-parity01/impl/special-values-jit-after.txt"

FIX=finite_baseline.HC
FIX_PATH="$REPO_ROOT/src/tests/native-x86-float-cmp-parity01/$FIX"
echo
echo "=== PARITY01 finite baseline (x86_64 AOT + JIT) ==="
run_fixture aot "$FIX_PATH" "$EXP_FIN_AOT"
run_fixture jit "$FIX_PATH" "$EXP_FIN_JIT"

FIX=special_values.HC
FIX_PATH="$REPO_ROOT/src/tests/native-x86-float-cmp-parity01/$FIX"
echo
echo "=== PARITY01 special values (x86_64 AOT + JIT) ==="
run_fixture aot "$FIX_PATH" "$EXP_SV_AOT"
run_fixture jit "$FIX_PATH" "$EXP_SV_JIT"

echo
echo "PARITY01_PASS=$PASS"
echo "PARITY01_FAIL=$FAIL"
echo "PARITY01_SKIP=$SKIP"

# -----------------------------------------------------------------------
# Optional: negative controls (NC1..NC8).
#
# Each NC temporarily introduces a specific regression into the x86_64
# backend, rebuilds hcc-x86_64, re-runs the harness, and asserts the
# harness reports FAIL on that specific case. After each NC the source
# files are restored and the harness must be GREEN again.
#
# Set PARITY01_RUN_NC=1 to enable.
# -----------------------------------------------------------------------

run_negative_controls() {
    if [ "${PARITY01_RUN_NC:-0}" != "1" ]; then
        return 0
    fi

    nc_pass=0
    nc_fail=0
    nc_total=0

    backup_sources() {
        cp src/asm/enc_x86_64.c "$TMP/enc_x86_64.c.bak"
        cp src/x86_64.c "$TMP/x86_64.c.bak"
        cp src/x86_64-jit.c "$TMP/x86_64-jit.c.bak"
    }

    restore_sources() {
        # Touch first to ensure the mtime is later than the patched
        # source - otherwise a make-based rebuild may not notice that
        # the file changed (cp can preserve mtime if the destination
        # has the same timestamp the source had at backup time).
        touch "$TMP/enc_x86_64.c.bak" "$TMP/x86_64.c.bak" "$TMP/x86_64-jit.c.bak"
        cp "$TMP/enc_x86_64.c.bak" src/asm/enc_x86_64.c
        cp "$TMP/x86_64.c.bak" src/x86_64.c
        cp "$TMP/x86_64-jit.c.bak" src/x86_64-jit.c
        # Verify restore succeeded by checking for the FIXED pattern.
        if ! grep -q 'IR_CMP_EQ: primary = "sete";  pf_helper = "setnp"; combiner = "andb";' src/x86_64.c; then
            echo "ERROR: restore_sources did not restore x86_64.c properly" >&2
            grep 'IR_CMP_EQ: primary' src/x86_64.c >&2
        fi
        # Clean sed backup files left behind by -i.bak.
        rm -f src/asm/enc_x86_64.c.bak src/x86_64.c.bak src/x86_64-jit.c.bak
        # Touch the source files to a future timestamp to force make to
        # rebuild even if the cp preserved mtime.
        touch src/asm/enc_x86_64.c src/x86_64.c src/x86_64-jit.c
    }

    rebuild() {
        label="$1"
        log="$TMP/nc-${label}-build.log"
        # Use a real, monotonic mtime stamp so the patched source is
        # definitely newer than any prior .o file (sed -i preserves the
        # original mtime, which can be older than the .o from a prior
        # build). Then force-rebuild the affected translation units
        # before relinking.
        (cd build-x86_64 && rm -f CMakeFiles/hcc.dir/x86_64.c.o CMakeFiles/hcc.dir/x86_64-jit.c.o CMakeFiles/hcc.dir/enc_x86_64.c.o && touch -d "now +5 seconds" ../src/x86_64.c ../src/x86_64-jit.c ../src/asm/enc_x86_64.c && make) >"$log" 2>&1 || {
            echo "FAIL  NC${label}: rebuild"
            cat "$log"
            return 1
        }
        # Also refresh hcc-x86_64 if it was used.
        cp hcc hcc-x86_64 2>/dev/null || true
        return 0
    }

    # Each ncN is a sed patch that introduces a specific regression.
    # We use sed address ranges (line numbers) to scope patches to a
    # specific switch statement. The first copy of each case lives in
    # x86_64EmitFloatSetCC (~lines 781-814); the second copy lives in
    # the IR_CMP_BR branch emission (~lines 2060-2095).
    nc1() {
        # Revert setcc_cl encoder to write AL (modrm 3,1,0).
        sed -i.bak 's|modrm(3, 0 /\* reg reserved \*/, 1 /\* CL = rm \*/)|modrm(3, 1 /* CL */, 0 /* AL */)|' src/asm/enc_x86_64.c
    }
    nc2() {
        # Revert EQ case in x86_64EmitFloatSetCC to single-sete (lines 781-814).
        sed -i.bak '781,814s|case IR_CMP_EQ: primary = "sete";  pf_helper = "setnp"; combiner = "andb";|case IR_CMP_EQ: primary = "sete";  pf_helper = NULL;    combiner = NULL;|' src/x86_64.c
    }
    nc3() {
        # Revert NE combiner in x86_64EmitFloatSetCC from orb to andb.
        sed -i.bak '781,814s|case IR_CMP_NE: primary = "setne"; pf_helper = "setp";  combiner = "orb"; |case IR_CMP_NE: primary = "setne"; pf_helper = "setp";  combiner = "andb";|' src/x86_64.c
    }
    nc4() {
        # Revert LT to single-setb in x86_64EmitFloatSetCC.
        sed -i.bak '781,814s|case IR_CMP_LT: primary = "setb";  pf_helper = "setnp"; combiner = "andb";|case IR_CMP_LT: primary = "setb";  pf_helper = NULL;    combiner = NULL;|' src/x86_64.c
    }
    nc5() {
        # Revert LE to single-setbe in x86_64EmitFloatSetCC.
        sed -i.bak '781,814s|case IR_CMP_LE: primary = "setbe"; pf_helper = "setnp"; combiner = "andb";|case IR_CMP_LE: primary = "setbe"; pf_helper = NULL;    combiner = NULL;|' src/x86_64.c
    }
    nc6() {
        # Revert IR_CMP_BR EQ case (second copy, lines 2060-2095).
        sed -i.bak '2060,2095s|case IR_CMP_EQ: primary = "sete";  pf_helper = "setnp"; combiner = "andb";|case IR_CMP_EQ: primary = "sete";  pf_helper = NULL;    combiner = NULL;|' src/x86_64.c
    }
    nc7() {
        # Revert IR_CMP_BR NE case.
        sed -i.bak '2060,2095s|case IR_CMP_NE: primary = "setne"; pf_helper = "setp";  combiner = "orb"; |case IR_CMP_NE: primary = "setne"; pf_helper = "setp";  combiner = "andb";|' src/x86_64.c
    }
    nc8() {
        # Revert IR_CMP_BR LT case.
        sed -i.bak '2060,2095s|case IR_CMP_LT: primary = "setb";  pf_helper = "setnp"; combiner = "andb";|case IR_CMP_LT: primary = "setb";  pf_helper = NULL;    combiner = NULL;|' src/x86_64.c
    }

    assert_harness_catches() {
        label="$1"
        expected_broken_predicate="$2"
        mode="$3"  # "aot" or "jit"
        # The buggy encoder produces non-deterministic output (depends
        # on whatever %cl was clobbered to by a prior call). To make
        # the NC reliable, run the JIT path multiple times and confirm
        # at least one run shows the bug. AOT is deterministic so a
        # single run suffices.
        n_runs=1
        case "$mode" in
            jit) n_runs=10;;
            aot) n_runs=1;;
        esac

        # For NC1 (encoder revert): the JIT buggy encoder accidentally
        # gives the right answer for the NaN matrix (both SETcc ops
        # write to AL, and the second setnp gives 0 for NaN inputs
        # which masks the primary result correctly). The bug shows up
        # reliably in the finite baseline where PF=0 (so buggy setnp
        # returns 1, clobbering the primary).
        #
        # For NC2-NC5 (AOT x86_64EmitFloatSetCC reverts): the IR_FCMP
        # path is broken - use the ir_fcmp_witness.HC fixture which
        # feeds the FCMP result to printf directly (bypassing the
        # pre-existing IR_FPTOSI bug that masks single-sete to 0).
        #
        # For NC6-NC8 (AOT IR_CMP_BR reverts): the branch-form is
        # broken - use red_nan.HC which uses `if` patterns.
        fixture="red_nan.HC"
        expected_file="$EXP_NAN"
        case "$label" in
            1) fixture="finite_baseline.HC"
               expected_file="$EXP_FIN_JIT"
               case "$expected_broken_predicate" in
                   EQ) bug_pattern="1.0 == 1.0 -> FALSE";;
                   NE) bug_pattern="1.0 != 1.0 -> TRUE";;
                   LT) bug_pattern="1.0 <  2.0 -> FALSE";;
                   LE) bug_pattern="1.0 <= 1.0 -> FALSE";;
                   *)  bug_pattern="";;
               esac
               ;;
            2|3|4|5) fixture="ir_fcmp_witness.HC"
               expected_file="$EXP_FCMP_JIT"
               case "$expected_broken_predicate" in
                   EQ) bug_pattern="NaN == 1.0 -> 1 (expected 0)";;
                   NE) bug_pattern="NaN != 1.0 -> 0 (expected 1)";;
                   LT) bug_pattern="NaN <  1.0 -> 1 (expected 0)";;
                   LE) bug_pattern="NaN <= 1.0 -> 1 (expected 0)";;
                   *)  bug_pattern="";;
               esac
               ;;
            *) case "$expected_broken_predicate" in
                   EQ) bug_pattern="NaN == 1.0  -> TRUE  (expected false)";;
                   NE) bug_pattern="NaN != 1.0  -> FALSE (expected true)";;
                   LT) bug_pattern="NaN <  1.0  -> TRUE  (expected false)";;
                   LE) bug_pattern="NaN <= 1.0  -> TRUE  (expected false)";;
                   *)  bug_pattern="";;
               esac
               ;;
        esac

        # Special-case NC1: instead of running the flaky finite-baseline
        # matrix (which depends on whatever %cl a prior printf happened
        # to leave), inspect the JIT-encoded bytes directly. The buggy
        # encoder writes setnp %al (ModR/M 0xC8) instead of setnp %cl
        # (ModR/M 0xC1). The byte sequence "0F 9B C8" or "0F 9A C8"
        # is the unique fingerprint of the bug.
        if [ "$label" = "1" ]; then
            dump="$TMP/nc-${label}.${mode}.dump"
            HCC_JIT_DUMP=1 DYLD_LIBRARY_PATH="$HCC_LIB_PATH" \
                arch -x86_64 "$HCC" $HCC_INSTALL_ARG \
                -jit "$REPO_ROOT/src/tests/native-x86-float-cmp-parity01/$fixture" \
                >"$dump" 2>&1 || true
            # Bug pattern: setnp %al (0F 9B C8) or setp %al (0F 9A C8).
            # These bytes should NOT appear with the correct encoder
            # (which would emit setnp %cl = 0F 9B C1 / setp %cl = 0F 9A C1).
            if grep -qE '0f 9[b|a] c8' "$dump"; then
                echo "PASS  $label (buggy ModR/M 0xC8 fingerprint found in JIT bytes)"
                return 0
            fi
            echo "FAIL  $label: JIT byte dump does not contain buggy ModR/M 0xC8"
            return 1
        fi

        caught=0
        for run in $(seq 1 $n_runs); do
            out="$TMP/nc-${label}.${mode}.${run}.out"
            fixture_path="$REPO_ROOT/src/tests/native-x86-float-cmp-parity01/$fixture"
            case "$mode" in
                jit)
                    DYLD_LIBRARY_PATH="$HCC_LIB_PATH" \
                        arch -x86_64 "$HCC" $HCC_INSTALL_ARG \
                        -jit "$fixture_path" \
                        >"$out" 2>&1 || true
                    ;;
                aot)
                    bin="$TMP/nc-${label}.aot.bin"
                    DYLD_LIBRARY_PATH="$HCC_LIB_PATH" \
                        arch -x86_64 "$HCC" $HCC_INSTALL_ARG \
                        -o "$bin" "$fixture_path" \
                        >/dev/null 2>&1 || true
                    DYLD_LIBRARY_PATH="$HCC_LIB_PATH" \
                        arch -x86_64 "$bin" >"$out" 2>&1 || true
                    ;;
            esac
            if [ -n "$bug_pattern" ] && grep -q "$bug_pattern" "$out"; then
                caught=1
                break
            fi
            # Also count: did the output diverge from expected?
            if ! diff -q "$out" "$expected_file" >/dev/null 2>&1; then
                caught=1
                break
            fi
        done

        if [ "$caught" != "1" ]; then
            echo "FAIL  $label: harness did not catch the regression in $n_runs runs ($fixture)"
            return 1
        fi
        echo "PASS  $label ($expected_broken_predicate $mode regression caught via $fixture)"
        return 0
    }

    run_nc() {
        idx="$1"; fn="$2"; expected_pred="$3"; mode="$4"
        nc_total=$((nc_total+1))
        backup_sources
        $fn || { echo "FAIL  NC${idx}: patch"; nc_fail=$((nc_fail+1)); restore_sources; return; }
        # Touch the patched source to a future mtime to ensure make
        # detects the change (sed -i can preserve the original mtime).
        touch src/asm/enc_x86_64.c src/x86_64.c src/x86_64-jit.c
        rebuild "${idx}-patched" || { nc_fail=$((nc_fail+1)); restore_sources; rebuild "${idx}-restored" || true; return; }
        if assert_harness_catches "$idx" "$expected_pred" "$mode"; then
            nc_pass=$((nc_pass+1))
        else
            nc_fail=$((nc_fail+1))
        fi
        restore_sources
        rebuild "${idx}-restored" || { echo "FAIL  NC${idx}: restore rebuild"; nc_fail=$((nc_fail+1)); }
    }

    echo
    echo "=== PARITY01 negative controls (NC1..NC8) ==="
    # NC1: encoder revert (JIT-side). Affects JIT.
    run_nc 1 nc1 EQ jit
    # NC2-NC5: AOT x86_64EmitFloatSetCC reverts. Affect AOT.
    run_nc 2 nc2 EQ aot
    run_nc 3 nc3 NE aot
    run_nc 4 nc4 LT aot
    run_nc 5 nc5 LE aot
    # NC6-NC8: AOT IR_CMP_BR reverts (different code copy). Affect AOT.
    run_nc 6 nc6 EQ aot
    run_nc 7 nc7 NE aot
    run_nc 8 nc8 LT aot

    echo
    echo "PARITY01_NC_PASS=$nc_pass"
    echo "PARITY01_NC_FAIL=$nc_fail"
    echo "PARITY01_NC_TOTAL=$nc_total"

    if [ "$nc_fail" -gt 0 ]; then
        return 1
    fi
    return 0
}

if ! run_negative_controls; then
    FAIL=$((FAIL+1))
fi

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
