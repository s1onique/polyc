#!/bin/sh
# scripts/quality/lexer08-trivia-fixedpoint.sh
#
# ACT-POLYC-SELFHOST-LEXER03-CORRECTION02 C2 IMPL.
# Thin launcher. All substantive work (byte-equality, SHA-256,
# negative control) lives in the PolyC tool
# tools/quality/lexer08-fixedpoint-verify.HC.
# F-POLYC-TOOLS compliant: <=50 LOC dispatch glue only.
set -eu
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR/../.."
[ -x ./build/lexer08-fixedpoint-verify ] || {
  echo "lexer08-trivia-fixedpoint: build artifact missing" >&2
  exit 3
}
exec ./build/lexer08-fixedpoint-verify "$@"
