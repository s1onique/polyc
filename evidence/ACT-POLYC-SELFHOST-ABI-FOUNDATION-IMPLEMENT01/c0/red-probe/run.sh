#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01/c0/red-probe/run.sh
#
# Bounded build/run carrier (no compiler decisions live here).
# Serialized by the caller: /tmp/holyc-asm.s is a shared filename.
#
# Args: <hcc-worktree-root> <build-dir>
#   <hcc-worktree-root> must contain ./hcc and build/test-prefix (the G0
#   isolated compiler and its header/runtime prefix).
set -eu

P=$(cd "$(dirname "$0")" && pwd)
ROOT=${1:?usage: run.sh <hcc-worktree-root> <relative-build-dir>}
B=${2:?usage: run.sh <hcc-worktree-root> <relative-build-dir>}

# ./hcc resolves -o against the process CWD, so every path below is relative to
# the worktree root and the script must run from there.
cd "$ROOT"

HCC="./hcc"
PREFIX="build/test-prefix"
SRC="src"

mkdir -p "$B"

echo "### PRODUCER_HCC=$HCC"
shasum -a 256 "$HCC"

"$HCC" --install-dir="$PREFIX" -c "$P/abi_red_probe.HC" -o "$B/abi_red_probe.o"

for f in abi_red_host abi_red_oracle abi_red_main; do
    cc -std=c99 -O2 -Wall -Wextra -Wno-typedef-redefinition \
       -ffunction-sections -fdata-sections -I"$SRC" -I"$P" \
       -c "$P/$f.c" -o "$B/$f.o"
done
for f in ast list aostr containers arena memory; do
    cc -std=gnu11 -O2 -ffunction-sections -fdata-sections -I"$SRC" \
       -c "$SRC/$f.c" -o "$B/$f.o"
done

cc -Wl,-dead_strip "$B/abi_red_probe.o" "$B/abi_red_host.o" \
   "$B/abi_red_oracle.o" "$B/abi_red_main.o" \
   "$B/ast.o" "$B/list.o" "$B/aostr.o" "$B/containers.o" \
   "$B/arena.o" "$B/memory.o" \
   -L"$PREFIX/lib" -ltos -o "$B/abi_red_bin"

echo "### OBJECTS"
shasum -a 256 "$B/abi_red_probe.o" "$B/abi_red_bin"
echo "### UNDEFINED_SYMBOLS_FROM_POLYC_SUBJECT"
nm -u "$B/abi_red_probe.o" | sed 's/^/  /'
echo "### DEFINED_SYMBOLS_IN_POLYC_SUBJECT"
nm -gU "$B/abi_red_probe.o" | sed 's/^/  /'
echo "### DEFINING_OBJECT_FOR_POLYC_SYMBOL_IN_BINARY"
nm -m "$B/abi_red_bin" | grep -E '_AbiRedShouldPrint|_AbiRedListAppendBounded' | sed 's/^/  /'
echo "### SETJMP_LONGJMP_IN_BINARY"
if nm -u "$B/abi_red_bin" | grep -Eq '_(setjmp|longjmp|sigsetjmp|siglongjmp)$'; then
    echo "  PRESENT=YES"
else
    echo "  PRESENT=NO"
fi

echo "### PRISTINE"
"$B/abi_red_bin"
echo "### CONTROLS"
for id in C0-KIND C0-FORGE C0-STALE C0-ARENA C0-WRAP C0-CAPACITY \
          C0-DOMAIN C0-ATOMIC C0-SIGNED C0-RECOVERY; do
    "$B/abi_red_bin" CONTROL "$id" || echo "CONTROL_FAILED=$id"
done
