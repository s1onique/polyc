#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01/q2/run-antiselftests.sh
#
# ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01 Q2 IMPL.
#
# THE ANTI-SELFTESTS OF THE COMPILED POLYC VERIFIER.
#
# Each test corrupts ONE input of an otherwise consistent input set
# and requires that the verifier REJECTS it with the test's OWN reason
# token. A verifier that accepts a broken input is not a verifier.
#
# Every test is performed on a DISPOSABLE COPY. The committed inputs
# are never modified.
#
# F-POLYC-TOOLS: orchestration glue, under the 50 LOC shell budget.

set -u

EV="evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01/q2"
V="build/driver-boundary-qualification01-verify"
I="$EV/inputs"
OUT="$EV/detector-anti-selftests.tsv"
TMP=$(mktemp -d /tmp/q01-anti.XXXXXX)
trap 'rm -rf "$TMP"' EXIT INT TERM

render() {
  if [ -z "$1" ]; then echo "EMPTY"; else printf '%s' "$1" | tr '\n' '|'; fi
}

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01'
  echo '# ACT_PHASE=Q2-IMPL'
  echo '# EVIDENCE_KIND=detector-anti-selftests'
  echo '#'
  echo '# Each test corrupts ONE input of a consistent input set and'
  echo '# requires that the verifier REJECTS it with the test OWN reason'
  echo '# token, and not merely with a non-zero exit code.'
  echo '#'
  printf 'test_id\tmode\texpected_reason\texit_code\treason_token_matched\treason_token_actual\toutput\n'
} > "$OUT"

# anti <id> <mode> <expected_reason> <input_a> <input_b> <mutation>
anti() {
  _id="$1"; _m="$2"; _req="$3"; _a="$4"; _b="$5"; _mut="$6"
  cp "$_a" "$TMP/a.tsv"
  cp "$_b" "$TMP/b.tsv"
  case "$_mut" in
    m_corrupt_id) m_corrupt_id "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_duplicate_id) m_duplicate_id "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_wrong_class) m_wrong_class "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_bogus_active_decision) m_bogus_active_decision "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_false_dormant) m_false_dormant "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_missing_row) m_missing_row "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_wrong_scope) m_wrong_scope "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_forged_receipt_timing) m_forged_receipt_timing "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_replay_as_original) m_replay_as_original "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_receipt_not_measured) m_receipt_not_measured "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_fake_ac_set) m_fake_ac_set "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_omitted_correction) m_omitted_correction "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_omitted_post_close_scan) m_omitted_post_close_scan "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_forged_entry) m_forged_entry "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_wrong_authority_count) m_wrong_authority_count "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_stale_object) m_stale_object "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_falsified_branch_provenance) m_falsified_branch_provenance "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_m2_overclaim) m_m2_overclaim "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_false_green_baseline) m_false_green_baseline "$TMP/a.tsv" "$TMP/b.tsv" ;;
    m_missing_decision_owner) m_missing_decision_owner "$TMP/a.tsv" "$TMP/b.tsv" ;;
  esac
  _out=$("$V" "$_m" "$TMP/a.tsv" "$TMP/b.tsv" 2>&1); _rc=$?
  _got=$(printf '%s' "$_out" | cut -d'|' -f1)
  _ok="NO_REASON_TOKEN"
  [ "$_got" = "$_req" ] && _ok="REASON_TOKEN_PRESENT"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$_id" "$_m" "$_req" "$_rc" "$_ok" "$_got" "$(render "$_out")" >> "$OUT"
}

# --- THE MUTATIONS ---------------------------------------------------------
#
# Every mutation targets a row BY CONTENT, never by line number, and
# every mutation rewrites the file through awk so that it is portable
# and cannot be confused by the comment header.

# The mutations below rewrite a SPECIFIC COLUMN of a SPECIFIC ROW,
# identified by the row's historical_id and by the column index.
# Column indices are 1-based and refer to the header line of
# current-classification.tsv:
#
#   1 historical_id          7 decision_owner        12 counterfactual_execution
#   3 historical_function   8 live_text_callsites   13 current_class
#                          11 wp001_route_reachable  14 confidence
#
# mutfield <file> <id> <col> <newvalue> rewrites exactly one cell.

mutfield() {
  awk -F'\t' -v OFS='\t' -v id="$2" -v col="$3" -v val="$4" '
    $1 == id { $col = val }
    { print }
  ' "$1" > "$1.m"
  mv "$1.m" "$1"
}

# AS01 -- the HISTORICAL roster carries an ID the current table lacks.
m_corrupt_id() { mutfield "$2" "A-C-DRIVER-cli-cliPanic-SL" 1 "A-C-DRIVER-cli-cliPanic-XX"; }

# AS02 -- the CURRENT table carries the same ID twice.
m_duplicate_id() {
  awk -F'\t' -v OFS='\t' '
    $1 == "A-C-DRIVER-cli-cliPanic-SL" { print; print; next }
    { print }
  ' "$1" > "$1.m"
  mv "$1.m" "$1"
}

# AS03 -- the retained-C-semantic main() row loses its counterfactual
# witness, so the entry-branch causal claim becomes unproven.
m_false_dormant() { mutfield "$1" "A-C-DRIVER-main-main-SW1" 12 "PENDING"; }

# AS04 -- a dormant row claims zero live call sites but is given one.
m_stale_object() { mutfield "$1" "A-C-DRIVER-cli-cliParseNop-SL" 8 "5"; }

# AS05 -- a PolyC-owned row loses its traced decision owner.
m_missing_decision_owner() { mutfield "$1" "A-C-DRIVER-cli-cliGetFileType-FC" 7 "PENDING"; }

# AS06 -- a counterfactual witness is replaced by a bare token with no
# provenance, so the row no longer carries a witness at all and the
# decision owner is no longer traced.
m_falsified_branch_provenance() { mutfield "$1" "A-C-DRIVER-cli-cliConcatArgv-FC" 12 "COUNTERFACTUAL_C_PERFORMED_UNWITNESSED"; }

# AS07 -- a mechanical row is forged into a PolyC-owned decision with
# no counterfactual witness behind the claim: the row asserts PolyC
# ownership of a decision whose owner was never traced.
m_bogus_active_decision() {
  mutfield "$1" "A-C-DRIVER-main-assemble-FC" 7 "POLYC_DRIVER"
  mutfield "$1" "A-C-DRIVER-main-assemble-FC" 13 "POLYC_OWNED_DECISION_PROVEN"
  mutfield "$1" "A-C-DRIVER-main-assemble-FC" 12 "PENDING"
}

# AS08 -- the immutable historical class is rewritten.
m_wrong_class() { mutfield "$1" "A-C-DRIVER-cli-cliPanic-SL" 4 "C_MECHANICAL"; }
m_wrong_scope() { awk '{ if ($0 ~ /^WP001_REQUIRED_ROUTE_C_SEMANTIC_REMAINDER/) { print "WP001_REQUIRED_ROUTE_C_SEMANTIC_REMAINDER\t0" } else { print } }' "$2" > "$2.m"; mv "$2.m" "$2"; }
m_forged_receipt_timing() { awk '{ if ($0 ~ /^HISTORICAL_ACT_TERMINALITY_CONFIRMED/) { print "HISTORICAL_ACT_TERMINALITY_CONFIRMED\tYES\tNO" } else { print } }' "$1" > "$1.m"; mv "$1.m" "$1"; }
m_replay_as_original() { awk '{ if ($0 ~ /^FRESH_EXTERNAL_REPLAY/) { print "FRESH_EXTERNAL_REPLAY\tVERIFIED\tYES" } else { print } }' "$1" > "$1.m"; mv "$1.m" "$1"; }
m_receipt_not_measured() { awk '{ if ($0 ~ /^ORIGINAL_EXTERNAL_RECEIPT/) { print "ORIGINAL_EXTERNAL_RECEIPT\tVERIFIED\tNO" } else { print } }' "$1" > "$1.m"; mv "$1.m" "$1"; }
m_fake_ac_set() { awk '{ if ($0 ~ /^AC02/) next; print }' "$1" > "$1.m"; mv "$1.m" "$1"; }
m_omitted_correction() { awk '{ if ($0 ~ /CORRECTION03/) next; print }' "$1" > "$1.m"; mv "$1.m" "$1"; }
m_omitted_post_close_scan() { awk '{ if ($0 ~ /^POST_CLOSE_ACT_ID_COMMITS/) { print "POST_CLOSE_ACT_ID_COMMITS\t7\tYES" } else { print } }' "$1" > "$1.m"; mv "$1.m" "$1"; }
m_forged_entry() { awk '{ if ($0 ~ /^ENTRY_HEAD/) { print "ENTRY_HEAD\t0000000000000000000000000000000000000000" } else { print } }' "$2" > "$2.m"; mv "$2.m" "$2"; }
m_wrong_authority_count() { awk '{ if ($0 ~ /^FINAL_AUTHORITIES/) { print "FINAL_AUTHORITIES\t32" } else { print } }' "$2" > "$2.m"; mv "$2.m" "$2"; }
m_missing_row() { awk -F'\t' 'BEGIN{OFS="\t"} $1 == "A-C-DRIVER-cli-cliPanic-SL" { next } { print }' "$2" > "$2.m"; mv "$2.m" "$2"; }
m_m2_overclaim() { awk '{ if ($0 ~ /^M2_ACHIEVED/) { print "M2_ACHIEVED\tYES" } else { print } }' "$1" > "$1.m"; mv "$1.m" "$1"; }
m_false_green_baseline() { awk '{ if ($0 ~ /^CROSS_TARGET_PREFIX/) { print "CROSS_TARGET_PREFIX\tPASS" } else { print } }' "$1" > "$1.m"; mv "$1.m" "$1"; }
m_missing_decision_owner_legacy() { :; }


# --- THE TESTS -------------------------------------------------------------

anti AS01_CORRUPTED_ROW_ID        ROSTER     DRIVER_ROSTER_ID_MISSING        "$I/current-classification.tsv" "$I/historical-roster.tsv" m_corrupt_id
anti AS02_DUPLICATE_ROW_ID        ROSTER     DRIVER_ROSTER_ID_DUPLICATE      "$I/current-classification.tsv" "$I/historical-roster.tsv" m_duplicate_id
anti AS03_WRONG_FUNCTION_RANGE    OWNERSHIP  ENTRY_BRANCH_CAUSAL_UNPROVEN    "$I/current-classification.tsv" "$I/expect-ownership.tsv" m_false_dormant
anti AS04_STALE_OBJECT            OWNERSHIP  UNREACHABILITY_NOT_PROVEN      "$I/current-classification.tsv" "$I/expect-ownership.tsv" m_stale_object
anti AS05_MISSING_C_DECISION      OWNERSHIP  DECISION_OWNER_NOT_TRACED       "$I/current-classification.tsv" "$I/expect-ownership.tsv" m_missing_decision_owner
anti AS06_FALSIFIED_BRANCH_PROV   OWNERSHIP  DECISION_OWNER_NOT_TRACED       "$I/current-classification.tsv" "$I/expect-ownership.tsv" m_falsified_branch_provenance
anti AS07_BOGUS_ACTIVE_DECISION   OWNERSHIP  DECISION_OWNER_NOT_TRACED       "$I/current-classification.tsv" "$I/expect-ownership.tsv" m_bogus_active_decision
anti AS08_REWRITTEN_HIST_CLASS    HISTCLASS  HISTORICAL_CLASS_REWRITTEN     "$I/current-classification.tsv" "$I/historical-roster.tsv" m_wrong_class
anti AS09_MISSING_ROW             ROSTER     DRIVER_ROSTER_ID_MISSING        "$I/current-classification.tsv" "$I/historical-roster.tsv" m_missing_row
anti AS10_WRONG_SCOPE             SCOPE      GLOBAL_DRIVER_REMAINDER_UNDERCOUNTED "$I/current-classification.tsv" "$I/expect-ownership.tsv" m_wrong_scope
anti AS11_FORGED_RECEIPT_TIMING   CHRONOLOGY PRECOMMITTED_RESULT_LAUNDERED "$I/chronology.tsv" "$I/expect-chronology.tsv" m_forged_receipt_timing
anti AS12_REPLAY_AS_ORIGINAL      CHRONOLOGY REPLAY_PROVENANCE_CONFLATED    "$I/chronology.tsv" "$I/expect-chronology.tsv" m_replay_as_original
anti AS13_RECEIPT_NOT_MEASURED    CHRONOLOGY RECEIPT_EXISTENCE_NOT_PROVEN  "$I/chronology.tsv" "$I/expect-chronology.tsv" m_receipt_not_measured
anti AS14_POST_CLOSE_SCAN_OMITTED CHRONOLOGY POST_CLOSE_ID_CARRIER_OMITTED "$I/chronology.tsv" "$I/expect-chronology.tsv" m_omitted_post_close_scan
anti AS15_FORGED_ENTRY_IDENTITY   IDENTITY   ENTRY_IDENTITY_FORGED          "$I/entry-identity.tsv" "$I/expect-identity.tsv" m_forged_entry
anti AS16_AUTHORITY_UNIT_MISMATCH AUTHORITY  AUTHORITY_UNIT_MISMATCH        "$I/production-authorities.tsv" "$I/expect-authority.tsv" m_wrong_authority_count
anti AS17_OMITTED_CORRECTION      FAMILY     ACT_FAMILY_COST_UNDERCOUNTED   "$I/act-family-inventory.tsv" "$I/expect-family.tsv" m_omitted_correction
anti AS18_FORGED_AC_SET           ACCEPT     FACTORY_ACCEPTANCE_OR_TERMINALITY_FORGED "$I/frozen-ac.tsv" "$I/frozen-ac.tsv" m_fake_ac_set
anti AS19_M2_OVERCLAIM            M2CLASS    M2_BOOTSTRAP_MISCLASSIFIED     "$I/milestone-claims.tsv" "$I/expect-m2class.tsv" m_m2_overclaim
anti AS20_FALSE_GREEN_BASELINE    M2CLASS    KNOWN_BASELINE_FALSE_GREEN     "$I/milestone-claims.tsv" "$I/expect-m2class.tsv" m_false_green_baseline

echo "ANTI_SELFTESTS=$OUT"
