#!/bin/sh
# scripts/quality/parser-slice-recon03-eligibility-controls.sh
# ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03 C2 IMPL.
#
# ELIGIBILITY NEGATIVE CONTROLS (ACT 8.3).  Shell bootstrap glue only: every
# SUBSTANTIVE decision is made by the PolyC-native checker
# tools/quality/parser-slice-recon03-eligibility.HC.  This driver mutates ONE
# fact field of ONE candidate in a COPY of the canonical facts table and
# re-runs the REAL checker, so the eligibility flag cannot be hand-authored.
set -eu
CHECKER=${1:-./build/parser-slice-recon03-eligibility}
FACTS=${2:-evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/c1/candidate-eligibility-facts.tsv}
WORK=./build/recon03-elig-controls
mkdir -p "$WORK"
fail=0
run_control() {
  id=$1; cand=$2; fld=$3; val=$4; expect=$5; out="$WORK/$id.tsv"
  awk -F'\t' -v OFS='\t' -v c="$cand" -v k="$fld" -v v="$val" \
    'BEGIN{n=0} {n++; if (n>1 && $1==c && $0 !~ /^#/) {split($0,a,"\t"); a[k]=v; s=a[1]; for(i=2;i<=NF;i++) s=s"\t"a[i]; print s} else print}' \
    "$FACTS" > "$out"
  got=$("$CHECKER" "$out" | awk -v c="$cand" '$1==c {print $2}')
  if [ "$expect" = EXCLUDED ]; then want=NO; else want=YES; fi
  [ "$got" = "$want" ] && ok=YES || ok=NO
  echo "$id candidate=$cand field=$fld value=$val expect=$expect got=$got result=$ok"
  [ "$ok" = YES ] || fail=1
}
# NC-01..NC-04: candidates the predicate MUST reject.  The mutation sets the
# disqualifying fact to its current value, so the UNCHANGED row is checked.
run_control NC-01 CAND-002 8  YES EXCLUDED
run_control NC-02 CAND-001 8  YES EXCLUDED
run_control NC-03 CAND-014 11 YES EXCLUDED
run_control NC-04 CAND-003 13 1  EXCLUDED
# NC-08: the eligibility-field mutation control.  The UNMUTATED verdict is the
# baseline, so a control passing for the wrong reason is visible.
base=$("$CHECKER" "$FACTS" | awk -v c=CAND-017 '$1==c {print $2}')
echo "NC-08 baseline_unmutated_verdict=$base"
run_control NC-08 CAND-017 8  YES EXCLUDED
# NC-11..NC-13: a hidden callback, a disguised host pointer and an
# unreachable helper are all rejected.
run_control NC-11 CAND-017 16 1 EXCLUDED
run_control NC-12 CAND-017 14 1 EXCLUDED
run_control NC-13 CAND-017 19 NO EXCLUDED
# NC-10: a synthetic second eligible candidate must pass the REAL checker.
awk -F'\t' -v OFS='\t' 'BEGIN{n=0} {n++; if (n>1 && $1=="CAND-017") {print "CTRL-SYNTHETIC-ELIGIBLE", $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20} else print}' "$FACTS" > "$WORK/NC-10.tsv"
got=$("$CHECKER" "$WORK/NC-10.tsv" | awk '$1=="CTRL-SYNTHETIC-ELIGIBLE" {print $2}')
[ "$got" = YES ] && ok=YES || ok=NO
echo "NC-10 candidate=CTRL-SYNTHETIC-ELIGIBLE expect=ELIGIBLE got=$got result=$ok"
[ "$ok" = YES ] || fail=1
echo "ELIGIBILITY_CONTROLS_FAIL=$fail"
[ "$fail" -eq 0 ] && echo "STATUS=PASS" || { echo "STATUS=FAIL"; exit 1; }
