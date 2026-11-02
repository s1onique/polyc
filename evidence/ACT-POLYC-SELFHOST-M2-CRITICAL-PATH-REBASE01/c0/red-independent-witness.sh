#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c0/red-independent-witness.sh
#
# The INDEPENDENT POSIX/Git/awk witness for the five C0 REDs.
#
# It shares NO CODE with the compiled PolyC detector. It re-derives
# each fact from the primary rows with plain awk/grep and checks the
# SAME claim files. If the two implementations agree on every
# pristine/adverse verdict, the detector is not self-confirming.
#
# This script computes the VERDICT ONLY. It does not mutate anything.

set -u
EV="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
I="$EV/c0/red-inputs"
C="$EV/c0/red-claims"

claim() { grep "^$1	" "$2" | head -1 | cut -f2; }

# --- HISTORY -----------------------------------------------------------
derived_phases=$(awk -F'\t' '!/^#/ && $1 !~ /^commit_sha/ {n++} END{print n+0}' "$I/pred-range.tsv")
derived_c1=$(awk -F'\t' '!/^#/ && $2=="C1" {n++} END{print (n>0)?1:0}' "$I/pred-range.tsv")
cp_phases=$(claim ACTUAL_PHASE_COUNT "$C/history-pristine.tsv")
cp_c1=$(claim C1_EVIDENCE_COMMIT_PRESENT "$C/history-pristine.tsv")
cp_ac50=$(claim FROZEN_AC50_LITERAL_SATISFIED "$C/history-pristine.tsv")
aa_phases=$(claim ACTUAL_PHASE_COUNT "$C/history-adverse-five-phases.tsv")
aa_c1=$(claim C1_EVIDENCE_COMMIT_PRESENT "$C/history-adverse-five-phases.tsv")
aa_ac50=$(claim FROZEN_AC50_LITERAL_SATISFIED "$C/history-adverse-five-phases.tsv")
literal_ok=$(( (derived_phases==5 && derived_c1==1) ? 1 : 0 ))
echo "WITNESS_HISTORY_DERIVED_PHASES=$derived_phases"
echo "WITNESS_HISTORY_DERIVED_C1=$derived_c1"
echo "WITNESS_HISTORY_LITERAL_AC50_OK=$literal_ok"
if [ "$cp_phases" = "$derived_phases" ] && [ "$cp_c1" = "$derived_c1" ] && [ "$cp_ac50" = "$literal_ok" ]; then
  echo "WITNESS_HISTORY_PRISTINE=ACCEPT"
else
  echo "WITNESS_HISTORY_PRISTINE=REJECT"
fi
if [ "$aa_phases" != "$derived_phases" ] || [ "$aa_c1" != "$derived_c1" ] || [ "$aa_ac50" != "$literal_ok" ]; then
  echo "WITNESS_HISTORY_ADVERSE=REJECT FALSE_PHASE_OR_AC50_TERMINALITY"
else
  echo "WITNESS_HISTORY_ADVERSE=ACCEPT"
fi

# --- GRAPH -------------------------------------------------------------
derived_mand=$(awk -F'\t' 'NR>1 && $6=="YES" {n++} END{print n+0}' "$I/graph-edges.tsv")
cp_mand=$(claim MANDATORY_EDGE_COUNT "$C/graph-pristine.tsv")
aa_mand=$(claim MANDATORY_EDGE_COUNT "$C/graph-adverse-134.tsv")
dup_cuts=$(awk -F'\t' '$1=="CUT_EDGE_IDS" {n=split($2,a,","); for(i=1;i<=n;i++){for(j=i+1;j<=n;j++) if(a[i]==a[j] && a[i]!="") c++}} END{print c+0}' "$C/graph-adverse-double-cut.tsv")
echo "WITNESS_GRAPH_DERIVED_MANDATORY=$derived_mand"
if [ "$cp_mand" = "$derived_mand" ]; then echo "WITNESS_GRAPH_PRISTINE=ACCEPT"; else echo "WITNESS_GRAPH_PRISTINE=REJECT"; fi
if [ "$aa_mand" != "$derived_mand" ]; then echo "WITNESS_GRAPH_ADVERSE=REJECT GRAPH_SCOPE_OR_CUT_CONFLATION"; else echo "WITNESS_GRAPH_ADVERSE=ACCEPT"; fi
if [ "$dup_cuts" -gt 0 ]; then echo "WITNESS_GRAPH_ADVERSE_CUT=REJECT GRAPH_SCOPE_OR_CUT_CONFLATION"; else echo "WITNESS_GRAPH_ADVERSE_CUT=ACCEPT"; fi

# --- FORECAST ----------------------------------------------------------
displayed=$(awk -F'\t' 'NR>1 && $1=="M2" {s=0; for(i=5;i<=10;i++) s+=$i; print s}' "$I/forecast.tsv")
reported=$(awk -F'\t' 'NR>1 && $1=="M2" {print $11}' "$I/forecast.tsv")
cp_rep=$(claim REPORTED_TOTAL "$C/forecast-pristine.tsv")
cp_rec=$(claim DISPLAYED_SUM_RECONCILES_REPORTED_TOTAL "$C/forecast-pristine.tsv")
aa_rep=$(claim REPORTED_TOTAL "$C/forecast-adverse-false-reconcile.tsv")
aa_rec=$(claim DISPLAYED_SUM_RECONCILES_REPORTED_TOTAL "$C/forecast-adverse-false-reconcile.tsv")
recon=$(( (displayed==reported) ? 1 : 0 ))
echo "WITNESS_FORECAST_DERIVED_DISPLAYED=$displayed"
echo "WITNESS_FORECAST_DERIVED_REPORTED=$reported"
if [ "$cp_rep" = "$reported" ] && [ "$cp_rec" = "$recon" ]; then echo "WITNESS_FORECAST_PRISTINE=ACCEPT"; else echo "WITNESS_FORECAST_PRISTINE=REJECT"; fi
if [ "$aa_rep" != "$reported" ] || [ "$aa_rec" != "$recon" ]; then echo "WITNESS_FORECAST_ADVERSE=REJECT FORECAST_SUM_RECONCILIATION"; else echo "WITNESS_FORECAST_ADVERSE=ACCEPT"; fi

# --- SOURCE ------------------------------------------------------------
derived_sem=$(awk -F'\t' '!/^#/ && $1 !~ /^authority_id/ && $3!="MECHANICAL_ADAPTER" && $3!="DORMANT_SELECTOR_OFF" {n++} END{print n+0}' "$I/authorities.tsv")
cp_sem=$(claim SEMANTIC_AUTHORITY_COUNT "$C/source-pristine.tsv")
aa_sem=$(claim SEMANTIC_AUTHORITY_COUNT "$C/source-adverse-cset.tsv")
aa_cset=$(claim CSET_COUNTED_AS_AUTHORITY "$C/source-adverse-cset.tsv")
aa_dorm=$(claim DORMANT_COUNTED_AS_PRODUCTION_REACHABLE "$C/source-adverse-dormant.tsv")
echo "WITNESS_SOURCE_DERIVED_SEMANTIC=$derived_sem"
if [ "$cp_sem" = "$derived_sem" ]; then echo "WITNESS_SOURCE_PRISTINE=ACCEPT"; else echo "WITNESS_SOURCE_PRISTINE=REJECT"; fi
if [ "$aa_sem" != "$derived_sem" ] || [ "$aa_cset" != "0" ]; then echo "WITNESS_SOURCE_ADVERSE=REJECT AUTHORITY_DENOMINATOR_MISMATCH"; else echo "WITNESS_SOURCE_ADVERSE=ACCEPT"; fi
if [ "$aa_dorm" != "0" ]; then echo "WITNESS_SOURCE_ADVERSE_DORMANT=REJECT AUTHORITY_DENOMINATOR_MISMATCH"; else echo "WITNESS_SOURCE_ADVERSE_DORMANT=ACCEPT"; fi

# --- BOOTSTRAP ---------------------------------------------------------
derived_m2=$(awk -F'\t' 'NR>1 && $7=="POLYC_AUTHORED_COMPILER" && $6=="YES" {n++} END{print n+0}' "$I/producers.tsv")
cp_m2=$(claim M2_PRODUCER_COUNT "$C/bootstrap-pristine.tsv")
cp_ach=$(claim M2_ACHIEVED "$C/bootstrap-pristine.tsv")
aa_m2=$(claim M2_PRODUCER_COUNT "$C/bootstrap-adverse-fake-m2.tsv")
aa_ach=$(claim M2_ACHIEVED "$C/bootstrap-adverse-fake-m2.tsv")
ach=$(( (derived_m2>0) ? 1 : 0 ))
echo "WITNESS_BOOTSTRAP_DERIVED_M2_PRODUCERS=$derived_m2"
if [ "$cp_m2" = "$derived_m2" ] && [ "$cp_ach" = "$ach" ]; then echo "WITNESS_BOOTSTRAP_PRISTINE=ACCEPT"; else echo "WITNESS_BOOTSTRAP_PRISTINE=REJECT"; fi
if [ "$aa_m2" != "$derived_m2" ] || [ "$aa_ach" != "$ach" ]; then echo "WITNESS_BOOTSTRAP_ADVERSE=REJECT M2_PRODUCER_SOURCE_NOT_CLOSED"; else echo "WITNESS_BOOTSTRAP_ADVERSE=ACCEPT"; fi
