#!/bin/sh
# scripts/quality/selfhost-component-registry.sh
#
# ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 C2.2 IMPL.
#
# Thin dispatch wrapper for the PolyC-native selfhost
# component registry validator. The substantive logic is
# in tools/selfhost/selfhost-component.HC (compiled to
# build/selfhost-component by ./hcc).
#
# Public Make contract (preserved):
#   make selfhost-registry-validate
#
# No registry parsing. No validation logic.

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
BIN="${REPO_ROOT}/build/selfhost-component"

if [ ! -x "$BIN" ]; then
    echo "selfhost-component-registry.sh: PolyC binary missing: $BIN" >&2
    exit 3
fi

exec "$BIN" validate "$@"
