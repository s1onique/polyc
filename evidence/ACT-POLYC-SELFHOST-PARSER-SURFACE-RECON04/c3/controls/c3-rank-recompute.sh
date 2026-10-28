#!/bin/sh
# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 C3 INDEPENDENT RANKING RECOMPUTATION.
#
# This re-runs the UNMODIFIED canonical ranker over the C1 fact table
# and the C2 ranking dimensions, with the `eligible` column taken from
# the C3 ELIGIBILITY RECOMPUTATION (which itself recomputes eligibility
# from the facts and does NOT read the C2 eligible column).
#
# It then compares the result against the C2 ranking, class by class.
#
# USAGE: c3-rank-recompute.sh <facts> <dims> <c3-elig> <c2-ranked> <out>
set -eu
FACTS=${1:-evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c1/eligibility-input-facts.tsv}
DIMS=${2:-evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c2/ranking-dimensions.tsv}
C3ELIG=${3:-evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c3/eligibility-recompute.tsv}
C2RANK=${4:-evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c2/ranked-all-candidates.tsv}
OUT=${5:-evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c3/ranking-recompute.tsv}
RANKER=./build/parser-slice-recon03-ranking
WORK=./build/recon04-controls/work
mkdir -p "$WORK"

# Build the ranker input: the C2 dimensions, but with the `eligible`
# column REPLACED by the C3 recomputed value.
awk -F'\t' -v OFS='\t' -v e="$C3ELIG" '
  BEGIN {
    while ((getline line < e) > 0) {
      if (line ~ /^#/ || line == "") continue;
      n = split(line, a, "\t");
      el[a[1]] = a[2];
    }
  }
  /^#/ { print; next }
  {
    a[1]=$1; for(i=2;i<=NF;i++) a[i]=$i;
    a[9]=el[$1];
    s=a[1]; for(i=2;i<=NF;i++) s=s"\t"a[i]; print s;
  }
' "$DIMS" > "$WORK/c3-rank-input.tsv"

"$RANKER" "$WORK/c3-rank-input.tsv" > "$WORK/c3-rank-out.txt"

# Compare the whole ranked order with the C2 order.
c2order=$(grep '^RANKED:' "$C2RANK" | awk -F'\t' '{print $2}' | tr '\n' ' ')
c3order=$(grep '^RANKED:' "$WORK/c3-rank-out.txt" | awk -F'\t' '{print $2}' | tr '\n' ' ')
c2win=$(grep '^SELECTED=' "$C2RANK" | cut -d= -f2)
c3win=$(grep '^SELECTED=' "$WORK/c3-rank-out.txt" | cut -d= -f2)

# The class partitions.
c3struct=$(grep '^RANKED:' "$WORK/c3-rank-out.txt" | awk -F'\t' '{print $2}' | while read -r c; do
  cls=$(awk -F'\t' -v x="$c" '$1==x{print $13}' evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c1/structural-subslices.tsv)
  if [ "$cls" = "STRUCTURAL_BOUNDARY" ]; then printf '%s ' "$c"; fi
done)
c3scalar=$(grep '^RANKED:' "$WORK/c3-rank-out.txt" | awk -F'\t' '{print $2}' | while read -r c; do
  cls=$(awk -F'\t' -v x="$c" '$1==x{print $13}' evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c1/structural-subslices.tsv)
  if [ "$cls" != "STRUCTURAL_BOUNDARY" ]; then printf '%s ' "$c"; fi
done)

{
echo "# ACT_ID=ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04"
echo "# ACT_PHASE=C3-VERIFY"
echo "# EVIDENCE_KIND=ranking-recompute"
echo "#"
echo "# The ranking was recomputed from the C1 facts and the C2 dimensions,"
echo "# with the eligible column taken from the C3 eligibility RECOMPUTATION"
echo "# (which recomputes eligibility from the facts and does NOT read the"
echo "# C2 eligible column)."
echo "#"
echo "C3_RANKED_ORDER=$c3order"
echo "C2_RANKED_ORDER=$c2order"
echo "C3_WINNER=$c3win"
echo "C2_WINNER=$c2win"
if [ "$c3order" = "$c2order" ]; then echo "RANKING_ORDER_IDENTICAL=YES"; else echo "RANKING_ORDER_IDENTICAL=NO"; fi
if [ "$c3win" = "$c2win" ]; then echo "WINNER_IDENTICAL=YES"; else echo "WINNER_IDENTICAL=NO"; fi
echo "C3_STRUCTURAL_RANKING=$c3struct"
echo "C3_SCALAR_RANKING=$c3scalar"
echo "C3_STRUCTURAL_RANK1=$(printf '%s' "$c3struct" | cut -d' ' -f1)"
echo "C3_SCALAR_RANK1=$(printf '%s' "$c3scalar" | cut -d' ' -f1)"
echo "#"
echo "--- the recomputed ranking, verbatim ---"
cat "$WORK/c3-rank-out.txt"
} > "$OUT"
cat "$OUT"
