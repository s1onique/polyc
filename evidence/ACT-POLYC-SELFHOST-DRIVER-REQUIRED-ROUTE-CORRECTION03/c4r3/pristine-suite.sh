#!/bin/sh
#
# evidence/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03/c4r3/pristine-suite.sh
#
# ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
# ROUND 3.
#
# THE PRISTINE ISOLATED CHECKOUT SUITE.
#
# It materializes the repository at the EXACT subject commit into an
# ISOLATED directory that shares no build state with the working tree, and
# runs EVERY CORRECTION03 target there.
#
# A build that only passes in the working tree is a WARM-TREE result. The
# F9 doctrine requires a fresh-tree result for a closure-critical gate.
#
# The isolation is total:
#
#   * the checkout is a `git worktree` at the subject commit, so it has
#     the committed bytes and NOT the working tree's uncommitted bytes;
#   * the build directory is INSIDE the worktree, so no artifact of the
#     working tree's build is reused;
#   * the shared assembly scratch path is removed before the run, so the
#     run cannot observe a stale scratch file.
#
# It writes a machine-readable ledger to stdout. Every row records the
# TARGET, the MAKE EXIT STATUS and whether the target reported its own
# PASS status line.
#
# The script is READ-ONLY with respect to the working tree: it writes only
# into the worktree it creates and into the work directory it is given.
# It uses no Python.
#
# F-POLYC-TOOLS: shell as bootstrap glue; the tools themselves are PolyC.

set -u

REPO="${1:?usage: pristine-suite.sh <repo-root> <work-dir>}"
WORK="${2:?usage: pristine-suite.sh <repo-root> <work-dir>}"

if [ ! -d "$REPO" ]; then
  echo "pristine-suite: the repository root $REPO does not exist" >&2
  exit 2
fi

SUBJECT=$(cd "$REPO" && git rev-parse HEAD)
if [ -z "$SUBJECT" ]; then
  echo "pristine-suite: the subject commit could not be determined" >&2
  exit 2
fi

rm -rf "$WORK"
mkdir -p "$WORK"

CHECKOUT="$WORK/checkout"
cd "$REPO" || exit 2
git worktree add --detach "$CHECKOUT" "$SUBJECT" >"$WORK/worktree.log" 2>&1
if [ ! -d "$CHECKOUT" ]; then
  echo "pristine-suite: the isolated checkout was not created" >&2
  cat "$WORK/worktree.log" >&2
  exit 3
fi

# The isolated checkout's own build directory starts EMPTY. Nothing from
# the working tree's build is reused.
rm -rf "$CHECKOUT/build"

# The shared assembly scratch path is removed, so the run cannot observe a
# stale scratch file left by another build.
rm -f /tmp/holyc-asm.s

echo "# ACT_PHASE=C4R3-EVIDENCE"
echo "# EVIDENCE_KIND=pristine-isolated-suite"
echo "# SUBJECT=$SUBJECT"
echo "# CHECKOUT=$CHECKOUT"
echo "target	make_exit	self_status"
echo "#"

failures=0
for target in \
  driver-wp001-correction03-contract-test \
  driver-wp001-correction03-test \
  driver-wp001-correction03-emission-test \
  driver-wp001-correction03-causal-test \
  driver-wp001-correction03-adverse-test \
  driver-wp001-correction03-publish-test \
  driver-wp001-correction03-matrix-test
do
  log="$WORK/$target.log"
  rm -f /tmp/holyc-asm.s
  ( cd "$CHECKOUT" && make "$target" ) >"$log" 2>&1
  rc=$?
  if grep -q "STATUS=PASS" "$log"; then
    self="PASS"
  else
    self="NO_PASS_STATUS"
  fi
  if [ "$rc" -ne 0 ] || [ "$self" != "PASS" ]; then
    failures=$((failures + 1))
  fi
  echo "$target	$rc	$self"
done

# The isolated checkout is removed. The worktree registration is removed
# with it, so the repository is left exactly as it was found.
( cd "$REPO" && git worktree remove --force "$CHECKOUT" ) >/dev/null 2>&1
( cd "$REPO" && git worktree prune ) >/dev/null 2>&1

echo "#"
echo "PRISTINE_TARGETS=7"
echo "PRISTINE_FAILURES=$failures"
if [ "$failures" -ne 0 ]; then
  echo "PRISTINE_SUITE_STATUS=FAIL"
  exit 1
fi
echo "PRISTINE_SUITE_STATUS=PASS"
