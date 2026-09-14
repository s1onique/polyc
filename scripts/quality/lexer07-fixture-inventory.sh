#!/bin/sh
# scripts/quality/lexer07-fixture-inventory.sh
#
# ACT-POLYC-SELFHOST-LEXER02-CORRECTION03 C2 IMPL.
# Thin launcher for tools/quality/lexer07-fixture-inventory.HC.
# F-POLYC-TOOLS compliant: ≤50 LOC dispatch glue only.
set -eu
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR/../.."
[ -x ./build/lexer07-fixture-inventory ] || {
  echo "lexer07-fixture-inventory: build artifact missing" >&2
  exit 3
}
exec ./build/lexer07-fixture-inventory "$@"
