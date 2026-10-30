#!/bin/sh
# ACT-POLYC-SELFHOST-PARSER-SLICE09: function-scoped relocation scope.
# USAGE: parser-slice09-reloc-scope.sh <object> <symbol>
# Bootstrap glue only: no domain rule lives here.
set -eu
OBJ=${1:?}; SYM=${2:?}
[ -f "$OBJ" ] || { echo "reloc-scope: no object: $OBJ" >&2; exit 2; }
OD="xcrun llvm-objdump"
command -v "$OD" >/dev/null 2>&1 || OD=objdump
START=$(nm -n "$OBJ" | awk -v s="_$SYM" '$3==s{print "0x"$1;exit}')
[ -n "$START" ] || { echo "reloc-scope: no _$SYM" >&2; exit 4; }
END=$(nm -n "$OBJ" | awk -v s="_$SYM" '$3==s{f=1;next} f&&$2~/^[TtDdBb]$/{print "0x"$1;exit}')
[ -n "$END" ] || END=0xFFFFFFFFFFFFFFFF
"$OD" -r "$OBJ" 2>/dev/null | awk '$1~/^[0-9a-f]{8,16}$/{print ("0x"$1),$2,$3}' | \
awk -v lo="$START" -v hi="$END" 'BEGIN{lo=strtonum(lo);hi=strtonum(hi)}{a=strtonum($1);if(a>=lo&&a<hi)print $2,$3}' | \
sort | uniq -c | awk '{print $2,$3,$1}'
