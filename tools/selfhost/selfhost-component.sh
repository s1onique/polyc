#!/bin/sh
# tools/selfhost/selfhost-component.sh
#
# ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 C2.2 IMPL.
#
# Thin dispatch wrapper for the PolyC-native self-host
# component control plane. The substantive logic lives in
# tools/selfhost/selfhost-component.HC (compiled to
# build/selfhost-component by ./hcc).
#
# Public Make contract (preserved):
#   make selfhost-component-build COMPONENT=<id> STAGE=<n>
#   make selfhost-component-test  COMPONENT=<id> STAGE=<n>
#   make selfhost-registry-validate
#
# This wrapper's only jobs are:
#   1. Locate the PolyC binary (build/selfhost-component)
#   2. Propagate env COMPONENT / STAGE (target-specific exported
#      variables from the Makefile; never appear in recipe
#      command text)
#   3. exec the binary
#
# No registry parsing. No build logic. No validation logic.

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
BIN="${REPO_ROOT}/build/selfhost-component"

if [ ! -x "$BIN" ]; then
    echo "selfhost-component.sh: PolyC binary missing or not executable: $BIN" >&2
    echo "selfhost-component.sh: build it via:" >&2
    echo "  ./hcc --install-dir=\${REPO_ROOT}/build/test-prefix -c \\" >&2
    echo "      tools/selfhost/selfhost-component.HC -o build/selfhost-component.o" >&2
    echo "  cc build/selfhost-component.o -L\${REPO_ROOT}/build/test-prefix/lib -ltos \\" >&2
    echo "      -o $BIN" >&2
    exit 3
fi

exec "$BIN" "$@"
