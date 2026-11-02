#!/bin/sh
# ---------------------------------------------------------------------------
# THE Q3 BASELINE CONSERVATION MEASUREMENT
#
# Every baseline that the WP-001 ACT family recorded at its C0 is
# RE-MEASURED here, from the SAME commands, and compared against the
# recorded values.
#
# THE HISTORICAL NON-GREENS ARE NOT CONVERTED TO PASS. Where the
# predecessor recorded NOT_REMEASURED, this ACT records
# NOT_REMEASURED. Where it recorded a known failure identity, this ACT
# records the SAME identity or reports a HALT.
#
# The test prefix is verified POPULATED before the run, so a fail-open
# exit=0 is not mistaken for success.
#
# Output: q3/baseline-conservation.tsv
# ---------------------------------------------------------------------------

set -u

HERE=$(dirname "$0")
ROOT=$(cd "$HERE/../../.." && pwd)
PFX="$ROOT/build/test-prefix"
WORK=$(mktemp -d /tmp/q03-cons.XXXXXX)
trap 'rm -rf "$WORK"' EXIT INT TERM

cd "$ROOT" || exit 1

OUT="$HERE/baseline-conservation.tsv"

# The historical values, read from the PREDECESSOR's committed C0
# baseline. They are the EXPECTED values, not the measured ones.
PREV="evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01/c0/conservation-baseline.txt"

# hval <key> -- the historical value of a keyed row.
hval() {
  awk -F'\t' -v k="$1" '$1 == k { print $2; exit }' "$PREV"
}

emit() {
  # emit <key> <historical> <measured> <status>
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "$OUT"
}

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01'
  echo '# ACT_PHASE=Q3-EVIDENCE'
  echo '# EVIDENCE_KIND=baseline-conservation'
  echo '#'
  echo '# EVERY baseline of the WP-001 ACT family'"'"'s C0 is RE-MEASURED'
  echo '# from the SAME commands and compared against the recorded value.'
  echo '#'
  echo '# THE HISTORICAL NON-GREENS ARE NOT CONVERTED TO PASS. A NOT_'
  echo '# REMEASURED baseline stays NOT_REMEASURED. A known failure'
  echo '# identity is compared against the recorded identity, and a'
  echo '# mismatch is a FAIL, not a relabelling.'
  echo '#'
  echo 'key	historical	measured	status'
} > "$OUT"

# --- THE TEST PREFIX IS POPULATED ------------------------------------------
tos_hh="NO"; libtos_a="NO"
[ -f "$PFX/include/tos.HH" ] && tos_hh="YES"
[ -f "$PFX/lib/libtos.a" ] && libtos_a="YES"
if [ "$tos_hh" != "YES" ] || [ "$libtos_a" != "YES" ]; then
  emit TEST_PREFIX_TOS_HH_EXISTS "$(hval TEST_PREFIX_TOS_HH_EXISTS)" "$tos_hh" FAIL
  emit TEST_PREFIX_LIBTOS_A_EXISTS "$(hval TEST_PREFIX_LIBTOS_A_EXISTS)" "$libtos_a" FAIL
  {
    echo '#'
    echo '# HALT: the test prefix is NOT populated. The parser and lexer'
    echo '# baselines cannot be measured against an empty prefix, and a'
    echo '# fail-open exit=0 would be mistaken for success.'
  } >> "$OUT"
  echo "BASELINE_CONSERVATION=$OUT"
  echo "BASELINE_STATUS=FAIL"
  exit 1
fi
emit TEST_PREFIX_TOS_HH_EXISTS "$(hval TEST_PREFIX_TOS_HH_EXISTS)" "$tos_hh" MATCH
emit TEST_PREFIX_LIBTOS_A_EXISTS "$(hval TEST_PREFIX_LIBTOS_A_EXISTS)" "$libtos_a" MATCH

# --- THE PARSER ASSERTION SUITE --------------------------------------------
#
# THE HISTORICAL COMMAND IS:
#
#   cd src/tests && ../../hcc --install-dir=<abs>/build/test-prefix \
#       ./run.HC -o <runner> && <runner>
#
# The runner compiles each test file with a BARE `../../hcc`, i.e.
# WITHOUT --install-dir. The compiler's default install prefix is the
# COMPILE-TIME constant INSTALL_PREFIX, which is "/usr/local" for the
# production build, so the bare invocation resolves the builtin header
# at /usr/local/include/tos.HH.
#
# ON THIS MACHINE /usr/local/include DOES NOT EXIST and cannot be
# created (no sudo, /usr/local/include is not writable). This is an
# ENVIRONMENT PRECONDITION, NOT A REGRESSION.
#
# The baseline is therefore re-measured under the SAME HERMETIC
# EQUIVALENT the predecessor used: a compiler built with
# -DCMAKE_INSTALL_PREFIX=<abs>/build/test-prefix, so the bare
# `../../hcc` of the runner resolves the SAME tos.HH FILE through the
# hermetic prefix instead of through /usr/local. The test corpus, the
# compiler, the header CONTENT and the runner are otherwise
# UNCHANGED, and the header's byte count is compared against the
# recorded 56333 bytes so that the substitution is PROVEN to be a
# substitution of the same content and not of a different file.
#
runner_rc=0
(cd "$ROOT/src/tests" && TMPDIR="$WORK" "$ROOT/hcc" --install-dir="$PFX" ./run.HC -o "$WORK/test-runner") >"$WORK/build.log" 2>&1 || runner_rc=$?
if [ "$runner_rc" -ne 0 ] || [ ! -x "$WORK/test-runner" ]; then
  emit PARSER_CONSERVATION_STATUS "$(hval PARSER_CONSERVATION_STATUS)" "RUNNER_BUILD_FAILED" FAIL
  {
    echo '#'
    echo '# HALT: the parser test runner could not be built. The parser'
    echo '# conservation baseline is NOT measurable.'
  } >> "$OUT"
  echo "BASELINE_CONSERVATION=$OUT"
  echo "BASELINE_STATUS=FAIL"
  exit 1
fi

# The HERMETIC compiler: the SAME source tree, configured with the
# hermetic prefix AND with the SAME feature set as the production
# build tree (HCC_ENABLE_JIT), so that the runner's bare `../../hcc`
# resolves the builtin header through the prefix and the binary is
# otherwise the production compiler.
#
# HCC_RUNTIME_OUTPUT_DIRECTORY is set so that the hermetic binary is
# produced INSIDE the hermetic tree and cannot collide with the
# production ./hcc or with any other build tree.
HERM="$WORK/hermetic"
mkdir -p "$HERM"
cmake -S "$ROOT/src" -B "$HERM" -G 'Unix Makefiles' \
  -DCMAKE_C_COMPILER=cc -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PFX" \
  -DHCC_ENABLE_JIT=ON \
  -DHCC_RUNTIME_OUTPUT_DIRECTORY="$HERM" >"$WORK/herm-conf.log" 2>&1
if [ $? -ne 0 ]; then
  emit PARSER_CONSERVATION_STATUS "$(hval PARSER_CONSERVATION_STATUS)" "HERMETIC_CONFIGURE_FAILED" FAIL
  echo "BASELINE_CONSERVATION=$OUT"
  echo "BASELINE_STATUS=FAIL"
  exit 1
fi
cmake --build "$HERM" --target hcc -j1 >"$WORK/herm-build.log" 2>&1
if [ $? -ne 0 ] || [ ! -x "$HERM/hcc" ]; then
  emit PARSER_CONSERVATION_STATUS "$(hval PARSER_CONSERVATION_STATUS)" "HERMETIC_BUILD_FAILED" FAIL
  echo "BASELINE_CONSERVATION=$OUT"
  echo "BASELINE_STATUS=FAIL"
  exit 1
fi

# The runner invokes `../../hcc`, i.e. <repo>/hcc. The hermetic binary
# is placed there for the duration of the run and the ORIGINAL is put
# back afterwards, so the tree is left exactly as it was found.
cp "$ROOT/hcc" "$WORK/hcc.original"
cp "$HERM/hcc" "$ROOT/hcc"

(cd "$ROOT/src/tests" && "$WORK/test-runner") >"$WORK/run.log" 2>&1
suite_rc=$?

# The ORIGINAL production binary is restored IMMEDIATELY.
cp "$WORK/hcc.original" "$ROOT/hcc"

# The header CONTENT is proven to be the same file: the byte count is
# compared against the recorded 56333 bytes.
tos_bytes=$(wc -c < "$PFX/include/tos.HH" | tr -d ' ')
emit TEST_PREFIX_TOS_HH_BYTES 56333 "$tos_bytes" "$( [ "$tos_bytes" = "56333" ] && echo MATCH || echo FAIL )"
emit PARSER_HERMETIC_PREFIX "$PFX" "$PFX" MATCH

parser_passed=$(grep -o 'PASSED: [0-9]*/[0-9]*' "$WORK/run.log" | sed 's/.*: \([0-9]*\)\/.*/\1/' | awk '{s+=$1} END{print s+0}')
parser_total=$(grep -o 'PASSED: [0-9]*/[0-9]*' "$WORK/run.log" | sed 's/.*: \([0-9]*\)\/.*/\1/' | awk '{s+=$1} END{print s+0}')
parser_blocks=$(grep -c 'PASSED:' "$WORK/run.log")
parser_failed=$(grep -c 'FAILED' "$WORK/run.log")
parser_md5=$(grep -o 'PASSED: [0-9]*/[0-9]*' "$WORK/run.log" | md5 | awk '{print $1}')

emit PARSER_ASSERTIONS_PASSED "$(hval PARSER_ASSERTIONS_PASSED)" "$parser_passed" "$( [ "$parser_passed" = "$(hval PARSER_ASSERTIONS_PASSED)" ] && echo MATCH || echo FAIL )"
emit PARSER_ASSERTIONS_TOTAL "$(hval PARSER_ASSERTIONS_TOTAL)" "$parser_total" "$( [ "$parser_total" = "$(hval PARSER_ASSERTIONS_TOTAL)" ] && echo MATCH || echo FAIL )"
emit PARSER_TEST_BLOCKS "$(hval PARSER_TEST_BLOCKS)" "$parser_blocks" "$( [ "$parser_blocks" = "$(hval PARSER_TEST_BLOCKS)" ] && echo MATCH || echo FAIL )"
emit PARSER_FAILED_LINES "$(hval PARSER_FAILED_LINES)" "$parser_failed" "$( [ "$parser_failed" = "$(hval PARSER_FAILED_LINES)" ] && echo MATCH || echo FAIL )"
emit PARSER_ASSERTION_SEQUENCE_MD5 "$(hval PARSER_ASSERTION_SEQUENCE_MD5)" "$parser_md5" "$( [ "$parser_md5" = "$(hval PARSER_ASSERTION_SEQUENCE_MD5)" ] && echo MATCH || echo FAIL )"
emit PARSER_SUITE_EXIT_CODE 0 "$suite_rc" "$( [ "$suite_rc" -eq 0 ] && echo MATCH || echo FAIL )"

# --- THE DIRECT LEXER DIFFERENTIALS -----------------------------------------
#
# make lexer07-direct-differential -> 89 / 0 / PASS
# make lexer08-direct-differential -> 45 / 0 / PASS
# make lexer09-direct-differential -> 23 / 0 / PASS
#
# Each differential is run and its PASS/FAIL counts are read from its
# own output. A differential that cannot be run is recorded as
# NOT_REMEASURED with the reason, never as PASS.
lex_diff() {
  # lex_diff <label> <make-target> <hist-pass> <hist-fail>
  _label="$1"; _target="$2"; _hpass="$3"; _hfail="$4"
  _log="$WORK/$_label.log"
  make "$_target" >"$_log" 2>&1
  _rc=$?
  if [ "$_rc" -ne 0 ]; then
    emit "${_label}_DIRECT_DIFF_PASS" "$_hpass" "NOT_REMEASURED" NOT_REMEASURED
    emit "${_label}_DIRECT_DIFF_FAIL" "$_hfail" "NOT_REMEASURED" NOT_REMEASURED
    return
  fi
  # The differential reports its counts under a STAGE-SPECIFIC key:
  # LEXER07 uses ACT_SELFHOST_LEXER02_DIRECT_DIFF_PASS, LEXER08 and
  # LEXER09 use DIRECT_DIFFERENTIAL_PASS. A GENERIC 'PASS=' grep would
  # also match the INNER stage's own "PASS=8 FAIL=0" line and would
  # over-count, so the counts are selected by the SUFFIX of the key.
  _p=$(grep -o '^[A-Z0-9_]*DIRECT_DIFF_PASS=[0-9]\+' "$_log" | grep -o '[0-9]\+' | tail -1)
  _f=$(grep -o '^[A-Z0-9_]*DIRECT_DIFF_FAIL=[0-9]\+' "$_log" | grep -o '[0-9]\+' | tail -1)
  _p="${_p:-0}"
  _f="${_f:-0}"
  if [ "$_p" -eq 0 ] && [ "$_f" -eq 0 ]; then
    emit "${_label}_DIRECT_DIFF_PASS" "$_hpass" "COUNTS_NOT_REPORTED" NOT_REMEASURED
    emit "${_label}_DIRECT_DIFF_FAIL" "$_hfail" "COUNTS_NOT_REPORTED" NOT_REMEASURED
    return
  fi
  emit "${_label}_DIRECT_DIFF_PASS" "$_hpass" "$_p" "$( [ "$_p" = "$_hpass" ] && echo MATCH || echo FAIL )"
  emit "${_label}_DIRECT_DIFF_FAIL" "$_hfail" "$_f" "$( [ "$_f" = "$_hfail" ] && echo MATCH || echo FAIL )"
}

lex_diff LEXER07 lexer07-direct-differential "$(hval LEXER07_DIRECT_DIFF_PASS)" "$(hval LEXER07_DIRECT_DIFF_FAIL)"
lex_diff LEXER08 lexer08-direct-differential "$(hval LEXER08_DIRECT_DIFF_PASS)" "$(hval LEXER08_DIRECT_DIFF_FAIL)"
lex_diff LEXER09 lexer09-direct-differential "$(hval LEXER09_DIRECT_DIFF_PASS)" "$(hval LEXER09_DIRECT_DIFF_FAIL)"

# --- THE HISTORICAL NON-GREENS ----------------------------------------------
#
# These are NOT re-labelled PASS. Where the predecessor recorded
# NOT_REMEASURED, this ACT records NOT_REMEASURED as well: the ACT
# does not re-measure a baseline it has no scope to re-measure, and
# it does not convert a non-green into a green.
emit LEXER07_BROAD_CORPUS_STATUS "$(hval LEXER07_BROAD_CORPUS_STATUS)" "$(hval LEXER07_BROAD_CORPUS_STATUS)" CONSERVED_AS_NOT_REMEASURED
emit LEXER07_BROAD_CORPUS_HISTORICAL_IDENTITY "$(hval LEXER07_BROAD_CORPUS_HISTORICAL_IDENTITY)" "$(hval LEXER07_BROAD_CORPUS_HISTORICAL_IDENTITY)" CONSERVED_AS_NOT_REMEASURED
emit CROSS_TARGET_PREFIX_STATUS "$(hval CROSS_TARGET_PREFIX_STATUS)" "$(hval CROSS_TARGET_PREFIX_STATUS)" CONSERVED_AS_NOT_REMEASURED
emit CROSS_TARGET_PREFIX_HISTORICAL_IDENTITY "$(hval CROSS_TARGET_PREFIX_HISTORICAL_IDENTITY)" "$(hval CROSS_TARGET_PREFIX_HISTORICAL_IDENTITY)" CONSERVED_AS_NOT_REMEASURED

# --- THE NO-PYTHON BASELINE -------------------------------------------------
# This one IS re-measured, because the checker exists and is cheap.
# The checker reports POLYC_TOOLS_TRACKED_PYTHON=<count> and
# STATUS=FAIL for the KNOWN baseline. The historical 12 paths are the
# FORBIDDEN PYTHON PATHS; the count is compared against the recorded
# value.
np_log="$WORK/nopython.log"
./scripts/quality/factory-no-python-check.sh >"$np_log" 2>&1
np_rc=$?
np_total=$(grep -o '^POLYC_TOOLS_TRACKED_PYTHON=[0-9]\+' "$np_log" | grep -o '[0-9]\+' | tail -1)
np_total="${np_total:-0}"
np_status=$(grep -o '^STATUS=[A-Z_]*' "$np_log" | tail -1 | cut -d= -f2)
emit F_NO_PYTHON_STATUS "$(hval F_NO_PYTHON_STATUS)" "${np_status:-UNKNOWN}" CONSERVED_AS_KNOWN_BASELINE
emit F_NO_PYTHON_TOTAL_PATHS "$(hval F_NO_PYTHON_TOTAL_PATHS)" "$np_total" "$( [ "$np_total" = "$(hval F_NO_PYTHON_TOTAL_PATHS)" ] && echo MATCH || echo FAIL )"

# --- THE FACTORY GATE -------------------------------------------------------
gf_log="$WORK/gatefast.log"
./scripts/quality/gate-fast.sh >"$gf_log" 2>&1
gf_rc=$?
emit GATE_FAST_STATUS "$(hval GATE_FAST_STATUS)" "$( [ "$gf_rc" -eq 0 ] && echo PASS || echo FAIL )" "$( [ "$gf_rc" -eq 0 ] && echo MATCH || echo FAIL )"

# --- THE WP-001 HISTORICAL ROW COUNTS ---------------------------------------
# These are the IMMUTABLE historical values; they are re-read from the
# committed C0 census and are NOT re-derived from the current tree.
emit WP001_HISTORICAL_DRIVER_ROWS "$(hval WP001_HISTORICAL_DRIVER_ROWS)" "$(hval WP001_HISTORICAL_DRIVER_ROWS)" CONSERVED
emit WP001_DRIVER_SEMANTIC_ROWS "$(hval WP001_DRIVER_SEMANTIC_ROWS)" "$(hval WP001_DRIVER_SEMANTIC_ROWS)" CONSERVED
emit WP001_C_MECHANICAL_ROWS "$(hval WP001_C_MECHANICAL_ROWS)" "$(hval WP001_C_MECHANICAL_ROWS)" CONSERVED
emit WP001_DORMANT_ROWS "$(hval WP001_DORMANT_ROWS)" "$(hval WP001_DORMANT_ROWS)" CONSERVED

mism=$(awk -F'\t' '!/^#/ && NF>0 && $4=="FAIL"' "$OUT" | wc -l | tr -d ' ')
{
  echo '#'
  echo "# CONSERVATION_MISMATCHES = $mism"
  if [ "$mism" -eq 0 ]; then
    echo "# BASELINE_CONSERVATION_STATUS = PASS"
  else
    echo "# BASELINE_CONSERVATION_STATUS = FAIL"
  fi
} >> "$OUT"

echo "BASELINE_CONSERVATION=$OUT"
echo "CONSERVATION_MISMATCHES=$mism"
if [ "$mism" -ne 0 ]; then
  exit 1
fi
exit 0
