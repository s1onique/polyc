#!/bin/sh
# scripts/quality/llvm-memory01-red-test.sh
#
# ACT-POLYC-LLVM-MEMORY01: bounded RED harness for the memory slice.
#
# For each RED fixture:
#   1. Run `hcc --emit-llvm` and capture stderr / stdout / exit code.
#   2. Run `hcc --dump-ir` and assert IR_LOAD_DEREF / IR_STORE_DEREF
#      presence (or absence for RED-4 baseline).
#   3. Assert rc != 0 with a named LLVM_BACKEND_UNSUPPORTED_* diagnostic.
#
# RED-4 is the SSA-local no-memory baseline: this asserts the
# existing scalar spike has zero alloca/load/store in its emitted
# LLVM IR. After MEMORY01 IMPL, this same fixture must STILL emit
# zero memory ops (the conservation witness for the SSA-only local
# contract).
#
# No network. No execution. No object emission.

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

EVID="$REPO_ROOT/evidence/llvm-memory01/red"
mkdir -p "$EVID"
mkdir -p "$EVID/_tmp"
mkdir -p "$EVID/dump-ir"
mkdir -p "$EVID/ll"
trap 'rm -rf "$EVID/_tmp"' EXIT

HCC=./hcc
HCC_INSTALL_DIR=${HCC_INSTALL_DIR:-}
HCC_INSTALL_ARG=""
if [ -n "$HCC_INSTALL_DIR" ]; then
    HCC_INSTALL_ARG="--install-dir=$HCC_INSTALL_DIR"
fi

PASS=0
FAIL=0

# Run an emit-llvm invocation and capture stderr / stdout / rc.
# Args: <fixture> <out-ll>
run_emit() {
    f="$1"
    out="$2"
    bn=$(basename "$f" .HC)
    set +e
    "$HCC" --emit-llvm $HCC_INSTALL_ARG "$f" -o "$out" \
        > "$EVID/_tmp/$bn.emit.stdout" \
        2> "$EVID/_tmp/$bn.emit.stderr"
    rc=$?
    set -e
    echo "$rc"
}

# Run a dump-ir invocation and capture IR text.
# Args: <fixture>
run_dump_ir() {
    f="$1"
    bn=$(basename "$f" .HC)
    raw_tmp="$EVID/_tmp/$bn.dump-ir.raw"
    "$HCC" $HCC_INSTALL_ARG --dump-ir "$f" \
        > "$raw_tmp" 2>&1 || true
    # Normalise: strip trailing whitespace per line, collapse trailing
    # blank lines, ensure exactly one trailing newline. Mirrors the
    # pattern in scripts/quality/llvm-spike-test.sh:dump_ir_capture
    # so the evidence files pass `git diff --check`.
    python3 -c '
import sys
with open(sys.argv[1], "r") as f:
    text = f.read()
lines = [line.rstrip() for line in text.split("\n")]
while lines and lines[-1] == "":
    lines.pop()
sys.stdout.write("\n".join(lines) + "\n")
' "$raw_tmp" > "$EVID/dump-ir/$bn.dump-ir.txt"
    rm -f "$raw_tmp"
}

# Assert a fixture currently fails with the given named diagnostic.
# Args: <fixture> <expected-diagnostic>
expect_red() {
    f="$1"
    expected="$2"
    bn=$(basename "$f" .HC)
    rc=$(run_emit "$f" "$EVID/ll/$bn.ll")
    if [ "$rc" = "0" ]; then
        echo "FAIL  $bn: hcc --emit-llvm succeeded but RED expected ($expected)" >&2
        FAIL=$((FAIL+1))
        return 1
    fi
    if ! grep -q "$expected" "$EVID/_tmp/$bn.emit.stderr"; then
        echo "FAIL  $bn: stderr missing '$expected'" >&2
        echo "  stderr: $(cat "$EVID/_tmp/$bn.emit.stderr")" >&2
        FAIL=$((FAIL+1))
        return 1
    fi
    PASS=$((PASS+1))
    echo "PASS  $bn (RED, expected '$expected')"
}

# Assert IR_LOAD_DEREF appears in --dump-ir output.
expect_load_deref_in_ir() {
    f="$1"
    bn=$(basename "$f" .HC)
    if ! grep -q 'load\*' "$EVID/dump-ir/$bn.dump-ir.txt"; then
        echo "FAIL  $bn: --dump-ir does not contain IR_LOAD_DEREF (load*)" >&2
        FAIL=$((FAIL+1))
        return 1
    fi
    PASS=$((PASS+1))
    echo "PASS  $bn (RED, IR_LOAD_DEREF present in dump-ir)"
}

# Assert IR_STORE_DEREF appears in --dump-ir output.
expect_store_deref_in_ir() {
    f="$1"
    bn=$(basename "$f" .HC)
    if ! grep -q 'store\*' "$EVID/dump-ir/$bn.dump-ir.txt"; then
        echo "FAIL  $bn: --dump-ir does not contain IR_STORE_DEREF (store*)" >&2
        FAIL=$((FAIL+1))
        return 1
    fi
    PASS=$((PASS+1))
    echo "PASS  $bn (RED, IR_STORE_DEREF present in dump-ir)"
}

# Capture dump-ir for every fixture (used by every expect_*).
for f in src/tests/llvm-memory01/red_pointer_param.HC \
         src/tests/llvm-memory01/red_load_deref.HC \
         src/tests/llvm-memory01/red_store_deref.HC \
         src/tests/llvm-memory01/red_ssa_local_baseline.HC; do
    run_dump_ir "$f"
done

echo "=== RED-1 pointer parameter ==="
expect_red src/tests/llvm-memory01/red_pointer_param.HC \
    LLVM_BACKEND_UNSUPPORTED_TYPE
run_dump_ir src/tests/llvm-memory01/red_pointer_param.HC
# This fixture uses an I64 *p param but does not dereference it
# (returns 0), so IR_LOAD_DEREF should NOT appear.
if grep -q 'load\*' "$EVID/dump-ir/red_pointer_param.dump-ir.txt"; then
    echo "FAIL  red_pointer_param: unexpected IR_LOAD_DEREF" >&2
    FAIL=$((FAIL+1))
else
    PASS=$((PASS+1))
    echo "PASS  red_pointer_param (no IR_LOAD_DEREF as expected)"
fi

echo "=== RED-2 I64 pointer read ==="
# Currently fails at the parameter-type check (LLVM_BACKEND_UNSUPPORTED_TYPE),
# before reaching the IR_LOAD_DEREF dispatch arm. After IMPL, the same
# fixture becomes a positive fixture; the diagnostic expectation here
# is the current entry-state behavior.
expect_red src/tests/llvm-memory01/red_load_deref.HC \
    LLVM_BACKEND_UNSUPPORTED_TYPE
expect_load_deref_in_ir src/tests/llvm-memory01/red_load_deref.HC

echo "=== RED-3 I64 pointer write ==="
expect_red src/tests/llvm-memory01/red_store_deref.HC \
    LLVM_BACKEND_UNSUPPORTED_TYPE
expect_store_deref_in_ir src/tests/llvm-memory01/red_store_deref.HC

echo "=== RED-4 SSA-local no-memory baseline ==="
bn=red_ssa_local_baseline
rc=$(run_emit "src/tests/llvm-memory01/$bn.HC" "$EVID/ll/$bn.ll")
if [ "$rc" != "0" ]; then
    echo "FAIL  $bn: existing scalar spike should compile cleanly" >&2
    FAIL=$((FAIL+1))
else
    PASS=$((PASS+1))
    echo "PASS  $bn (compiled cleanly, baseline .ll captured)"
    # Verify NO alloca/load/store in the .ll (structural purity).
    bad=$(grep -nE '^[[:space:]]*(alloca|load|store)[[:space:]]' \
        "$EVID/ll/$bn.ll" || true)
    if [ -n "$bad" ]; then
        echo "FAIL  $bn: baseline .ll contains memory ops (forbidden):" >&2
        printf '  %s\n' "$bad" | head -5 >&2
        FAIL=$((FAIL+1))
    else
        PASS=$((PASS+1))
        echo "PASS  $bn (zero alloca/load/store; SSA-only baseline)"
    fi
fi

echo
echo "================================="
echo "MEMORY01 RED summary: PASS=$PASS FAIL=$FAIL"
echo "================================="
if [ "$FAIL" != "0" ]; then
    exit 1
fi
exit 0
