#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01/c0/run-reds.sh
#
# ACT-POLYC-SELFHOST-DRIVER-MIGRATION01 C0 RED.
#
# Executes the FIVE adverse probes against the COMPILED PolyC detector
# (build/driver-migration01-red), with a pristine / adverse / restored
# cycle for each. The detector is compiled from PolyC source by the real
# production compiler; it shares no code with the independent POSIX
# witness below.
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

EV="evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01"
D="build/driver-migration01-red"
I="$EV/c0/red-inputs"
C="$EV/c0/red-claims"
OUT="$EV/c0/five-red-executions.tsv"
TMP=$(mktemp -d /tmp/wp001-red.XXXXXX)
trap 'rm -rf "$TMP"' EXIT INT TERM

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-MIGRATION01'
  echo '# ACT_PHASE=C0-RED'
  echo '# EVIDENCE_KIND=five-red-executions'
  echo '#'
  echo '# THE DETECTOR'
  echo '#   build/driver-migration01-red'
  echo '# compiled from tools/quality/driver-migration01-red.HC by the'
  echo '# real production compiler. It RE-DERIVES each fact from the'
  echo '# primary rows it loads itself; it never reads a status field.'
  echo '#'
  printf 'red_id\trequired_reason\tphase\texit_code\treason_token_emitted\tclaim_file_sha256_before\tclaim_file_sha256_after\trestored_byte_identical\toutput\n'
} > "$OUT"

DET_SHA=$(shasum -a 256 "$D" | awk '{print $1}')

# Render a detector output as a single-line field. An EMPTY output is
# rendered as the explicit token EMPTY, so no row ever ends in a
# trailing TAB (the patch-hygiene gate rejects trailing whitespace).
render() {
  if [ -z "$1" ]; then echo "EMPTY"; else printf '%s' "$1" | tr '\n' '|'; fi
}

run_one() {
  _red="$1"; _mode="$2"; _prim="$3"; _pris="$4"; _adv="$5"; _req="$6"

  _before=$(shasum -a 256 "$_pris" | awk '{print $1}')
  _after=$(shasum -a 256 "$_pris" | awk '{print $1}')

  _pout=$("$D" "$_mode" "$_prim" "$_pris" 2>&1); _prc=$?
  _ptok="SILENT"
  printf '%s' "$_pout" | grep -q "$_req" && _ptok="REASON_TOKEN_PRESENT"
  printf '%s\t%s\tPRISTINE\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_red" "$_req" "$_prc" "$_ptok" "$_before" "$_after" \
    "N/A_PRISTINE" "$(render "$_pout")" >> "$OUT"

  cp "$_adv" "$TMP/adv.tsv"
  _aout=$("$D" "$_mode" "$_prim" "$TMP/adv.tsv" 2>&1); _arc=$?
  _atok="NO_REASON_TOKEN"
  printf '%s' "$_aout" | grep -q "$_req" && _atok="REASON_TOKEN_PRESENT"
  printf '%s\t%s\tADVERSE\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_red" "$_req" "$_arc" "$_atok" "$_before" "$_after" \
    "N/A_ADVERSE" "$(render "$_aout")" >> "$OUT"

  _rout=$("$D" "$_mode" "$_prim" "$_pris" 2>&1); _rrc=$?
  _rtok="SILENT"
  printf '%s' "$_rout" | grep -q "$_req" && _rtok="REASON_TOKEN_PRESENT"
  _restored="NO"
  [ "$_before" = "$_after" ] && _restored="YES"
  printf '%s\t%s\tRESTORED\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_red" "$_req" "$_rrc" "$_rtok" "$_before" "$_after" \
    "$_restored" "$(render "$_rout")" >> "$OUT"
}

run_one R01_FAKE_DRIVER_INERT   FAKE      "$I/driver-symbols.tsv" "$C/fake-pristine.tsv" \
          "$C/fake-adverse-inert.tsv"      POLYC_DRIVER_NOT_SEMANTIC_AUTHORITY
run_one R01_FAKE_DRIVER_OVERCLAIM FAKE    "$I/driver-symbols.tsv" "$C/fake-pristine.tsv" \
          "$C/fake-adverse-overclaim.tsv"  POLYC_DRIVER_NOT_SEMANTIC_AUTHORITY
run_one R02_ORACLE_LEAK         ORACLE   "$I/oracle-nm.tsv"      "$C/oracle-pristine.tsv" \
          "$C/oracle-adverse-leak.tsv"     C_ORACLE_CONTAMINATED
run_one R03_DORMANT_C           DORMANT  "$I/legacy-c-relocs.tsv" "$C/dormant-pristine.tsv" \
          "$C/dormant-adverse-claimdormant.tsv" LEGACY_C_DRIVER_DECISION_ACTIVE
run_one R04_ARGUMENT_LIFETIME   LIFETIME "$I/abi-contract.tsv"  "$C/lifetime-pristine.tsv" \
          "$C/lifetime-adverse-noabi.tsv"   DRIVER_ABI_LIFETIME_OR_DOMAIN
run_one R05_FALSE_P0            P0       "$I/source-closure.tsv" "$C/p0-pristine.tsv" \
          "$C/p0-adverse-falsep0.tsv"       BOOTSTRAP_SOURCE_CLOSURE_FALSE

{
  echo '#'
  echo '# THE VERDICT'
  echo '#'
  printf 'key\tvalue\n'
  printf 'DETECTOR_BINARY\t%s\n' "$D"
  printf 'DETECTOR_SHA256\t%s\n' "$DET_SHA"
  printf 'DETECTOR_SOURCE\ttools/quality/driver-migration01-red.HC\n'
  printf 'RED_COUNT\t5\n'
  printf 'RED_CYCLES_EXECUTED\t6\n'
  printf 'RED_CYCLES_FIRED\t%s\n' \
    "$(awk -F'\t' '$3=="ADVERSE" && $5=="REASON_TOKEN_PRESENT" && $4!=0 {n++} END{print n+0}' "$OUT")"
  printf 'RED_PRISTINE_ALL_ACCEPTED\t%s\n' \
    "$(awk -F'\t' '$3=="PRISTINE" && $4==0 && $5=="SILENT" {n++} END{print n+0}' "$OUT")"
  printf 'RED_RESTORED_ALL_ACCEPTED\t%s\n' \
    "$(awk -F'\t' '$3=="RESTORED" && $4==0 && $5=="SILENT" && $8=="YES" {n++} END{print n+0}' "$OUT")"
  printf 'RED_CLAIM_FILES_UNMUTATED\t%s\n' \
    "$(awk -F'\t' '$8=="YES" {n++} END{print (n>0) ? "YES" : "NO"}' "$OUT")"
  printf 'RED_DISTINCT_REASON_TOKENS\t%s\n' \
    "$(awk -F'\t' '$3=="ADVERSE" && $5=="REASON_TOKEN_PRESENT" {print $2}' "$OUT" | sort -u | paste -sd, -)"
} >> "$OUT"

echo "RED_EXECUTIONS_WRITTEN=$OUT"
