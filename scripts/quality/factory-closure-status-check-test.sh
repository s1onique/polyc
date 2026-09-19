#!/bin/sh
# scripts/quality/factory-closure-status-check-test.sh
#
# ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION02 P0-1:
# Pure dispatch wrapper. The 12-case regression matrix is data
# in scripts/quality/factory-closure-status-test-cases.tsv; all
# test logic lives in tools/quality/factory-closure-status-test.HC
# (the PolyC authoritative tool).
set -eu
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"
exec env \
    FACTORY_CLOSURE_STATUS_CHECKER="$REPO_ROOT/scripts/quality/factory-closure-status-check.sh" \
    FACTORY_CLOSURE_STATUS_CASES="$REPO_ROOT/scripts/quality/factory-closure-status-test-cases.tsv" \
    "$REPO_ROOT/build/factory-closure-status-test"
