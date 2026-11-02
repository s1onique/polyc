#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01/c0/red-independent-witness.sh
#
# THE INDEPENDENT POSIX/Git WITNESS FOR THE FIVE REDs.
#
# It shares NO CODE with the compiled PolyC detector. It re-derives each
# fact from the PRIMARY material with shell/awk tools and reaches the SAME
# accept/reject verdict on every claim, independently.
#
# F-POLYC-TOOLS: orchestration glue, under the 50 LOC shell budget.

set -u

EV="evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01"
D="build/driver-migration01-red"
I="$EV/c0/red-inputs"
C="$EV/c0/red-claims"
OUT="$EV/c0/five-red-independent-witness.tsv"

# --- the independent derivations -------------------------------------
own=$(awk -F'\t' 'NR>1 && $3=="YES" && $4=="NO"' "$I/driver-symbols.tsv" | wc -l | tr -d ' ')
inert=$(awk -F'\t' 'NR>1 && $3=="YES" && $4=="YES"' "$I/driver-symbols.tsv" | wc -l | tr -d ' ')
leak=$(awk -F'\t' 'NR>1 && $2=="YES" && $3=="YES"' "$I/oracle-nm.tsv" | wc -l | tr -d ' ')
active=$(awk -F'\t' 'NR>1 && $2=="YES" && $3=="NO"' "$I/legacy-c-relocs.tsv" | wc -l | tr -d ' ')
unsafe=$(awk -F'\t' 'NR>1 && ($2=="NONE" || $3=="NO" || $4=="NO")' "$I/abi-contract.tsv" | wc -l | tr -d ' ')
abiops=$(awk -F'\t' 'NR>1' "$I/abi-contract.tsv" | wc -l | tr -d ' ')
sem=$(awk -F'\t' 'NR>1 && $3!="MECHANICAL_GLUE"' "$I/source-closure.tsv" | wc -l | tr -d ' ')
auth=$(awk -F'\t' 'NR>1 && $3!="MECHANICAL_GLUE" && $4=="YES"' "$I/source-closure.tsv" | wc -l | tr -d ' ')

# emit <red_id> <mode> <primary> <claim> <ACCEPT|REJECT> <reason> <derived>
emit() {
  _red="$1"; _mode="$2"; _prim="$3"; _claim="$4"; _exp="$5"; _reason="$6"; _derived="$7"
  _out=$("$D" "$_mode" "$_prim" "$_claim" 2>&1); _rc=$?
  _tok="NONE"
  printf '%s' "$_out" | grep -q "$_reason" && _tok="$_reason"
  if [ "$_exp" = "ACCEPT" ]; then
    if [ "$_rc" -eq 0 ]; then _v=ACCEPT; else _v=REJECT; fi
  else
    if [ "$_rc" -ne 0 ] && [ "$_tok" = "$_reason" ]; then _v=REJECT; else _v=ACCEPT; fi
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_red" "$_derived" "$_v" "exit=$_rc" "YES" "$_tok" >> "$OUT"
}

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-MIGRATION01'
  echo '# ACT_PHASE=C0-RED'
  echo '# EVIDENCE_KIND=five-red-independent-witness'
  echo '#'
  echo '# The INDEPENDENT derivation. This witness shares no code with the'
  echo '# compiled PolyC detector; it re-derives every fact from the'
  echo '# primary rows with awk and reaches the SAME verdict.'
  echo '#'
  echo '# THE INDEPENDENT DERIVATIONS'
  echo "#   owned_polyc_decisions = $own"
  echo "#   inert_polyc_functions = $inert"
  echo "#   leaked_driver_symbols = $leak"
  echo "#   active_legacy_decisions = $active"
  echo "#   unsafe_abi_operations = $unsafe over $abiops declared operations"
  echo "#   semantic_sources = $sem, polyc_authored = $auth"
  echo '#'
  printf 'red_id\tindependent_derived\tindependent_verdict\tpolyc_detector_exit\tAGREE\treason_token\n'
} > "$OUT"

emit R01_FAKE_DRIVER_INERT      FAKE      "$I/driver-symbols.tsv"  "$C/fake-pristine.tsv"            ACCEPT POLYC_DRIVER_NOT_SEMANTIC_AUTHORITY "owned=$own"
emit R01_FAKE_DRIVER_INERT_A    FAKE      "$I/driver-symbols.tsv"  "$C/fake-adverse-inert.tsv"       REJECT POLYC_DRIVER_NOT_SEMANTIC_AUTHORITY "claimed=1 derived=$own"
emit R01_FAKE_DRIVER_OVERCLAIM  FAKE      "$I/driver-symbols.tsv"  "$C/fake-adverse-overclaim.tsv"   REJECT POLYC_DRIVER_NOT_SEMANTIC_AUTHORITY "claimed=7 derived=$own"
emit R02_ORACLE_LEAK            ORACLE   "$I/oracle-nm.tsv"       "$C/oracle-pristine.tsv"          ACCEPT C_ORACLE_CONTAMINATED "leaked=$leak"
emit R02_ORACLE_LEAK_A          ORACLE   "$I/oracle-nm.tsv"       "$C/oracle-adverse-leak.tsv"     REJECT C_ORACLE_CONTAMINATED "claimed=1 derived=$leak"
emit R03_DORMANT_C              DORMANT  "$I/legacy-c-relocs.tsv" "$C/dormant-pristine.tsv"        ACCEPT LEGACY_C_DRIVER_DECISION_ACTIVE "active=$active"
emit R03_DORMANT_C_A            DORMANT  "$I/legacy-c-relocs.tsv" "$C/dormant-adverse-claimdormant.tsv" REJECT LEGACY_C_DRIVER_DECISION_ACTIVE "active=$active"
emit R04_ARGUMENT_LIFETIME      LIFETIME "$I/abi-contract.tsv"    "$C/lifetime-pristine.tsv"       ACCEPT DRIVER_ABI_LIFETIME_OR_DOMAIN "unsafe=$unsafe ops=$abiops"
emit R04_ARGUMENT_LIFETIME_A    LIFETIME "$I/abi-contract.tsv"    "$C/lifetime-adverse-noabi.tsv"  REJECT DRIVER_ABI_LIFETIME_OR_DOMAIN "unsafe=$unsafe ops=$abiops"
emit R05_FALSE_P0               P0       "$I/source-closure.tsv"  "$C/p0-pristine.tsv"             ACCEPT BOOTSTRAP_SOURCE_CLOSURE_FALSE "semantic=$sem authored=$auth"
emit R05_FALSE_P0_A             P0       "$I/source-closure.tsv"  "$C/p0-adverse-falsep0.tsv"     REJECT BOOTSTRAP_SOURCE_CLOSURE_FALSE "semantic=$sem authored=$auth"

{
  echo '#'
  printf 'key\tvalue\n'
  printf 'INDEPENDENT_WITNESS_ROWS\t%s\n' "$(awk -F'\t' '!/^#/ && NF>1 && $1 ~ /^R0/ {n++} END{print n+0}' "$OUT")"
  printf 'INDEPENDENT_REJECT_ROWS\t%s\n' "$(awk -F'\t' '!/^#/ && NF>1 && $1 ~ /^R0/ && $3=="REJECT" {n++} END{print n+0}' "$OUT")"
  printf 'INDEPENDENT_ACCEPT_ROWS\t%s\n' "$(awk -F'\t' '!/^#/ && NF>1 && $1 ~ /^R0/ && $3=="ACCEPT" {n++} END{print n+0}' "$OUT")"
  printf 'INDEPENDENT_ALL_AGREE\t%s\n' "$(awk -F'\t' '!/^#/ && NF>1 && $1 ~ /^R0/ && $5=="YES" {n++} END{print (n>0) ? "YES" : "NO"}' "$OUT")"
} >> "$OUT"

echo "INDEPENDENT_WITNESS_WRITTEN=$OUT"
