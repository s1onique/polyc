#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01/q0/run-reds-independent-witness.sh
#
# ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01 Q0 RED.
#
# THE INDEPENDENT POSIX/GIT WITNESS.
#
# It re-derives the SAME five facts by a DIFFERENT algorithm and a
# DIFFERENT data path:
#
#   * the compiled PolyC detector counts LINES of a table that contain a
#     needle; this witness uses awk FIELD matching over the same table.
#   * the compiled PolyC detector reads a claim file into key/value
#     pairs; this witness reads the SAME claim file with grep -v.
#   * the compiled PolyC detector counts the action-selection symbols
#     with four separate substring tests; this witness counts them with
#     ONE awk regular expression over the whole symbol column.
#
# It shares NO detection algorithm with the PolyC detector. It is a
# cross-check, not a copy.
#
# It writes its own result table and the two are compared by an
# independent diff.

set -u

EV="evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01/q0"
I="$EV/red-inputs"
C="$EV/red-claims"
OUT="$EV/five-red-independent-witness.tsv"

claim() { grep -v '^#' "$1" | awk -F'\t' -v k="$2" '$1==k {print $2; exit}'; }

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01'
  echo '# ACT_PHASE=Q0-RED'
  echo '# EVIDENCE_KIND=five-red-independent-witness'
  echo '#'
  echo '# An independent POSIX/Git cross-check of the five REDs. It uses'
  echo '# awk field matching and ONE regular expression, where the'
  echo '# compiled PolyC detector uses line-substring counting and four'
  echo '# separate substring tests. It shares no detection algorithm.'
  echo '#'
  printf 'red_id\texpected_reason\tindependent_verdict\treason\n'

  # R01 -- relocation is not decision proof.
  _rel=$(awk -F'\t' 'NF>=2 && $2 ~ /^_WpDriver/ {n++} END {print n+0}' "$I/driver-relocations.tsv")
  _act=$(awk -F'\t' 'NF>=2 && $2 ~ /^_WpDriver(SelectAction|SelectedAction|OptionAction|MapStatus)$/ {n++} END {print n+0}' "$I/driver-relocations.tsv")
  _c_rel=$(claim "$C/r01-adverse.tsv" RELOC_COUNT)
  _c_act=$(claim "$C/r01-adverse.tsv" ACTION_RELOC_COUNT)
  _c_proves=$(claim "$C/r01-adverse.tsv" PROVES_NO_C_DECISION)
  if [ "$_c_proves" = "1" ] && [ "$_c_act" != "$_act" ]; then
    printf 'R01\tRELOCATION_IS_NOT_DECISION_PROOF\tFIRED\tclaimed %s action-selection relocations, measured %s (of %s total)\n' "$_c_act" "$_act" "$_rel"
  elif [ "$_c_proves" = "1" ] && [ "$_act" = "0" ]; then
    printf 'R01\tRELOCATION_IS_NOT_DECISION_PROOF\tFIRED\tno action-selection relocation exists among the %s measured relocations\n' "$_rel"
  else
    printf 'R01\tRELOCATION_IS_NOT_DECISION_PROOF\tSILENT\tno adverse condition\n'
  fi

  # R02 -- the boundary is not causally proven.
  _notlinked=$(awk -F'\t' 'NR>1 && $3!="1" {n++} END {print n+0}' "$I/branch-counterfactuals-adverse.tsv")
  _nodiff=$(awk -F'\t' 'NR>1 && $4!="1" {n++} END {print n+0}' "$I/branch-counterfactuals-adverse.tsv")
  _c_causal=$(claim "$C/r02-adverse.tsv" CAUSAL_CLAIMED)
  if [ "$_c_causal" = "1" ] && [ "$_notlinked" -gt 0 ]; then
    printf 'R02\tDRIVER_BOUNDARY_NOT_CAUSALLY_PROVEN\tFIRED\t%s branch(es) mutated without a linked proof\n' "$_notlinked"
  elif [ "$_c_causal" = "1" ] && [ "$_nodiff" -gt 0 ]; then
    printf 'R02\tDRIVER_BOUNDARY_NOT_CAUSALLY_PROVEN\tFIRED\t%s branch(es) linked without an observed difference\n' "$_nodiff"
  else
    printf 'R02\tDRIVER_BOUNDARY_NOT_CAUSALLY_PROVEN\tSILENT\tno adverse condition\n'
  fi

  # R03 -- a precommitted terminality result is not a post-CLOSE receipt.
  _outcome=$(awk -F'\t' '$1=="PROBE_RESULT" && $2=="PASS" {n++} $1=="EXTERNAL_TERMINALITY" && $2=="PASS" {n++} $1=="AC50" && $2=="PASS" {n++} END {print n+0}' "$I/tracked-terminality-outcome.tsv")
  _intree=$(grep -c 'terminality-outcome.tsv' "$I/close-tree-paths.txt")
  _c_receipt=$(claim "$C/r03-adverse.tsv" CLAIMS_EXTERNAL_RECEIPT)
  if [ "$_c_receipt" = "1" ] && [ "$_outcome" -gt 0 ] && [ "$_intree" -gt 0 ]; then
    printf 'R03\tPRECOMMITTED_TERMINALITY_RESULT\tFIRED\t%d terminal PASS assertion(s) in a file already present in the CLOSE tree\n' "$_outcome"
  else
    printf 'R03\tPRECOMMITTED_TERMINALITY_RESULT\tSILENT\tno adverse condition\n'
  fi

  # R04 -- the correction family must not be omitted.
  _acts=$(awk -F'\t' 'NR>1 && $1 ~ /^ACT-POLYC-SELFHOST-DRIVER-MIGRATION01/ {n++} END {print n+0}' "$I/act-family-inventory.tsv")
  _c_acts=$(claim "$C/r04-adverse.tsv" FAMILY_ACT_COUNT)
  if [ "$_c_acts" != "$_acts" ]; then
    printf 'R04\tWP001_CORRECTION_FAMILY_OMITTED\tFIRED\tclaimed %s ACT(s), measured %s\n' "$_c_acts" "$_acts"
  else
    printf 'R04\tWP001_CORRECTION_FAMILY_OMITTED\tSILENT\tno adverse condition\n'
  fi

  # R05 -- no authority overclaim, no M2 overclaim.
  _live=$(awk -F'\t' 'NR>1 && $3+0 >= 1 {n++} END {print n+0}' "$I/production-authorities.tsv")
  _c_auth=$(claim "$C/r05-adverse.tsv" CLAIMED_AUTHORITIES)
  _c_m2=$(claim "$C/r05-adverse.tsv" CLAIMED_M2)
  _c_rows=$(claim "$C/r05-adverse.tsv" HISTORICAL_ROWS)
  if [ "$_c_auth" != "$_live" ]; then
    printf 'R05\tWP001_AUTHORITY_OR_M2_OVERCLAIM\tFIRED\tclaimed %s authorities, measured %s live\n' "$_c_auth" "$_live"
  elif [ "$_c_m2" = "1" ]; then
    printf 'R05\tWP001_AUTHORITY_OR_M2_OVERCLAIM\tFIRED\tM2 claimed against %s historical review rows and %s authorities\n' "$_c_rows" "$_c_auth"
  else
    printf 'R05\tWP001_AUTHORITY_OR_M2_OVERCLAIM\tSILENT\tno adverse condition\n'
  fi
} > "$OUT"

echo "FIVE_RED_INDEPENDENT_WITNESS=$OUT"
