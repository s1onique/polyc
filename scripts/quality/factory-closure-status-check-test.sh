#!/bin/sh
# scripts/quality/factory-closure-status-check-test.sh
#
# ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01 P0-4:
# Reduced to <=50-LOC dispatch wrapper. The 12-case regression
# matrix lives in scripts/quality/factory-closure-status-test-cases.sh
# and is driven by tools/quality/factory-closure-status-test.HC
# (the PolyC authoritative tool).
set -eu
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"
exec "$REPO_ROOT/build/factory-closure-status-test" \
    "$REPO_ROOT/scripts/quality/factory-closure-status-check.sh" \
    "$REPO_ROOT/scripts/quality/factory-closure-status-test-cases.sh"
