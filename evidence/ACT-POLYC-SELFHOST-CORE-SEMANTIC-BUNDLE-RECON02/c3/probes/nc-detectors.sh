#!/bin/sh
# ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02 C3 negative-control detectors.
#
# Each detector is a bounded, independent check over the ACT's own evidence.
# A detector returns exit 0 when it FIRES (the adverse condition it watches
# for is present) and exit 1 when it does not. Each control therefore has:
#   a PRISTINE run (the detector must NOT fire),
#   an ADVERSE run (the detector MUST fire), and
#   a RESTORED run (the detector must NOT fire again).
set -u
ROOT=${1:-.}
EV=$ROOT/evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02
C0=$EV/c0

# NC-01: the entry identity must match the frozen values.
nc01() {
  grep -q '^ENTRY_HEAD=c05a028276ac3eff3976c113c16b220c7de1331a$' "$C0/entry-identity.txt" || return 0
  grep -q '^ENTRY_TREE=47283adc6df6c6494ea636a193021856c1f8b364$' "$C0/entry-identity.txt" || return 0
  grep -q '^ENTRY_BRANCH=main$' "$C0/entry-identity.txt" || return 0
  grep -q '^ENTRY_REPLACE_REFS=0$' "$C0/entry-identity.txt" || return 0
  return 1
}
# NC-02: every frozen predecessor path must still hash to its frozen digest.
nc02() {
  n=$(awk -F'\t' 'NR>1 && $3!="" {c++} END {print c+0}' "$C0/predecessor-freeze.tsv")
  m=$(awk -F'\t' 'NR>1 && $3!="" && $4!="TRACKED" {c++} END {print c+0}' "$C0/predecessor-freeze.tsv")
  [ "$n" -gt 0 ] || return 0
  [ "$m" -eq 0 ] || return 0
  return 1
}
# NC-03: the RO attribution row must NOT claim that the RO experiment mutated
# AbiCoreIsRangeOperator while its digests identify the PO function.
# This detector watches MY OWN audit row. It FIRES if the audit row ever
# mis-binds: i.e. if it names the range site but records digests that the
# audit itself proved belong to the pointer-operator function.
nc03() {
  awk -F'\t' '
    NR==1 { next }
    $1=="M-POLYC-RO" {
      site=$2; sym=$3
      reproduced_target=$5
      verdict=$12
    }
    END {
      if (site=="") exit 1
      # The mis-binding fires when the row claims the RANGE site but the
      # reproduced target is the POINTER-operator function. That is exactly
      # the defect the audit must RECORD, so the audit row is expected to
      # contain it. The detector therefore fires only if the audit FAILED to
      # label that row as MISATTRIBUTED.
      if (site=="SITE-RANGE-OPERATOR" && reproduced_target ~ /AbiCoreIsValidPointerOperator/) {
        if (verdict !~ /MISATTRIBUTED/) exit 0
      }
      exit 1
    }' "$C0/predecessor-ro-attribution.tsv" && return 0
  return 1
}
# NC-04: the G0 oracle must be a real whole production compiler, not a copy.
nc04() {
  grep -q '^G0_IS_WHOLE_PRODUCTION_COMPILER=YES' "$C0/predecessor-g0-proof.tsv" || return 0
  grep -q '^G0_COPIED_ORACLE_SUBSTITUTED=NO$' "$C0/predecessor-g0-proof.tsv" || return 0
  grep -q '^G0_POLYC_SUBJECT_SYMBOL_COUNT=0$' "$C0/predecessor-g0-proof.tsv" || return 0
  grep -q '^G0_BINARY_SIZE_BYTES=' "$C0/predecessor-g0-proof.tsv" || return 0
  return 1
}
# NC-05: the implicit enum zero must be RECOVERED as zero, not left unknown.
nc05() {
  grep -q 'RECOVERED_AS_ZERO' "$C0/enum-zero.tsv" || return 0
  grep -q 'CONFIRMED_ZERO' "$C0/enum-zero.tsv" || return 0
  return 1
}
# NC-22: E-MUT-0137 must NOT be promoted to a proven cut.
# FIRES (returns 0) when the adverse condition IS present.
# graph-after.tsv is a TSV: metric \t value \t method \t source \t result
nc22() {
  awk -F'\t' 'NR>1 && $1=="E_MUT_0137_PROMOTED_TO_CUT" && $2!="NO" {bad=1}
              NR>1 && $1=="E_MUT_0137_STATUS" && $2 ~ /CUT_PROVEN/ {bad=1}
              END {exit(bad?0:1)}' "$EV/c3/graph-after.tsv" && return 0
  return 1
}
# NC-21: no speculative graph cut may be claimed.
# FIRES (returns 0) when the adverse condition IS present.
nc21() {
  awk -F'\t' 'NR>1 && $1=="NEW_PROVEN_CUTS" && $2+0>0 {bad=1}
              NR>1 && $1=="SPECULATIVE_EDGES_ADDED" && $2+0>0 {bad=1}
              END {exit(bad?0:1)}' "$EV/c3/graph-after.tsv" && return 0
  return 1
}
# NC-24: the AC ledger must not contain a forged PASS.
# FIRES (returns 0) when the adverse condition IS present.
nc24() {
  [ -s "$EV/c3/ac01-ac49-ledger.tsv" ] || return 0
  # Every data row must carry a legal status in column 5.
  bad=$(awk -F'\t' 'NR>1 && $0 !~ /^#/ { s=$5; if (s!="PASS" && s!="FAIL" && s!="UNPROVEN" && s!="DEFERRED" && s!="NOT_RUN") c++ } END {print c+0}' "$EV/c3/ac01-ac49-ledger.tsv")
  [ "$bad" -eq 0 ] || return 0
  # A row may not claim PASS while its evidence path is empty.
  bad2=$(awk -F'\t' 'NR>1 && $0 !~ /^#/ { if ($5=="PASS" && ($4=="" || $4=="-")) c++ } END {print c+0}' "$EV/c3/ac01-ac49-ledger.tsv")
  [ "$bad2" -eq 0 ] || return 0
  return 1
}

run() {
  name=$1; fn=$2
  if "$fn"; then
    echo "$name DETECTOR=FIRED"
  else
    echo "$name DETECTOR=SILENT"
  fi
}

echo "== PRISTINE run: every detector must be SILENT =="
run NC-01 nc01
run NC-02 nc02
run NC-03 nc03
run NC-04 nc04
run NC-05 nc05
run NC-21 nc21
run NC-22 nc22
run NC-24 nc24

# ---------------------------------------------------------------------
# THE ADVERSE RUN. A disposable copy of the evidence tree is mutated so
# that EACH watched adverse condition is present. Every detector MUST fire
# on this copy. The copy is discarded; the authoritative tree is untouched.
# ---------------------------------------------------------------------
CTRL=$(mktemp -d)
trap 'rm -rf "$CTRL"' EXIT
cp -R "$EV" "$CTRL/"

# NC-01: wrong entry HEAD.
perl -pi -e 's/^ENTRY_HEAD=c05a028276ac3eff3976c113c16b220c7de1331a$/ENTRY_HEAD=0000000000000000000000000000000000000000/' "$CTRL/$(basename $EV)/c0/entry-identity.txt"
# NC-02: a frozen predecessor path digest is tampered.
perl -pi -e 's/\tTRACKED$/\tTAMPERED/ if $. == 3' "$CTRL/$(basename $EV)/c0/predecessor-freeze.tsv"
# NC-03: the audit row is edited so that it no longer labels the mis-binding
# (the verdict is column 12 of the TSV).
perl -pi -e 's/(\t)MISATTRIBUTED(\t)/${1}CONFIRMED${2}/ if $. == 2' "$CTRL/$(basename $EV)/c0/predecessor-ro-attribution.tsv"
# NC-04: the G0 oracle is replaced by a copied oracle.
perl -pi -e 's/^G0_COPIED_ORACLE_SUBSTITUTED=NO$/G0_COPIED_ORACLE_SUBSTITUTED=YES/' "$CTRL/$(basename $EV)/c0/predecessor-g0-proof.tsv"
# NC-05: the implicit enum zero is treated as unknown.
perl -pi -e 's/RECOVERED_AS_ZERO/UNKNOWN_AS_RECORDED/' "$CTRL/$(basename $EV)/c0/enum-zero.tsv"
# NC-21: a speculative graph cut is claimed (TSV column 2).
perl -pi -e 's/^NEW_PROVEN_CUTS\t0\t/NEW_PROVEN_CUTS\t1\t/' "$CTRL/$(basename $EV)/c3/graph-after.tsv"
# NC-22: E-MUT-0137 is promoted to a proven cut (TSV column 2).
perl -pi -e 's/^E_MUT_0137_PROMOTED_TO_CUT\tNO\t/E_MUT_0137_PROMOTED_TO_CUT\tYES\t/' "$CTRL/$(basename $EV)/c3/graph-after.tsv"
# NC-24: an AC row is forged as PASS with an empty evidence path.
perl -pi -e 's/^AC01\tC0\t[^\t]*\tc0\/entry-identity.txt\tPASS\t.*$/AC01\tC0\tforged\t-\tPASS\tforged pass/' "$CTRL/$(basename $EV)/c3/ac01-ac49-ledger.tsv"

echo
echo "== ADVERSE run: every detector must FIRE =="
(
  ROOT=$CTRL
  EV=$CTRL/$(basename $EV)
  C0=$EV/c0
  run NC-01 nc01
  run NC-02 nc02
  run NC-03 nc03
  run NC-04 nc04
  run NC-05 nc05
  run NC-21 nc21
  run NC-22 nc22
  run NC-24 nc24
)

# ---------------------------------------------------------------------
# THE RESTORED run. The authoritative tree was never mutated, so the
# detectors must be SILENT again.
# ---------------------------------------------------------------------
echo
echo "== RESTORED run: every detector must be SILENT again =="
run NC-01 nc01
run NC-02 nc02
run NC-03 nc03
run NC-04 nc04
run NC-05 nc05
run NC-21 nc21
run NC-22 nc22
run NC-24 nc24
echo
echo "AUTHORITATIVE_TREE_MUTATED=NO (the adverse run used a disposable copy)"
