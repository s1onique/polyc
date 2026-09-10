#!/bin/sh
# scripts/quality/harness-evidence-isolation-test.sh
#
# ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C5 (harness-isolation
# producer fix): regression test that proves a fresh run of the
# spike harness does NOT modify any tracked closed-ACT evidence tree.
#
# Method:
#   1. snapshot `git status --porcelain`
#   2. snapshot SHA-256 of every file under
#      evidence/llvm-core04-resume01/c2/red-multi_def/ and
#      evidence/llvm-memory01/spike/red-6-live-transcripts/
#      (the two closed-ACT trees that RED-1 reproduced as dirty)
#   3. run `make llvm-spike-test`
#   4. assert git status has NO new modifications under either tree
#   5. assert the SHA-256 of every closed-ACT evidence file is unchanged
#
# Exit code:
#   0  PASS
#   non-zero on FAIL

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

CLOSED_ACT_TREES="
evidence/llvm-core04-resume01/c2/red-multi_def
evidence/llvm-memory01/spike/red-6-live-transcripts
"

# The test requires hcc built with LLVM support, an install dir,
# and LLVM 22.x on PATH. We require the user to set HCC_INSTALL_DIR
# (or rely on a system-wide install).
HCC_INSTALL_DIR=${HCC_INSTALL_DIR:-}
HCC_INSTALL_ARG=""
if [ -n "$HCC_INSTALL_DIR" ]; then
    HCC_INSTALL_ARG="HCC_INSTALL_DIR=$HCC_INSTALL_DIR"
fi

if [ ! -x ./hcc ]; then
    echo "SKIP: ./hcc not built (run 'make llvm-all' first)" >&2
    exit 0
fi

if ! command -v llvm-config >/dev/null 2>&1; then
    echo "SKIP: llvm-config not on PATH" >&2
    exit 0
fi

if [ "$(llvm-config --version | cut -d. -f1)" != "22" ]; then
    echo "SKIP: llvm-config reports $(llvm-config --version); need 22.x" >&2
    exit 0
fi

if ! nm ./hcc 2>/dev/null | grep -q '_LLVMAddFunction'; then
    echo "SKIP: ./hcc is not an LLVM-enabled build" >&2
    exit 0
fi

# Step 1: snapshot git status BEFORE
before_status=$(git status --porcelain)
before_status_clean=$(printf '%s\n' "$before_status" | \
    grep -E '^\?\? evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02/c5/' || true)

# Step 2: snapshot SHA-256 of every file under the two closed-ACT trees
before_sha_file=$(mktemp)
trap 'rm -f "$before_sha_file"' EXIT
for tree in $CLOSED_ACT_TREES; do
    if [ -d "$tree" ]; then
        (cd "$tree" && sha256sum ./* 2>/dev/null) >> "$before_sha_file"
    fi
done
before_sha_count=$(wc -l < "$before_sha_file")

# Step 3: run the spike harness. Use `env -i` semantics via a clean
# EVIDENCE_OUT unset state (this script does NOT set EVIDENCE_OUT,
# so the harness's ordinary-regression default fires).
echo "=== running make llvm-spike-test (C5 isolation check) ==="
if ! env -u EVIDENCE_OUT -u LLVM_SPIKE_EVID_OVERRIDE -u LLVM_SPIKE_EVID_CORR_OVERRIDE \
        $HCC_INSTALL_ARG make llvm-spike-test >/tmp/c5-spike.stdout 2>/tmp/c5-spike.stderr; then
    echo "FAIL: llvm-spike-test exited non-zero"
    tail -20 /tmp/c5-spike.stderr >&2
    exit 1
fi

# Step 4: assert git status has no new modifications under the
# closed-ACT trees (filter the porcelain to only those paths).
after_status=$(git status --porcelain)
contamination=$(printf '%s\n' "$after_status" | \
    grep -E '^.. (evidence/llvm-core04-resume01|evidence/llvm-memory01)/' || true)
if [ -n "$contamination" ]; then
    echo "FAIL: closed-ACT evidence tree was mutated:"
    printf '%s\n' "$contamination"
    exit 1
fi

# Step 5: re-snapshot SHA-256 and compare.
after_sha_file=$(mktemp)
trap 'rm -f "$before_sha_file" "$after_sha_file"' EXIT
for tree in $CLOSED_ACT_TREES; do
    if [ -d "$tree" ]; then
        (cd "$tree" && sha256sum ./* 2>/dev/null) >> "$after_sha_file"
    fi
done
after_sha_count=$(wc -l < "$after_sha_file")

if [ "$before_sha_count" -ne "$after_sha_count" ]; then
    echo "FAIL: file count under closed-ACT trees changed ($before_sha_count -> $after_sha_count)"
    exit 1
fi

if ! cmp -s "$before_sha_file" "$after_sha_file"; then
    echo "FAIL: SHA-256 of closed-ACT evidence files changed"
    diff "$before_sha_file" "$after_sha_file" >&2
    exit 1
fi

echo "PASS: harness-evidence-isolation-test"
echo "  closed-ACT trees scanned: $before_sha_count files"
echo "  git status --porcelain mod in any closed-ACT evidence tree: NONE"
exit 0
