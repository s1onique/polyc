#!/bin/sh
# scripts/quality/factory-halt-classification-check.sh
#
# ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01
# ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01 D3
# ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 C2.3.c
#
# Thin shell wrapper that dispatches to the PolyC authoritative
# implementation at tools/factory/factory-halt-classification.HC
# (built into ./build/factory-halt-classification by
# `make factory-halt-classification-binary`). No substantive
# policy in this file; the wrapper stays under the <=50 LOC
# ratchet.

set -eu
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"
exec "$REPO_ROOT/build/factory-halt-classification" "$@"
