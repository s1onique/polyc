#!/bin/sh
# scripts/quality/factory-no-python-check.sh
#
# ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 C2.1.1 IMPL.
# Thin launcher for tools/factory/factory-no-python-check.HC.
#
# -z is used because git filenames MAY contain newline
# characters; NUL is the only unambiguous delimiter.
# The PolyC parser walks NUL records directly.

set -eu
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

if [ ! -d .git ]; then
    echo "factory-no-python-check: not a git repository" >&2
    exit 3
fi

LIST=$(mktemp -t factory-no-python.XXXXXXXXXX)
trap 'rm -f "$LIST"' EXIT
git ls-files -z > "$LIST"

if [ ! -x ./build/factory-no-python-check ]; then
    echo "factory-no-python-check: build artifact missing" >&2
    exit 3
fi

exec ./build/factory-no-python-check "$LIST"
