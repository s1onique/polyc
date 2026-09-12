#!/bin/sh
# scripts/quality/shell-loc-gate.sh -- enforce the <=50 LOC ratchet.
# Reads baseline.txt; fails if a new shell file is >50 LOC or any
# existing shell file grew past its baseline.
# Hard cap: 50 physical LOC.
set -eu
ROOT=${1:-scripts/quality}
BASE=${2:-evidence/ACT-POLYC-TOOLING-SHELL-INVENTORY01/c1/baseline.txt}
LIMIT=50
fail=0
if [ ! -f "$BASE" ]; then
    echo "ERROR: baseline not found: $BASE"; exit 2
fi
while IFS=' ' read -r path loc; do
    [ -z "$path" ] && continue
    cur=$(wc -l <"$path" | tr -d ' ')
    base=$(awk -v p="$path" '$1==p{print $2}' "$BASE")
    if [ -z "$base" ]; then
        [ "$cur" -le "$LIMIT" ] || { echo "FAIL  NEW   $path  cur=$cur > 50"; fail=1; }
    else
        [ "$cur" -le "$base" ] || { echo "FAIL  GROW  $path  base=$base cur=$cur"; fail=1; }
    fi
done <<EOF
$(find "$ROOT" -maxdepth 1 -type f -name '*.sh')
EOF
[ "$fail" -eq 0 ] && echo "PASS  shell-loc-gate" || exit 1
