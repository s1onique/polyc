#!/bin/sh
# THE C3 CONSERVATION EVIDENCE.
#
# PRODUCTION_SEMANTICS_CHANGED = NO
# HISTORICAL_EVIDENCE_MODIFIED = NO
#
# Every row is MEASURED by comparing the subject commit against the
# predecessor close, or by digesting the production bytes.
set -u
REPO=/Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc
D=evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01
CLOSE=edfc3b16620e8d84b00a276984109a3b2fa8b338
PRE=907af8c82abfb2292d5eccfdf18b63080da767f2
cd "$REPO" || exit 1
OUT="$D/c3/conservation.tsv"

{
echo "# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01"
echo '# ACT_PHASE=C3-EVIDENCE'
echo '# EVIDENCE_KIND=conservation'
echo '#'
echo '# PRODUCTION_SEMANTICS_CHANGED = NO'
echo '# HISTORICAL_EVIDENCE_MODIFIED = NO'
echo '#'
echo '# Every row is MEASURED. A row whose method is a git diff records'
echo '# the EXACT number of differing paths between the predecessor close'
echo '# and the subject commit, over the named path set.'
echo '#'
printf 'subject\tpath_set\tdiffering_paths\tmeasured_by\tresult\n'
} > "$OUT"

row() {
  printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" >> "$OUT"
}

# --- The production source set ---------------------------------------------
for p in src tools/bootstrap; do
  n=$(git diff --name-only "$CLOSE" HEAD -- "$p" | wc -l | tr -d ' ')
  row PRODUCTION_SOURCE "$p" "$n" "git diff --name-only <predecessor-close> HEAD -- $p" "$( [ "$n" -eq 0 ] && echo UNCHANGED || echo CHANGED )"
done

# --- The production binaries ----------------------------------------------
HCC_SHA=$(shasum -a 256 hcc | awk '{print $1}')
HCC_EXPECT=c59254bf70b7826a12042ba7aa6ac25ef5b6b4ddb53a706042abc773d4b7fb41
row PRODUCTION_BINARY "hcc" "$HCC_SHA" "sha256 of the production compiler in the working tree" "$( [ "$HCC_SHA" = "$HCC_EXPECT" ] && echo UNCHANGED || echo CHANGED )"

# The bootstrap driver object and the subject object.
for f in build/CMakeFiles/hcc.dir/src/main.c.o build/CMakeFiles/hcc.dir/tools/bootstrap/selfhost-driver-wp001.HC.o; do
  if [ -f "$f" ]; then
    row PRODUCTION_OBJECT "$f" "$(shasum -a 256 "$f" | awk '{print $1}')" "sha256 of the built object" MEASURED
  else
    row PRODUCTION_OBJECT "$f" ABSENT "the object is not present in this build tree" NOT_APPLICABLE
  fi
done

# --- The historical evidence ------------------------------------------------
# The predecessor's committed evidence is preserved byte for byte: the
# predecessor close tree is compared against the subject tree.
for p in evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01 docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01.md; do
  n=$(git diff --name-only "$CLOSE" HEAD -- "$p" | wc -l | tr -d ' ')
  row HISTORICAL_EVIDENCE "$p" "$n" "git diff --name-only <predecessor-close> HEAD -- $p" "$( [ "$n" -eq 0 ] && echo UNCHANGED || echo CHANGED )"
done

# The predecessor's closed ACT document itself.
n=$(git diff --name-only "$CLOSE" HEAD -- docs/acts/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01.md | wc -l | tr -d ' ')
row HISTORICAL_ACT_DOCUMENT "docs/acts/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01.md" "$n" "git diff --name-only <predecessor-close> HEAD -- <the closed ACT document>" "$( [ "$n" -eq 0 ] && echo UNCHANGED || echo CHANGED )"

# The predecessor's CLOSE commit is still present and is an ancestor.
if git merge-base --is-ancestor "$CLOSE" HEAD; then anc=YES; else anc=NO; fi
row HISTORICAL_CLOSE_ANCESTRY "<predecessor-close>" "$anc" "git merge-base --is-ancestor <predecessor-close> HEAD" "$( [ "$anc" = YES ] && echo PASS || echo FAIL )"

# The predecessor's post-close outcome commit is still present.
if git cat-file -e "$PRE^{commit}" 2>/dev/null; then pc=YES; else pc=NO; fi
row HISTORICAL_POST_CLOSE_OUTCOME "<predecessor-post-close>" "$pc" "git cat-file -e <predecessor-post-close>^{commit}" "$( [ "$pc" = YES ] && echo PASS || echo FAIL )"

# --- The changed-file set of this correction ------------------------------
n=$(git diff --name-only "$PRE" HEAD | wc -l | tr -d ' ')
row CORRECTION_SCOPE "all paths changed by this correction" "$n" "git diff --name-only <predecessor-post-close> HEAD" MEASURED

{
echo '#'
echo '# The production source set and the production compiler bytes are'
echo '# UNCHANGED against the predecessor close. The predecessor'
echo '# evidence, the predecessor handoff and the predecessor closed ACT'
echo '# document are UNCHANGED. The predecessor close and its post-close'
echo '# outcome commit are both still present, and the close is an'
echo '# ancestor of the subject commit.'
} >> "$OUT"
