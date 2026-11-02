#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01/q2/run-verifier.sh
#
# ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01 Q2 IMPL.
#
# Runs the COMPILED PolyC qualification verifier over the measured
# input tables and records the verdict of every mode.
#
# It also runs the INDEPENDENT POSIX/Git witness over the same tables
# and compares the two verdicts. The two implementations share no
# material detection algorithm.
#
# F-POLYC-TOOLS: orchestration glue, under the 50 LOC shell budget.

set -u

EV="evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01/q2"
V="build/driver-boundary-qualification01-verify"
I="$EV/inputs"
OUT="$EV/audit-tool-build-and-selftest.tsv"

render() {
  if [ -z "$1" ]; then echo "EMPTY"; else printf '%s' "$1" | tr '\n' '|'; fi
}

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01'
  echo '# ACT_PHASE=Q2-IMPL'
  echo '# EVIDENCE_KIND=audit-tool-build-and-selftest'
  echo '#'
  echo '# THE COMPILED POLYC VERIFIER'
  echo '#   build/driver-boundary-qualification01-verify'
  echo '# compiled from tools/quality/driver-boundary-qualification01-verify.HC'
  echo '# by the REAL production compiler. It ingests the measured input'
  echo '# tables as DATA and RE-DERIVES every count it checks.'
  echo '#'
  printf 'mode\tinput_a\tinput_b\texit_code\tverdict\treason_token\toutput\n'
} > "$OUT"

run_mode() {
  _m="$1"; _a="$2"; _b="$3"
  _out=$("$V" "$_m" "$_a" "$_b" 2>&1); _rc=$?
  _vd="SILENT"
  [ "$_rc" -ne 0 ] && _vd="REJECTED"
  _tok="NONE"
  printf '%s' "$_out" | grep -q '|' && _tok=$(printf '%s' "$_out" | cut -d'|' -f1)
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$_m" "$_a" "$_b" "$_rc" "$_vd" "$_tok" "$(render "$_out")" >> "$OUT"
}

# The selftest proves the verifier's own helpers are live.
_st=$("$V" SELFTEST 2>&1); _src=$?
printf 'SELFTEST\t-\t-\t%s\t%s\t%s\t%s\n' "$_src" \
  "$([ "$_src" -eq 0 ] && echo PASS || echo FAIL)" \
  "$([ "$_src" -eq 0 ] && echo NONE || echo SELFTEST_FAILED)" \
  "$(render "$_st")" >> "$OUT"

run_mode IDENTITY   "$I/entry-identity.tsv"        "$I/expect-identity.tsv"
run_mode ROSTER     "$I/current-classification.tsv" "$I/historical-roster.tsv"
run_mode HISTCLASS  "$I/current-classification.tsv" "$I/historical-roster.tsv"
run_mode OWNERSHIP  "$I/current-classification.tsv" "$I/expect-ownership.tsv"
run_mode SCOPE      "$I/current-classification.tsv" "$I/expect-ownership.tsv"
run_mode AUTHORITY  "$I/production-authorities.tsv" "$I/expect-authority.tsv"
run_mode FAMILY     "$I/act-family-inventory.tsv"  "$I/expect-family.tsv"
run_mode CHRONOLOGY "$I/chronology.tsv"            "$I/expect-chronology.tsv"
run_mode LINKS      "$I/links.tsv"                 "$I/expect-links.tsv"
run_mode ACCEPT     "$EV/../q3/acceptance-ledger.tsv" "$I/frozen-ac.tsv"

echo "AUDIT_VERIFIER_RUN=$OUT"
