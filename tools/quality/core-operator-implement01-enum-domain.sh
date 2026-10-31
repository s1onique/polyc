#!/bin/sh
# tools/quality/core-operator-implement01-enum-domain.sh
#
# ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01 C1.
#
# THE INDEPENDENT SOURCE-DOMAIN DERIVER.
#
# It parses LIVE Git source bytes (not a checked-in constant table) and
# derives:
#
#   * the AstBinOp enum domain and its numeric values, from src/ast.h;
#   * the TK_ token domain and its numeric values, from src/lexer.h;
#   * the three selected decision tables, from the frozen source ranges.
#
# It NEVER hardcodes an expected aggregate count: the row count is whatever
# the live source yields, and the caller compares it to the C oracle.
#
# The expected VALUES come from the G0 C ORACLE (the real C predicate),
# which is an INDEPENDENT implementation, not from the PolyC subject.
#
# Usage:
#   core-operator-implement01-enum-domain.sh <git-ref> <out-dir>
#
# Writes <out-dir>/enum-domain.tsv and <out-dir>/astbinop.tsv.
set -eu
REPO=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO"
REF=${1:-HEAD}
OUT=${2:-/tmp/aci01-enum}
mkdir -p "$OUT"

ASTH=$(mktemp); LEXH=$(mktemp); PRS=$(mktemp); ASTC=$(mktemp)
trap 'rm -f "$ASTH" "$LEXH" "$PRS" "$ASTC"' EXIT
git cat-file blob "$REF:src/ast.h" > "$ASTH"
git cat-file blob "$REF:src/lexer.h" > "$LEXH"
git cat-file blob "$REF:src/prslib.c" > "$PRS"
git cat-file blob "$REF:src/ast.c"  > "$ASTC"

# ---- 1. AstBinOp enum: name -> numeric value, derived from the C enum ----
awk '
  /typedef enum AstBinOp \{/ { inb=1; next }
  inb && /^\} AstBinOp;/ { inb=0 }
  inb {
    line=$0
    sub(/\/\*.*$/, "", line)
    gsub(/^[ \t]+/, "", line)
    if (line == "") next
    n=split(line, a, ",")
    for (i=1;i<=n;i++) {
      nm=a[i]
      gsub(/^[ \t]+|[ \t]+$/, "", nm)
      if (nm == "") continue
      if (nm !~ /^AST_BIN_OP_[A-Z_]+$/) continue
      print nm "\t" val
      val++
    }
  }
' "$ASTH" > "$OUT/astbinop.tsv"

# ---- 2. TK_ token domain from src/lexer.h ----
# Every TK_ define is included: the hex-valued ones AND the single decimal
# one (TK_EOF 0). The row count is DERIVED, never asserted.
#
# The hex values are converted with strtonum when the awk provides it and
# with an explicit per-digit hex expansion otherwise, so the numeric domain
# is exact on every awk. (A bare "0x319" + 0 is NOT portable: on BSD awk it
# yields the STRING "0x319", not the number 793.)
awk '
  function hexnum(s,   i, c, v, d) {
    v = 0
    for (i = 1; i <= length(s); i++) {
      c = tolower(substr(s, i, 1))
      d = index("0123456789abcdef", c) - 1
      if (d < 0) return -1
      v = v * 16 + d
    }
    return v
  }
  /^#define TK_[A-Z_0-9]+[ \t]+[0-9]/ {
    line=$0
    sub(/\/\/.*$/, "", line)
    split(line, a, /[ \t]+/)
    nm=a[2]; val=a[3]
    if (val ~ /^0[xX]/) { printf "%s\t%d\n", nm, hexnum(substr(val, 3)) }
    else { printf "%s\t%d\n", nm, (val + 0) }
  }
' "$LEXH" | sort -u > "$OUT/tokens.tsv"

# ---- 3. The three selected decision tables, from the frozen source ranges ----
# SITE-COMPOUND-ASSIGN: src/prslib.c:1328..1348
CA_OUT="$OUT/decision-ca.tsv"
printf 'input_token_type\tinput_token_value\texpected_operator\texpected_status\n' > "$CA_OUT"
awk '
  NR>=1328 && NR<=1348 {
    if ($0 ~ /case TK_[A-Z_]+:/) {
      line=$0
      sub(/.*case TK_/, "", line)
      sub(/:.*/, "", line)
      tok=line
      op=$0
      sub(/.*\*_op = /, "", op)
      sub(/;.*/, "", op)
      printf "TK_PUNCT\tTK_%s\t%s\t0\n", tok, op
    }
  }
' "$PRS" >> "$CA_OUT"

# SITE-VALID-POINTER-OP: src/ast.c:974..990
PO_OUT="$OUT/decision-po.tsv"
printf 'input_operator\texpected_valid\n' > "$PO_OUT"
awk '
  NR>=974 && NR<=990 {
    if ($0 ~ /case AST_BIN_OP_[A-Z_]+:/) {
      line=$0
      sub(/.*case /, "", line)
      sub(/:.*/, "", line)
      print line "\t1"
    }
  }
' "$ASTC" >> "$PO_OUT"

# SITE-RANGE-OPERATOR: src/ast.c:2348..2358
RO_OUT="$OUT/decision-ro.tsv"
printf 'input_operator\texpected_range\n' > "$RO_OUT"
awk '
  NR>=2348 && NR<=2358 {
    if ($0 ~ /case AST_BIN_OP_[A-Z_]+:/) {
      line=$0
      sub(/.*case /, "", line)
      sub(/:.*/, "", line)
      print line "\t1"
    }
  }
' "$ASTC" >> "$RO_OUT"

# ---- 4. The consolidated enum-domain table ----
DOM="$OUT/enum-domain.tsv"
printf 'domain_kind\tsymbol\tnumeric_value\tsource_file\tsource_range\n' > "$DOM"
while IFS="$(printf '\t')" read -r nm v; do
  printf 'AstBinOp\t%s\t%s\tsrc/ast.h\ttypedef enum AstBinOp\n' "$nm" "$v" >> "$DOM"
done < "$OUT/astbinop.tsv"
while IFS="$(printf '\t')" read -r nm v; do
  printf 'Token\t%s\t%s\tsrc/lexer.h\t#define TK_\n' "$nm" "$v" >> "$DOM"
done < "$OUT/tokens.tsv"

echo "ASTBINOP_ROWS=$(($(wc -l < "$OUT/astbinop.tsv") + 0))"
echo "TOKEN_ROWS=$(($(wc -l < "$OUT/tokens.tsv") + 0))"
echo "CA_DECISION_ROWS=$(($(wc -l < "$CA_OUT") - 1))"
echo "PO_DECISION_ROWS=$(($(wc -l < "$PO_OUT") - 1))"
echo "RO_DECISION_ROWS=$(($(wc -l < "$RO_OUT") - 1))"
echo "ENUM_DOMAIN_ROWS=$(($(wc -l < "$DOM") - 1))"
