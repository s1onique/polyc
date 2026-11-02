#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01/q0/run-cli-corpus.sh
#
# ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01 Q0 RED.
#
# Runs the real CLI corpus through BOTH compiler generations (the
# selector-ON production compiler and the selector-OFF C-only oracle
# G0) and records the exit code, the stdout size and the produced
# artifact for every case.
#
# The corpus is the predecessor's frozen 14-case set PLUS the
# source-derived route-discriminating cases this audit adds. Each case
# names the DECISION it exercises and the expected OWNER of that
# decision.
#
# F-POLYC-TOOLS: orchestration glue, under the 50 LOC shell budget.

set -u

EV="evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01/q0"
OUT="$EV/baseline-and-real-cli.tsv"
REPO=$(pwd)
ON="$REPO/hcc"
G0="${G0_BIN:-/tmp/q01/hcc}"
PFX="$REPO/build/test-prefix"
WORK=$(mktemp -d /tmp/q01-cli.XXXXXX)
trap 'rm -rf "$WORK"' EXIT INT TERM

printf 'I64 main() {\n  return 0;\n}\n' > "$WORK/input.HC"

# case <id> <expected_owner> <note> <argv...>
case_run() {
  _id="$1"; _owner="$2"; _note="$3"; shift 3
  _shape="$*"

  rm -f "$WORK/out.o" "$WORK/out.s" "$WORK/out.txt"
  _onout=$(cd "$WORK" && "$ON" --install-dir="$PFX" "$@" 2>"$WORK/on.err"); _orc=$?
  _onlines=$(printf '%s' "$_onout" | wc -l | tr -d ' ')
  _onart="NONE"
  if [ -f "$WORK/out.o" ]; then _onart="out.o:$(file -b "$WORK/out.o" | cut -d, -f1)"; fi
  if [ -f "$WORK/out.s" ]; then _onart="out.s:assembly"; fi
  _onerr=$(head -1 "$WORK/on.err" 2>/dev/null | tr -d '\n')

  rm -f "$WORK/out.o" "$WORK/out.s" "$WORK/out.txt"
  _g0out=$(cd "$WORK" && "$G0" --install-dir="$PFX" "$@" 2>"$WORK/g0.err"); _grc=$?
  _g0art="NONE"
  if [ -f "$WORK/out.o" ]; then _g0art="out.o:$(file -b "$WORK/out.o" | cut -d, -f1)"; fi
  if [ -f "$WORK/out.s" ]; then _g0art="out.s:assembly"; fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_id" "$_shape" "$_owner" "$_orc" "$_onlines" "$_onart" \
    "$_grc" "$_g0art" "${_onerr:-NO_STDERR}" "$_note" >> "$OUT"
}

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01'
  echo '# ACT_PHASE=Q0-RED'
  echo '# EVIDENCE_KIND=baseline-and-real-cli'
  echo '#'
  echo '# Both compiler generations executed over the frozen corpus.'
  echo '# c_on_* is the selector-ON production compiler; g0_* is the'
  echo '# selector-OFF C-only oracle. The two must AGREE on the route.'
  echo '#'
  printf 'case_id\targv_shape\texpected_decision_owner\tc_on_exit\tc_on_stdout_lines\tc_on_artifact\tg0_exit\tg0_artifact\tc_on_first_stderr_line\tnote\n'
} > "$OUT"

# --- THE PREDECESSOR FROZEN 14-CASE CORPUS -------------------------------
case_run C01_help              POLYC_DRIVER "option classification and the HELP action"  --help
case_run C02_version           POLYC_DRIVER "option classification and the VERSION action" --version
case_run C03_no_args           POLYC_DRIVER "the no-input-file status" --install-dir="$PFX"
case_run C04_unknown_option    POLYC_DRIVER "the unknown-argument status" --bogus
case_run C05_missing_o_value   POLYC_DRIVER "the arity-violation status" -o
case_run C06_nonexistent_src   C_ENGINE     "a well-formed request whose input is missing" -c nonexistent.HC -o out.o
case_run C07_compile_object    POLYC_DRIVER "the compile-object action" -c input.HC -o out.o
case_run C08_install_dir_eq    POLYC_DRIVER "the = suffix value source" --install-dir="$PFX"
case_run C09_o_dashdash        POLYC_DRIVER "the unknown-argument status" --
case_run C10_permuted          POLYC_DRIVER "the NEXT value source" -o out.o -c input.HC
case_run C11_dup_c             POLYC_DRIVER "the repeated-flag action" -c -c input.HC -o out.o
case_run C12_source_only       C_ENGINE     "the source-only default route" input.HC
case_run C13_define_flag       POLYC_DRIVER "the -D suffix value" -D FOO input.HC
case_run C14_unknown_short     POLYC_DRIVER "the unknown-argument status" -z input.HC

# --- THE AUDIT-ADDED ROUTE-DISCRIMINATING CASES --------------------------
case_run A01_assemble_only     C_EMITFILE   "the emitFile assembly arm" -S input.HC -o out.s
case_run A02_emit_object_only  C_EMITFILE   "the emitFile object arm" -c input.HC -o out.o
case_run A03_tokens            C_MAIN       "the main action dispatch: tokens" -tokens input.HC
case_run A04_transpile         C_MAIN       "the main action dispatch: transpile" -transpile input.HC
case_run A05_ast               C_MAIN       "the main action dispatch: ast" -ast input.HC
case_run A06_cfg               C_MAIN       "the main action dispatch: cfg" -cfg input.HC
case_run A07_dump_ir           C_MAIN       "the main action dispatch: dump-ir" --dump-ir input.HC

echo "CLI_CORPUS=$OUT"
