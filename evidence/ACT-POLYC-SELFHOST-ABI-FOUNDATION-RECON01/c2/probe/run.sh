#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/probe/run.sh
# Bounded build/run carrier (no compiler decisions live here).
# Serialized by the caller: /tmp/holyc-asm.s is a shared filename.
set -eu
cd "$(dirname "$0")/../../../.."
P=evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c2/probe
B=${1:-build/abi-foundation-recon01/c2}
TMPDIR=${TMPDIR:-/tmp}
mkdir -p "$B"
./hcc --install-dir="$PWD/build/test-prefix" -c "$P/abi_probe.HC" -o "$B/abi_probe.o"
for f in abi_host abi_main abi_oracle; do
    cc -std=c99 -O2 -Wall -Wextra -Wno-typedef-redefinition \
       -ffunction-sections -fdata-sections -Isrc -I"$P" \
       -c "$P/$f.c" -o "$B/$f.o"
done
for f in ast list aostr containers arena memory; do
    cc -std=gnu11 -O2 -ffunction-sections -fdata-sections -Isrc \
       -c "src/$f.c" -o "$B/$f.o"
done
cc -Wl,-dead_strip "$B/abi_probe.o" "$B/abi_host.o" "$B/abi_main.o" \
   "$B/abi_oracle.o" "$B/ast.o" "$B/list.o" "$B/aostr.o" \
   "$B/containers.o" "$B/arena.o" "$B/memory.o" \
   -Lbuild/test-prefix/lib -ltos -o "$B/abi_probe_bin"
./"$B/abi_probe_bin"
./"$B/abi_probe_bin" ARENA
for id in AB-HD-01 AB-HD-02 AB-HD-03 AB-HD-04 AB-HD-05 AB-HD-06 \
          AB-HD-07 AB-HD-08 AB-ST-01 AB-ST-02 AB-ST-03 AB-ST-05; do
    ./"$B/abi_probe_bin" CONTROL "$id"
done
