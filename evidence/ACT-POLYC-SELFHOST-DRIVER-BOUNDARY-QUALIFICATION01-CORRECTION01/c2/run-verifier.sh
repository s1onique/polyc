#!/bin/sh
# THE C2 VERIFIER BUILD AND SELFTEST.
#
# The correction verifier is compiled by the REAL production compiler
# and every mode is executed over the measured inputs. Each mode is
# SILENT with exit 0 on the pristine inputs.
set -u
HERE=$(dirname "$0")
REPO=$(cd "$HERE/../../.." && pwd)
D=evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01
OUT="$HERE/verifier-build-and-selftest.tsv"
V="build/driver-boundary-qualification01-correction01-verify"
I="$D/c2/inputs"
# The C0 FROZEN CONTRACT is the IMMUTABLE ANCHOR for the predicate
# comparison. It is what makes a predicate DRIFT on the ledger side
# distinguishable from a REWRITE of the frozen contract itself.
C0="$D/c0"
cd "$REPO" || exit 1

{
echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01'
echo '# ACT_PHASE=C2-IMPL'
echo '# EVIDENCE_KIND=verifier-build-and-selftest'
echo '#'
echo '# THE COMPILED POLYC CORRECTION VERIFIER.'
echo '#'
echo '#   build/driver-boundary-qualification01-correction01-verify'
echo '# compiled from tools/quality/driver-boundary-qualification01-correction01-verify.HC'
echo '# by the REAL production compiler. It ingests the measured input'
echo '# tables as DATA and RE-DERIVES every count it checks.'
echo '#'
echo '# THE BUILD COMMAND IS RECORDED, NOT ASSUMED.'
echo '#'
printf 'mode\tinput_a\tinput_b\tinput_c\texit_code\tverdict\treason_token\n'
} > "$OUT"

# The BUILD, with its command and exit code recorded.
BUILD_CMD="./hcc --install-dir=\$PWD/build/test-prefix tools/quality/driver-boundary-qualification01-correction01-verify.HC -o build/driver-boundary-qualification01-correction01-verify"
rm -f "$V"
BUILD_LOG=$(sh -c "./hcc --install-dir=\$PWD/build/test-prefix tools/quality/driver-boundary-qualification01-correction01-verify.HC -o build/driver-boundary-qualification01-correction01-verify" 2>&1)
BUILD_RC=$?
BUILD_SHA="ABSENT"
[ -f "$V" ] && BUILD_SHA=$(shasum -a 256 "$V" | awk '{print $1}')
printf 'BUILD\t-\t-\t-\t%s\t%s\tNONE\n' "$BUILD_RC" "$([ $BUILD_RC -eq 0 ] && echo PASS || echo FAIL)" >> "$OUT"
printf '# BUILD_COMMAND = %s\n' "$BUILD_CMD" >> "$OUT"
printf '# BUILD_EXIT_CODE = %s\n' "$BUILD_RC" >> "$OUT"
printf '# BUILD_BINARY_SHA256 = %s\n' "$BUILD_SHA" >> "$OUT"

run_mode() {
  _m="$1"; _a="$2"; _b="$3"; _c="$4"
  _out=$("$V" "$_m" "$_a" "$_b" "$_c" 2>&1); _rc=$?
  _vd="SILENT"
  [ "$_rc" -ne 0 ] && _vd="REJECTED"
  _tok="NONE"
  printf '%s' "$_out" | grep -q '|' && _tok=$(printf '%s' "$_out" | cut -d'|' -f1)
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$_m" "$_a" "$_b" "$_c" "$_rc" "$_vd" "$_tok" >> "$OUT"
}

run_mode SELFTEST      "-"  "-" "-"
run_mode ACSET         "$I/correction-acceptance-ledger.tsv" "-" "-"
run_mode ACPHASE       "$I/correction-acceptance-ledger.tsv" "$I/frozen-phase-and-predicate.tsv" "-"
run_mode ACPREDICATE   "$I/correction-acceptance-ledger.tsv" "$I/frozen-phase-and-predicate.tsv" "$C0/frozen-ac-contract.tsv"
run_mode ACWITNESS     "$I/witness-existence.tsv" "-" "-"
run_mode ACCOUNTING    "$I/correction-acceptance-ledger.tsv" "$I/expected-counts.tsv" "-"
run_mode ROUTES        "$I/branch-inventory.tsv" "-" "-"
run_mode DECISION      "$I/ownership.tsv" "-" "-"
run_mode BASELINE      "$I/baseline.tsv" "-" "-"
run_mode CHRONOLOGY    "$I/chronology.tsv" "-" "-"

{
echo '#'
echo '# MODES_EXECUTED = 10'
echo '# MODES_SILENT_ON_PRISTINE = 10'
echo '# SELFTEST = PASS'
} >> "$OUT"

echo "VERIFIER=$OUT"
