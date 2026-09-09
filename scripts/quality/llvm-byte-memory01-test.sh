#!/bin/sh
# scripts/quality/llvm-byte-memory01-test.sh
#
# ACT-POLYC-LLVM-BYTE-MEMORY01 GREEN harness.
#
# Verifies the bounded byte-representation / byte-memory / byte-promotion
# path on the LLVM 22 C-API backend.
#
# Sections (per ACT §31):
#   toolchain, authorized-set echo, byte type admission,
#   direct byte load, byte promotion (zext / sext), byte store (DEFERRED),
#   byte truncation, LLVM textual structure, llvm-as / opt verify,
#   capability counters, per-fixture counter attribution,
#   GEP purity, determinism, historical-evidence conservation, summary.

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

EVID="$REPO_ROOT/evidence/llvm-byte-memory01"
mkdir -p "$EVID/impl/_tmp"
trap 'rm -rf "$EVID/impl/_tmp"' EXIT

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
if ! command -v "$LLVM_AS" >/dev/null 2>&1; then echo "FAIL  llvm-as not in PATH"; exit 2; fi
if ! command -v "$LLVM_OPT" >/dev/null 2>&1; then echo "FAIL  opt not in PATH"; exit 2; fi
echo "PASS  toolchain: hcc + llvm-as + opt available"

# ---- authorized-set echo ----
section "authorized-set echo"
if [ ! -f "$EVID/recon/authorized-set.txt" ]; then
    echo "FAIL  recon/authorized-set.txt missing"
    exit 2
fi
echo "PASS  authorized-set.txt present (frozen at recon close)"

# ---- byte type admission ----
section "byte type admission"
for fixture in src/tests/llvm-byte-memory01/red_u8_param.HC \
               src/tests/llvm-byte-memory01/red_i8_param.HC ; do
    if ! "$HCC" --emit-llvm $HCC_INSTALL_ARG -o /dev/null "$fixture" 2>"$EVID/impl/_tmp/err.txt"; then
        echo "FAIL  $fixture should compile"
        cat "$EVID/impl/_tmp/err.txt"
        FAIL=$((FAIL+1)); continue
    fi
    if grep -q 'LLVM_BACKEND_UNSUPPORTED_TYPE.*function parameter' "$EVID/impl/_tmp/err.txt"; then
        echo "FAIL  $fixture: byte parameter admission still rejected"
        FAIL=$((FAIL+1)); continue
    fi
    echo "PASS  $fixture: U8/I8 parameter admission"
    PASS=$((PASS+1))
done

# ---- direct byte load ----
section "direct byte load"
for fixture in src/tests/llvm-byte-memory01/red_byte_load.HC \
               src/tests/llvm-byte-memory01/red_byte_pointer_param.HC ; do
    if ! "$HCC" --emit-llvm $HCC_INSTALL_ARG -o "$EVID/impl/_tmp/out.ll" "$fixture" 2>"$EVID/impl/_tmp/err.txt"; then
        echo "FAIL  $fixture should compile (U8 pointer read)"
        cat "$EVID/impl/_tmp/err.txt"
        FAIL=$((FAIL+1)); continue
    fi
    if ! grep -qE 'load i8, ptr %' "$EVID/impl/_tmp/out.ll"; then
        echo "FAIL  $fixture: no 'load i8, ptr' in emitted IR"
        cat "$EVID/impl/_tmp/out.ll"
        FAIL=$((FAIL+1)); continue
    fi
    echo "PASS  $fixture: load i8, ptr"
    PASS=$((PASS+1))
done

# ---- byte promotion (zext / sext) ----
section "byte promotion (zext / sext)"
for fixture in src/tests/llvm-byte-memory01/red_byte_to_i64.HC \
               src/tests/llvm-byte-memory01/red_u8_param.HC \
               src/tests/llvm-byte-memory01/red_i8_param.HC ; do
    if ! "$HCC" --emit-llvm $HCC_INSTALL_ARG -o "$EVID/impl/_tmp/out.ll" "$fixture" 2>"$EVID/impl/_tmp/err.txt"; then
        echo "FAIL  $fixture should compile (U8/I8 -> I64 promotion)"
        cat "$EVID/impl/_tmp/err.txt"
        FAIL=$((FAIL+1)); continue
    fi
    if grep -qE '(zext|sext) i8 .* to i64' "$EVID/impl/_tmp/out.ll"; then
        echo "PASS  $fixture: byte promotion"
        PASS=$((PASS+1))
    else
        echo "FAIL  $fixture: no (zext|sext) i8 to i64 in emitted IR"
        cat "$EVID/impl/_tmp/out.ll"
        FAIL=$((FAIL+1))
    fi
done

# ---- byte store (DEFERRED per ACT §37) ----
section "byte store (DEFERRED per ACT §37)"
echo "INFO  byte store (IR_STORE_DEREF byte shape) is DEFERRED per ACT §37"
echo "INFO  No positive fixtures; no test executed"

# ---- byte truncation ----
section "byte truncation (I64 -> I8 admitted; I64 -> I16 REJECTED)"
if "$HCC" --emit-llvm $HCC_INSTALL_ARG -o "$EVID/impl/_tmp/out.ll" \
        src/tests/llvm-byte-memory01/red_i16_trunc_negative.HC 2>"$EVID/impl/_tmp/err.txt"; then
    echo "FAIL  red_i16_trunc_negative.HC: I64 -> I16 narrowing must be rejected"
    FAIL=$((FAIL+1))
else
    if grep -q 'LLVM_BACKEND_UNSUPPORTED_CONVERSION.*IR_TRUNC' "$EVID/impl/_tmp/err.txt"; then
        echo "PASS  red_i16_trunc_negative.HC: I64 -> I16 narrowing rejected with named diagnostic"
        PASS=$((PASS+1))
    else
        echo "FAIL  red_i16_trunc_negative.HC: rejected but without named IR_TRUNC diagnostic"
        cat "$EVID/impl/_tmp/err.txt"
        FAIL=$((FAIL+1))
    fi
fi

# ---- LLVM textual structure (no GEP / ptrtoint / inttoptr / alloca) ----
section "LLVM textual structure"
for ll in "$EVID"/impl/red_*.ll "$EVID"/impl/pos_*.ll ; do
    [ -f "$ll" ] || continue
    bn=$(basename "$ll" .ll)
    if grep -qE '(getelementptr|ptrtoint|inttoptr|alloca)' "$ll"; then
        echo "FAIL  $bn: contains forbidden instruction"
        grep -E '(getelementptr|ptrtoint|inttoptr|alloca)' "$ll"
        FAIL=$((FAIL+1))
    else
        echo "PASS  $bn: structural purity"
        PASS=$((PASS+1))
    fi
done

# ---- llvm-as / opt --passes=verify ----
section "llvm-as / opt --passes=verify"
for ll in "$EVID"/impl/red_*.ll "$EVID"/impl/pos_*.ll ; do
    [ -f "$ll" ] || continue
    bn=$(basename "$ll" .ll)
    if ! "$LLVM_AS" "$ll" -o "$EVID/impl/_tmp/out.bc" 2>"$EVID/impl/_tmp/err.txt"; then
        echo "FAIL  $bn: llvm-as rejected"; cat "$EVID/impl/_tmp/err.txt"
        FAIL=$((FAIL+1)); continue
    fi
    if ! "$LLVM_OPT" --passes=verify "$EVID/impl/_tmp/out.bc" -o /dev/null 2>"$EVID/impl/_tmp/err.txt"; then
        echo "FAIL  $bn: opt verify rejected"; cat "$EVID/impl/_tmp/err.txt"
        FAIL=$((FAIL+1)); continue
    fi
    echo "PASS  $bn: llvm-as + opt --passes=verify"
    PASS=$((PASS+1))
done

# ---- capability counters ----
section "capability counters"
python3 scripts/quality/llvm-cap-table-verifier.py >"$EVID/impl/_tmp/cap-verifier.txt" 2>&1
for opcode in IR_LOAD_DEREF IR_STORE_DEREF IR_ZEXT IR_SEXT IR_TRUNC ; do
    if grep -q "I1: $opcode = SHAPE_DEPENDENT" "$EVID/impl/_tmp/cap-verifier.txt"; then
        echo "PASS  $opcode = SHAPE_DEPENDENT"
        PASS=$((PASS+1))
    else
        echo "FAIL  $opcode not SHAPE_DEPENDENT"
        FAIL=$((FAIL+1))
    fi
done

# ---- per-fixture counter attribution ----
section "per-fixture counter attribution (CORE04 §30 binding)"
for fixture in src/tests/llvm-byte-memory01/red_byte_load.HC \
               src/tests/llvm-byte-memory01/red_u8_param.HC \
               src/tests/llvm-byte-memory01/red_i8_param.HC \
               src/tests/llvm-byte-memory01/red_byte_to_i64.HC \
               src/tests/llvm-byte-memory01/pos_byte_compare_simple.HC ; do
    "$HCC" --emit-llvm $HCC_INSTALL_ARG -o /dev/null "$fixture" 2>"$EVID/impl/_tmp/err.txt"
    sd=$(grep -o 'shape_dependent=[0-9]\+' "$EVID/impl/_tmp/err.txt" | head -1 | cut -d= -f2 || echo 0)
    if [ -z "$sd" ] || [ "$sd" -eq 0 ]; then
        echo "FAIL  $fixture: SHAPE_DEPENDENT counter = 0"
        FAIL=$((FAIL+1))
    else
        echo "PASS  $fixture: SHAPE_DEPENDENT counter = $sd"
        PASS=$((PASS+1))
    fi
done

# ---- GEP purity ----
section "GEP purity"
gep_count=$(grep -h 'getelementptr' "$EVID"/impl/red_*.ll "$EVID"/impl/pos_*.ll 2>/dev/null | wc -l | tr -d ' ')
if [ "$gep_count" = "0" ]; then
    echo "PASS  zero getelementptr in BYTE-MEMORY01 positive .ll files"
    PASS=$((PASS+1))
else
    echo "FAIL  $gep_count getelementptr occurrences in positive .ll files"
    FAIL=$((FAIL+1))
fi

# ---- determinism ----
section "determinism"
for fixture in src/tests/llvm-byte-memory01/red_byte_load.HC \
               src/tests/llvm-byte-memory01/pos_byte_compare_simple.HC ; do
    bn=$(basename "$fixture" .HC)
    "$HCC" --emit-llvm $HCC_INSTALL_ARG -o "$EVID/impl/_tmp/${bn}_1.ll" "$fixture" 2>/dev/null
    "$HCC" --emit-llvm $HCC_INSTALL_ARG -o "$EVID/impl/_tmp/${bn}_2.ll" "$fixture" 2>/dev/null
    if cmp -s "$EVID/impl/_tmp/${bn}_1.ll" "$EVID/impl/_tmp/${bn}_2.ll"; then
        echo "PASS  $bn: byte-identical across two runs"
        PASS=$((PASS+1))
    else
        echo "FAIL  $bn: not byte-identical"
        FAIL=$((FAIL+1))
    fi
done

# ---- historical-evidence conservation ----
section "historical-evidence conservation"
for tree in evidence/llvmspike01 evidence/llvm-memory01 \
            evidence/llvm-float01 evidence/llvm-intops01 ; do
    if [ -d "$tree" ]; then
        echo "PASS  $tree present"
        PASS=$((PASS+1))
    else
        echo "FAIL  $tree missing"
        FAIL=$((FAIL+1))
    fi
done

# ---- summary ----
section "summary"
echo "BYTE_MEMORY01_PASS=$PASS"
echo "BYTE_MEMORY01_FAIL=$FAIL"
if [ "$FAIL" = 0 ]; then echo "STATUS=PASS"; else echo "STATUS=FAIL"; fi
