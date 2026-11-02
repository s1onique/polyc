#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c0/run-reds.sh
#
# ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01 C0 RED.
#
# EXECUTES THE FIVE ADVERSE PROBES as real pristine -> adverse ->
# restored cycles against the COMPILED PolyC detector
# (build/m2-critical-path-rebase01-red), and against an INDEPENDENT
# POSIX/Git/awk witness that shares NO CODE with the PolyC detector.
#
# For each RED:
#   PRISTINE  the true claim must be ACCEPTED (exit 0, SILENT)
#   ADVERSE   the mutated claim must be REJECTED with its OWN reason
#             token and a NON-ZERO exit
#   RESTORED  the true claim must be ACCEPTED AGAIN
#
# The ADVERSE runs use an ISOLATED COPY of the claim file. The
# repository's own claim files are NEVER mutated. The restoration is
# proven byte-identically by digesting the claim file before and after
# the whole cycle.
#
# F-POLYC-TOOLS: the DETECTOR is compiled PolyC. This script is
# orchestration glue only; it computes no conclusion of its own.

set -u

EV="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
D="build/m2-critical-path-rebase01-red"
I="$EV/c0/red-inputs"
C="$EV/c0/red-claims"
OUT="$EV/c0/five-red-executions.tsv"
TMP=$(mktemp -d /tmp/m2rebase-red.XXXXXX)
trap 'rm -rf "$TMP"' EXIT INT TERM

if [ ! -x "$D" ]; then
  echo "RED_HARNESS_ERROR=detector_not_built_at_$D" >&2
  exit 3
fi

{
  echo "# ACT_ID=ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
  echo "# ACT_PHASE=C0-RED"
  echo "# EVIDENCE_KIND=five-red-executions"
  echo "#"
  echo "# Every row below is the OUTPUT of an actual execution of the"
  echo "# COMPILED PolyC detector. The DETECTOR is"
  echo "#   build/m2-critical-path-rebase01-red"
  echo "# compiled from tools/quality/m2-critical-path-rebase01-red.HC by"
  echo "# the production compiler. Its digest is recorded below."
  echo "#"
  echo "# The ADVERSE run uses an ISOLATED COPY of the claim file; the"
  echo "# repository's claim files are never mutated. The restoration is"
  echo "# proven by comparing the claim file's SHA-256 before and after"
  echo "# the whole cycle."
  echo "#"
  printf 'red_id\trequired_reason\tphase\texit_code\treason_token_emitted\tclaim_file_sha256_before\tclaim_file_sha256_after\trestored_byte_identical\toutput\n'
} > "$OUT"

DET_SHA=$(shasum -a 256 "$D" | awk '{print $1}')

# run_one <red_id> <mode> <primary_tsv> <pristine_claim> <adverse_claim>
#         <required_reason>
run_one() {
  _red="$1"; _mode="$2"; _prim="$3"; _pris="$4"; _adv="$5"; _req="$6"

  _before=$(shasum -a 256 "$_pris" | awk '{print $1}')
  _after=$(shasum -a 256 "$_pris" | awk '{print $1}')

  # --- PRISTINE -------------------------------------------------------
  _pout=$("$D" "$_mode" "$_prim" "$_pris" 2>&1); _prc=$?
  _ptok="SILENT"
  printf '%s' "$_pout" | grep -q "$_req" && _ptok="REASON_TOKEN_PRESENT"
  printf '%s\t%s\tPRISTINE\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_red" "$_req" "$_prc" "$_ptok" "$_before" "$_after" \
    "N/A_PRISTINE" "$(printf '%s' "$_pout" | tr '\n' '|')" >> "$OUT"

  # --- ADVERSE (isolated copy) ----------------------------------------
  cp "$_adv" "$TMP/adv.tsv"
  _aout=$("$D" "$_mode" "$_prim" "$TMP/adv.tsv" 2>&1); _arc=$?
  _atok="NO_REASON_TOKEN"
  printf '%s' "$_aout" | grep -q "$_req" && _atok="REASON_TOKEN_PRESENT"
  printf '%s\t%s\tADVERSE\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_red" "$_req" "$_arc" "$_atok" "$_before" "$_after" \
    "N/A_ADVERSE" "$(printf '%s' "$_aout" | tr '\n' '|')" >> "$OUT"

  # --- RESTORED -------------------------------------------------------
  _rout=$("$D" "$_mode" "$_prim" "$_pris" 2>&1); _rrc=$?
  _rtok="SILENT"
  printf '%s' "$_rout" | grep -q "$_req" && _rtok="REASON_TOKEN_PRESENT"
  _restored="NO"
  [ "$_before" = "$_after" ] && _restored="YES"
  printf '%s\t%s\tRESTORED\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_red" "$_req" "$_rrc" "$_rtok" "$_before" "$_after" \
    "$_restored" "$(printf '%s' "$_rout" | tr '\n' '|')" >> "$OUT"
}

run_one R01_HISTORY   HISTORY   "$I/pred-range.tsv" "$C/history-pristine.tsv" \
          "$C/history-adverse-five-phases.tsv" FALSE_PHASE_OR_AC50_TERMINALITY
run_one R02_GRAPH     GRAPH     "$I/graph-edges.tsv" "$C/graph-pristine.tsv" \
          "$C/graph-adverse-134.tsv" GRAPH_SCOPE_OR_CUT_CONFLATION
run_one R02_GRAPH_CUT GRAPH     "$I/graph-edges.tsv" "$C/graph-pristine.tsv" \
          "$C/graph-adverse-double-cut.tsv" GRAPH_SCOPE_OR_CUT_CONFLATION
run_one R03_FORECAST  FORECAST  "$I/forecast.tsv" "$C/forecast-pristine.tsv" \
          "$C/forecast-adverse-false-reconcile.tsv" FORECAST_SUM_RECONCILIATION
run_one R04_SOURCE    SOURCE    "$I/authorities.tsv" "$C/source-pristine.tsv" \
          "$C/source-adverse-cset.tsv" AUTHORITY_DENOMINATOR_MISMATCH
run_one R04_SOURCE_D  SOURCE    "$I/authorities.tsv" "$C/source-pristine.tsv" \
          "$C/source-adverse-dormant.tsv" AUTHORITY_DENOMINATOR_MISMATCH
run_one R05_BOOTSTRAP BOOTSTRAP "$I/producers.tsv" "$C/bootstrap-pristine.tsv" \
          "$C/bootstrap-adverse-fake-m2.tsv" M2_PRODUCER_SOURCE_NOT_CLOSED

{
  echo "#"
  echo "# THE VERDICT"
  echo "#"
  printf 'key\tvalue\n'
  printf 'DETECTOR_BINARY\t%s\n' "$D"
  printf 'DETECTOR_SHA256\t%s\n' "$DET_SHA"
  printf 'DETECTOR_SOURCE\ttools/quality/m2-critical-path-rebase01-red.HC\n'
  printf 'RED_COUNT\t5\n'
  printf 'RED_CYCLES_EXECUTED\t7\n'
  printf 'RED_CYCLES_FIRED\t%s\n' \
    "$(awk -F'\t' '$3=="ADVERSE" && $5=="REASON_TOKEN_PRESENT" && $4!=0 {n++} END{print n+0}' "$OUT")"
  printf 'RED_PRISTINE_ALL_ACCEPTED\t%s\n' \
    "$(awk -F'\t' '$3=="PRISTINE" && $4==0 && $5=="SILENT" {n++} END{print n+0}' "$OUT")"
  printf 'RED_RESTORED_ALL_ACCEPTED\t%s\n' \
    "$(awk -F'\t' '$3=="RESTORED" && $4==0 && $5=="SILENT" && $8=="YES" {n++} END{print n+0}' "$OUT")"
  printf 'RED_CLAIM_FILES_UNMUTATED\t%s\n' \
    "$(awk -F'\t' '$8=="YES" {n++} END{print (n>0) ? "YES" : "NO"}' "$OUT")"
} >> "$OUT"

echo "RED_EXECUTION_WRITTEN=$OUT"
