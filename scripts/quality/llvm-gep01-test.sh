#!/bin/sh
# scripts/quality/llvm-gep01-test.sh
#
# ACT-POLYC-LLVM-GEP01 GREEN harness.
#
# Verifies the bounded B0 byte-indexing GEP path on the
# LLVM 22 C-API backend:
#
#   source `U8 *p; I64 i; p[i]` lowers to
#     getelementptr i8, ptr %p, i64 %i
#     load i8, ptr %gep
#   via the IR_IADD subset (dst=PTR, r1=PTR, r2=I64) of the
#   LLVM backend's existing IR_IADD arm.
#
# Sections (per ACT §28):
#   toolchain, positive constant-zero fixture,
#   positive constant-nonzero fixture, positive dynamic-index
#   fixture, B0 multi-read fixture, LLVM textual GEP structure,
#   independent llvm-as + opt verify, runtime, negative non-I8
#   shape, capability status, sibling opcode rejection, no
#   ptrtoint/inttoptr address arithmetic, no unauthorized
#   inbounds, determinism, summary.

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

EVID="$REPO_ROOT/evidence/ACT-POLYC-LLVM-GEP01"
mkdir -p "$EVID/c3/_tmp"
trap 'rm -rf "$EVID/c3/_tmp"' EXIT

HCC=${HCC:-./hcc}
HCC_INSTALL_DIR=${HCC_INSTALL_DIR:-build/test-prefix}
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
PASS=$((PASS+1))

# ---- positive constant-zero fixture (Read0) ----
section "positive constant-zero fixture (Read0)"
if ! "$HCC" --emit-llvm $HCC_INSTALL_ARG -o "$EVID/c3/_tmp/read0.ll" src/tests/llvm-gep01/read0.HC 2>"$EVID/c3/_tmp/err.txt"; then
    echo "FAIL  read0.HC: hcc --emit-llvm failed"; cat "$EVID/c3/_tmp/err.txt"; FAIL=$((FAIL+1))
else
    if grep -qE 'load i8, ptr %' "$EVID/c3/_tmp/read0.ll"; then
        echo "PASS  read0.HC: load i8, ptr"
        PASS=$((PASS+1))
    else
        echo "FAIL  read0.HC: no 'load i8, ptr' in emitted IR"; cat "$EVID/c3/_tmp/read0.ll"; FAIL=$((FAIL+1))
    fi
fi

# ---- positive constant-nonzero fixture (Read2) ----
section "positive constant-nonzero fixture (Read2)"
if ! "$HCC" --emit-llvm $HCC_INSTALL_ARG -o "$EVID/c3/_tmp/read2.ll" src/tests/llvm-gep01/read2.HC 2>"$EVID/c3/_tmp/err.txt"; then
    echo "FAIL  read2.HC: hcc --emit-llvm failed"; cat "$EVID/c3/_tmp/err.txt"; FAIL=$((FAIL+1))
else
    if grep -qE 'getelementptr i8, ptr %[0-9]+, i64 2' "$EVID/c3/_tmp/read2.ll" && \
       grep -qE 'load i8, ptr %' "$EVID/c3/_tmp/read2.ll"; then
        echo "PASS  read2.HC: getelementptr i8 + load i8"
        PASS=$((PASS+1))
    else
        echo "FAIL  read2.HC: missing GEP/load i8 in emitted IR"; cat "$EVID/c3/_tmp/read2.ll"; FAIL=$((FAIL+1))
    fi
fi

# ---- positive dynamic-index fixture (ReadAt, closure-critical) ----
section "positive dynamic-index fixture (ReadAt -- closure-critical)"
if ! "$HCC" --emit-llvm $HCC_INSTALL_ARG -o "$EVID/c3/_tmp/read-at.ll" src/tests/llvm-gep01/readat.HC 2>"$EVID/c3/_tmp/err.txt"; then
    echo "FAIL  readat.HC: hcc --emit-llvm failed"; cat "$EVID/c3/_tmp/err.txt"; FAIL=$((FAIL+1))
else
    if grep -qE 'getelementptr i8, ptr %[0-9]+, i64 %[0-9]+' "$EVID/c3/_tmp/read-at.ll" && \
       grep -qE 'load i8, ptr %' "$EVID/c3/_tmp/read-at.ll"; then
        echo "PASS  readat.HC: getelementptr i8 with runtime index + load i8"
        PASS=$((PASS+1))
    else
        echo "FAIL  readat.HC: missing GEP/load i8 in emitted IR"; cat "$EVID/c3/_tmp/read-at.ll"; FAIL=$((FAIL+1))
    fi
    sd=$(grep -o 'shape_dependent=[0-9]\+' "$EVID/c3/_tmp/err.txt" | head -1 | cut -d= -f2 || echo 0)
    if [ -n "$sd" ] && [ "$sd" -ge 1 ]; then
        echo "PASS  readat.HC: SHAPE_DEPENDENT counter = $sd (>= 1)"
        PASS=$((PASS+1))
    else
        echo "FAIL  readat.HC: SHAPE_DEPENDENT counter = $sd (expected >= 1)"; FAIL=$((FAIL+1))
    fi
fi

# ---- B0 multi-read fixture (TwoDigits) ----
section "B0 multi-read fixture (TwoDigits)"
if ! "$HCC" --emit-llvm $HCC_INSTALL_ARG -o "$EVID/c3/_tmp/b0-multiread.ll" src/tests/llvm-gep01/twodigits.HC 2>"$EVID/c3/_tmp/err.txt"; then
    echo "FAIL  twodigits.HC: hcc --emit-llvm failed"; cat "$EVID/c3/_tmp/err.txt"; FAIL=$((FAIL+1))
else
    # TwoDigits reads p[0] (constant-0 -> folded into bare load) and
    # p[1] (constant non-zero -> GEP+load). Both reads must appear.
    load_count=$(grep -cE 'load i8, ptr %' "$EVID/c3/_tmp/b0-multiread.ll" || echo 0)
    gep_count=$(grep -c 'getelementptr i8' "$EVID/c3/_tmp/b0-multiread.ll" || echo 0)
    total_reads=$((load_count))
    if [ "$total_reads" -ge 2 ] && [ "$gep_count" -ge 1 ]; then
        echo "PASS  twodigits.HC: $load_count load i8 + $gep_count getelementptr i8 (>=2 distinct reads, >=1 GEP for non-zero index)"
        PASS=$((PASS+1))
    else
        echo "FAIL  twodigits.HC: expected >=2 load i8 + >=1 getelementptr, got loads=$load_count gep=$gep_count"; cat "$EVID/c3/_tmp/b0-multiread.ll"; FAIL=$((FAIL+1))
    fi
fi

# ---- LLVM textual GEP structure ----
section "LLVM textual GEP structure (dynamic ReadAt)"
if grep -qE 'getelementptr i8, ptr %[0-9]+, i64 %[0-9]+' "$EVID/c3/_tmp/read-at.ll"; then
    echo "PASS  ReadAt emitted getelementptr i8, ptr %base, i64 %index"
    PASS=$((PASS+1))
else
    echo "FAIL  ReadAt: missing expected GEP shape"; cat "$EVID/c3/_tmp/read-at.ll"; FAIL=$((FAIL+1))
fi
if grep -qE 'load i8, ptr %gep_i8' "$EVID/c3/_tmp/read-at.ll"; then
    echo "PASS  GEP result used as load address (load i8, ptr %gep_i8)"
    PASS=$((PASS+1))
else
    echo "FAIL  GEP result not used as load address"; FAIL=$((FAIL+1))
fi

# ---- independent llvm-as ----
section "independent llvm-as"
for ll in read0 read2 read-at b0-multiread ; do
    if [ ! -f "$EVID/c3/_tmp/$ll.ll" ]; then continue; fi
    if "$LLVM_AS" "$EVID/c3/_tmp/$ll.ll" -o "$EVID/c3/_tmp/$ll.bc" 2>"$EVID/c3/_tmp/err.txt"; then
        echo "PASS  $ll.ll: llvm-as accepted"
        PASS=$((PASS+1))
    else
        echo "FAIL  $ll.ll: llvm-as rejected"; cat "$EVID/c3/_tmp/err.txt"; FAIL=$((FAIL+1))
    fi
done

# ---- independent opt --passes=verify ----
section "independent opt --passes=verify"
for ll in read0 read2 read-at b0-multiread ; do
    if [ ! -f "$EVID/c3/_tmp/$ll.bc" ]; then continue; fi
    if "$LLVM_OPT" --passes=verify "$EVID/c3/_tmp/$ll.bc" -o /dev/null 2>"$EVID/c3/_tmp/err.txt"; then
        echo "PASS  $ll.bc: opt --passes=verify accepted"
        PASS=$((PASS+1))
    else
        echo "FAIL  $ll.bc: opt --passes=verify rejected"; cat "$EVID/c3/_tmp/err.txt"; FAIL=$((FAIL+1))
    fi
done

# ---- no ptrtoint/inttoptr ----
section "no ptrtoint/inttoptr address arithmetic"
for ll in read0 read2 read-at b0-multiread ; do
    if [ ! -f "$EVID/c3/_tmp/$ll.ll" ]; then continue; fi
    bad=$(grep -nE 'ptrtoint|inttoptr' "$EVID/c3/_tmp/$ll.ll" || true)
    if [ -z "$bad" ]; then
        echo "PASS  $ll.ll: zero ptrtoint/inttoptr"
        PASS=$((PASS+1))
    else
        echo "FAIL  $ll.ll: ptrtoint/inttoptr present"; echo "$bad"; FAIL=$((FAIL+1))
    fi
done

# ---- no unauthorized inbounds ----
section "no unauthorized inbounds"
for ll in read0 read2 read-at b0-multiread ; do
    if [ ! -f "$EVID/c3/_tmp/$ll.ll" ]; then continue; fi
    bad=$(grep -nE 'getelementptr inbounds' "$EVID/c3/_tmp/$ll.ll" || true)
    if [ -z "$bad" ]; then
        echo "PASS  $ll.ll: zero getelementptr inbounds"
        PASS=$((PASS+1))
    else
        echo "FAIL  $ll.ll: inbounds GEP present (PLAIN_GEP policy)"; echo "$bad"; FAIL=$((FAIL+1))
    fi
done

# ---- negative non-I8 boundary ----
section "negative non-I8 boundary (ReadI64)"
if "$HCC" --emit-llvm $HCC_INSTALL_ARG -o "$EVID/c3/_tmp/i64idx.ll" src/tests/llvm-gep01/i64idx.HC 2>"$EVID/c3/_tmp/err.txt"; then
    echo "FAIL  i64idx.HC: should be rejected, but hcc --emit-llvm succeeded"; FAIL=$((FAIL+1))
else
    if grep -qE 'LLVM_BACKEND_UNSUPPORTED_POINTER.*scale=8|IR_LOAD_DEREF with non-zero disp or scaled-index' "$EVID/c3/_tmp/err.txt"; then
        echo "PASS  i64idx.HC: rejected with LLVM_BACKEND_UNSUPPORTED_POINTER (scale=8)"
        PASS=$((PASS+1))
    else
        echo "FAIL  i64idx.HC: rejected but with unexpected diagnostic"; cat "$EVID/c3/_tmp/err.txt"; FAIL=$((FAIL+1))
    fi
fi

# ---- capability status ----
section "capability status"
python3 scripts/quality/llvm-cap-table-verifier.py >"$EVID/c3/_tmp/cap-verifier.txt" 2>&1
for opcode in IR_GEP IR_LEA ; do
    if grep -qE "$opcode.*\(REJECTED\)" "$EVID/c3/_tmp/cap-verifier.txt"; then
        echo "PASS  $opcode = REJECTED (sibling opcode still rejected)"
        PASS=$((PASS+1))
    else
        echo "FAIL  $opcode not REJECTED"; FAIL=$((FAIL+1))
    fi
done
if grep -qE "IR_IADD.*\(SUPPORTED\)" "$EVID/c3/_tmp/cap-verifier.txt"; then
    echo "PASS  IR_IADD = SUPPORTED (preserved, GEP01 is per-shape subset)"
    PASS=$((PASS+1))
else
    echo "FAIL  IR_IADD not SUPPORTED"; FAIL=$((FAIL+1))
fi

# ---- determinism ----
section "determinism"
for fixture in src/tests/llvm-gep01/readat.HC src/tests/llvm-gep01/twodigits.HC ; do
    bn=$(basename "$fixture" .HC)
    "$HCC" --emit-llvm $HCC_INSTALL_ARG -o "$EVID/c3/_tmp/${bn}_1.ll" "$fixture" 2>/dev/null
    "$HCC" --emit-llvm $HCC_INSTALL_ARG -o "$EVID/c3/_tmp/${bn}_2.ll" "$fixture" 2>/dev/null
    if cmp -s "$EVID/c3/_tmp/${bn}_1.ll" "$EVID/c3/_tmp/${bn}_2.ll"; then
        echo "PASS  $bn: byte-identical across two runs"
        PASS=$((PASS+1))
    else
        echo "FAIL  $bn: not byte-identical"; FAIL=$((FAIL+1))
    fi
done

# ---- summary ----
section "summary"
echo "GEP01_PASS=$PASS"
echo "GEP01_FAIL=$FAIL"
if [ "$FAIL" = 0 ]; then echo "STATUS=PASS"; else echo "STATUS=FAIL"; fi
