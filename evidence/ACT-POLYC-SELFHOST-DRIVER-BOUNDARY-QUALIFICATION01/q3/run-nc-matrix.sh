#!/bin/sh
# ---------------------------------------------------------------------------
# THE Q3 NEGATIVE-CONTROL MATRIX
#
# Every NC01..NC24 negative control from the FROZEN Q0 roster is
# executed PRISTINE / ADVERSE / RESTORED against the COMPILED PolyC
# detectors, and each must produce its OWN expected reason token on the
# adverse phase and be SILENT on the pristine phase.
#
# TWO DETECTORS ARE USED:
#
#   RED     build/driver-boundary-qualification01-red   (the Q0 detector)
#   VERIFY  build/driver-boundary-qualification01-verify (the Q2 verifier)
#
# The mapping from each NC to its detector and to its adversarial
# construction is EXPLICIT and is recorded in the output table, so the
# matrix is auditable rather than asserted.
#
# Every adverse test is performed on a DISPOSABLE COPY. No committed
# input file is ever mutated.
#
# Output: q3/nc01-nc24-execution-matrix.tsv
# ---------------------------------------------------------------------------

set -u

HERE=$(dirname "$0")
ROOT=$(cd "$HERE/../../.." && pwd)
EV="$ROOT/evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01"
Q0="$EV/q0"
Q2="$EV/q2"
I="$Q2/inputs"
RED="$ROOT/build/driver-boundary-qualification01-red"
VERIFY="$ROOT/build/driver-boundary-qualification01-verify"
OUT="$HERE/nc01-nc24-execution-matrix.tsv"
TMP=$(mktemp -d /tmp/q03-nc.XXXXXX)
trap 'rm -rf "$TMP"' EXIT INT TERM

cd "$ROOT" || exit 1

if [ ! -x "$RED" ] || [ ! -x "$VERIFY" ]; then
  echo "nc-matrix: a required detector binary is missing" >&2
  exit 2
fi

pass=0
fail=0

# emit <nc_id> <reason> <phase> <rc> <token> <detail>
emit() {
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" "$6" >> "$OUT"
}

# The token check is EXACT: the detector's output must CONTAIN the
# required reason token. A different token is a failure.
has_token() {
  case "$1" in
    *"$2"*) return 0 ;;
    *) return 1 ;;
  esac
}

# nc_verify <nc_id> <reason> <mode> <pristine_file> <adverse_file> [extra]
#
# Runs the Q2 VERIFIER in pristine / adverse / restored order.
nc_verify() {
  _nc="$1"; _req="$2"; _mode="$3"; _pris="$4"; _adv="$5"; _extra="${6-}"

  _pout=$("$VERIFY" "$_mode" "$_pris" $_extra 2>&1); _prc=$?
  _ptok="SILENT"
  has_token "$_pout" "$_req" && _ptok="REASON_TOKEN_PRESENT"
  if [ "$_prc" -eq 0 ] && [ "$_ptok" = "SILENT" ]; then
    emit "$_nc" "$_req" PRISTINE "$_prc" SILENT "detector accepted the true claim"
  else
    emit "$_nc" "$_req" PRISTINE "$_prc" "$_ptok" "UNEXPECTED on pristine"
    fail=$((fail+1))
  fi

  cp "$_adv" "$TMP/adv.tsv"
  _aout=$("$VERIFY" "$_mode" "$TMP/adv.tsv" $_extra 2>&1); _arc=$?
  _atok="NO_REASON_TOKEN"
  has_token "$_aout" "$_req" && _atok="REASON_TOKEN_PRESENT"
  if [ "$_arc" -ne 0 ] && [ "$_atok" = "REASON_TOKEN_PRESENT" ]; then
    emit "$_nc" "$_req" ADVERSE "$_arc" "$_atok" "detector rejected the false claim"
    pass=$((pass+1))
  else
    emit "$_nc" "$_req" ADVERSE "$_arc" "$_atok" "UNEXPECTED on adverse"
    fail=$((fail+1))
  fi

  _rout=$("$VERIFY" "$_mode" "$_pris" $_extra 2>&1); _rrc=$?
  _rtok="SILENT"
  has_token "$_rout" "$_req" && _rtok="REASON_TOKEN_PRESENT"
  if [ "$_rrc" -eq 0 ] && [ "$_rtok" = "SILENT" ]; then
    emit "$_nc" "$_req" RESTORED "$_rrc" SILENT "detector accepted the true claim again"
  else
    emit "$_nc" "$_req" RESTORED "$_rrc" "$_rtok" "UNEXPECTED on restored"
    fail=$((fail+1))
  fi
}

# nc_red <nc_id> <reason> <mode> <primary_input> <pristine_claim> <adverse_claim> [extra]
nc_red() {
  _nc="$1"; _req="$2"; _mode="$3"; _prim="$4"; _pris="$5"; _adv="$6"; _extra="${7-}"

  if [ -n "$_extra" ]; then
    _pout=$("$RED" "$_mode" "$_prim" "$_extra" "$_pris" 2>&1); _prc=$?
  else
    _pout=$("$RED" "$_mode" "$_prim" "$_pris" 2>&1); _prc=$?
  fi
  _ptok="SILENT"
  has_token "$_pout" "$_req" && _ptok="REASON_TOKEN_PRESENT"
  if [ "$_prc" -eq 0 ] && [ "$_ptok" = "SILENT" ]; then
    emit "$_nc" "$_req" PRISTINE "$_prc" SILENT "detector accepted the true claim"
  else
    emit "$_nc" "$_req" PRISTINE "$_prc" "$_ptok" "UNEXPECTED on pristine"
    fail=$((fail+1))
  fi

  cp "$_adv" "$TMP/adv.tsv"
  if [ -n "$_extra" ]; then
    _aout=$("$RED" "$_mode" "$_prim" "$_extra" "$TMP/adv.tsv" 2>&1); _arc=$?
  else
    _aout=$("$RED" "$_mode" "$_prim" "$TMP/adv.tsv" 2>&1); _arc=$?
  fi
  _atok="NO_REASON_TOKEN"
  has_token "$_aout" "$_req" && _atok="REASON_TOKEN_PRESENT"
  if [ "$_arc" -ne 0 ] && [ "$_atok" = "REASON_TOKEN_PRESENT" ]; then
    emit "$_nc" "$_req" ADVERSE "$_arc" "$_atok" "detector rejected the false claim"
    pass=$((pass+1))
  else
    emit "$_nc" "$_req" ADVERSE "$_arc" "$_atok" "UNEXPECTED on adverse"
    fail=$((fail+1))
  fi

  if [ -n "$_extra" ]; then
    _rout=$("$RED" "$_mode" "$_prim" "$_extra" "$_pris" 2>&1); _rrc=$?
  else
    _rout=$("$RED" "$_mode" "$_prim" "$_pris" 2>&1); _rrc=$?
  fi
  _rtok="SILENT"
  has_token "$_rout" "$_req" && _rtok="REASON_TOKEN_PRESENT"
  if [ "$_rrc" -eq 0 ] && [ "$_rtok" = "SILENT" ]; then
    emit "$_nc" "$_req" RESTORED "$_rrc" SILENT "detector accepted the true claim again"
  else
    emit "$_nc" "$_req" RESTORED "$_rrc" "$_rtok" "UNEXPECTED on restored"
    fail=$((fail+1))
  fi
}

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01'
  echo '# ACT_PHASE=Q3-EVIDENCE'
  echo '# EVIDENCE_KIND=nc01-nc24-execution-matrix'
  echo '#'
  echo "# EVERY negative control of the FROZEN Q0 roster, executed"
  echo "# PRISTINE / ADVERSE / RESTORED against the COMPILED PolyC"
  echo "# detectors. The adverse phase must fire the control's OWN"
  echo "# reason token; the pristine and restored phases must be SILENT."
  echo '#'
  echo '# Every adverse test runs on a DISPOSABLE COPY. No committed'
  echo '# input file is ever mutated.'
  echo '#'
  echo 'nc_id	expected_reason	phase	exit_code	reason_token	result_detail'
} > "$OUT"

. "$HERE/nc-cases.sh"

{
  echo '#'
  echo "# ADVERSE_CONTROLS_FIRED = $pass"
  echo "# UNEXPECTED_RESULTS      = $fail"
  echo "# NC_ROSTER_SIZE          = 24"
} >> "$OUT"

echo "NC_MATRIX=$OUT"
echo "ADVERSE_CONTROLS_FIRED=$pass"
echo "UNEXPECTED_RESULTS=$fail"
if [ "$fail" -ne 0 ]; then
  exit 1
fi
exit 0
