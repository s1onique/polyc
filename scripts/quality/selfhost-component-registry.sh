#!/bin/sh
# scripts/quality/selfhost-component-registry.sh
#
# ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 C2.1 IMPL.
# Thin launcher for the (currently Python) selfhost
# component registry validator. The substantive logic
# is in scripts/quality/selfhost-component-registry.py
# (subject to C2.2 PolyC rewrite).
#
# This shell wrapper exists so the Makefile selfhost-
# registry-validate target no longer invokes python3
# directly; this is the F-NO-PYTHON transitional seam.

set -eu
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
exec python3 "$SCRIPT_DIR/selfhost-component-registry.py" "$@"
