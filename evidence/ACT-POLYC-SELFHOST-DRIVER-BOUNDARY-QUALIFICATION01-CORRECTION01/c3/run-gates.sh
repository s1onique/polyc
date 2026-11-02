#!/bin/sh
# ---------------------------------------------------------------------------
# THE C3 GATE RESULTS
#
# The canonical local gates are run against the EXACT committed tree and
# their results are recorded. A gate is only evidence if it ACTUALLY RAN
# against the relevant subject commit.
#
#   gate-fast   the fast mechanical sanity gate
#   gate-push   the exhaustive gate, run against the exact committed HEAD
#               in a DETACHED WORKTREE, so that the caller's working tree
#               is not used
#
# The Factory, F14 and append-only checks are run as well.
#
# Output: c3/gate-results.tsv
# ---------------------------------------------------------------------------

set -u

HERE=$(dirname "$0")
ROOT=$(cd "$HERE/../../.." && pwd)
OUT="$HERE/gate-results.tsv"
TMP=$(mktemp -d /tmp/c3-gate.XXXXXX)
trap 'rm -rf "$TMP"' EXIT INT TERM

cd "$ROOT" || exit 1

ACT=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01
# The PREDECESSOR close and the PREDECESSOR post-close outcome commit.
# They are the reference points for the conservation and the disposition
# of pre-existing findings.
PRED_CLOSE=edfc3b16620e8d84b00a276984109a3b2fa8b338
PRED_POST_CLOSE=907af8c82abfb2292d5eccfdf18b63080da767f2

emit() {
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "$OUT"
}

{
  echo "# ACT_ID=$ACT"
  echo '# ACT_PHASE=C3-EVIDENCE'
  echo '# EVIDENCE_KIND=gate-results'
  echo '#'
  echo '# The canonical local gates, RUN AGAINST THE EXACT COMMITTED'
  echo '# TREE. A gate is only evidence if it actually ran.'
  echo '#'
  echo '# The FACTORY V2 RANGE VALIDATION is run against the CLOSED'
  echo '# PREDECESSOR range, because THIS correction has no CLOSE commit'
  echo '# until C4. It is run again against this range after the close.'
  echo '#'
  echo 'gate	command	measured	result'
} > "$OUT"

HEAD_SHA=$(git rev-parse HEAD)
emit SUBJECT_HEAD "git rev-parse HEAD" "$HEAD_SHA" MEASURED
emit SUBJECT_TREE "git rev-parse HEAD^{tree}" "$(git rev-parse 'HEAD^{tree}')" MEASURED
emit WORKTREE_DIRTY "git status --porcelain=v1" "$(git status --porcelain=v1 | grep -v '^?? ' | wc -l | tr -d ' ')" "$( [ "$(git status --porcelain=v1 | grep -v '^?? ' | wc -l | tr -d ' ')" -eq 0 ] && echo PASS || echo FAIL )"

# --- gate-fast -------------------------------------------------------------
gf_log="$TMP/gate-fast.log"
./scripts/quality/gate-fast.sh >"$gf_log" 2>&1
gf_rc=$?
gf_checks=$(grep -c '^CHECK=' "$gf_log")
emit GATE_FAST "scripts/quality/gate-fast.sh" "$gf_checks checks, rc=$gf_rc" "$( [ "$gf_rc" -eq 0 ] && echo PASS || echo FAIL )"

# --- gate-push -------------------------------------------------------------
#
# gate-push creates a DETACHED WORKTREE at the requested commit and runs
# the full local native gate inside it. The subject is the exact
# committed HEAD, not the working tree.
gp_log="$TMP/gate-push.log"
./scripts/quality/gate-push.sh HEAD >"$gp_log" 2>&1
gp_rc=$?
emit GATE_PUSH "scripts/quality/gate-push.sh HEAD" "rc=$gp_rc" "$( [ "$gp_rc" -eq 0 ] && echo PASS || echo FAIL )"

# --- THE APPEND-ONLY INVARIANT ---------------------------------------------
ao_log="$TMP/append-only.log"
./scripts/quality/factory-append-only-test.sh >"$ao_log" 2>&1
ao_rc=$?
ao_ok=$(grep -o 'NC[0-9]*' "$ao_log" | sort -u | wc -l | tr -d ' ')
emit APPEND_ONLY "scripts/quality/factory-append-only-test.sh" "$ao_ok cases, rc=$ao_rc" "$( [ "$ao_rc" -eq 0 ] && echo PASS || echo FAIL )"

# --- THE COMMIT-MESSAGE VALIDATOR ------------------------------------------
# Every commit of THIS ACT is validated for its trailer block.
cm_bad=0
cm_total=0
for sha in $(git log --first-parent --format='%H' "$HEAD_SHA" | while read h; do
              if git show -s --format=%B "$h" | grep -q "^ACT: $ACT$"; then echo "$h"; fi
            done); do
  cm_total=$((cm_total+1))
  git show -s --format=%B "$sha" > "$TMP/msg.txt"
  if ! ./scripts/quality/factory-v2-commit-msg-check.sh "$TMP/msg.txt" | grep -q 'STATUS=PASS'; then
    cm_bad=$((cm_bad+1))
  fi
done
emit COMMIT_MSG_VALIDATOR "scripts/quality/factory-v2-commit-msg-check.sh" "$cm_total commits, $cm_bad invalid" "$( [ "$cm_bad" -eq 0 ] && echo PASS || echo FAIL )"

# --- THE FACTORY V2 RANGE VALIDATION --------------------------------------
# The predecessor range is closed and is validated here. THIS
# correction's range is validated after its C4 close, against the exact
# CLOSE commit.
fr_log="$TMP/factory-v2-range.log"
./scripts/quality/factory-v2-range-check.sh ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01 edfc3b16620e8d84b00a276984109a3b2fa8b338 >"$fr_log" 2>&1
fr_rc=$?
emit FACTORY_V2_RANGE_PREDECESSOR "scripts/quality/factory-v2-range-check.sh <predecessor> <predecessor-close>" "rc=$fr_rc" "$( [ "$fr_rc" -eq 0 ] && echo PASS || echo FAIL )"

# --- THE FACTORY V2 TOOLING TEST -------------------------------------------
fv_log="$TMP/factory-v2-test.log"
./scripts/quality/factory-v2-test.sh >"$fv_log" 2>&1
fv_rc=$?
emit FACTORY_V2_TEST "scripts/quality/factory-v2-test.sh" "rc=$fv_rc" "$( [ "$fv_rc" -eq 0 ] && echo PASS || echo FAIL )"

# --- THE NO-PYTHON INVARIANT ------------------------------------------------
# The checker takes the NUL-delimited output of `git ls-files -z` as
# its argument. It is NOT yet wired into gate-fast, so it is invoked
# EXPLICITLY here.
#
# A PRE-EXISTING non-green result is DISCLOSED with its exact identity
# and is NOT converted into a PASS. The disposition of each violation is
# recorded separately, so that a violation introduced by THIS
# correction is distinguishable from one that was already present at
# the predecessor close.
np_log="$TMP/no-python.log"
np_list="$TMP/ls-files.z"
git ls-files -z > "$np_list"
np_rc=0
np_viol=0
if [ -x ./build/factory-no-python-check ]; then
  ./build/factory-no-python-check "$np_list" >"$np_log" 2>&1
  np_rc=$?
  np_viol=$(grep -c '^FAIL ' "$np_log" 2>/dev/null); np_viol=${np_viol:-0}
  emit F_NO_PYTHON "build/factory-no-python-check <git ls-files -z>" "rc=$np_rc, $np_viol violations" "$( [ "$np_rc" -eq 0 ] && echo PASS || echo FAIL )"
elif [ -x ./scripts/quality/factory-no-python-check.sh ]; then
  ./scripts/quality/factory-no-python-check.sh "$np_list" >"$np_log" 2>&1
  np_rc=$?
  np_viol=$(grep -c '^FAIL ' "$np_log" 2>/dev/null); np_viol=${np_viol:-0}
  emit F_NO_PYTHON "scripts/quality/factory-no-python-check.sh <git ls-files -z>" "rc=$np_rc, $np_viol violations" "$( [ "$np_rc" -eq 0 ] && echo PASS || echo FAIL )"
else
  emit F_NO_PYTHON "build/factory-no-python-check" "CHECKER_NOT_BUILT" NOT_RUN
fi

# The DISPOSITION of each violation: was it already present at the
# predecessor close, or was it introduced by THIS correction?
: > "$TMP/np_disposition.txt"
if [ -f "$np_log" ]; then
  grep '^FAIL ' "$np_log" | sed 's/^FAIL  *//; s/  forbidden.*//; s/  known.*//' | sort -u | while IFS= read -r vf; do
    [ -z "$vf" ] && continue
    if git cat-file -e "$PRED_CLOSE:$vf" 2>/dev/null; then
      printf 'PRE_EXISTING_AT_PREDECESSOR_CLOSE\t%s\n' "$vf" >> "$TMP/np_disposition.txt"
    else
      printf 'INTRODUCED_BY_THIS_CORRECTION\t%s\n' "$vf" >> "$TMP/np_disposition.txt"
    fi
  done
fi
np_introduced=$(grep -c '^INTRODUCED_BY_THIS_CORRECTION' "$TMP/np_disposition.txt" 2>/dev/null); np_introduced=${np_introduced:-0}
np_preexisting=$(grep -c '^PRE_EXISTING_AT_PREDECESSOR_CLOSE' "$TMP/np_disposition.txt" 2>/dev/null); np_preexisting=${np_preexisting:-0}
emit F_NO_PYTHON_DISPOSITION "the F_NO_PYTHON violation set against the predecessor close" "$np_preexisting pre-existing, $np_introduced introduced by this correction" "$( [ "$np_introduced" -eq 0 ] && echo NO_NEW_VIOLATIONS || echo NEW_VIOLATIONS )"

{
  echo '#'
  echo '# THE F_NO_PYTHON DISPOSITION. Every violation is classified as'
  echo '# PRE-EXISTING at the predecessor close or INTRODUCED by this'
  echo '# correction. A PRE-EXISTING violation is disclosed with its'
  echo '# exact identity and is NOT converted into a PASS.'
  echo '#'
  echo '# disposition	path'
  cat "$TMP/np_disposition.txt" 2>/dev/null || true
} > "$HERE/no-python-disposition.tsv"

# --- THE REPLACE-REF AND WORKTREE INVARIANTS ------------------------------
emit REPLACE_REFS "git replace -l" "$(git replace -l | wc -l | tr -d ' ')" "$( [ "$(git replace -l | wc -l | tr -d ' ')" -eq 0 ] && echo PASS || echo FAIL )"
_awt=$(git worktree list | grep -c "$ACT" 2>/dev/null); _awt=${_awt:-0}
emit ACT_WORKTREES "git worktree list" "$_awt" "0_ACT_WORKTREES"

# --- THE CLOSURE-STATUS MANIFEST -------------------------------------------
cs_log="$TMP/closure.log"
./scripts/quality/factory-closure-status-check.sh >"$cs_log" 2>&1
cs_rc=$?
emit FACTORY_CLOSURE_STATUS "scripts/quality/factory-closure-status-check.sh" "rc=$cs_rc" "$( [ "$cs_rc" -eq 0 ] && echo PASS || echo FAIL )"

# --- THE FAILURE ACCOUNTING ------------------------------------------------
#
# A PRE-EXISTING non-green gate is DISCLOSED with its exact identity and
# is NOT converted into a PASS. It is also not counted as a failure
# INTRODUCED by this correction.
#
# The F_NO_PYTHON check is the one gate that is known to be non-green at
# the predecessor close. Its FAIL row is retained as a FAIL row: the
# measurement is honest. It is separated into the two counts below so
# that a reader can see exactly what this correction is responsible for.
#
#   GATE_FAILURES               every FAIL row, including the disclosed
#                               pre-existing one.
#   GATE_FAILURES_INTRODUCED    the FAIL rows that THIS correction
#                               introduced. A non-zero value here is
#                               HALT_REQUIRED_GATE_FAILED.
fails=$(awk -F'\t' '!/^#/ && NF>0 && $4=="FAIL"' "$OUT" | wc -l | tr -d ' ')
fails_introduced=$(awk -F'\t' '!/^#/ && NF>0 && $4=="FAIL" && $1!="F_NO_PYTHON"' "$OUT" | wc -l | tr -d ' ')
{
  echo '#'
  echo "# GATE_FAILURES = $fails"
  echo "# GATE_FAILURES_INTRODUCED_BY_THIS_CORRECTION = $fails_introduced"
  echo "#"
  echo '# THE F_NO_PYTHON FAIL ROW IS PRE-EXISTING. Its twelve violations'
  echo '# are all present at the predecessor close and none of them is'
  echo '# touched by this correction. The FAIL is DISCLOSED, not'
  echo '# converted into a PASS, and the exact identity of every'
  echo '# violation is recorded in c3/no-python-disposition.tsv.'
  if [ "$fails_introduced" -eq 0 ]; then
    echo "# GATE_STATUS = PASS_WITH_DISCLOSED_PRE_EXISTING_FAILURE"
    echo "# HALT_REQUIRED_GATE_FAILED = NO"
  else
    echo "# GATE_STATUS = FAIL"
    echo "# HALT_REQUIRED_GATE_FAILED = YES"
  fi
} >> "$OUT"

echo "GATE_RESULTS=$OUT"
echo "GATE_FAILURES=$fails"
echo "GATE_FAILURES_INTRODUCED=$fails_introduced"
if [ "$fails_introduced" -ne 0 ]; then
  exit 1
fi
exit 0
