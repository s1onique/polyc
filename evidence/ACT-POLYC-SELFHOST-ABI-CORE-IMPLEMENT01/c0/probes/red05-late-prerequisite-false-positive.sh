#!/bin/sh
# ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01 C0 RED-05
#
# DETECTOR: a build rule whose prerequisite VARIABLE is declared AFTER the
#   consuming rule expands that prerequisite to EMPTY. The object is then
#   never built, a MISSING input silently yields exit 0, and a FAKE object
#   can be accepted as the real subject.
# ANTI-CONTROL: the SAME detector applied to the EXISTING, correctly
#   ordered CPA subject rule must PASS, proving the detector distinguishes
#   a correctly wired prerequisite from an empty one.
set -u
cd "$(dirname "$0")/../../../.." || exit 2
MAKEFILE=Makefile
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo "DETECTOR=a prerequisite variable declared after the consuming rule expands to EMPTY"

# LATE declaration: the variable is defined AFTER the rule that uses it.
cat > "$WORK/Makefile" <<'MK'
all: $(SUBJ_OBJ)
	@echo "BUILD_RC=0"
$(SUBJ_OBJ):
	@rm -f $@
	@echo "FAKE" > $@
	@echo "produced $@"
SUBJ_OBJ = ./subj.o
MK
rm -f "$WORK/subj.o"
( cd "$WORK" && make -s all ) > "$WORK/late.out" 2>&1
LATE_RC=$?
LATE_PRODUCED=NO
[ -f "$WORK/subj.o" ] && LATE_PRODUCED=YES
echo "LATE_DECLARATION_MAKE_RC=$LATE_RC"
echo "LATE_DECLARATION_PRODUCED_OBJECT=$LATE_PRODUCED"
echo "LATE_DECLARATION_OUTPUT=$(tr '\n' '|' < "$WORK/late.out")"

# EARLY declaration: the variable is defined BEFORE the rule that uses it.
cat > "$WORK/Makefile" <<'MK'
SUBJ_OBJ = ./subj.o
all: $(SUBJ_OBJ)
	@echo "BUILD_RC=0"
$(SUBJ_OBJ):
	@rm -f $@
	@echo "FAKE" > $@
	@echo "produced $@"
MK
rm -f "$WORK/subj.o"
( cd "$WORK" && make -s all ) > "$WORK/early.out" 2>&1
EARLY_RC=$?
EARLY_PRODUCED=NO
[ -f "$WORK/subj.o" ] && EARLY_PRODUCED=YES
echo "EARLY_DECLARATION_MAKE_RC=$EARLY_RC"
echo "EARLY_DECLARATION_PRODUCED_OBJECT=$EARLY_PRODUCED"

echo "ANTI_CONTROL=the existing CPA subject rule declares its variable BEFORE the consuming rule"
CPA_VAR=$(grep -n '^ABI_CPA_OBJ *=' "$MAKEFILE" | head -1 | cut -d: -f1)
CPA_RULE=$(grep -n '^\$(ABI_CPA_OBJ):' "$MAKEFILE" | head -1 | cut -d: -f1)
echo "CPA_VAR_DECLARED_AT_LINE=$CPA_VAR"
echo "CPA_RULE_AT_LINE=$CPA_RULE"
CPA_ORDERING=UNKNOWN
if [ -n "$CPA_VAR" ] && [ -n "$CPA_RULE" ] && [ "$CPA_VAR" -lt "$CPA_RULE" ]; then
  CPA_ORDERING=CORRECT
elif [ -n "$CPA_VAR" ] && [ -n "$CPA_RULE" ]; then
  CPA_ORDERING=INCORRECT
fi
echo "CPA_ORDERING=$CPA_ORDERING"

# The hazard is REAL when the late declaration exits 0 WITHOUT producing the
# object, while the early declaration exits 0 AND produces it.
if [ "$LATE_RC" -eq 0 ] && [ "$LATE_PRODUCED" = "NO" ] && [ "$EARLY_RC" -eq 0 ] && [ "$EARLY_PRODUCED" = "YES" ]; then
  echo "RED05_RESULT=RED_CONFIRMED"; else echo "RED05_RESULT=NOT_RED"; fi
if [ "$CPA_ORDERING" = "CORRECT" ]; then
  echo "RED05_ANTI_CONTROL=DETECTOR_IS_SENSITIVE"; else echo "RED05_ANTI_CONTROL=DETECTOR_INSENSITIVE"; fi
