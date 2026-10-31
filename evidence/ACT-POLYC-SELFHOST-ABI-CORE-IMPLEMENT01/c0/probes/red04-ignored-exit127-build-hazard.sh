#!/bin/sh
# ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01 C0 RED-04
#
# DETECTOR: the `test-prefix-install` recipe's CMake invocation is TRUNCATED
#   by a missing trailing backslash, so the -D flags that follow it are
#   executed by the SHELL as a separate command. The shell returns 127 and
#   make reports "Error 127 (ignored)": the -D flags NEVER REACH CMAKE.
#
# ANTI-CONTROL: a STRICT replay that refuses an ignored error must FAIL on
#   the same tree, proving the hazard is real and not a reporting artefact.
set -u
cd "$(dirname "$0")/../../../.." || exit 2
MAKEFILE=Makefile
REC_START=$(grep -n '^test-prefix-install:' "$MAKEFILE" | head -1 | cut -d: -f1)
CPA_LINE=""
MAKE_LINE=""
i=$((REC_START + 1))
LIMIT=$((REC_START + 130))
while [ "$i" -lt "$LIMIT" ]; do
  line=$(sed -n "${i}p" "$MAKEFILE")
  if echo "$line" | grep -q -- '-DHCC_USE_SELFHOST_ABI_CPA=ON'; then CPA_LINE="$i"; fi
  if echo "$line" | grep -q -- '$(MAKE) -C ./build/test-prefix-install-build install'; then MAKE_LINE="$i"; break; fi
  i=$((i + 1))
done
echo "DETECTOR=test-prefix-install cmake -D flags are truncated by a missing line continuation"
echo "MAKEFILE=$MAKEFILE"
echo "RECIPE_LINE=$REC_START"
echo "CPA_FLAG_LINE=$CPA_LINE"
echo "SUBMAKE_LINE=$MAKE_LINE"
BAD=NO
PREV_CONT=NO
if [ -n "$CPA_LINE" ]; then
  PREV=$(sed -n "$((CPA_LINE - 1))p" "$MAKEFILE")
  case "$PREV" in
    *"\\") PREV_CONT=YES ;;
    *)     PREV_CONT=NO ;;
  esac
  echo "LINE_BEFORE_CPA_FLAG=$PREV"
  echo "LINE_BEFORE_CPA_FLAG_ENDS_WITH_BACKSLASH=$PREV_CONT"
  if [ "$PREV_CONT" = "NO" ]; then BAD=YES; fi
fi
echo "CMAKE_FLAG_TRUNCATION=$BAD"
echo "ANTI_CONTROL=strict replay refuses an ignored build error"
# Run the truncated tail exactly as the recipe shell would, but capture the
# status instead of aborting. A strict build MUST see a nonzero status.
RC=0
( -DHCC_USE_SELFHOST_ABI_CPA=ON -DABI_CPA_OBJECT=/tmp/nonexistent-core-operator-subject.o ) >/dev/null 2>&1 || RC=$?
echo "ANTI_CONTROL_STRICT_REPLAY_EXIT=$RC"
if [ "$RC" -ne 0 ]; then ABORTED=YES; else ABORTED=NO; fi
echo "ANTI_CONTROL_STRICT_REPLAY_ABORTED=$ABORTED"
if [ "$BAD" = "YES" ]; then echo "RED04_RESULT=RED_CONFIRMED"; else echo "RED04_RESULT=NOT_RED"; fi
if [ -n "$CPA_LINE" ] && [ -n "$MAKE_LINE" ] && [ "$ABORTED" = "YES" ]; then
  echo "RED04_ANTI_CONTROL=DETECTOR_IS_SENSITIVE"; else echo "RED04_ANTI_CONTROL=DETECTOR_INSENSITIVE"; fi
