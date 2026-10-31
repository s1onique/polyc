#!/bin/sh
# ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02 C3 control-verifier selftest.
#
# The verifier must REJECT a tampered control ledger. Each case mutates a
# disposable copy of the ledger and asserts that the verifier's rejection
# reason is the EXPECTED one. A verifier that accepts everything fails.
set -u
ROOT=${1:-.}
EV=$ROOT/evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02
LEDGER=$EV/c3/control-execution.tsv

# The expected detector for each NC id that this ACT executed.
exp_det() {
  case $1 in
    NC-01) echo ENTRY_IDENTITY_MISMATCH ;;
    NC-02) echo F14_FROZEN_PATH_TAMPER ;;
    NC-03) echo PREDECESSOR_CAUSAL_ID_MISBIND ;;
    NC-04) echo PREDECESSOR_G0_NOT_PRODUCTION ;;
    NC-05) echo SOURCE_ENUM_ZERO_NORMALIZATION ;;
    NC-21) echo SPECULATIVE_PRODUCTION_GRAPH_CUT ;;
    NC-22) echo UNSUPPORTED_GRAPH_WITNESS_PROMOTED ;;
    NC-24) echo AC_OR_BASELINE_FALSE_PASS ;;
    *)     echo "" ;;
  esac
}

# verify() prints the rejection reason for the given ledger, or OK.
verify() {
  L=$1
  bad=$(awk -F'\t' 'NR>1 && $1 ~ /^NC-/ && $1 !~ /^NC-(0[1-9]|1[0-9]|2[0-4])$/ {c++} END{print c+0}' "$L")
  if [ "$bad" -ne 0 ]; then echo "UNKNOWN_ID"; return; fi
  d=$(awk -F'\t' 'NR>1 && $1 ~ /^NC-/ {print $1}' "$L" | sort | uniq -d | wc -l | tr -d ' ')
  if [ "$d" -ne 0 ]; then echo "DUPLICATE_ID"; return; fi
  n=$(awk -F'\t' 'NR>1 && $1 ~ /^NC-/ {c++} END{print c+0}' "$L")
  if [ "$n" -ne 24 ]; then echo "ROW_COUNT $n"; return; fi
  bad=$(awk -F'\t' 'NR>1 && $1 ~ /^NC-/ { if ($2=="" || $8=="") c++ } END{print c+0}' "$L")
  if [ "$bad" -ne 0 ]; then echo "MISSING_FIELD"; return; fi
  bad=$(awk -F'\t' 'NR>1 && $1 ~ /^NC-/ { if ($8=="PASS" && $2 !~ /^EXEC-/ && $2 != "NOT_EXECUTED") c++ } END{print c+0}' "$L")
  if [ "$bad" -ne 0 ]; then echo "FORGED_PASS"; return; fi
  # a PASS row must carry the correct required detector for its NC id
  bad=0
  for id in NC-01 NC-02 NC-03 NC-04 NC-05 NC-21 NC-22 NC-24; do
    want=$(exp_det "$id")
    got=$(awk -F'\t' -v id="$id" 'NR>1 && $1==id {print $3; exit}' "$L")
    st=$(awk -F'\t' -v id="$id" 'NR>1 && $1==id {print $8; exit}' "$L")
    if [ "$st" = "PASS" ] && [ "$got" != "$want" ]; then bad=$((bad+1)); fi
  done
  if [ "$bad" -ne 0 ]; then echo "WRONG_REASON"; return; fi
  # a swapped executor id must be rejected
  bad=$(awk -F'\t' 'NR>1 && $1 ~ /^NC-/ && $2 ~ /^EXEC-/ { e[$2]++ } END{ c=0; for (k in e) if (e[k]>1) c++; print c }' "$L")
  if [ "$bad" -ne 0 ]; then echo "SWAPPED_EXECUTOR_ID"; return; fi
  echo "OK"
}

case_run() {
  name=$1; expect=$2; mutate=$3
  T=$(mktemp -d)
  cp "$LEDGER" "$T/l.tsv"
  ( cd "$T" && eval "$mutate" )
  got=$(verify "$T/l.tsv")
  rm -rf "$T"
  # The verifier's reason may carry a detail suffix (e.g. "ROW_COUNT 23");
  # the reason PREFIX is what the selftest asserts.
  case "$got" in
    "$expect"|"$expect "*)
      echo "$name EXPECTED=$expect GOT=$got SELFTEST=PASS" ;;
    *)
      echo "$name EXPECTED=$expect GOT=$got SELFTEST=FAIL" ;;
  esac
}

echo "== control-verifier selftest =="
case_run "delete-an-id"        "ROW_COUNT"           "perl -ni -e 'print unless \$. == 2' l.tsv"
case_run "duplicate-an-id"     "DUPLICATE_ID"        "perl -ne 'print; print if \$. == 2' l.tsv > l2 && mv l2 l.tsv"
case_run "unknown-id"          "UNKNOWN_ID"          "perl -pi -e 's/^NC-01/NC-99/ if \$. == 2' l.tsv"
case_run "forge-a-pass"        "MISSING_FIELD"       "perl -pi -e 's/EXEC-NC-01// if \$. == 2' l.tsv"
case_run "wrong-reason"        "WRONG_REASON"        "perl -pi -e 's/ENTRY_IDENTITY_MISMATCH/SOMETHING_ELSE/ if \$. == 2' l.tsv"
case_run "swap-executor-id"    "SWAPPED_EXECUTOR_ID" "perl -pi -e 's/EXEC-NC-02/EXEC-NC-01/ if \$. == 3' l.tsv"
case_run "unmutated-ledger"    "OK"                  "true"
