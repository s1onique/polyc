#!/bin/sh
# tools/quality/core-operator-implement01-fixtures.sh
#
# ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01 C1.
#
# THE SOURCE-BOUND FIXTURE GENERATOR.
#
# It derives the complete, boundary-complete fixture population for all
# three selected sites from LIVE source bytes and the INDEPENDENT G0 C
# oracle. It does NOT call PolyC and it does NOT copy the PolyC
# implementation.
#
# Partitions per site:
#
#   SITE-COMPOUND-ASSIGN
#     positive   : every enumerated compound-assignment token (10)
#     negative   : every other TK_ token value, plain '=', other punctuation
#     boundary   : the value immediately below and above each compound token
#     invalid    : token values outside the whole token domain
#
#   SITE-VALID-POINTER-OP
#     positive   : every accepted operator
#     negative   : every rejected operator in the enum
#     boundary   : the enum-adjacent values on both sides
#     invalid    : operator values outside the enum
#
#   SITE-RANGE-OPERATOR
#     positive   : every accepted operator
#     negative   : every rejected operator in the enum
#     boundary   : the enum-adjacent values on both sides
#     invalid    : operator values outside the enum
#
# The fixture rows carry the NUMERIC input values (what the ABI actually
# transports) and the expected value produced by the G0 C oracle.
#
# Usage:
#   core-operator-implement01-fixtures.sh <git-ref> <out-dir>
set -eu
REPO=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO"
REF=${1:-HEAD}
OUT=${2:-/tmp/aci01-fixtures}
DERIVED=/tmp/aci01-fixtures-derived
rm -rf "$DERIVED"; mkdir -p "$OUT" "$DERIVED"
sh tools/quality/core-operator-implement01-enum-domain.sh "$REF" "$DERIVED" > "$DERIVED/enum-summary.txt"

# Build NUMERIC decision tables (operator VALUE -> expected) from the
# symbolic ones derived from source. The classification below compares
# numeric values, so the symbolic names must be resolved here.
awk -F'\t' 'NR==FNR{ if (FNR>1) v[$1]=$2; next } FNR>1{ print v[$1] "\t" $2 }' \
  "$DERIVED/astbinop.tsv" "$DERIVED/decision-po.tsv" > "$DERIVED/decision-po-numeric.tsv"
awk -F'\t' 'NR==FNR{ if (FNR>1) v[$1]=$2; next } FNR>1{ print v[$1] "\t" $2 }' \
  "$DERIVED/astbinop.tsv" "$DERIVED/decision-ro.tsv" > "$DERIVED/decision-ro-numeric.tsv"
awk -F'\t' 'NR==FNR{ if (FNR>1) v[$1]=$2; next } FNR>1{ print v[$2] "\t" $3 }' \
  "$DERIVED/tokens.tsv" "$DERIVED/decision-ca.tsv" > "$DERIVED/decision-ca-numeric.tsv"

cc -std=c99 -O2 -Wall -Wextra -o "$DERIVED/g0-oracle" \
   tools/quality/core-operator-implement01-g0-oracle.c
G0_SHA=$(shasum -a 256 "$DERIVED/g0-oracle" | cut -d' ' -f1)
G0_SRC_SHA=$(shasum -a 256 tools/quality/core-operator-implement01-g0-oracle.c | cut -d' ' -f1)

tkval() { awk -F'\t' -v k="$1" '$1==k{print $2}' "$DERIVED/tokens.tsv"; }
opval() { awk -F'\t' -v k="$1" '$1==k{print $2}' "$DERIVED/astbinop.tsv"; }

# ---- the request stream (SYMBOLIC), derived from the source decision tables ----
REQ="$DERIVED/requests.txt"
: > "$REQ"
# CA positives: exactly the enumerated compound-assignment tokens.
awk -F'\t' 'NR>1{print "CA TK_PUNCT " $2}' "$DERIVED/decision-ca.tsv" >> "$REQ"
# CA negatives: every TK_ token that is NOT a compound-assignment token.
awk -F'\t' '
  NR==FNR { if (FNR>1) ca[$2]=1; next }
  { if (!($1 in ca)) print "CA TK_PUNCT " $1 }
' "$DERIVED/decision-ca.tsv" "$DERIVED/tokens.tsv" >> "$REQ"
# CA negatives: a non-TK_PUNCT token type carrying a compound token value.
awk -F'\t' 'NR>1{print "CA TK_IDENT " $2}' "$DERIVED/decision-ca.tsv" >> "$REQ"
# CA boundaries: the numeric value immediately below and above each compound
# token, plus the token-domain edges.
awk -F'\t' 'NR>1 { v=$2+0; print "CA TK_PUNCT " (v-1); print "CA TK_PUNCT " (v+1) }' \
  "$DERIVED/decision-ca.tsv" >> "$REQ"
printf 'CA TK_PUNCT -1\nCA TK_PUNCT 999999\n' >> "$REQ"

# PO and RO: EVERY operator in the AstBinOp enum.
awk -F'\t' 'NR>1{print "PO " $2; print "RO " $2}' "$DERIVED/astbinop.tsv" >> "$REQ"
LASTOP=$(awk -F'\t' 'END{print $2}' "$DERIVED/astbinop.tsv")
FIRSTOP=$(awk -F'\t' 'NR==2{print $2}' "$DERIVED/astbinop.tsv")
printf 'PO %s\nRO %s\n' "$((FIRSTOP - 1))" "$((FIRSTOP - 1))" >> "$REQ"
printf 'PO %s\nRO %s\n' "$((LASTOP + 1))" "$((LASTOP + 1))" >> "$REQ"
printf 'PO -1\nRO -1\nPO 99999\nRO 99999\n' >> "$REQ"

# ---- resolve the symbolic requests into the numeric ABI inputs ----
NUMREQ="$DERIVED/requests-numeric.txt"
: > "$NUMREQ"
while read -r kind x y; do
  case "$kind" in
    CA)
      if [ -n "$y" ]; then
        tv=$(tkval "$y"); tt=$(tkval "$x")
        [ -z "$tv" ] && tv=$y
        [ -z "$tt" ] && tt=$x
        printf 'CA %s %s\n' "$tt" "$tv" >> "$NUMREQ"
      else
        printf 'CA %s %s\n' "$x" "$x" >> "$NUMREQ"
      fi
      ;;
    PO|RO)
      ov=$(opval "$x"); [ -z "$ov" ] && ov=$x
      printf '%s %s\n' "$kind" "$ov" >> "$NUMREQ"
      ;;
  esac
done < "$REQ"

# ---- run the G0 oracle to obtain the expected values ----
"$DERIVED/g0-oracle" < "$NUMREQ" > "$DERIVED/answers.txt"

CA_BLOB=$(git rev-parse "$REF:src/prslib.c")
AST_BLOB=$(git rev-parse "$REF:src/ast.c")
CA_SHA=4d941407ee054e207586b3a4fb645caf8917e6b43fa467b79d50a75e1b54bb43
PO_SHA=bc06b0d757538f6c00ce0e96003cf5613823e98f4c48288c727cf9ac1dd82ac5
RO_SHA=8c1acadaa4f1ae26d27c6be491812db2d16a8dd18528cb5cf2cc81d242b24f99
HDR='fixture_id	site_id	source_git_blob	source_range_sha256	input_domain	input_1	input_2_if_present	expected_value	expected_status	semantic_partition	reachable_by_real_compiler	oracle_object_sha256	expected_witness_id'

CA_OUT="$OUT/fixture-ca.tsv"; PO_OUT="$OUT/fixture-po.tsv"; RO_OUT="$OUT/fixture-ro.tsv"
ALL_OUT="$OUT/fixture-all.tsv"
printf '%s\n' "$HDR" > "$CA_OUT"
printf '%s\n' "$HDR" > "$PO_OUT"
printf '%s\n' "$HDR" > "$RO_OUT"
printf '%s\n' "$HDR" > "$ALL_OUT"

nca=0; npo=0; nro=0
while read -r kind x y z st extra; do
  case "$kind" in
    CA)
      tt=$x; tv=$y; iscompound=$z; opval_c=$st
      if [ "$iscompound" = "1" ]; then part=POSITIVE; else
        if [ "$tv" -lt 0 ] 2>/dev/null || [ "$tv" -gt 4095 ] 2>/dev/null; then
          part=INVALID_OUT_OF_DOMAIN
        else
          part=NEGATIVE
        fi
      fi
      nca=$((nca + 1))
      fid=$(printf 'CA-%04d' "$nca")
      row="$fid	SITE-COMPOUND-ASSIGN	$CA_BLOB	$CA_SHA	token_type+token_value	$tt	$tv	$opval_c	0	$part	YES	$G0_SHA	W-CA-$fid"
      printf '%s\n' "$row" >> "$CA_OUT"; printf '%s\n' "$row" >> "$ALL_OUT"
      ;;
    PO)
      if awk -F'\t' -v k="$x" '$1==k{print $2}' "$DERIVED/decision-po-numeric.tsv" | grep -q '^1$'; then part=POSITIVE; else
        if [ "$x" -ge 0 ] && [ "$x" -le "$LASTOP" ]; then part=NEGATIVE
        else part=INVALID_OUT_OF_ENUM; fi
      fi
      npo=$((npo + 1))
      fid=$(printf 'PO-%04d' "$npo")
      row="$fid	SITE-VALID-POINTER-OP	$AST_BLOB	$PO_SHA	binary_operator	$x	-	$y	0	$part	YES	$G0_SHA	W-PO-$fid"
      printf '%s\n' "$row" >> "$PO_OUT"; printf '%s\n' "$row" >> "$ALL_OUT"
      ;;
    RO)
      if awk -F'\t' -v k="$x" '$1==k{print $2}' "$DERIVED/decision-ro-numeric.tsv" | grep -q '^1$'; then part=POSITIVE; else
        if [ "$x" -ge 0 ] && [ "$x" -le "$LASTOP" ]; then part=NEGATIVE
        else part=INVALID_OUT_OF_ENUM; fi
      fi
      nro=$((nro + 1))
      fid=$(printf 'RO-%04d' "$nro")
      row="$fid	SITE-RANGE-OPERATOR	$AST_BLOB	$RO_SHA	binary_operator	$x	-	$y	0	$part	YES	$G0_SHA	W-RO-$fid"
      printf '%s\n' "$row" >> "$RO_OUT"; printf '%s\n' "$row" >> "$ALL_OUT"
      ;;
  esac
done < "$DERIVED/answers.txt"

echo "G0_ORACLE_SHA256=$G0_SHA"
echo "G0_ORACLE_SOURCE_SHA256=$G0_SRC_SHA"
echo "CA_FIXTURE_ROWS=$nca"
echo "PO_FIXTURE_ROWS=$npo"
echo "RO_FIXTURE_ROWS=$nro"
echo "ALL_FIXTURE_ROWS=$(($(wc -l < "$ALL_OUT") - 1))"
echo "REQUEST_ROWS=$(wc -l < "$NUMREQ")"
