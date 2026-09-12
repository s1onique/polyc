#!/bin/sh
# scripts/quality/inventory.sh -- one row per shell script under scripts/
# with LOC, shebang, executable bit, and role tag.
# Hard cap: 50 physical LOC.
set -eu
ROOT=${1:-scripts}
find "$ROOT" -maxdepth 3 -type f -name '*.sh' -print 2>/dev/null \
| while read -r f; do
    loc=$(wc -l <"$f" | tr -d ' ')
    shebang=$(head -n 1 "$f" 2>/dev/null || echo "")
    if [ -x "$f" ]; then x="X"; else x="-"; fi
    case "$f" in
        *llvm-*test*)     role=TEST ;;
        *gate-*)          role=GATE ;;
        *factory*)        role=FACTORY ;;
        *)                role=TOOL ;;
    esac
    printf '%-50s %4s %1s %-12s %s\n' "$f" "$loc" "$x" "$role" "$shebang"
done
