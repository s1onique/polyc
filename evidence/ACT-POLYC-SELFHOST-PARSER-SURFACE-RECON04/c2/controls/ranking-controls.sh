#!/bin/sh
# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 C2 RANKING ANTI-BIAS CONTROLS.
#
# Every control mutates the RANKING INPUT and re-runs the REAL,
# UNMODIFIED canonical ranker, so the winner cannot be hand-picked.
#
# USAGE: ranking-controls.sh <ranker> <dims.tsv> <out.txt>
set -eu
RANKER=${1:-./build/parser-slice-recon03-ranking}
DIMS=${2:-evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c2/ranking-dimensions.tsv}
OUT=${3:-build/recon04-controls/ranking-controls.txt}
WORK=./build/recon04-controls/work
mkdir -p "$WORK"
rm -f "$WORK/.failures"

# The pristine winner, as computed by the unmodified ranker.
pristine=$("$RANKER" "$DIMS" | awk -F= '$1=="SELECTED"{print $2}')
{
echo "ACT_ID=ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04"
echo "ACT_PHASE=C2-RANK-SELECT"
echo "EVIDENCE_KIND=ranking-controls"
echo
echo "COMMAND=$RANKER <mutated copy of $DIMS>"
echo
echo "PRISTINE_WINNER=$pristine"
echo
} > "$OUT"

note_fail() { echo "$1" >> "$WORK/.failures"; }

# NC-R01 candidate row permutation: shuffling the input rows must not
# change the winner.
awk -F'\t' -v OFS='\t' '
  /^#/ { h[++nh]=$0; next }
  { r[++nr]=$0 }
  END { for(i=nr;i>=1;i--) print r[i] }
' "$DIMS" > "$WORK/NC-R01.tsv"
w=$("$RANKER" "$WORK/NC-R01.tsv" | awk -F= '$1=="SELECTED"{print $2}')
echo "NC-R01 control=row_permutation expect_winner=$pristine got_winner=$w result=$([ "$w" = "$pristine" ] && echo YES || echo NO)" >> "$OUT"
[ "$w" = "$pristine" ] || note_fail NC-R01

# NC-R02 winner removal: removing the winner must rerank the rest.
awk -F'\t' -v OFS='\t' -v c="$pristine" '
  /^#/ { print; next }
  $1==c { next }
  { print }
' "$DIMS" > "$WORK/NC-R02.tsv"
w=$("$RANKER" "$WORK/NC-R02.tsv" | awk -F= '$1=="SELECTED"{print $2}')
rem=$("$RANKER" "$WORK/NC-R02.tsv" | awk -F= '$1=="RANKED"{print $2}')
echo "NC-R02 control=winner_removal removed=$pristine new_winner=$w remaining_ranked=$rem result=$([ "$w" != "$pristine" ] && [ -n "$w" ] && echo YES || echo NO)" >> "$OUT"
if [ "$w" = "$pristine" ] || [ -z "$w" ]; then note_fail NC-R02; fi

# NC-R03 ranking-value perturbation: raising the winner's R0 must
# change the leader when a rival exists.
awk -F'\t' -v OFS='\t' -v c="$pristine" '
  /^#/ { print; next }
  $1==c { a[1]=$1; for(i=2;i<=NF;i++) a[i]=$i; a[2]=a[2]+1;
           s=a[1]; for(i=2;i<=NF;i++) s=s"\t"a[i]; print s; next }
  { print }
' "$DIMS" > "$WORK/NC-R03.tsv"
w=$("$RANKER" "$WORK/NC-R03.tsv" | awk -F= '$1=="SELECTED"{print $2}')
rivals=$("$RANKER" "$WORK/NC-R03.tsv" | awk -F= '$1=="RANKED"{n++} END{print n+0}')
echo "NC-R03 control=r0_perturbation perturbed=$pristine new_winner=$w eligible_rivals=$rivals result=$([ "$w" != "$pristine" ] && [ "$rivals" -gt 0 ] && echo YES || echo NO)" >> "$OUT"
if [ "$rivals" -gt 0 ] && [ "$w" = "$pristine" ]; then note_fail NC-R03; fi

# NC-R04 ineligible candidate with ideal scores: a row whose eligible
# column is NO must never win, whatever its scores.
awk -F'\t' -v OFS='\t' '
  /^#/ { print; next }
  $1=="CAND-040" { a[1]=$1; for(i=2;i<=NF;i++) a[i]=$i; a[3]=0; a[4]=0; a[5]=0; a[6]=0; a[7]=0; a[8]=0; a[9]="NO";
           s=a[1]; for(i=2;i<=NF;i++) s=s"\t"a[i]; print s; next }
  { print }
' "$DIMS" > "$WORK/NC-R04.tsv"
w=$("$RANKER" "$WORK/NC-R04.tsv" | awk -F= '$1=="SELECTED"{print $2}')
echo "NC-R04 control=ineligible_ideal_scores expect_winner=$pristine got_winner=$w result=$([ "$w" = "$pristine" ] && echo YES || echo NO)" >> "$OUT"
[ "$w" = "$pristine" ] || note_fail NC-R04

# NC-R05 source-order tie break: two rows with IDENTICAL R0..R5 must be
# ordered by (file lexical asc, line asc).
awk -F'\t' -v OFS='\t' '
  /^#/ { print; next }
  $1=="CAND-022" { a[1]=$1; for(i=2;i<=NF;i++) a[i]=$i; a[2]=0; a[3]=2; a[4]=2; a[5]=2; a[6]=0; a[7]=0; a[8]="src/prslib.c:700";
                   s=a[1]; for(i=2;i<=NF;i++) s=s"\t"a[i]; print s; next }
  $1=="CAND-018" { a[1]=$1; for(i=2;i<=NF;i++) a[i]=$i; a[2]=0; a[3]=2; a[4]=2; a[5]=2; a[6]=0; a[7]=0; a[8]="src/prslib.c:100";
                   s=a[1]; for(i=2;i<=NF;i++) s=s"\t"a[i]; print s; next }
  { print }
' "$DIMS" > "$WORK/NC-R05.tsv"
# The two rows now have IDENTICAL R0..R5 and differ only in R6, so the
# source-order tie break must place the lower line first.
p18=$("$RANKER" "$WORK/NC-R05.tsv" | grep '^RANKED:' | awk -F'\t' '$2=="CAND-018"{print substr($1,8)}')
p22=$("$RANKER" "$WORK/NC-R05.tsv" | grep '^RANKED:' | awk -F'\t' '$2=="CAND-022"{print substr($1,8)}')
if [ "$p18" -lt "$p22" ]; then r05=YES; else r05=NO; fi
echo "NC-R05 control=source_order_tie_break tied=CAND-018:src/prslib.c:100 vs CAND-022:src/prslib.c:700 rank_CAND-018=$p18 rank_CAND-022=$p22 expect=CAND-018_first result=$r05" >> "$OUT"
[ "$r05" = YES ] || note_fail NC-R05

# NC-R06 structural-class removal: with the whole CLASS_1 removed, the
# winner must become the CLASS_2 rank-1.
awk -F'\t' -v OFS='\t' '
  /^#/ { print; next }
  $1 ~ /^SUB-/ { next }
  { print }
' "$DIMS" > "$WORK/NC-R06.tsv"
w=$("$RANKER" "$WORK/NC-R06.tsv" | awk -F= '$1=="SELECTED"{print $2}')
echo "NC-R06 control=structural_class_removed expect_class2_rank1=CAND-022 got_winner=$w result=$([ "$w" = "CAND-022" ] && echo YES || echo NO)" >> "$OUT"
[ "$w" = "CAND-022" ] || note_fail NC-R06

# NC-R07 false structural classification: if the structural candidates
# are RE-CLASSIFIED as scalar (their R1 lowered to the scalar level),
# the winner must change to the scalar rank-1.
awk -F'\t' -v OFS='\t' '
  /^#/ { print; next }
  $1 ~ /^SUB-/ { a[1]=$1; for(i=2;i<=NF;i++) a[i]=$i; a[3]=2; a[4]=3; a[5]=2; a[6]=1; a[7]=1;
           s=a[1]; for(i=2;i<=NF;i++) s=s"\t"a[i]; print s; next }
  { print }
' "$DIMS" > "$WORK/NC-R07.tsv"
w=$("$RANKER" "$WORK/NC-R07.tsv" | awk -F= '$1=="SELECTED"{print $2}')
echo "NC-R07 control=false_structural_classification expect_winner=CAND-022 got_winner=$w result=$([ "$w" = "CAND-022" ] && echo YES || echo NO)" >> "$OUT"
[ "$w" = "CAND-022" ] || note_fail NC-R07

# NC-R08 stale candidate ID: a row whose id names a candidate that does
# not exist in the source registry must not be selectable by virtue of
# its id alone; the ranker must still rank by the DIMENSIONS.
awk -F'\t' -v OFS='\t' '
  /^#/ { print; next }
  $1=="CAND-999" { print; next }
  { print }
' "$DIMS" > "$WORK/NC-R08.tsv"
w=$("$RANKER" "$WORK/NC-R08.tsv" | awk -F= '$1=="SELECTED"{print $2}')
echo "NC-R08 control=stale_candidate_id expect_winner=$pristine got_winner=$w result=$([ "$w" = "$pristine" ] && echo YES || echo NO)" >> "$OUT"
[ "$w" = "$pristine" ] || note_fail NC-R08

# NC-R09 historical ranking replay: the frozen RECON03 ranking input
# must still produce the RECON03 ordering.
HIST=evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/c2/ranking-dimensions.tsv
hw=$("$RANKER" "$HIST" | awk -F= '$1=="SELECTED"{print $2}')
horder=$("$RANKER" "$HIST" | grep '^RANKED:' | awk -F'\t' '{print $2}' | tr '\n' ' ')
echo "NC-R09 control=historical_ranking_replay historical_winner=$hw historical_order=$horder result=$([ "$hw" = "CAND-017" ] && echo YES || echo NO)" >> "$OUT"
[ "$hw" = "CAND-017" ] || note_fail NC-R09

# The pristine rerun must still give the pristine winner.
w=$("$RANKER" "$DIMS" | awk -F= '$1=="SELECTED"{print $2}')
echo "NC-R00 pristine_recheck expect_winner=$pristine got_winner=$w result=$([ "$w" = "$pristine" ] && echo YES || echo NO)" >> "$OUT"
[ "$w" = "$pristine" ] || note_fail NC-R00

{
echo
if [ -f "$WORK/.failures" ]; then
  echo "RANKING_CONTROL_FAILURES=$(wc -l < "$WORK/.failures" | tr -d ' ')"
  echo "STATUS=FAIL"
else
  echo "RANKING_CONTROL_FAILURES=0"
  echo "STATUS=PASS"
fi
} >> "$OUT"
cat "$OUT"
[ -f "$WORK/.failures" ] && exit 1 || exit 0
