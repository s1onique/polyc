#!/bin/sh
# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 C2 ELIGIBILITY NEGATIVE CONTROLS.
#
# Every control mutates ONE fact field of ONE candidate in a COPY of the
# canonical facts table and re-runs the REAL, UNMODIFIED checker, so the
# eligibility flag cannot be hand-authored and a control that passes for
# the wrong reason is visible.
#
# USAGE: eligibility-controls.sh <checker> <facts.tsv> <out.txt>
set -eu
CHECKER=${1:-./build/parser-slice-recon03-eligibility}
FACTS=${2:-evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c1/eligibility-input-facts.tsv}
OUT=${3:-build/recon04-controls/eligibility-controls.txt}
WORK=./build/recon04-controls/work
mkdir -p "$WORK"

mutate() {
  awk -F'\t' -v OFS='\t' -v c="$1" -v k="$2" -v v="$3" '
    /^#/ { print; next }
    $1==c { a[1]=$1; for(i=2;i<=NF;i++) a[i]=$i; a[k]=v;
            s=a[1]; for(i=2;i<=NF;i++) s=s"\t"a[i]; print s; next }
    { print }
  ' "$FACTS" > "$4"
}

run_control() {
  id=$1; cand=$2; fld=$3; val=$4; expect=$5; clause=$6; out="$WORK/$id.tsv"
  mutate "$cand" "$fld" "$val" "$out"
  line=$("$CHECKER" "$out" | awk -v c="$cand" '$1==c {print $2"|"$3}')
  got=$(printf '%s' "$line" | cut -d'|' -f1)
  bits=$(printf '%s' "$line" | cut -d'|' -f2)
  if [ "$expect" = EXCLUDED ]; then want=NO; else want=YES; fi
  if [ "$got" = "$want" ]; then ok=YES; else ok=NO; fi
  targeted=""
  case "$clause" in
    1)  targeted=$(printf '%s' "$bits" | cut -c1) ;;
    2)  targeted=$(printf '%s' "$bits" | cut -c2) ;;
    3)  targeted=$(printf '%s' "$bits" | cut -c3) ;;
    4)  targeted=$(printf '%s' "$bits" | cut -c4) ;;
    5)  targeted=$(printf '%s' "$bits" | cut -c5) ;;
    6)  targeted=$(printf '%s' "$bits" | cut -c6) ;;
    7)  targeted=$(printf '%s' "$bits" | cut -c7) ;;
    8)  targeted=$(printf '%s' "$bits" | cut -c8) ;;
    9)  targeted=$(printf '%s' "$bits" | cut -c9) ;;
    10) targeted=$(printf '%s' "$bits" | cut -c10) ;;
    11) targeted=$(printf '%s' "$bits" | cut -c11) ;;
    12) targeted=$(printf '%s' "$bits" | cut -c12) ;;
    13) targeted=$(printf '%s' "$bits" | cut -c13) ;;
  esac
  if [ -n "$targeted" ] && [ "$targeted" = "1" ]; then tOK=NO; else tOK=YES; fi
  echo "$id candidate=$cand field=$fld value=$val target_clause=$clause targeted_clause_bit=$targeted expect=$expect got=$got verdict=$ok targeted_clause_failed=$tOK"
  if [ "$ok" != YES ] || [ "$tOK" != YES ]; then echo "$id" >> "$WORK/.failures"; fi
}

{
echo "ACT_ID=ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04"
echo "ACT_PHASE=C2-RANK-SELECT"
echo "EVIDENCE_KIND=eligibility-controls"
echo
echo "COMMAND=$CHECKER <mutated copy of $FACTS>"
echo
} > "$OUT"

rm -f "$WORK/.failures"
run_control NC-E01 SUB-001 8 YES EXCLUDED 2 >> "$OUT"
run_control NC-E02 SUB-001 6 STATIC_HELPER EXCLUDED 13 >> "$OUT"
run_control NC-E03 SUB-001 13 1 EXCLUDED 7 >> "$OUT"
run_control NC-E04 SUB-001 10 YES EXCLUDED 4 >> "$OUT"
run_control NC-E04b SUB-001 11 YES EXCLUDED 5 >> "$OUT"
run_control NC-E04c SUB-001 12 YES EXCLUDED 6 >> "$OUT"
run_control NC-E05 SUB-001 15 1 EXCLUDED 9 >> "$OUT"
run_control NC-E05b SUB-001 16 1 EXCLUDED 10 >> "$OUT"
run_control NC-E06 SUB-001 9 3 EXCLUDED 3 >> "$OUT"
run_control NC-E07 SUB-001 19 NO EXCLUDED 0 >> "$OUT"
run_control NC-E08 SUB-001 17 NO EXCLUDED 11 >> "$OUT"
run_control NC-E09 SUB-001 18 NO EXCLUDED 12 >> "$OUT"
run_control NC-E10 SUB-001 14 1 EXCLUDED 8 >> "$OUT"
run_control NC-E11 SUB-001 7 NO EXCLUDED 1 >> "$OUT"
#
# The UNMUTATED baseline: the pristine table must accept the candidate.
#
base=$("$CHECKER" "$FACTS" | awk -v c=SUB-001 '$1==c {print $2}')
echo "NC-E00 baseline_unmutated_verdict=$base" >> "$OUT"
if [ "$base" != YES ]; then echo "NC-E00" >> "$WORK/.failures"; fi
#
{
echo
if [ -f "$WORK/.failures" ]; then
  echo "ELIGIBILITY_CONTROL_FAILURES=$(wc -l < "$WORK/.failures" | tr -d ' ')"
  echo "STATUS=FAIL"
else
  echo "ELIGIBILITY_CONTROL_FAILURES=0"
  echo "STATUS=PASS"
fi
} >> "$OUT"
cat "$OUT"
[ -f "$WORK/.failures" ] && exit 1 || exit 0
