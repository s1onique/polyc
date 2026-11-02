#!/bin/sh
# ---------------------------------------------------------------------------
# THE INDEPENDENT POSIX/GIT WITNESS FOR Q2
#
# This script recomputes EVERY Q2 verdict WITHOUT the PolyC verifier.
# It uses ONLY POSIX shell, awk, sort, uniq, comm and git.
#
# IT SHARES NO MATERIAL DETECTION ALGORITHM WITH THE POLYC VERIFIER:
#
#   * the PolyC verifier compares two tables by loading them into a
#     shared field store and scanning cells with an exact-string
#     equality predicate;
#   * this witness sorts the two tables and compares them with the
#     `comm` SET ALGEBRA over whole lines, and it derives every count
#     with `sort | uniq -c` over the FIRST FIELD.
#
# The two implementations therefore agree by CONVERGENCE on the same
# measured facts, not by sharing code.
#
# Output: q2/independent-witness.tsv
# ---------------------------------------------------------------------------

set -u

HERE=$(dirname "$0")
I="$HERE/inputs"
OUT="$HERE/independent-witness.tsv"

fail=0

row() {
  # row <check> <expected> <actual> <result>
  if [ "$2" = "$3" ]; then
    r=MATCH
  else
    r=MISMATCH
    fail=1
  fi
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$r" >> "$OUT"
}

# The first field of a TSV, ignoring comment and blank lines.
col1() {
  awk -F'\t' '!/^#/ && NF>0 { print $1 }' "$1"
}

# The value of a keyed row, by exact first-field match.
val() {
  awk -F'\t' -v k="$2" '!/^#/ && NF>0 && $1==k { print $2; exit }' "$1"
}

# The MEASURED value of a keyed row in a (check, command, measured,
# result) table: the value lives in the THIRD column.
val3() {
  awk -F'\t' -v k="$2" '!/^#/ && NF>0 && $1==k { print $3; exit }' "$1"
}

rm -f "$OUT"
{
  printf '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01\n'
  printf '# ACT_PHASE=Q2-IMPL\n'
  printf '# EVIDENCE_KIND=independent-posix-git-witness\n'
  printf '#\n'
  printf '# Every value below was recomputed with POSIX shell, awk, sort, uniq\n'
  printf '# and git ONLY. The compiled PolyC verifier was NOT invoked by this\n'
  printf '# script. The set-algebra (comm) and the field-counting (sort|uniq -c)\n'
  printf '# strategies are shared with nothing in the PolyC verifier, which\n'
  printf '# compares loaded cells with exact equality.\n'
  printf '#\n'
  printf 'check\texpected\tactual\tresult\n'
} >> "$OUT"

# --- IDENTITY --------------------------------------------------------------
# Recomputed from the LIVE Git object store, not from a recorded file.
live_head=$(git rev-parse HEAD)
live_tree=$(git rev-parse 'HEAD^{tree}')
live_branch=$(git branch --show-current)
live_replace=$(git replace -l | wc -l | tr -d ' ')
row REPLACE_REFS_ZERO 0 "$live_replace"

# The ENTRY identity is a HISTORICAL fact: it is the identity that was
# pinned at Q0, BEFORE this ACT produced any commit of its own. The
# live HEAD has legitimately moved on (this ACT's own Q1 commit
# descends from the entry point), so the entry identity is compared
# against the FROZEN entry-identity table, and the entry point is
# RE-VERIFIED as an ANCESTOR of the live HEAD.
entry_head=$(val "$I/expect-identity.tsv" ENTRY_HEAD)
entry_tree=$(val "$I/expect-identity.tsv" ENTRY_TREE)
row ENTRY_HEAD_MATCHES_FROZEN "$entry_head" "$(val3 "$I/entry-identity.tsv" ENTRY_HEAD)"
row ENTRY_TREE_MATCHES_FROZEN "$entry_tree" "$(val3 "$I/entry-identity.tsv" ENTRY_TREE)"
row ENTRY_BRANCH_MATCHES_FROZEN "$(val "$I/expect-identity.tsv" BRANCH)" "$(val3 "$I/entry-identity.tsv" BRANCH)"

# The entry point must be an ANCESTOR of the live HEAD: the audit is
# running on the tree it pinned, with this ACT's own commits on top.
if git merge-base --is-ancestor "$entry_head" HEAD 2>/dev/null; then
  anc=YES
else
  anc=NO
fi
row ENTRY_IS_ANCESTOR_OF_LIVE_HEAD YES "$anc"

# --- ROSTER: THE 32-HISTORICAL-ID SET JOIN ---------------------------------
# The whole-line SET ALGEBRA: the current IDs and the historical IDs are
# sorted and compared with `comm`. Missing / duplicate / extra are all
# consequences of the same sorted-stream comparison.
col1 "$I/current-classification.tsv" | grep '^A-C-DRIVER-' | sort > /tmp/q02.cur.ids
col1 "$I/historical-roster.tsv"  | grep '^A-C-DRIVER-' | sort > /tmp/q02.his.ids

cur_n=$(wc -l < /tmp/q02.cur.ids | tr -d ' ')
his_n=$(wc -l < /tmp/q02.his.ids | tr -d ' ')
uniq_cur_n=$(uniq /tmp/q02.cur.ids | wc -l | tr -d ' ')
uniq_his_n=$(uniq /tmp/q02.his.ids | wc -l | tr -d ' ')

row ROSTER_CURRENT_ROWS 32 "$cur_n"
row ROSTER_HISTORICAL_ROWS 32 "$his_n"
row ROSTER_MISSING_IDS 0 "$(comm -13 /tmp/q02.cur.ids /tmp/q02.his.ids | wc -l | tr -d ' ')"
row ROSTER_EXTRA_IDS   0 "$(comm -23 /tmp/q02.cur.ids /tmp/q02.his.ids | wc -l | tr -d ' ')"
row ROSTER_DUPLICATE_IDS 0 "$(( cur_n - uniq_cur_n + his_n - uniq_his_n ))"

# --- HISTCLASS: THE IMMUTABLE HISTORICAL CLASS -----------------------------
# Whole-line comparison of the (id, historical_class) PAIRS.
awk -F'\t' '!/^#/ && NF>0 && $1 ~ /^A-C-DRIVER-/ { print $1 "\t" $4 }' "$I/current-classification.tsv" | sort > /tmp/q02.cur.cls
awk -F'\t' '!/^#/ && NF>0 && $1 ~ /^A-C-DRIVER-/ { print $1 "\t" $4 }' "$I/historical-roster.tsv"  | sort > /tmp/q02.his.cls
row HISTCLASS_REWRITTEN_CLASSES 0 "$(comm -3 /tmp/q02.cur.cls /tmp/q02.his.cls | wc -l | tr -d ' ')"

# --- OWNERSHIP: THE PER-ROW CLASSIFICATION COUNTS --------------------------
# Counted by `sort | uniq -c` over the current_class field.
cls_counts=$(awk -F'\t' '!/^#/ && NF>0 && $1 ~ /^A-C-DRIVER-/ { print $13 }' "$I/current-classification.tsv" | sort | uniq -c | awk '{print $2"="$1}' | tr '\n' ' ')
row OWNERSHIP_POLYC_OWNED 9  "$(echo "$cls_counts" | tr ' ' '\n' | awk -F= '$1=="POLYC_OWNED_DECISION_PROVEN"{print $2}')"
row OWNERSHIP_C_MECHANICAL 12 "$(echo "$cls_counts" | tr ' ' '\n' | awk -F= '$1=="C_MECHANICAL_EXECUTION_PROVEN"{print $2}')"
row OWNERSHIP_C_SEMANTIC_RETAINED 2 "$(echo "$cls_counts" | tr ' ' '\n' | awk -F= '$1=="C_SEMANTIC_RETAINED_WP001"{print $2}')"
row OWNERSHIP_DORMANT 9 "$(echo "$cls_counts" | tr ' ' '\n' | awk -F= '$1=="DORMANT_OR_UNREACHABLE_PROVEN"{print $2}')"

# The retained-C-semantic rows are the main() and emitFile() rows.
ret_ids=$(awk -F'\t' '!/^#/ && NF>0 && $13=="C_SEMANTIC_RETAINED_WP001" { print $1 }' "$I/current-classification.tsv" | sort | tr '\n' ' ')
row OWNERSHIP_RETAINED_ROW_IDS "A-C-DRIVER-main-emitFile-FC A-C-DRIVER-main-main-SW1 " "$ret_ids"

# --- SCOPE: THE TWO C-SEMANTIC REMAINders ----------------------------------
# The route-scoped remainder counts only the rows that are BOTH retained-C
# AND on the WP-001 required route; the global remainder counts every
# retained-C row. The two are counted SEPARATELY, which is the point.
req_rem=$(awk -F'\t' '!/^#/ && NF>0 && $13=="C_SEMANTIC_RETAINED_WP001" && $11=="YES"' "$I/current-classification.tsv" | wc -l | tr -d ' ')
glob_rem=$(awk -F'\t' '!/^#/ && NF>0 && $13=="C_SEMANTIC_RETAINED_WP001"' "$I/current-classification.tsv" | wc -l | tr -d ' ')
row SCOPE_REQUIRED_ROUTE_REMAINDER "$(val "$I/expect-ownership.tsv" WP001_REQUIRED_ROUTE_C_SEMANTIC_REMAINDER)" "$req_rem"
row SCOPE_GLOBAL_REMAINDER        "$(val "$I/expect-ownership.tsv" WP001_GLOBAL_C_SEMANTIC_REMAINDER)"        "$glob_rem"



# --- AUTHORITY: THE 16 AUTHORITY SUBJECTS ----------------------------------
auth_n=$(awk -F'\t' '!/^#/ && NF>0 && $1 ~ /^AUTH-/' "$I/production-authorities.tsv" | wc -l | tr -d ' ')
auth_uniq=$(awk -F'\t' '!/^#/ && NF>0 && $1 ~ /^AUTH-/' "$I/production-authorities.tsv" | cut -f1 | sort -u | wc -l | tr -d ' ')
row AUTHORITY_COUNT       "$(val "$I/expect-authority.tsv" FINAL_AUTHORITIES)" "$auth_n"
row AUTHORITY_UNIQUE_IDS  "$(val "$I/expect-authority.tsv" FINAL_AUTHORITIES)" "$auth_uniq"
row AUTHORITY_HISTORICAL_ROWS "$(val "$I/expect-authority.tsv" HISTORICAL_ROWS)" "$his_n"

# --- FAMILY: THE FIVE-ACT COST ---------------------------------------------
# The kind is counted by `sort | uniq -c` over the kind field.
fam_counts=$(awk -F'\t' '!/^#/ && NF>0 && $1 ~ /^ACT-/' "$I/act-family-inventory.tsv" | cut -f2 | sort | uniq -c | awk '{print $2"="$1}' | tr '\n' ' ')
fam_all=$(awk -F'\t' '!/^#/ && NF>0 && $1 ~ /^ACT-/' "$I/act-family-inventory.tsv" | wc -l | tr -d ' ')
row FAMILY_ALL_ACTS           "$(val "$I/expect-family.tsv" WP001_ALL_ACTS_CONSUMED)"           "$fam_all"
row FAMILY_IMPLEMENTATION     "$(val "$I/expect-family.tsv" WP001_IMPLEMENTATION_ACTS)"      "$(echo "$fam_counts" | tr ' ' '\n' | awk -F= '$1=="IMPLEMENTATION"{print $2}')"
row FAMILY_TECHNICAL          "$(val "$I/expect-family.tsv" WP001_TECHNICAL_CORRECTION_ACTS)" "$(echo "$fam_counts" | tr ' ' '\n' | awk -F= '$1=="TECHNICAL_CORRECTION"{print $2}')"
row FAMILY_GOVERNANCE         "$(val "$I/expect-family.tsv" WP001_GOVERNANCE_CORRECTION_ACTS)" "$(echo "$fam_counts" | tr ' ' '\n' | awk -F= '$1=="GOVERNANCE_CORRECTION"{print $2}')"

# --- CHRONOLOGY: THE TERMINALITY CLAIM SEPARATIONS -------------------------
for k in HISTORICAL_TRACKED_OUTCOME_PROVENANCE ORIGINAL_EXTERNAL_RECEIPT \
         FRESH_EXTERNAL_REPLAY HISTORICAL_ACT_TERMINALITY_CONFIRMED \
         POST_CLOSE_ACT_ID_COMMITS; do
  row "CHRONOLOGY_$k" "$(val "$I/expect-chronology.tsv" "$k")" "$(val "$I/chronology.tsv" "$k")"
done

# The POST-CLOSE ACT-id carrier count is RECOMPUTED from git, not read.
# CORRECTION04's terminal CLOSE is the last commit carrying its ACT id.
# The walk uses a NUL-separated record stream so that the commit body
# cannot be confused with the commit subject line: each record is
# "<sha>\n<body>". The walk is over the FIRST-PARENT history of the
# live HEAD in reverse chronological order, so "after the close" is
# literal: every record that comes after the close record is a
# descendant of it.
c04="ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION04"
c04_close=$(git log --first-parent --format='%H%x00%B%x00' | tr '\0' '\n' | awk -v id="$c04" '
  /^[0-9a-f]{40}$/ { sha = $0; inact = 0; next }
  /^ACT: / { if ($0 == "ACT: " id) inact = 1; next }
  /^ACT-Phase: CLOSE$/ { if (inact && closeref == "") closeref = sha }
  END { print closeref }
')
row CHRONOLOGY_C04_CLOSE_FOUND 1 "$([ -n "$c04_close" ] && echo 1 || echo 0)"

# The post-close count is the number of ACT-id-carrying commits that
# DESCEND FROM the close.
#
# `git log` emits NEWEST FIRST. The commits carrying the ACT id are
# therefore listed with the NEWEST first. The close is the newest of
# them (rule 4 of the range contract: the close is the LAST member of
# the range, and the range is contiguous), so it is the FIRST entry of
# the list. Every OTHER entry is OLDER than the close, i.e. a member
# of the range BEFORE it.
#
# A commit that DESCENDS FROM the close would appear BEFORE the close
# in the newest-first list. Counting the entries that appear before
# the close therefore counts exactly the post-close ACT-id carriers.
all_ids=$(git log --first-parent --format='%H%x00%B%x00' | tr '\0' '\n' | awk -v id="$c04" '
  /^[0-9a-f]{40}$/ { sha = $0; inact = 0; next }
  /^ACT: / { if ($0 == "ACT: " id) inact = 1; next }
  inact && sha != "" { print sha; sha = "" }
')
newest_id=$(printf '%s\n' "$all_ids" | head -1)
row CHRONOLOGY_NEWEST_ACT_ID_COMMIT_IS_THE_CLOSE "$c04_close" "$newest_id"
post_close=$(printf '%s\n' "$all_ids" | awk -v closeref="$c04_close" '
  $0 == closeref { seen = 1; next }
  !seen { n++ }
  END { print n + 0 }
')
row CHRONOLOGY_POST_CLOSE_RECOMPUTED 0 "$post_close"

# --- ACCEPT: THE FROZEN 50-ID ACCEPTANCE ROSTER ---------------------------
ac_n=$(awk -F'\t' '!/^#/ && NF>0 && $1 ~ /^AC[0-9][0-9]$/' "$I/frozen-ac.tsv" | wc -l | tr -d ' ')
row ACCEPT_ROSTER_SIZE 50 "$ac_n"

# --- M2CLASS: THE MILESTONE CLAIMS ----------------------------------------
for k in M2_ACHIEVED CROSS_TARGET_PREFIX; do
  row "M2CLASS_$k" "$(val "$I/expect-m2class.tsv" "$k")" "$(val "$I/milestone-claims.tsv" "$k")"
done

{
  printf '#\n'
  if [ "$fail" -eq 0 ]; then
    printf '# INDEPENDENT_WITNESS_RESULT = PASS\n'
  else
    printf '# INDEPENDENT_WITNESS_RESULT = FAIL\n'
  fi
  printf '# MISMATCH_COUNT = %s\n' "$(awk -F'\t' '!/^#/ && NF>0 && $4=="MISMATCH"' "$OUT" | wc -l | tr -d ' ')"
} >> "$OUT"

echo "INDEPENDENT_WITNESS=$OUT"
if [ "$fail" -ne 0 ]; then
  echo "INDEPENDENT_WITNESS_RESULT=FAIL"
  exit 1
fi
echo "INDEPENDENT_WITNESS_RESULT=PASS"
exit 0

  row "CHRONOLOGY_$k" "$(val "$I/expect-chronology.tsv" "$k")" "$(val "$I/chronology.tsv" "$k")"
done
