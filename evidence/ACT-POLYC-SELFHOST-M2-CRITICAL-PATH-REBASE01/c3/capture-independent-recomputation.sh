#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c3/capture-independent-recomputation.sh
#
# Builds c3/independent-recomputation.tsv.
#
# Every row recomputes a C1 or C2 conclusion from the PRIMARY SOURCE
# ROWS and compares it with the primary value. The recomputation
# route differs from the route that produced the primary value:
#
#   the graph count   is recomputed from the CENSUS01 edges file
#                     while the primary value was computed by the
#                     C1 generator;
#   the SCC partition is recomputed from the archived scc-members
#                     table while the primary value was quoted from
#                     the CENSUS01 narrative;
#   the forecast      is recomputed from the archived verifier
#                     SOURCE, not from the archived forecast.tsv;
#   the DAG totals    are recomputed by the compiled PolyC verifier
#                     while the primary value was computed by the
#                     POSIX generator;
#   the ranking       is recomputed by a POSIX reachability walk
#                     while the primary value was computed by the
#                     C2 generator.
#
# A mismatch is a FAIL and is reported, never hidden.
#
# F-POLYC-TOOLS: orchestration glue.

set -u

EV="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
CENSUS="evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01"
OUT="$EV/c3/independent-recomputation.tsv"
TMP=$(mktemp /tmp/m2rebase-rc.XXXXXX)
trap 'rm -f "$TMP"' EXIT INT TERM

PASS=0
FAIL=0

row() {
  _id="$1"; _what="$2"; _rc="$3"; _pv="$4"; _match="$5"; _route="$6"
  if [ "$_match" = "YES" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_id" "$_what" "$_rc" "$_pv" "$_match" "$_route" \
    "c3/independent-recomputation.tsv" >> "$TMP"
}

cmp() {
  if [ "$1" = "$2" ]; then echo YES; else echo NO; fi
}

# --- RC01: the mandatory edge count, recomputed from the CENSUS01 file --
RC_MAND=$(awk -F'\t' 'NR>1 && $6=="YES"' "$CENSUS/c1/graph-edges.tsv" | wc -l | tr -d ' ')
PV_MAND=$(awk -F'\t' '/^E-/ && $6=="YES" {n++} END{print n+0}' "$EV/c1/typed-graph-versioned.tsv")
row RC01 "the BASE_GRAPH mandatory edge count" "$RC_MAND" "$PV_MAND" \
  "$(cmp "$RC_MAND" "$PV_MAND")" \
  "recomputed by awk over the CENSUS01 edges file, independently of the C1 generator"

# --- RC02: the raw edge count ------------------------------------------
RC_RAW=$(awk -F'\t' 'NR>1 && NF>1' "$CENSUS/c1/graph-edges.tsv" | wc -l | tr -d ' ')
PV_RAW=$(awk -F'\t' '/^E-/ {n++} END{print n+0}' "$EV/c1/typed-graph-versioned.tsv")
row RC02 "the BASE_GRAPH raw edge count" "$RC_RAW" "$PV_RAW" \
  "$(cmp "$RC_RAW" "$PV_RAW")" \
  "recomputed by awk over the CENSUS01 edges file"

# --- RC03: the SCC partition count, recomputed from the archived members -
RC_SCC=$(awk -F'\t' 'NR>1{c[$1]++} END{n=0;for(x in c)n++; print n}' "$CENSUS/c2/scc-members.tsv")
PV_SCC=34
row RC03 "the SCC partition count" "$RC_SCC" "$PV_SCC" \
  "$(cmp "$RC_SCC" "$PV_SCC")" \
  "recomputed by awk over the archived scc-members table"

# --- RC04: the largest SCC, recomputed ---------------------------------
RC_BIG=$(awk -F'\t' 'NR>1{c[$1]++} END{m=0;for(x in c){if(c[x]+0>m)m=c[x]+0}; print m}' "$CENSUS/c2/scc-members.tsv")
PV_BIG=19
row RC04 "the largest SCC size" "$RC_BIG" "$PV_BIG" \
  "$(cmp "$RC_BIG" "$PV_BIG")" \
  "recomputed by awk over the archived scc-members table"

# --- RC05: the archived M2 forecast, recomputed from the verifier SOURCE -
RC_M2=$(awk 'function ceil(x){return (x==int(x))?int(x):int(x)+1}
  BEGIN{
    split("2136 88 9",S," "); sb=0; sh=0; shlo=0;
    for(i=1;i<=3;i++){
      sites=S[i];
      impl=ceil(sites/12); if(impl<1)impl=1;
      integ=1; proof=1; corr=ceil((impl+integ)*44/100);
      base=1+impl+integ+proof+corr;
      if(i==1) base=ceil(base*125/100);
      sb+=base;
      li=ceil(sites/20); if(li<1)li=1;
      shlo+=1+li+1+1+ceil((li+1)*25/100);
      hi=ceil(sites/6); if(hi<1)hi=1;
      hv=1+hi+1+1+ceil((hi+1)*65/100); hv=ceil(hv*150/100); sh+=hv;
    }
    m1b=sb+3; m1l=shlo+2; m1h=sh+5;
    printf "%d/%d/%d", m1l+3+2, m1b+4+3, m1h+8+5;
  }')
PV_M2=$(awk -F'\t' '$1=="M2"{print $2"/"$3"/"$4}' "$CENSUS/c2/forecast.tsv")
row RC05 "the archived M2 forecast low/base/high" "$RC_M2" "$PV_M2" \
  "$(cmp "$RC_M2" "$PV_M2")" \
  "recomputed from the CENSUS01 verifier SOURCE formula, not from the archived forecast.tsv"

# --- RC06: the DAG totals, recomputed by the compiled PolyC verifier ---
DAGOUT=$(./build/m2-critical-path-rebase01-verify DAG "$EV/c2/work-packages.tsv" "$EV/c2/work-package-dependencies.tsv")
RC_TOT=$(printf '%s\n' "$DAGOUT" | sed -n 's/^DAG_TOTAL_EFFORT_LOW=\([0-9]*\).*/\1/p')
RC_TOT="$RC_TOT/$(printf '%s\n' "$DAGOUT" | sed -n 's/^DAG_TOTAL_EFFORT_BASE=\([0-9]*\).*/\1/p')/$(printf '%s\n' "$DAGOUT" | sed -n 's/^DAG_TOTAL_EFFORT_HIGH=\([0-9]*\).*/\1/p')"
PV_TOT=$(awk -F'\t' '$1=="S05"{print $3"/"$4"/"$5}' "$EV/c2/forecast-scenarios.tsv")
row RC06 "the S05 total effort low/base/high" "$RC_TOT" "$PV_TOT" \
  "$(cmp "$RC_TOT" "$PV_TOT")" \
  "recomputed by the compiled PolyC verifier, independently of the POSIX generator"

# --- RC07: the critical path, recomputed by the compiled PolyC verifier -
RC_CRIT=$(printf '%s\n' "$DAGOUT" | sed -n 's/^DAG_CRITICAL_PATH_ACTS=\([0-9]*\).*/\1/p')
PV_CRIT=$(awk -F'\t' '$1=="S05"{print $7}' "$EV/c2/forecast-scenarios.tsv")
row RC07 "the S05 critical path" "$RC_CRIT" "$PV_CRIT" \
  "$(cmp "$RC_CRIT" "$PV_CRIT")" \
  "recomputed by the compiled PolyC verifier"

# --- RC08: the critical path witness route ----------------------------
RC_ROUTE=$(printf '%s\n' "$DAGOUT" | sed -n 's/^DAG_CRITICAL_PATH_WITNESS=//p')
PV_ROUTE=$(awk -F'\t' '$1=="critical_witness"{print $2}' "$EV/c3/nc-states/dag-pristine.tsv")
row RC08 "the critical path witness route" "$RC_ROUTE" "$PV_ROUTE" \
  "$(cmp "$RC_ROUTE" "$PV_ROUTE")" \
  "recomputed by the compiled PolyC verifier"

# --- RC09: the selected package's downstream reachability --------------
#
# The route here is INDEPENDENT of the C2 generator's breadth-first
# walk: it computes the transitive closure by ITERATED RELAXATION
# over the adjacency relation and then counts the reachable set.
RC_DOWN=$(awk -F'\t' '
  $1 ~ /^WP-/ { adj[$1] = adj[$1] " " $2; nodes[$1] = 1; nodes[$2] = 1 }
  END {
    # reach[a,b] is 1 when b is reachable from a.
    for (a in nodes) {
      n = split(adj[a], lst, " ")
      for (i = 1; i <= n; i++) {
        if (lst[i] != "") reach[a, lst[i]] = 1
      }
    }
    # Iterate the closure to a fixed point.
    changed = 1
    while (changed) {
      changed = 0
      for (a in nodes) {
        for (b in nodes) {
          if (reach[a, b]) continue
          for (c in nodes) {
            if (reach[a, c] && reach[c, b]) { reach[a, b] = 1; changed = 1; break }
          }
        }
      }
    }
    count = 0
    for (b in nodes) { if (reach["WP-001", b]) count++ }
    print count
  }' "$EV/c2/work-package-dependencies.tsv")
PV_DOWN=$(awk -F'\t' '$2=="WP-001"{print $6}' "$EV/c2/work-package-ranking.tsv")
row RC09 "the selected package's downstream reachability" "$RC_DOWN" "$PV_DOWN" \
  "$(cmp "$RC_DOWN" "$PV_DOWN")" \
  "recomputed by transitive closure over the adjacency relation, independently of the C2 breadth-first walk"

# --- RC10: the selected package's authority rows -----------------------
RC_AUTH=$(awk -F'\t' '$1=="WP-001"{s+=$5} END{print s+0}' "$EV/c1/current-authority-join.tsv")
PV_AUTH=$(awk -F'\t' '$2=="WP-001"{print $5}' "$EV/c2/work-package-ranking.tsv")
row RC10 "the selected package's authority row count" "$RC_AUTH" "$PV_AUTH" \
  "$(cmp "$RC_AUTH" "$PV_AUTH")" \
  "recomputed by awk over the C1 authority join"

# --- RC11: the authority population ------------------------------------
RC_POP=$(awk -F'\t' 'NR>1 && NF>1' "$CENSUS/c1/authorities.tsv" | wc -l | tr -d ' ')
PV_POP=2233
row RC11 "the CENSUS01 authority population" "$RC_POP" "$PV_POP" \
  "$(cmp "$RC_POP" "$PV_POP")" \
  "recomputed by awk over the CENSUS01 authority table"

# --- RC12: the PolyC authority population ------------------------------
RC_POLYC=$(awk -F'\t' 'NR>1 && toupper($4)=="POLYC"' "$CENSUS/c1/authorities.tsv" | wc -l | tr -d ' ')
PV_POLYC=$(awk -F'\t' '$1=="polyc_authority_count"{print $2}' "$EV/c3/nc-states/authority-pristine.tsv")
row RC12 "the PolyC authority count" "$RC_POLYC" "$PV_POLYC" \
  "$(cmp "$RC_POLYC" "$PV_POLYC")" \
  "recomputed by awk over the CENSUS01 authority table"

# --- RC13: the dormant site population ---------------------------------
RC_DORM=$(awk -F'\t' 'NR>1 && NF>1' "$CENSUS/c1/dormant-polyc-sites.tsv" | wc -l | tr -d ' ')
PV_DORM=6
row RC13 "the dormant PolyC site count" "$RC_DORM" "$PV_DORM" \
  "$(cmp "$RC_DORM" "$PV_DORM")" \
  "recomputed by awk over the CENSUS01 dormant site table"

# --- RC14: the unknown-bearing edge population --------------------------
RC_UNK=$(awk -F'\t' 'NR>1 && NF>1 && $1 ~ /^U-/' "$CENSUS/c1/unknown-edges.tsv" | wc -l | tr -d ' ')
PV_UNK=$(awk -F'\t' '$1=="unknown_rows"{print $2}' "$EV/c3/nc-states/authority-pristine.tsv")
row RC14 "the unknown-bearing edge count" "$RC_UNK" "$PV_UNK" \
  "$(cmp "$RC_UNK" "$PV_UNK")" \
  "recomputed by awk over the CENSUS01 unknown-edge table"

# --- RC15: the historical displayed-sum delta ---------------------------
RC_DISP=$(awk -F'\t' '$1=="M2"{s=0;for(i=5;i<=10;i++)s+=$i;print s}' "$CENSUS/c2/forecast.tsv")
RC_TOT2=$(awk -F'\t' '$1=="M2"{print $11}' "$CENSUS/c2/forecast.tsv")
PV_DELTA=$((RC_TOT2 - RC_DISP))
row RC15 "the historical displayed-sum delta" "$PV_DELTA" "65" \
  "$(cmp "$PV_DELTA" "65")" \
  "recomputed by awk over the archived forecast.tsv"

mv "$TMP" "$OUT"
trap - EXIT INT TERM

echo "RECOMPUTATION_CHECKS=$((PASS + FAIL))"
echo "RECOMPUTATION_MATCH=$PASS"
echo "RECOMPUTATION_MISMATCH=$FAIL"
echo "RECOMPUTATION_WRITTEN=$OUT"
if [ "$FAIL" -ne 0 ]; then
  echo "RECOMPUTATION_STATUS=FAIL"
  exit 1
fi
echo "RECOMPUTATION_STATUS=PASS"
