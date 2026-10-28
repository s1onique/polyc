#!/bin/sh
# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 C3 INDEPENDENT ELIGIBILITY RECOMPUTATION.
#
# This recomputes eligibility FROM THE C1 FACT FIELDS, WITHOUT reading
# the `eligible` column of the C2 ranking table.  It implements the 13
# clauses directly from the committed checker source, and then compares
# its result against the C2 eligibility results.
#
# USAGE: c3-elig-recompute.sh <facts.tsv> <c2-results.tsv> <out.tsv>
set -eu
FACTS=${1:-evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c1/eligibility-input-facts.tsv}
C2RES=${2:-evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c2/eligibility-results.tsv}
OUT=${3:-evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04/c3/eligibility-recompute.tsv}

# The 13 clause tests, re-implemented here from the committed checker
# source (tools/quality/parser-slice-recon03-eligibility.HC).
awk -F'\t' -v OFS='\t' -v c2="$C2RES" '
  BEGIN {
    while ((getline line < c2) > 0) {
      if (line ~ /^#/ || line == "") continue;
      n = split(line, a, "\t");
      if (a[1] == "TOTAL" || a[1] == "ELIGIBLE" || a[1] == "MALFORMED" || a[1] == "STATUS") continue;
      c2elig[a[1]] = a[2];
      c2bits[a[1]] = a[3];
    }
  }
  /^#/ { next }
  {
    id=$1; kind=$6;
    c[1]  = ($7 == "YES");
    c[2]  = ($8 == "NO");
    c[3]  = ($9 + 0) <= 2;
    c[4]  = ($10 == "NO");
    c[5]  = ($11 == "NO");
    c[6]  = ($12 == "NO");
    c[7]  = ($13 + 0) == 0;
    c[8]  = ($14 + 0) == 0;
    c[9]  = ($15 + 0) == 0;
    c[10] = ($16 + 0) == 0;
    c[11] = ($17 == "YES");
    c[12] = ($18 == "YES");
    k = kind;
    c[13] = (k=="OPERATOR_PRECEDENCE_TABLE" || k=="OPERATOR_CLASSIFIER" ||
              k=="FORMAT_SPEC_COUNTER" || k=="FORMAT_FUNCTION_TABLE" ||
              k=="ALIGNMENT_CALCULATION" || k=="TOKEN_CLASSIFIER" ||
              k=="AST_PROJECTION_PRIMITIVE" || k=="DELIMITER_PRIMITIVE" ||
              k=="TYPE_MODIFIER_PRIMITIVE");
    ok = 1; failed = 0;
    for (i=1;i<=13;i++) { if (!c[i]) { ok = 0; failed++; } }
    if ($19 != "YES") ok = 0;
    e = (ok ? "YES" : "NO");
    bits = "";
    for (i=1;i<=13;i++) bits = bits (c[i] ? "1" : "0");
    print id"\t"e"\t"bits"\t"failed"\tc2="c2elig[id]"\tc2bits="c2bits[id];
    if (c2elig[id] != e) mismatch++;
    if (c2bits[id] != bits) bitmismatch++;
    total++;
    if (e == "YES") elig++;
  }
  END {
    printf "# C3_ELIGIBILITY_RECOMPUTE_TOTAL=%d\n", total;
    printf "# C3_ELIGIBILITY_RECOMPUTE_ELIGIBLE=%d\n", elig;
    printf "# C3_VS_C2_VERDICT_MISMATCHES=%d\n", mismatch + 0;
    printf "# C3_VS_C2_CLAUSEBIT_MISMATCHES=%d\n", bitmismatch + 0;
  }
' "$FACTS" > "$OUT"
cat "$OUT"
