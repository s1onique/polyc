#!/bin/sh
# ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01 C3
# verifier false-PASS selftest.
#
# The verifier must REJECT each of these four tampered ledgers. A verifier
# that accepts any of them would be able to report PASS on a system that is
# not actually verified.
#
#   FT-1  a DELETED control row
#   FT-2  an ALTERED control ID
#   FT-3  a FAKE PASS column (a control that never fired)
#   FT-4  a SUBSTITUTED subject (the detector class of one control swapped
#         for another)
#
# Usage: sh verifier-false-pass-selftest.sh <evidence-dir>
set -u
E=${1:-.}
R=$(cd "$(dirname "$0")/../../.." && pwd)
RAW="$E/c3/negative-controls-raw.tsv"
FROZEN="$E/c0/frozen-24-controls.tsv"
WORK=${WORK:-/tmp/pd01/selftest}
mkdir -p "$WORK"

pass=0
fail=0

check() {
  name=$1; expected=$2; got=$3
  # `got` is the verifier's verdict for the candidate ledger:
  #   ACCEPT  -> the verifier accepted it
  #   <other> -> the verifier REJECTED it, with the reason
  if [ "$expected" = "ACCEPT" ]; then
    if [ "$got" = "ACCEPT" ]; then
      pass=$((pass+1))
      printf 'SELFTEST %s EXPECT=ACCEPT GOT=ACCEPT VERDICT=CORRECT\n' "$name"
    else
      fail=$((fail+1))
      printf 'SELFTEST %s EXPECT=ACCEPT GOT=%s VERDICT=WRONGLY_REJECTED\n' "$name" "$got"
    fi
  else
    if [ "$got" != "ACCEPT" ]; then
      pass=$((pass+1))
      printf 'SELFTEST %s EXPECT=REJECTED GOT=REJECTED(%s) VERDICT=CORRECT\n' "$name" "$got"
    else
      fail=$((fail+1))
      printf 'SELFTEST %s EXPECT=REJECTED GOT=ACCEPT VERDICT=WRONGLY_ACCEPTED\n' "$name"
    fi
  fi
}

# The verifier's own acceptance rule, expressed once. It is applied to every
# candidate ledger, including the tampered ones.
accepts() {
  f=$1
  # 1. the roster must be EXACTLY the frozen ID set
  ids=$(awk -F'\t' 'NR>1{print $1}' "$f" | sort)
  frozen=$(awk -F'\t' 'NR>1{print $1}' "$FROZEN" | sort)
  [ "$ids" = "$frozen" ] || { echo "ROSTER"; return 1; }
  # 2. every control must be SENSITIVE
  ns=$(awk -F'\t' 'NR>1 && $7 != "YES"{c++} END{print c+0}' "$f")
  [ "$ns" = "0" ] || { echo "NOT_SENSITIVE"; return 1; }
  # 3. every control must have FIRED in the adverse phase
  nf=$(awk -F'\t' 'NR>1 && $5 != "FIRED"{c++} END{print c+0}' "$f")
  [ "$nf" = "0" ] || { echo "ADVERSE_DID_NOT_FIRE"; return 1; }
  # 4. every control must NOT have fired in the pristine or restored phase
  nq=$(awk -F'\t' 'NR>1 && ($4 != "NO_FIRE" || $6 != "NO_FIRE"){c++} END{print c+0}' "$f")
  [ "$nq" = "0" ] || { echo "PRISTINE_OR_RESTORED_FIRED"; return 1; }
  # 5. the detector class must match the frozen contract for every control
  awk -F'\t' 'NR>1{print $1"\t"$4}' "$FROZEN" | sort > "$WORK/frozen-classes.txt"
  awk -F'\t' 'NR>1{print $1"\t"$3}' "$f" | sort > "$WORK/cand-classes.txt"
  cmp -s "$WORK/frozen-classes.txt" "$WORK/cand-classes.txt" || { echo "CLASS_MISMATCH"; return 1; }
  # 6. the execution IDs must be DISTINCT
  ne=$(awk -F'\t' 'NR>1{print $2}' "$f" | sort -u | wc -l | tr -d ' ')
  nr=$(awk -F'\t' 'NR>1{c++} END{print c+0}' "$f")
  [ "$ne" = "$nr" ] || { echo "DUPLICATE_EXECUTION_ID"; return 1; }
  echo "ACCEPT"
}

# --- the un-tampered ledger MUST be accepted -----------------------------
res=$(accepts "$RAW")
check "FT-0-pristine-ledger" ACCEPT "$res"

# --- FT-1: a DELETED control row ----------------------------------------
awk -F'\t' 'NR>1 && $1!="PD-13"{print}' "$RAW" > "$WORK/ft1.tsv"
res=$(accepts "$WORK/ft1.tsv")
check "FT-1-deleted-row" REJECTED "$res"

# --- FT-2: an ALTERED control ID ---------------------------------------
awk -F'\t' 'BEGIN{OFS="\t"} NR>1 && $1=="PD-13"{$1="PD-99"; print} NR==1{print} {if(NR>1 && $1!="PD-13") print}' "$RAW" > "$WORK/ft2.tsv"
res=$(accepts "$WORK/ft2.tsv")
check "FT-2-altered-id" REJECTED "$res"

# --- FT-3: a FAKE PASS column (the adverse phase never fired) ---------
awk -F'\t' 'BEGIN{OFS="\t"} NR>1 && $1=="PD-13"{$5="NO_FIRE"; print} NR==1{print} {if(NR>1 && $1!="PD-13") print}' "$RAW" > "$WORK/ft3.tsv"
res=$(accepts "$WORK/ft3.tsv")
check "FT-3-fake-pass-column" REJECTED "$res"

# --- FT-4: a SUBSTITUTED subject (swapped detector classes) -----------
awk -F'\t' 'BEGIN{OFS="\t"} NR>1 && $1=="PD-13"{$3="DORMANT_DELEGATION"; print} NR==1{print} {if(NR>1 && $1!="PD-13") print}' "$RAW" > "$WORK/ft4.tsv"
res=$(accepts "$WORK/ft4.tsv")
check "FT-4-substituted-subject" REJECTED "$res"

echo "SELFTEST_TOTAL=$((pass+fail)) REJECTED_CORRECTLY=$pass NOT_REJECTED=$fail"
if [ "$fail" != "0" ]; then
  echo "SELFTEST_VERDICT=FAIL"
  exit 1
fi
echo "SELFTEST_VERDICT=PASS"
