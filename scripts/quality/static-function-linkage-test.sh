#!/bin/sh
# scripts/quality/static-function-linkage-test.sh
#
# ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01 §20 regression gate.
# Re-runs the native S01..S08 fixtures and the JIT J01..J05 fixtures;
# exits non-zero on any FAIL. Shell + existing hcc/nm/ld only.
#
# hcc invokes cc with "./<absolute-path>" for the output, so all
# invocations run from a scratch directory; cd is restored at exit.
set -u
REPO=$(cd "$(dirname "$0")/../.." && pwd)
HCC=$REPO/hcc
PREFIX=${TEST_PREFIX:-$REPO/build/test-prefix}
FIX=$REPO/tests/compiler/static-function-linkage
SCRATCH=$(mktemp -d -t sfl-test-XXXXXX); trap 'rm -rf "$SCRATCH"' EXIT
cd "$SCRATCH"
F=0
$HCC --install-dir="$PREFIX" -o s01 $FIX/s01-single-static/s01.HC >/dev/null 2>&1
./s01 >/dev/null 2>&1; RC=$?; [ "$RC" = "1" ] || { echo "S01 FAIL rc=$RC"; F=1; }
$HCC --install-dir="$PREFIX" -c -o s02_tuA.o $FIX/s02-two-tu-same-static/tuA.HC >/dev/null 2>&1
$HCC --install-dir="$PREFIX" -c -o s02_tuB.o $FIX/s02-two-tu-same-static/tuB.HC >/dev/null 2>&1
$HCC --install-dir="$PREFIX" -c -o s02_main.o $FIX/s02-two-tu-same-static/main.HC >/dev/null 2>&1
ld -r -o s02_combined.o s02_tuA.o s02_tuB.o 2>/dev/null
cc -o s02 s02_combined.o s02_main.o 2>/dev/null
./s02 >/dev/null 2>&1; RC=$?; [ "$((RC % 256))" = "98" ] || { echo "S02 FAIL rc=$RC"; F=1; }
ld -r -o s03_dup.o $FIX/s03-two-tu-same-external/tuA.HC $FIX/s03-two-tu-same-external/tuB.HC 2>/dev/null && { echo "S03 FAIL"; F=1; } || true
$HCC --install-dir="$PREFIX" -c -o s04_tuA.o $FIX/s04-static-plus-external/tuA.HC >/dev/null 2>&1
$HCC --install-dir="$PREFIX" -c -o s04_tuB.o $FIX/s04-static-plus-external/tuB.HC >/dev/null 2>&1
$HCC --install-dir="$PREFIX" -c -o s04_main.o $FIX/s04-static-plus-external/main.HC >/dev/null 2>&1
ld -r -o s04_combined.o s04_tuA.o s04_tuB.o 2>/dev/null
cc -o s04 s04_combined.o s04_main.o 2>/dev/null
./s04 >/dev/null 2>&1; RC=$?; [ "$RC" = "33" ] || { echo "S04 FAIL rc=$RC"; F=1; }
$HCC --install-dir="$PREFIX" -c -o s05.o $FIX/s05-same-tu-static-duplicate/s05.HC >/dev/null 2>&1 && { echo "S05 FAIL"; F=1; } || true
$HCC --install-dir="$PREFIX" -c -o s06.o $FIX/s06-static-forward-definition/s06.HC >/dev/null 2>&1 || { echo "S06 FAIL"; F=1; }
$HCC --install-dir="$PREFIX" -c -o s07.o $FIX/s07-public-forward-definition/s07.HC >/dev/null 2>&1 || { echo "S07 FAIL"; F=1; }
$HCC --install-dir="$PREFIX" -c -o s08a.o $FIX/s08-mixed-linkage/s08a-public-then-static.HC >/dev/null 2>&1 || { echo "S08a FAIL"; F=1; }
$HCC --install-dir="$PREFIX" -c -o s08b.o $FIX/s08-mixed-linkage/s08b-static-then-public.HC >/dev/null 2>&1 || { echo "S08b FAIL"; F=1; }
OUT=$(printf 'static I64 Foo(){return 11;}\npublic I64 Foo(){return 22;}\n"%%d\\n", Foo();\n' | $HCC --install-dir="$PREFIX" -repl 2>&1)
echo "$OUT" | grep -q '^22$' || { echo "J03 FAIL: $OUT"; F=1; }
OUT=$(printf 'public I64 Foo(){return 11;}\n"%%d\\n", Foo();\nstatic I64 Bar(){return 22;}\n' | $HCC --install-dir="$PREFIX" -repl 2>&1)
echo "$OUT" | grep -q '^11$' || { echo "J04 FAIL: $OUT"; F=1; }
$HCC --install-dir="$PREFIX" -jit $FIX/j01-jit-single-private/j01.HC >/dev/null 2>&1; RC=$?; [ "$RC" = "1" ] || { echo "J01 FAIL rc=$RC"; F=1; }
# s09: legacy x86 backend --use-legacy-x86 must gate .global on fn_is_static
$HCC --install-dir="$PREFIX" --use-legacy-x86 --target=x86_64-apple-darwin -c -o s09.o $FIX/s09-legacy-x86-static.HC >/dev/null 2>&1
nm -m s09.o 2>/dev/null | grep -qE ' external _StaticFn$' && { echo "S09 FAIL"; F=1; } || true
nm -m s09.o 2>/dev/null | grep -qE 'non-external _StaticFn$' || { echo "S09 FAIL (StaticFn not local)"; F=1; }
[ $F = 0 ] && echo "STATIC_FUNCTION_LINKAGE_TEST=PASS" || echo "STATIC_FUNCTION_LINKAGE_TEST=FAIL"
exit $F
