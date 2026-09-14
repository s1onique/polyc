#!/bin/sh
# scripts/quality/lexer07-broad-corpus-4-stage.sh
#
# ACT-POLYC-SELFHOST-LEXER02-CORRECTION03 C2 IMPL.
# Thin launcher. All substantive work (sha256, classification,
# provenance binding, evidence emission) lives in the PolyC
# tool tools/quality/lexer07-broad-corpus-4-stage.HC.
# F-POLYC-TOOLS compliant: <=50 LOC dispatch glue only.
set -eu
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR/../.."
[ -x ./build/lexer07-broad-corpus-4-stage ] || {
  echo "lexer07-broad-corpus-4-stage: build artifact missing" >&2
  exit 3
}
exec ./build/lexer07-broad-corpus-4-stage "$@"
