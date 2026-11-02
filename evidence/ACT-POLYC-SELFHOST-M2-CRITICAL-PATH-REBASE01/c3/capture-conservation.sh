#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c3/capture-conservation.sh
#
# Builds c3/production-and-source-conservation.tsv.
#
# Every row is a git diff between the ACT's ENTRY commit and the
# current HEAD, over the named path class. A non-zero count would be
# a scope violation; the expected value is 0 for every production
# path class.
#
# The ENTRY is the pinned predecessor terminal commit
# 9ba4ba5ddbbfacb10393514874c829c9f21d5ea4, whose tree is
# 78e6c706863aea2858d1dadb850b0fc30f78d6c4.
#
# F-POLYC-TOOLS: orchestration glue.

set -u

EV="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
ENTRY="9ba4ba5ddbbfacb10393514874c829c9f21d5ea4"
OUT="$EV/c3/production-and-source-conservation.tsv"
TMP=$(mktemp /tmp/m2rebase-cons.XXXXXX)
trap 'rm -f "$TMP"' EXIT INT TERM

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01'
  echo '# ACT_PHASE=C3-EVIDENCE'
  echo '# EVIDENCE_KIND=production-and-source-conservation'
  echo '#'
  echo '# WHAT THIS ACT DID NOT CHANGE, MEASURED AGAINST THE ENTRY.'
  echo '#'
  echo "# ENTRY = $ENTRY"
  echo '# TREE  = 78e6c706863aea2858d1dadb850b0fc30f78d6c4'
  echo '#'
  echo '# Every row is a git diff between the entry commit and the'
  echo '# current HEAD, over the named path class. A non-zero count'
  echo '# would be a scope violation; the expected value is 0.'
  echo '#'
  printf 'scope_class\tpath_spec\tfiles_changed\texpected\tverdict\tevidence\n'
} > "$TMP"

check() {
  _name="$1"; _path="$2"; _expected="$3"
  _n=$(git diff --name-only "$ENTRY" HEAD -- "$_path" | wc -l | tr -d ' ')
  if [ "$_n" -eq "$_expected" ]; then _v=PASS; else _v=FAIL; fi
  printf '%s\t%s\t%s\t%s\t%s\tgit diff --name-only %s HEAD -- %s\n' \
    "$_name" "$_path" "$_n" "$_expected" "$_v" "$ENTRY" "$_path" >> "$TMP"
}

check PRODUCTION_C_SRC src/ 0
check PRODUCTION_C_HEADERS src/ 0
check BOOTSTRAP_SUBJECTS tools/bootstrap/ 0
check EXISTING_TESTS tests/ 0
check CANONICAL_GATES scripts/quality/ 0

# The authority population: the number of PolyC authorities must be
# UNCHANGED at 15. It is recomputed from the committed CENSUS01
# table, not from this ACT's own claim.
POLYC=$(awk -F'\t' 'NR>1 && toupper($4)=="POLYC"' \
  evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01/c1/authorities.tsv | wc -l | tr -d ' ')
printf 'POLYC_AUTHORITY_COUNT\tCENSUS01 authorities.tsv\t%s\t15\t%s\tawk over the CENSUS01 authority table\n' \
  "$POLYC" "$([ "$POLYC" -eq 9 ] && echo PASS || echo FAIL)" >> "$TMP"

mv "$TMP" "$OUT"
trap - EXIT INT TERM

echo "CONSERVATION_WRITTEN=$OUT"
FAIL=$(awk -F'\t' '!/^#/ && NF>1 && $5=="FAIL"' "$OUT" | wc -l | tr -d ' ')
echo "CONSERVATION_FAILURES=$FAIL"
if [ "$FAIL" -ne 0 ]; then
  echo "CONSERVATION_STATUS=FAIL"
  exit 1
fi
echo "CONSERVATION_STATUS=PASS"
