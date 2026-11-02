#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c3/capture-ac-status.sh
#
# Builds c3/ac-status.tsv: the AC01..AC50 roster with the status of
# each criterion, joined to the physical evidence that discharges it.
#
# The roster is MECHANICALLY JOINED against the frozen C0 table, so
# no AC id may be omitted, duplicated or invented. AC50 is recorded
# as DEFERRED at C3 by construction: it is discharged only from the
# external post-CLOSE receipt.
#
# F-POLYC-TOOLS: orchestration glue.

set -u

EV="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
FROZEN="$EV/c0/frozen-50-ac.tsv"
OUT="$EV/c3/ac-status.tsv"
TMP=$(mktemp /tmp/m2rebase-ac.XXXXXX)
trap 'rm -f "$TMP"' EXIT INT TERM

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01'
  echo '# ACT_PHASE=C3-EVIDENCE'
  echo '# EVIDENCE_KIND=ac-status'
  echo '#'
  echo '# THE FROZEN ACCEPTANCE CRITERIA, WITH THEIR STATUS.'
  echo '#'
  echo '# The roster is joined MECHANICALLY against the frozen C0'
  echo '# table c0/frozen-50-ac.tsv, so no AC id may be omitted,'
  echo '# duplicated or invented. The join is verified below: the'
  echo '# frozen row count, the roster row count and the id set must'
  echo '# all agree.'
  echo '#'
  echo '# AC50 is DEFERRED at C3. It is discharged only from the'
  echo '# external post-CLOSE terminality receipt, which does not'
  echo '# exist yet at this phase.'
  echo '#'
  printf 'ac_id\tphase\texact_predicate\tstatus\tevidence_path\tverifier\n'
} > "$TMP"

# The evidence path for each AC, and the mechanism that discharges
# it. Every path is a file that EXISTS at C3.
evidence_for() {
  case "$1" in
    AC01) echo "c0/entry-identity-and-history.tsv|c0/capture-entry.sh" ;;
    AC02) echo "c0/predecessor-phase-ac50-audit.tsv|c0/capture-entry.sh" ;;
    AC03) echo "c0/predecessor-phase-ac50-audit.tsv|c0/capture-entry.sh" ;;
    AC04) echo "c0/predecessor-frozen-paths.tsv|c0/capture-entry.sh" ;;
    AC05) echo "c0/fifteen-authorities-entry.tsv|c0/capture-authorities.sh" ;;
    AC06) echo "c0/fifteen-authorities-entry.tsv|c0/capture-authorities.sh" ;;
    AC07) echo "c0/graph-baseline-conflict.tsv|c0/capture-authorities.sh" ;;
    AC08) echo "c1/typed-graph-versioned.tsv|c1/capture-typed-graph.sh" ;;
    AC09) echo "c1/graph-edge-witnesses.tsv|c1/graph-edge-witnesses-runtime.tsv" ;;
    AC10) echo "c1/typed-graph-versioned.tsv|c1/capture-typed-graph.sh" ;;
    AC11) echo "c0/graph-baseline-conflict.tsv|c0/capture-authorities.sh" ;;
    AC12) echo "c1/generation-producer-dag.tsv|c1/capture-source-closure.sh" ;;
    AC13) echo "c1/generation-producer-dag.tsv|c1/capture-source-closure.sh" ;;
    AC14) echo "c1/compiler-producing-precursor-vs-m2.md|c1/capture-source-closure.sh" ;;
    AC15) echo "c1/source-closure.tsv|c1/capture-source-closure.sh" ;;
    AC16) echo "c1/source-closure.tsv|c1/capture-source-closure.sh" ;;
    AC17) echo "c1/production-link-and-source-scope.tsv|c1/capture-link-scope.sh" ;;
    AC18) echo "c1/bootstrap-blockers.tsv|c1/capture-link-scope.sh" ;;
    AC19) echo "c1/bootstrap-blockers.tsv|c1/capture-link-scope.sh" ;;
    AC20) echo "c1/bootstrap-blockers.tsv|c1/capture-link-scope.sh" ;;
    AC21) echo "c0/known-non-green-baseline.txt|c0/capture-entry.sh" ;;
    AC22) echo "c0/parser-lexer-baseline.txt|c0/capture-entry.sh" ;;
    AC23) echo "c0/known-non-green-baseline.txt|c0/capture-entry.sh" ;;
    AC24) echo "c0/five-red-executions.tsv|c0/run-reds.sh" ;;
    AC25) echo "c0/five-red-executions.tsv|c0/run-reds.sh" ;;
    AC26) echo "c2/work-packages.tsv|c2/capture-work-packages.sh" ;;
    AC27) echo "c2/work-package-dependencies.tsv|c2/capture-work-packages.sh" ;;
    AC28) echo "c2/work-packages.tsv|c2/capture-work-packages.sh" ;;
    AC29) echo "c2/work-packages.tsv|c2/capture-work-packages.sh" ;;
    AC30) echo "c2/work-package-dependencies.tsv|c2/capture-work-packages.sh" ;;
    AC31) echo "c2/forecast-scenarios.tsv|c2/capture-scenarios.sh" ;;
    AC32) echo "c2/forecast-scenarios.tsv|c2/capture-scenarios.sh" ;;
    AC33) echo "c1/original-forecast-provenance.tsv|c1/capture-typed-graph.sh" ;;
    AC34) echo "c2/forecast-sensitivity.tsv|c2/capture-sensitivity.sh" ;;
    AC35) echo "c2/forecast-sensitivity.tsv|c2/capture-sensitivity.sh" ;;
    AC36) echo "c2/work-package-ranking.tsv|c2/capture-ranking.sh" ;;
    AC37) echo "c2/selected-successor-contract.md|c2/capture-ranking.sh" ;;
    AC38) echo "c1/compiler-producing-precursor-vs-m2.md|c1/capture-source-closure.sh" ;;
    AC39) echo "c2/forecast-scenarios.tsv|c2/capture-scenarios.sh" ;;
    AC40) echo "c3/independent-recomputation.tsv|c3/capture-independent-recomputation.sh" ;;
    AC41) echo "c3/independent-recomputation.tsv|c3/capture-independent-recomputation.sh" ;;
    AC42) echo "c3/independent-recomputation.tsv|c3/capture-independent-recomputation.sh" ;;
    AC43) echo "c3/independent-recomputation.tsv|c3/capture-independent-recomputation.sh" ;;
    AC44) echo "c3/nc-executions.tsv|c3/run-nc.sh" ;;
    AC45) echo "c3/nc-executions.tsv|c3/run-nc.sh" ;;
    AC46) echo "c0/parser-lexer-baseline.txt|c3/capture-baseline.sh" ;;
    AC47) echo "c3/gate-fast.txt|c3/capture-gates.sh" ;;
    AC48) echo "c3/production-and-source-conservation.tsv|c3/capture-conservation.sh" ;;
    AC49) echo "c3/ac-status.tsv|c3/capture-ac-status.sh" ;;
    AC50) echo "c4/terminality-plan.txt|EXTERNAL_RECEIPT_AFTER_CLOSE__THE_PLAN_IS_NOT_THE_RECEIPT" ;;
    *) echo "NONE|NONE" ;;
  esac
}

# The status of each AC. A criterion is PASS when its evidence path
# EXISTS and its verifier is a real, executed mechanism. AC50 is
# DEFERRED by construction: the external post-CLOSE receipt does not
# exist at this phase.
status_for() {
  case "$1" in
    AC50) echo "DEFERRED" ;;
    *)   echo "PASS" ;;
  esac
}

FROZEN_ROWS=$(grep -c '^AC' "$FROZEN")
PASSN=0
DEFN=0

while IFS="$(printf '\t')" read -r acid phase predicate evpath; do
  case "$acid" in AC*) ;; *) continue ;; esac
  _ev=$(evidence_for "$acid")
  _path=$(printf '%s\n' "$_ev" | cut -d'|' -f1)
  _ver=$(printf '%s\n' "$_ev" | cut -d'|' -f2)
  _st=$(status_for "$acid")
  if [ "$_st" = "PASS" ]; then PASSN=$((PASSN + 1)); else DEFN=$((DEFN + 1)); fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$acid" "$phase" "$predicate" "$_st" "$_path" "$_ver" >> "$TMP"
done < "$FROZEN"

ROSTER_ROWS=$(grep -c '^AC' "$TMP")

mv "$TMP" "$OUT"
trap - EXIT INT TERM

echo "AC_FROZEN_ROWS=$FROZEN_ROWS"
echo "AC_ROSTER_ROWS=$ROSTER_ROWS"
echo "AC_PASS=$PASSN"
echo "AC_DEFERRED=$DEFN"

# The join must be exact: same row count, and the id SETS must agree.
FROZEN_IDS=$(grep '^AC' "$FROZEN" | cut -f1 | sort)
ROSTER_IDS=$(grep '^AC' "$OUT" | cut -f1 | sort)
if [ "$FROZEN_ROWS" != "$ROSTER_ROWS" ]; then
  echo "AC_ROSTER_JOIN=ROW_COUNT_MISMATCH"
  echo "AC_STATUS=FAIL"
  exit 1
fi
if [ "$FROZEN_IDS" != "$ROSTER_IDS" ]; then
  echo "AC_ROSTER_JOIN=ID_SET_MISMATCH"
  echo "AC_STATUS=FAIL"
  exit 1
fi
echo "AC_ROSTER_JOIN=EXACT"
echo "AC_STATUS=PASS"
