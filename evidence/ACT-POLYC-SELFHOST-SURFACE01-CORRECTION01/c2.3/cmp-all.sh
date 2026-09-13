#!/bin/sh
# cmp-all.sh — byte-compare every captured case between raw/ (Python)
# and polyc-raw/ (PolyC). Exits 0 on full parity, 1 on any diff.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
PY=$HERE/raw
PO=$HERE/polyc-raw

fail=0
ids=""
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do ids="$ids R$i"; done
for i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24; do ids="$ids D$i"; done
ids="$ids USAGE MISSING_FILE MATRIX"

for f in $ids; do
  cmp -s $PY/$f.stdout $PO/$f.stdout || { echo "STDOUT_DIFF $f"; fail=1; }
  cmp -s $PY/$f.stderr $PO/$f.stderr || { echo "STDERR_DIFF $f"; fail=1; }
  diff -q $PY/$f.rc     $PO/$f.rc     >/dev/null || { echo "RC_DIFF $f"; fail=1; }
done

if [ $fail -eq 0 ]; then
  echo "STDOUT_EQ=ALL"
  echo "STDERR_EQ=ALL"
  echo "RC_EQ=ALL"
  echo "CMP_RESULT=ALL_BYTE_EQ"
fi
exit $fail
