#!/bin/sh
# extract-signature.sh — CORRECTION01 GEP01 failure-signature extractor.
#
# Input:  raw `gate-push.sh` stdout/stderr log
# Output: deterministic GEP01 failure signature containing only
#         semantically relevant content.

set -eu
RAW="$1"
OUT="$2"
[ -r "$RAW" ] || { echo "ERROR: cannot read $RAW" >&2; exit 2; }

sed -E \
    -e 's|/private/var/folders/[^ ]*|<SANDBOX_TMPDIR>|g' \
    -e 's|/var/folders/[^ ]*xcrun_db-[A-Za-z0-9]+|/var/folders/<CACHE>|g' \
    -e 's|build/quality/gep01/run-[0-9]+-[0-9]+|build/quality/gep01/run-<PID>|g' \
    -e 's|/run/current-system/sw/bin/llvm-as|<LLVM_TOOL>|g' \
    -e 's|/run/current-system/sw/bin/opt|<LLVM_TOOL>|g' \
    -e 's|/run/current-system/sw/bin/python3|<PYTHON>|g' \
    "$RAW" > "$OUT.tmp"

# Drop run-specific / non-semantic lines.
sed -E -i.bak \
    -e '/^SUBJECT=/d' \
    -e '/^install_dir   =/d' \
    -e '/^-- Configuring done /d' \
    -e '/^-- Build files have been written to:/d' \
    -e '/^-- Install configuration:/d' \
    -e '/^-- Up-to-date:/d' \
    -e '/^-- Installing:/d' \
    -e '/^\[[ 0-9]+%\]/d' \
    -e '/^ar: error: couldn.t create cache file/d' \
    -e '/^ranlib: error: couldn.t create cache file/d' \
    -e '/^clang: warning: argument unused during compilation/d' \
    -e '/^cc -shared -fPIC -c \/tmp\/holyc-asm\.s/d' \
    -e '/^ar rcs libtos\.a all\.o/d' \
    -e '/^ld: Undefined symbols:/d' \
    -e '/^      _Errno, referenced from:/d' \
    -e '/^      _MALLOC in all\.o$/d' \
    -e '/^clang: error: linker command failed/d' \
    -e '/^cc -dynamiclib -Wl,-install_name=/d' \
    -e '/^CMake Warning at cmake_install\.cmake:91/d' \
    -e '/^  hcc -lib exited with code 1/d' \
    -e '/^  Continuing\.$/d' \
    -e '/^\[0;31mERROR: \[0mFailed to execute command:/d' \
    -e '/^Building C object CMakeFiles\/hcc\.dir/d' \
    -e '/^Building C object asm\/CMakeFiles\/tasm\.dir/d' \
    -e '/^Linking C executable/d' \
    -e '/^Built target hcc$/d' \
    -e '/^Install the project\.\.\.$/d' \
    -e '/^make: \*\*\* \[llvm-gep01-test\] Error 1$/d' \
    -e '/^.*\.c:[0-9]+:[0-9]+: warning:/d' \
    -e '/^.*\.h:[0-9]+:[0-9]+: note:/d' \
    -e '/^.*\.c:[0-9]+:[0-9]+: note:/d' \
    -e '/^1 warning generated$/d' \
    -e '/^2 warnings generated$/d' \
    -e '/^3 warnings generated$/d' \
    -e '/^4 warnings generated$/d' \
    -e '/^[0-9]+ warnings generated$/d' \
    -e '/^.*\.o$/d' \
    -e '/^=== ACT-POLYC-TOOLING-MIGRATE-GEP01 PolyC harness ===$/d' \
    "$OUT.tmp"

awk 'BEGIN{p=0} { if (NF==0) { if (!p) print; p=1 } else { print; p=0 } }' \
    "$OUT.tmp" > "$OUT"
rm -f "$OUT.tmp" "$OUT.tmp.bak"
echo "signature written: $OUT"
wc -l "$OUT"
