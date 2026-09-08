#!/bin/sh
# scripts/quality/llvm-closure-status-check.sh
#
# COMPATIBILITY WRAPPER (introduced by ACT-POLYC-FACTORY-STATUS-RECONCILIATION).
#
# This script is retained only for callers that still reference
# the historical filename. It delegates to the canonical exact-token
# factory closure-status gate at:
#
#   scripts/quality/factory-closure-status-check.sh
#
# The exact-token model, manifest bijection, and metadata contract
# are defined in:
#
#   docs/acts/ACT-POLYC-FACTORY-STATUS-RECONCILIATION.md
#
# See also: docs/factory/act-handoff-map.tsv.

set -eu
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
exec "$SCRIPT_DIR/factory-closure-status-check.sh" "$@"
