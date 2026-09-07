#!/bin/sh
# scripts/install-git-hooks.sh
#
# Configure this repository to use the versioned Git hooks under
# .githooks/. Idempotent. Repository-local only.
#
# Side effects:
#   git config core.hooksPath .githooks
#
# No global git configuration is modified. No files are copied into
# .git/hooks.

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
cd "$REPO_ROOT"

if [ ! -d .git ]; then
    echo "STATUS=ERROR"
    echo "REASON=not inside a git repository ($REPO_ROOT)"
    exit 2
fi

# Validate that the expected hook files are present and executable.
fail=0
for required in .githooks/pre-commit .githooks/pre-push; do
    if [ ! -f "$required" ]; then
        echo "STATUS=ERROR"
        echo "REASON=missing hook file: $required"
        exit 2
    fi
    if [ ! -x "$required" ]; then
        echo "STATUS=ERROR"
        echo "REASON=hook file is not executable: $required"
        exit 2
    fi
done

git config core.hooksPath .githooks

echo "POLYC_HOOKS_INSTALLED=YES"
echo "CORE_HOOKSPATH=$(git config --get core.hooksPath)"
echo "PRE_COMMIT_EXECUTABLE=$([ -x .githooks/pre-commit ] && echo YES || echo NO)"
echo "PRE_PUSH_EXECUTABLE=$([ -x .githooks/pre-push ] && echo YES || echo NO)"

exit 0
