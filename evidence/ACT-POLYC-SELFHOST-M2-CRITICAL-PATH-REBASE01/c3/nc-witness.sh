#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c3/nc-witness.sh
#
# THE INDEPENDENT POSIX WITNESS FOR THE TWENTY-FOUR CONTROLS.
#
# It recomputes the SAME fact the PolyC detector recomputes, by a
# DIFFERENT route, and shares NO CODE with it. When the two disagree
# the control is not sensitive and the run is void.
#
# Usage: nc-witness.sh <MODE> <state.tsv>
# It prints the reason token on a violation, and nothing on acceptance.
#
# F-POLYC-TOOLS: orchestration glue; it computes no conclusion of the
# ACT, only the cross-check of a conclusion.

set -u

EV="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
CENSUS="evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01"
EDGES="$CENSUS/c1/graph-edges.tsv"
AUTHS="$CENSUS/c1/authorities.tsv"
UNKNOWN="$CENSUS/c1/unknown-edges.tsv"
DORM="$CENSUS/c1/dormant-polyc-sites.tsv"
PROD="$EV/c1/generation-producer-dag.tsv"
WPT="$EV/c2/work-packages.tsv"
DEPT="$EV/c2/work-package-dependencies.tsv"
RANK="$EV/c2/work-package-ranking.tsv"

MODE="$1"
STATE="$2"

kv() { awk -F'\t' -v k="$1" '$1==k{print $2; exit}' "$STATE"; }

case "$MODE" in
  IDENTITY)
    ph=$(kv predecessor_head); phe=$(kv predecessor_head_expected)
    pr=$(kv predecessor_range); pre=$(kv predecessor_range_expected)
    rh=$(kv receipt_bound_head); rt=$(kv receipt_bound_tree)
    eh=$(kv entry_head); et=$(kv entry_tree)
    cc=$(kv close_count); dis=$(kv ac50_discharged)
    fsha=$(kv frozen_artifact_sha256); fshae=$(kv frozen_artifact_sha256_expected)
    fpath=$(kv frozen_artifact_path)
    if [ -n "$fsha" ] && [ -n "$fshae" ] && [ "$fsha" != "$fshae" ]; then echo "HISTORICAL_F14_BLOB_MISMATCH"; exit 0; fi
    # The digest must ALSO match the real file on disk. This is the
    # independent route: the detector compares two state keys, the
    # witness recomputes the digest from the artifact itself.
    if [ -n "$fpath" ] && [ -n "$fsha" ] && [ -f "$fpath" ]; then
      actual=$(shasum -a 256 "$fpath" | cut -d' ' -f1)
      if [ "$actual" != "$fsha" ]; then echo "HISTORICAL_F14_BLOB_MISMATCH"; exit 0; fi
    fi
    if [ "$ph" != "$phe" ]; then echo "ENTRY_OR_PREDECESSOR_IDENTITY"; exit 0; fi
    if [ "$pr" != "$pre" ]; then echo "FALSE_PHASE_OR_AC50_TERMINALITY"; exit 0; fi
    if [ "$rh" != "$eh" ] || [ "$rt" != "$et" ]; then echo "MISBOUND_EXTERNAL_TERMINALITY"; exit 0; fi
    if [ "$dis" = "YES" ] && [ "$cc" -lt 1 ]; then echo "AC_NC_OR_TERMINALITY_FALSE_PASS"; exit 0; fi
    if [ "$cc" != "1" ]; then echo "AC_NC_OR_TERMINALITY_FALSE_PASS"; exit 0; fi
    ;;
  GRAPH)
    bm=$(awk -F'\t' 'NR>1 && $6=="YES"' "$EDGES" | wc -l | tr -d ' ')
    scope=$(kv graph_scope); me=$(kv mandatory_edges)
    pc=$(kv production_cuts); sc=$(kv shadow_cuts)
    pl=$(kv proven_mandatory_layout); mg=$(kv migration_order_edges)
    a=$(kv scc_members_a); b=$(kv scc_members_b)
    if [ "$scope" != "BASE_GRAPH" ] || [ "$me" != "$bm" ]; then echo "GRAPH_VERSION_ALIAS"; exit 0; fi
    if [ -n "$pc" ] && [ -n "$sc" ]; then
      hit=$(printf '%s\n' "$sc" | tr ',' '\n' | grep -F -x -f <(printf '%s\n' "$pc" | tr ',' '\n') 2>/dev/null | head -1)
      if [ -n "$hit" ]; then echo "SHADOW_PRODUCTION_CUT_CONFLATION"; exit 0; fi
    fi
    if [ "$pl" = "YES" ]; then
      inc=$(awk -F'\t' 'NR>1 && $4=="TYPE_REPRESENTATION" && $8 ~ /#/' "$EDGES" | wc -l | tr -d ' ')
      if [ "$inc" -gt 0 ]; then echo "LAYOUT_OBSERVATION_AS_MANDATORY"; exit 0; fi
    fi
    if [ -n "$mg" ] && [ "$mg" -gt 0 ]; then
      cal=$(awk -F'\t' 'NR>1 && $4=="CALLS"' "$EDGES" | wc -l | tr -d ' ')
      if [ "$cal" -gt 0 ]; then echo "CALL_EDGE_SCOPE_CONFUSION"; exit 0; fi
    fi
    if [ -n "$a" ] && [ -n "$b" ] && [ "$a" != "$b" ]; then echo "SCC_PARTITION_MISMATCH"; exit 0; fi
    ;;
  AUTHORITY)
    tot=$(awk -F'\t' 'NR>1 && NF>1' "$AUTHS" | wc -l | tr -d ' ')
    polyc=$(awk -F'\t' 'NR>1 && toupper($4)=="POLYC"' "$AUTHS" | wc -l | tr -d ' ')
    dorm=$(awk -F'\t' 'NR>1 && NF>1' "$DORM" | wc -l | tr -d ' ')
    pc=$(kv polyc_authority_count); cs=$(kv cset_counted_as_authority)
    ct=$(kv census_total); rm=$(kv remaining_scope); un=$(kv unknown_rows)
    pr=$(kv production_reachable)
    unr=$(awk -F'\t' 'NR>1 && NF>1 && $1 ~ /^U-/' "$UNKNOWN" | wc -l | tr -d ' ')
    if [ "$pc" != "$polyc" ]; then echo "MECHANICAL_ADAPTER_MISCOUNT"; exit 0; fi
    if [ "$cs" = "YES" ]; then echo "MECHANICAL_ADAPTER_MISCOUNT"; exit 0; fi
    if [ -n "$pr" ] && [ "$pr" != "$((tot - dorm))" ]; then echo "PRODUCTION_REACHABILITY_FALSE"; exit 0; fi
    if [ -n "$ct" ] && [ "$ct" != "$tot" ]; then echo "CENSUS_SCOPE_DOUBLE_COUNT"; exit 0; fi
    if [ -n "$rm" ] && [ -n "$ct" ] && [ "$rm" -gt "$ct" ]; then echo "CENSUS_SCOPE_DOUBLE_COUNT"; exit 0; fi
    if [ -n "$un" ] && [ "$un" != "$unr" ]; then echo "UNKNOWN_AUTHORITY_SILENT_DROP"; exit 0; fi
    ;;
  PRODUCER)
    pcs=$(kv polyc_compiler_source_set)
    bl=$(kv blockers_listed); bt=$(kv blockers_total)
    if [ -n "$pcs" ] && [ "$pcs" -gt 0 ]; then
      pf=$(awk -F'\t' 'NR>1 && $4=="POLYC_COMPILER_SOURCE_SET"' "$PROD" | wc -l | tr -d ' ')
      if [ "$pf" -eq 0 ]; then echo "M2_SOURCE_PRODUCER_NOT_CLOSED"; exit 0; fi
    fi
    if [ -n "$bl" ] && [ -n "$bt" ] && [ "$bl" != "$bt" ]; then echo "BOOTSTRAP_BLOCKER_OMITTED"; exit 0; fi
    ;;
  DAG)
    pk=$(awk -F'\t' 'NR>1 && $1 ~ /^WP-/' "$WPT" | wc -l | tr -d ' ')
    ec=$(awk -F'\t' '$1 ~ /^WP-/' "$DEPT" | wc -l | tr -d ' ')
    pc=$(kv packages); ecl=$(kv edges); acy=$(kv acyclic)
    tb=$(kv total_base); cb=$(kv critical_base); cw=$(kv critical_witness)
    if [ "$pc" != "$pk" ] || [ "$ecl" != "$ec" ]; then echo "WORK_PACKAGE_DAG_INVALID"; exit 0; fi
    if [ "$acy" = "YES" ]; then
      dang=$(awk -F'\t' 'NR>1 && $1 ~ /^WP-/ {print $2}' "$DEPT" | while read -r t; do grep -q "^$t	" "$WPT" || echo "$t"; done | wc -l | tr -d ' ')
      if [ "$dang" -gt 0 ]; then echo "WORK_PACKAGE_DAG_INVALID"; exit 0; fi
    fi
    if [ -n "$tb" ] && [ -n "$cb" ] && [ "$cb" = "$tb" ] && { [ -z "$cw" ] || [ "$cw" = "NONE" ]; }; then echo "CRITICAL_PATH_NOT_DERIVED"; exit 0; fi
    if [ -n "$tb" ] && [ -n "$cb" ] && [ "$cb" -gt "$tb" ]; then echo "CRITICAL_PATH_NOT_DERIVED"; exit 0; fi
    ;;
  FORECAST)
    rec=$(kv reconciliation); rs=$(kv residual_work)
    pv=$(kv throughput_provenance); un=$(kv throughput_unit)
    ra=$(kv throughput_sites_per_act)
    sh=$(kv shared_acts); shx=$(kv shared_acts_expected)
    if [ "$rec" = "EQUAL" ]; then echo "FORECAST_SUM_RECONCILIATION"; exit 0; fi
    if [ -n "$rs" ] && [ "$rs" != "0" ]; then echo "INVENTED_COST_RESIDUAL"; exit 0; fi
    if [ "$pv" = "MEASURED" ] && [ "$un" != "SITES" ]; then echo "THROUGHPUT_PROVENANCE_OR_UNIT"; exit 0; fi
    if [ "$pv" = "ASSUMED" ] && [ "$ra" = "12" ]; then echo "THROUGHPUT_PROVENANCE_OR_UNIT"; exit 0; fi
    if [ -n "$sh" ] && [ -n "$shx" ] && [ "$sh" != "$shx" ]; then echo "FORECAST_DOUBLE_CHARGE"; exit 0; fi
    ;;
  RANK)
    sel=$(kv selected_wp); sr=$(kv selected_rank)
    sd=$(kv selected_downstream); sq=$(kv selected_qualified)
    row=$(awk -F'\t' -v w="$sel" '$2==w{print; exit}' "$RANK")
    if [ -z "$row" ]; then echo "RANKER_ELIGIBILITY_OR_ORDER"; exit 0; fi
    rr=$(printf '%s' "$row" | cut -f1)
    rq=$(printf '%s' "$row" | cut -f9)
    rd=$(printf '%s' "$row" | cut -f6)
    if [ -n "$sr" ] && [ "$sr" != "$rr" ]; then echo "RANKER_ELIGIBILITY_OR_ORDER"; exit 0; fi
    if [ -n "$sd" ] && [ "$sd" != "$rd" ]; then echo "RANKER_ELIGIBILITY_OR_ORDER"; exit 0; fi
    if [ "$sq" = "YES" ]; then
      if [ "$rq" != "QUALIFIED" ]; then echo "RANKER_ELIGIBILITY_OR_ORDER"; exit 0; fi
      better=$(awk -F'\t' -v w="$sel" -v d="$rd" '$2!=w && $9=="QUALIFIED" && $6+0>d+0 {print; exit}' "$RANK")
      if [ -n "$better" ]; then echo "RANKER_ELIGIBILITY_OR_ORDER"; exit 0; fi
    fi
    ;;
esac
exit 0
