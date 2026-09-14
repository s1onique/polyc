#!/bin/sh
# lexer07-fixture-inventory.sh
#
# Mechanical classifier for the lexer07-direct-differential
# corpus. Parses the binary's output and produces a TSV with
# observed contract per fixture.
#
# Categories are derived from OBSERVED contract:
#   is_numeric = (kind==1 OR kind==2)        [I64 or F64]
#   is_char    = (kind==3)                  [CHAR]
#   is_negative = (err != 0)                [real error]
#   is_edge    = (cursor < 0 OR cursor >= src_len)
#
# Floor requirements:
#   TOTAL >= 64
#   is_char >= 24
#   is_negative >= 16
#
# Exits 0 if all floors satisfied, 1 otherwise.

set -eu

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

if [ ! -x ./build/lexer07-direct-differential ]; then
  echo "FATAL: ./build/lexer07-direct-differential not built" >&2
  exit 1
fi

OUTDIR="evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION02/c2"
TSV="$OUTDIR/fixture-inventory.tsv"
SUMMARY="$OUTDIR/fixture-inventory-summary.txt"

mkdir -p "$OUTDIR"

# Extract {name, src, cursor, flags} tuples from the C source
awk '
BEGIN { in_inputs = 0 }
/^static input_t INPUTS\[\]/ { in_inputs = 1; next }
in_inputs && /^};/ { in_inputs = 0 }
in_inputs {
  # Each line: {"name", "src", cursor, flags},
  line = $0
  gsub(/^[ \t]+|[ \t]+$/, "", line)
  # Strip trailing comma and braces
  gsub(/,$/, "", line)
  gsub(/^\{/, "", line)
  gsub(/^\}/, "", line)
  # Now we have: "name", "src", cursor, flags  (or possibly
  # on multiple lines if the source has long strings).
  if (line ~ /^"[a-zA-Z_][a-zA-Z_0-9]*"/) {
    # Extract name and src
    n = split(line, parts, "\"")
    # parts: [before, name, between, src, after...]
    # Format is {"name", "src", cursor, flags}
    name = parts[2]
    src = parts[4]
    # cursor and flags are numbers at the end
    rest = line
    gsub("^\"[^\"]*\"[ \t]*,[ \t]*\"[^\"]*\"[ \t]*,[ \t]*", "", rest)
    n2 = split(rest, nums, ",")
    cursor = nums[1] + 0
    gsub(/[ \t]+/, "", cursor)
    cursor_val = cursor + 0
    printf "%s\t%s\t%s\t%s\n", name, src, nums[1]+0, nums[2]+0
  }
}
' tools/quality/lexer07-direct-differential.c > /tmp/lexer07-inputs.tsv

# Run the binary and extract OK/FAIL lines
./build/lexer07-direct-differential > /tmp/lexer07-out.txt 2>&1
awk '
/^OK/ || /^FAIL/ {
  name = $2
  kind = $0
  sub(/.*kind=/, "", kind)
  sub(/\/.*/, "", kind)
  err = $0
  sub(/.*err=/, "", err)
  sub(/\/.*/, "", err)
  slen = $0
  sub(/.*slen=/, "", slen)
  sub(/\/.*/, "", slen)
  i64 = $0
  sub(/.*i64=0x/, "", i64)
  sub(/\/0x.*/, "", i64)
  printf "%s\t%s\t%s\t%s\t%s\n", name, kind, err, slen, i64
}
' /tmp/lexer07-out.txt > /tmp/lexer07-obs.tsv

# Combine inputs and observations, compute categories
echo "name	src	cursor	flags	observed_kind	observed_err	observed_strlen	observed_i64	src_len	is_numeric	is_char	is_negative	is_edge" > "$TSV"
awk -F'\t' '
NR==FNR {
  # inputs file: name src cursor flags
  src_of[$1] = $2
  cursor_of[$1] = $3 + 0
  next
}
{
  # obs file: name kind err slen i64
  name=$1; kind=$2+0; err=$3+0; slen=$4; i64=$5
  src = src_of[name]
  cursor = cursor_of[name]
  src_len = length(src)
  is_numeric = (kind == 1 || kind == 2) ? 1 : 0
  is_char = (kind == 3) ? 1 : 0
  is_negative = (err != 0) ? 1 : 0
  is_edge = (cursor < 0 || cursor >= src_len) ? 1 : 0
  # Replace tabs in src with space
  gsub(/	/, " ", src)
  printf "%s\t%s\t%d\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\n",
    name, src, cursor, "", kind, err, slen, i64, src_len,
    is_numeric, is_char, is_negative, is_edge
}
' OFS='	' /tmp/lexer07-inputs.tsv /tmp/lexer07-obs.tsv >> "$TSV"

# Compute summary
TOTAL=$(awk -F'\t' 'NR>1' "$TSV" | wc -l | tr -d ' ')
N_NUMERIC=$(awk -F'\t' 'NR>1 && $10==1' "$TSV" | wc -l | tr -d ' ')
N_CHAR=$(awk -F'\t' 'NR>1 && $11==1' "$TSV" | wc -l | tr -d ' ')
N_NEGATIVE=$(awk -F'\t' 'NR>1 && $12==1' "$TSV" | wc -l | tr -d ' ')
N_EDGE=$(awk -F'\t' 'NR>1 && $13==1' "$TSV" | wc -l | tr -d ' ')

{
  echo "FIXTURE INVENTORY SUMMARY (mechanical)"
  echo "======================================"
  echo ""
  echo "TOTAL=$TOTAL"
  echo "is_numeric (kind==1 OR kind==2)=$N_NUMERIC"
  echo "is_char    (kind==3)=$N_CHAR"
  echo "is_negative (err != 0)=$N_NEGATIVE"
  echo "is_edge    (cursor<0 OR cursor>=src_len)=$N_EDGE"
  echo ""
  echo "Floor requirements:"
  TOTAL_OK=$([ "$TOTAL" -ge 64 ] && echo PASS || echo FAIL)
  CHAR_OK=$([ "$N_CHAR" -ge 24 ] && echo PASS || echo FAIL)
  NEG_OK=$([ "$N_NEGATIVE" -ge 16 ] && echo PASS || echo FAIL)
  echo "  TOTAL         >= 64   : $TOTAL  $TOTAL_OK"
  echo "  is_char       >= 24   : $N_CHAR  $CHAR_OK"
  echo "  is_negative   >= 16   : $N_NEGATIVE  $NEG_OK"
  echo ""

  echo "Negative fixtures (err != 0):"
  awk -F'\t' 'NR>1 && $12==1 {printf "  %-32s kind=%s err=%s\n", $1, $5, $6}' "$TSV"
  echo ""

  echo "Char fixtures (kind==3): count=$N_CHAR"
  awk -F'\t' 'NR>1 && $11==1 {printf "  %s\n", $1}' "$TSV" | head -10
  echo "  ... (showing first 10)"
  echo ""

  if [ "$TOTAL" -ge 64 ] && [ "$N_CHAR" -ge 24 ] && [ "$N_NEGATIVE" -ge 16 ]; then
    echo "FIXTURE_INVENTORY_FLOORS=PASS"
    echo "STATUS=PASS"
  else
    echo "FIXTURE_INVENTORY_FLOORS=FAIL"
    echo "STATUS=FAIL"
  fi
} > "$SUMMARY"

cat "$SUMMARY"

grep -q "STATUS=PASS" "$SUMMARY"
