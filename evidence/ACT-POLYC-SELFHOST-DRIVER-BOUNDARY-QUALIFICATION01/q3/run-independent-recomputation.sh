#!/bin/sh
# ---------------------------------------------------------------------------
# THE Q3 INDEPENDENT RECOMPUTATION
#
# The Q3 acceptance criterion AC43 requires that the INDEPENDENT
# recomputation agrees on ownership, identity and chronology. This
# script performs that recomputation with POSIX shell, awk, sort, uniq
# and git ONLY, and compares the result with the COMPILED PolyC
# verifier's verdicts.
#
# The two implementations share no detection algorithm:
#
#   POLYC VERIFIER  load each table into a shared field store and scan
#                   cells with an exact-string equality predicate
#   INDEPENDENT     sort whole lines and compare them with the `comm`
#                   SET ALGEBRA; count with `sort | uniq -c`
#
# Output: q3/independent-recomputation.tsv
# ---------------------------------------------------------------------------

set -u

HERE=$(dirname "$0")
ROOT=$(cd "$HERE/../../.." && pwd)
EV="$ROOT/evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01"
Q0="$EV/q0"
Q2="$EV/q2"
I="$Q2/inputs"
V="$ROOT/build/driver-boundary-qualification01-verify"
OUT="$HERE/independent-recomputation.tsv"
TMP=$(mktemp -d /tmp/q03-recomp.XXXXXX)
trap 'rm -rf "$TMP"' EXIT INT TERM

cd "$ROOT" || exit 1

pass=0
fail=0

row() {
  # row <fact> <independent_verdict> <verifier_verdict>
  #
  # The two implementations must reach the SAME VERDICT about the same
  # measured fact. The independent side's verdict is SILENT when its
  # own recomputation found the fact CONSISTENT and REJECTED when it
  # found a DEFECT; the verifier's verdict is the same two-valued
  # answer. Comparing the two VERDICTS is the meaningful comparison:
  # comparing an independent COUNT against a verdict would never be
  # equal and would prove nothing.
  if [ "$2" = "$3" ]; then
    r=AGREE
    pass=$((pass+1))
  else
    r=DISAGREE
    fail=$((fail+1))
  fi
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$r" >> "$OUT"
}

# The verifier's verdict for a mode: SILENT when it accepted the
# measured facts, REJECTED when it rejected them.
verdict() {
  "$V" "$1" "$2" "$3" >/dev/null 2>&1
  if [ $? -eq 0 ]; then echo SILENT; else echo REJECTED; fi
}

col1() {
  awk -F'\t' '!/^#/ && NF>0 { print $1 }' "$1"
}

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01'
  echo '# ACT_PHASE=Q3-EVIDENCE'
  echo '# EVIDENCE_KIND=independent-recomputation'
  echo '#'
  echo '# The INDEPENDENT recomputation of ownership, identity and'
  echo '# chronology, compared with the COMPILED PolyC verifier'"'"'s'
  echo '# verdicts on the SAME measured inputs.'
  echo '#'
  echo '# The two implementations share NO detection algorithm: the'
  echo '# verifier scans loaded cells with exact equality; this script'
  echo '# sorts whole lines and compares them with the `comm` set'
  echo '# algebra and counts with `sort | uniq -c`.'
  echo '#'
  echo 'fact	independent_value	verifier_verdict	result'
} > "$OUT"

# --- OWNERSHIP --------------------------------------------------------------
# The per-row classification counts, by `sort | uniq -c` over the
# current_class field. The independent side is REJECTED when its own
# count differs from the FROZEN expectation.
cls=$(awk -F'\t' '!/^#/ && NF>0 && $1 ~ /^A-C-DRIVER-/ { print $13 }' "$I/current-classification.tsv" | sort | uniq -c | awk '{print $2"="$1}' | tr '\n' ' ')
for pair in POLYC_OWNED_DECISION_PROVEN:9 C_MECHANICAL_EXECUTION_PROVEN:12 C_SEMANTIC_RETAINED_WP001:2 DORMANT_OR_UNREACHABLE_PROVEN:9; do
  k="${pair%%:*}"; want="${pair##*:}"
  n=$(echo "$cls" | tr ' ' '\n' | awk -F= -v kk="$k" '$1==kk{print $2}')
  if [ "${n:-0}" = "$want" ]; then iv=SILENT; else iv=REJECTED; fi
  row "OWNERSHIP_$k" "$iv" "$(verdict OWNERSHIP "$I/current-classification.tsv" "$I/expect-ownership.tsv")"
done

# The ROUTE-SCOPED and GLOBAL remainders are counted SEPARATELY, each
# against its own frozen expectation.
req=$(awk -F'\t' '!/^#/ && NF>0 && $13=="C_SEMANTIC_RETAINED_WP001" && $11=="YES"' "$I/current-classification.tsv" | wc -l | tr -d ' ')
glob=$(awk -F'\t' '!/^#/ && NF>0 && $13=="C_SEMANTIC_RETAINED_WP001"' "$I/current-classification.tsv" | wc -l | tr -d ' ')
want_req=$(awk -F'\t' '!/^#/ && $1=="WP001_REQUIRED_ROUTE_C_SEMANTIC_REMAINDER" { print $2; exit }' "$I/expect-ownership.tsv")
want_glob=$(awk -F'\t' '!/^#/ && $1=="WP001_GLOBAL_C_SEMANTIC_REMAINDER" { print $2; exit }' "$I/expect-ownership.tsv")
[ "$req" = "$want_req" ] && iv=SILENT || iv=REJECTED
row SCOPE_REQUIRED_ROUTE_REMAINDER "$iv" "$(verdict SCOPE "$I/current-classification.tsv" "$I/expect-ownership.tsv")"
[ "$glob" = "$want_glob" ] && iv=SILENT || iv=REJECTED
row SCOPE_GLOBAL_REMAINDER "$iv" "$(verdict SCOPE "$I/current-classification.tsv" "$I/expect-ownership.tsv")"

# --- IDENTITY ---------------------------------------------------------------
# The entry point must be an ancestor of the live HEAD, and the frozen
# entry identity must match the frozen expectation.
eh=$(awk -F'\t' '!/^#/ && NF>0 && $1=="ENTRY_HEAD" { print $3; exit }' "$I/entry-identity.tsv")
if git merge-base --is-ancestor "$eh" HEAD 2>/dev/null; then anc=YES; else anc=NO; fi
want_h=$(awk -F'\t' '!/^#/ && $1=="ENTRY_HEAD" { print $2; exit }' "$I/expect-identity.tsv")
[ "$anc" = "YES" ] && [ "$eh" = "$want_h" ] && iv=SILENT || iv=REJECTED
row IDENTITY_ENTRY_IS_ANCESTOR "$iv" "$(verdict IDENTITY "$I/entry-identity.tsv" "$I/expect-identity.tsv")"

# --- ROSTER -----------------------------------------------------------------
col1 "$I/current-classification.tsv" | grep '^A-C-DRIVER-' | sort > "$TMP/c.ids"
col1 "$I/historical-roster.tsv"  | grep '^A-C-DRIVER-' | sort > "$TMP/h.ids"
miss=$(comm -13 "$TMP/c.ids" "$TMP/h.ids" | wc -l | tr -d ' ')
extra=$(comm -23 "$TMP/c.ids" "$TMP/h.ids" | wc -l | tr -d ' ')
[ "$miss" -eq 0 ] && [ "$extra" -eq 0 ] && iv=SILENT || iv=REJECTED
row ROSTER_JOIN "$iv" "$(verdict ROSTER "$I/current-classification.tsv" "$I/historical-roster.tsv")"

# --- CHRONOLOGY -------------------------------------------------------------
# The CORRECTION04 close and the parent's duplicate-close count are
# RECOMPUTED from git and compared with the frozen expectations.
c04="ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04"
parent="ACT-POLYC-SELFHOST-DRIVER-MIGRATION01"
c04_close=$(git log --first-parent --format='%H%x00%B%x00' | tr '\0' '\n' | awk -v id="$c04" '
  /^[0-9a-f]{40}$/ { sha = $0; inact = 0; next }
  /^ACT: / { if ($0 == "ACT: " id) inact = 1; next }
  /^ACT-Phase: CLOSE$/ { if (inact && c == "") c = sha }
  END { print c }
')
parent_closes=$(git log --first-parent --format='%H%x00%B%x00' | tr '\0' '\n' | awk -v id="$parent" '
  /^[0-9a-f]{40}$/ { sha = $0; inact = 0; next }
  /^ACT: / { if ($0 == "ACT: " id) inact = 1; next }
  /^ACT-Phase: CLOSE$/ { if (inact) n++ }
  END { print n + 0 }
')
want_close=$(awk -F'\t' '!/^#/ && $1=="CORRECTION04_TERMINAL_CLOSE" { print $2; exit }' "$I/expect-chronology.tsv")
want_dup=$(awk -F'\t' '!/^#/ && $1=="HISTORICAL_DUPLICATE_CLOSES" { print $2; exit }' "$I/expect-chronology.tsv")
[ "$c04_close" = "$want_close" ] && iv=SILENT || iv=REJECTED
row CHRONOLOGY_C04_TERMINAL_CLOSE "$iv" "$(verdict CHRONOLOGY "$I/chronology.tsv" "$I/expect-chronology.tsv")"
[ "$parent_closes" = "$want_dup" ] && iv=SILENT || iv=REJECTED
row CHRONOLOGY_HISTORICAL_DUPLICATE_CLOSES "$iv" "$(verdict CHRONOLOGY "$I/chronology.tsv" "$I/expect-chronology.tsv")"

{
  echo '#'
  echo "# INDEPENDENT_RECOMPUTATION_AGREEMENTS = $pass"
  echo "# INDEPENDENT_RECOMPUTATION_DISAGREEMENTS = $fail"
} >> "$OUT"

echo "INDEPENDENT_RECOMPUTATION=$OUT"
echo "AGREEMENTS=$pass"
echo "DISAGREEMENTS=$fail"
if [ "$fail" -ne 0 ]; then
  exit 1
fi
exit 0
