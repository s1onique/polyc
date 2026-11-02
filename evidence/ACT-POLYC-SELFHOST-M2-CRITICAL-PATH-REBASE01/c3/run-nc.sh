#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c3/run-nc.sh
#
# ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01 C3 EVIDENCE.
#
# EXECUTES THE TWENTY-FOUR FROZEN ADVERSARIAL CONTROLS as real
# pristine -> adverse -> restored cycles against the COMPILED PolyC
# detector (build/m2-critical-path-rebase01-nc), and against an
# INDEPENDENT POSIX witness that shares NO CODE with the PolyC
# detector.
#
# For each NC:
#   PRISTINE  the true state must be ACCEPTED (exit 0, SILENT)
#   ADVERSE   the mutated state must be REJECTED with its OWN reason
#             token and a NON-ZERO exit
#   RESTORED  the true state must be ACCEPTED AGAIN
#
# The ADVERSE runs use an ISOLATED COPY of the state file. The
# repository's own state files are NEVER mutated. The restoration is
# proven byte-identically by digesting the state file before and after
# the whole cycle.
#
# Every adverse mutation changes a SOURCE FACT, never a verdict
# label. That is what makes the control sensitive.
#
# F-POLYC-TOOLS: the DETECTOR is compiled PolyC. This script is
# orchestration glue only; it computes no conclusion of its own.

set -u

EV="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
D="build/m2-critical-path-rebase01-nc"
W="$EV/c3/nc-witness.sh"
C="$EV/c3/nc-states"
OUT="$EV/c3/nc-executions.tsv"
TMP=$(mktemp -d /tmp/m2rebase-nc.XXXXXX)
trap 'rm -rf "$TMP"' EXIT INT TERM

if [ ! -x "$D" ]; then
  echo "NC_HARNESS_ERROR=detector_not_built_at_$D" >&2
  exit 3
fi

CENSUS="evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01"
EDGES="$CENSUS/c1/graph-edges.tsv"
AUTHS="$CENSUS/c1/authorities.tsv"
UNK="$CENSUS/c1/unknown-edges.tsv"
DORM="$CENSUS/c1/dormant-polyc-sites.tsv"
PROD="$EV/c1/generation-producer-dag.tsv"
WPT="$EV/c2/work-packages.tsv"
DEPT="$EV/c2/work-package-dependencies.tsv"
SCEN="$EV/c2/forecast-scenarios.tsv"
HIST="$CENSUS/c2/forecast.tsv"
RANK="$EV/c2/work-package-ranking.tsv"

# The detector command for a mode, and the witness command.
detector_cmd() {
  case "$1" in
    IDENTITY) echo "$D IDENTITY" ;;
    GRAPH)    echo "$D GRAPH $EDGES" ;;
    AUTHORITY) echo "$D AUTHORITY $AUTHS $UNK $DORM" ;;
    PRODUCER) echo "$D PRODUCER $PROD" ;;
    DAG)      echo "$D DAG $WPT $DEPT" ;;
    FORECAST) echo "$D FORECAST $SCEN $HIST" ;;
    RANK)     echo "$D RANK $RANK" ;;
  esac
}

NC_TOTAL=0
NC_SENSITIVE=0
NC_FAILED=0

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01'
  echo '# ACT_PHASE=C3-EVIDENCE'
  echo '# EVIDENCE_KIND=nc-executions'
  echo '#'
  echo '# THE TWENTY-FOUR FROZEN ADVERSARIAL CONTROLS, EXECUTED.'
  echo '#'
  echo '# Every control is a PRISTINE -> ADVERSE -> RESTORED cycle:'
  echo '#   PRISTINE  the true state must be ACCEPTED (exit 0, SILENT)'
  echo '#   ADVERSE   the mutated state must be REJECTED with its OWN'
  echo '#             reason token and a NON-ZERO exit'
  echo '#   RESTORED  the true state must be ACCEPTED AGAIN'
  echo '#'
  echo '# A changed PASS LABEL is not a qualifying adverse mutation.'
  echo '# Every adverse run mutates a SOURCE FACT, not a verdict.'
  echo '#'
  echo '# The detector is the COMPILED PolyC checker'
  echo '#   build/m2-critical-path-rebase01-nc'
  echo '# and an INDEPENDENT POSIX witness shares NO CODE with it.'
  echo '#'
  printf 'nc_id\tphase\tdetector\tadverse_mutation\texit_code\treason_token\tsource_fact_mutated\tinput_digest\trestored_digest\trestored_identical\tevidence\n'
} > "$TMP/nc-executions.tsv"

# run_cycle <nc_id> <mode> <pristine_state> <adverse_state> <expected_reason> <mutation_desc>
#
# The adverse state is a SEPARATE file. The pristine file is never
# written to. The restoration is proven by digesting the pristine
# file before and after the whole cycle.
run_cycle() {
  _id="$1"; _mode="$2"; _pris="$3"; _adv="$4"; _exp="$5"; _desc="$6"
  NC_TOTAL=$((NC_TOTAL + 1))

  _dig_before=$(shasum -a 256 "$_pris" | cut -d' ' -f1)
  _adv_dig=$(shasum -a 256 "$_adv" | cut -d' ' -f1)
  _dcmd=$(detector_cmd "$_mode")

  # PRISTINE: must be accepted.
  _pout=$($_dcmd "$_pris" 2>&1); _prc=$?
  if [ "$_prc" -ne 0 ] || [ -n "$_pout" ]; then
    NC_FAILED=$((NC_FAILED + 1))
    printf 'NC_PRISTINE_NOT_ACCEPTED %s rc=%s out=%s\n' "$_id" "$_prc" "$_pout" >&2
  fi

  # ADVERSE: must be rejected with its OWN reason token.
  _aout=$($_dcmd "$_adv" 2>&1); _arc=$?
  _areason=$(printf '%s\n' "$_aout" | sed -n 's/^REASON=//p' | head -1)
  _wout=$(sh "$W" "$_mode" "$_adv" 2>&1)
  _wreason=$(printf '%s\n' "$_wout" | head -1)

  _ok=1
  if [ "$_arc" -eq 0 ]; then _ok=0; fi
  if [ "$_areason" != "$_exp" ]; then _ok=0; fi
  if [ "$_wreason" != "$_exp" ]; then _ok=0; fi

  # RESTORED: the pristine state must be accepted again.
  _rout=$($_dcmd "$_pris" 2>&1); _rrc=$?
  _dig_after=$(shasum -a 256 "$_pris" | cut -d' ' -f1)
  _same=NO
  if [ "$_dig_before" = "$_dig_after" ]; then _same=YES; else _ok=0; fi
  if [ "$_rrc" -ne 0 ] || [ -n "$_rout" ]; then _ok=0; fi

  if [ "$_ok" -eq 1 ]; then NC_SENSITIVE=$((NC_SENSITIVE + 1)); else NC_FAILED=$((NC_FAILED + 1)); fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\tYES\t%s\t%s\t%s\t%s\n' \
    "$_id" "$_mode" "$(basename "$_dcmd" | cut -d' ' -f1)" "$_desc" \
    "$_arc" "$_areason" "$_adv_dig" "$_dig_after" "$_same" \
    "$_id detector=$_dcmd witness=nc-witness.sh $_mode" >> "$TMP/nc-executions.tsv"

  printf '%s %s rc=%s reason=%s witness=%s restored=%s\n' \
    "$_id" "$_ok" "$_arc" "$_areason" "$_wreason" "$_same"
}

# mutate <src> <dst> <key> <newvalue>
#
# Writes an ISOLATED copy of the state with ONE key changed. The
# source file is never written to.
mutate() {
  awk -F'\t' -v k="$3" -v v="$4" 'BEGIN{OFS="\t"} $1==k{$2=v} {print}' "$1" > "$2"
}

# --- NC01: forge the predecessor identity ------------------------------
mutate "$C/identity-pristine.tsv" "$TMP/nc01.tsv" predecessor_head 0000000000000000000000000000000000000000
run_cycle NC01 IDENTITY "$C/identity-pristine.tsv" "$TMP/nc01.tsv" \
  ENTRY_OR_PREDECESSOR_IDENTITY \
  "the predecessor_head is forged to a commit that is not the predecessor terminal"

# --- NC02: an invented five-phase predecessor chronology ---------------
mutate "$C/identity-pristine.tsv" "$TMP/nc02.tsv" predecessor_range 5
run_cycle NC02 IDENTITY "$C/identity-pristine.tsv" "$TMP/nc02.tsv" \
  FALSE_PHASE_OR_AC50_TERMINALITY \
  "the predecessor range is inflated from its actual 4 commits to an invented 5"

# --- NC03: an unbound external terminality receipt ----------------------
mutate "$C/identity-pristine.tsv" "$TMP/nc03.tsv" receipt_bound_head 1111111111111111111111111111111111111111
run_cycle NC03 IDENTITY "$C/identity-pristine.tsv" "$TMP/nc03.tsv" \
  MISBOUND_EXTERNAL_TERMINALITY \
  "the external receipt is claimed to be bound to a HEAD that is not this ACT's HEAD"

# --- NC04: a frozen historical artifact modified or a bad SHA accepted --
# The F14 blob check is performed against the real frozen paths; the
# state records the digest the ACT believes each frozen artifact has.
mutate "$C/identity-pristine.tsv" "$TMP/nc04.tsv" frozen_artifact_sha256 0000000000000000000000000000000000000000000000000000000000000000
run_cycle NC04 IDENTITY "$C/identity-pristine.tsv" "$TMP/nc04.tsv" \
  HISTORICAL_F14_BLOB_MISMATCH \
  "the recorded digest of a frozen historical artifact is replaced with a bad SHA"

# --- NC05: CSET counted as the sixteenth PolyC authority ---------------
mutate "$C/authority-pristine.tsv" "$TMP/nc05.tsv" polyc_authority_count 10
run_cycle NC05 AUTHORITY "$C/authority-pristine.tsv" "$TMP/nc05.tsv" \
  MECHANICAL_ADAPTER_MISCOUNT \
  "the CSET mechanical adapter is counted as a PolyC authority, raising the count to 10"

# --- NC06: an inactive authority counted as production-reachable -------
mutate "$C/authority-pristine.tsv" "$TMP/nc06.tsv" production_reachable 2233
run_cycle NC06 AUTHORITY "$C/authority-pristine.tsv" "$TMP/nc06.tsv" \
  PRODUCTION_REACHABILITY_FALSE \
  "every authority row, including the 8 that are not production-reachable, is counted as reachable"

# --- NC07: the census denominator double-counted -----------------------
mutate "$C/authority-pristine.tsv" "$TMP/nc07.tsv" census_total 2242
run_cycle NC07 AUTHORITY "$C/authority-pristine.tsv" "$TMP/nc07.tsv" \
  CENSUS_SCOPE_DOUBLE_COUNT \
  "the census denominator is inflated by 9, double-counting the historical PolyC authorities"

# --- NC08: an unknown-bearing row dropped from the denominator ---------
mutate "$C/authority-pristine.tsv" "$TMP/nc08.tsv" unknown_rows 3
run_cycle NC08 AUTHORITY "$C/authority-pristine.tsv" "$TMP/nc08.tsv" \
  UNKNOWN_AUTHORITY_SILENT_DROP \
  "one of the 4 unknown-bearing edge rows is silently dropped from the denominator"

# --- NC09: the graph scope aliased to a non-BASE scope -----------------
mutate "$C/graph-pristine.tsv" "$TMP/nc09.tsv" graph_scope SHADOW
run_cycle NC09 GRAPH "$C/graph-pristine.tsv" "$TMP/nc09.tsv" \
  GRAPH_VERSION_ALIAS \
  "the BASE_GRAPH mandatory total is compared against the SHADOW scope"

# --- NC10: a shadow cut claimed as a production cut --------------------
mutate "$C/graph-pristine.tsv" "$TMP/nc10a.tsv" shadow_cuts E-TYP-0136
mutate "$TMP/nc10a.tsv" "$TMP/nc10.tsv" production_cuts E-TYP-0136
run_cycle NC10 GRAPH "$C/graph-pristine.tsv" "$TMP/nc10.tsv" \
  SHADOW_PRODUCTION_CUT_CONFLATION \
  "the shadow-only cut E-TYP-0136 is also claimed as a production cut"

# --- NC11: header inclusion claimed as a proven mandatory edge ---------
mutate "$C/graph-pristine.tsv" "$TMP/nc11.tsv" proven_mandatory_layout YES
run_cycle NC11 GRAPH "$C/graph-pristine.tsv" "$TMP/nc11.tsv" \
  LAYOUT_OBSERVATION_AS_MANDATORY \
  "a TYPE_REPRESENTATION edge whose only evidence is a header inclusion is claimed as a proven mandatory runtime dependency"

# --- NC12: availability CALLS edges counted as migration-order ---------
mutate "$C/graph-pristine.tsv" "$TMP/nc12.tsv" migration_order_edges 103
run_cycle NC12 GRAPH "$C/graph-pristine.tsv" "$TMP/nc12.tsv" \
  CALL_EDGE_SCOPE_CONFUSION \
  "the 103 availability-only CALLS edges are counted as migration-order edges"

# --- NC13: a mandatory edge dropped while the graph still passes -------
mutate "$C/graph-pristine.tsv" "$TMP/nc13.tsv" mandatory_edges 134
run_cycle NC13 GRAPH "$C/graph-pristine.tsv" "$TMP/nc13.tsv" \
  GRAPH_VERSION_ALIAS \
  "the mandatory edge count is dropped from 135 to the historical narrative 134"

# --- NC14: two different SCC member lists both claimed -----------------
mutate "$C/graph-pristine.tsv" "$TMP/nc14.tsv" scc_members_b 'SYS-A;SYS-C'
run_cycle NC14 GRAPH "$C/graph-pristine.tsv" "$TMP/nc14.tsv" \
  SCC_PARTITION_MISMATCH \
  "two different SCC member lists are both claimed as the partition"

# --- NC15: the C-rooted stage0 asserted to satisfy genuine M2 ----------
mutate "$C/producer-pristine.tsv" "$TMP/nc15.tsv" polyc_compiler_source_set 12
run_cycle NC15 PRODUCER "$C/producer-pristine.tsv" "$TMP/nc15.tsv" \
  M2_SOURCE_PRODUCER_NOT_CLOSED \
  "the 12 PolyC helper subjects are asserted to be a PolyC-authored compiler source set"

# --- NC16: an actual PolyC language-feature blocker omitted ------------
mutate "$C/producer-pristine.tsv" "$TMP/nc16.tsv" blockers_listed 7
run_cycle NC16 PRODUCER "$C/producer-pristine.tsv" "$TMP/nc16.tsv" \
  BOOTSTRAP_BLOCKER_OMITTED \
  "the blocker list omits the RES-04 unsupported-grammar blocker"

# --- NC17: a dangling work-package dependency accepted as a DAG --------
mutate "$C/dag-pristine.tsv" "$TMP/nc17.tsv" edges 38
run_cycle NC17 DAG "$C/dag-pristine.tsv" "$TMP/nc17.tsv" \
  WORK_PACKAGE_DAG_INVALID \
  "an extra dependency edge is claimed while the edge count no longer matches the table"

# --- NC18: the critical path equated with the total --------------------
mutate "$C/dag-pristine.tsv" "$TMP/nc18.tsv" critical_base 121
mutate "$TMP/nc18.tsv" "$TMP/nc18b.tsv" critical_witness NONE
run_cycle NC18 DAG "$C/dag-pristine.tsv" "$TMP/nc18b.tsv" \
  CRITICAL_PATH_NOT_DERIVED \
  "the critical path is set equal to the total effort and the path witness is removed"

# --- NC19: the historical 290 accepted as equal to the reported 355 ----
mutate "$C/forecast-pristine.tsv" "$TMP/nc19.tsv" reconciliation EQUAL
run_cycle NC19 FORECAST "$C/forecast-pristine.tsv" "$TMP/nc19.tsv" \
  FORECAST_SUM_RECONCILIATION \
  "the archived displayed category sum of 290 is accepted as equal to the reported total of 355"

# --- NC20: the missing 65 introduced as fictional future work ----------
mutate "$C/forecast-pristine.tsv" "$TMP/nc20.tsv" residual_work 65
run_cycle NC20 FORECAST "$C/forecast-pristine.tsv" "$TMP/nc20.tsv" \
  INVENTED_COST_RESIDUAL \
  "the 65-ACT discrepancy is carried as a residual work item with no source-bound basis"

# --- NC21: the assumed 12 sites/ACT presented as measured --------------
mutate "$C/forecast-pristine.tsv" "$TMP/nc21.tsv" throughput_provenance ASSUMED
mutate "$TMP/nc21.tsv" "$TMP/nc21b.tsv" throughput_sites_per_act 12
run_cycle NC21 FORECAST "$C/forecast-pristine.tsv" "$TMP/nc21b.tsv" \
  THROUGHPUT_PROVENANCE_OR_UNIT \
  "the archived assumed 12 sites-per-ACT rate is presented with measured provenance"

# --- NC22: the shared infrastructure ACT charged to several packages ---
mutate "$C/forecast-pristine.tsv" "$TMP/nc22.tsv" shared_acts 36
run_cycle NC22 FORECAST "$C/forecast-pristine.tsv" "$TMP/nc22.tsv" \
  FORECAST_DOUBLE_CHARGE \
  "the shared infrastructure and correction reserve is charged twice, at 36 instead of 18"

# --- NC23: a convenient classifier promoted ahead of the blocker -------
mutate "$C/rank-pristine.tsv" "$TMP/nc23.tsv" selected_wp WP-006
run_cycle NC23 RANK "$C/rank-pristine.tsv" "$TMP/nc23.tsv" \
  RANKER_ELIGIBILITY_OR_ORDER \
  "the CONTAINERS package is promoted ahead of the DRIVER, which has 19 downstream packages against its 4"

# --- NC24: AC50 discharged before the CLOSE exists ----------------------
mutate "$C/identity-pristine.tsv" "$TMP/nc24.tsv" ac50_discharged YES
mutate "$TMP/nc24.tsv" "$TMP/nc24b.tsv" close_count 0
run_cycle NC24 IDENTITY "$C/identity-pristine.tsv" "$TMP/nc24b.tsv" \
  AC_NC_OR_TERMINALITY_FALSE_PASS \
  "AC50 is claimed discharged while the ACT has no CLOSE commit"

cp "$TMP/nc-executions.tsv" "$OUT"
rm -rf "$TMP" 2>/dev/null || true

echo "NC_TOTAL=$NC_TOTAL"
echo "NC_SENSITIVE=$NC_SENSITIVE"
echo "NC_FAILED=$NC_FAILED"
echo "NC_EXECUTIONS_WRITTEN=$OUT"
if [ "$NC_FAILED" -ne 0 ]; then
  echo "NC_MODE_STATUS=FAIL"
  exit 1
fi
echo "NC_MODE_STATUS=PASS"
