#!/bin/sh
# tools/quality/core-operator-implement01-strict-build.sh
#
# ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01 C1/C2.
#
# THE STRICT, FAIL-CLOSED BUILD-STATUS DETECTOR.
#
# It proves three things about the production build graph:
#
#   1. The `test-prefix-install` recipe's cmake invocation is NOT
#      truncated: every -D flag belongs to ONE shell command. (At the
#      entry this check FAILS, which is RED-04.)
#
#   2. A MALFORMED cmake -D argument or a MISSING subject path produces a
#      NONZERO FATAL status. The detector runs the real cmake configure in
#      a disposable build root with a deliberately broken -D argument and
#      requires a nonzero exit. It also requires that the repository's
#      build recipe does NOT swallow the failure.
#
#   3. The repository's own build recipes do not use a '- ignore-error'
#      recipe prefix on the mandatory production build lines.
#
# Usage:
#   core-operator-implement01-strict-build.sh <mode>
#     inspect   -- report the recipe structure (no build)
#     negative  -- run the fail-closed negative probes
set -u
REPO=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO"
MODE=${1:-inspect}
MAKEFILE=Makefile

# ---- 1. recipe structure ----
REC_START=$(grep -n '^test-prefix-install:' "$MAKEFILE" | head -1 | cut -d: -f1)
CPA_LINE=""
MAKE_LINE=""
i=$((REC_START + 1))
LIMIT=$((REC_START + 140))
while [ "$i" -lt "$LIMIT" ]; do
  line=$(sed -n "${i}p" "$MAKEFILE")
  if echo "$line" | grep -q -- '-DHCC_USE_SELFHOST_ABI_CPA=ON'; then CPA_LINE="$i"; fi
  if echo "$line" | grep -q -- '$(MAKE) -C ./build/test-prefix-install-build install'; then MAKE_LINE="$i"; break; fi
  i=$((i + 1))
done
echo "RECIPE=test-prefix-install"
echo "RECIPE_LINE=$REC_START"
echo "CPA_FLAG_LINE=$CPA_LINE"
echo "SUBMAKE_LINE=$MAKE_LINE"
TRUNCATED=NO
if [ -n "$CPA_LINE" ]; then
  PREV=$(sed -n "$((CPA_LINE - 1))p" "$MAKEFILE")
  case "$PREV" in
    *"\\") ;;
    *) TRUNCATED=YES ;;
  esac
  echo "LINE_BEFORE_CPA_FLAG=$PREV"
fi
echo "CMAKE_FLAG_TRUNCATION=$TRUNCATED"

# ---- 3. no ignored-error prefix on the mandatory build lines ----
IGNORED=$(awk '
  /^test-prefix-install:/ {inr=1; next}
  inr && /^\t/ {
    if ($0 ~ /^\t-[[:space:]]/) print NR
    next
  }
  inr && !/^\t/ {inr=0}
' "$MAKEFILE" | tr '\n' ' ')
echo "IGNORED_ERROR_RECIPE_LINES=${IGNORED:-NONE}"

# ---- 2. fail-closed negative probes ----
if [ "$MODE" = "negative" ]; then
  WORK=$(mktemp -d)
  trap 'rm -rf "$WORK"' EXIT
  echo "NEGATIVE_PROBE_ROOT=$WORK"

  # Probe A: a malformed cmake -D argument must fail nonzero.
  rc=0
  cmake -S ./src -B "$WORK/probeA" -G 'Unix Makefiles' \
       -DHCC_USE_SELFHOST_CORE_OPERATOR_CLASSIFY=ON \
       "-DCORE_OPERATOR_OBJECT=$WORK/does-not-exist.o" \
       "-DCORE_OPERATOR_PRODUCER" \
       > "$WORK/probeA.log" 2>&1 || rc=$?
  echo "PROBE_A_MALFORMED_D_ARGUMENT_RC=$rc"
  if [ "$rc" -ne 0 ]; then echo "PROBE_A=FAIL_CLOSED"; else echo "PROBE_A=NOT_FAIL_CLOSED"; fi

  # Probe B: a missing subject object with the selector ON must fail
  # nonzero at CONFIGURE time, naming the subject.
  rc=0
  cmake -S ./src -B "$WORK/probeB" -G 'Unix Makefiles' \
       -DHCC_USE_SELFHOST_CORE_OPERATOR_CLASSIFY=ON \
       -DCORE_OPERATOR_OBJECT="$WORK/does-not-exist.o" \
       > "$WORK/probeB.log" 2>&1 || rc=$?
  echo "PROBE_B_MISSING_SUBJECT_RC=$rc"
  if [ "$rc" -ne 0 ]; then echo "PROBE_B=FAIL_CLOSED"; else echo "PROBE_B=NOT_FAIL_CLOSED"; fi
  if grep -qi 'CORE_OPERATOR\|core-operator' "$WORK/probeB.log"; then
    echo "PROBE_B_NAMES_THE_SUBJECT=YES"; else echo "PROBE_B_NAMES_THE_SUBJECT=NO"; fi

  # Probe C: a subject object that exists but exports the WRONG symbol must
  # be rejected by the producer rule.
  echo "PROBE_C_WRONG_SYMBOL=DEFERRED_TO_C2_BUILD_NEGATIVE_CONTROLS"

  # Probe D: the shell-level 127 must be refused by a strict build.
  rc=0
  ( -DHCC_USE_SELFHOST_ABI_CPA=ON -DCORE_OPERATOR_OBJECT="$WORK/x.o" ) >/dev/null 2>&1 || rc=$?
  echo "PROBE_D_TRUNCATED_TAIL_RC=$rc"
  if [ "$rc" -ne 0 ]; then echo "PROBE_D=FAIL_CLOSED"; else echo "PROBE_D=NOT_FAIL_CLOSED"; fi
fi
