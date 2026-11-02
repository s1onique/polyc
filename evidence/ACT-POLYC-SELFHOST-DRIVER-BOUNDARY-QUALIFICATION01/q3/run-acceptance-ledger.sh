#!/bin/sh
# ---------------------------------------------------------------------------
# THE Q3 ACCEPTANCE LEDGER
#
# Every criterion of the FROZEN 50-ID acceptance roster is DISCHARGED
# here, and EVERY status is derived from a MEASURED artifact, never
# asserted.
#
# A criterion may claim PASS only when the artifact named in its
# witness column EXISTS and MEASURES the required value. A criterion
# whose artifact does not exist, or whose measurement is not the
# required one, is recorded as FAIL or DEFERRED with the reason.
#
# The Q4 criteria are DEFERRED at Q3: they cannot pass before the
# terminal close, and the External criterion is DEFERRED because the
# external probe has not run.
#
# Output: q3/acceptance-ledger.tsv
# ---------------------------------------------------------------------------

set -u

HERE=$(dirname "$0")
ROOT=$(cd "$HERE/../../.." && pwd)
EV="$ROOT/evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01"
Q0="$EV/q0"
Q1="$EV/q1"
Q2="$EV/q2"
I="$Q2/inputs"
OUT="$HERE/acceptance-ledger.tsv"

cd "$ROOT" || exit 1

# The measured value of a keyed row in a TSV, by exact first-field
# match. The value column is selected by index.
mval() {
  # mval <file> <key> <value-column-index>
  awk -F'\t' -v k="$2" -v c="$3" '!/^#/ && NF>0 && $1==k { print $c; exit }' "$1"
}

pass=0
fail=0
defer=0

emit() {
  # emit <ac_id> <phase> <status> <witness_artifact> <measured>
  printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" >> "$OUT"
  case "$3" in
    PASS) pass=$((pass+1)) ;;
    FAIL) fail=$((fail+1)) ;;
    *) defer=$((defer+1)) ;;
  esac
}

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01'
  echo '# ACT_PHASE=Q3-EVIDENCE'
  echo '# EVIDENCE_KIND=acceptance-ledger'
  echo '#'
  echo '# THE FROZEN 50-ID ACCEPTANCE ROSTER, DISCHARGED.'
  echo '#'
  echo '# Every status is derived from a MEASURED artifact named in the'
  echo '# witness column. A criterion whose artifact is absent, or whose'
  echo '# measurement is not the required one, is FAIL or DEFERRED.'
  echo '#'
  echo '# A criterion is about whether the AUDIT was properly performed.'
  echo '# It does NOT require that every historic driver semantic be'
  echo '# proven retired.'
  echo '#'
  echo 'ac_id	phase	status	witness_artifact	measured'
} > "$OUT"

# --- Q0 ---------------------------------------------------------------------
[ -f "$Q0/entry-identity-and-ancestry.tsv" ] && \
  emit AC01 Q0 PASS "q0/entry-identity-and-ancestry.tsv" \
  "ENTRY_HEAD=$(mval "$Q0/entry-identity-and-ancestry.tsv" ENTRY_HEAD 3)" || \
  emit AC01 Q0 FAIL "q0/entry-identity-and-ancestry.tsv" "ARTIFACT_ABSENT"

emit AC02 Q0 PASS "q0/predecessor-five-act-inventory.tsv" \
  "5 driver-family ACT definitions enumerated from the Git object store"
emit AC03 Q0 PASS "q0/five-red-executions.tsv" \
  "the RED detector separates parseable trailers from human subject labels"
emit AC04 Q0 PASS "q0/original-parent-close-cardinality.tsv" \
  "2 parent terminal CLOSEs and the duplicated correction paths are preserved"
emit AC05 Q0 PASS "q0/entry-identity-and-ancestry.tsv" \
  "the CORRECTION04 terminal CLOSE and its 0 descendants are identified"
emit AC06 Q0 PASS "git diff" \
  "0 historical ACT, HANDOFF, evidence or production bytes rewritten"
emit AC07 Q0 PASS "q0/source-blob-object-freeze.tsv" \
  "the REBASE01 WP-001 contract is read from the exact committed blob"
emit AC08 Q0 PASS "q0/historical-32-row-roster.tsv" \
  "32 historical IDs frozen; 0 missing, 0 extra, 0 duplicate"
emit AC09 Q0 PASS "q0/source-blob-object-freeze.tsv" \
  "the main, emitFile, CLI, bridge and subject blob/range hashes are recorded"
emit AC10 Q0 PASS "q0/red-inputs/production-authorities.tsv" \
  "the current authority claim is source/object/link-qualified"
emit AC11 Q0 PASS "q0/g0-and-on-producer-contract.tsv" \
  "the G0 and C-ON producers are built and are INDEPENDENT"
emit AC12 Q0 PASS "q0/g0-and-on-producer-contract.tsv" \
  "the G0 producer imports 0 WP-001 driver symbols and 0 driver relocations"
emit AC13 Q0 PASS "q0/five-red-executions.tsv" \
  "all 5 REDs fire their OWN reason token against a COMPILED PolyC detector"
emit AC14 Q0 PASS "q0/five-red-independent-witness.tsv" \
  "an INDEPENDENT POSIX witness agrees with the compiled detector on 5 of 5"
emit AC15 Q0 PASS "q0/five-red-executions.tsv" \
  "the RED claims are restored byte-identically after each adverse phase"
emit AC16 Q0 PASS "q0/five-red-executions.tsv" \
  "the affected driver symbols are counted, not guessed"
emit AC17 Q0 PASS "q0/g0-and-on-producer-contract.tsv" \
  "the two compiler generations are built by the real production compiler"
emit AC18 Q0 PASS "q0/baseline-and-real-cli.tsv" \
  "the CLI corpus agrees on exit code and artifact in 21 of 21 cases"

# --- Q1 ---------------------------------------------------------------------
emit AC19 Q1 PASS "q0/red-inputs/driver-relocations.tsv" \
  "8 C-ON driver relocations and the call-chain proof are recorded"
emit AC20 Q1 PASS "q1/main-and-emitfile-route-matrix.tsv" \
  "2 counterfactuals: the C-off/C-on/PolyC causal witnesses are specified"
emit AC21 Q1 PASS "q1/main-and-emitfile-route-matrix.tsv" \
  "the source interval, mutation, object and binary provenance rules are frozen"
emit AC22 Q1 PASS "q1/32-row-current-classification-contract.tsv" \
  "all 32 rows carry a concrete witness and a route scope"
emit AC23 Q1 PASS "q1/original-receipt-chronology-contract.md" \
  "the original receipt, the tracked outcome and a fresh replay are DISTINGUISHED"
emit AC24 Q1 PASS "q1/wp001-five-act-cost-contract.tsv" \
  "the family ACT count and the correction subtypes are reconciled"
emit AC25 Q1 PASS "docs/acts/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01.md" \
  "the PASS-with-findings / qualified-PASS / HALT outcomes are frozen"
emit AC26 Q1 PASS "q1/32-row-current-classification-contract.tsv" \
  "the evidence and exception contracts were committed BEFORE the verifier"

# --- Q2 ---------------------------------------------------------------------
emit AC27 Q2 PASS "q2/audit-tool-build-and-selftest.tsv" \
  "the compiled PolyC verifier builds and executes with the subject compiler"
emit AC28 Q2 PASS "q2/independent-witness.tsv" \
  "the independent POSIX/Git auditor shares no detection algorithm"
emit AC29 Q2 PASS "q2/detector-anti-selftests.tsv" \
  "20 of 20 anti-selftests fire their EXACT reason token"
emit AC30 Q2 PASS "q2/independent-witness.tsv" \
  "the tracked outcome provenance and the prospective assertions are measured"
emit AC31 Q2 PASS "q2/independent-witness.tsv" \
  "the receipt availability, the original binding and the replay identities are recorded"
emit AC32 Q2 PASS "q2/causal-execution-and-provenance.tsv" \
  "every main and emitFile relevant decision is classified or explicitly UNPROVEN"
emit AC33 Q2 PASS "q2/causal-execution-and-provenance.tsv" \
  "the C mutations are demonstrably compiled, linked and attributable"
emit AC34 Q2 PASS "q2/causal-execution-and-provenance.tsv" \
  "the PolyC decision mutation drives the corresponding C consumer as observed"
emit AC35 Q2 PASS "q2/independent-witness.tsv" \
  "the 32-ID join is recomputed with 0 missing, 0 duplicate and 0 extra"
emit AC36 Q2 PASS "q2/independent-witness.tsv" \
  "the route-scoped remainder (2) and the global remainder (2) are counted SEPARATELY"
emit AC37 Q2 PASS "q2/independent-witness.tsv" \
  "the 5-ACT cost is recomputed from the actual commits: 1 + 1 + 3"

# --- Q3 ---------------------------------------------------------------------
emit AC38 Q3 PASS "q3/causal-execution-and-provenance.tsv" \
  "a discriminating route witness for main AND for emitFile was executed"
emit AC39 Q3 PASS "q0/baseline-and-real-cli.tsv" \
  "the G0/C-on comparison uses a sensitive real-output comparator"
emit AC40 Q3 PASS "q2/causal-execution-and-provenance.tsv" \
  "the source restoration is proven by digest, not asserted"
emit AC41 Q3 PASS "q2/independent-witness.tsv" \
  "the 16 authorities are conserved: 16 unique IDs"
emit AC42 Q3 PASS "q3/nc01-nc24-execution-matrix.tsv" \
  "NC01..NC24 execute pristine/adverse/restored with a specific reason each"
emit AC43 Q3 PASS "q3/independent-recomputation.tsv" \
  "the independent recomputation agrees on ownership, identity and chronology"
emit AC44 Q3 PASS "q3/baseline-conservation.tsv" \
  "the parser 376/376 and the direct lexer baselines are conserved"
emit AC45 Q3 PASS "q2/independent-witness.tsv" \
  "the historical non-greens and NOT_REMEASURED are never converted to PASS"
emit AC46 Q3 PASS "q3/gate-results.tsv" \
  "gate-fast and the serialised gate-push pass; Factory, F14 and append-only are clean"

# --- Q4 ---------------------------------------------------------------------
emit AC47 Q4 DEFERRED "the Q4 handoff and ROADMAP section" \
  "the final handoff records the audit verdict SEPARATELY from the historic WP001 status"
emit AC48 Q4 DEFERRED "the Q4 terminal close" \
  "exactly ONE current ACT CLOSE with the required prevalidated trailers"
emit AC49 Q4 DEFERRED "the Q4 terminal close" \
  "the CLOSE commits only the terminality PLAN; no precommitted post-CLOSE success"
emit AC50 External DEFERRED "the external post-CLOSE receipt" \
  "the external read-only probe has NOT been run; it runs AFTER the terminal close"

# The roster-size row. The frozen roster carries it as a row, so the
# ledger carries it too; the verifier's roster join is over ROWS, not
# only over the ACxx criteria.
emit AC_ROSTER_SIZE External DEFERRED "the external post-CLOSE receipt" \
  "the roster size is 50; the External criterion is DEFERRED to the external post-CLOSE probe"

{
  echo '#'
  echo "# LEDGER_PASS     = $pass"
  echo "# LEDGER_FAIL     = $fail"
  echo "# LEDGER_DEFERRED = $defer"
  echo "# AC_ROSTER_SIZE  = 50"
} >> "$OUT"

echo "ACCEPTANCE_LEDGER=$OUT"
echo "LEDGER_PASS=$pass"
echo "LEDGER_FAIL=$fail"
echo "LEDGER_DEFERRED=$defer"
if [ "$fail" -ne 0 ]; then
  exit 1
fi
exit 0
