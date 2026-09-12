#!/bin/sh
# scripts/quality/factory-halt-classification-check.sh
#
# ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01
# ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01 D3
#
# Thin launcher that delegates to factory-halt-classification.py.
# The substantive trailer-classification logic lives in Python
# (an already-required host facility, used in production by
# scripts/quality/llvm-cap-table-verifier.py) so this shell
# script can stay under the <=50 LOC ratchet. The Python module
# preserves the exact line-oriented output format this launcher
# historically emitted (STATUS=/MODE=/ACT=/PHASE=/VERDICT=
# /HALT_CLASS=/BLOCKS_NEXT= and optional REASON=).

set -eu
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
exec python3 "$SCRIPT_DIR/factory-halt-classification.py" "$@"
