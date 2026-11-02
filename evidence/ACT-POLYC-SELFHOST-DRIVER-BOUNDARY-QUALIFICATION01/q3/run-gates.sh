#!/bin/sh
# ---------------------------------------------------------------------------
# THE Q3 GATE RESULTS
#
# The canonical local gates are run against the EXACT committed tree
# and their results are recorded. A gate is only evidence if it
# ACTUALLY RAN against the relevant subject commit.
#
#   gate-fast   the fast mechanical sanity gate
#   gate-push   the exhaustive gate, run against the exact committed
#               HEAD in a DETACHED WORKTREE, so that the caller's
#               working tree is not used
#
# The Factory, F14 and append-only checks are run as well.
#
# Output: q3/gate-results.tsv
# ---------------------------------------------------------------------------

set -u

HERE=$(dirname "$0")
ROOT=$(cd "$HERE/../../.." && pwd)
OUT="$HERE/gate-results.tsv"
TMP=$(mktemp -d /tmp/q03-gate.XXXXXX)
trap 'rm -rf "$TMP"' EXIT INT TERM

cd "$ROOT" || exit 1

emit() {
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "$OUT"
}

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01'
  echo '# ACT_PHASE=Q3-EVIDENCE'
  echo '# EVIDENCE_KIND=gate-results'
  echo '#'
  echo '# The canonical local gates, RUN AGAINST THE EXACT COMMITTED'
  echo '# TREE. A gate is only evidence if it actually ran.'
  echo '#'
  echo 'gate	command	measured	result'
} > "$OUT"

HEAD_SHA=$(git rev-parse HEAD)
emit SUBJECT_HEAD "git rev-parse HEAD" "$HEAD_SHA" MEASURED
emit SUBJECT_TREE "git rev-parse HEAD^{tree}" "$(git rev-parse 'HEAD^{tree}')" MEASURED
emit WORKTREE_DIRTY "git status --porcelain=v1" "$(git status --porcelain=v1 | grep -v '^?? ' | wc -l | tr -d ' ')" "0_DIRTY_TRACKED_ENTRIES"

# --- gate-fast -------------------------------------------------------------
gf_log="$TMP/gate-fast.log"
./scripts/quality/gate-fast.sh >"$gf_log" 2>&1
gf_rc=$?
gf_checks=$(grep -c '^CHECK=' "$gf_log")
emit GATE_FAST "scripts/quality/gate-fast.sh" "$gf_checks checks, rc=$gf_rc" "$( [ "$gf_rc" -eq 0 ] && echo PASS || echo FAIL )"

# --- gate-push -------------------------------------------------------------
#
# gate-push creates a DETACHED WORKTREE at the requested commit and
# runs the full local native gate inside it. The subject is the exact
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

# --- THE COMMIT-MESSAGE AND RANGE VALIDATORS ------------------------------
# Every commit of THIS ACT is validated for its trailer block.
cm_bad=0
cm_total=0
for sha in $(git log --first-parent --format='%H' "$HEAD_SHA" | while read h; do
              if git show -s --format=%B "$h" | grep -q '^ACT: ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01$'; then echo "$h"; fi
            done); do
  cm_total=$((cm_total+1))
  git show -s --format=%B "$sha" > "$TMP/msg.txt"
  if ! ./scripts/quality/factory-v2-commit-msg-check.sh "$TMP/msg.txt" | grep -q 'STATUS=PASS'; then
    cm_bad=$((cm_bad+1))
  fi
done
emit COMMIT_MSG_VALIDATOR "scripts/quality/factory-v2-commit-msg-check.sh" "$cm_total commits, $cm_bad invalid" "$( [ "$cm_bad" -eq 0 ] && echo PASS || echo FAIL )"

# --- THE REPLACE-REF AND WORKTREE INVARIANTS ------------------------------
emit REPLACE_REFS "git replace -l" "$(git replace -l | wc -l | tr -d ' ')" "$( [ "$(git replace -l | wc -l | tr -d ' ')" -eq 0 ] && echo PASS || echo FAIL )"
emit ACT_WORKTREES "git worktree list" "$(git worktree list | grep -c 'ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01' || true)" "0_ACT_WORKTREES"

# --- THE CLOSURE-STATUS MANIFEST -------------------------------------------
cs_log="$TMP/closure.log"
./scripts/quality/factory-closure-status-check.sh >"$cs_log" 2>&1
cs_rc=$?
emit FACTORY_CLOSURE_STATUS "scripts/quality/factory-closure-status-check.sh" "rc=$cs_rc" "$( [ "$cs_rc" -eq 0 ] && echo PASS || echo FAIL )"

fails=$(awk -F'\t' '!/^#/ && NF>0 && $4=="FAIL"' "$OUT" | wc -l | tr -d ' ')
{
  echo '#'
  echo "# GATE_FAILURES = $fails"
  if [ "$fails" -eq 0 ]; then
    echo "# GATE_STATUS = PASS"
  else
    echo "# GATE_STATUS = FAIL"
  fi
} >> "$OUT"

echo "GATE_RESULTS=$OUT"
echo "GATE_FAILURES=$fails"
if [ "$fails" -ne 0 ]; then
  exit 1
fi
exit 0
