#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01/q0/run-reds.sh
#
# ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01 Q0 RED.
#
# Executes the FIVE adverse probes against the COMPILED PolyC detector
# (build/driver-boundary-qualification01-red), with a pristine /
# adverse / restored cycle for each. The detector is compiled from
# PolyC source by the real production compiler; it shares no code with
# the independent POSIX witness (run-reds-independent-witness.sh).
#
# For each RED:
#   PRISTINE   the TRUE claim must be ACCEPTED (exit 0, SILENT)
#   ADVERSE    the WRONG claim must be REJECTED (non-zero exit, and the
#              detector's OWN reason token must appear in the output)
#   RESTORED   the TRUE claim must be ACCEPTED AGAIN, and the claim file
#              must be byte-identical to its pristine state
#
# F-POLYC-TOOLS: orchestration glue, under the 50 LOC shell budget.

set -u

EV="evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01/q0"
D="build/driver-boundary-qualification01-red"
I="$EV/red-inputs"
C="$EV/red-claims"
OUT="$EV/five-red-executions.tsv"
TMP=$(mktemp -d /tmp/q01-red.XXXXXX)
trap 'rm -rf "$TMP"' EXIT INT TERM

render() {
  if [ -z "$1" ]; then echo "EMPTY"; else printf '%s' "$1" | tr '\n' '|'; fi
}

# run_one <red_id> <required_reason> <primary_input> <pristine_claim> <adverse_claim> [extra_arg]
run_one() {
  _red="$1"; _req="$2"; _prim="$3"; _pris="$4"; _adv="$5"; _extra="${6-}"

  _before=$(shasum -a 256 "$_pris" | awk '{print $1}')

  if [ -n "$_extra" ]; then
    _pout=$("$D" "$_red" "$_prim" "$_extra" "$_pris" 2>&1); _prc=$?
  else
    _pout=$("$D" "$_red" "$_prim" "$_pris" 2>&1); _prc=$?
  fi
  _ptok="SILENT"
  printf '%s' "$_pout" | grep -q "$_req" && _ptok="REASON_TOKEN_PRESENT"
  printf '%s\t%s\tPRISTINE\t%s\t%s\t%s\tN/A_PRISTINE\t%s\n' \
    "$_red" "$_req" "$_prc" "$_ptok" "$_before" "$(render "$_pout")" >> "$OUT"

  cp "$_adv" "$TMP/adv.tsv"
  if [ -n "$_extra" ]; then
    _aout=$("$D" "$_red" "$_prim" "$_extra" "$TMP/adv.tsv" 2>&1); _arc=$?
  else
    _aout=$("$D" "$_red" "$_prim" "$TMP/adv.tsv" 2>&1); _arc=$?
  fi
  _atok="NO_REASON_TOKEN"
  printf '%s' "$_aout" | grep -q "$_req" && _atok="REASON_TOKEN_PRESENT"
  printf '%s\t%s\tADVERSE\t%s\t%s\t%s\tN/A_ADVERSE\t%s\n' \
    "$_red" "$_req" "$_arc" "$_atok" "$_before" "$(render "$_aout")" >> "$OUT"

  if [ -n "$_extra" ]; then
    _rout=$("$D" "$_red" "$_prim" "$_extra" "$_pris" 2>&1); _rrc=$?
  else
    _rout=$("$D" "$_red" "$_prim" "$_pris" 2>&1); _rrc=$?
  fi
  _rtok="SILENT"
  printf '%s' "$_rout" | grep -q "$_req" && _rtok="REASON_TOKEN_PRESENT"
  _after=$(shasum -a 256 "$_pris" | awk '{print $1}')
  _ident="NOT_IDENTICAL"
  [ "$_before" = "$_after" ] && _ident="BYTE_IDENTICAL"
  printf '%s\t%s\tRESTORED\t%s\t%s\t%s\t%s\t%s\n' \
    "$_red" "$_req" "$_rrc" "$_rtok" "$_after" "$_ident" "$(render "$_rout")" >> "$OUT"
}

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01'
  echo '# ACT_PHASE=Q0-RED'
  echo '# EVIDENCE_KIND=five-red-executions'
  echo '#'
  echo '# THE DETECTOR'
  echo '#   build/driver-boundary-qualification01-red'
  echo '# compiled from tools/quality/driver-boundary-qualification01-red.HC'
  echo '# by the real production compiler. It RE-DERIVES each fact from the'
  echo '# primary rows it loads itself; it never reads a status field.'
  echo '#'
  printf 'red_id\trequired_reason\tphase\texit_code\treason_token_emitted\tclaim_file_sha256_before\tclaim_file_sha256_after\trestored_byte_identical\toutput\n'
} > "$OUT"

run_one R01 RELOCATION_IS_NOT_DECISION_PROOF      "$I/driver-relocations.tsv"           "$C/r01-pristine.tsv" "$C/r01-adverse.tsv"
run_one R02 DRIVER_BOUNDARY_NOT_CAUSALLY_PROVEN   "$I/branch-counterfactuals-adverse.tsv" "$C/r02-pristine.tsv" "$C/r02-adverse.tsv"
run_one R03 PRECOMMITTED_TERMINALITY_RESULT       "$I/tracked-terminality-outcome.tsv"  "$C/r03-pristine.tsv" "$C/r03-adverse.tsv" "$I/close-tree-paths.txt"
run_one R04 WP001_CORRECTION_FAMILY_OMITTED       "$I/act-family-inventory.tsv"         "$C/r04-pristine.tsv" "$C/r04-adverse.tsv"
run_one R05 WP001_AUTHORITY_OR_M2_OVERCLAIM       "$I/production-authorities.tsv"       "$C/r05-pristine.tsv" "$C/r05-adverse.tsv"

echo "FIVE_RED_EXECUTIONS=$OUT"
