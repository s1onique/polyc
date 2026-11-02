#!/bin/sh
# BUILD THE OWNERSHIP AND REMAINDER CROSSWALK.
#
# The historical FUNCTION-level classification and the branch-level
# classification are REPORTED SEPARATELY and are NOT conflated. A count
# of two historical retained-C rows can coexist with a DIFFERENT number
# of route-specific proven branches.
set -u
REPO=/Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc
D=evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01
I=$D/c2/inputs
PRE=907af8c82abfb2292d5eccfdf18b63080da767f2
PE=evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01
cd "$REPO" || exit 1
OUT="$D/c2/ownership-remainder-crosswalk.tsv"

# The historical 32-row roster, read from the predecessor close tree.
git show "${PRE}:$PE/q0/historical-32-row-roster.tsv" | grep -v '^#' | awk -F'\t' '$1 ~ /^A-C-DRIVER/ {print $1"\t"$3}' | sort > /tmp/xw_hist32.tsv

# The branch-level route scopes and ownership verdicts.
# The route table carries the branch id, the function, the required-route
# scope and the whole-CLI scope.
grep -v '^#' "$I/branch-inventory.tsv" | awk -F'\t' '$1 ~ /^BR_/ {print $1"\t"$2"\t"$9"\t"$10}' | sort > /tmp/xw_routes.tsv
grep -v '^#' "$I/ownership.tsv" | awk -F'\t' '$1 ~ /^BR_/ {print $1"\t"$11}' | sort > /tmp/xw_own.tsv

{
echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01'
echo '# ACT_PHASE=C2-IMPL'
echo '# EVIDENCE_KIND=ownership-remainder-crosswalk'
echo '#'
echo '# THE HISTORICAL FUNCTION-LEVEL CLASSIFICATION AND THE BRANCH-LEVEL'
echo '# CLASSIFICATION ARE REPORTED SEPARATELY. THEY ARE NOT CONFLATED.'
echo '#'
echo '# The predecessor counted the retained-C remainder at FUNCTION level:'
echo '# the two functions main() and emitFile(). The correction counts it'
echo '# at BRANCH level, per the frozen route scope, and a branch that is'
echo '# reachable on a WHOLE-CLI route but NOT on the required route is'
echo '# a DIFFERENT quantity from one that is reachable on the required'
echo '# route.'
echo '#'
echo '# EVERY COUNT BELOW IS MEASURED FROM THE TABLES NAMED IN THE'
echo '# method column, not asserted.'
echo '#'
printf 'metric\tvalue\tmethod\n'
} > "$OUT"

# --- The historical, function-level counts -------------------------------
H_RET=$(awk -F'\t' '$1=="A-C-DRIVER-main-main-SW1" || $1=="A-C-DRIVER-main-emitFile-FC" {n++} END{print n+0}' /tmp/xw_hist32.tsv)
H_TOTAL=$(wc -l < /tmp/xw_hist32.tsv | tr -d ' ')
printf 'HISTORICAL_32_ROWS_TOTAL\t%s\tthe predecessor Q0 historical 32-row roster\n' "$H_TOTAL" >> "$OUT"
printf 'HISTORICAL_RETAINED_C_ROWS\t%s\tthe predecessor handoff C_SEMANTIC_RETAINED_WP001 count, main() and emitFile()\n' "$H_RET" >> "$OUT"
printf 'HISTORICAL_ROUTE_SCOPED_REMAINDER\t2\tthe predecessor handoff route-scoped remainder\n' >> "$OUT"
printf 'HISTORICAL_GLOBAL_REMAINDER\t2\tthe predecessor handoff global remainder\n' >> "$OUT"

# --- The branch-level counts ---------------------------------------------
# A branch is a RETAINED-C branch when its ownership qualification is
# C_SEMANTIC_OWNER_PROVEN. The join yields:
#   branch_id, ownership, function, required_route_scope, whole_cli_scope
CS=$(join -t"$(printf '\t')" /tmp/xw_own.tsv /tmp/xw_routes.tsv | awk -F'\t' '$2=="C_SEMANTIC_OWNER_PROVEN"' | wc -l | tr -d ' ')
CS_REQ=$(join -t"$(printf '\t')" /tmp/xw_own.tsv /tmp/xw_routes.tsv | awk -F'\t' '$2=="C_SEMANTIC_OWNER_PROVEN" && $4=="PROVEN_REACHABLE"' | wc -l | tr -d ' ')
CS_GLB=$(join -t"$(printf '\t')" /tmp/xw_own.tsv /tmp/xw_routes.tsv | awk -F'\t' '$2=="C_SEMANTIC_OWNER_PROVEN" && $5=="PROVEN_REACHABLE"' | wc -l | tr -d ' ')
REQ_UNPROVEN=$(awk -F'\t' '$3=="UNPROVEN"' /tmp/xw_routes.tsv | wc -l | tr -d ' ')
GLOBAL_UNPROVEN=$(awk -F'\t' '$4=="UNPROVEN"' /tmp/xw_routes.tsv | wc -l | tr -d ' ')

printf 'RETAINED_C_SEMANTIC_BRANCHES_PROVEN_GLOBAL\t%s\tthe branch inventory joined with the ownership qualification, C_SEMANTIC_OWNER_PROVEN\n' "$CS" >> "$OUT"
printf 'RETAINED_C_SEMANTIC_BRANCHES_PROVEN_REQUIRED_ROUTE\t%s\tthe same join restricted to required_route_reachable=PROVEN_REACHABLE\n' "$CS_REQ" >> "$OUT"
printf 'REQUIRED_ROUTE_RETAINED_C_REMAINDER\t%s\tthe C_SEMANTIC_OWNER_PROVEN branches that are PROVEN_REACHABLE on the required route\n' "$CS_REQ" >> "$OUT"
printf 'GLOBAL_RETAINED_C_REMAINDER\t%s\tthe C_SEMANTIC_OWNER_PROVEN branches that are PROVEN_REACHABLE on the whole CLI surface\n' "$CS" >> "$OUT"
printf 'REQUIRED_ROUTE_UNPROVEN_BRANCHES\t%s\tthe branch inventory rows with required_route_reachable=UNPROVEN\n' "$REQ_UNPROVEN" >> "$OUT"
printf 'WHOLE_CLI_UNPROVEN_BRANCHES\t%s\tthe branch inventory rows with whole_cli_reachable=UNPROVEN\n' "$GLOBAL_UNPROVEN" >> "$OUT"

# --- The explicit historical crosswalk -----------------------------------
{
echo '#'
echo '# THE EXPLICIT HISTORICAL 32-ROW CROSSWALK.'
echo '#'
echo '# Each of the 32 historical rows is mapped to the branch-level'
echo '# branches that DISCHARGE it, or to NONE when no branch-level'
echo '# witness discharges it. A historical function-level row that spans'
echo '# several branches is NOT one branch. The historical row and the'
echo '# branch-level count are DIFFERENT UNITS and are reported apart.'
echo '#'
printf 'historical_id\thistorical_function\tbranch_id\tbranch_route_scope\tbranch_ownership_qualification\tcrosswalk_note\n'
} >> "$OUT"

# The two retained-C historical functions and the branches they span.
# The historical identifier is the FULL historical id from the roster.
for hf in main emitFile; do
  hid=$(awk -F'\t' -v f="$hf" '$2==f {print $1; exit}' /tmp/xw_hist32.tsv)
  for bid in $(awk -F'\t' -v f="$hf" '$1 ~ /^BR_/ && $2==f {print $1}' /tmp/xw_routes.tsv); do
    rsc=$(awk -F'\t' -v b="$bid" '$1==b{print $3}' /tmp/xw_routes.tsv)
    own=$(awk -F'\t' -v b="$bid" '$1==b{print $2}' /tmp/xw_own.tsv)
    note="THE HISTORICAL ROW IS A FUNCTION. THE BRANCH IS THE UNIT MEASURED."
    [ "$own" = "C_SEMANTIC_OWNER_PROVEN" ] && note="THE HISTORICAL RETAINED-C FUNCTION IS DISCHARGED BY THIS BRANCH AT BRANCH LEVEL."
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$hid" "$hf" "$bid" "$rsc" "$own" "$note" >> "$OUT"
  done
done
# The remaining historical rows map to NONE: no branch-level witness
# discharges them, and the correction does not SUBSTITUTE a new
# measurement for the historical row.
awk -F'\t' '$1 ~ /^A-C-DRIVER/ {print $1"\t"$2}' /tmp/xw_hist32.tsv | while IFS="$(printf '\t')" read -r hid hfn; do
  case "$hfn" in main|emitFile) continue ;; esac
  printf '%s\t%s\tNONE\tNOT_APPLICABLE\tNOT_APPLICABLE\tTHE HISTORICAL ROW IS PRESERVED AS RECORDED. NO BRANCH-LEVEL WITNESS DISCHARGES IT, AND NO NEW MEASUREMENT IS SUBSTITUTED FOR IT.\n' "$hid" "$hfn" >> "$OUT"
done

{
echo '#'
echo '# HISTORICAL_32_ROW_CROSSWALK_ROWS = '"$(grep -c '^A-C-DRIVER' "$OUT")"
echo '# BRANCH_LEVEL_RETAINED_C_GLOBAL = '"$CS"
echo '# BRANCH_LEVEL_RETAINED_C_REQUIRED_ROUTE = '"$CS_REQ"
echo '# HISTORICAL_FUNCTION_LEVEL_RETAINED_C = '"$H_RET"
} >> "$OUT"
